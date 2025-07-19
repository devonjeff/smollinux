#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/config.sh"

echo "Workdir: $WORKDIR"
echo "Initramfs dir: $INITRAMFS_DIR"
echo "Rootfs dir: $ROOTFS_DIR"
echo "Sources dir: $SOURCES_DIR"
echo "Sources build dir: $SOURCES_BUILD_DIR"
echo "Sources install dir: $SOURCES_INSTALL_DIR"
echo "Build dir: $BUILD_DIR"
echo "Temp dir: $TEMP_DIR"
echo ""

echo -e "${GREEN}Creating directories...${NC}"
    mkdir -p "$INITRAMFS_DIR" "$INITRAMFS_FILES_DIR" "$ROOTFS_DIR" "$ROOTFS_FILES_DIR" "$SOURCES_DIR" "$SOURCES_BUILD_DIR" "$SOURCES_INSTALL_DIR" "$BUILD_DIR" "$TEMP_DIR" "$GLIBC_BUILD_DIR" "$GLIBC_INSTALL_DIR" 

# Main command dispatcher
if [ $# -lt 1 ]; then
  echo "Usage: $0 [build rootfs|build initramfs|clean|help]"
  exit 1
fi

# Process commands
case "$1" in
  build)
    if [ "$2" = "rootfs" ]; then
      echo -e "${GREEN}Building rootfs...${NC}"
      ./scripts/mkrootfsdir.sh
      ./scripts/bash.sh
      ./scripts/coreutils.sh
      ./scripts/utillinux.sh
      ./scripts/glibc.sh "$2"
      ./scripts/ncurses.sh
      #./scripts/busybox.sh "$2"
      ./scripts/mkrootfsimg.sh
    elif [ "$2" = "initramfs" ]; then
      echo -e "${GREEN}Building initramfs...${NC}"
      ./scripts/mkinitramfsdir.sh
      ./scripts/glibc.sh "$2"
      ./scripts/busybox.sh "$2"
      ./scripts/mkinitramfsimg.sh
    else
      echo -e "${GREEN}Please specify what to build:${NC}"
      echo "  - '$0 build rootfs' to build the root filesystem"
      echo "  - '$0 build initramfs' to build the initial RAM filesystem"
      echo "  - Run '$0 help' for more information"
    fi
    ;;
    
  clean)
    ./scripts/clean.sh
    ;;
    
  help)
    echo "Available commands:"
    echo "  build           - Build the project"
    echo "  build rootfs    - Build the root filesystem"
    echo "  build initramfs - Build the initial RAM filesystem"
    echo "  clean           - Clean build artifacts"
    echo "  help            - Show this help message"
    ;;
    
  *)
    echo -e "${RED}Unknown command: $1${NC}"
    echo "Run '$0 help' for usage information."
    exit 1
    ;;
esac