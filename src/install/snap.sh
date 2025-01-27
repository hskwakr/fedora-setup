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

echo "Starting snapd installation on Fedora..."

# Install snapd if not already installed
if ! rpm -q snapd &>/dev/null; then
    echo "Installing snapd..."
    dnf install -y snapd
else
    echo "snapd is already installed. Skipping installation."
fi

# Enable and start snapd service if not already running
if ! systemctl is-active --quiet "$SNAPD_SERVICE"; then
    echo "Enabling and starting snapd service..."
    systemctl enable --now "$SNAPD_SERVICE"
else
    echo "snapd service is already running."
fi

# Verify snapd service status
if systemctl is-active --quiet "$SNAPD_SERVICE"; then
    echo "snapd service is running successfully."
else
    echo "Error: snapd service failed to start. Check system logs for details."
    exit 1
fi

# Create symbolic link for classic snap support if it does not exist
if [[ ! -e $SNAP_SYMLINK ]]; then
    echo "Creating symbolic link for classic snap support..."
    ln -s /var/lib/snapd/snap "$SNAP_SYMLINK"
else
    echo "Symbolic link $SNAP_SYMLINK already exists. Skipping."
fi

echo "Snap installation completed successfully!"
