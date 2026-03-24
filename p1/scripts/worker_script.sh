#!/bin/bash

MASTER_NODE="192.168.56.110"

curl -sfL https://get.k3s.io\
| sh -s - agent --server=https://${MASTER_NODE}:6443 --token-file=/vagrant/token --flannel-iface=eth1
