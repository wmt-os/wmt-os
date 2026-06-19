#!/bin/bash
# REQUIRES: git
set -eu
. "$(dirname "$0")/lib.sh"
. "$BASE_DIR/config"

cd "$KERNEL_DIR"

CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "$KERNEL_BRANCH" ] && [ "${FORCE:-}" != "1" ]; then
	log ERROR "Kernel is on '$CURRENT_BRANCH', not '$KERNEL_BRANCH'; refusing (FORCE=1 to override)"
	exit 1
fi

log INFO "Syncing kernel to upstream"
git switch -f "$KERNEL_BRANCH"
git fetch
git reset --hard @{upstream}
log OK "Kernel synced"
