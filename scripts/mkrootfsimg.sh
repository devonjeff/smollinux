#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../config.sh"

echo "Creating rootfs image..."

echo "Creating blank image file..."
truncate -s "$IMG_SIZE" "$BUILD_DIR/rootfs.img"

echo "Making ext4 filesystem..."
sudo mkfs.ext4 -F "$BUILD_DIR/rootfs.img"

echo "Creating mount point..."
sudo mkdir -p "$ROOTFS_MOUNT_DIR"

echo "Mounting image..."
sudo mount -o loop "$BUILD_DIR/rootfs.img" "$ROOTFS_MOUNT_DIR"

echo "Copying rootfs contents..."
sudo rsync -aHAX --numeric-ids "$ROOTFS_DIR"/ "$ROOTFS_MOUNT_DIR"/

echo "Syncing and unmounting..."
sync
sudo umount "$ROOTFS_MOUNT_DIR"

echo "Removing mount directory..."
sudo rmdir "$ROOTFS_MOUNT_DIR"

echo "[✓] Root filesystem image created: "$BUILD_DIR/rootfs.img""