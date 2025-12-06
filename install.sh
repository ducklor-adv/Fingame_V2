#!/bin/bash

set -e

echo "=== Installing Docker, Docker Compose, Node.js, npm on Ubuntu 22.04 ==="

# Update system
apt-get update

# Install Docker
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

# Install Docker Compose
apt-get install -y docker-compose-plugin

# Install Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Verify installations
echo ""
echo "=== Installation Complete ==="
docker --version
docker compose version
node --version
npm --version
