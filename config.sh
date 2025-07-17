#!/bin/bash
set -euo pipefail

# Define colors for output
GREEN='\033[0;32m'
DARK_GREEN='\033[0;32;2m'
RED='\033[0;31m'
DARK_RED='\033[0;31;2m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INITRAMFS_DIR="$WORKDIR/initramfs"
INITRAMFS_FILES_DIR="$WORKDIR/initramfs-files"

ROOTFS_DIR="$WORKDIR/rootfs"
ROOTFS_FILES_DIR="$WORKDIR/rootfs-files"

SOURCES_DIR="$WORKDIR/sources"
SOURCES_BUILD_DIR="$SOURCES_DIR/build"
SOURCES_INSTALL_DIR="$SOURCES_DIR/install"

BUILD_DIR="$WORKDIR/build"

TEMP_DIR="$WORKDIR/temp"

GLIBC_BUILD_DIR="$SOURCES_BUILD_DIR/glibc"
GLIBC_INSTALL_DIR="$SOURCES_INSTALL_DIR/glibc"

# List of libraries to copy into initramfs
INITRAMFS_LIBS=("ld-linux-x86-64.so.2" "libc.so.6" "libm.so.6" "libresolv.so.2")

BUSYBOX_URL="https://busybox.net/downloads/"

# Size of the image
IMG_SIZE="2G"

# Temporary mount point
ROOTFS_MOUNT_DIR="/mnt/rootfs_build"
