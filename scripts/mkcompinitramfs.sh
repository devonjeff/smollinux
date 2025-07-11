#!/bin/bash

source "$(dirname "$0")/../config.sh"

echo "Creating initramfs image..."

# Check if INITRAMFS_DIR exists
if [ ! -d "$INITRAMFS_DIR" ]; then
    echo "Error: INITRAMFS_DIR '$INITRAMFS_DIR' does not exist!"
    exit 1
fi

# Check if BUILD_DIR exists
if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: BUILD_DIR '$BUILD_DIR' does not exist!"
    exit 1
fi

cd "$INITRAMFS_DIR"
# Create the initramfs image
find . | cpio -o --format=newc | gzip > "$BUILD_DIR/initramfs.cpio.gz"
cd "$WORKDIR"

# Check if the operation was successful
if [ $? -eq 0 ] && [ -f "$BUILD_DIR/initramfs.cpio.gz" ]; then
    echo "Successfully created initramfs at $BUILD_DIR/initramfs.cpio.gz"
    echo "Size: $(du -h "$BUILD_DIR/initramfs.cpio.gz" | cut -f1)"
else
    echo "Error: Failed to create initramfs image!"
    echo "Please check if the directories exist and you have proper permissions."
    exit 1
fi