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
mkdir -p "$DEST/var/lib/zenos" "$DEST/usr/local/bin" "$DEST/usr/local/sbin" "$DEST/etc/systemd/system"
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
    firefox dolphin konsole discover flatpak packagekit-qt6 \
    networkmanager wpa_supplicant iwd pipewire pipewire-alsa pipewire-pulse wireplumber \
    bluez bluez-utils sudo nano vim git curl wget \
    xdg-user-dirs xdg-utils xdg-desktop-portal xdg-desktop-portal-kde \
    ark spectacle cups power-profiles-daemon unzip p7zip file htop
  systemctl enable NetworkManager.service
  systemctl enable bluetooth.service
  systemctl enable sddm.service
'
install -m 0755 scripts/zenos-app "$DEST/usr/local/bin/zenos-app"
install -m 0755 scripts/zenos-install "$DEST/usr/local/bin/zenos-install"
install -m 0755 scripts/zenos-firstboot "$DEST/usr/local/sbin/zenos-firstboot"
install -m 0755 scripts/zenos-theme-apply "$DEST/usr/local/bin/zenos-theme-apply"
install -m 0644 overlay/etc/systemd/system/zenos-firstboot-tty.service "$DEST/etc/systemd/system/zenos-firstboot-tty.service"
install -m 0644 overlay/etc/zenos-release "$DEST/etc/zenos-release"
install -m 0644 overlay/usr/share/applications/*.desktop "$DEST/usr/share/applications/"
chroot "$DEST" systemctl enable zenos-firstboot-tty.service
