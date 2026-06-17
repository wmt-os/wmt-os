#!/bin/bash

export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export KERNEL_DIR="$BASE_DIR/linux-wmt"
export BUILD_DIR="$BASE_DIR/build"

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
