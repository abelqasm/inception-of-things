#!/bin/bash
export INSTALL_K3S_EXEC="server \
  --node-ip=192.168.56.110 \
  --flannel-iface=eth1"

curl -sfL https://get.k3s.io | sh -

# Wait until the token file exists
while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
  sleep 1
done

# Copy token to shared folder so worker can read it
cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token

# Set kubeconfig permissions for vagrant user
mkdir -p /vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /vagrant/.kube/config
chown vagrant:vagrant /vagrant/.kube/config

echo 'export KUBECONFIG=/home/vagrant/.kube/config' >> /home/vagrant/.bashrc