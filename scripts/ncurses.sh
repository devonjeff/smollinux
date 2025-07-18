#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../config.sh"

NCURSES_TARBALL=$(curl -s "$NCURSES_URL" | grep -o 'ncurses-[0-9]\+\.[0-9]\+\.tar\.gz' | sort -V | tail -n1)
NCURSES_SRC_DIR="$SOURCES_DIR/$(basename "$NCURSES_TARBALL" .tar.gz)"



# Extract ncurses
if [ ! -d "$NCURSES_SRC_DIR" ]; then
    # Download ncurses
    if [ ! -f "$TEMP_DIR/$NCURSES_TARBALL" ]; then
        echo "Downloading Ncurses..."
        curl -o "$TEMP_DIR/$NCURSES_TARBALL" "$NCURSES_URL$NCURSES_TARBALL"
    else
        echo "Ncurses already downloaded."
    fi
    echo "Extracting Ncurses..."
    mkdir -p "$SOURCES_DIR"
    tar -zxf "$TEMP_DIR/$NCURSES_TARBALL" -C "$SOURCES_DIR"
else
    echo "Ncurses already extracted."
fi


# Build ncurses
if [ ! -f "$NCURSES_BUILD_DIR/.make_done" ]; then
    # Configure ncurses
    if [ ! -d "$NCURSES_BUILD_DIR" ] || [ ! -f "$NCURSES_BUILD_DIR/config.status" ]; then
        echo "Configuring Ncurses..."
        mkdir -p "$NCURSES_BUILD_DIR"
        cd "$NCURSES_BUILD_DIR"
        "$NCURSES_SRC_DIR"/configure --with-shared --with-termlib --enable-widec --with-versioned-syms --without-cxx --without-cxx-binding --prefix=/usr
    else
        echo "Ncurses already configured."
    fi
    echo "Building Ncurses..."
    make -j"$(nproc)"
    touch "$NCURSES_BUILD_DIR/.make_done"
else
    echo "Ncurses already built."
fi

# Install ncurses
if [ ! -f "$NCURSES_INSTALLED_MARKER" ]; then
    echo "Installing Ncurses..."
    make -C "$NCURSES_BUILD_DIR" DESTDIR="$ROOTFS_DIR" install
    echo "Ncurses installed to $ROOTFS_DIR."
else
    echo "Ncurses already installed."
fi