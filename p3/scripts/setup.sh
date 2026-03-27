#!/bin/bash

#  create cluster
echo "---------- Creating k3d cluster  ----------"
k3d cluster create p3 -p 8080:80@loadbalancer

sleep 10

#  create namespaces
echo "---------- Creating argocd and dev namespaces ---------"
kubectl create namespace argocd
kubectl create namespace dev

sleep 3

#  install argocd
echo "---------- Installing argocd into cluster ---------"
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
