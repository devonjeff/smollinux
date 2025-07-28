#!/bin/bash
set -e

# Source config
if [ -f "$(dirname "$0")/../config.sh" ]; then
    source "$(dirname "$0")/../config.sh"
else
    echo "==> [clean] Error: config.sh not found!"
    exit 1
fi

# Function to safely remove directory
safe_rm() {
    local dir="$1"
    if [ -n "$dir" ] && [ -d "$dir" ]; then
        echo "==> [clean] Removing $dir"
        if rm -rf "$dir"; then
            echo "==> [clean] Successfully removed $dir"
        else
            echo "==> [clean] Warning: Failed to remove $dir"
            return 1
        fi
    elif [ -n "$dir" ] && [ -e "$dir" ]; then
        echo "==> [clean] Warning: $dir exists but is not a directory"
        return 1
    else
        echo "==> [clean] $dir does not exist, skipping"
    fi
    return 0
}

echo "==> [clean] Starting cleanup process"

# Track overall success
SUCCESS=true

# Remove directories one by one with error handling
for dir in "$ROOTFS_DIR" "$INITRAMFS_DIR" "$TEMP_DIR" ; do
    if [ -n "$dir" ]; then
        if ! safe_rm "$dir"; then
            SUCCESS=false
        fi
    fi
done

# Note about BUILD_DIR - preserved to maintain build cache
echo "==> [clean] Note: BUILD_DIR is preserved to maintain build cache (cache.json)"

# Note about SOURCES_DIR - preserved to not rebuild packages
echo "==> [clean] Note: SOURCES_DIR is preserved to not extract, configure, and build packages again"

if [ "$SUCCESS" = "true" ]; then
    echo "==> [clean] Cleanup completed successfully"
else
    echo "==> [clean] Cleanup completed with some errors"
    exit 1
fi
