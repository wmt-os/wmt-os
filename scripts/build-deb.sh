#!/bin/bash
# REQUIRES: bc bison build-essential debhelper dpkg-dev fakeroot flex gcc-arm-linux-gnueabi kmod libssl-dev rsync
set -e
source "$(dirname "$0")/common.sh"

cd "$KERNEL_DIR"

RELEASE=$(make -s kernelrelease)              # uname -r, e.g. 6.12.93-wm8505
KERNEL_PKG="linux-image-$RELEASE"             # versioned kernel package name
# One UTC timestamp gives a monotonic deb revision; an upstream bump dominates it
BUILD_STAMP=$(date -u +%Y%m%d%H%M%S)
PKG_VERSION="$(make -s kernelversion)-$BUILD_STAMP"

export DEBFULLNAME="$BUILDER_NAME" DEBEMAIL="$BUILDER_EMAIL"

DEBS="$BUILD_DIR/debs"
mkdir -p "$DEBS"
rm -f "$DEBS"/*.deb "$DEBS"/Packages.gz       # the local repo holds only this build

log INFO "Building $KERNEL_PKG ($PKG_VERSION) with bindeb-pkg"
# Objects are already built by the `kernel`/`modules` targets, so package
# serially: parallel dtbs_install races on `install -d` (notably under uutils).
# DPKG_FLAGS=-d: skip dpkg's target-arch build-dep check — we cross-compile with
# the host's native toolchain (the recipe only auto-skips it on native builds).
make bindeb-pkg KBUILD_DEBARCH=armel KDEB_PKGVERSION="$PKG_VERSION" KDEB_COMPRESS=xz DPKG_FLAGS=-d
# Keep only the image deb; bindeb-pkg also drops headers/libc-dev/changes/buildinfo
# beside it in the parent dir, which we discard.
mv "$BASE_DIR/${KERNEL_PKG}_${PKG_VERSION}_"*.deb "$DEBS/"
rm -f "$BASE_DIR"/linux-headers-*.deb "$BASE_DIR"/linux-libc-dev_*.deb \
	"$BASE_DIR"/linux-upstream_*.buildinfo "$BASE_DIR"/linux-upstream_*.changes

log INFO "Building wmt-boot"
staging=$(mktemp -d)
install -Dm755 "$BASE_DIR/config/wmt-boot/deploy" "$staging/usr/sbin/wmt-deploy-boot"
install -Dm755 "$BASE_DIR/config/wmt-boot/kernel-postinst" "$staging/etc/kernel/postinst.d/zz-wmt-boot"
install -Dm755 "$BASE_DIR/config/wmt-boot/kernel-postrm" "$staging/etc/kernel/postrm.d/zz-wmt-boot"
install -Dm644 "$BASE_DIR/config/wmt-boot/uboot.cmd" "$staging/usr/share/wmt-boot/uboot.cmd"
mkdir -p "$staging/DEBIAN"
cat > "$staging/DEBIAN/control" <<EOF
Package: wmt-boot
Version: $PKG_VERSION
Architecture: all
Maintainer: $BUILDER_NAME <$BUILDER_EMAIL>
Section: kernel
Priority: optional
Depends: u-boot-tools
Description: WM8505 U-Boot boot integration
 Builds the U-Boot boot slot (uzImage.bin + scriptcmd) from an installed kernel
 and keeps the previous one as a rollback slot, via /etc/kernel hooks.
EOF
cat > "$staging/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
[ "$1" = configure ] || exit 0
/usr/sbin/wmt-deploy-boot   # deploy the newest installed kernel
EOF
chmod 755 "$staging/DEBIAN/postinst"
dpkg-deb --root-owner-group --build "$staging" "$DEBS/wmt-boot_${PKG_VERSION}_all.deb" >/dev/null
rm -rf "$staging"

log INFO "Building $PACKAGE_NAME metapackage"
staging=$(mktemp -d)
mkdir -p "$staging/DEBIAN"
cat > "$staging/DEBIAN/control" <<EOF
Package: $PACKAGE_NAME
Version: $PKG_VERSION
Architecture: armel
Maintainer: $BUILDER_NAME <$BUILDER_EMAIL>
Section: kernel
Priority: optional
Depends: $KERNEL_PKG (= $PKG_VERSION), wmt-boot
Description: Linux kernel for the WonderMedia WM8505 (metapackage)
 Tracks the latest $KERNEL_PKG and pulls in the boot integration. Each kernel is a
 distinct co-installable package; upgrading pulls the new one while apt keeps the
 previous one as a rollback target.
EOF
dpkg-deb --root-owner-group --build "$staging" "$DEBS/${PACKAGE_NAME}_${PKG_VERSION}_armel.deb" >/dev/null
rm -rf "$staging"

log INFO "Indexing local repository"
cd "$DEBS"
dpkg-scanpackages --multiversion . /dev/null | gzip -9c > Packages.gz
log OK "Local repository ready at $DEBS"
