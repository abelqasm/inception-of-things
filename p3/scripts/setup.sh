#!/bin/bash
set -e

echo "---------- Creating k3d cluster ----------"
k3d cluster create p3 -p "8080:80@loadbalancer" --wait

echo "---------- Creating namespaces ----------"
kubectl create namespace argocd || true
kubectl create namespace dev || true

echo "---------- Installing Argo CD ----------"
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "---------- Waiting for Argo CD ----------"
kubectl wait -n argocd --for=condition=Ready pods \
  --all --timeout=300s
echo "---------- Argo CD is up ----------"

echo "---------- Disabling Argo CD HTTPS redirect ----------"
kubectl patch configmap argocd-cmd-params-cm -n argocd \
  --type merge -p '{"data":{"server.insecure":"true"}}'
kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout status deployment argocd-server -n argocd

echo "---------- Applying Ingress ----------"
kubectl apply -f /Users/hamza/Desktop/inception-of-things/p3/confs/ingress.yaml

echo "---------- Applying Argo CD Application ----------"
kubectl apply -f /Users/hamza/Desktop/inception-of-things/p3/confs/application.yaml

echo "---------- Done ----------"
echo "Argo CD UI: http://localhost:8080"
echo "Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"