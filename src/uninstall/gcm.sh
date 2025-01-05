#!/usr/bin/env bash
set -e

# 1. そもそも GCM が入っていなければ何もしない
if ! command -v git-credential-manager &>/dev/null; then
  echo "[INFO] Git Credential Manager is not installed. Nothing to do."
  exit 0
fi

# 2. GCM の実行ファイルパスを確認 (例: /usr/local/bin/git-credential-manager)
GCM_PATH="$(command -v git-credential-manager)"
echo "[INFO] Found GCM at: ${GCM_PATH}"

# 3. Git の設定から GCM を外す
#    ~/.gitconfig の credential.helper 設定を削除
echo "[INFO] Running 'git-credential-manager unconfigure' ..."
git-credential-manager unconfigure || true

# 4. GCM 実行ファイル本体を削除
echo "[INFO] Removing GCM binary..."
sudo rm -f "${GCM_PATH}"

# 5. 付随ファイルの削除
#    ※ もし tar.gz 展開時に /usr/local/bin 直下に作られたファイルがあればここでまとめて消す。
#    例: libHarfBuzzSharp.so, libSkiaSharp.so, NOTICE など
POSSIBLE_FILES=(
  "/usr/local/bin/libHarfBuzzSharp.so"
  "/usr/local/bin/libSkiaSharp.so"
  "/usr/local/bin/NOTICE"
)

echo "[INFO] Removing associated files (if they exist)..."
for f in "${POSSIBLE_FILES[@]}"; do
  if [ -f "$f" ]; then
    echo "  - removing $f"
    sudo rm -f "$f"
  fi
done

echo "[INFO] GCM (and associated files) uninstalled successfully."

