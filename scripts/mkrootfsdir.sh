#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../config.sh"

# Check if rootfs directory has content
if [ "$(ls -A "$ROOTFS_DIR" 2>/dev/null)" ]; then
    echo -e "${RED}Rootfs directory contains files. Please clean it first.${NC}"
    echo "Run '$0 clean' to clean the project."
    exit 1
else
    echo -e "${GREEN}Creating directories inside rootfs...${NC}"
    # Create directory inside rootfs's folder
    mkdir -p "$ROOTFS_DIR"/{bin,dev,etc,proc,root,sbin,sys,usr,usr/bin,usr/sbin,usr/lib,usr/lib32}
    
    # Create files for rootfs
    echo -e "${GREEN}Creating files for rootfs...${NC}"
    cp -r "$ROOTFS_FILES_DIR"/* "$ROOTFS_DIR/"

    # Install busybox
    echo -e "${GREEN}Installing busybox for rootfs...${NC}"


    # Create essential device nodes
    echo -e "${GREEN}Creating essential device nodes...${NC}"
    sudo mknod -m 600 "$ROOTFS_DIR/dev/console" c 5 1
    sudo mknod -m 666 "$ROOTFS_DIR/dev/null" c 1 3

    # Symlink folders
    (
        cd "$ROOTFS_DIR"
        sudo ln -s "usr/lib" "lib"
        sudo ln -s "usr/lib" "lib64"
        sudo ln -s "usr/lib" "usr/lib64"
    )

fi

