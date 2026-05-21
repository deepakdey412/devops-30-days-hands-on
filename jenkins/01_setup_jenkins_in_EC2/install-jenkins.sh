#!/bin/bash

set -e

echo "🔄 Updating system..."
sudo apt update -y

echo "☕ Installing Java (required for Jenkins)..."
sudo apt install -y fontconfig openjdk-21-jre

echo "✔ Java version:"
java -version

echo "🔑 Adding Jenkins LTS repo key..."
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

echo "📦 Adding Jenkins repository..."
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
/etc/apt/sources.list.d/jenkins.list > /dev/null

echo "🔄 Updating package list again..."
sudo apt update -y

echo "⚙ Installing Jenkins LTS..."
sudo apt install -y jenkins

echo "🚀 Starting Jenkins service..."
sudo systemctl start jenkins

echo "🔁 Enabling Jenkins on boot..."
sudo systemctl enable jenkins

echo "📊 Jenkins status:"
sudo systemctl status jenkins --no-pager

echo "✅ Jenkins LTS installation completed!"
echo "👉 Open in browser: http://<EC2-PUBLIC-IP>:8080"