#!/bin/bash
set -e
set -u

export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export KERNEL_DIR="$BASE_DIR/linux-wmt"
export BUILD_DIR="$BASE_DIR/build"

export ARCH="arm"
export CROSS_COMPILE="arm-linux-gnueabi-"
export KCFLAGS="-march=armv5te -mtune=arm926ej-s"

export KERNEL_BRANCH="wmt-dev"
export KERNEL_REPO="https://github.com/lrussell887/linux-wmt.git"
export KERNEL_UPSTREAM_RELEASES="https://www.kernel.org/releases.json"
export KERNEL_UPSTREAM_REPO="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git"
export KERNEL_VERSION_PATTERN='^6\.12\.'

export BUILDER_NAME="WMT Automation"
export BUILDER_EMAIL="auto@wmt.os"

# Kernel flavour (CONFIG_LOCALVERSION="-$KERNEL_FLAVOUR"): each build is a distinct
# versioned package linux-image-<release> (release ends in -$KERNEL_FLAVOUR-g<commit>),
# tracked by the stable-named metapackage $PACKAGE_NAME that the image installs.
export KERNEL_FLAVOUR="wm8505"
export PACKAGE_NAME="linux-image-$KERNEL_FLAVOUR"

export DEBIAN_CONFIG_POOL="https://ftp.debian.org/debian/pool/main/l/linux/"
export DEBIAN_CONFIG_PATTERN="linux-config-6.12_.*_armel\.deb$"
export DEBIAN_CONFIG_FILE="./usr/src/linux-config-6.12/config.armel_none_rpi.xz"

export DEBIAN_MIRROR="https://deb.debian.org/debian"
export DEBIAN_COMPONENTS="main non-free-firmware"
export DEBIAN_EXTRA_PACKAGES="cloud-guest-utils debian-archive-keyring dropbear fastfetch firmware-mediatek gpiod htop network-manager sudo wireless-regdb wpasupplicant"
export DEBIAN_DESKTOP_PACKAGES="xserver-xorg-core xserver-xorg-input-libinput xinit openbox xterm"

# Image profile: standard | desktop
export PROFILE="${PROFILE:-standard}"

log() {
	local level=$1
	shift
	case $level in
		OK) echo "$(tput setaf 2)[OK]$(tput sgr0) $*" ;;
		INFO) echo "$(tput setaf 6)[INFO]$(tput sgr0) $*" ;;
		WARN) echo "$(tput setaf 3)[WARN]$(tput sgr0) $*" ;;
		ERROR) echo "$(tput setaf 1)[ERROR]$(tput sgr0) $*" ;;
	esac
}
