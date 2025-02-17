#!/usr/bin/env bash
set -e

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
# You can adjust these variables for other packages.
PACKAGE_NAME="pnpm"
DESCRIPTION="pnpm"

# ------------------------------------------------------------------------------
# Require running as root (or via sudo)
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (e.g., 'sudo ./install.sh')."
  exit 1
fi

# ------------------------------------------------------------------------------
# Check package information
# ------------------------------------------------------------------------------
echo "Fetching information about $PACKAGE_NAME..."
dnf info "$PACKAGE_NAME"

# ------------------------------------------------------------------------------
# Install the package
# ------------------------------------------------------------------------------
echo "Installing $DESCRIPTION..."
dnf -y install "$PACKAGE_NAME"

# ------------------------------------------------------------------------------
# Completion message
# ------------------------------------------------------------------------------
echo "$DESCRIPTION installed successfully."

