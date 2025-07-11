#!/bin/bash

source "$(dirname "$0")/../config.sh"

set -e

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
    elif [ "$2" = "initramfs" ]; then
      echo -e "${GREEN}Building initramfs...${NC}"
      ./scripts/mkinitramfs.sh
      ./scripts/busybox.sh
      ./scripts/glibc.sh
      ./scripts/mkcompinitramfs.sh
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