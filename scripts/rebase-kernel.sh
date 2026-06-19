#!/bin/bash
# REQUIRES: build-essential git jq wget
set -eu
. "$(dirname "$0")/lib.sh"
. "$BASE_DIR/config"

cd "$KERNEL_DIR"

CURRENT_KERNEL=$(make -s kernelversion)
UPSTREAM_KERNEL=$(wget -q -O - "$KERNEL_UPSTREAM_RELEASES" | jq -r '.releases[].version' | grep "$KERNEL_VERSION_PATTERN")
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
git fetch --no-tags "$KERNEL_UPSTREAM_REPO" "v$UPSTREAM_KERNEL"
git rebase FETCH_HEAD
log OK "Rebased to $UPSTREAM_KERNEL"
