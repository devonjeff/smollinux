#!/bin/bash
set -e

source "$(dirname "$0")/../config.sh"
source "$SCRIPTS_DIR/helpers.sh"

PKG_NAME="$1"
[ -z "$PKG_NAME" ] && { echo "Usage: ./build-package.sh <pkg-name>"; exit 1; }

PKG_FILE="$BASE_DIR/packages/$PKG_NAME.pkg"
[ ! -f "$PKG_FILE" ] && { echo "Package definition not found: $PKG_FILE"; exit 1; }

source "$PKG_FILE"

# Use real install target
PKG_INSTALL_DIR="$BUILD_TARGET"
ABS_INSTALL_DIR="$(realpath "$PKG_INSTALL_DIR")"
echo "==> [$PKG_NAME] Installing to $ABS_INSTALL_DIR"

# Provide default no-op hooks
: "${do_fetch:=:}"
: "${do_extract:=:}"
: "${do_configure:=:}"
: "${do_build:=:}"
: "${do_install:=:}"

# Initialize cache file
CACHE_FILE="$BUILD_DIR/cache.json"
[ ! -f "$CACHE_FILE" ] && echo "{}" > "$CACHE_FILE"

# Handle --force: remove only the current package's cache entry
if [ "$FORCE_CLEAN" = "1" ]; then
    if [ -f "$CACHE_FILE" ]; then
        echo "==> [$PKG_NAME] Clearing cache entry for this package"
        jq "del(.$PKG_NAME)" "$CACHE_FILE" > "$CACHE_FILE.tmp" && mv "$CACHE_FILE.tmp" "$CACHE_FILE"
    else
        echo "==> [$PKG_NAME] Cache file not found, creating new one"
        echo "{}" > "$CACHE_FILE"
    fi
fi

# Dependencies
if declare -p DEPENDS &>/dev/null; then
    for dep in "${DEPENDS[@]}"; do
        echo "==> [$PKG_NAME] Building dependency: $dep"
        "$SCRIPTS_DIR/build-package.sh" "$dep"
    done
    # Invalidate cache if dependencies were rebuilt
    if [ "$source_dir_hash" = "$cached_source_hash" ]; then
        echo "==> [$PKG_NAME] Dependency change detected, invalidating cache"
        source_dir_hash=""
    fi
fi

