#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "==============================================="
echo "==> 1. Updating System Packages & Dependencies"
echo "==============================================="
sudo apt update
sudo apt install -y ca-certificates curl wget fontconfig gnupg lsb-release

echo "==============================================="
echo "==> 2. Installing Java 21 & Setting Default"
echo "==============================================="
sudo apt install -y openjdk-21-jdk openjdk-21-jre
java -version

echo "==============================================="
echo "==> 3. Installing Docker & Docker Compose"
echo "==============================================="
# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository to Apt sources
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker service
sudo systemctl enable docker
sudo systemctl start docker

echo "==============================================="
echo "==> 4. Installing Jenkins"
echo "==============================================="
# Add Jenkins GPG key
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

# Add Jenkins repository to Apt sources
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update
sudo apt install -y jenkins

# Enable and start Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

echo "==============================================="
echo "==> 5. Configuring Docker Permissions for Jenkins"
echo "==============================================="
# Add jenkins user to the docker group to avoid socket permission errors
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

echo "==============================================="
echo "==> 6. Deploying SonarQube Container"
echo "==============================================="
# Set required sysctl limits for SonarQube/Elasticsearch
sudo sysctl -w vm.max_map_count=524288
echo "vm.max_map_count=524288" | sudo tee -a /etc/sysctl.conf

# Remove any existing stopped sonarqube container
# sudo docker rm -f sonarqube || true

# Run active SonarQube Community image
# sudo docker run -d --name sonarqube \
#   -p 9000:9000 \
#   -v sonarqube_data:/opt/sonarqube/data \
#   -v sonarqube_extensions:/opt/sonarqube/extensions \
#   -v sonarqube_logs:/opt/sonarqube/logs \
#   sonarqube:community

echo "==============================================="
echo "==> Installation & Deployment Complete!"
echo "==============================================="
echo "Jenkins URL:   http://<your-server-ip>:8080"
echo "SonarQube URL: http://<your-server-ip>:9000 (Default: admin/admin)"
echo ""
echo "Initial Jenkins Admin Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword || true
