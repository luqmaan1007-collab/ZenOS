# ARM64 targets

ZenOS publishes two ARM64 artifacts:

- `zenos-aarch64-rootfs.tar.gz`: the installed root filesystem for developers and board integrators.
- `zenos-aarch64-uefi.img.zst`: a generic GPT disk image with a FAT EFI system partition, ext4 root partition and GRUB's ARM64 UEFI removable-media boot path.

## UEFI image compatibility

The disk image targets standard ARM64 UEFI computers that can boot a removable-media EFI application and provide the platform interfaces expected by the generic mainline ARM64 kernel. It is not certified for all ARM64 computers.

It is not a Raspberry Pi image and is not a universal single-board-computer image. Raspberry Pi, Rockchip, Amlogic, Qualcomm and Chromebook devices may need board-specific firmware, bootloader stages, device trees, kernel packages, firmware and partition layouts.

The generic Arch Linux ARM base includes preset credentials and services. The ZenOS build locks the root account, removes the preset alarm account, disables the default SSH/networkd/resolved services and uses a first-boot account prompt instead. SSH is not enabled by default.

## Flashing and testing

The image is an engineering preview. Verify the compressed artifact checksum, decompress it, and test it on a spare ARM64 UEFI device or virtual machine before considering installation. Writing a disk image overwrites the selected target drive. Do not use a drive containing important data.

Secure Boot signing, full-disk encryption, update rollback, recovery and hardware certification are not complete.
