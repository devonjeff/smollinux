#!/bin/bash
set -e

download() {
    local url="$1"
    local output="$2"
    [ -f "$output" ] && return
    echo ">> Downloading $url"
    curl -L "$url" -o "$output"
}

extract() {
    local file="$1"
    local dir="$2"
    echo ">> Extracting $file"
    rm -rf "$dir"
    mkdir -p "$dir"
    tar -xf "$file" -C "$dir" --strip-components=1
}

latest_version_from_url() {
    local url="$1"
    local regex="$2"

    # This function is fragile and may break if the website format changes.
    # Only return version to stdout
    curl -s "$url" | grep -Eo "$regex" | sort -V | uniq | tail -n1 | grep -Eo '[0-9]+(\.[0-9]+)+'
}

default_do_fetch() {
    download "$PKG_DOWNLOAD_URL" "$PKG_FILENAME"
}

default_do_extract() {
    extract "$PKG_FILENAME" "$PKG_SRC_DIR"
}

# This default configure function is fragile. It assumes the configure script
# is in the parent directory if PKG_BUILD_DIR is not ".". This may not
# always be the case.
default_do_configure() {
    if [ -f "configure" ]; then
        ./configure $CONFIGURE_ARGS
    elif [ -f "../configure" ]; then
        ../configure $CONFIGURE_ARGS
    else
        echo "!!> [helpers] Could not find configure script"
        exit 1
    fi
}

default_do_build() {
    make -j$(nproc)
}

default_do_install() {
    make DESTDIR="$PKG_INSTALL_DIR" install
}

sha256_file() {
    local file="$1"
    [ ! -f "$file" ] && echo "0" && return
    sha256sum "$file" | awk '{print $1}'
}

sha256_tree() {
    local dir="$1"
    [ ! -d "$dir" ] && echo "0" && return
    find "$dir" -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}'
}

