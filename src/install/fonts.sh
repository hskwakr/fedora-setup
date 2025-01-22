#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Variables (System Fonts)
# ------------------------------------------------------------------------------
PACKAGES=(
  fira-code-fonts
  ipa-gothic-fonts
  google-noto-sans-mono-fonts
)

# ------------------------------------------------------------------------------
# Variables (Nerd Fonts)
# ------------------------------------------------------------------------------
NERD_FONTS=(
  "FiraMono"
  "CascadiaMono"
  "GeistMono"
)

NERD_FONTS_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
FONT_INSTALL_DIR="/usr/share/fonts/nerd-fonts"
TEMP_DIR="/tmp/nerdfonts"

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
# Install system fonts
# ------------------------------------------------------------------------------
echo "Installing system fonts..."
for pkg in "${PACKAGES[@]}"; do
  if dnf -y install "$pkg"; then
    echo "Successfully installed $pkg."
  else
    echo "Failed to install $pkg. Skipping..." >&2
  fi
done

# ------------------------------------------------------------------------------
# Install Nerd Fonts
# ------------------------------------------------------------------------------
echo "Installing Nerd Fonts..."
mkdir -p "$FONT_INSTALL_DIR"
mkdir -p "$TEMP_DIR"

for font in "${NERD_FONTS[@]}"; do
  echo "Downloading $font Nerd Font..."
  FONT_ZIP="${font}.zip"
  if curl -L -o "$TEMP_DIR/$FONT_ZIP" "$NERD_FONTS_URL/$FONT_ZIP"; then
    echo "Extracting $font..."
    unzip -o "$TEMP_DIR/$FONT_ZIP" -d "$FONT_INSTALL_DIR/$font"
    echo "$font installed successfully."
  else
    echo "Failed to download $font. Skipping..." >&2
  fi
done

# Update font cache
echo "Updating font cache..."
fc-cache -fv

# Clean up temporary files
rm -rf "$TEMP_DIR"

# ------------------------------------------------------------------------------
# Cleanup & Finish
# ------------------------------------------------------------------------------
echo "Cleaning up unnecessary packages..."
dnf -y autoremove
dnf -y clean all

echo "All packages installed successfully. Please reboot for all changes to take effect."
