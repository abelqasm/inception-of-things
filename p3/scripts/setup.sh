#!/bin/bash
set -e

k3d cluster delete p3 2>/dev/null || true

echo "---------- Creating k3d cluster ----------"
k3d cluster create p3 \
  -p "8888:80@loadbalancer" \
  --k3s-arg "--disable=traefik@server:0" \
  --wait

echo "---------- Installing nginx ingress ----------"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.2/deploy/static/provider/cloud/deploy.yaml

echo "---------- Waiting for nginx ingress ----------"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

echo "---------- Creating namespaces ----------"
kubectl create namespace argocd || true
kubectl create namespace dev || true

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

echo "---------- Applying Argo CD Application ----------"
kubectl apply -f ../confs/application.yaml

echo "---------- Waiting for app sync ----------"
until kubectl get svc abelqasm-service -n dev 2>/dev/null; do
  echo "  waiting..."
  sleep 5
done

kubectl wait --for=condition=Ready pod \
  -l app=abelqasm -n dev --timeout=300s

echo "---------- Port forwarding app to 8888 ----------"
kubectl port-forward svc/abelqasm-service -n dev 8888:8888 &
sleep 3

echo "---------- Port forwarding ArgoCD to 8080 ----------"
kubectl port-forward svc/argocd-server -n argocd 8080:80 &
sleep 3

echo ""
curl http://localhost:8888/

# Add this at the end of setup.sh, before the echo statements
nohup bash -c 'while true; do
  kubectl port-forward svc/playground-service -n dev 8888:8888 2>/dev/null
  sleep 1
done' > /tmp/playground-pf.log 2>&1 &
echo "Auto-reconnecting port-forward started"

echo ""
echo "=========================================="
echo "App:        http://localhost:8888"
echo "ArgoCD:     http://localhost:8080"
echo "Password:   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo "=========================================="