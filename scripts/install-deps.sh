#!/bin/bash
set -eu
. "$(dirname "$0")/lib.sh"

mapfile -t ALL_REQUIRED < <(
    awk '/^# REQUIRES:/ {for (i=3; i<=NF; i++) print $i}' "$(dirname "$0")"/*.sh | sort -u
)

mapfile -t missing_packages < <(
    for package in "${ALL_REQUIRED[@]}"; do
        dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q '^install ok installed$' || echo "$package"
    done
)

if [ ${#missing_packages[@]} -ne 0 ]; then
    log INFO "Installing missing packages: ${missing_packages[*]}"
    apt-get update
    apt-get install -y "${missing_packages[@]}"
    log OK "Installed packages"
else
    log OK "Dependencies satisfied"
fi
