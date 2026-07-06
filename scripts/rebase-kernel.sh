#!/bin/bash
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

# REQUIRES: build-essential git jq wget

set -eu
. "$(dirname "$0")/lib.sh"

UPSTREAM_RELEASES="https://www.kernel.org/releases.json"
UPSTREAM_REPO="https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git"
VERSION_PATTERN='^6\.12\.'

cd "$KERNEL_DIR"

CURRENT_KERNEL=$(make -s kernelversion)
UPSTREAM_KERNEL=$(wget -q -O - "$UPSTREAM_RELEASES" | jq -r '.releases[].version' | grep "$VERSION_PATTERN")
[ -n "$UPSTREAM_KERNEL" ] || { log ERROR "Could not fetch upstream kernel version"; exit 1; }

if [ "$(printf '%s\n' "$CURRENT_KERNEL" "$UPSTREAM_KERNEL" | sort -V | tail -n 1)" = "$CURRENT_KERNEL" ]; then
	log INFO "Kernel already up-to-date ($CURRENT_KERNEL)"
	exit 0
fi

log INFO "Rebasing $CURRENT_KERNEL -> $UPSTREAM_KERNEL"
git config --get user.name >/dev/null || {
	git config user.name "$BUILDER_NAME"
	git config user.email "$BUILDER_EMAIL"
}
git fetch --no-tags "$UPSTREAM_REPO" "v$UPSTREAM_KERNEL"
git rebase FETCH_HEAD
log OK "Kernel rebased to $UPSTREAM_KERNEL"
