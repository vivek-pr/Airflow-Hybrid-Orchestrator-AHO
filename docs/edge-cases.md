# Edge Case Tests & Hardening Outcomes

This document captures the results of attempted edge case tests for the Airflow Hybrid Orchestrator. Due to the absence of a running Kubernetes cluster in the evaluation environment, most tests could not be executed. The details below record the steps taken and notes for future production validation.

## Resource Exhaustion
- **Intended Test:** Trigger a DAG with 10 parallel tasks and monitor for scheduling failures.
- **Attempt:** Cluster creation via `kind` failed (`docker` not available). `kubectl` was installed but no API server was reachable.
- **Outcome:** Not executed; to be addressed in production.

## Worker Node Failure
- **Intended Test:** `kubectl cordon kind-airflow-poc-worker` then trigger a new DAG run.
- **Attempt:** No Kubernetes node available.
- **Outcome:** Not executed; multi-node cluster required.

## Scheduler Crash Recovery
- **Intended Test:** Delete scheduler pod and verify automatic recovery.
- **Attempt:** No scheduler pod present to delete.
- **Outcome:** Not executed; add to production checklist.

## Database Restart
- **Intended Test:** Delete PostgreSQL pod and confirm scheduler reconnects automatically.
- **Attempt:** No database pod present.
- **Outcome:** Not executed; needs production validation.

## DAG Update Sync
- **Intended Test:** Edit `sample_poc_dag.py` and ensure Airflow syncs the change within 1–2 minutes.
- **Attempt:** DAG file updated locally adding a third Bash task; sync could not be verified without a running scheduler.
- **Outcome:** Pending verification in production.

## Performance Measurement
- **Intended Test:** Record latency between pod creation and task start.
- **Attempt:** No pods could be created.
- **Outcome:** Not executed; measure in production environment.

## Logging Consistency
- **Intended Test:** Delete a task pod mid-run and verify logs persist on PVC.
- **Attempt:** No task pods available to delete.
- **Outcome:** Not executed; validate when persistent logging is set up.

## Noted Edge Cases
- Single worker node leads to total task failure if the node is lost.
- Potential race conditions in DAG synchronization when using gitSync.

## Next Steps
- Provision a Kubernetes cluster (min. two worker nodes).
- Re-run the tests above to capture concrete metrics.
- Address any failures or document "To be addressed in production" items accordingly.

