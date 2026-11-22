#!/usr/bin/env bash
iso_name="zenos"
iso_label="ZENOS_$(date +%Y%m)"
iso_publisher="ZenOS Project"
iso_application="ZenOS Arch Linux desktop preview"
iso_version="$(date +%Y.%m.%d)"
install_dir="zenos"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi-x64.systemd-boot.esp' 'uefi-x64.systemd-boot.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
)
