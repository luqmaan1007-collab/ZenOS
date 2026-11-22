#!/usr/bin/env bash
set -euo pipefail
ROOTFS=${1:?Usage: build-uefi-image.sh ROOTFS_DIR OUTPUT.img.zst}
OUTPUT=${2:?Usage: build-uefi-image.sh ROOTFS_DIR OUTPUT.img.zst}
[[ $EUID -eq 0 ]] || { echo "Run as root (the workflow uses sudo)." >&2; exit 1; }
for cmd in losetup parted partprobe udevadm mkfs.fat mkfs.ext4 rsync blkid zstd; do
  command -v "$cmd" >/dev/null || { echo "Missing build dependency: $cmd" >&2; exit 1; }
done
[[ -d "$ROOTFS/boot" ]] || { echo "Root filesystem has no /boot directory." >&2; exit 1; }
KERNEL="$ROOTFS/boot/Image"
INITRD="$ROOTFS/boot/initramfs-linux.img"
[[ -s "$KERNEL" ]] || { echo "Expected EFI-stubbed ARM64 kernel at $KERNEL." >&2; exit 1; }
[[ -s "$INITRD" ]] || { echo "Expected initramfs at $INITRD." >&2; exit 1; }
mkdir -p "$(dirname "$OUTPUT")"
WORK="$(mktemp -d)"
RAW="$WORK/zenos-aarch64-uefi.img"
ROOT_MNT="$WORK/root"
ESP_MNT="$ROOT_MNT/boot"
LOOP=""
cleanup() {
  set +e
  mountpoint -q "$ROOT_MNT/dev/pts" && umount "$ROOT_MNT/dev/pts"
  mountpoint -q "$ROOT_MNT/dev" && umount "$ROOT_MNT/dev"
  mountpoint -q "$ROOT_MNT/proc" && umount "$ROOT_MNT/proc"
  mountpoint -q "$ROOT_MNT/sys" && umount "$ROOT_MNT/sys"
  mountpoint -q "$ESP_MNT" && umount "$ESP_MNT"
  mountpoint -q "$ROOT_MNT" && umount "$ROOT_MNT"
  [[ -n "$LOOP" ]] && losetup -d "$LOOP"
  rm -rf "$WORK"
}
trap cleanup EXIT
truncate -s 8G "$RAW"
LOOP="$(losetup --find --show --partscan "$RAW")"
parted -s "$LOOP" mklabel gpt
parted -s "$LOOP" mkpart ESP fat32 1MiB 513MiB
parted -s "$LOOP" set 1 esp on
parted -s "$LOOP" mkpart ROOT ext4 513MiB 100%
partprobe "$LOOP"
udevadm settle
ESP_DEV="${LOOP}p1"
ROOT_DEV="${LOOP}p2"
for _ in $(seq 1 20); do
  [[ -b "$ESP_DEV" && -b "$ROOT_DEV" ]] && break
  sleep 1
done
[[ -b "$ESP_DEV" && -b "$ROOT_DEV" ]] || { echo "Partition devices did not appear." >&2; exit 1; }
mkfs.fat -F 32 -n ZENOS_EFI "$ESP_DEV"
mkfs.ext4 -F -L ZENOS_ROOT "$ROOT_DEV"
mkdir -p "$ROOT_MNT"
mount "$ROOT_DEV" "$ROOT_MNT"
rsync -aHAX --numeric-ids "$ROOTFS/" "$ROOT_MNT/"
mount --bind /dev "$ROOT_MNT/dev"
mount --bind /dev/pts "$ROOT_MNT/dev/pts"
mount -t proc proc "$ROOT_MNT/proc"
mount -t sysfs sysfs "$ROOT_MNT/sys"
mkdir -p "$ESP_MNT"
mount "$ESP_DEV" "$ESP_MNT"
mkdir -p "$ESP_MNT/EFI/BOOT" "$ESP_MNT/zenos" "$ESP_MNT/grub"
install -m 0644 "$KERNEL" "$ESP_MNT/zenos/Image"
install -m 0644 "$INITRD" "$ESP_MNT/zenos/initramfs-linux.img"
ROOT_UUID="$(blkid -s UUID -o value "$ROOT_DEV")"
ESP_UUID="$(blkid -s UUID -o value "$ESP_DEV")"
[[ -n "$ROOT_UUID" && -n "$ESP_UUID" ]] || { echo "Could not read filesystem UUIDs." >&2; exit 1; }
cat > "$ROOT_MNT/etc/fstab" <<FSTAB
UUID=$ROOT_UUID / ext4 defaults,noatime 0 1
UUID=$ESP_UUID /boot vfat umask=0077 0 2
FSTAB
chroot "$ROOT_MNT" /bin/bash -euo pipefail -c 'command -v grub-install >/dev/null; grub-install --target=arm64-efi --efi-directory=/boot --boot-directory=/boot --removable --no-nvram --recheck'
cat > "$ESP_MNT/grub/grub.cfg" <<GRUB
set default=0
set timeout=5
insmod part_gpt
insmod fat
insmod ext2
search --no-floppy --fs-uuid --set=root $ESP_UUID
menuentry "ZenOS ARM64 UEFI" {
    linux /zenos/Image root=UUID=$ROOT_UUID rw rootwait
    initrd /zenos/initramfs-linux.img
}
GRUB
sync
umount "$ESP_MNT"
umount "$ROOT_MNT"
losetup -d "$LOOP"
LOOP=""
zstd -T0 -6 "$RAW" -o "$OUTPUT"
echo "Created generic ARM64 UEFI disk image: $OUTPUT"
