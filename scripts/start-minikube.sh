#!/usr/bin/env bash
set -euo pipefail

# Ensure dependencies exist
command -v minikube >/dev/null 2>&1 || { echo "minikube is required but not installed" >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required but not installed" >&2; exit 1; }

PROFILE=${PROFILE:-airflow-dev}
NODES=${NODES:-2}
CPUS=${CPUS:-4}
MEMORY=${MEMORY:-8192}
DAGS_DIR=${DAGS_DIR:-"$PWD/airflow_dags"}
LOGS_DIR=${LOGS_DIR:-"$PWD/airflow_logs"}

mkdir -p "$DAGS_DIR" "$LOGS_DIR"

minikube start -p "$PROFILE" --driver=docker --cpus="$CPUS" --memory="$MEMORY" \
  --nodes="$NODES" --mount \
  --mount-string="$DAGS_DIR:/mnt/airflow/dags" \
  --mount-string="$LOGS_DIR:/mnt/airflow/logs"

kubectl config use-context "$PROFILE" >/dev/null 2>&1 || true
kubectl create namespace airflow --dry-run=client -o yaml | kubectl apply -f -

kubectl get nodes
kubectl get storageclass

cat <<'POD' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: airflow-mount-test
  namespace: airflow
spec:
  containers:
  - name: writer
    image: busybox
    command: ['sh', '-c', 'echo "minikube mount works" > /mnt/dags/test.txt && sleep 3600']
    volumeMounts:
    - mountPath: /mnt/dags
      name: dags
  restartPolicy: Never
  volumes:
  - name: dags
    hostPath:
      path: /mnt/airflow/dags
      type: Directory
POD

kubectl -n airflow wait --for=condition=Ready pod/airflow-mount-test --timeout=120s
kubectl -n airflow exec airflow-mount-test -- cat /mnt/dags/test.txt
echo "Minikube cluster '$PROFILE' is ready."
