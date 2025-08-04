#!/bin/bash
set -euo pipefail

NAMESPACE=${NAMESPACE:-airflow}
DAG_ID=external_trigger_dag
WORKER_LOG="worker/worker.log"
TIMEOUT=120
SLEEP=5

# Wait for worker log entry
echo "[TEST] Waiting for worker log entry..."
for ((i=0; i<TIMEOUT; i+=SLEEP)); do
  if [[ -f "$WORKER_LOG" ]] && grep -q "Task executed" "$WORKER_LOG"; then
    echo "[TEST] Worker log entry detected."
    break
  fi
  sleep $SLEEP
  if (( i + SLEEP >= TIMEOUT )); then
    echo "[TEST] ERROR: Worker did not log execution within timeout." >&2
    exit 1
  fi
  echo "[TEST] Polling..."
done

SCHEDULER_POD=$(kubectl -n "$NAMESPACE" get pods -l component=scheduler -o jsonpath='{.items[0].metadata.name}')

# Check DAG run status
echo "[TEST] Waiting for DAG run to succeed..."
for ((i=0; i<TIMEOUT; i+=SLEEP)); do
  STATUS=$(kubectl -n "$NAMESPACE" exec "$SCHEDULER_POD" -- airflow dags state $DAG_ID --latest || true)
  echo "[TEST] DAG status: $STATUS"
  if echo "$STATUS" | grep -qi "success"; then
    echo "[TEST] DAG run succeeded."
    exit 0
  fi
  sleep $SLEEP
done

echo "[TEST] ERROR: DAG run did not reach success state." >&2
exit 1
