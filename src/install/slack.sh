#!/bin/bash

# Slack Flatpak Installation Script for Fedora 41+
set -e

echo "Starting Slack installation via Flatpak..."

# Check if Flatpak is installed, install it if not
if ! command -v flatpak &> /dev/null; then
    echo "Flatpak is not installed. Installing now..."
    sudo dnf install -y flatpak
else
    echo "Flatpak is already installed."
fi

# Add the Flathub repository if it doesn't exist
if ! flatpak remote-list | grep -q flathub; then
    echo "Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
else
    echo "Flathub repository is already added."
fi

# Install or update Slack
if flatpak list --app | grep -q "com.slack.Slack"; then
    echo "Slack is already installed. Checking for updates..."
    flatpak update -y com.slack.Slack
else
    echo "Installing Slack..."
    flatpak install -y flathub com.slack.Slack
fi

echo "Slack installation is complete!"

# Provide instructions to run Slack
echo "To launch Slack, run the following command:"
echo "  flatpak run com.slack.Slack"
