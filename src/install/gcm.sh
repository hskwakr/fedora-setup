#!/usr/bin/env bash
set -e

if command -v git-credential-manager &>/dev/null; then
  echo "[INFO] Git Credential Manager is already installed. Skip installation."
  exit 0
fi

REPO="git-ecosystem/git-credential-manager"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"

echo "[INFO] Fetching latest release info from: ${API_URL}"
LATEST_RELEASE_JSON=$(curl -s "${API_URL}")

# 'jq' で:
# 1. アセット一覧 (.assets[]) を順番に取り出し
# 2. ファイル名 (.name) が ".tar.gz" で終わるものだけに絞る
# 3. "linux_amd64" を含むものだけに絞る
# 4. "symbols" を含まないものだけに絞る
# 5. 絞り込んだ結果が複数ある場合、配列化([ ... ])して .[0] つまり最初の1つを取り出す
# 6. 最後に .browser_download_url を取得

TAR_GZ_URL=$(
  echo "${LATEST_RELEASE_JSON}" \
    | jq -r '[ 
        .assets[] 
        | select(.name | endswith(".tar.gz")) 
        | select(.name | contains("linux_amd64")) 
        | select(.name | contains("symbols") | not) 
      ][0].browser_download_url'
)

if [ -z "${TAR_GZ_URL}" ] || [ "${TAR_GZ_URL}" = "null" ]; then
  echo "[ERROR] No matching tar.gz asset found."
  exit 1
fi

echo "[INFO] Downloading tar.gz from: ${TAR_GZ_URL}"
curl -LO "${TAR_GZ_URL}"

TARBALL="$(basename "$TAR_GZ_URL")"

if [ ! -f "$TARBALL" ]; then
  echo "[ERROR] Download failed or file not found: $TARBALL"
  exit 1
fi

echo "[INFO] Extracting $TARBALL into /usr/local/bin ..."
sudo tar -xvf "$TARBALL" -C /usr/local/bin

echo "[INFO] Configuring Git Credential Manager ..."
git-credential-manager configure

if [ -f "$TARBALL" ]; then
  echo "[INFO] Cleaning up: removing $TARBALL"
  rm -f "$TARBALL"
fi

echo "[INFO] Done! GCM installed & configured, and tarball cleaned up."

