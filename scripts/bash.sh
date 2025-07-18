#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../config.sh"

# Define variables
BASH_TARBALL=$(curl -s "$BASH_URL" | grep -o 'bash-[0-9]\+\.[0-9]\+\.tar\.gz' | sort -V | tail -n1)
BASH_SRC_DIR="$SOURCES_DIR/$(basename "$BASH_TARBALL" .tar.gz)"



# Extract bash
if [ ! -d "$BASH_SRC_DIR" ]; then
    # Download bash
    if [ ! -f "$TEMP_DIR/$BASH_TARBALL" ]; then
        echo "Downloading Bash..."
        curl -o "$TEMP_DIR/$BASH_TARBALL" "$BASH_URL$BASH_TARBALL"
    else
        echo "Bash already downloaded."
    fi
    echo "Extracting Bash..."
    mkdir -p "$SOURCES_DIR"
    tar -zxf "$TEMP_DIR/$BASH_TARBALL" -C "$SOURCES_DIR"
else
    echo "Bash already extracted."
fi



# Build bash
if [ ! -f "$BASH_BUILD_DIR/.make_done" ]; then
    # Configure bash
    if [ ! -d "$BASH_BUILD_DIR" ] || [ ! -f "$BASH_BUILD_DIR/config.status" ]; then
        echo "Configuring Bash..."
        mkdir -p "$BASH_BUILD_DIR"
        cd "$BASH_BUILD_DIR"
        "$BASH_SRC_DIR"/configure --prefix=/usr
    else
        echo "Bash already configured."
    fi
    echo "Building Bash..."
    make -j"$(nproc)"
    touch "$BASH_BUILD_DIR/.make_done"
else
    echo "Bash already built."
fi

# Install bash
if [ ! -f "$BASH_INSTALLED_MARKER" ]; then
    echo "Installing Bash..."
    sudo make -C "$BASH_BUILD_DIR" DESTDIR="$ROOTFS_DIR" install
    echo "Bash installed to $ROOTFS_DIR."
else
    echo "Bash already installed."
fi