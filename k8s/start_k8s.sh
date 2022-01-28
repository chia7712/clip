#!/bin/bash

# get path
BASEDIR=$(dirname $0)

sudo swapoff -a
sudo rm -rf /etc/cni/net.d
sudo kubeadm init --control-plane-endpoint=k8s00 --pod-network-cidr=10.244.0.0/16
rm -rf $HOME/.kube
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
sleep 5
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
sleep 10
kubectl taint nodes --all node-role.kubernetes.io/master-