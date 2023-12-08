#!/bin/bash

declare -r SCRIPT_FOLDER=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
declare -r RBAC_FILE="$SCRIPT_FOLDER/yunikorn-rbac.yaml"
declare -r QUEUES_FILE="$SCRIPT_FOLDER/yunikorn-configs.yaml"
declare -r SCHEDULER_FILE="$SCRIPT_FOLDER/scheduler.yaml"
declare -r RBAC_NAME="yunikorn-rbac"
declare -r ADMIN_NAME="yunikorn-admin"
declare -r CONFIG_NAME="yunikorn-configs"

# ===================================[functions]===================================

function showHelp() {
  echo "Usage: [ENV] restart_yunikorn.sh"
  echo "Arguments: "
  echo "    --image       docker image of yunikorn scheduler"
  echo "    --namespace   k8s namespace to deploy yunikorn scheduler"
  echo "    --account     k8s account for spark application"
}

function requireNonEmpty() {
  local var=$1
  local message=$2
  if [[ "$var" == "" ]]; then
    echo "$message"
    exit 2
  fi
}

function generateScheduler() {
  local image=$1
  local ui_image=$2
  echo "
# this file is generated automatically
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: yunikorn
  name: yunikorn-scheduler
spec:
  replicas: 1
  selector:
    matchLabels:
      app: yunikorn
  template:
    metadata:
      labels:
        app: yunikorn
        component: yunikorn-scheduler
      name: yunikorn-scheduler
    spec:
      hostNetwork: true
      serviceAccountName: yunikorn-admin
      containers:
        - name: yunikorn-scheduler-k8s
          image: $image
          resources:
            requests:
              cpu: 200m
              memory: 1Gi
            limits:
              cpu: 4
              memory: 2Gi
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 9080
        - name: yunikorn-scheduler-web
          image: $ui_image
          imagePullPolicy: IfNotPresent
          resources:
            requests:
              cpu: 100m
              memory: 100Mi
            limits:
              cpu: 200m
              memory: 500Mi
          ports:
            - containerPort: 9889
" >"$SCHEDULER_FILE"
}

function generateRbac() {
  local namespace=$1

  echo "
# this file is generated automatically
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $ADMIN_NAME
  namespace: $namespace
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $RBAC_NAME
subjects:
  - kind: ServiceAccount
    name: $ADMIN_NAME
    namespace: $namespace
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io

" >"$RBAC_FILE"
}

function cleanup() {
  local namespace=$1
  kubectl delete deployment/yunikorn-scheduler -n "$namespace" \
    ;
  kubectl delete clusterrolebinding $RBAC_NAME -n "$namespace" \
    ;
  kubectl delete serviceaccount $ADMIN_NAME -n "$namespace" \
    ;
  kubectl delete configmap $CONFIG_NAME -n "$namespace"
}

function setup() {
  local namespace=$1
  kubectl create namespace "$namespace" \
    ;
  kubectl create -f "$RBAC_FILE" &&
    kubectl apply -f "$QUEUES_FILE" -n "$namespace" &&
    kubectl create -f "$SCHEDULER_FILE" -n "$namespace"
}

function setupSpark() {
  local namespace=$1
  local account=$2
  kubectl delete rolebinding spark-on-yunikorn -n "$namespace" \
    ;
  kubectl create serviceaccount $account -n "$namespace" \
    ;
  kubectl create rolebinding spark-on-yunikorn --clusterrole=edit --serviceaccount=$namespace:$account -n "$namespace"
}

# ===================================[main]===================================

image="ghcr.io/chia7712/yunikorn:scheduler-amd64-latest"
ui_image="ghcr.io/chia7712/yunikorn:web-amd64-latest"
arch=$(uname -m)
if [[ "$arch" == arm* ]] ||  [[ "$arch" == aarch* ]] ; then
  image="ghcr.io/chia7712/yunikorn:scheduler-arm64-latest"
  ui_image="ghcr.io/chia7712/yunikorn:web-arm64-latest"
fi

namespace="default"
account="spark"
while [[ $# -gt 0 ]]; do
  case $1 in
  --namespace)
    namespace="$2"
    shift
    shift
    ;;
  --account)
    account="$2"
    shift
    shift
    ;;
  --image)
    image="$2"
    shift
    shift
    ;;
  --ui_image)
    ui_image="$2"
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

requireNonEmpty "$namespace" "namespace can not be empty"
requireNonEmpty "$image" "image can not be empty"

generateRbac "$namespace"
generateScheduler "$image" "$ui_image"
cleanup "$namespace"
setup "$namespace"

# prepare rbac for spark
if [[ "$account" != "" ]]; then
  setupSpark "$namespace" "$account"
fi
