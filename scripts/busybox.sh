#!/bin/bash

source "$(dirname "$0")/../config.sh"

set -e

# Get the latest version from the Busybox website
echo -e "${BLUE}Checking for latest Busybox version...${NC}"
BUSYBOX_URL="https://busybox.net/downloads/"
LATEST_VERSION=$(curl -s "$BUSYBOX_URL" | grep -o 'busybox-[0-9.]*\.tar\.bz2' | sort -V | tail -n1)

if [ -z "$LATEST_VERSION" ]; then
    echo -e "${RED}Failed to determine latest Busybox version${NC}"
    exit 1
fi

# Get the directory name without .tar.bz2
SOURCE_DIR_NAME=$(echo "$LATEST_VERSION" | sed 's/\.tar\.bz2//')
BUSYBOX_SRC_DIR="$SOURCES_DIR/$SOURCE_DIR_NAME"

# Check if Busybox binary already exists
if [ -f "$BUSYBOX_SRC_DIR/busybox" ]; then
    echo -e "${BLUE}Busybox already built at $BUSYBOX_SRC_DIR/busybox${NC}"
else
    # Check if source directory exists
    if [ -d "$BUSYBOX_SRC_DIR" ]; then
        echo -e "${BLUE}Busybox source already extracted at $BUSYBOX_SRC_DIR${NC}"
    else
        # Check if the tarball is already downloaded
        if [ -f "$TEMP_DIR/$LATEST_VERSION" ]; then
            echo -e "${BLUE}Busybox tarball already downloaded${NC}"
        else
            echo -e "${BLUE}Latest Busybox version: $LATEST_VERSION${NC}"
            DOWNLOAD_URL="${BUSYBOX_URL}${LATEST_VERSION}"

            # Download Busybox tarball
            cd "$TEMP_DIR"
            echo -e "${BLUE}Downloading from $DOWNLOAD_URL...${NC}"
            wget -q "$DOWNLOAD_URL" -O "$LATEST_VERSION"
        fi

        echo -e "${BLUE}Extracting Busybox source...${NC}"
        # Extract the tarball to SOURCES_DIR
        mkdir -p "$SOURCES_DIR"
        tar -xf "$TEMP_DIR/$LATEST_VERSION" -C "$SOURCES_DIR"
    fi

    echo -e "${BLUE}Building Busybox...${NC}"
    cd "$BUSYBOX_SRC_DIR"

    # Check if configuration already exists
    if [ ! -f ".config" ]; then
        # Generate default configuration
        echo -e "${BLUE}Generating default configuration...${NC}"
        make defconfig
    fi

    # Modify configuration
    echo -e "${BLUE}Modifying configuration...${NC}"
    sed -i -e '/^# CONFIG_STATIC is not set/c\CONFIG_STATIC=n' -e '/^CONFIG_STATIC[ =]/c\CONFIG_STATIC=n' .config
    sed -i '/^CONFIG_TC[ =]/c\# CONFIG_TC is not set' .config

    # Build Busybox
    echo -e "${BLUE}Building Busybox with $(nproc) parallel jobs...${NC}"
    make -j$(nproc)

    echo -e "${GREEN}Build complete...${NC}"
fi

echo -e "${BLUE}Busybox binary location: $BUSYBOX_SRC_DIR/busybox${NC}"
echo -e "C${BLUE}opying busybox binary into $INITRAMFS_DIR/bin${NC}"
mkdir -p "$INITRAMFS_DIR/bin"
cp "$BUSYBOX_SRC_DIR/busybox" "$INITRAMFS_DIR/bin"

cd "$WORKDIR"