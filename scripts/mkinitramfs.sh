#!/bin/bash

source "$(dirname "$0")/../config.sh"

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
    mkdir -p "$INITRAMFS_DIR"/{bin,dev,lib,proc,sys,newroot,usr}
    
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

    # Symlink /lib to /lib64
    (
        cd "$INITRAMFS_DIR"
        ln -s "lib" "lib64"
    )

fi

