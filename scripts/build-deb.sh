#!/bin/bash
# REQUIRES: bc bison build-essential dpkg-dev flex gcc-arm-linux-gnueabi libssl-dev u-boot-tools
set -e
source "$(dirname "$0")/common.sh"

cd "$KERNEL_DIR"

KERNEL_RELEASE=$(make -s kernelrelease)   # uname -r; pairs the deb with its modules
# One timestamp: human for the splash, digits for the version
BUILD_TIME=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
BUILD_STAMP=${BUILD_TIME//[!0-9]/}
PACKAGE_VERSION="$(make -s kernelversion)-wmt-$BUILD_STAMP"
DEB_FILE="$BUILD_DIR/debs/${PACKAGE_NAME}_${PACKAGE_VERSION}_armel.deb"

log INFO "Packaging $PACKAGE_NAME $PACKAGE_VERSION ($KERNEL_RELEASE)"

staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT

# Ship the deploy hook that the postinst runs
install -Dm755 "$BASE_DIR/config/wmt-deploy-boot" "$staging/usr/sbin/wmt-deploy-boot"

log INFO "Building boot artifacts"
install -d "$staging/usr/lib/wmt/boot"
tmp=$(mktemp)
# uzImage.bin: zImage with the DTB appended, wrapped as a U-Boot kernel image
cat arch/arm/boot/zImage arch/arm/boot/dts/vt8500/wm8505-ref.dtb > "$tmp"
mkimage -A arm -O linux -T kernel -C none -a 0x8000 -e 0x8000 -n linux \
	-d "$tmp" "$staging/usr/lib/wmt/boot/uzImage.bin" >/dev/null
# scriptcmd: uboot.cmd with KERNEL_RELEASE/BUILD_TIME prepended, wrapped as a U-Boot script
sed "1i setenv KERNEL_RELEASE $KERNEL_RELEASE\nsetenv BUILD_TIME $BUILD_TIME" "$BASE_DIR/config/uboot.cmd" > "$tmp"
mkimage -A arm -O linux -T script -C none -a 1 -e 0 -n "script image" \
	-d "$tmp" "$staging/usr/lib/wmt/boot/scriptcmd" >/dev/null
rm -f "$tmp"

log INFO "Installing stripped modules"
make -s INSTALL_MOD_PATH="$staging" INSTALL_MOD_STRIP=1 modules_install
# Drop the build/source symlinks; they point into the build tree and dangle on-device
rm -f "$staging/lib/modules/$KERNEL_RELEASE/build" "$staging/lib/modules/$KERNEL_RELEASE/source"

# Package metadata and maintainer scripts (postinst/postrm run on-device)
mkdir -p "$staging/DEBIAN"
cat > "$staging/DEBIAN/control" <<EOF
Package: $PACKAGE_NAME
Version: $PACKAGE_VERSION
Architecture: armel
Maintainer: $BUILDER_NAME <$BUILDER_EMAIL>
Section: kernel
Priority: optional
Installed-Size: $(du -ks "$staging" | cut -f1)
Description: Linux kernel for WonderMedia WM8505
 Kernel $KERNEL_RELEASE for the WonderMedia WM8505 SoC.
EOF

cat > "$staging/DEBIAN/postinst" <<EOF
#!/bin/sh
set -e
[ "\$1" = configure ] || exit 0
depmod -a "$KERNEL_RELEASE"
/usr/sbin/wmt-deploy-boot
EOF

cat > "$staging/DEBIAN/postrm" <<EOF
#!/bin/sh
set -e
case "\$1" in
	remove|purge) rm -rf "/lib/modules/$KERNEL_RELEASE" ;;
esac
EOF
chmod 755 "$staging/DEBIAN/postinst" "$staging/DEBIAN/postrm"

mkdir -p "$BUILD_DIR/debs"
dpkg-deb --root-owner-group --build "$staging" "$DEB_FILE" >/dev/null
log OK "Built $(basename "$DEB_FILE")"

log INFO "Indexing local repository"
cd "$BUILD_DIR/debs"
dpkg-scanpackages --multiversion . /dev/null | gzip -9c > Packages.gz
log OK "Local repository ready at $BUILD_DIR/debs"
