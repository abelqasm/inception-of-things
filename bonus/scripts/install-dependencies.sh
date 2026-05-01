#!/bin/bash
set -e

echo "---------- Installing dependencies ----------"

echo "---------- installing HELM ----------"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash

# Install Homebrew if not present
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install Docker (Docker Desktop must be running)
if ! command -v docker &>/dev/null; then
  echo "Installing Docker..."
  brew install --cask docker
  echo "Please open Docker Desktop and wait for it to start, then re-run setup.sh"
  exit 0
fi

# Check Docker is running
if ! docker info &>/dev/null; then
  echo "Docker is not running. Please start Docker Desktop first."
  exit 1
fi

echo "---------- Installing kubectl ----------"
if ! command -v kubectl &>/dev/null; then
  ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
  KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
  curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/darwin/${ARCH}/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/kubectl
  echo "kubectl installed"
else
  echo "kubectl already installed: $(kubectl version --client --short 2>/dev/null)"
fi

echo "---------- Installing k3d ----------"
if ! command -v k3d &>/dev/null; then
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
  echo "k3d installed"
else
  echo "k3d already installed: $(k3d version)"
fi

echo "---------- All done ----------"
kubectl version --client
k3d version