#!/bin/bash

# Error handling configuration
set -e
set -o pipefail
set -u

# Constants
readonly FEDORA_VERSION="41"
readonly REQUIRED_PACKAGES=(
    "akmod-nvidia"
    "xorg-x11-drv-nvidia-cuda"
    "kernel-devel"
    "kernel-headers"
)
readonly REQUIRED_SYSTEM_COMMANDS=(
    "dnf"
    "rpm"
    "lsmod"
    "grep"
    "dracut"
)

# Logging functions
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

log_warning() {
    echo "[WARNING] $1" >&2
}

log_step() {
    echo "[STEP $1] $2"
}

log_substep() {
    echo "  → $1"
}

# Check if a command exists
check_command() {
    if ! command -v "$1" &>/dev/null; then
        log_error "Required command '$1' not found."
        return 1
    fi
    return 0
}

# Check all required commands
check_dependencies() {
    log_step "0" "Checking system dependencies..."
    local missing_deps=0

    # Check only system commands that should be pre-installed
    for cmd in "${REQUIRED_SYSTEM_COMMANDS[@]}"; do
        if ! check_command "$cmd"; then
            missing_deps=$((missing_deps + 1))
        fi
    done

    # Check for systemd (required for service management)
    if ! pidof systemd &>/dev/null; then
        log_error "systemd is required but not running."
        missing_deps=$((missing_deps + 1))
    fi

    # Check for secure boot status
    if [ -d "/sys/firmware/efi" ]; then
        if mokutil --sb-state &>/dev/null; then
            if mokutil --sb-state | grep -q "SecureBoot enabled"; then
                log_warning "Secure Boot is enabled. You may need to sign the NVIDIA kernel module."
            fi
        fi
    fi

    if [ $missing_deps -gt 0 ]; then
        log_error "Found ${missing_deps} missing system dependencies. Please install them first."
        return 1
    fi

    log_substep "All system dependencies are satisfied."
    return 0
}

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run with sudo privileges."
    log_error "Please run: sudo $0"
    exit 1
fi

# Run dependency check
if ! check_dependencies; then
    exit 1
fi

# Cleanup function
cleanup() {
    local exit_code=$?
    log_info "Script execution completed. Exit code: $exit_code"
    exit $exit_code
}

trap cleanup EXIT

# Version check
if [ "$(rpm -E %fedora)" != "$FEDORA_VERSION" ]; then
    log_warning "This script is designed for Fedora ${FEDORA_VERSION}."
    read -p "Continue anyway? (y/N): " response
    if [[ ! $response =~ ^[Yy]$ ]]; then
        log_info "Installation aborted."
        exit 1
    fi
fi

log_info "Fedora ${FEDORA_VERSION}: Installing NVIDIA drivers..."

# Check if RPM Fusion repositories are already configured
log_step "1" "Checking RPM Fusion repositories..."
if ! rpm -q rpmfusion-free-release rpmfusion-nonfree-release &>/dev/null; then
    log_substep "RPM Fusion not installed. Installing now..."
    sudo dnf install -y \
        https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
else
    log_substep "RPM Fusion is already enabled. Skipping..."
fi

# System update
log_step "2" "Updating system packages..."
sudo dnf upgrade -y

# Install required packages
log_step "3" "Installing NVIDIA driver packages..."
sudo dnf install -y "${REQUIRED_PACKAGES[@]}"

# Check if kernel module is loaded
log_step "4" "Checking NVIDIA kernel module..."
if ! lsmod | grep -q nvidia; then
    log_substep "NVIDIA module not loaded. Checking akmods..."
    
    # Check if module is pre-built
    if [ ! -f "/usr/lib/modules/$(uname -r)/extra/nvidia.ko" ]; then
        log_substep "NVIDIA kernel module not found. Running akmods..."
        sudo akmods --verbose
    else
        log_substep "NVIDIA kernel module already built. Skipping..."
    fi
else
    log_substep "NVIDIA kernel module is already loaded."
fi

# Check if NVIDIA module is included in initramfs
log_step "5" "Checking initramfs..."
if ! lsinitrd | grep -q nvidia; then
    log_substep "NVIDIA module not found in initramfs. Running dracut..."
    sudo dracut --force
else
    log_substep "NVIDIA module found in initramfs. Skipping..."
fi

# Post-installation check
log_step "6" "Verifying installation..."
if nvidia-smi &>/dev/null; then
    log_substep "NVIDIA driver successfully installed."
    nvidia-smi
else
    log_error "NVIDIA driver installation might have issues."
fi

log_info "Installation complete. Please restart your system."
log_info "Run: sudo reboot"
