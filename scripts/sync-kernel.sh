#!/bin/bash
# REQUIRES: git
set -e
source "$(dirname "$0")/common.sh"

cd "$KERNEL_DIR"

CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "$KERNEL_BRANCH" ] && [ "${FORCE:-}" != "1" ]; then
	log ERROR "Kernel is on '$CURRENT_BRANCH', not '$KERNEL_BRANCH'; refusing (FORCE=1 to override)"
	exit 1
fi

log INFO "Syncing kernel to origin/$KERNEL_BRANCH"
git fetch origin
git switch -f "$KERNEL_BRANCH"
git reset --hard "origin/$KERNEL_BRANCH"
log OK "Kernel synced"
