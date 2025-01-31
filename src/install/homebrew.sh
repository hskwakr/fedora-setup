#!/usr/bin/env bash

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Constants
readonly BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
readonly MIN_KERNEL_VERSION="3.2"
readonly REQUIRED_ARCH="x86_64"
readonly REQUIRED_DEPS=("curl" "git" "gcc" "make")
readonly DNF_PACKAGES=("procps-ng" "curl" "file" "git")

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Utility functions
log() {
    local level=$1
    local msg=$2
    local color

    case "$level" in
        "INFO")  color="$GREEN" ;;
        "WARN")  color="$YELLOW" ;;
        "ERROR") color="$RED" ;;
        *)       color="$NC" ;;
    esac

    echo -e "${color}[${level}]${NC} ${msg}" >&2
}

log_info()  { log "INFO" "$1"; }
log_warn()  { log "WARN" "$1"; }
log_error() { log "ERROR" "$1"; }

die() {
    log_error "$1"
    exit 1
}

cleanup() {
    local exit_code=$?
    [ -n "${INSTALL_SCRIPT:-}" ] && [ -f "$INSTALL_SCRIPT" ] && rm -f "$INSTALL_SCRIPT"
    exit $exit_code
}

# Validation functions
validate_user() {
    log_info "Validating user permissions..."
    
    log_info "Checking if running as root..."
    [ "$(id -u)" -eq 0 ] && die "Homebrew should not be run under sudo or as root"
    
    local current_user login_user
    current_user=$(id -un)
    login_user=${LOGNAME:-}
    
    log_info "Checking LOGNAME environment variable..."
    [ -z "$login_user" ] && die "LOGNAME environment variable is not set"
    
    log_info "Verifying current user ($current_user) matches login user ($login_user)..."
    [ "$current_user" != "$login_user" ] && die "Script must be run as login user (current: $current_user, login: $login_user)"
    log_info "User validation successful"
}

validate_os() {
    log_info "Checking operating system..."
    log_info "Looking for dnf package manager..."
    command -v dnf >/dev/null 2>&1 || die "This script is designed for Fedora Linux"
    log_info "Operating system check successful"
}

validate_system() {
    log_info "Validating system requirements..."
    
    log_info "Checking CPU architecture..."
    [ "$(uname -m)" = "$REQUIRED_ARCH" ] || die "Homebrew requires a 64-bit x86_64 CPU"

    log_info "Checking kernel version..."
    local kernel_version
    kernel_version=$(uname -r | cut -d. -f1-2)
    log_info "Current kernel version: ${kernel_version} (minimum required: ${MIN_KERNEL_VERSION})"
    bc_output=$(echo "${kernel_version} < ${MIN_KERNEL_VERSION}" | bc)
    [ "$bc_output" -eq 1 ] && die "Homebrew requires Linux ${MIN_KERNEL_VERSION} or newer"
    log_info "System requirements validation successful"
}

validate_dependencies() {
    log_info "Checking required dependencies..."
    local missing_deps=()

    for dep in "${REQUIRED_DEPS[@]}"; do
        log_info "Checking for ${dep}..."
        command -v "$dep" >/dev/null 2>&1 || missing_deps+=("$dep")
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_error "Please install the required packages using:"
        log_error "sudo dnf groupinstall 'Development Tools'"
        log_error "sudo dnf install ${DNF_PACKAGES[*]}"
        exit 1
    fi
    log_info "All dependencies are installed"
}

check_brew_installed() {
    log_info "Checking if Homebrew is already installed..."
    if command -v brew >/dev/null 2>&1; then
        log_warn "Homebrew is already installed"
        exit 0
    fi
}

install_homebrew() {
    log_info "Starting Homebrew installation..."
    
    # Create temporary file with cleanup trap
    log_info "Creating temporary installation script..."
    INSTALL_SCRIPT=$(mktemp)
    trap cleanup EXIT
    
    log_info "Downloading Homebrew installation script from ${BREW_INSTALL_URL}..."
    # Download and verify installation script
    if ! curl -fsSL "$BREW_INSTALL_URL" -o "$INSTALL_SCRIPT"; then
        die "Failed to download Homebrew installation script"
    fi
    
    log_info "Setting execute permissions on installation script..."
    chmod +x "$INSTALL_SCRIPT"
    
    log_info "Setting up Homebrew installation directory..."
    if [ ! -d "/home/linuxbrew" ]; then
        log_info "Creating /home/linuxbrew directory (requires sudo)..."
        if ! sudo mkdir -p /home/linuxbrew; then
            die "Failed to create /home/linuxbrew directory"
        fi
    fi
    
    if [ ! -d "/home/linuxbrew/.linuxbrew" ]; then
        log_info "Creating /home/linuxbrew/.linuxbrew directory (requires sudo)..."
        if ! sudo mkdir -p /home/linuxbrew/.linuxbrew; then
            die "Failed to create /home/linuxbrew/.linuxbrew directory"
        fi
    fi
    
    log_info "Setting appropriate permissions for Homebrew directories..."
    if ! sudo chown -R "$(id -u):$(id -g)" /home/linuxbrew; then
        die "Failed to set ownership of /home/linuxbrew"
    fi
    
    log_info "Running Homebrew installation script (this may take a few minutes)..."
    if ! "$INSTALL_SCRIPT"; then
        die "Homebrew installation failed"
    fi
    
    log_info "Verifying installation..."
    log_info "Checking for Homebrew directory at /home/linuxbrew/.linuxbrew..."
    if ! test -d /home/linuxbrew/.linuxbrew; then
        die "Homebrew directory not found after installation"
    fi
    
    log_info "Setting final permissions..."
    if ! sudo chown -R "$(id -u):$(id -g)" /home/linuxbrew/.linuxbrew; then
        die "Failed to set final ownership of Homebrew installation"
    fi
    
    log_info "Installation verification successful"
}

show_env_instructions() {
    log_info "To use Homebrew, add the following to your dotfiles:"
    cat << 'EOF'

# Homebrew environment setup
eval "$($(brew --prefix)/bin/brew shellenv)"

EOF
    log_info "After setting up the environment, run 'brew doctor' to verify the installation"
}

main() {
    log_info "Running Homebrew installation script for Fedora"
    
    validate_user
    validate_os
    validate_system
    check_brew_installed
    validate_dependencies
    install_homebrew
    show_env_instructions
    
    log_info "Homebrew installation completed successfully"
}

main
