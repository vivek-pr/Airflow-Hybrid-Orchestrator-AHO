#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=airflow
DAG_ID=poc_test
RUN_ID=test_run
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(dirname "$SCRIPT_DIR")
LOG_DIR="$REPO_ROOT/logs"

# 1. Unpause and trigger the DAG
kubectl -n $NAMESPACE exec deploy/airflow-scheduler -- airflow dags unpause $DAG_ID >/dev/null
kubectl -n $NAMESPACE exec deploy/airflow-scheduler -- airflow dags trigger $DAG_ID --run-id $RUN_ID >/dev/null

echo "Waiting for tasks to finish..."
for i in {1..30}; do
  state=$(kubectl -n $NAMESPACE exec deploy/airflow-scheduler -- airflow dags state $DAG_ID $RUN_ID 2>/dev/null || true)
  if [[ "$state" == "success" ]]; then
    break
  fi
  sleep 10
done

# collect task pods
pods=$(kubectl -n $NAMESPACE get pods --no-headers | awk '/^poc-test/ {print $1}')

WORKER_NODE=$(kubectl get nodes -l role=airflow-worker --no-headers -o custom-columns=':metadata.name')

for pod in $pods; do
  node=$(kubectl -n $NAMESPACE get pod "$pod" -o jsonpath='{.spec.nodeName}')
  if [[ "$node" != "$WORKER_NODE" ]]; then
    echo "Pod $pod scheduled on $node, expected $WORKER_NODE" >&2
    exit 1
  fi
done

# verify logs exist in hostPath volume and via CLI
for task in echo sleep; do
  kubectl -n $NAMESPACE exec deploy/airflow-scheduler -- airflow tasks logs $DAG_ID $task $RUN_ID | grep -q ""
  file=$(find "$LOG_DIR/$DAG_ID/$task" -name '*.log' | head -n1)
  if [[ ! -s "$file" ]]; then
    echo "Log for task $task not found in $LOG_DIR" >&2
    exit 1
  fi
done

echo "POC test succeeded"
