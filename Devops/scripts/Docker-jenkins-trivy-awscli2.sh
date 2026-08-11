#!/usr/bin/env bash

# Exit immediately if any command fails
set -e

echo "==============================================="
echo "==> 1. Updating System Packages & Prerequisites"
echo "==============================================="
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl wget gnupg lsb-release unzip fontconfig

echo "==============================================="
echo "==> 2. Installing Java 21 (Jenkins Dependency)"
echo "==============================================="
sudo apt-get install -y openjdk-21-jdk openjdk-21-jre
java -version

echo "==============================================="
echo "==> 3. Installing Docker & Docker Compose"
echo "==============================================="
# Add Docker official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable & start Docker service
sudo systemctl enable docker
sudo systemctl start docker

echo "==============================================="
echo "==> 4. Installing Jenkins"
echo "==============================================="
# Add Jenkins GPG key
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

# Add Jenkins repository
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y jenkins

# Enable & start Jenkins service
sudo systemctl enable jenkins
sudo systemctl start jenkins

echo "==============================================="
echo "==> 5. Installing Trivy Security Scanner"
echo "==============================================="
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update -y
sudo apt-get install -y trivy

echo "==============================================="
echo "==> 6. Installing AWS CLI v2"
echo "==============================================="
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y || sudo yum install unzip -y
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws

echo "==============================================="
echo "==> 7. Configuring Permissions & Restarts"
echo "==============================================="
# Add jenkins and current user to docker group to prevent permission errors
sudo usermod -aG docker jenkins
sudo usermod -aG docker $USER || true

# Restart Jenkins to load updated user permissions and environment PATH
sudo systemctl restart jenkins

echo "==============================================="
echo "==> Installation Complete!"
echo "==============================================="
echo "Jenkins Access: http://<server-ip>:8080"
echo ""
echo "Tool Versions Installed:"
docker --version
docker compose version
java -version 2>&1 | head -n 1
trivy --version | head -n 1
aws --version
echo ""
echo "Initial Jenkins Admin Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword || true
