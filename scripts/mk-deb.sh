#!/bin/bash
# REQUIRES: bc bison build-essential debhelper dpkg-dev fakeroot flex gcc-arm-linux-gnueabi kmod libssl-dev rsync
set -eu
. "$(dirname "$0")/lib.sh"
. "$BASE_DIR/config"

cd "$KERNEL_DIR"

WMTBOOT_HASH=$(cat "$BASE_DIR"/packages/wmt-boot/* | sha256sum | cut -c1-12)
STAMP=$(date +%s)

# Content id: sha256 of HEAD, the dirty tree, .config, and the cross compile flags.
commit=$(git rev-parse --verify HEAD)
dirty=$(git --no-optional-locks status --porcelain -uno)
ID=$({ printf '%s\n' "$commit" "$dirty"; cat .config; \
	printf '%s\n' "$ARCH" "$CROSS_COMPILE" "$KCFLAGS"; } | sha256sum | cut -c1-12)

# The id is appended to the release, so distinct kernels co-install under their own /lib/modules
RELEASE=$(make -s kernelrelease LOCALVERSION=-$ID)
KERNEL_PKG="linux-image-$RELEASE"

# Stamp is apt's upgrade counter and the sole leading numeric run, so rebuilds sort monotonically.
# Kernel + meta: identity is in the name/Depends, so the deb version is just the stamp.
# wmt-boot: stamp then content hash (the hash must stay after the stamp, or dpkg's leading-numeric
# compare follows the hash, not time -> non-monotonic).
KERNEL_VERSION="$STAMP"
META_VERSION="$STAMP"
WMTBOOT_VERSION="$STAMP+$WMTBOOT_HASH"

export DEBFULLNAME="$BUILDER_NAME" DEBEMAIL="$BUILDER_EMAIL"

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

log INFO "Building wmt-boot ($WMTBOOT_VERSION)"
staging=$(mktemp -d)
install -Dm755 "$BASE_DIR/packages/wmt-boot/deploy" "$staging/usr/sbin/wmt-deploy-boot"
install -Dm755 "$BASE_DIR/packages/wmt-boot/kernel-postinst" "$staging/etc/kernel/postinst.d/zz-wmt-boot"
install -Dm755 "$BASE_DIR/packages/wmt-boot/kernel-postrm" "$staging/etc/kernel/postrm.d/zz-wmt-boot"
install -Dm644 "$BASE_DIR/packages/wmt-boot/uboot.cmd" "$staging/usr/share/wmt-boot/uboot.cmd"
install -Dm755 "$BASE_DIR/packages/wmt-boot/postinst" "$staging/DEBIAN/postinst"
install -Dm644 "$BASE_DIR/packages/wmt-boot/triggers" "$staging/DEBIAN/triggers"
cat > "$staging/DEBIAN/control" <<EOF
Package: wmt-boot
Version: $WMTBOOT_VERSION
Architecture: all
Maintainer: $BUILDER_NAME <$BUILDER_EMAIL>
Section: kernel
Priority: optional
Depends: u-boot-tools
Description: WonderMedia WM8505 boot integration
 Builds each kernel's U-Boot boot image, keeping the previous one as a rollback.
EOF
dpkg-deb --root-owner-group --build "$staging" "$DEBS/wmt-boot_${WMTBOOT_VERSION}_all.deb" >/dev/null
rm -rf "$staging"

log INFO "Building $PACKAGE_NAME metapackage ($META_VERSION)"
staging=$(mktemp -d)
mkdir -p "$staging/DEBIAN"
cat > "$staging/DEBIAN/control" <<EOF
Package: $PACKAGE_NAME
Version: $META_VERSION
Architecture: armel
Maintainer: $BUILDER_NAME <$BUILDER_EMAIL>
Section: kernel
Priority: optional
Depends: $KERNEL_PKG, wmt-boot
Description: Linux kernel for the WonderMedia WM8505 (metapackage)
 Depends on the latest WM8505 kernel and its boot integration.
EOF
dpkg-deb --root-owner-group --build "$staging" "$DEBS/${PACKAGE_NAME}_${META_VERSION}_armel.deb" >/dev/null
rm -rf "$staging"

log INFO "Indexing local repository"
cd "$DEBS"
dpkg-scanpackages --multiversion . /dev/null | gzip -9c > Packages.gz
log OK "Local repository ready at $DEBS"
