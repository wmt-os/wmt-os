#!/bin/bash
# REQUIRES: bc bison build-essential debhelper dpkg-dev fakeroot flex gcc-arm-linux-gnueabi kmod libssl-dev rsync
set -eu
. "$(dirname "$0")/lib.sh"
. "$BASE_DIR/config"

cd "$KERNEL_DIR"

RELEASE=$(make -s kernelrelease)
KERNEL_PKG="linux-image-$RELEASE"
UPSTREAM=$(make -s kernelversion)
KCOMMIT=$(git rev-parse --short=12 HEAD 2>/dev/null || echo 0)

# Each package embeds a content id in its version so publish ships only real changes:
# kernel = hash(.config + cross flags); metapackage = tracked commit; wmt-boot = hash(files).
CONFIGHASH=$({ cat .config; printf '%s\n' "$ARCH" "$CROSS_COMPILE" "$KCFLAGS"; } | sha256sum | cut -c1-12)
WMTBOOT_HASH=$(cat "$BASE_DIR"/packages/wmt-boot/* | sha256sum | cut -c1-12)
STAMP=$(date -u +%Y%m%d%H%M%S)

KERNEL_VERSION="$UPSTREAM-$STAMP+c$CONFIGHASH"
META_VERSION="$UPSTREAM-$STAMP+g$KCOMMIT"
WMTBOOT_VERSION="$UPSTREAM-$STAMP+w$WMTBOOT_HASH"

export DEBFULLNAME="$BUILDER_NAME" DEBEMAIL="$BUILDER_EMAIL"

DEBS="$BUILD_DIR/debs"
mkdir -p "$DEBS"
rm -f "$DEBS"/*.deb "$DEBS"/Packages.gz

log INFO "Building $KERNEL_PKG ($KERNEL_VERSION) with bindeb-pkg"
# Serial: parallel dtbs_install races on `install -d` (notably under uutils).
# DPKG_FLAGS=-d skips the target-arch build-dep check (we cross-build natively).
make bindeb-pkg KBUILD_DEBARCH=armel KDEB_PKGVERSION="$KERNEL_VERSION" KDEB_COMPRESS=xz DPKG_FLAGS=-d
# Keep only the image deb; discard the headers/libc-dev/changes/buildinfo beside it.
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
 Sets up each installed kernel for the WM8505's U-Boot, keeping the previous
 kernel as a one-step rollback.
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
 Depends on the latest WM8505 kernel and its boot integration, so "apt upgrade"
 keeps the device on the current kernel.
EOF
dpkg-deb --root-owner-group --build "$staging" "$DEBS/${PACKAGE_NAME}_${META_VERSION}_armel.deb" >/dev/null
rm -rf "$staging"

log INFO "Indexing local repository"
cd "$DEBS"
dpkg-scanpackages --multiversion . /dev/null | gzip -9c > Packages.gz
log OK "Local repository ready at $DEBS"
