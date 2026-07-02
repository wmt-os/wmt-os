#!/bin/bash
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

# REQUIRES: bison build-essential flex gcc-arm-linux-gnueabi lynx wget

set -eu
. "$(dirname "$0")/lib.sh"

CONFIG_POOL="https://ftp.debian.org/debian/pool/main/l/linux/"
CONFIG_PATTERN="linux-config-6.12_.*_armel\.deb$"
CONFIG_FILE="./usr/src/linux-config-6.12/config.armel_none_rpi.xz"

log INFO "Generating kernel config"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

log INFO "Downloading Debian config"
DEB_URL=$(lynx -dump -listonly -nonumbers "$CONFIG_POOL" | grep "$CONFIG_PATTERN" | tail -n 1)
[ -n "$DEB_URL" ] || { log ERROR "Failed to find Debian config"; exit 1; }
wget -q -O "$tmp/config.deb" "$DEB_URL"
ar p "$tmp/config.deb" data.tar.xz | tar -xOJf - "$CONFIG_FILE" | unxz > "$tmp/config.debian"

log INFO "Merging config"
cd "$KERNEL_DIR"
# Snapshot the seed's enabled options after dependency resolution, to re-assert below
cp "$BASE_DIR/kernel-seed.config" .config
make olddefconfig
grep -E '=(y|m)$' .config > "$tmp/seed.defconfig"

# Merge the Debian base under the seed, re-assert the snapshot, then finalize
scripts/kconfig/merge_config.sh -m "$tmp/config.debian" "$BASE_DIR/kernel-seed.config" "$tmp/seed.defconfig"
make olddefconfig

log OK "Config ready"
