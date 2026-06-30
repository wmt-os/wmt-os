#!/bin/bash
# REQUIRES: binfmt-support debian-archive-keyring mmdebstrap qemu-user-binfmt
set -eu
. "$(dirname "$0")/lib.sh"

log INFO "Bootstrapping rootfs ($PROFILE)"

ROOTFS_DIR="$BUILD_DIR/rootfs"
rm -rf "$ROOTFS_DIR"

PACKAGES="$DEBIAN_EXTRA_PACKAGES $PACKAGE_NAME"
[ "$PROFILE" = desktop ] && PACKAGES="$PACKAGES $DEBIAN_DESKTOP_PACKAGES"

cd "$BASE_DIR"

# Install from the local repo; ship bootstrap/sources, drop the bootstrap list
mmdebstrap \
	--variant=standard \
	--include="${PACKAGES// /,}" \
	--architectures=armel \
	--components="$DEBIAN_COMPONENTS" \
	--setup-hook='cp -r overlays/rootfs/. "$1"/' \
	--customize-hook='chroot "$1" /bin/sh < bootstrap/hooks.sh' \
	--customize-hook='rm -f "$1"/etc/apt/sources.list; cp -r bootstrap/sources/. "$1"/etc/apt/' \
	trixie \
	"$ROOTFS_DIR" \
	"deb [trusted=yes] copy://$BUILD_DIR/debs ./" \
	"$DEBIAN_MIRROR"

log INFO "Allocating swapfile"
dd if=/dev/zero of="$ROOTFS_DIR/swapfile" bs=1M count=256 conv=fsync status=none
chmod 600 "$ROOTFS_DIR/swapfile"
mkswap "$ROOTFS_DIR/swapfile" > /dev/null

log OK "Rootfs ready"
