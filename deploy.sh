#!/bin/bash
set -euo pipefail

NAMESPACE=${NAMESPACE:-airflow}
RELEASE=${RELEASE:-airflow}
MINIKUBE_PROFILE=${MINIKUBE_PROFILE:-airflow-poc}

# Start Minikube if not running
if ! minikube -p "$MINIKUBE_PROFILE" status >/dev/null 2>&1; then
  minikube start -p "$MINIKUBE_PROFILE" --driver=docker --mount --mount-string="$(pwd):/repo"
fi

# Label node and create namespace
NODE=$(kubectl get nodes --no-headers | head -n1 | awk '{print $1}')
kubectl label node "$NODE" role=airflow --overwrite
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Create PersistentVolumes for DAGs and logs
mkdir -p logs
cat <<PV | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: dags-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  hostPath:
    path: /repo/dags
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dags-pvc
  namespace: $NAMESPACE
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  volumeName: dags-pv
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: logs-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  hostPath:
    path: /repo/logs
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: logs-pvc
  namespace: $NAMESPACE
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  volumeName: logs-pv
PV

# Start external worker
pip install -r worker/requirements.txt >/dev/null
python worker/app.py &
echo $! > worker/worker.pid

# Install Airflow via Helm
helm repo add apache-airflow https://airflow.apache.org 2>/dev/null || true
helm repo update
helm upgrade --install "$RELEASE" apache-airflow/airflow -n "$NAMESPACE" -f values.yaml

# Wait for Airflow scheduler and webserver
kubectl -n "$NAMESPACE" wait --for=condition=Ready pod -l component=scheduler --timeout=600s
kubectl -n "$NAMESPACE" wait --for=condition=Ready pod -l component=webserver --timeout=600s

# Trigger the sample DAG
SCHEDULER_POD=$(kubectl -n "$NAMESPACE" get pods -l component=scheduler -o jsonpath='{.items[0].metadata.name}')
kubectl -n "$NAMESPACE" exec "$SCHEDULER_POD" -- airflow dags trigger external_trigger_dag
