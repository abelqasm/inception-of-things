#!/bin/bash

#install helm
echo "---------- installing HELM ----------"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash


#install gitlab helm sharts
echo "---------- installing HELM ----------"
helm repo add gitlab https://charts.gitlab.io/
helm repo update

#create gitlab namespace
kubectl create namespace gitlab

#install gitlab using helm
helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  --set global.hosts.domain=localhost \
  --set global.edition=ce \
  --set global.ingress.configureCertmanager=false \
  --set global.hosts.https=false \
  --set gitlab-runner.install=false \
  --set certmanager.install=false


#wait for gitlab to be running and ready
kubectl wait --for=condition=Ready pods --all -n gitlab

#get gitlab root password
kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 -d
