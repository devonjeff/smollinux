#!/bin/sh

# Define colors for output
GREEN='\033[0;32m'
DARK_GREEN='\033[0;32;2m'
RED='\033[0;31m'
DARK_RED='\033[0;31;2m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
WORKDIR="$(dirname "$(realpath "$0")")"
INITRAMFS_DIR="$WORKDIR/initramfs"
SOURCES_DIR="$WORKDIR/sources"
SOURCES_BUILD_DIR="$SOURCES_DIR/build"
SOURCES_INSTALL_DIR="$SOURCES_DIR/install"
BUILD_DIR="$WORKDIR/build"
TEMP_DIR="$WORKDIR/temp"
GLIBC_BUILD_DIR="$SOURCES_BUILD_DIR/glibc"
GLIBC_INSTALL_DIR="$SOURCES_INSTALL_DIR/glibc"



echo "Workdir: $WORKDIR"
echo "Initramfs dir: $INITRAMFS_DIR"
echo "Sources dir: $SOURCES_DIR"
echo "Sources build dir: $SOURCES_BUILD_DIR"
echo "Sources install dir: $SOURCES_INSTALL_DIR"
echo "Build dir: $BUILD_DIR"
echo "Temp dir: $TEMP_DIR"
echo ""



build_initramfs() {
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
        # Create directory inside initramfs's folder
        mkdir -p "$INITRAMFS_DIR"/{bin,dev,lib64,proc,sys,newroot,usr}
        
        # Create init script
        echo -e "${GREEN}Creating init script...${NC}"
        cat > "$INITRAMFS_DIR/init" << 'EOF'
#!/bin/sh

# Make sure critical filesystems are mounted
mount -t devtmpfs devtmpfs /dev
mount -t proc proc /proc
mount -t sysfs sysfs /sys

echo "[initramfs] Welcome!"
echo "[initramfs] Kernel cmdline: $(cat /proc/cmdline)"

bootmode=""
rootarg=""

# Parse cmdline
for arg in $(cat /proc/cmdline); do
    case "$arg" in
        root=*)
            rootarg="${arg#root=}"
            ;;
        boot=live)
            bootmode="live"
            ;;
    esac
done

if [ "$bootmode" = "live" ]; then
    echo "[initramfs] Detected boot=live mode!"

    echo "[initramfs] Looking for /live/rootfs.squashfs..."

    mkdir -p /mnt
    mount -t squashfs -o loop /live/rootfs.squashfs /mnt
    if [ $? -ne 0 ]; then
        echo "[initramfs] ERROR: Failed to mount squashfs!"
        echo "[initramfs] Dropping to emergency shell!"
        exec sh
    fi

    echo "[initramfs] Contents of new root:"
    ls /mnt

    echo "[initramfs] Switching root..."
    exec switch_root /mnt /sbin/init

    echo "[initramfs] ERROR: switch_root failed!"
    echo "[initramfs] Dropping to emergency shell!"
    exec sh
fi

echo "[initramfs] root= parameter is: $rootarg"

if [ -z "$rootarg" ]; then
    echo "[initramfs] ERROR: No root= argument provided!"
    echo "[initramfs] Dropping to emergency shell!"
    exec sh
fi

# Resolve device
device=""
case "$rootarg" in
    LABEL=*|UUID=*)
        echo "[initramfs] Resolving filesystem specifier..."
        for i in $(seq 1 10); do
            if echo "$rootarg" | grep -q "^UUID="; then
                uuidval="${rootarg#UUID=}"
                device=$(blkid | grep "UUID=\"$uuidval\"" | cut -d: -f1)
            elif echo "$rootarg" | grep -q "^LABEL="; then
                labelval="${rootarg#LABEL=}"
                device=$(blkid | grep "LABEL=\"$labelval\"" | cut -d: -f1)
            fi

            if [ -n "$device" ]; then
                echo "[initramfs] Found device: $device"
                break
            fi

            echo "[initramfs] Waiting for blkid to see $rootarg... ($i/10)"
            sleep 1
        done
        ;;
    *)
        device="$rootarg"
        ;;
esac

echo "[initramfs] Resolved device: $device"

echo "[initramfs] Waiting for $device to appear..."
for i in $(seq 1 10); do
    if [ -b "$device" ]; then
        echo "[initramfs] Found block device $device"
        break
    fi
    echo "[initramfs] Device $device not ready yet, waiting..."
    sleep 1
done

# Mount real root
echo "[initramfs] Mounting $device on /mnt (read-only)..."
mkdir -p /mnt
mount -o ro "$device" /mnt
if [ $? -ne 0 ]; then
    echo "[initramfs] ERROR: Mount failed!"
    echo "[initramfs] Dropping to emergency shell!"
    exec sh
