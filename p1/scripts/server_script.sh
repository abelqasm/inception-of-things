#!/bin/bash

curl -sfL https://get.k3s.io | sh -s - server --write-kubeconfig-mode=644 --flannel-iface=eth1 
TOKEN="/var/lib/rancher/k3s/server/token" 
while [ ! -f ${TOKEN} ]
do
    sleep 2
done
cp ${TOKEN} /vagrant