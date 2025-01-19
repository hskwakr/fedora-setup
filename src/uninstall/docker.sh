#!/usr/bin/env bash

# Exit on any error
set -euo pipefail

# ------------------------------------------------------------------------------
# Require running as root (or via sudo)
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (e.g., 'sudo ./uninstall.sh')."
  exit 1
fi

# Variables
DOCKER_PACKAGES=(
  docker-ce
  docker-ce-cli
  containerd.io
  docker-buildx-plugin
  docker-compose-plugin
  docker
  docker-client
  docker-client-latest
  docker-common
  docker-latest
  docker-latest-logrotate
  docker-logrotate
  docker-selinux
  docker-engine-selinux
  docker-engine
)

DOCKER_DIRS=(
  /var/lib/docker
  /etc/docker
  ~/.docker
  /var/run/docker.sock
)

# Functions
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# ------------------------------------------------------------------------------
# Stop and disable Docker service
# ------------------------------------------------------------------------------
log "Stopping and disabling Docker service..."
if systemctl is-active --quiet docker; then
  systemctl stop docker
  log "Docker service stopped."
else
  log "Docker service is not running."
fi

if systemctl is-enabled --quiet docker; then
  systemctl disable docker
  log "Docker service disabled."
else
  log "Docker service is not enabled."
fi

# ------------------------------------------------------------------------------
# Stop and remove all containers
# ------------------------------------------------------------------------------
log "Stopping and removing all Docker containers..."
if [ -d /var/lib/docker ]; then
  CONTAINERS=$(docker ps -aq || true)
  if [ -n "$CONTAINERS" ]; then
    while read -r container; do
      if ! docker stop "$container"; then
        log "Failed to stop container ID: $container"
      fi
    done <<< "$CONTAINERS"
    docker rm -v $CONTAINERS || log "Failed to remove some containers."
  else
    log "No Docker containers found."
  fi
else
  log "Docker data directory not found. Skipping container cleanup."
fi

# ------------------------------------------------------------------------------
# Remove Docker images
# ------------------------------------------------------------------------------
log "Removing all Docker images..."
IMAGES=$(docker images -aq || true)
if [ -n "$IMAGES" ]; then
  while read -r image; do
    if ! docker rmi -f "$image"; then
      log "Failed to remove image ID: $image"
    fi
  done <<< "$IMAGES"
else
  log "No Docker images found."
fi

# ------------------------------------------------------------------------------
# Remove Docker networks
# ------------------------------------------------------------------------------
log "Removing all custom Docker networks..."
docker network prune -f || log "No custom networks to prune."

# ------------------------------------------------------------------------------
# Remove Docker volumes
# ------------------------------------------------------------------------------
log "Removing all unused Docker volumes..."
docker volume prune -f || log "No volumes to prune."

# ------------------------------------------------------------------------------
# Remove Docker packages
# ------------------------------------------------------------------------------
log "Removing Docker packages..."
dnf remove -y "${DOCKER_PACKAGES[@]}"

# ------------------------------------------------------------------------------
# Remove Docker files, directories, and symbolic links
# ------------------------------------------------------------------------------
log "Removing Docker files, directories, and symbolic links..."
for dir in "${DOCKER_DIRS[@]}"; do
  if [ -L "$dir" ]; then
    unlink "$dir"
    log "Unlinked symbolic link $dir."
  elif [ -e "$dir" ]; then
    rm -rf "$dir"
    log "Removed $dir."
  else
    log "$dir does not exist. Skipping."
  fi

done

# ------------------------------------------------------------------------------
# Additional cleanup
# ------------------------------------------------------------------------------
log "Checking for dangling symlinks or unused dependencies..."
dnf autoremove -y

# ------------------------------------------------------------------------------
# Validation and final checks
# ------------------------------------------------------------------------------
log "Validating uninstallation..."
# Check if any Docker-related processes are still running
if pgrep -x docker > /dev/null; then
  log "Warning: Docker-related processes are still running."
else
  log "No Docker-related processes found."
fi

# Check for remaining Docker directories
for dir in "${DOCKER_DIRS[@]}"; do
  if [ -e "$dir" ]; then
    log "Warning: Directory $dir still exists."
  fi

done

# ------------------------------------------------------------------------------
# Completion message
# ------------------------------------------------------------------------------
log "Docker uninstalled successfully, including all containers, images, and volumes."