fi

echo "[initramfs] Contents of new root:"
ls /mnt

echo "[initramfs] Switching root..."
exec switch_root /mnt /sbin/init

# Fallback emergency shell
echo "[initramfs] ERROR: switch_root failed!"
echo "[initramfs] Dropping to emergency shell!"
exec sh
EOF
        chmod +x "$INITRAMFS_DIR/init"
        
        # Create busybox symlinks
        echo -e "${GREEN}Creating busybox symlinks...${NC}"
        for cmd in blkid cat cut echo grep ls mkdir mount seq sh sleep switch_root; do
            ln -sf busybox "$INITRAMFS_DIR/bin/$cmd"
        done
        
        # Create essential device nodes
        echo -e "${GREEN}Creating essential device nodes...${NC}"
        sudo mknod -m 600 "$INITRAMFS_DIR/dev/console" c 5 1
        sudo mknod -m 666 "$INITRAMFS_DIR/dev/null" c 1 3

        echo -e "${DARK_GREEN}Initramfs directory structure created successfully.${NC}"

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

    # Configure glibc
    echo "Configuring glibc..."
    "$GLIBC_SRC/configure" --prefix=/usr \
    --enable-obsolete-rpc --disable-werror --with-headers=/usr/include \
    --enable-kernel=3.2


    # Build glibc
    echo "Building glibc..."
    make -j16

    # Install glibc
    echo "Installing glibc..."
    make install DESTDIR="$GLIBC_INSTALL_DIR"
    fi
}

clean() {
    echo -e "${GREEN}Cleaning the project...${NC}"
    
    # Handle initramfs directory cleanup
    if [ -d "$INITRAMFS_DIR" ]; then
        if [ "$(ls -A "$INITRAMFS_DIR" 2>/dev/null)" ]; then
            echo -e "${BLUE}Removing initramfs files...${NC}"
            rm -rf "$INITRAMFS_DIR"/*
            echo -e "${GREEN}Removing initramfs files completed successfully!${NC}"
        else
            echo -e "${YELLOW}Initramfs directory exists but is empty. Nothing to clean.${NC}"
        fi
    else
        echo -e "${RED}Initramfs directory doesn't exist. Skipping...${NC}"
    fi

    # Handle build directory cleanup
    if [ -d "$BUILD_DIR" ]; then
        if [ "$(ls -A "$BUILD_DIR" 2>/dev/null)" ]; then
            echo -e "${BLUE}Removing build files...${NC}"
            rm -rf "$BUILD_DIR"/*
            echo -e "${GREEN}Removing build files completed successfully!${NC}"
        else
            echo -e "${YELLOW}Build directory exists but is empty. Nothing to clean.${NC}"
        fi
    else
        echo -e "${RED}Build directory doesn't exist. Skipping...${NC}"
    fi

    # Handle temp directory cleanup
    if [ -d "$TEMP_DIR" ]; then
        if [ "$(ls -A "$TEMP_DIR" 2>/dev/null)" ]; then
            echo -e "${BLUE}Removing temporary files...${NC}"
            rm -rf "$TEMP_DIR"/*
            echo -e "${GREEN}Removing temporary files completed successfully!${NC}"
        else
            echo -e "${YELLOW}Temp directory exists but is empty. Nothing to clean.${NC}"
        fi
    else
        echo -e "${RED}Temp directory doesn't exist. Skipping...${NC}"
    fi

    # Handle sources directory cleanup
    #if [ -d "$SOURCES_DIR" ]; then
        #if [ "$(ls -A "$SOURCES_DIR" 2>/dev/null)" ]; then
            #echo -e "${BLUE}Cleaning sources directory...${NC}"
            #rm -rf "$SOURCES_DIR"/*
            #echo -e "${GREEN}Cleaning sources directory completed successfully!${NC}"
        #else
            #echo -e "${YELLOW}Sources directory exists but is empty. Nothing to clean.${NC}"
        #fi
    #else
        #echo -e "${RED}Temp directory doesn't exist. Skipping...${NC}"
    #fi

    echo -e "${DARK_GREEN}Done.${NC}"
}

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
      build_rootfs
    elif [ "$2" = "initramfs" ]; then
      echo -e "${GREEN}Building initramfs...${NC}"
      build_initramfs
    else
      echo -e "${GREEN}Please specify what to build:${NC}"
      echo "  - '$0 build rootfs' to build the root filesystem"
      echo "  - '$0 build initramfs' to build the initial RAM filesystem"
      echo "  - Run '$0 help' for more information"
    fi
    ;;
    
  clean)
    clean
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