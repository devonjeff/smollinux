#!/bin/bash

source "$(dirname "$0")/../config.sh"

# Check if there's already a glibc directory in $WORKDIR/sources
if ls "$WORKDIR/sources" | grep -q "glibc-"; then
    echo -e "${GREEN}Glibc source already exists in $WORKDIR/sources${NC}"
else
    echo -e "${YELLOW}Glibc source not found. Downloading latest version...${NC}"
    
    # Get the latest version from GNU FTP site
    LATEST_VERSION=$(wget -qO- 'https://mirror.freedif.org/GNU/libc/' | grep -o 'glibc-[0-9]\+\.[0-9]\+\.tar.gz' | sort -V | tail -n1)
    echo -e "${BLUE}Glibc latest version is: $LATEST_VERSION${NC}"

    # Download the latest version
    echo -e -n "${BLUE}"
    wget -q --show-progress "https://mirror.freedif.org/GNU/libc/$LATEST_VERSION" -P "$WORKDIR/temp"
    echo -e -n "${NC}"
    
    # Extract the downloaded archive
    tar -xf "$WORKDIR/temp/$LATEST_VERSION" -C "$WORKDIR/sources"
    
    # Clean up the downloaded archive
    #rm "/temp/$LATEST_VERSION"
    
    echo -e "${GREEN}Downloaded and extracted $LATEST_VERSION to $WORKDIR/sources${NC}"
fi

# Exit on error
set -e

# Find the glibc source directory
GLIBC_SRC=$(find $SOURCES_DIR -maxdepth 1 -name "glibc-*" -type d | sort -V | tail -n1)
if [ -z "$GLIBC_SRC" ]; then
    echo "Error: Could not find glibc source in $SOURCES_DIR"
    exit 1
fi

echo "Using glibc source: $GLIBC_SRC"

# Create build and install directories
mkdir -p "$GLIBC_BUILD_DIR"
mkdir -p "$GLIBC_INSTALL_DIR"
echo "Glibc build directory is: $GLIBC_BUILD_DIR"
echo "Glibc install directory is: $GLIBC_INSTALL_DIR"

# Navigate to build directory
cd "$GLIBC_BUILD_DIR"
echo "Changing into Glibc build directory: $GLIBC_BUILD_DIR"

# Check if glibc is already configured
if [ -f "$GLIBC_BUILD_DIR/config.status" ]; then
    echo "Glibc is already configured, skipping configuration step."
else

# Configure glibc
echo "Configuring glibc..."
"$GLIBC_SRC/configure" --prefix=/usr --host=x86_64-linux-gnu --build=x86_64-linux-gnu \
--enable-obsolete-rpc --disable-werror --with-headers="${KERNEL_HEADERS}" \
--enable-kernel=3.2 \
CC="gcc -m64" \
CXX="g++ -m64" \
CFLAGS="-O2" \
CXXFLAGS="-O2"

fi

# Check if glibc is already built
if [ -f "$GLIBC_BUILD_DIR/libc.so" ]; then
    echo "Glibc is already built, skipping build step."
else
    # Build glibc
    echo "Building glibc..."
    make -j16
fi

# Check if glibc is already installed
if [ -d "$GLIBC_INSTALL_DIR/usr/lib64" ]; then
    echo "Glibc is already installed, skipping installation step."
else
    # Install glibc
    echo "Installing glibc..."
    make install DESTDIR="$GLIBC_INSTALL_DIR"
fi

# Copy each library
for lib in "${INITRAMFS_LIBS[@]}"; do
    if [ -f "$GLIBC_INSTALL_DIR/lib64/$lib" ]; then
        echo "Copying $lib..."
        cp "$GLIBC_INSTALL_DIR/lib64/$lib" "$INITRAMFS_DIR/lib"
    else
        echo "Warning: $lib not found in $GLIBC_INSTALL_DIR/lib64"
    fi
done

echo -e "${DARK_GREEN}Initramfs directory structure created successfully.${NC}"
