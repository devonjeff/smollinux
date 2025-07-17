#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../config.sh"

# Check if initramfs directory has content
if [ "$(ls -A "$INITRAMFS_DIR" 2>/dev/null)" ]; then
    echo -e "${RED}Initramfs directory contains files. Please clean it first.${NC}"
    echo "Run '$0 clean' to clean the project."
    exit 1
else
    echo -e "${GREEN}Creating directories inside initramfs folder...${NC}"
    # Create directory inside initramfs's folder
    mkdir -p "$INITRAMFS_DIR"/{bin,dev,lib,proc,sys,newroot,usr}
    
    # Create init script
    echo -e "${GREEN}Creating init script...${NC}"
    cp "$INITRAMFS_FILES_DIR/init" "$INITRAMFS_DIR/"
    chmod +x "$INITRAMFS_DIR/init"

    # Create busybox symlinks
    echo -e "${GREEN}Creating busybox symlinks...${NC}"
    for cmd in blkid cat cut echo grep ls mkdir mount seq sh sleep switch_root; do
        ln -sf busybox "$INITRAMFS_DIR/bin/$cmd"
    done

    # Create essential device nodes
    echo -e "${GREEN}Creating essential device nodes...${NC}"
    echo -e "${YELLOW}! Creating device nodes needs root privileges${NC}"
    sudo mknod -m 600 "$INITRAMFS_DIR/dev/console" c 5 1
    sudo mknod -m 666 "$INITRAMFS_DIR/dev/null" c 1 3

    # Symlink /lib to /lib64
    (
        cd "$INITRAMFS_DIR"
        ln -s "lib" "lib64"
    )

fi

