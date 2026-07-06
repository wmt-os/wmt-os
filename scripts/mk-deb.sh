#!/bin/bash
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

# REQUIRES: bc bison build-essential debhelper dpkg-dev fakeroot flex gcc-arm-linux-gnueabi kmod libc6-dev-armel-cross libssl-dev rsync

set -eu
. "$(dirname "$0")/lib.sh"

cd "$KERNEL_DIR"

STAMP=$(date +%s)
export STAMP

# Content id: sha256 of HEAD, the dirty diff, .config, and the cross compile flags;
# a dirty tree marks the id, and the publisher refuses dirty builds
commit=$(git rev-parse --verify HEAD)
git --no-optional-locks diff --quiet HEAD && dirty= || dirty=-dirty
ID=$({ printf '%s\n' "$commit"; git --no-optional-locks diff HEAD; cat .config; \
	printf '%s\n' "$ARCH" "$CROSS_COMPILE" "$KCFLAGS"; } | sha256sum | cut -c1-12)$dirty

# The id is appended to the release, so distinct kernels co-install under their own /lib/modules
RELEASE=$(make -s kernelrelease LOCALVERSION=-$ID)
KERNEL_PKG="linux-image-$RELEASE"

# Stamp is apt's upgrade counter; the kernel's identity is already in the name
KERNEL_VERSION="$STAMP"

export DEBFULLNAME="$BUILDER_NAME" DEBEMAIL="$BUILDER_EMAIL"
export KBUILD_BUILD_VERSION=1 # deterministic uname -v '#1'

DEBS="$BUILD_DIR/debs"
mkdir -p "$DEBS"
rm -f "$DEBS"/*.deb "$DEBS"/Packages.gz

log INFO "Building $KERNEL_PKG ($KERNEL_VERSION) with bindeb-pkg"
# -j1: parallel dtbs_install races on install -d. DPKG_FLAGS=-d skips the target-arch
# build-dep check (cross-building); KBUILD_BUILD_TIMESTAMP bakes STAMP as uname -v's date
make -j1 bindeb-pkg KBUILD_DEBARCH=armel KDEB_PKGVERSION="$KERNEL_VERSION" LOCALVERSION=-$ID \
	KBUILD_BUILD_TIMESTAMP="$(LC_ALL=C date -d @$STAMP)" DPKG_FLAGS=-d
# Keep only the image deb; discard the headers/libc-dev/changes/buildinfo beside it
mv "$BASE_DIR/${KERNEL_PKG}_${KERNEL_VERSION}_"*.deb "$DEBS/"
rm -f "$BASE_DIR"/linux-headers-*.deb "$BASE_DIR"/linux-libc-dev_*.deb \
	"$BASE_DIR"/linux-upstream_*.buildinfo "$BASE_DIR"/linux-upstream_*.changes

"$BASE_DIR/packages/wmt-boot/build-deb.sh"
"$BASE_DIR/packages/wmt-os-base/build-deb.sh"

# The meta's key is its control hash, so it changes exactly when its kernel does
meta_control=$(cat <<EOF
Package: $PACKAGE_NAME
Architecture: armel
Maintainer: $BUILDER_NAME <$BUILDER_EMAIL>
Section: kernel
Priority: optional
Depends: $KERNEL_PKG, wmt-boot
Description: Linux kernel for the WonderMedia WM8505 (metapackage)
 Depends on the latest WM8505 kernel and its boot integration.
EOF
)
META_VERSION="$STAMP+$(printf '%s\n' "$meta_control" | sha256sum | cut -c1-12)"

log INFO "Building $PACKAGE_NAME metapackage ($META_VERSION)"
staging=$(mktemp -d)
mkdir -p "$staging/DEBIAN"
printf '%s\nVersion: %s\n' "$meta_control" "$META_VERSION" > "$staging/DEBIAN/control"
dpkg-deb --root-owner-group --build "$staging" "$DEBS/${PACKAGE_NAME}_${META_VERSION}_armel.deb" >/dev/null
rm -rf "$staging"

log INFO "Indexing local repository"
cd "$DEBS"
dpkg-scanpackages --multiversion . /dev/null | gzip -9c > Packages.gz
log OK "Local repository ready at $DEBS"
