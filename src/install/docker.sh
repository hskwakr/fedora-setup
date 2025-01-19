#!/usr/bin/env bash

# Exit on any error
set -e

# ------------------------------------------------------------------------------
# Require running as root (or via sudo)
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (e.g., 'sudo ./install.sh')."
  exit 1
fi

# Variables
DOCKER_REPO="https://download.docker.com/linux/fedora/docker-ce.repo"
CURRENT_USER=${SUDO_USER:-${USER}}

# ------------------------------------------------------------------------------
# Remove old Docker versions if installed
# ------------------------------------------------------------------------------
echo "Checking for old Docker versions to remove..."
if dnf list installed | grep -q "^docker"; then
  echo "Old Docker versions detected. Removing..."
  if ! sudo dnf remove -y \
    docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-selinux \
    docker-engine-selinux \
    docker-engine; then
    echo "Failed to remove old Docker versions. Please check for conflicts or manual installations."
    exit 1
  fi
else
  echo "No old Docker versions found."
fi

# ------------------------------------------------------------------------------
# Install required dependencies
# ------------------------------------------------------------------------------
echo "Installing required dependencies..."
if ! sudo dnf -y install dnf-plugins-core; then
  echo "Failed to install required dependencies. Check your network connection and package manager settings."
  exit 1
fi

# ------------------------------------------------------------------------------
# Add Docker repository
# ------------------------------------------------------------------------------
echo "Adding Docker repository..."
if ! sudo dnf config-manager addrepo --overwrite --from-repofile="${DOCKER_REPO}"; then
  echo "Failed to add Docker repository. Check your network connection."
  exit 1
fi

# ------------------------------------------------------------------------------
# Install Docker packages
# ------------------------------------------------------------------------------
echo "Installing Docker packages..."
if ! sudo dnf install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin; then
  echo "Failed to install Docker packages. Check for conflicts or missing dependencies."
  exit 1
fi

# Enable and start Docker service
echo "Enabling and starting Docker service..."
if ! sudo systemctl enable --now docker; then
  echo "Failed to enable and start Docker service. Check system logs for details."
  exit 1
fi

# ------------------------------------------------------------------------------
# Configure Docker group
# ------------------------------------------------------------------------------
echo "Configuring Docker group..."
sudo groupadd docker || echo "Docker group already exists."
echo "Adding user: ${CURRENT_USER} to docker group"
sudo gpasswd -a "$CURRENT_USER" docker
sudo chown root:docker /var/run/docker.sock
sudo chmod 660 /var/run/docker.sock
sudo systemctl restart docker

echo "Docker group configuration completed."

# ------------------------------------------------------------------------------
# Verify Docker installation
# ------------------------------------------------------------------------------
echo "Verifying Docker installation..."
if ! systemctl is-active --quiet docker; then
  echo "Docker installation failed. Please check logs."
  echo "Possible steps to troubleshoot the issue:"
  echo "1. Check the system logs using 'journalctl -u docker'."
  echo "2. Verify that the Docker service is enabled and running using 'systemctl status docker'."
  echo "3. Ensure that no conflicting services or applications are using Docker ports."
  echo "4. Reinstall Docker if necessary by removing it and rerunning this script."
  exit 1
fi

# ------------------------------------------------------------------------------
# Completion message
# ------------------------------------------------------------------------------
echo "Docker installed successfully."
echo "Docker version: $(docker --version)"
echo "\n**************************************************"
echo "* To apply group changes:                     *"
echo "* newgrp docker                               *"
echo "* Or log out and log back in.                 *"
echo "**************************************************\n"
