#!/usr/bin/env bash

set -e

ROOT=$(dirname "$(dirname "$(readlink -f $0)")")

function get_arch() {
    local arch=$(uname -m)
    if [ "$arch" == "x86_64" ]; then
        echo "x64"
    elif [ "$arch" == "aarch64" ]; then
        echo "arm64"
    else
        echo "Unsupported architecture: $arch" >&2
        exit 1
    fi
}

function find_cursor_appimage() {
    local search_dirs=("$HOME/AppImages" "$HOME/Applications" "$HOME/.local/bin")
    for dir in "${search_dirs[@]}"; do
        local appimage=$(find "$dir" -name "cursor.appimage" -print -quit 2>/dev/null)
        if [ -n "$appimage" ]; then
            echo "$appimage"
            return 0
        fi
    done
    return 1
}

function get_install_dir() {
    local search_dirs=("$HOME/AppImages" "$HOME/Applications" "$HOME/.local/bin")
    for dir in "${search_dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo "$dir"
            return 0
        fi
    done
    echo "No suitable installation directory found" >&2
    exit 1
}

function install_cursor() {
    local download_url="$1"
    local install_dir="$2"
    local temp_file=$(mktemp)
    local current_dir=$(pwd)

    echo "Downloading latest Cursor AppImage..."
    if ! curl -L "$download_url" -o "$temp_file"; then
        echo "Failed to download Cursor AppImage" >&2
        rm -f "$temp_file"
        return 1
    fi

    chmod +x "$temp_file"
    mv "$temp_file" "$install_dir/cursor.appimage"

    echo "Extracting icons and desktop file..."
    local temp_extract_dir=$(mktemp -d)
    cd "$temp_extract_dir"

    # Extract icons
    "$install_dir/cursor.appimage" --appimage-extract "usr/share/icons" >/dev/null 2>&1
    # Extract desktop file
    "$install_dir/cursor.appimage" --appimage-extract "cursor.desktop" >/dev/null 2>&1

    # Copy icons
    local icon_dir="$HOME/.local/share/icons/hicolor"
    mkdir -p "$icon_dir"
    cp -r squashfs-root/usr/share/icons/hicolor/* "$icon_dir/"

    # Copy desktop file
    local apps_dir="$HOME/.local/share/applications"
    mkdir -p "$apps_dir"
    cp squashfs-root/cursor.desktop "$apps_dir/"

    # Update desktop file to point to the correct AppImage location
    sed -i "s|Exec=.*|Exec=$install_dir/cursor.appimage|g" "$apps_dir/cursor.desktop"

    # Clean up
    cd "$current_dir"
    rm -rf "$temp_extract_dir"

    echo "Cursor has been installed to $install_dir/cursor.appimage"
    echo "Icons and desktop file have been extracted and placed in the appropriate directories"
}

function update_cursor() {
    echo "Updating Cursor..."
    local arch=$(get_arch)
    local download_url="https://downloader.cursor.sh/linux/appImage/$arch"
    local current_appimage=$(find_cursor_appimage)
    local install_dir

    if [ -n "$current_appimage" ]; then
        install_dir=$(dirname "$current_appimage")
    else
        install_dir=$(get_install_dir)
    fi

    install_cursor "$download_url" "$install_dir"
}

function launch_cursor() {
    local cursor_appimage=$(find_cursor_appimage)
    
    if [ -z "$cursor_appimage" ]; then
        echo "Error: Cursor AppImage not found. Running update to install it."
        update_cursor
        cursor_appimage=$(find_cursor_appimage)
    fi

    # Launch Cursor in the background with no logs
    nohup "$cursor_appimage" "$@" >/dev/null 2>&1 &
}

# Parse command-line arguments
if [ "$1" == "--update" ]; then
    update_cursor
else
    launch_cursor "$@"
fi

exit $?
