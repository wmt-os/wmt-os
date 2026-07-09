#!/bin/sh
set -e

# ---- Desktop ----

# Set urxvt as the default terminal
update-alternatives --set x-terminal-emulator /usr/bin/urxvt
