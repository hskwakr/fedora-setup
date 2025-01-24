#!/usr/bin/env bash
set -e

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
# You can adjust these variables for other packages.
PACKAGE_NAME="fzf"
DESCRIPTION="fzf"

# ------------------------------------------------------------------------------
# Require running as root (or via sudo)
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (e.g., 'sudo ./remove.sh')."
  exit 1
fi

# ------------------------------------------------------------------------------
# Confirm package removal
# ------------------------------------------------------------------------------
echo "Fetching information about $PACKAGE_NAME..."
dnf info "$PACKAGE_NAME" || {
  echo "$PACKAGE_NAME is not installed or not available in repositories."
  exit 0
}

# ------------------------------------------------------------------------------
# Remove the package
# ------------------------------------------------------------------------------
echo "Removing $DESCRIPTION..."
dnf -y remove "$PACKAGE_NAME"

# ------------------------------------------------------------------------------
# Completion message
# ------------------------------------------------------------------------------
echo "$DESCRIPTION removed successfully."

