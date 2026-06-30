#!/bin/bash
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

# REQUIRES: git

set -eu
. "$(dirname "$0")/lib.sh"

cd "$KERNEL_DIR"
log INFO "Discarding build artifacts"
git clean -fdx -q
log OK "Kernel reset"
