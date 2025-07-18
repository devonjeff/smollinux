#!/bin/bash
#set -euo pipefail
source "$(dirname "$0")/../config.sh"

LATEST_VERSION_FOLDER=$(curl -s "$UTILLINUX_URL" | grep -o 'v[0-9]\+\.[0-9]\+/' | sort -V | tail -n1)
SUBDIR_URL="$UTILLINUX_URL$LATEST_VERSION_FOLDER"
UTIL_LINUX_TARBALL=$(curl -s "$SUBDIR_URL" | grep -o 'util-linux-[0-9]\+\.[0-9]\+\.[0-9]\+\.tar\.xz' | sort -V | tail -n1)
UTIL_LINUX_SRC_DIR="$SOURCES_DIR/$(basename "$UTIL_LINUX_TARBALL" .tar.xz)"
UTIL_LINUX_BUILD_DIR="$SOURCES_BUILD_DIR/util-linux"
UTIL_LINUX_INSTALLED_MARKER="$ROOTFS_DIR/usr/bin/lsblk"

# Extract util-linux
if [ ! -d "$UTIL_LINUX_SRC_DIR" ]; then
    # Download util-linux
    if [ ! -f "$TEMP_DIR/$UTIL_LINUX_TARBALL" ]; then
        echo "Downloading Util-Linux..."
        curl -o "$TEMP_DIR/$UTIL_LINUX_TARBALL" "$SUBDIR_URL$UTIL_LINUX_TARBALL"
    else
        echo "Util-Linux already downloaded."
    fi
    echo "Extracting Util-Linux..."
    mkdir -p "$SOURCES_DIR"
    tar -xf "$TEMP_DIR/$UTIL_LINUX_TARBALL" -C "$SOURCES_DIR"
else
    echo "Util-Linux already extracted."
fi

# Build util-linux
if [ ! -f "$UTIL_LINUX_BUILD_DIR/.make_done" ]; then
    # Configure util-linux
    if [ ! -d "$UTIL_LINUX_BUILD_DIR" ] || [ ! -f "$UTIL_LINUX_BUILD_DIR/config.status" ]; then
        echo "Configuring Util-Linux..."
        mkdir -p "$UTIL_LINUX_BUILD_DIR"
        cd "$UTIL_LINUX_BUILD_DIR"
        "$UTIL_LINUX_SRC_DIR"/configure --disable-liblastlog2 --prefix=/usr
    else
        echo "Util-Linux already configured."
    fi
    echo "Building Util-Linux..."
    make -j"$(nproc)"
    touch "$UTIL_LINUX_BUILD_DIR/.make_done"
else
    echo "Util-Linux already built."
fi

# Install util-linux
if [ ! -f "$UTIL_LINUX_INSTALLED_MARKER" ]; then
    echo "Installing Util-Linux..."
    sudo make -C "$UTIL_LINUX_BUILD_DIR" DESTDIR="$ROOTFS_DIR" install
    echo "Util-Linux installed to $ROOTFS_DIR."
else
    echo "Util-Linux already installed."
fi