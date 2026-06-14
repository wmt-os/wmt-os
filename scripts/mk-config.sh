#!/bin/bash
# REQUIRES: bison build-essential flex gcc-arm-linux-gnueabi lynx wget
set -e
source "$(dirname "$0")/common.sh"

log INFO "Generating kernel config"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

log INFO "Downloading Debian config"
DEB_URL=$(lynx -dump -listonly -nonumbers "$DEBIAN_CONFIG_POOL" | grep "$DEBIAN_CONFIG_PATTERN" | tail -n 1)
if [ -z "$DEB_URL" ]; then
    log ERROR "Failed to find Debian config matching $DEBIAN_CONFIG_PATTERN"
    exit 1
fi
wget -q -O "$tmp/config.deb" "$DEB_URL"
ar p "$tmp/config.deb" data.tar.xz | tar -xOJf - "$DEBIAN_CONFIG_FILE" | unxz > "$tmp/config.debian"

log INFO "Merging config"
cd "$KERNEL_DIR"
# Resolve the seed on its own and snapshot the resulting enabled options
cp "$BASE_DIR/config/kernel-seed.config" .config
make olddefconfig
grep -E '=(y|m)$' .config > "$tmp/seed.defconfig"

# Merge the Debian base under the seed, re-assert the snapshot, then finalize
scripts/kconfig/merge_config.sh -m "$tmp/config.debian" "$BASE_DIR/config/kernel-seed.config"
scripts/kconfig/merge_config.sh -m .config "$tmp/seed.defconfig"
make olddefconfig

log OK "Config ready"
