#!/bin/bash
set -euo pipefail

# Run from the OpenWrt source root. Keep the complete package and API patches.
MT76_PACKAGE_COMMIT=2e13223aaa378a2cfcd01b9739aef6fa3cc645e1

if [ -e package/kernel/mt76 ]; then
  echo "package/kernel/mt76 already exists; refusing to replace it" >&2
  exit 1
fi

DONOR_DIR=$(mktemp -d)
trap 'rm -rf "$DONOR_DIR"' EXIT
git -C "$DONOR_DIR" init -q
git -C "$DONOR_DIR" remote add origin https://github.com/immortalwrt/immortalwrt.git
git -C "$DONOR_DIR" sparse-checkout init --cone
git -C "$DONOR_DIR" sparse-checkout set package/kernel/mt76
git -C "$DONOR_DIR" -c protocol.version=2 fetch --depth=1 --filter=blob:none origin "$MT76_PACKAGE_COMMIT"
git -C "$DONOR_DIR" checkout --detach FETCH_HEAD
test -f "$DONOR_DIR/package/kernel/mt76/patches/100-api_compat.patch"
mkdir -p package/kernel
cp -a "$DONOR_DIR/package/kernel/mt76" package/kernel/
echo "Imported mt76 package from ImmortalWrt $MT76_PACKAGE_COMMIT"
