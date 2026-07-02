#!/bin/bash
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

# REQUIRES: dosfstools e2fsprogs parted pigz pv zerofree

set -eu
. "$(dirname "$0")/lib.sh"

IMG_FILE="$BUILD_DIR/disk.img"
IMG_GZ="$BUILD_DIR/disk-$PROFILE.img.gz"
MNT=$(mktemp -d)
MNT_BOOT="$MNT/boot"
MNT_ROOTFS="$MNT/rootfs"

cleanup() {
	sync
	umount "$MNT_BOOT" 2>/dev/null || true
	umount "$MNT_ROOTFS" 2>/dev/null || true
	losetup -d "$LOOP_DEV" 2>/dev/null || true
	rm -rf "$MNT"
}

log INFO "Creating disk image"
rm -f "$IMG_FILE"
dd if=/dev/zero of="$IMG_FILE" bs=1M count=3500 conv=fsync status=none

parted "$IMG_FILE" --script mklabel msdos
parted "$IMG_FILE" --script mkpart primary fat32 1MiB 65MiB
parted "$IMG_FILE" --script mkpart primary ext4 65MiB 100%

LOOP_DEV=$(losetup -fP --show "$IMG_FILE")
trap cleanup EXIT
udevadm settle # wait for the ${LOOP_DEV}pN partition nodes

log INFO "Formatting filesystems"
mkfs.vfat -F 32 -n BOOT "${LOOP_DEV}p1" >/dev/null
mkfs.ext4 -q -L rootfs "${LOOP_DEV}p2" >/dev/null

mkdir -p "$MNT_BOOT" "$MNT_ROOTFS"
mount "${LOOP_DEV}p1" "$MNT_BOOT"
mount "${LOOP_DEV}p2" "$MNT_ROOTFS"

log INFO "Populating filesystems"
cp -a "$BUILD_DIR"/rootfs/. "$MNT_ROOTFS/"

# Move the package-staged boot files onto the boot partition
cp -r "$MNT_ROOTFS"/boot/uboot/. "$MNT_BOOT/"
rm -rf "$MNT_ROOTFS"/boot/uboot/*

log INFO "Unmounting and zeroing free space"
sync
umount "$MNT_BOOT"
umount "$MNT_ROOTFS"
zerofree "${LOOP_DEV}p2"

log INFO "Compressing image"
pv "$IMG_FILE" | pigz -9 > "$IMG_GZ"
rm -f "$IMG_FILE"

[ -n "${SUDO_UID:-}" ] && chown "$SUDO_UID:$SUDO_GID" "$IMG_GZ"
log OK "Image ready: $IMG_GZ"
