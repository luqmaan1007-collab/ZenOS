# ZenOS release roadmap

## Engineering preview
- [x] Arch Linux desktop baseline and remote build definitions
- [x] Firefox, Discover, Flatpak, networking, audio, Bluetooth and printing package selection
- [x] Initial ZenGlass KDE color scheme and KWin blur configuration
- [x] First-boot local administrator account prompt (requires boot validation)
- [x] Format-aware application launcher for Flatpak, AppImage, Wine and optional Waydroid
- [ ] Run and fix the first x86-64 and ARM64 GitHub Actions builds
- [ ] Boot the x86-64 ISO in UEFI and BIOS virtual machines

## Stable release blockers
- [ ] Choose and validate named ARM64 devices; publish board-specific images only
- [ ] Replace upstream guided installer with a branded, tested installer workflow
- [ ] Secure update repository, package signing, verified updates and rollback
- [ ] Recovery environment and disk/boot repair tooling
- [ ] Full disk encryption setup and recovery-key UX
- [ ] Accessibility, localization, screen reader and input-method validation
- [ ] Power, suspend/resume, GPU acceleration, Wi-Fi and Bluetooth hardware matrix
- [ ] Security review, threat model and reproducible-build process
- [ ] Automated installer and upgrade tests

A checkbox is not evidence of a passing test. Build and hardware status must be recorded from actual CI logs and device tests.
