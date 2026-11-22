# ZenOS

ZenOS is an Arch Linux-based desktop distribution project targeting x86-64 PCs and ARM64 devices. Its design goal is a polished, translucent Liquid Glass desktop with a complete everyday desktop stack.

> **Status: engineering preview.** A successful CI build is not proof of hardware compatibility or production readiness. ARM64 is built as a generic root filesystem until a specific board and boot firmware are selected and tested.

## Current design

- KDE Plasma 6 desktop, Wayland session, SDDM, custom ZenOS translucent color scheme and desktop styling.
- Firefox browser, Dolphin file manager, Konsole terminal, Discover software center.
- Arch packages through pacman; Flatpak/Flathub; AppImage; Windows applications through Wine (compatibility varies).
- Optional Android APK support through Waydroid on compatible kernels and hardware.
- NetworkManager, Wi-Fi tooling, Bluetooth/BlueZ, PipeWire audio, printing, power profiles, portals, firewall and firmware tools.
- Remote GitHub Actions builds for x86-64 live ISO and ARM64 root filesystem archive.

## Application formats

| Format | ZenOS handling |
|---|---|
| .pkg.tar.zst | Native Arch package via pacman |
| Flatpak / .flatpakref | Native via Flatpak and Discover |
| .AppImage | Launch with FUSE/runtime dependencies as required |
| .exe | Wine; Windows compatibility is application-specific |
| .apk | Optional Waydroid; requires compatible kernel, graphics and session |
| .dmg / .app | macOS application binaries are not Linux binaries; not natively installable |
| .deb / .rpm | Not native; prefer a Flatpak or Arch package |

No compatibility layer can guarantee that every Windows or Android app works. ZenOS will never label an unsupported format as natively supported.

## Build

1. Open **Actions → Build ZenOS**.
2. Run the workflow on main.
3. Download the zenos-x86_64-iso and zenos-aarch64-rootfs artifacts.

The builds run on GitHub-hosted runners. The ARM archive is a root filesystem, **not a universal bootable image**. A bootable ARM image needs a named target board, matching bootloader, kernel, device tree, firmware, partition layout and hardware tests.

## Development status

The project includes build automation and a desktop baseline. It is not yet a finished consumer OS. Before a stable release, the project still needs repeatable build validation, a secure first-boot account flow, installer UX, signed updates and rollback, recovery tooling, accessibility/localization review, security audits, and boot tests on named x86-64 and ARM64 hardware.

Test in a virtual machine or spare device first. Back up important data. Installation can erase disks.

## License

MIT for original project code. Individual packages, themes, codecs and applications retain their own licenses.