#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Error handling configuration
# ------------------------------------------------------------------------------
set -euo pipefail

# Function to display error messages and exit
error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# Global trap for errors: include line number
trap 'error_exit "An error occurred on line ${LINENO}"' ERR

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
PERSISTENCE_FILE="/etc/modules-load.d/v4l2loopback.conf"

# ------------------------------------------------------------------------------
# Check if the script is run with appropriate privileges
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
  error_exit "This script must be run as root."
fi

# ------------------------------------------------------------------------------
# Function: Check for Flatpak
# ------------------------------------------------------------------------------
check_flatpak() {
  echo "[INFO] Checking if Flatpak is installed..."
  if ! command -v flatpak >/dev/null 2>&1; then
    error_exit "Flatpak is not installed. Please install Flatpak and try again."
  fi
}

# ------------------------------------------------------------------------------
# Function: Ensure Flathub repository exists
# ------------------------------------------------------------------------------
ensure_flathub() {
  echo "[INFO] Verifying that the Flathub repository is added..."
  if ! flatpak remotes | grep -q flathub; then
    echo "[INFO] Flathub repository not found. Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  fi
}

# ------------------------------------------------------------------------------
# Function: Install OBS Studio via Flatpak if missing
# ------------------------------------------------------------------------------
install_obs() {
  echo "[INFO] Checking if OBS Studio is installed via Flatpak..."
  if ! flatpak info com.obsproject.Studio >/dev/null 2>&1; then
    echo "[INFO] OBS Studio not found. Installing OBS Studio via Flatpak..."
    flatpak install -y flathub com.obsproject.Studio
  fi
}

# ------------------------------------------------------------------------------
# Function: Install kmod-v4l2loopback using dnf if missing
# ------------------------------------------------------------------------------
install_kmod() {
  echo "[INFO] Checking if kmod-v4l2loopback package is installed..."
  if ! rpm -q kmod-v4l2loopback >/dev/null 2>&1; then
    echo "[INFO] kmod-v4l2loopback package not found. Installing..."
    dnf install -y kmod-v4l2loopback
  fi
}

# ------------------------------------------------------------------------------
# Function: Load v4l2loopback module if not loaded
# ------------------------------------------------------------------------------
load_module() {
  echo "[INFO] Checking if the v4l2loopback module is loaded..."
  if ! lsmod | grep -q v4l2loopback; then
    echo "[INFO] v4l2loopback module not loaded. Updating module dependencies..."
    depmod -a

    echo "[INFO] Loading v4l2loopback module..."
    if ! modprobe v4l2loopback exclusive_caps=1; then
      error_exit "Failed to load v4l2loopback module."
    fi
  fi
}

# ------------------------------------------------------------------------------
# Function: Ensure v4l2loopback module is loaded on boot (persistent)
# ------------------------------------------------------------------------------
persist_module() {
  echo "[INFO] Configuring v4l2loopback module to load on boot..."
  if [ ! -f "$PERSISTENCE_FILE" ] || ! grep -q "^v4l2loopback" "$PERSISTENCE_FILE"; then
    echo "[INFO] Adding v4l2loopback to the persistence configuration..."
    echo "v4l2loopback" | tee "$PERSISTENCE_FILE" >/dev/null
  fi
}

# ------------------------------------------------------------------------------
# Main execution flow
# ------------------------------------------------------------------------------
echo "[INFO] Starting installation and configuration process..."

check_flatpak
ensure_flathub
install_obs
install_kmod
load_module
persist_module

echo "[INFO] Installation and configuration completed successfully."
