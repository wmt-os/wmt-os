#!/bin/sh
set -e

log() {
    echo "$(tput setaf 6)[INFO]$(tput sgr0) $1"
}

log "Extend the login timeout for the busy first boot"
sed -i '/^LOGIN_TIMEOUT/s/60/300/' /etc/login.defs

log "Use upstream regulatory.db"
update-alternatives --set regulatory.db /lib/firmware/regulatory.db-upstream

log "Remove Dropbear host keys (regenerated on first boot)"
rm -f /etc/dropbear/dropbear_*_host_key*

log "Mask interactive firstboot and networkd wait-online"
systemctl mask systemd-firstboot.service systemd-networkd-wait-online.service

log "Reset build-host identity for first boot"
rm -f /etc/machine-id /etc/hostname

exit 0
