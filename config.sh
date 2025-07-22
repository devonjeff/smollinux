#!/bin/bash

# Base directory (root of repo)
export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Core directories
export ROOTFS_DIR="$BASE_DIR/rootfs"
export ROOTFS_FILES_DIR="$BASE_DIR/rootfs-files"
export INITRAMFS_DIR="$BASE_DIR/initramfs"
export INITRAMFS_FILES_DIR="$BASE_DIR/initramfs-files"
export SOURCES_DIR="$BASE_DIR/sources"
export BUILD_DIR="$BASE_DIR/build"
export TEMP_DIR="$BASE_DIR/temp"
export STAMPS_DIR="$BUILD_DIR/stamps"
export SCRIPTS_DIR="$BASE_DIR/scripts"
