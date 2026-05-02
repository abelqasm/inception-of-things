#!/bin/bash
set -e

echo "---------- Cleaning up ----------"
pkill -f "port-forward" 2>/dev/null || true
k3d cluster delete bonus 2>/dev/null || true

echo "---------- Creating k3d cluster ----------"
k3d cluster create bonus \
  -p "8888:80@loadbalancer" \
  --k3s-arg "--disable=traefik@server:0" \
  --wait

echo "---------- Creating namespaces ----------"
kubectl create namespace argocd || true
kubectl create namespace dev || true
kubectl create namespace gitlab || true

echo "---------- Installing GitLab via Helm ----------"
helm repo add gitlab https://charts.gitlab.io/ 2>/dev/null || true
helm repo update

helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  --values ../confs/gitlab-values.yaml \
  --timeout 15m

echo "---------- GitLab Helm install initiated ----------"
echo "Waiting for GitLab pods (this takes 8-12 minutes)..."

# Wait for webservice to be ready
until kubectl get pod -n gitlab -l app=webservice 2>/dev/null | grep -q "Running"; do
  echo "  waiting for GitLab webservice..."
  sleep 20
done

kubectl wait --for=condition=Ready pod \
  -l app=webservice \
  -n gitlab --timeout=600s

echo "---------- Installing Argo CD ----------"
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "---------- Waiting for Argo CD ----------"
kubectl wait -n argocd --for=condition=Ready pods \
  --all --timeout=300s

echo "---------- Disabling Argo CD HTTPS ----------"
kubectl patch configmap argocd-cmd-params-cm -n argocd \
  --type merge -p '{"data":{"server.insecure":"true"}}'
kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout status deployment argocd-server -n argocd

echo "---------- Getting GitLab root password ----------"
GITLAB_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password \
  -n gitlab -o jsonpath='{.data.password}' | base64 -d)

echo "---------- Port forwarding ----------"
kubectl port-forward svc/gitlab-webservice-default \
  -n gitlab 8181:8181 &
kubectl port-forward svc/argocd-server \
  -n argocd 8080:80 &
sleep 3

echo ""
echo "=========================================="
echo "GitLab UI:    http://localhost:8181"
echo "GitLab user:  root"
echo "GitLab pass:  ${GITLAB_PASSWORD}"
echo ""
echo "ArgoCD UI:    http://localhost:8080"
echo "ArgoCD pass:  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "Next steps:"
echo "1. Open GitLab — login as root"
echo "2. Create public project 'playground'"
echo "3. Push manifests:"
echo "   git remote add gitlab http://localhost:8181/root/playground.git"
echo "   git push gitlab main"
echo "4. kubectl apply -f ../confs/application.yaml"
echo "5. kubectl port-forward svc/playground-service -n dev 8888:80 &"
echo "6. curl http://localhost:8888/"
echo "=========================================="
