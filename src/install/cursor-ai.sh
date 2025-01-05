#!/bin/bash

# Enable strict mode for safer scripting
set -euo pipefail

# Variables
APP_NAME="Cursor AI"
APP_URL="https://downloader.cursor.sh/linux/appImage/x64"
APP_IMAGE="cursor.appimage"
INSTALL_DIR="/opt"
BIN_DIR="/usr/local/bin"
DESKTOP_ENTRY="/usr/share/applications/cursor.desktop"
ICON_PATH="$INSTALL_DIR/cursor.png"
ICON_URL="https://raw.githubusercontent.com/getcursor/docs/refs/heads/main/images/logo/logo-transparent.png"

# Functions
log_info() {
    printf "\e[32m[INFO]\e[0m %s\n" "$1"
}

log_warning() {
    printf "\e[33m[WARNING]\e[0m %s\n" "$1"
}

log_error() {
    printf "\e[31m[ERROR]\e[0m %s\n" "$1"
    exit 1
}

check_and_create_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || log_error "Failed to create directory: $dir"
        log_info "Directory created: $dir"
    fi
}

create_desktop_entry() {
    local name="$1"
    local exec="$2"
    local icon="$3"
    local path="$4"
    cat <<EOF > "$path"
[Desktop Entry]
Name=$name
Exec=$exec
Icon=$icon
Type=Application
Categories=Development;
EOF
}

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root. Please use sudo."
fi

log_info "Starting installation of $APP_NAME..."

# Ensure installation directory exists
check_and_create_dir "$INSTALL_DIR"

# Step 1: Download the AppImage
if [ ! -f "$INSTALL_DIR/$APP_IMAGE" ]; then
    log_info "Downloading $APP_NAME from $APP_URL..."
    curl -L "$APP_URL" -o "$INSTALL_DIR/$APP_IMAGE" || log_error "Failed to download $APP_NAME. Check your internet connection."
else
    log_warning "$APP_IMAGE already exists in $INSTALL_DIR. Skipping download."
fi

# Step 2: Download the Icon
if [ ! -f "$ICON_PATH" ]; then
    log_info "Downloading icon from $ICON_URL..."
    curl -L "$ICON_URL" -o "$ICON_PATH" || log_warning "Failed to download icon. Desktop entry will not have a custom icon."
else
    log_warning "Icon already exists at $ICON_PATH. Skipping download."
fi

# Step 3: Set executable permissions
chmod +x "$INSTALL_DIR/$APP_IMAGE"
log_info "Set executable permissions for $APP_IMAGE."

# Step 4: Create a symlink for terminal access
if [ ! -L "$BIN_DIR/cursor" ]; then
    log_info "Creating symlink for terminal access..."
    ln -s "$INSTALL_DIR/$APP_IMAGE" "$BIN_DIR/cursor" || log_error "Failed to create symlink. Check permissions."
else
    log_warning "Symlink already exists in $BIN_DIR."
fi

# Step 5: Create a desktop entry
if [ ! -f "$DESKTOP_ENTRY" ]; then
    log_info "Creating desktop entry..."
    create_desktop_entry "$APP_NAME" "$INSTALL_DIR/$APP_IMAGE" "$ICON_PATH" "$DESKTOP_ENTRY"
    log_info "Desktop entry created at $DESKTOP_ENTRY."
else
    log_warning "Desktop entry already exists at $DESKTOP_ENTRY."
fi

# Finalize
log_info "$APP_NAME installation complete."
log_info "You can launch it using the command 'cursor' or from your desktop menu."

