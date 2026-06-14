#!/bin/bash
# REQUIRES: git
set -e
source "$(dirname "$0")/common.sh"

cd "$KERNEL_DIR"
log INFO "Discarding build artifacts"
git clean -fdx -q
log OK "Kernel reset"
