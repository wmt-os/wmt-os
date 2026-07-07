#!/bin/bash
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

# REQUIRES: git

set -eu
. "$(dirname "$0")/lib.sh"

cd "$KERNEL_DIR"

# Content id of the kernel: sha256 of HEAD, the dirty diff, .config, and the
# cross compile flags; a dirty tree marks the id.
commit=$(git rev-parse --verify HEAD)
git --no-optional-locks diff --quiet HEAD && dirty= || dirty=-dirty
id=$({ printf '%s\n' "$commit"; git --no-optional-locks diff HEAD; cat .config; \
	printf '%s\n' "$ARCH" "$CROSS_COMPILE" "$KCFLAGS"; } | sha256sum | cut -c1-12)$dirty

if [ "${1:-}" = stamp ]; then
	# Prints the timestamp of the last mk-deb build for this id
	set -- "$BUILD_DIR/debs/linux-image-"*"-${id}_"*_armel.deb
	[ -e "$1" ] || exit 0
	LC_ALL=C date -d "@$(dpkg-deb -f "$1" Version)"
else
	echo "$id"
fi
