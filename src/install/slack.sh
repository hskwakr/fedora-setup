#!/usr/bin/env bash
set -e

echo "[WARNING] This script is deprecated.\ 
 Please install Slack via software center."

trap 'echo "[ERROR] An unexpected error occurred. Exiting..."; exit 1' ERR

check_root() {
    echo "[STEP] Checking root privileges..."
    if [ "$EUID" -ne 0 ]; then
        echo "Please run this script as root (e.g., 'sudo ./install.sh')."
        exit 1
    fi
    echo "[OK] Root privileges confirmed"
}

check_dependencies() {
    echo "[STEP] Checking Slack installation status..."
    
    if [ -d "/snap/slack" ]; then
        echo "[INFO] Slack (snap version) is already installed. Skip installation."
        return 0
    fi

    if [ -e "/usr/bin/slack" ] || [ -e "/usr/local/bin/slack" ] || [ -e "/opt/slack" ]; then
        echo "[WARNING] Slack is already installed but not via snap. Please uninstall it first."
        exit 1
    fi

    echo "[STEP] Checking dependencies..."
    if ! command -v snap &>/dev/null; then
        echo "[ERROR] Snap is not installed. Please install snap first."
        exit 1
    fi

    echo "[OK] All required dependencies are present"
}

install_slack() {
    echo "[STEP] Installing Slack..."
    sudo snap install slack --classic
    echo "[INFO] Slack installation completed successfully"
}

main() {
    check_root
    check_dependencies
    install_slack
}

main
