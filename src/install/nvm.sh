#!/usr/bin/env bash
set -e

if ! command -v curl &>/dev/null; then
  echo "[ERROR] curl is not installed. Please install curl first."
  exit 1
fi

if ! command -v git &>/dev/null; then
  echo "[ERROR] git is not installed. Please install git first."
  exit 1
fi

LATEST_NVM_VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_NVM_VERSION" ]; then
  echo "[ERROR] Failed to fetch latest NVM version. Using fallback version v0.40.1"
  LATEST_NVM_VERSION="v0.40.1"
fi

curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${LATEST_NVM_VERSION}/install.sh" | bash

echo "Run 'source ~/.bashrc' after adding exports to your profile file"
