#!/bin/bash
set -e

echo "---------- Checking Docker ----------"
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
fi

echo "---------- Installing k3d ----------"
if ! command -v k3d &>/dev/null; then
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

echo "---------- Installing helm ----------"
if ! command -v helm &>/dev/null; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "---------- All done ----------"
kubectl version --client
k3d version
helm version
