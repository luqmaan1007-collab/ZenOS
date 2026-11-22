# Validation checklist

## CI
- [ ] x86-64 Archiso job completes and uploads exactly one ISO.
- [ ] ARM64 rootfs job completes and uploads a rootfs archive.
- [ ] Verify artifact checksums and archive contents.
- [ ] Confirm all systemd units and scripts have expected executable permissions.

## x86-64 VM
- [ ] UEFI boot and legacy BIOS boot
- [ ] SDDM, Plasma Wayland and X11 fallback (if installed)
- [ ] First-boot account creation and sudo
- [ ] Ethernet, Wi-Fi, Bluetooth, audio and browser networking
- [ ] Discover/Flatpak install and update
- [ ] AppImage and Wine smoke tests
- [ ] Installer in a disposable virtual disk

## ARM64 device
- [ ] Named board and revision recorded
- [ ] Bootloader, firmware, kernel and device tree verified
- [ ] Display/GPU, storage, USB, network, Wi-Fi, Bluetooth and audio tested
- [ ] Suspend/resume and thermal/power behavior tested

Never mark a platform supported from a successful package build alone.
