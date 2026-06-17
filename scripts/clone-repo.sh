#!/bin/bash
# REQUIRES: git
set -eu
. "$(dirname "$0")/lib.sh"
. "$BASE_DIR/config"

log INFO "Cloning kernel repo ($KERNEL_BRANCH)"
git clone "$KERNEL_REPO" -b "$KERNEL_BRANCH" "$KERNEL_DIR"
