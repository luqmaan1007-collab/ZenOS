#!/usr/bin/env bash
set -euo pipefail
DEST=${1:?Usage: build-rootfs.sh DESTINATION}
: "${RUNNER_TEMP:=$(mktemp -d)}"
# Arch Linux ARM publishes a detached signature for this root filesystem.
# The origin's TLS certificate currently fails hostname validation, so use
# the official HTTP redirector and authenticate the archive with the pinned
# upstream signing-key fingerprint before extracting any files.
ARCHROOT_URL="http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz"
ARCHIVE="$RUNNER_TEMP/ArchLinuxARM-aarch64-latest.tar.gz"
ARCHIVE_SIG="$ARCHIVE.sig"
mkdir -p "$DEST"
curl --fail --location --retry 5 --retry-all-errors --retry-delay 3 "$ARCHROOT_URL" -o "$ARCHIVE"
curl --fail --location --retry 5 --retry-all-errors --retry-delay 3 "${ARCHROOT_URL}.sig" -o "$ARCHIVE_SIG"
command -v gpg >/dev/null || { echo "gpg is required to verify the official Arch Linux ARM rootfs" >&2; exit 1; }
GNUPGHOME="$RUNNER_TEMP/zenos-gnupg"
mkdir -m 0700 -p "$GNUPGHOME"
export GNUPGHOME
gpg --batch --keyserver hkps://keyserver.ubuntu.com --recv-keys 68B3537F39A313B3E574D06777193F152BDBE6A6
FINGERPRINT="$(gpg --batch --with-colons --fingerprint 68B3537F39A313B3E574D06777193F152BDBE6A6 | awk -F: '$1 == "fpr" { print $10; exit }')"
[[ "$FINGERPRINT" == "68B3537F39A313B3E574D06777193F152BDBE6A6" ]] || { echo "Arch Linux ARM signing-key fingerprint mismatch" >&2; exit 1; }
gpg --batch --verify "$ARCHIVE_SIG" "$ARCHIVE"
tar -xpf "$ARCHIVE" -C "$DEST" --numeric-owner
# The compressed bootstrap archive is large; remove it before pacman downloads
# hundreds of MiB of package updates into the extracted root filesystem.
rm -f "$ARCHIVE" "$ARCHIVE_SIG"
rm -f "$DEST/etc/resolv.conf"
cp --dereference /etc/resolv.conf "$DEST/etc/resolv.conf"
printf '%s\n' "zenos-arm64" > "$DEST/etc/hostname"
printf '%s\n' "en_US.UTF-8 UTF-8" > "$DEST/etc/locale.gen"
printf '%s\n' 'LANG=en_US.UTF-8' > "$DEST/etc/locale.conf"
cat > "$DEST/etc/os-release" <<'RELEASE'
NAME="ZenOS"
PRETTY_NAME="ZenOS ARM64 Engineering Preview"
ID=zenos
ID_LIKE=arch
BUILD_ID=development
RELEASE
mkdir -p "$DEST/var/lib/zenos" "$DEST/usr/local/bin" "$DEST/usr/local/sbin" \
  "$DEST/etc/systemd/system/multi-user.target.wants" \
  "$DEST/etc/systemd/system/graphical.target.wants" \
  "$DEST/usr/share/applications" "$DEST/usr/share/color-schemes" "$DEST/dev/pts" "$DEST/proc" "$DEST/sys"
mount --bind /dev "$DEST/dev"
mount --bind /dev/pts "$DEST/dev/pts"
mount -t proc proc "$DEST/proc"
mount -t sysfs sysfs "$DEST/sys"
cleanup() {
  umount -lf "$DEST/dev/pts" || true
  umount -lf "$DEST/dev" || true
  umount -lf "$DEST/proc" || true
  umount -lf "$DEST/sys" || true
}
trap cleanup EXIT
chroot "$DEST" /bin/bash -euo pipefail -c '
  pacman-key --init
  pacman-key --populate archlinuxarm
  # Firmware bundles are very large; retain the bootstrap firmware to keep the
  # ARM runner within its disk budget while upgrading the userspace and kernel.
  pacman -Syu --noconfirm \
    --ignore linux-firmware,linux-firmware-amd,linux-firmware-amdgpu,linux-firmware-atheros,linux-firmware-broadcom,linux-firmware-cirrus,linux-firmware-intel,linux-firmware-mediatek,linux-firmware-nvidia,linux-firmware-other,linux-firmware-radeon,linux-firmware-realtek,linux-firmware-ti,linux-firmware-whence
  # Do not keep the bootstrap upgrade packages while downloading the desktop.
  pacman -Scc --noconfirm
  pacman -S --needed --noconfirm \
    base linux-aarch64 linux-firmware mkinitcpio grub efibootmgr \
    plasma-meta plasma-welcome plasma-workspace-wallpapers sddm breeze kdialog papirus-icon-theme noto-fonts noto-fonts-emoji \
    firefox mpv dolphin dolphin-plugins kio-extras konsole kate okular kcalc \
    discover flatpak packagekit packagekit-qt6 kde-gtk-config sddm-kcm \
    plasma-nm plasma-pa plasma-firewall plasma-systemmonitor polkit-kde-agent \
    networkmanager wpa_supplicant iwd pipewire pipewire-alsa pipewire-pulse wireplumber \
    bluez bluez-utils sudo nano vim git openssh rsync curl wget alsa-utils \
    xdg-user-dirs xdg-utils xdg-desktop-portal xdg-desktop-portal-kde xdg-desktop-portal-gtk \
    ark spectacle partitionmanager firewalld power-profiles-daemon upower udisks2 \
    gvfs gvfs-mtp gvfs-smb fuse2 fuse3 unzip 7zip file htop btop fastfetch man-db man-pages bash-completion zsh fish \
    e2fsprogs dosfstools btrfs-progs exfatprogs ntfs-3g f2fs-tools
  optional=(kdeconnect cups system-config-printer avahi nss-mdns gvfs-gphoto2 fwupd sane simple-scan v4l-utils libcamera usbutils pciutils dmidecode smartmontools nvme-cli)
  available=()
  for package in "${optional[@]}"; do
    if pacman -Si "$package" >/dev/null 2>&1; then available+=("$package"); else echo "Optional ARM package unavailable: $package"; fi
  done
  if (("${#available[@]}" > 0)); then pacman -S --needed --noconfirm "${available[@]}"; fi
  # Release the package cache before creating the final rootfs and disk image.
  pacman -Scc --noconfirm
  locale-gen
  passwd -l root
  userdel -r alarm || true
  find /etc/systemd/system -type l -name sshd.service -delete
  find /etc/systemd/system -type l -name sshd.socket -delete
  find /etc/systemd/system -type l -name systemd-networkd.service -delete
  find /etc/systemd/system -type l -name systemd-networkd-wait-online.service -delete
  find /etc/systemd/system -type l -name systemd-resolved.service -delete
  find /etc/systemd/system -type l -name dbus-org.freedesktop.resolve1.service -delete
  rm -f /etc/resolv.conf
  touch /etc/resolv.conf
