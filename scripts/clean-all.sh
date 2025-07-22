#!/bin/bash
set -e
source "$(dirname "$0")/../config.sh"

echo "==> [clean] Removing build/, sources/, rootfs/, initramfs/, temp/"
rm -rf "$BUILD_DIR" "$SOURCES_DIR" "$ROOTFS_DIR" "$INITRAMFS_DIR" "$TEMP_DIR"
