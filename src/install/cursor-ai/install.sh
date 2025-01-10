#!/usr/bin/env bash

set -e

# Path to the local cursor.sh script (relative to this script)
SCRIPT_DIR=$(dirname "$(realpath "$0")")
CURSOR_SCRIPT="$SCRIPT_DIR/cursor.sh"

# Local bin directory
LOCAL_BIN="$HOME/.local/bin"

# Create ~/.local/bin if it doesn't exist
mkdir -p "$LOCAL_BIN"

# Copy local cursor.sh and save it as 'cursor' in ~/.local/bin
if [[ -f "$CURSOR_SCRIPT" ]]; then
    echo "Copying local Cursor installer script..."
    cp "$CURSOR_SCRIPT" "$LOCAL_BIN/cursor"
else
    echo "Error: cursor.sh not found at $CURSOR_SCRIPT"
    exit 1
fi

# Make the script executable
chmod +x "$LOCAL_BIN/cursor"

echo "Cursor installer script has been placed in $LOCAL_BIN/cursor"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
    echo "Warning: $LOCAL_BIN is not in your PATH."
    echo "To add it, run this command or add it to your shell profile:"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# Run cursor --update to download and install Cursor
echo "Downloading and installing Cursor..."
"$LOCAL_BIN/cursor" --update

echo "Installation complete. You can now run 'cursor' to start Cursor."

