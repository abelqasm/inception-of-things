#!/bin/bash
# Wait for server to write the token
while [ ! -f /vagrant/node-token ]; do
  sleep 2
done

TOKEN=$(cat /vagrant/node-token)

export INSTALL_K3S_EXEC="agent \
  --server=https://192.168.56.110:6443 \
  --token=${TOKEN} \
  --node-ip=192.168.56.111 \
  --flannel-iface=eth1"

curl -sfL https://get.k3s.io | sh -