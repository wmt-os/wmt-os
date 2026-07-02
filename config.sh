# WMT OS Build Settings
#
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

export ARCH="arm"
export CROSS_COMPILE="arm-linux-gnueabi-"
export KCFLAGS="-march=armv5te -mtune=arm926ej-s"

export KERNEL_BRANCH="wmt-dev"
export KERNEL_REPO="https://github.com/lrussell887/linux-wmt.git"

export BUILDER_NAME="WMT OS Builder"
export BUILDER_EMAIL="root@wmt-os.org"

# Kernels are linux-image-<ver>-$KERNEL_FLAVOR-<id>; $PACKAGE_NAME tracks the newest
export KERNEL_FLAVOR="wm8505"
export PACKAGE_NAME="linux-image-$KERNEL_FLAVOR"

# Debian source for the build; the device's ships in bootstrap/sources/debian.sources
export DEBIAN_MIRROR="https://deb.debian.org/debian"
export DEBIAN_COMPONENTS="main non-free-firmware"
export EXTRA_PACKAGES="cloud-guest-utils debian-archive-keyring dropbear fastfetch firmware-mediatek gpiod htop network-manager rsync screen sudo wireless-regdb wpasupplicant"
export DESKTOP_PACKAGES="alsa-utils dillo icewm moc xdm xorg"

# Image profile: standard | desktop
export PROFILE="${PROFILE:-standard}"
