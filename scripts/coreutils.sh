#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../config.sh"

COREUTILS_TARBALL=$(curl -s "$COREUTILS_URL" | grep -o 'coreutils-[0-9]\+\.[0-9]\+\.tar\.xz' | sort -V | tail -n1)
COREUTILS_SRC_DIR="$SOURCES_DIR/$(basename "$COREUTILS_TARBALL" .tar.xz)"



# Extract coreutils
if [ ! -d "$COREUTILS_SRC_DIR" ]; then
    # Download coreutils
    if [ ! -f "$TEMP_DIR/$COREUTILS_TARBALL" ]; then
        echo "Downloading Coreutils..."
        curl -o "$TEMP_DIR/$COREUTILS_TARBALL" "$COREUTILS_URL$COREUTILS_TARBALL"
    else
        echo "Coreutils already downloaded."
    fi
    echo "Extracting Coreutils..."
    mkdir -p "$SOURCES_DIR"
    tar -xf "$TEMP_DIR/$COREUTILS_TARBALL" -C "$SOURCES_DIR"
else
    echo "Coreutils already extracted."
fi

# Build coreutils
if [ ! -f "$COREUTILS_BUILD_DIR/.make_done" ]; then
    # Configure coreutils
    if [ ! -d "$COREUTILS_BUILD_DIR" ] || [ ! -f "$COREUTILS_BUILD_DIR/config.status" ]; then
        echo "Configuring Coreutils..."
        mkdir -p "$COREUTILS_BUILD_DIR"
        cd "$COREUTILS_BUILD_DIR"
        "$COREUTILS_SRC_DIR"/configure --without-selinux --disable-libcap --prefix=/usr

    else
        echo "Coreutils already configured."
    fi
    echo "Building Coreutils..."
    make -j"$(nproc)"
    touch "$COREUTILS_BUILD_DIR/.make_done"
else
    echo "Coreutils already built."
fi

# Install coreutils
if [ ! -f "$COREUTILS_INSTALLED_MARKER" ]; then
    echo "Installing Coreutils..."
    make -C "$COREUTILS_BUILD_DIR" DESTDIR="$ROOTFS_DIR" install
    echo "Coreutils installed to $ROOTFS_DIR."
else
    echo "Coreutils already installed."
fi