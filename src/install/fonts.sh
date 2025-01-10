#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
PACKAGES=(
  fira-code-fonts
  ipa-gothic-fonts
  google-noto-sans-mono-fonts
)

# ------------------------------------------------------------------------------
# Require running as root (or via sudo)
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (e.g., 'sudo ./install.sh')."
  exit 1
fi

# ------------------------------------------------------------------------------
# Update system packages
# ------------------------------------------------------------------------------
echo "Updating system packages..."
dnf -y update

# ------------------------------------------------------------------------------
# Install Fonts
# ------------------------------------------------------------------------------
echo "Installing fonts..."
for pkg in "${PACKAGES[@]}"; do
  if dnf -y install "$pkg"; then
    echo "Successfully installed $pkg."
  else
    echo "Failed to install $pkg. Skipping..." >&2
  fi
done

# ------------------------------------------------------------------------------
# Cleanup & Finish
# ------------------------------------------------------------------------------
echo "Cleaning up unnecessary packages..."
dnf -y autoremove
dnf -y clean all

echo "All packages installed successfully. Please reboot for all changes to take effect."
