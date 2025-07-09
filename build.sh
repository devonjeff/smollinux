#!/bin/sh

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Variables
WORKDIR="$(dirname "$(realpath "$0")")"
INITRAMFS_DIR="$WORKDIR/initramfs"
SOURCES_DIR="$WORKDIR/sources"
SOURCES_BUILD_DIR="$SOURCES_DIR/build"
SOURCES_INSTALL_DIR="$SOURCES_DIR/install"
BUILD_DIR="$WORKDIR/build"
TEMP_DIR="$WORKDIR/temp"



echo "Workdir: $WORKDIR"
echo "Initramfs dir: $INITRAMFS_DIR"
echo "Sources dir: $SOURCES_DIR"
echo "Sources build dir: $SOURCES_BUILD_DIR"
echo "Sources install dir: $SOURCES_INSTALL_DIR"
echo "Build dir: $BUILD_DIR"
echo "Temp dir: $TEMP_DIR"
echo ""



build() {
    # Ensure all required directories exist
    echo -e "${GREEN}Creating directories${NC}"
    mkdir -p "$INITRAMFS_DIR" "$SOURCES_DIR" "$SOURCES_BUILD_DIR" "$SOURCES_INSTALL_DIR" "$BUILD_DIR" "$TEMP_DIR"
    
    # Check if initramfs directory has content
    if [ "$(ls -A "$INITRAMFS_DIR" 2>/dev/null)" ]; then
        echo -e "${RED}Initramfs directory contains files. Please clean it first.${NC}"
        echo "Run '$0 clean' to clean the project."
        exit 1
    else
        echo -e "${GREEN}Creating directories inside initramfs folder...${NC}"
        # Create dirs inside initramfs's folder
        mkdir -p "$INITRAMFS_DIR"/{bin,dev,lib64,proc,sys,newroot,usr}
        echo -e "${GREEN}Initramfs directory structure created successfully.${NC}"
    fi
}

clean() {
    echo -e "${GREEN}Cleaning the project...${NC}"
    
    # Handle initramfs directory cleanup
    if [ -d "$INITRAMFS_DIR" ]; then
        if [ "$(ls -A "$INITRAMFS_DIR" 2>/dev/null)" ]; then
            echo "Removing initramfs files..."
            rm -rf "$INITRAMFS_DIR"/*
            echo -e "${GREEN}Removing initramfs files completed successfully!${NC}"
        else
            echo -e "${RED}Initramfs directory exists but is empty. Nothing to clean.${NC}"
        fi
    else
        echo -e "${RED}Initramfs directory doesn't exist. Skipping...${NC}"
    fi

    # Handle build directory cleanup
    if [ -d "$BUILD_DIR" ]; then
        if [ "$(ls -A "$BUILD_DIR" 2>/dev/null)" ]; then
            echo "Removing build files..."
            rm -rf "$BUILD_DIR"/*
            echo -e "${GREEN}Removing build files completed successfully!${NC}"
        else
            echo -e "${RED}Build directory exists but is empty. Nothing to clean.${NC}"
        fi
    else
        echo -e "${RED}Build directory doesn't exist. Skipping...${NC}"
    fi

    # Handle temp directory cleanup
    if [ -d "$TEMP_DIR" ]; then
        if [ "$(ls -A "$TEMP_DIR" 2>/dev/null)" ]; then
            echo "Removing temporary files..."
            rm -rf "$TEMP_DIR"/*
            echo -e "${GREEN}Removing temporary files completed successfully!${NC}"
        else
            echo -e "${RED}Temp directory exists but is empty. Nothing to clean.${NC}"
        fi
    else
        echo -e "${RED}Temp directory doesn't exist. Skipping...${NC}"
    fi

    echo -e "${GREEN}Done.${NC}"
}

# Main command dispatcher
if [ $# -lt 1 ]; then
  echo "Usage: $0 [build|clean|help]"
  exit 1
fi

# Process commands
case $1 in
  build)
    build
    ;;
    
  clean)
    clean
    ;;
    
  help)
    echo "Available commands:"
    echo "  build  - Build the project"
    echo "  clean  - Clean build artifacts"
    echo "  help   - Show this help message"
    ;;
    
  *)
    echo -e "${RED}Unknown command: $1${NC}"
    echo "Run '$0 help' for usage information."
    exit 1
    ;;
esac