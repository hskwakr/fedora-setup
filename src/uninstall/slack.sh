#!/bin/bash

# Slack Flatpak Uninstallation Script for Fedora
# Description: Uninstalls Slack installed via Flatpak and optionally removes user configuration files.

set -euo pipefail  # Enable strict mode for better error handling

# Variables
FLATPAK_APP_ID="com.slack.Slack"
SLACK_CONFIG_DIR="$HOME/.var/app/$FLATPAK_APP_ID"

# Check if Flatpak is installed
if ! command -v flatpak &>/dev/null; then
    echo "Error: Flatpak is not installed. Please install it first." >&2
    exit 1
fi

# Check if Slack is installed
if flatpak list --app | grep -q "$FLATPAK_APP_ID"; then
    echo "Uninstalling Slack..."
    flatpak uninstall -y "$FLATPAK_APP_ID"
    echo "Slack has been successfully uninstalled."
else
    echo "Slack is not installed. No action needed."
fi

# Prompt user to remove configuration files
read -p "Do you want to remove Slack configuration files? (y/N): " -r REMOVE_CONFIG
REMOVE_CONFIG=${REMOVE_CONFIG,,}  # Convert to lowercase

if [[ "$REMOVE_CONFIG" == "y" ]]; then
    if [[ -d "$SLACK_CONFIG_DIR" ]]; then
        echo "Removing Slack configuration directory: $SLACK_CONFIG_DIR"
        rm -rf "$SLACK_CONFIG_DIR"
        echo "Configuration files removed successfully."
    else
        echo "No Slack configuration directory found. Skipping cleanup."
    fi
else
    echo "Slack configuration files were not removed."
fi

echo "Slack uninstallation completed."
