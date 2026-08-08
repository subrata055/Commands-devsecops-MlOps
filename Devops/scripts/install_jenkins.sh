#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "==> Updating package index and installing Java 21..."
sudo apt update
sudo apt install -y fontconfig openjdk-21-jre wget
java -version

echo "==> Creating keyrings directory if it doesn't exist..."
sudo install -m 0755 -d /etc/apt/keyrings

echo "==> Adding Jenkins GPG key..."
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

echo "==> Adding Jenkins repository to Apt sources..."
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "==> Updating package index with Jenkins repository..."
sudo apt update

echo "==> Installing Jenkins..."
sudo apt install -y jenkins

echo "==> Enabling and starting Jenkins service..."
sudo systemctl enable jenkins
sudo systemctl start jenkins

echo "==> Checking Jenkins status..."
sudo systemctl status jenkins --no-pager
