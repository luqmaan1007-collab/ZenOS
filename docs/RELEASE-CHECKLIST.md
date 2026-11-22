# Stable release checklist

A release must not be marked stable until each relevant item has evidence attached.

- [ ] x86-64 Archiso workflow succeeds from a clean commit.
- [ ] ARM64 rootfs and UEFI image jobs succeed from a clean commit.
- [ ] x86-64 ISO boots in UEFI and BIOS virtual machines.
- [ ] ARM64 UEFI image boots on at least one named physical device.
- [ ] First-boot account setup succeeds and default accounts are absent.
- [ ] SDDM and Plasma start reliably after first boot.
- [ ] Wi-Fi, Ethernet, Bluetooth, audio, printing, storage and time sync tested.
- [ ] Discover, PackageKit and Flathub install/update tested.
- [ ] Wine and AppImage smoke tests completed.
- [ ] Installer tested on a disposable disk, including recovery from failure.
- [ ] Secure Boot, signed updates, rollback and recovery strategy reviewed.
- [ ] License notices and third-party attributions checked.
- [ ] Checksums published for every release artifact.

Never check an item merely because its package is installed. Record the device, firmware, test procedure and result.
