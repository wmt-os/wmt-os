#!/bin/bash
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

# REQUIRES: bc bison build-essential debhelper dpkg-dev fakeroot flex gcc-arm-linux-gnueabi kmod libc6-dev-armel-cross libssl-dev rsync

set -eu
. "$(dirname "$0")/lib.sh"

cd "$KERNEL_DIR"

STAMP=$(date +%s)
export STAMP

ID=$("$BASE_DIR/scripts/kernel-id.sh")

# Append the id to the release to give each kernel a unique identity
KERNEL_PKG="linux-image-$(make -s kernelrelease LOCALVERSION=-$ID)"

# Drop the version from the release to name the metapackage
KERNEL_META="linux-image-$(make -s kernelrelease LOCALVERSION= | cut -d- -f2-)"

# Stamp is apt's upgrade counter; the kernel's identity is already in the name
KERNEL_VERSION="$STAMP"

export DEBFULLNAME="$BUILDER_NAME" DEBEMAIL="$BUILDER_EMAIL"

DEBS="$BUILD_DIR/debs"
mkdir -p "$DEBS"
rm -f "$DEBS"/*.deb "$DEBS"/Packages.gz

# A failed build strands partial bindeb-pkg output in the repo root; remove it
trap '[ $? -eq 0 ] || rm -f "$BASE_DIR"/linux-*.deb "$BASE_DIR"/linux-upstream_*' EXIT

log INFO "Building $KERNEL_PKG ($KERNEL_VERSION)"
BUILD_TS=$(LC_ALL=C date -d @$STAMP) # baked in as uname -v's date

# Compile in parallel, then package serially: kbuild install targets race under -j
# DPKG_FLAGS=-d skips the target-arch build-dep check (cross-building)
make -j"$(nproc)" LOCALVERSION=-$ID KBUILD_BUILD_TIMESTAMP="$BUILD_TS"
make -j1 bindeb-pkg KBUILD_DEBARCH=armel KDEB_PKGVERSION="$KERNEL_VERSION" LOCALVERSION=-$ID \
	KBUILD_BUILD_TIMESTAMP="$BUILD_TS" DPKG_FLAGS=-d

# Keep only the image deb; discard the headers/libc-dev/changes/buildinfo beside it
mv "$BASE_DIR/${KERNEL_PKG}_${KERNEL_VERSION}_"*.deb "$DEBS/"
rm -f "$BASE_DIR"/linux-headers-*.deb "$BASE_DIR"/linux-libc-dev_*.deb \
	"$BASE_DIR"/linux-upstream_*.buildinfo "$BASE_DIR"/linux-upstream_*.changes

"$BASE_DIR/packages/wmt-boot/build-deb.sh"
"$BASE_DIR/packages/wmt-os-base/build-deb.sh"

# The meta's key is its control hash, so it changes exactly when its kernel does
meta_control=$(cat <<EOF
Package: $KERNEL_META
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

log INFO "Building $KERNEL_META metapackage ($META_VERSION)"
staging=$(mktemp -d)
mkdir -p "$staging/DEBIAN"
printf '%s\nVersion: %s\n' "$meta_control" "$META_VERSION" > "$staging/DEBIAN/control"
dpkg-deb --root-owner-group --build "$staging" "$DEBS/${KERNEL_META}_${META_VERSION}_armel.deb" >/dev/null
rm -rf "$staging"

log INFO "Indexing local repository"
cd "$DEBS"
dpkg-scanpackages --multiversion . /dev/null | gzip -9c > Packages.gz
log OK "Packages ready: $DEBS"
