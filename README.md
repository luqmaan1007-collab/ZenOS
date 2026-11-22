# ZenOS

ZenOS is an Arch Linux-based desktop distribution project targeting x86-64 PCs and ARM64 devices. Its design goal is a polished, translucent Liquid Glass desktop with a complete everyday desktop stack.

> **Status: engineering preview.** A successful CI build is not proof of hardware compatibility or production readiness. ARM64 includes a generic UEFI-computer image and rootfs archive; single-board computers still need board-specific ports.

## Current design

- KDE Plasma 6 desktop, Wayland session, SDDM, Plasma Welcome, a custom ZenGlass wallpaper, Papirus icons, Noto fonts, a ZenOS Welcome hub, default ZenGlass colors, KWin blur settings and dark GTK defaults.
- Firefox browser, Dolphin file manager, Konsole terminal, Discover software center, Kate editor, Okular PDF viewer, calculator and MPV media player.
- Arch packages through pacman; Flatpak/Flathub; AppImage; Windows applications through Wine (compatibility varies).
- Optional Android APK support through Waydroid on compatible kernels and hardware.
- NetworkManager, Wi-Fi tooling, Bluetooth/BlueZ, PipeWire audio, printing, power profiles, portals, firewall and firmware tools.
- Remote GitHub Actions builds for x86-64 live ISO, ARM64 root filesystem archive and generic ARM64 UEFI disk image (compressed as `.img.zst`).

## Application formats

| Format | ZenOS handling |
|---|---|
| .pkg.tar.zst / .pkg.tar.xz | Native Arch package via pacman |
| Flatpak / .flatpakref | Native via Flatpak and Discover |
| .AppImage | Launch with FUSE/runtime dependencies as required |
| .exe / .msi | Wine on x86-64 only; Windows compatibility is application-specific |
| .apk | Optional Waydroid; requires compatible kernel, graphics and session |
| .dmg / .app | macOS application binaries are not Linux binaries; not natively installable |
| .deb / .rpm | Not native; prefer a Flatpak or Arch package |

No compatibility layer can guarantee that every Windows or Android app works. ZenOS will never label an unsupported format as natively supported.

## Build

1. Open **Actions → Build ZenOS**.
2. Run the workflow on main.
3. Download the zenos-x86_64-iso, zenos-aarch64-rootfs and zenos-aarch64-uefi-image artifacts.

The builds run on GitHub-hosted runners. The ARM UEFI image targets standard ARM64 UEFI computers; it is not a universal image for every ARM board. Raspberry Pi and other SBCs need a board-specific bootloader, kernel, device tree, firmware and partition layout.

## Development status

The project includes build automation, a desktop baseline, a first-boot account prompt and a generic ARM64 UEFI image builder. It is not yet a finished consumer OS. Before a stable release, the project still needs successful repeatable CI builds, first-boot and installer validation, a branded installer, signed updates and rollback, recovery tooling, accessibility/localization review, security audits, and boot tests on named x86-64 and ARM64 hardware.

Test in a virtual machine or spare device first. Back up important data. Installation can erase disks.

## License

MIT for original project code. Individual packages, themes, codecs and applications retain their own licenses.