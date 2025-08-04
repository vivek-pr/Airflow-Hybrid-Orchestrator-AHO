#!/bin/bash
set -euo pipefail

NAMESPACE=${NAMESPACE:-airflow}
RELEASE=${RELEASE:-airflow}
MINIKUBE_PROFILE=${MINIKUBE_PROFILE:-airflow-poc}

# Stop worker if running
if [ -f worker/worker.pid ]; then
  kill $(cat worker/worker.pid) 2>/dev/null || true
  rm -f worker/worker.pid
fi

# Remove Helm release and Kubernetes resources
helm uninstall "$RELEASE" -n "$NAMESPACE" 2>/dev/null || true
kubectl delete pvc -n "$NAMESPACE" dags-pvc logs-pvc 2>/dev/null || true
kubectl delete pv dags-pv logs-pv 2>/dev/null || true
kubectl delete namespace "$NAMESPACE" 2>/dev/null || true

# Delete Minikube cluster
minikube -p "$MINIKUBE_PROFILE" delete 2>/dev/null || true
