#!/usr/bin/env bash
set -e

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
# You can adjust these variables for other packages.
PACKAGE_NAME="code"
DESCRIPTION="vs code"

# ------------------------------------------------------------------------------
# Require running as root (or via sudo)
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (e.g., 'sudo ./install.sh')."
  exit 1
fi

# ------------------------------------------------------------------------------
# Add repo
# ------------------------------------------------------------------------------
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
dnf check-update

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

