#!/bin/bash

# Enable strict mode for safer scripting
set -euo pipefail

# Variables
APP_NAME="Cursor AI"
APP_IMAGE="cursor.appimage"
INSTALL_DIR="/opt"
BIN_DIR="/usr/local/bin"
DESKTOP_ENTRY="/usr/share/applications/cursor.desktop"
ICON_PATH="$INSTALL_DIR/cursor.png"

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

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root. Please use sudo."
fi

log_info "Starting uninstallation of $APP_NAME..."

# Step 1: Remove the AppImage
if [ -f "$INSTALL_DIR/$APP_IMAGE" ]; then
    rm -f "$INSTALL_DIR/$APP_IMAGE"
    log_info "Removed $APP_IMAGE from $INSTALL_DIR."
else
    log_warning "$APP_IMAGE not found in $INSTALL_DIR. Skipping."
fi

# Step 2: Remove the Icon
if [ -f "$ICON_PATH" ]; then
    rm -f "$ICON_PATH"
    log_info "Removed icon at $ICON_PATH."
else
    log_warning "Icon not found at $ICON_PATH. Skipping."
fi

# Step 3: Remove the symlink
if [ -L "$BIN_DIR/cursor" ]; then
    rm -f "$BIN_DIR/cursor"
    log_info "Removed symlink from $BIN_DIR."
else
    log_warning "Symlink not found in $BIN_DIR. Skipping."
fi

# Step 4: Remove the desktop entry
if [ -f "$DESKTOP_ENTRY" ]; then
    rm -f "$DESKTOP_ENTRY"
    log_info "Removed desktop entry at $DESKTOP_ENTRY."
else
    log_warning "Desktop entry not found at $DESKTOP_ENTRY. Skipping."
fi

log_info "$APP_NAME uninstallation complete."

