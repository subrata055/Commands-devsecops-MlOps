#!/bin/bash

set -e

# ============================================================
# EKS Tool Installation Script
# Ubuntu Linux - x86_64 / amd64
# ============================================================

echo "============================================================"
echo "     AWS EKS Tools Installation Script"
echo "============================================================"

# ------------------------------------------------------------
# Variables
# ------------------------------------------------------------

AWS_REGION="us-east-1"
KUBECTL_VERSION="1.35.3"

# ------------------------------------------------------------
# Check root/sudo access
# ------------------------------------------------------------

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo:"
    echo "sudo $0"
    exit 1
fi

# ------------------------------------------------------------
# Detect architecture
# ------------------------------------------------------------

ARCH=$(uname -m)

if [ "$ARCH" != "x86_64" ]; then
    echo "ERROR: This script currently supports x86_64 only."
    echo "Detected architecture: $ARCH"
    exit 1
fi

echo "[INFO] Architecture: $ARCH"

# ------------------------------------------------------------
# Update package information
# ------------------------------------------------------------

echo
echo "[1/8] Updating APT package information..."

apt-get update -y

# Required packages
apt-get install -y \
    curl \
    unzip \
    tar \
    gzip \
    ca-certificates \
    gnupg \
    lsb-release

# ============================================================
# AWS CLI v2
# ============================================================

echo
echo "[2/8] Installing AWS CLI v2..."

if command -v aws >/dev/null 2>&1; then
    echo "[INFO] AWS CLI already installed."
    aws --version
else

    cd /tmp

    rm -f awscliv2.zip

    echo "[INFO] Downloading AWS CLI v2..."

    curl -fsSL \
        "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
        -o awscliv2.zip

    echo "[INFO] Extracting AWS CLI..."

    unzip -q awscliv2.zip

    echo "[INFO] Installing AWS CLI..."

    ./aws/install

    rm -rf aws awscliv2.zip

    echo "[INFO] AWS CLI installation completed."

    aws --version
fi

# ============================================================
# kubectl
# ============================================================

echo
echo "[3/8] Installing kubectl ${KUBECTL_VERSION}..."

if command -v kubectl >/dev/null 2>&1; then
    echo "[INFO] kubectl already installed."
    kubectl version --client
else

    cd /tmp

    echo "[INFO] Downloading kubectl..."

    curl -fsSL \
        "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
        -o kubectl

    chmod +x kubectl

    mv kubectl /usr/local/bin/kubectl

    echo "[INFO] kubectl installation completed."

    kubectl version --client
fi

# ============================================================
# Helm
# ============================================================

echo
echo "[4/8] Installing Helm..."

if command -v helm >/dev/null 2>&1; then
    echo "[INFO] Helm already installed."
    helm version
else

    echo "[INFO] Installing Helm using official installer..."

    curl -fsSL \
        https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
        | bash

    echo "[INFO] Helm installation completed."

    helm version
fi

# ============================================================
# eksctl
# ============================================================

echo
echo "[5/8] Installing eksctl..."

if command -v eksctl >/dev/null 2>&1; then
    echo "[INFO] eksctl already installed."
    eksctl version
else

    cd /tmp

    echo "[INFO] Downloading latest eksctl..."

    curl -fsSL \
        "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" \
        -o eksctl.tar.gz

    echo "[INFO] Extracting eksctl..."

    tar -xzf eksctl.tar.gz

    echo "[INFO] Installing eksctl..."

    install -m 0755 eksctl /usr/local/bin/eksctl

    rm -f eksctl.tar.gz eksctl

    echo "[INFO] eksctl installation completed."

    eksctl version
fi

# ============================================================
# AWS Region
# ============================================================

echo
echo "[6/8] Configuring AWS region..."

aws configure set region "$AWS_REGION"

echo "[INFO] AWS Region:"
aws configure get region

# ============================================================
# Verify installations
# ============================================================

echo
echo "[7/8] Verifying installed tools..."

echo
echo "------------------------------------------------------------"
echo "AWS CLI"
echo "------------------------------------------------------------"
aws --version

echo
echo "------------------------------------------------------------"
echo "kubectl"
echo "------------------------------------------------------------"
kubectl version --client

echo
echo "------------------------------------------------------------"
echo "Helm"
echo "------------------------------------------------------------"
helm version

echo
echo "------------------------------------------------------------"
echo "eksctl"
echo "------------------------------------------------------------"
eksctl version

# ============================================================
# AWS STS Identity
# ============================================================

echo
echo "[8/8] Checking AWS identity using STS..."

echo
echo "------------------------------------------------------------"
echo "AWS STS Caller Identity"
echo "------------------------------------------------------------"

if aws sts get-caller-identity; then

    echo
    echo "============================================================"
    echo "SUCCESS!"
    echo "============================================================"
    echo
    echo "Installed tools:"
    echo "  ✓ AWS CLI v2"
    echo "  ✓ kubectl"
    echo "  ✓ Helm"
    echo "  ✓ eksctl"
    echo
    echo "AWS Region:"
    echo "  $AWS_REGION"
    echo
    echo "AWS STS authentication:"
    echo "  ✓ Successful"
    echo
    echo "You are ready to create the EKS cluster."
    echo "============================================================"

else

    echo
    echo "============================================================"
    echo "WARNING"
    echo "============================================================"
    echo
    echo "The tools were installed successfully, but"
    echo "AWS STS authentication failed."
    echo
    echo "Configure AWS credentials using:"
    echo
    echo "    aws configure"
    echo
    echo "Then test:"
    echo
    echo "    aws sts get-caller-identity"
    echo "============================================================"

    exit 1
fi
