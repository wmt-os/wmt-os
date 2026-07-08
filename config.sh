# WMT OS Build Settings
#
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

export NICE="${NICE:-19}" # Niceness value

export ARCH="arm"
export CROSS_COMPILE="arm-linux-gnueabi-"
export KCFLAGS="-march=armv5te -mtune=arm926ej-s"
export KBUILD_BUILD_VERSION=1 # Deterministic uname -v '#1'

export KERNEL_BRANCH="wmt-dev"
export KERNEL_REPO="https://github.com/wmt-os/linux-wmt.git"

export BUILDER_NAME="WMT OS Builder"
export BUILDER_EMAIL="root@wmt-os.org"

# Kernels are linux-image-<ver>-$KERNEL_FLAVOR-<id>; $PACKAGE_NAME tracks the newest
export KERNEL_FLAVOR="wm8505"
export PACKAGE_NAME="linux-image-$KERNEL_FLAVOR"

export EXTRA_PACKAGES="cloud-guest-utils debian-archive-keyring dropbear fastfetch firmware-mediatek htop network-manager rsync screen sudo wireless-regdb wpasupplicant"
export DESKTOP_PACKAGES="alsa-utils dbus-user-session dillo gogglesmm icewm polkitd rxvt-unicode xdm xfe xorg xserver-xorg-video-wmt"

export PROFILE="${PROFILE:-standard}" # Image profile: standard | desktop
export XZ_LEVEL="${XZ_LEVEL:-9}" # Image compression level: xz 0-9[e]
