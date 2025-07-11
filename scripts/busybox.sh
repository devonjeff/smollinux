#!/bin/bash

source "$(dirname "$0")/../config.sh"

set -e

# Get the latest version from the Busybox website
echo "Checking for latest Busybox version..."
BUSYBOX_URL="https://busybox.net/downloads/"
LATEST_VERSION=$(curl -s "$BUSYBOX_URL" | grep -o 'busybox-[0-9.]*\.tar\.bz2' | sort -V | tail -n1)

if [ -z "$LATEST_VERSION" ]; then
    echo "Failed to determine latest Busybox version"
    exit 1
fi

# Get the directory name without .tar.bz2
SOURCE_DIR_NAME=$(echo "$LATEST_VERSION" | sed 's/\.tar\.bz2//')
BUSYBOX_SRC_DIR="$SOURCES_DIR/$SOURCE_DIR_NAME"

# Check if Busybox binary already exists
if [ -f "$BUSYBOX_SRC_DIR/busybox" ]; then
    echo "Busybox already built at $BUSYBOX_SRC_DIR/busybox"
else
    # Check if source directory exists
    if [ -d "$BUSYBOX_SRC_DIR" ]; then
        echo "Busybox source already extracted at $BUSYBOX_SRC_DIR"
    else
        # Check if the tarball is already downloaded
        if [ -f "$TEMP_DIR/$LATEST_VERSION" ]; then
            echo "Busybox tarball already downloaded"
        else
            echo "Latest Busybox version: $LATEST_VERSION"
            DOWNLOAD_URL="${BUSYBOX_URL}${LATEST_VERSION}"

            # Download Busybox tarball
            cd "$TEMP_DIR"
            echo "Downloading from $DOWNLOAD_URL..."
            wget -q "$DOWNLOAD_URL" -O "$LATEST_VERSION"
        fi

        echo "Extracting Busybox source..."
        # Extract the tarball to SOURCES_DIR
        mkdir -p "$SOURCES_DIR"
        tar -xf "$TEMP_DIR/$LATEST_VERSION" -C "$SOURCES_DIR"
    fi

    echo "Building Busybox..."
    cd "$BUSYBOX_SRC_DIR"

    # Check if configuration already exists
    if [ ! -f ".config" ]; then
        # Generate default configuration
        echo "Generating default configuration..."
        make defconfig
    fi

    # Modify configuration
    echo "Modifying configuration..."
    sed -i -e '/^# CONFIG_STATIC is not set/c\CONFIG_STATIC=n' -e '/^CONFIG_STATIC[ =]/c\CONFIG_STATIC=n' .config
    sed -i '/^CONFIG_TC[ =]/c\# CONFIG_TC is not set' .config

    # Build Busybox
    echo "Building Busybox with $(nproc) parallel jobs..."
    make -j$(nproc)

    echo "Build complete..."
fi

echo "Busybox binary location: $BUSYBOX_SRC_DIR/busybox"
echo "Copying busybox binary into $INITRAMFS_DIR/bin"
mkdir -p "$INITRAMFS_DIR/bin"
cp "$BUSYBOX_SRC_DIR/busybox" "$INITRAMFS_DIR/bin"

cd "$WORKDIR"