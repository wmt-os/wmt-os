#!/bin/sh
set -e

# Extend the login timeout
sed -i '/^LOGIN_TIMEOUT/s/60/180/' /etc/login.defs

# Use upstream regulatory.db
update-alternatives --set regulatory.db /lib/firmware/regulatory.db-upstream

# Default the desktop terminal to urxvt
[ -x /usr/bin/urxvt ] && update-alternatives --set x-terminal-emulator /usr/bin/urxvt

# Remove Dropbear host keys (regenerated on first boot)
rm -f /etc/dropbear/dropbear_*_host_key*

# Mask interactive firstboot and networkd wait-online
systemctl mask systemd-firstboot.service systemd-networkd-wait-online.service

# Reset build-host identity for first boot
rm -f /etc/machine-id /etc/hostname /etc/resolv.conf

exit 0
