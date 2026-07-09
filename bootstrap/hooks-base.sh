#!/bin/sh
set -e

# ---- Defaults ----

sed -i '/^LOGIN_TIMEOUT/s/[0-9]\+/180/' /etc/login.defs
update-alternatives --set regulatory.db /lib/firmware/regulatory.db-upstream

# ---- First-boot reset ----

systemctl mask systemd-firstboot.service systemd-networkd-wait-online.service
rm -f /etc/dropbear/dropbear_*_host_key*
rm -f /etc/machine-id /etc/hostname /etc/resolv.conf
