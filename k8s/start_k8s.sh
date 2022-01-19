#!/bin/bash

# get path
BASEDIR=$(dirname $0)

sudo swapoff -a
sudo rm -rf /etc/cni/net.d
sudo kubeadm init --control-plane-endpoint=k8s00 --pod-network-cidr=192.168.100.0/24
rm -rf $HOME/.kube
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
sleep 5
kubectl create -f "$BASEDIR/tigera-operator.yaml"
kubectl create -f "$BASEDIR/custom-resources.yaml"
sleep 30
kubectl taint nodes --all node-role.kubernetes.io/master-