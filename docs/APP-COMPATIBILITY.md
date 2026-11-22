# Application compatibility policy

ZenOS is a Linux distribution. It cannot make binaries for another operating system universally compatible.

- Arch packages: install through pacman or Discover/PackageKit. The zenos-app helper can install local .pkg.tar.zst, .pkg.tar.xz and .pkg.tar.gz archives with administrator approval.
- Flatpak: preferred cross-distribution desktop app format; Discover is the graphical frontend.
- AppImage: executable container; host FUSE and shared-library requirements still apply.
- Windows EXE/MSI: the zenos-app helper launches EXE files with Wine and MSI files with Wine msiexec. Wine is a compatibility layer, not a full Windows installation. DirectX, anti-cheat, drivers and DRM may prevent applications from working.
- Android APK: Waydroid requires compatible kernel features, graphics, binder support and a working container/session. It is optional and may not work on every ARM board.
- macOS DMG/APP: these contain macOS filesystem layouts and Mach-O binaries/frameworks. They are not Linux application packages and cannot be installed as native Linux applications. Use a Linux release or web app.
- Debian DEB and RPM: not native package formats on Arch; use Flatpak or an Arch package where available.

The software center should only advertise formats that have a tested installation path on the current device.
