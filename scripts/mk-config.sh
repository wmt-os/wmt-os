#!/bin/bash
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

# REQUIRES: bison build-essential debian-archive-keyring devscripts flex gcc-arm-linux-gnueabi

set -eu
. "$(dirname "$0")/lib.sh"

CONFIG_PKG="linux-config-6.12"
CONFIG_FILE="./usr/src/linux-config-6.12/config.armel_none_rpi.xz"

log INFO "Generating kernel config"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

log INFO "Downloading Debian config"
# chdist fetches the newest revision against Packages-only sources derived from the overlay's own
chdist -d "$tmp" -a armel create debian > /dev/null
awk -v RS= -v ORS='\n\n' '{sub(/Components:[^\n]*/, "Components: main"); print $0 "\nTargets: Packages"}' \
	"$BASE_DIR/overlays/rootfs/etc/apt/sources.list.d/debian.sources" > "$tmp/debian/etc/apt/sources.list.d/debian.sources"
chdist -d "$tmp" apt-get debian -qq update
(cd "$tmp" && chdist -d "$tmp" apt-get debian -qq download "$CONFIG_PKG")
dpkg-deb --fsys-tarfile "$tmp/$CONFIG_PKG"_*_armel.deb | tar -xOf - "$CONFIG_FILE" | unxz > "$tmp/config.debian"

log INFO "Merging config"
cd "$KERNEL_DIR"
# Snapshot the seed's enabled options after dependency resolution, to re-assert below
cp "$BASE_DIR/kernel-seed.config" "$tmp/.config"
make KCONFIG_CONFIG="$tmp/.config" olddefconfig
grep -E '=(y|m)$' "$tmp/.config" > "$tmp/seed.defconfig"

# Merge the Debian base under the seed, re-assert the snapshot, then finalize
scripts/kconfig/merge_config.sh -m -O "$tmp" "$tmp/config.debian" "$BASE_DIR/kernel-seed.config" "$tmp/seed.defconfig"
make KCONFIG_CONFIG="$tmp/.config" olddefconfig

# Replace existing config only on real changes
cmp -s "$tmp/.config" .config || mv "$tmp/.config" .config

log OK "Config ready"
