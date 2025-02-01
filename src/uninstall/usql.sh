#!/bin/bash

# Exit codes
readonly E_SUCCESS=0
readonly E_HOMEBREW_NOT_FOUND=1
readonly E_UNINSTALL_ERROR=2
readonly E_SUDO_USED=3

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Cleanup function
cleanup() {
    if [ $? -ne 0 ]; then
        log_error "Uninstallation failed. Please check the error messages above."
    fi
}

# Set up trap for cleanup
trap cleanup EXIT

# Stop on error, undefined variables, and propagate pipe errors
set -euo pipefail
IFS=$'\n\t'

# Check if script is being run with sudo
if [ "$(id -u)" = 0 ]; then
    log_error "This script should not be run with sudo or as root."
    log_error "Homebrew should be run as a non-root user."
    exit ${E_SUDO_USED}
fi

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    log_error "Homebrew is not installed. Nothing to uninstall."
    exit ${E_HOMEBREW_NOT_FOUND}
fi

# Check if usql is installed
if ! brew list usql &> /dev/null; then
    log_info "usql is not installed. Nothing to uninstall."
    exit ${E_SUCCESS}
fi

log_info "Uninstalling usql..."

# Attempt uninstallation
if ! brew uninstall xo/xo/usql; then
    log_error "Failed to uninstall usql."
    exit ${E_UNINSTALL_ERROR}
fi

# Verify uninstallation
if brew list usql &> /dev/null; then
    log_error "Uninstallation verification failed. usql is still installed."
    exit ${E_UNINSTALL_ERROR}
else
    log_info "usql uninstallation completed successfully."
fi

exit ${E_SUCCESS} 