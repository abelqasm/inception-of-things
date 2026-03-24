#!/bin/bash

curl -sfL https://get.k3s.io | sh -s - server --write-kubeconfig-mode=644 --flannel-iface=eth1
until sudo rc-service k3s status | grep -q started; do
    sleep 2
done

kubectl apply -f "/vagrant/app1/conf.yaml"
kubectl apply -f "/vagrant/app2/conf.yaml"
kubectl apply -f "/vagrant/app3/conf.yaml"
kubectl apply -f "/vagrant/ingress.yaml"