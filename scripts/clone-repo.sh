#!/bin/bash
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

# REQUIRES: git

set -eu
. "$(dirname "$0")/lib.sh"

log INFO "Cloning kernel repo ($KERNEL_BRANCH)"
git clone "$KERNEL_REPO" -b "$KERNEL_BRANCH" "$KERNEL_DIR"
log OK "Kernel cloned"
