# ZenOS architecture

## Distribution model

ZenOS is a curated Arch Linux-based distribution, not a new kernel or an independent Unix implementation. It uses the Linux kernel, systemd, pacman and KDE Plasma, then adds ZenOS configuration, desktop defaults, first-boot behavior, application helpers and build automation.

## x86-64 live system

- Archiso creates a bootable live ISO.
- The image includes Linux, firmware, KDE Plasma 6, SDDM and a Wayland session.
- The live image carries the ZenGlass wallpaper, color scheme, KWin blur defaults, GTK dark defaults and application launchers.
- A first-boot account service creates the local administrator before the graphical login.
- The guided installer currently launches upstream archinstall; it is not yet a custom branded installer.

## ARM64 targets

- The rootfs job installs the Arch Linux ARM AArch64 base, mainline kernel, firmware and the ZenOS desktop stack.
- The UEFI image builder partitions a raw disk image into a FAT EFI system partition and ext4 root partition, installs GRUB's ARM64 EFI loader and writes a root-UUID-based boot entry.
- The generic image is intended for standard ARM64 UEFI computers. SBCs require per-board boot configuration, device trees and firmware.

## Desktop and services

KDE Plasma provides the shell, settings, panels, notifications, file manager integration and session management. Firefox is the browser; Discover with PackageKit and Flatpak is the software center. NetworkManager manages wired and wireless networking, BlueZ provides Bluetooth, PipeWire provides audio, CUPS provides printing, firewalld provides the host firewall, and systemd-timesyncd provides network time synchronization.

## Application compatibility

Native software uses pacman/Discover or Flatpak. AppImage is launched directly. Wine is used for Windows EXE/MSI applications on x86-64 where compatible; it is not included in the ARM64 image. Waydroid is optional for APKs and requires kernel and graphics support. macOS DMG/APP binaries are not Linux executables and are not natively supported.

## Build pipeline

GitHub Actions validates shell syntax, then builds the x86-64 ISO and ARM64 rootfs/UEFI image on hosted runners. Artifacts are engineering previews until boot-tested. CI success alone does not certify hardware support.
