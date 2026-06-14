#!/bin/bash
# REQUIRES: git
set -e
source "$(dirname "$0")/common.sh"

log INFO "Cloning kernel repo ($KERNEL_BRANCH)"
git clone "$KERNEL_REPO" -b "$KERNEL_BRANCH" "$KERNEL_DIR"
