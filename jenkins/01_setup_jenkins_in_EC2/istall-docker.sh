#!/bin/bash

set -e

echo "🔄 Updating system..."
sudo apt update -y

echo "📦 Installing prerequisites..."
sudo apt install -y ca-certificates curl

echo "🔑 Creating keyrings directory..."
sudo install -m 0755 -d /etc/apt/keyrings

echo "⬇️ Adding Docker GPG key..."
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc

echo "🔐 Setting permissions..."
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "📦 Adding Docker repository..."
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

echo "🔄 Updating package list..."
sudo apt update -y

echo "🐳 Installing Docker Engine + plugins..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "🚀 Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

echo "📊 Checking Docker status..."
sudo systemctl status docker --no-pager

echo "✔ Verifying Docker version..."
docker --version

echo "🎉 Docker installation completed successfully!"