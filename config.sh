# WMT OS Build Settings
#
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

export ARCH="arm"
export CROSS_COMPILE="arm-linux-gnueabi-"
export KCFLAGS="-march=armv5te -mtune=arm926ej-s"

export KERNEL_BRANCH="wmt-dev"
export KERNEL_REPO="https://github.com/lrussell887/linux-wmt.git"
export KERNEL_UPSTREAM_RELEASES="https://www.kernel.org/releases.json"
export KERNEL_UPSTREAM_REPO="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git"
export KERNEL_VERSION_PATTERN='^6\.12\.'

export BUILDER_NAME="WMT OS Builder"
export BUILDER_EMAIL="root@wmt-os.org"

# Kernels are linux-image-<ver>-$KERNEL_FLAVOR-<id>; $PACKAGE_NAME tracks the newest
export KERNEL_FLAVOR="wm8505"
export PACKAGE_NAME="linux-image-$KERNEL_FLAVOR"

export DEBIAN_CONFIG_POOL="https://ftp.debian.org/debian/pool/main/l/linux/"
export DEBIAN_CONFIG_PATTERN="linux-config-6.12_.*_armel\.deb$"
export DEBIAN_CONFIG_FILE="./usr/src/linux-config-6.12/config.armel_none_rpi.xz"

export DEBIAN_MIRROR="https://deb.debian.org/debian"
export DEBIAN_COMPONENTS="main non-free-firmware"
export DEBIAN_EXTRA_PACKAGES="cloud-guest-utils debian-archive-keyring dropbear fastfetch firmware-mediatek gpiod htop network-manager rsync screen sudo wireless-regdb wpasupplicant"
export DEBIAN_DESKTOP_PACKAGES="alsa-utils dillo icewm moc xdm xorg"

# Image profile: standard | desktop
export PROFILE="${PROFILE:-standard}"
