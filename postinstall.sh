#!/usr/bin/env bash
#
###############################################################################
#        _          _          _           _       _         
#       | |        | |        | |         (_)     | |        
#   ____| | __  ___| |__   ___| |_   _ ___ _  __ _| |_ ___   
#  / _  | |/ / / _ \ '_ \ / _ \ | | | / __| |/ _` | __/ _ \  
# | (_| |   < |  __/ |_) |  __/ | |_| \__ \ | (_| | ||  __/  
#  \__,_|_|\_\ \___|_.__/ \___|_|\__,_|___/_|\__,_|\__\___|  
#                                                            
# Script Name : postainstall.sh
# Description : A script to set up a freshly installed Fedora system.
###############################################################################

# Exit on errors: if any command fails (non-zero exit), the script exits
# immediately.
set -e

# ------------------------------------------------------------------------------
# Require running as root (or via sudo)
# ------------------------------------------------------------------------------
# Ensures we have the privileges to install packages and modify system settings.
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (e.g., 'sudo ./postainstall.sh')."
  exit 1
fi

echo "Starting Fedora setup..."

# ------------------------------------------------------------------------------
# System Update
# ------------------------------------------------------------------------------
# We'll update existing packages to their latest versions before installing new
# ones.
echo "Updating system packages..."
dnf -y update

# ------------------------------------------------------------------------------
# Enable RPM Fusion (Free and Non-Free)
# ------------------------------------------------------------------------------
# Fedora's default repos only include FOSS (free/open-source) software. RPM Fusion
# provides additional packages (Free and Non-Free) such as proprietary drivers,
# certain multimedia codecs, and more software that Fedora does not ship by
# default.
echo "Enabling RPM Fusion repositories..."
sudo dnf install \
https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# ------------------------------------------------------------------------------
# Install Common Packages
# ------------------------------------------------------------------------------
# Adjust this list to suit your needs. These are commonly used tools:
#   - vim: A powerful text editor
#   - git: Version control system
#   - curl, wget: Tools for web requests
#   - htop: Interactive process viewer
#   - gnome-tweaks: Tool to tweak GNOME desktop settings
#   - util-linux-user: Utilities like chsh
echo "Installing common packages..."
dnf -y install \
  vim \
  git \
  curl \
  wget \
  htop \
  gnome-tweaks \
  util-linux-user \
  pass \
  unzip \

# ------------------------------------------------------------------------------
# Multimedia Support
# ------------------------------------------------------------------------------
# Installs and updates multimedia codecs from RPM Fusion, allowing playback of
# various video/audio formats not in Fedora by default.
echo "Installing multimedia codecs..."

# ------------------------------------------------------------------------------
# Developer Tools (Optional)
# ------------------------------------------------------------------------------
# Installs standard development utilities:
#   - "Development Tools" group: Basic dev tools like gcc, g++, make, etc.
#   - python3-pip: Python’s package installer
#   - gcc-c++: C++ compiler
#   - make: Build utility
echo "Installing development tools..."
dnf -y install \
  python3-pip \
  gcc-c++ \
  make

# ------------------------------------------------------------------------------
# Flatpak + Flathub
# ------------------------------------------------------------------------------
# Flatpak is a universal app packaging system. Flathub is its main repo.
# After enabling Flathub, you can install apps like:
#   flatpak install flathub com.videolan.VLC
echo "Enabling Flatpak and Flathub..."
dnf -y install flatpak
flatpak remote-add --if-not-exists flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo

# ------------------------------------------------------------------------------
# Optional: Other Software
# ------------------------------------------------------------------------------
# Examples: enabling the Google Chrome repository, installing GNOME Extensions,
# etc.

echo "Installing Google Chrome..."
dnf -y install fedora-workstation-repositories
dnf config-manager setopt google-chrome.enabled=1
dnf -y install google-chrome-stable

echo "Installing GNOME Shell Extensions..."
dnf -y install gnome-extensions-app

# ------------------------------------------------------------------------------
# Japanese Input Method (Mozc)
# ------------------------------------------------------------------------------
# ibus-mozc is a popular IME (Input Method Engine) for typing Japanese.
# After installation, go to Settings -> Keyboard (or Region & Language)
# to add "Japanese (Mozc)" as an input source, and switch using your shortcut.
echo "Installing ibus-mozc for Japanese input..."
dnf -y install ibus-mozc

# ------------------------------------------------------------------------------
# Cleanup & Finish
# ------------------------------------------------------------------------------
# Removes unnecessary packages and cleans up the package cache.
echo "Cleaning up..."
dnf -y autoremove
dnf -y clean all

echo "All done! Please reboot for all changes to take effect."