'
install -m 0755 scripts/zenos-app "$DEST/usr/local/bin/zenos-app"
install -m 0755 scripts/zenos-firstboot "$DEST/usr/local/sbin/zenos-firstboot"
install -m 0755 scripts/zenos-theme-apply "$DEST/usr/local/bin/zenos-theme-apply"
install -m 0755 scripts/zenos-desktop-first-login "$DEST/usr/local/bin/zenos-desktop-first-login"
install -m 0755 scripts/zenos-welcome "$DEST/usr/local/bin/zenos-welcome"
install -m 0644 overlay/etc/systemd/system/zenos-firstboot-tty.service "$DEST/etc/systemd/system/zenos-firstboot-tty.service"
install -m 0644 overlay/etc/zenos-release "$DEST/etc/zenos-release"
mkdir -p "$DEST/etc/skel"
cp -a overlay/etc/skel/. "$DEST/etc/skel/"
install -m 0644 overlay/usr/share/applications/zenos-browser.desktop "$DEST/usr/share/applications/"
install -m 0644 overlay/usr/share/applications/zenos-store.desktop "$DEST/usr/share/applications/"
install -m 0644 overlay/usr/share/applications/zenos-theme.desktop "$DEST/usr/share/applications/"
install -m 0644 overlay/usr/share/applications/zenos-welcome.desktop "$DEST/usr/share/applications/"
install -m 0644 overlay/usr/share/color-schemes/ZenGlass.colors "$DEST/usr/share/color-schemes/ZenGlass.colors"
mkdir -p "$DEST/usr/share/wallpapers/ZenGlass/contents/images"
install -m 0644 overlay/usr/share/wallpapers/ZenGlass/metadata.json "$DEST/usr/share/wallpapers/ZenGlass/metadata.json"
install -m 0644 overlay/usr/share/wallpapers/ZenGlass/contents/images/1920x1080.svg "$DEST/usr/share/wallpapers/ZenGlass/contents/images/1920x1080.svg"
enable_unit() {
  local unit="$1"
  local destination="$2"
  if [[ -f "$DEST/usr/lib/systemd/system/$unit" ]]; then
    ln -sfn "/usr/lib/systemd/system/$unit" "$destination"
  else
    echo "Skipping unavailable service unit: $unit"
  fi
}
enable_unit NetworkManager.service "$DEST/etc/systemd/system/multi-user.target.wants/NetworkManager.service"
enable_unit bluetooth.service "$DEST/etc/systemd/system/multi-user.target.wants/bluetooth.service"
enable_unit cups.service "$DEST/etc/systemd/system/multi-user.target.wants/cups.service"
enable_unit avahi-daemon.service "$DEST/etc/systemd/system/multi-user.target.wants/avahi-daemon.service"
enable_unit firewalld.service "$DEST/etc/systemd/system/multi-user.target.wants/firewalld.service"
enable_unit systemd-timesyncd.service "$DEST/etc/systemd/system/multi-user.target.wants/systemd-timesyncd.service"
ln -sfn /etc/systemd/system/zenos-firstboot-tty.service "$DEST/etc/systemd/system/multi-user.target.wants/zenos-firstboot-tty.service"
enable_unit sddm.service "$DEST/etc/systemd/system/graphical.target.wants/sddm.service"
if [[ -f "$DEST/usr/lib/systemd/system/sddm.service" ]]; then
  ln -sfn /usr/lib/systemd/system/sddm.service "$DEST/etc/systemd/system/display-manager.service"
fi
