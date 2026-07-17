#!/bin/sh
set -e

# ---- Defaults ----

# Yescrypt takes multiple seconds per password check; hash with SHA-512 instead
perl -pi -e 's/\byescrypt\b/sha512/ and $m++; END { exit !$m }' /etc/pam.d/common-password
perl -pi -e 's/^ENCRYPT_METHOD YESCRYPT$/ENCRYPT_METHOD SHA512/ and $m++; END { exit !$m }' /etc/login.defs

# Debian signs regulatory.db for their kernel; ours only trusts the upstream key
update-alternatives --set regulatory.db /lib/firmware/regulatory.db-upstream

# Keep networkd's wait-online from stalling boot; NetworkManager owns networking
systemctl mask systemd-networkd-wait-online.service

# Disable suspend targets; the hardware cannot resume
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# ---- First-Boot Reset ----

# Keep systemd-firstboot from running; wmt-firstboot handles setup
systemctl mask systemd-firstboot.service

# Remove the Dropbear host keys; first boot regenerates them
rm -f /etc/dropbear/dropbear_*_host_key*

# Remove build host identity; trigger ConditionFirstBoot
rm -f /etc/machine-id /etc/hostname /etc/resolv.conf
