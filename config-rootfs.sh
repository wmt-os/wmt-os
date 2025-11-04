#!/bin/sh
set -e

log() {
    echo "$(tput setaf 6)[INFO]$(tput sgr0) $1"
}

log "Extend login timeout"
sed -i '/^LOGIN_TIMEOUT/s/60/300/' /etc/login.defs

log "Use upstream regulatory.db"
update-alternatives --set regulatory.db /lib/firmware/regulatory.db-upstream

log "Remove Dropbear SSH keys"
rm /etc/dropbear/dropbear_*_host_key*

log "Trigger systemd-firstboot"
rm /etc/machine-id /etc/hostname

exit 0
