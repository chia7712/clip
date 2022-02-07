#!/bin/bash

# ===================================[functions]===================================

function showHelp() {
  echo "Usage: [ENV] start_k8s.sh"
  echo "Arguments: "
  echo "    --single   true if you want to build single-machine Kubernetes cluster"
}

function cleanup() {
  sudo swapoff -a
  sudo rm -rf /etc/cni/net.d
  rm -rf "$HOME"/.kube
}

function initK8s() {
  sudo kubeadm init --control-plane-endpoint=k8s00 --pod-network-cidr=10.244.0.0/16
  mkdir -p "$HOME"/.kube
  sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
  sudo chown $(id -u):$(id -g) "$HOME"/.kube/config
}

function initNetwork() {
  kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
}

function untaintControlNode() {
  kubectl taint nodes --all node-role.kubernetes.io/master-
}

# ===================================[main]===================================

# true if you want to build single-machine Kubernetes cluster
single="false"
while [[ $# -gt 0 ]]; do
  case $1 in
  --single)
    single="$2"
    shift
    shift
    ;;
  --help)
    showHelp
    exit 0
    ;;
  *)
    echo "Unknown option $1"
    exit 1
    ;;
  esac
done

cleanup
initK8s
initNetwork

if [[ "$single" == "true" ]]; then
  untaintControlNode
fi
