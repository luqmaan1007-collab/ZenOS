# Testing and installation

## Recommended first test

Use a disposable virtual machine first. Allocate at least 4 GB RAM and 30 GB virtual disk for the x86-64 ISO test. Do not attach a physical disk containing important data.

1. Download the `zenos-x86_64-iso` artifact from a successful GitHub Actions run.
2. Create a new UEFI virtual machine and attach the ISO.
3. Boot the live environment and complete the first-boot account prompt.
4. Check Plasma, Firefox, Discover, network, audio, Bluetooth and printing.
5. If testing the installer, use only the VM's disposable virtual disk.

## ARM64 UEFI image

The `zenos-aarch64-uefi-image` artifact is Zstandard-compressed. Decompress it before writing it to a test drive. Writing a raw image overwrites the selected drive. Verify the target device carefully and use only a spare drive.

This image is for standard ARM64 UEFI computers. It is not for Raspberry Pi or arbitrary ARM single-board computers.

## Artifacts

- `zenos-x86_64-iso`: x86-64 live ISO
- `zenos-aarch64-rootfs`: ARM64 root filesystem archive
- `zenos-aarch64-uefi-image`: generic ARM64 UEFI disk image
