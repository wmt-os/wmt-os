#!/bin/bash
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

# REQUIRES: arch-test binfmt-support debian-archive-keyring mmdebstrap qemu-user-binfmt

set -eu
. "$(dirname "$0")/lib.sh"

case $PROFILE in standard|desktop) ;; *) log ERROR "Unknown profile: $PROFILE"; exit 1 ;; esac

log INFO "Bootstrapping rootfs ($PROFILE)"

ROOTFS_DIR="$BUILD_DIR/rootfs-$PROFILE"
rm -rf "$ROOTFS_DIR" "$ROOTFS_DIR.tmp"

# Derive the metapackage name from the kernel release
KERNEL_META="linux-image-$(make -s -C "$KERNEL_DIR" kernelrelease LOCALVERSION= | cut -d- -f2-)"

PACKAGES="$EXTRA_PACKAGES $KERNEL_META wmt-os-base"
[ "$PROFILE" = desktop ] && PACKAGES="$PACKAGES $DESKTOP_PACKAGES"

cd "$BASE_DIR"

# The device's own sources are placed ahead of the update, so bootstrap and
# device resolve identically; apt-build.pref orders them local > archive >
# Debian. sources.list carries only the local repo and is removed once done
mmdebstrap \
	--variant=standard \
	--include="${PACKAGES// /,}" \
	--architectures=armel \
	--setup-hook='cp -r overlays/rootfs-base/. "$1"/' \
	--setup-hook='if [ -d "overlays/rootfs-$PROFILE" ]; then cp -r "overlays/rootfs-$PROFILE/." "$1"/; fi' \
	--setup-hook='install -Dm644 bootstrap/apt-build.pref "$1"/etc/apt/preferences.d/apt-build.pref' \
	--setup-hook='install -Dm644 packages/wmt-os-base/wmt.sources "$1"/etc/apt/sources.list.d/wmt.sources' \
	--customize-hook='chroot "$1" /bin/sh < bootstrap/hooks-base.sh' \
	--customize-hook='if [ -e "bootstrap/hooks-$PROFILE.sh" ]; then chroot "$1" /bin/sh < "bootstrap/hooks-$PROFILE.sh"; fi' \
	--customize-hook='rm -f "$1"/etc/apt/sources.list "$1"/etc/apt/preferences.d/apt-build.pref' \
	trixie \
	"$ROOTFS_DIR.tmp" \
	"deb [trusted=yes] copy://$BUILD_DIR/debs ./"

mv "$ROOTFS_DIR.tmp" "$ROOTFS_DIR"
log OK "Rootfs ready: $ROOTFS_DIR"
