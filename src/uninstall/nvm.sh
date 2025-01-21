#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Set NVM directory
nvm_dir="${NVM_DIR:-$HOME/.nvm}"

# Check if NVM exists
if [ ! -d "$nvm_dir" ]; then
    echo "NVM is not installed or already uninstalled."
    exit 0
fi

# Confirm uninstallation
read -p "Do you want to uninstall NVM? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 1
fi

# Try to unload NVM
if command -v nvm >/dev/null 2>&1; then
    echo "Unloading NVM..."
    nvm unload || echo "Warning: Failed to unload NVM."
fi

# Remove directory
echo "Removing NVM directory: $nvm_dir"
rm -rf "$nvm_dir"

echo "NVM uninstallation completed."
