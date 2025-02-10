#!/bin/bash

# Set strict mode
set -euo pipefail
IFS=$'\n\t'

# Script constants
readonly TIMEOUT_SECONDS=30
readonly DENO_INSTALL_DIR="${HOME}/.deno"
readonly DENO_BIN="${DENO_INSTALL_DIR}/bin/deno"

# Error handling
error() {
    echo "❌ Error on line $1: $2"
    exit 1
}

trap 'error ${LINENO} "$BASH_COMMAND"' ERR

# Function definitions
log_step() {
    echo "📋 Step: $1"
}

prepare_directory() {
    log_step "Preparing installation directory..."
    # Remove existing installation if exists
    if [[ -d "$DENO_INSTALL_DIR" ]]; then
        echo "  - Cleaning up existing installation..."
        rm -rf "$DENO_INSTALL_DIR"
    fi
    
    # Create fresh directory structure
    echo "  - Creating installation directory..."
    mkdir -p "${DENO_INSTALL_DIR}/bin"
    chmod 755 "${DENO_INSTALL_DIR}"
    chmod 755 "${DENO_INSTALL_DIR}/bin"
    echo "  ✓ Installation directory prepared"
}

check_dependencies() {
    log_step "Checking required dependencies..."
    local -r deps=("curl" "unzip")
    for dep in "${deps[@]}"; do
        echo "  - Checking for $dep..."
        if ! command -v "$dep" &> /dev/null; then
            error "${LINENO}" "Required command not found: $dep"
        fi
    done
    echo "  ✓ All dependencies are available"
}

check_network() {
    log_step "Checking network connectivity..."
    if ! curl --connect-timeout 5 -Is "https://deno.land" &> /dev/null; then
        error "${LINENO}" "Cannot connect to deno.land. Please check your internet connection"
    fi
    echo "  ✓ Network connection is available"
}

check_user() {
    log_step "Checking user permissions..."
    if [ "$(id -u)" -eq 0 ]; then
        echo "❌ This script cannot be run as root"
        echo "👉 Please run as a regular user"
        exit 1
    fi
    echo "  ✓ Running with correct user permissions"
}

verify_installation() {
    log_step "Verifying installation..."
    local installation_success=true

    echo "  - Checking Deno binary..."
    # Check if Deno binary exists and is executable
    if [[ ! -f "$DENO_BIN" ]]; then
        echo "❌ Deno binary not found at: $DENO_BIN"
        installation_success=false
    elif [[ ! -x "$DENO_BIN" ]]; then
        echo "❌ Deno binary is not executable at: $DENO_BIN"
        installation_success=false
    else
        echo "  ✓ Deno binary is present and executable"
    fi

    echo "  - Checking installation directory..."
    # Check if installation directory exists
    if [[ ! -d "$DENO_INSTALL_DIR" ]]; then
        echo "❌ Deno installation directory not found at: $DENO_INSTALL_DIR"
        installation_success=false
    else
        echo "  ✓ Installation directory exists"
    fi

    if [[ "$installation_success" == "false" ]]; then
        error "${LINENO}" "Installation verification failed"
    fi

    echo
    echo "✅ Deno successfully installed!"
    echo
    echo "📍 Installation location: $DENO_BIN"
    echo
    echo "🔨 To start using Deno, please:"
    echo "1. Add Deno to your PATH by running:"
    echo "   echo 'export PATH=\"${DENO_INSTALL_DIR}/bin:\$PATH\"' >> ~/.bashrc"
    echo
    echo "2. Reload your shell configuration:"
    echo "   source ~/.bashrc"
    echo
    echo "3. Verify the installation:"
    echo "   deno --version"
}

main() {
    echo "🦕 Starting Deno installation process..."
    echo

    # Pre-installation checks
    check_dependencies
    check_network
    check_user

    # Prepare installation directory
    prepare_directory

    # Execute installation script
    log_step "Installing Deno..."
    
    # Create a temporary file for capturing output
    local output_file
    output_file=$(mktemp)
    
    # Run installation with output capture
    if ! timeout "$TIMEOUT_SECONDS" sh -c "curl -fsSL https://deno.land/install.sh | DENO_INSTALL=\"$DENO_INSTALL_DIR\" sh" > "$output_file" 2>&1; then
        echo "❌ Installation command failed. Output:"
        echo "----------------------------------------"
        cat "$output_file"
        echo "----------------------------------------"
        rm -f "$output_file"
        error "${LINENO}" "Installation failed (see output above)"
    fi
    
    # Display output even on success for verification
    echo "📝 Installation output:"
    echo "----------------------------------------"
    cat "$output_file"
    echo "----------------------------------------"
    rm -f "$output_file"
    
    echo "  ✓ Installation completed"

    verify_installation
}

# Execute main process
main
