#!/bin/bash
# Copyright (C) 2026 Logan Russell <me@lrussell.net>

set -eu
. "$(dirname "$0")/../../scripts/lib.sh"

SRC="$BASE_DIR/packages/wmt-os-base"
DEBS="$BUILD_DIR/debs"
STAMP=${STAMP:-$(date +%s)}
HASH=$(find "$SRC" -type f | LC_ALL=C sort | xargs cat | sha256sum | cut -c1-12)
VERSION="$STAMP+$HASH"

log INFO "Building wmt-os-base ($VERSION)"
mkdir -p "$DEBS"
staging=$(mktemp -d)
install -Dm644 "$SRC/wmt.sources" "$staging/etc/apt/sources.list.d/wmt.sources"
install -Dm644 "$SRC/wmt-os.pref" "$staging/etc/apt/preferences.d/wmt-os.pref"
install -Dm755 "$SRC/preinst" "$staging/DEBIAN/preinst"
install -Dm755 "$SRC/postinst" "$staging/DEBIAN/postinst"
install -Dm755 "$SRC/postrm" "$staging/DEBIAN/postrm"
install -Dm644 "$SRC/triggers" "$staging/DEBIAN/triggers"
printf '%s\n' /etc/apt/sources.list.d/wmt.sources \
	/etc/apt/preferences.d/wmt-os.pref > "$staging/DEBIAN/conffiles"
cat > "$staging/DEBIAN/control" <<EOF
Package: wmt-os-base
Version: $VERSION
Architecture: all
Maintainer: $BUILDER_NAME <$BUILDER_EMAIL>
Section: admin
Priority: optional
Description: WMT OS distribution identity and archive trust
 Derives the identity files (os-release, issue, motd) from Debian's
 and carries the WMT OS archive signing key, package source, and pin.
EOF
dpkg-deb --root-owner-group --build "$staging" "$DEBS/wmt-os-base_${VERSION}_all.deb" >/dev/null
rm -rf "$staging"
