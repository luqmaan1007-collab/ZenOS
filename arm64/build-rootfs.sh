#!/usr/bin/env bash
set -euo pipefail
DEST=${1:?Usage: build-rootfs.sh DESTINATION}
: "${RUNNER_TEMP:=$(mktemp -d)}"
# Arch Linux ARM's download page publishes the official tarball and detached
# signature. Use its HTTP redirector because the origin's TLS certificate
# currently fails hostname validation; authenticate the payload with GPG
# before running anything from the extracted root filesystem.
ARCHROOT_URL="http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz"
ARCHIVE="$RUNNER_TEMP/ArchLinuxARM-aarch64-latest.tar.gz"
ARCHIVE_SIG="$ARCHIVE.sig"
mkdir -p "$DEST"
curl --fail --location --retry 5 --retry-all-errors --retry-delay 3 "$ARCHROOT_URL" -o "$ARCHIVE"
curl --fail --location --retry 5 --retry-all-errors --retry-delay 3 "${ARCHROOT_URL}.sig" -o "$ARCHIVE_SIG"
tar -xpf "$ARCHIVE" -C "$DEST" --numeric-owner
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
  pacman-key --verify "$ARCHIVE_SIG" "$ARCHIVE"
  pacman -Syu --noconfirm
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
