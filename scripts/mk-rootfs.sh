#!/bin/bash
# REQUIRES: binfmt-support debian-archive-keyring mmdebstrap qemu-user-binfmt
set -e
source "$(dirname "$0")/common.sh"

log INFO "Bootstrapping rootfs ($PROFILE)"

ROOTFS_DIR="$BUILD_DIR/rootfs"
rm -rf "$ROOTFS_DIR"

PACKAGES="$DEBIAN_EXTRA_PACKAGES $PACKAGE_NAME"
[ "$PROFILE" = desktop ] && PACKAGES="$PACKAGES $DEBIAN_DESKTOP_PACKAGES"

cd "$BASE_DIR"

# Install from the local repo; ship config/sources, drop the bootstrap list
mmdebstrap \
	--variant=standard \
	--include="${PACKAGES// /,}" \
	--architectures=armel \
	--components="$DEBIAN_COMPONENTS" \
	--setup-hook='cp -r config/overlay/. "$1"/' \
	--customize-hook='chroot "$1" /bin/sh < config/rootfs-hooks.sh' \
	--customize-hook='rm -f "$1"/etc/apt/sources.list; cp -r config/sources/. "$1"/etc/apt/' \
	trixie \
	"$ROOTFS_DIR" \
	"deb [trusted=yes] copy://$BUILD_DIR/debs ./" \
	"$DEBIAN_MIRROR"

log INFO "Allocating swapfile"
dd if=/dev/zero of="$ROOTFS_DIR/swapfile" bs=1M count=256 conv=fsync status=none
chmod 600 "$ROOTFS_DIR/swapfile"
mkswap "$ROOTFS_DIR/swapfile" > /dev/null

log OK "Rootfs ready"
