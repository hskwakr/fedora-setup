#!/usr/bin/env bash
set -e

# ------------------------------------------------------------------------------
# Require running as root (or via sudo)
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (e.g., 'sudo ./install.sh')."
  exit 1
fi

# ------------------------------------------------------------------------------
# Install GitHub CLI
# ------------------------------------------------------------------------------
# DNF5 installation commands
sudo dnf install dnf5-plugins
sudo dnf config-manager addrepo --overwrite --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo
sudo dnf -y install gh --repo gh-cli

# ------------------------------------------------------------------------------
# Completion message
# ------------------------------------------------------------------------------
echo "GitHub CLI installed successfully."