# Handle versioned packages
if [ -n "$PKG_LATEST_URL" ]; then
    # Determine latest version
    PKG_VERSION="$(latest_version_from_url "$PKG_LATEST_URL" "$PKG_MATCH_REGEX")"
    if [ -z "$PKG_VERSION" ]; then
        echo "==> [$PKG_NAME] Could not detect latest version"
        exit 1
    fi

    # Build details
    PKG_FILENAME="${PKG_TARBALL_TEMPLATE/__VERSION__/$PKG_VERSION}"
    PKG_DOWNLOAD_URL="${PKG_DOWNLOAD_URL_TEMPLATE/__TARBALL__/$PKG_FILENAME}"
    PKG_DIR_NAME="${PKG_DIR_NAME/__VERSION__/$PKG_VERSION}"
    PKG_SRC_DIR="$SOURCES_DIR/$PKG_DIR_NAME"
    PKG_BUILD_DIR="${PKG_SRC_DIR}/${PKG_BUILD_DIR:-.}"

    echo "==> [$PKG_NAME] Version       : $PKG_VERSION"
    echo "==> [$PKG_NAME] Tarball       : $PKG_FILENAME"
    echo "==> [$PKG_NAME] Download URL  : $PKG_DOWNLOAD_URL"
    echo "==> [$PKG_NAME] Extracted Dir : $PKG_SRC_DIR"

    # Fetch
    current_pkg_hash=$(sha256_file "$PKG_FILE")
    cached_pkg_hash=$(jq -r ".[\"$PKG_NAME\"].pkg_hash // \"\"" "$CACHE_FILE")

    if [ "$current_pkg_hash" = "$cached_pkg_hash" ]; then
        if [ ! -f "$TEMP_DIR/$PKG_FILENAME" ]; then
            echo "==> [$PKG_NAME] Tarball missing, re-fetching"
            mkdir -p "$TEMP_DIR"
            (
                cd "$TEMP_DIR"
                download "$PKG_DOWNLOAD_URL" "$PKG_FILENAME"
            )
            jq ".[\"$PKG_NAME\"].pkg_hash = \"$current_pkg_hash\"" "$CACHE_FILE" > "$CACHE_FILE.tmp" && mv "$CACHE_FILE.tmp" "$CACHE_FILE"
        else
            echo "==> [$PKG_NAME] Skipping fetch (cached)"
        fi
    else
        mkdir -p "$TEMP_DIR"
        (
            cd "$TEMP_DIR"
            download "$PKG_DOWNLOAD_URL" "$PKG_FILENAME"
        )
        jq ".[\"$PKG_NAME\"].pkg_hash = \"$current_pkg_hash\"" "$CACHE_FILE" > "$CACHE_FILE.tmp" && mv "$CACHE_FILE.tmp" "$CACHE_FILE"
    fi

    # Extract
    current_tarball_hash=$(sha256_file "$TEMP_DIR/$PKG_FILENAME")
    cached_tarball_hash=$(jq -r ".[\"$PKG_NAME\"].tarball_hash // \"\"" "$CACHE_FILE")
    
    if [ "$current_tarball_hash" = "$cached_tarball_hash" ] && [ -d "$PKG_SRC_DIR" ]; then
        echo "==> [$PKG_NAME] Skipping extract (cached)"
    else
        mkdir -p "$SOURCES_DIR"
        extract "$TEMP_DIR/$PKG_FILENAME" "$PKG_SRC_DIR"
        jq ".[\"$PKG_NAME\"].tarball_hash = \"$current_tarball_hash\"" "$CACHE_FILE" > "$CACHE_FILE.tmp" && mv "$CACHE_FILE.tmp" "$CACHE_FILE"
    fi
else
    PKG_SRC_DIR="$SOURCES_DIR/$PKG_NAME"
    PKG_BUILD_DIR="${PKG_SRC_DIR}/${PKG_BUILD_DIR:-.}"
fi

# Compute source directory hash for configure/build/install
source_dir_hash=$(sha256_dir "$PKG_SRC_DIR")
cached_source_hash=$(jq -r ".[\"$PKG_NAME\"].source_hash // \"\"" "$CACHE_FILE")

# Configure
if [ -z "$source_dir_hash" ] || [ "$source_dir_hash" != "$cached_source_hash" ]; then
    echo "==> [$PKG_NAME] Configuring..."
    mkdir -p "$PKG_BUILD_DIR"
    (
        cd "$PKG_BUILD_DIR"
        do_configure
    )
    # Update source hash in cache
    jq ".[\"$PKG_NAME\"].source_hash = \"$source_dir_hash\"" "$CACHE_FILE" > "$CACHE_FILE.tmp" && mv "$CACHE_FILE.tmp" "$CACHE_FILE"
else
    echo "==> [$PKG_NAME] Skipping configure (cached)"
fi

# Build
if [ -z "$source_dir_hash" ] || [ "$source_dir_hash" != "$cached_source_hash" ]; then
    echo "==> [$PKG_NAME] Building..."
    (
        cd "$PKG_BUILD_DIR"
        do_build
    )
else
    echo "==> [$PKG_NAME] Skipping build (cached)"
fi

# Install
if [ -z "$source_dir_hash" ] || [ "$source_dir_hash" != "$cached_source_hash" ]; then
    echo "==> [$PKG_NAME] Installing to $ABS_INSTALL_DIR"
    (
        cd "$PKG_BUILD_DIR"
        do_install
    )
else
    echo "==> [$PKG_NAME] Skipping install (cached)"
fi

echo "==> [$PKG_NAME] Installed successfully."