#!/bin/bash
set -e
k3d cluster delete bonus
echo "---------- Creating k3d cluster ----------"
k3d cluster create bonus \
  -p "8888:80@loadbalancer" \
  -p "8929:8929@loadbalancer" \
  --wait

echo "---------- Creating namespaces ----------"
kubectl create namespace argocd || true
kubectl create namespace dev || true
kubectl create namespace gitlab || true

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

echo "---------- Installing GitLab via Helm ----------"
helm repo add gitlab https://charts.gitlab.io/ || true
helm repo update

helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  --values ../confs/gitlab-values.yaml \
  --timeout 10m \
  --wait

echo "---------- GitLab is up ----------"
echo "Getting GitLab root password..."
kubectl get secret gitlab-gitlab-initial-root-password \
  -n gitlab \
  -o jsonpath='{.data.password}' | base64 -d; echo

echo "---------- Port-forwarding GitLab ----------"
kubectl port-forward svc/gitlab-webservice-default \
  -n gitlab 8181:8080 &
PF_PID=$!
echo "GitLab available at http://localhost:8181 (pid: $PF_PID)"

sleep 5

echo "---------- Applying ArgoCD Ingress ----------"
kubectl apply -f ../confs/ingress.yaml

echo "---------- Done ----------"
echo ""
echo "Next steps:"
echo "1. Open http://localhost:8181 — login as root with password above"
echo "2. Create a new project called 'playground'"
echo "3. Push your manifests to it"
echo "4. Run: kubectl apply -f ../confs/application.yaml"
echo ""
echo "ArgoCD UI: http://localhost:8888"
echo "ArgoCD password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
