#!/bin/bash

declare -r HOSTNAME=$(hostname)

# ===================================[functions]===================================

function showHelp() {
  echo "Usage: [ENV] start_k8s.sh"
  echo "Arguments: "
  echo "    --single   true if you want to build single-machine Kubernetes cluster"
  echo "    --cleanup  true if you want to cleanup previous k8s settings"
}

function cleanup() {
  local cri-socket=$1
  if [[ "${cri-socket}" == "" ]]; then
    sudo kubeadm reset -f
  else
    sudo kubeadm reset -f --cri-socket "$cri-socket"
  fi
  sudo swapoff -a
  sudo rm -rf /etc/cni/net.d
  rm -rf "$HOME"/.kube
  sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
  # reload the network setting
  sudo systemctl restart docker
}

function initK8s() {
  local cri-socket=$1
  if [[ "${cri-socket}" == "" ]]; then
    sudo kubeadm init --control-plane-endpoint=$HOSTNAME --pod-network-cidr=10.244.0.0/16
  else
    sudo kubeadm init --control-plane-endpoint=$HOSTNAME --pod-network-cidr=10.244.0.0/16 --cri-socket "$cri-socket"
  fi
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

function copyCertificate() {
  mkdir -p $HOME/pki/etcd
  sudo cp /etc/kubernetes/pki/ca.crt $HOME/pki/
  sudo cp /etc/kubernetes/pki/ca.key $HOME/pki/
  sudo cp /etc/kubernetes/pki/front-proxy-ca.crt $HOME/pki/
  sudo cp /etc/kubernetes/pki/front-proxy-ca.key $HOME/pki/
  sudo cp /etc/kubernetes/pki/front-proxy-client.crt $HOME/pki/
  sudo cp /etc/kubernetes/pki/front-proxy-client.key $HOME/pki/
  sudo cp /etc/kubernetes/pki/sa.key $HOME/pki/
  sudo cp /etc/kubernetes/pki/sa.pub $HOME/pki/
  sudo cp /etc/kubernetes/pki/etcd/ca.crt $HOME/pki/etcd/
  sudo cp /etc/kubernetes/pki/etcd/ca.key $HOME/pki/etcd/
}

# ===================================[main]===================================

# true if you want to build single-machine Kubernetes cluster
single="false"
# true if you want to cleanup k8s cluster only
cleanup="false"
# true if you want to collect certificate
certificate="false"
cri-socket=""
while [[ $# -gt 0 ]]; do
  case $1 in
  --single)
    single="$2"
    shift
    shift
    ;;
  --cleanup)
    cleanup="$2"
    shift
    shift
    ;;
  --certificate)
    certificate="$2"
    shift
    shift
    ;;
  --cri-socket)
    cri-socket="$2"
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

if [[ "$cleanup" == "true" ]]; then
  cleanup "$cri-socket"
fi

initK8s "$cri-socket"
initNetwork

if [[ "$single" == "true" ]]; then
  untaintControlNode
fi

if [[ "$certificate" == "true" ]]; then
  copyCertificate
fi
