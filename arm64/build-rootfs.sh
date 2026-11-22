#!/usr/bin/env bash
set -euo pipefail
DEST=${1:?Usage: build-rootfs.sh DESTINATION}
: "${RUNNER_TEMP:=$(mktemp -d)}"
ARCHROOT_URL="https://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz"
ARCHIVE="$RUNNER_TEMP/ArchLinuxARM-aarch64-latest.tar.gz"
mkdir -p "$DEST"
curl --fail --location --retry 4 --retry-delay 2 "$ARCHROOT_URL" -o "$ARCHIVE"
tar -xpf "$ARCHIVE" -C "$DEST" --numeric-owner
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
  "$DEST/usr/share/applications" "$DEST/usr/share/color-schemes"
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
  pacman -Syu --noconfirm
  pacman -S --needed --noconfirm \
    base linux-aarch64 linux-firmware \
    plasma-meta plasma-wayland-session sddm breeze \
    firefox dolphin dolphin-plugins kio-extras konsole kate okular kcalc \
    discover flatpak packagekit-qt6 kdeconnect kde-gtk-config sddm-kcm \
    networkmanager plasma-nm wpa_supplicant iwd pipewire pipewire-alsa pipewire-pulse wireplumber \
    bluez bluez-utils sudo nano vim git openssh rsync curl wget \
    xdg-user-dirs xdg-utils xdg-desktop-portal xdg-desktop-portal-kde xdg-desktop-portal-gtk \
    ark spectacle partitionmanager cups system-config-printer avahi nss-mdns \
    power-profiles-daemon upower udisks2 gvfs gvfs-mtp gvfs-smb \
    fwupd unzip p7zip file htop btop man-db man-pages bash-completion \
    sane simple-scan v4l-utils
  locale-gen
'
install -m 0755 scripts/zenos-app "$DEST/usr/local/bin/zenos-app"
install -m 0755 scripts/zenos-install "$DEST/usr/local/bin/zenos-install"
install -m 0755 scripts/zenos-firstboot "$DEST/usr/local/sbin/zenos-firstboot"
install -m 0755 scripts/zenos-theme-apply "$DEST/usr/local/bin/zenos-theme-apply"
install -m 0644 overlay/etc/systemd/system/zenos-firstboot-tty.service "$DEST/etc/systemd/system/zenos-firstboot-tty.service"
install -m 0644 overlay/etc/zenos-release "$DEST/etc/zenos-release"
install -m 0644 overlay/usr/share/applications/*.desktop "$DEST/usr/share/applications/"
install -m 0644 overlay/usr/share/color-schemes/ZenGlass.colors "$DEST/usr/share/color-schemes/ZenGlass.colors"
ln -sfn /usr/lib/systemd/system/NetworkManager.service "$DEST/etc/systemd/system/multi-user.target.wants/NetworkManager.service"
ln -sfn /usr/lib/systemd/system/bluetooth.service "$DEST/etc/systemd/system/multi-user.target.wants/bluetooth.service"
ln -sfn /etc/systemd/system/zenos-firstboot-tty.service "$DEST/etc/systemd/system/multi-user.target.wants/zenos-firstboot-tty.service"
ln -sfn /usr/lib/systemd/system/sddm.service "$DEST/etc/systemd/system/graphical.target.wants/sddm.service"
