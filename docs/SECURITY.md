# Security status

## Implemented in the engineering preview

- ARM root password is locked during image construction.
- The upstream Arch Linux ARM `alarm` account is removed.
- Upstream SSH service/socket enablement is removed; SSH is not enabled by default.
- Upstream systemd-networkd/resolved enablement is removed when NetworkManager is selected.
- The first-boot flow creates a named local administrator with a password and sudo access.
- firewalld is enabled as the default host firewall.

## Not yet production-ready

- Secure Boot is not signed or enforced by ZenOS.
- There is no signed ZenOS package repository or verified atomic update mechanism.
- There is no tested update rollback or recovery environment.
- Full-disk encryption and recovery-key setup are not integrated into the installer.
- The first-boot flow and all image services still require boot testing and security review.

Do not expose an engineering-preview device to untrusted networks or store important data on it. Do not assume that an unsigned image provides Secure Boot protection.
