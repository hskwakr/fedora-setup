#!/bin/bash
set -euo pipefail

# --- Global Constants ---
readonly INSTALL_ROOT="/usr"
readonly LIB_DIR="/usr/lib/ollama"
readonly SHARE_DIR="/usr/share/ollama"
readonly SYSTEMD_DIR="/etc/systemd/system"
readonly SERVICE_FILE="${SYSTEMD_DIR}/ollama.service"
readonly DOWNLOAD_BASE_URL="https://ollama.com/download"

# --- Utility Functions ---

# Log informational messages
log() {
    echo "[INFO] $*"
}

# Log error messages and exit
error_exit() {
    echo "[ERROR] $*" >&2
    exit 1
}

# Check if a required command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Download and extract a package from a given URL to a destination directory
download_and_extract() {
    local url="$1"
    local dest_dir="$2"
    local tmp_file

    tmp_file=$(mktemp)
    log "Downloading package from ${url}..."
    if ! curl -L "$url" -o "$tmp_file"; then
        rm -f "$tmp_file"
        error_exit "Failed to download package from ${url}"
    fi

    log "Extracting package to ${dest_dir}..."
    if ! tar -C "$dest_dir" -xzf "$tmp_file"; then
        rm -f "$tmp_file"
        error_exit "Failed to extract package from ${url}"
    fi

    rm -f "$tmp_file"
}

# --- Pre-checks ---

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    error_exit "Please run this script with root privileges."
fi

# Verify required commands exist
for cmd in curl tar systemctl useradd usermod logname; do
    command_exists "$cmd" || error_exit "Required command '$cmd' is not installed."
done

# Remove previous installation if it exists (adjust path if necessary)
if [ -d "${LIB_DIR}" ]; then
    log "Removing existing Ollama installation at ${LIB_DIR}..."
    rm -rf "${LIB_DIR}"
fi

# --- Determine Architecture & Set Package URLs ---
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        PACKAGE_URL="${DOWNLOAD_BASE_URL}/ollama-linux-amd64.tgz"
        ;;
    aarch64)
        PACKAGE_URL="${DOWNLOAD_BASE_URL}/ollama-linux-arm64.tgz"
        ;;
    *)
        error_exit "Unsupported architecture: $ARCH"
        ;;
esac

# --- Download and Install Main Package ---
download_and_extract "$PACKAGE_URL" "${INSTALL_ROOT}"

# --- Optional: Install AMD GPU ROCm Package ---
# If INSTALL_ROCM environment variable is set to 1, install the ROCm package.
if [ "${INSTALL_ROCM:-0}" = "1" ]; then
    ROCM_PACKAGE_URL="${DOWNLOAD_BASE_URL}/ollama-linux-amd64-rocm.tgz"
    download_and_extract "$ROCM_PACKAGE_URL" "${INSTALL_ROOT}"
fi

# --- Create System User & Group ---
# Create the system user and group if they don't exist
if ! id -u ollama >/dev/null 2>&1; then
    log "Creating system user and group for Ollama..."
    useradd -r -s /bin/false -U -m -d "${SHARE_DIR}" ollama
fi

# Add the current logged-in user to the ollama group for permissions management
current_user=$(logname)
log "Adding user '${current_user}' to the 'ollama' group..."
usermod -a -G ollama "$current_user"

# --- Create systemd Service File ---
log "Creating systemd service file at ${SERVICE_FILE}..."
cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
Environment="PATH=$PATH"

[Install]
WantedBy=default.target
EOF

# --- Reload systemd and Enable Service ---
log "Reloading systemd daemon..."
systemctl daemon-reload

log "Enabling Ollama service..."
systemctl enable ollama

log "Starting Ollama service..."
systemctl start ollama

log "Ollama installation and service setup completed successfully."
log "To check the service status, run: sudo systemctl status ollama"
