#!/usr/bin/env bash
set -e

trap 'echo "[ERROR] An unexpected error occurred. Exiting..."; exit 1' ERR

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run this script as root (e.g., 'sudo ./install.sh')."
        exit 1
    fi
}

check_dependencies() {
    if ! command -v snap &>/dev/null; then
        echo "[ERROR] Snap is not installed. Nothing to remove."
        exit 1
    fi
}

uninstall_slack() {
    if [ ! -d "/snap/slack" ]; then
        if [ -e "/usr/bin/slack" ] || [ -e "/usr/local/bin/slack" ] || [ -e "/opt/slack" ]; then
            echo "[WARNING] Slack is installed but not via snap. This script only handles snap installations."
            exit 1
        else
            echo "[INFO] Slack (snap version) is not installed. Nothing to do."
            return 0
        fi
    fi

    echo "[INFO] Removing Slack (snap version)..."
    sudo snap remove slack
    echo "[INFO] Slack has been successfully removed."
}

main() {
    check_root
    check_dependencies
    uninstall_slack
}

main
