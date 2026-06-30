#!/bin/bash
# REQUIRES: git
set -eu
. "$(dirname "$0")/lib.sh"

cd "$KERNEL_DIR"
log INFO "Discarding build artifacts"
git clean -fdx -q
log OK "Kernel reset"
