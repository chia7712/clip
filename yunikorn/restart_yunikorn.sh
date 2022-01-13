#!/bin/bash

declare -r SCRIPT_FOLDER=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
declare -r RBAC_FILE="$SCRIPT_FOLDER/yunikorn-rbac.yaml"
declare -r QUEUES_FILE="$SCRIPT_FOLDER/queues.yaml"
declare -r SCHEDULER_FILE="$SCRIPT_FOLDER/scheduler.yaml"


# ===================================[functions]===================================

function showHelp() {
  echo "Usage: [ENV] restart_yunikorn.sh"
  echo "Arguments: "
  echo "    --namespace   k8s namespace"
  echo "    --account     k8s account"
}


function requireNonEmpty() {
  local var=$1
  local message=$2
  if [[ "$var" == "" ]]; then
    echo "$message"
    exit 2
  fi
}

# ===================================[main]===================================

namespace="yunikorn"
account="default"
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

requireNonEmpty "$account" "account can not be empty"
requireNonEmpty "$namespace" "namespace can not be empty"

kubectl delete deployment/yunikorn-scheduler -n $namespace \
; kubectl delete clusterrolebinding yunikorn-rbac -n $namespace \
; kubectl delete serviceaccount yunikorn-admin -n $namespace \
; kubectl delete configmap yunikorn-configs -n $namespace \
; kubectl create namespace $namespace \
; kubectl create -f "$RBAC_FILE" \
&& kubectl create configmap yunikorn-configs --from-file=queues.yaml="$QUEUES_FILE" -n $namespace \
&& kubectl create -f "$SCHEDULER_FILE" -n $namespace

# prepare rbac for spark
kubectl delete rolebinding spark-on-yunikorn -n $namespace \
; kubectl create rolebinding spark-on-yunikorn --clusterrole=edit --serviceaccount=$namespace:$account -n $namespace
