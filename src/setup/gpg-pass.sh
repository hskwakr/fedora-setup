#!/bin/bash

# スクリプトを安全に実行するための設定
set -e

# デフォルトのGPGキー情報（必要に応じて編集）
NAME="Your Name"
EMAIL="your.email@example.com"
KEY_TYPE="RSA"
KEY_LENGTH="4096"
EXPIRATION="1y" # キーの有効期限

# 確認メッセージ
echo "This script will:"
echo "1. Generate a new GPG key pair (if no key exists)."
echo "2. Initialize 'pass' with the GPG key."
echo "3. Configure Git to use GPG for credential storage."
read -p "Do you want to proceed? (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
  echo "Operation canceled."
  exit 0
fi

# GPGキーの存在確認
GPG_KEY_ID=$(gpg --list-keys --with-colons | grep "^pub" | cut -d':' -f5 || true)

if [[ -z "$GPG_KEY_ID" ]]; then
  echo "No existing GPG key found. Generating a new key..."

  gpg --generate-key

  # 新しいキーIDを取得
  GPG_KEY_ID=$(gpg --list-keys --with-colons | grep "^pub" | cut -d':' -f5)
  echo "New GPG key generated: $GPG_KEY_ID"
else
  echo "Existing GPG key found: $GPG_KEY_ID"
fi

# passの初期化
if ! command -v pass >/dev/null 2>&1; then
  echo "'pass' is not installed. Please install it and rerun the script."
  exit 1
fi

if ! pass ls >/dev/null 2>&1; then
  echo "Initializing 'pass' with GPG key ID: $GPG_KEY_ID..."
  pass init "$GPG_KEY_ID"
else
  echo "'pass' is already initialized."
fi

# Gitの認証情報ストア設定
echo "Configuring Git to use GPG for credential storage..."
git config --global credential.credentialStore gpg

echo "Setup completed successfully!"

