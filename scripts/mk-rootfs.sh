#!/bin/bash
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

# REQUIRES: arch-test binfmt-support debian-archive-keyring mmdebstrap qemu-user-binfmt

set -eu
. "$(dirname "$0")/lib.sh"

case $PROFILE in standard|desktop) ;; *) log ERROR "Unknown profile: $PROFILE"; exit 1 ;; esac

log INFO "Bootstrapping rootfs ($PROFILE)"

ROOTFS_DIR="$BUILD_DIR/rootfs"
rm -rf "$ROOTFS_DIR"

PACKAGES="$EXTRA_PACKAGES $PACKAGE_NAME wmt-os-base"
[ "$PROFILE" = desktop ] && PACKAGES="$PACKAGES $DESKTOP_PACKAGES"

cd "$BASE_DIR"

# Resolve against the local debs, Debian, and the live archive; apt-build.pref
# orders them (local > archive > Debian) until the real sources land. Bootstrap
# apt runs host-side, so signed-by names the in-tree keyring
mmdebstrap \
	--variant=standard \
	--include="${PACKAGES// /,}" \
	--architectures=armel \
	--components="$DEBIAN_COMPONENTS" \
	--setup-hook='cp -r overlays/rootfs/. "$1"/' \
	--setup-hook='install -Dm644 bootstrap/apt-build.pref "$1"/etc/apt/preferences.d/apt-build.pref' \
	--customize-hook='chroot "$1" /bin/sh < bootstrap/hooks.sh' \
	--customize-hook='rm -f "$1"/etc/apt/sources.list "$1"/etc/apt/preferences.d/apt-build.pref; cp -r bootstrap/sources/. "$1"/etc/apt/' \
	trixie \
	"$ROOTFS_DIR" \
	"deb [trusted=yes] copy://$BUILD_DIR/debs ./" \
	"$DEBIAN_MIRROR" \
	"deb [signed-by=$BASE_DIR/packages/wmt-os-base/wmt-os.pgp] $WMT_MIRROR trixie main"

log OK "Rootfs ready: $ROOTFS_DIR"
