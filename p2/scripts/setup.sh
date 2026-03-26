#!/bin/bash

curl -sfL https://get.k3s.io | sh -s - server --write-kubeconfig-mode=644 --flannel-iface=eth1

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

until kubectl get nodes >/dev/null 2>&1; do
    echo "Waiting for Kubernetes API..."
    sleep 3
done

kubectl apply -n kube-system -f "/vagrant/app1/conf.yaml"
kubectl apply -n kube-system -f "/vagrant/app2/conf.yaml"
kubectl apply -n kube-system -f "/vagrant/app3/conf.yaml"
kubectl apply -n kube-system -f "/vagrant/ingress.yaml"