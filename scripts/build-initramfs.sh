#!/bin/bash
set -e
source "$(dirname "$0")/../config.sh"

echo "==> [initramfs] Cleaning previous initramfs..."
rm -rf "$INITRAMFS_DIR"
mkdir -p "$INITRAMFS_DIR"/{bin,sbin,etc,proc,sys,dev,mnt}

# 1. Copy BusyBox from rootfs
echo "==> [initramfs] Copying BusyBox from rootfs..."
cp -a "$ROOTFS_DIR/bin/busybox" "$INITRAMFS_DIR/bin/"

# 2. Symlink common applets
echo "==> [initramfs] Creating BusyBox symlinks..."
(
    cd "$INITRAMFS_DIR/bin"
    for app in sh mount echo cat switch_root; do
        ln -sf busybox "$app"
    done
)

# 3. Copy /init from initramfs-files/
echo "==> [initramfs] Adding /init script..."
cp "$INITRAMFS_FILES_DIR/init" "$INITRAMFS_DIR/init"
chmod +x "$INITRAMFS_DIR/init"

# 4. Package it into .cpio.gz
echo "==> [initramfs] Creating archive..."
mkdir -p "$BUILD_DIR"
(
    cd "$INITRAMFS_DIR"
    find . | cpio -o -H newc | gzip > "$BUILD_DIR/initramfs.cpio.gz"
)

echo "==> [initramfs] Done: $BUILD_DIR/initramfs.cpio.gz"
