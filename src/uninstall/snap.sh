#!/bin/bash

# Exit immediately if a command exits with a non-zero status, treat unset variables as errors, and fail on the first command in a pipeline that fails
set -euo pipefail

# Constants
SNAPD_SERVICE="snapd.socket"
SNAP_SYMLINK="/snap"

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root. Please use sudo."
    exit 1
fi

echo "Starting snapd uninstallation on Fedora..."

# Stop and disable the snapd service if it is running
if systemctl is-active --quiet "$SNAPD_SERVICE"; then
    echo "Stopping snapd service..."
    systemctl stop "$SNAPD_SERVICE"
    echo "Disabling snapd service..."
    systemctl disable "$SNAPD_SERVICE"
else
    echo "snapd service is not running. Skipping stop."
fi

# Remove symbolic link if it exists
if [[ -L $SNAP_SYMLINK ]]; then
    echo "Removing symbolic link $SNAP_SYMLINK..."
    rm -f "$SNAP_SYMLINK"
else
    echo "Symbolic link $SNAP_SYMLINK does not exist. Skipping removal."
fi

# Remove snapd package if installed
if rpm -q snapd &>/dev/null; then
    echo "Removing snapd package..."
    dnf remove -y snapd
else
    echo "snapd is not installed. Skipping package removal."
fi

# Clean up snap-related directories
SNAP_DIRS=(
    "/var/lib/snapd"
    "$HOME/snap"
)

for dir in "${SNAP_DIRS[@]}"; do
    if [[ -d $dir ]]; then
        echo "Removing $dir..."
        rm -rf "$dir"
    else
        echo "Directory $dir does not exist. Skipping."
    fi
done

echo "Snapd has been successfully uninstalled from your system."
