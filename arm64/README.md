# ARM64 build target

The ARM job creates an Arch Linux ARM AArch64 root filesystem archive. It is not a universal SD-card image or a tested bootable image.

A bootable release must name a target board (for example, a specific UEFI ARM64 PC or a specific SBC revision), then add its boot firmware, bootloader, kernel package, device tree, firmware blobs, partition layout and installation instructions. Do not flash this rootfs archive directly to a disk.

The workflow runs on an ARM64 GitHub-hosted runner and performs an ARM-native chroot package install. Hardware validation remains outstanding.
