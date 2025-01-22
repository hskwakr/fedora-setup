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

# Nerd Fonts関連の変数を追加
NERD_FONTS_DIR="/usr/share/fonts/nerd-fonts"
NERD_FONTS=(
  "FiraMono"
  "CascadiaMono"
  "GeistMono"
)

FONT_PATTERNS=(
  "*fira*"
  "*ipa*"
  "*noto*"
)
FONT_DIRECTORIES=(
  "$HOME/.fonts"
  "$HOME/.local/share/fonts"
  "/usr/share/fonts"
  "/usr/local/share/fonts"
)

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------
print_section() {
  echo "--------------------------------------------------"
  echo "$1"
  echo "--------------------------------------------------"
}

remove_package() {
  local pkg=$1
  if dnf -y remove "$pkg"; then
    echo "Successfully removed $pkg."
  else
    echo "Failed to remove $pkg. Skipping..." >&2
  fi
}

# ------------------------------------------------------------------------------
# Require running as root (or via sudo)
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (e.g., 'sudo ./uninstall.sh')."
  exit 1
fi

# Check for required commands
for cmd in dnf find; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: Required command $cmd is not installed." >&2
    exit 1
  fi
done

# ------------------------------------------------------------------------------
# Check Installed Fonts
# ------------------------------------------------------------------------------
print_section "Checking installed font packages"
missing_packages=()
for pkg in "${PACKAGES[@]}"; do
  if ! dnf list installed "$pkg" &>/dev/null; then
    echo "$pkg is not installed. Skipping."
    missing_packages+=("$pkg")
  fi
done

# ------------------------------------------------------------------------------
# Uninstall Fonts
# ------------------------------------------------------------------------------
print_section "Uninstalling font packages"
for pkg in "${PACKAGES[@]}"; do
  if [[ ! " ${missing_packages[@]} " =~ " $pkg " ]]; then
    remove_package "$pkg"
  fi
done

# ------------------------------------------------------------------------------
# Remove Residual Fonts
# ------------------------------------------------------------------------------
print_section "Removing residual font files"
for dir in "${FONT_DIRECTORIES[@]}"; do
  if [ -d "$dir" ]; then
    echo "Checking directory: $dir"
    find "$dir" -type f \( $(printf -- '-iname "%s" -o ' "${FONT_PATTERNS[@]}") -false \) -exec rm -f {} +
  fi
done

# Check for remaining font files
print_section "Verifying residual files"
for dir in "${FONT_DIRECTORIES[@]}"; do
  if [ -d "$dir" ]; then
    remaining_fonts=$(find "$dir" -type f \( $(printf -- '-iname "%s" -o ' "${FONT_PATTERNS[@]}") -false \))
    if [ -n "$remaining_fonts" ]; then
      echo "Warning: The following fonts were not removed:"
      echo "$remaining_fonts"
    fi
  fi
done

# ------------------------------------------------------------------------------
# Remove Nerd Fonts
# ------------------------------------------------------------------------------
print_section "Removing Nerd Fonts"
if [ -d "$NERD_FONTS_DIR" ]; then
  echo "Removing Nerd Fonts from $NERD_FONTS_DIR"
  for font in "${NERD_FONTS[@]}"; do
    if [ -d "$NERD_FONTS_DIR/$font" ]; then
      echo "Removing $font..."
      rm -rf "$NERD_FONTS_DIR/$font"
    fi
  done
  
  # ディレクトリが空の場合は削除
  if [ -z "$(ls -A $NERD_FONTS_DIR)" ]; then
    rm -rf "$NERD_FONTS_DIR"
  fi
else
  echo "Nerd Fonts directory not found. Skipping."
fi

# フォントキャッシュを更新
echo "Updating font cache..."
fc-cache -fv

# ------------------------------------------------------------------------------
# Cleanup & Finish
# ------------------------------------------------------------------------------
print_section "Cleaning up unnecessary packages"
dnf -y autoremove
dnf -y clean all

print_section "Package uninstallation completed"
