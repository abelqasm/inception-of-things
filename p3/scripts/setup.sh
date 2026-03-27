#!/bin/bash

set -e

# check Docker first
if ! docker info >/dev/null 2>&1; then
    echo "Docker daemon is not running or accessible"
    exit 1
fi

echo "---------- Creating k3d cluster ---------"
k3d cluster create p3 -p 8080:80@loadbalancer

sleep 10

echo "---------- Configuring Kubectl ---------"
export KUBECONFIG=$(k3d kubeconfig write p3)

echo "---------- Creating argocd and dev namespaces ---------"
kubectl create namespace argocd
kubectl create namespace dev

sleep 3

echo "---------- Installing argocd into cluster ---------"
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
