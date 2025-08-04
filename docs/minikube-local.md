# Local Minikube Development Cluster

This guide describes how to spin up a local Kubernetes cluster for Airflow development using Minikube.

## Requirements

- Linux with Docker or another Minikube VM driver
- [minikube](https://minikube.sigs.k8s.io/docs/) and [kubectl](https://kubernetes.io/docs/tasks/tools/)
- At least 4 CPUs and 8GiB memory available (adjust Docker Desktop resources if necessary)

## Start the cluster

Run the provided script:

```bash
./scripts/start-minikube.sh
```

Environment variables can override defaults:

| Variable | Description | Default |
|----------|-------------|---------|
| `CPUS`   | vCPUs allocated to each node | `4` |
| `MEMORY` | Memory (MiB) for each node  | `8192` |
| `NODES`  | Total nodes in the cluster (1 control-plane + workers) | `2` |
| `DAGS_DIR` | Host path for Airflow DAGs | `./airflow_dags` |
| `LOGS_DIR` | Host path for Airflow logs | `./airflow_logs` |

## What the script does

- Starts a Minikube profile named `airflow-dev` with multiple nodes.
- Mounts `DAGS_DIR` to `/mnt/airflow/dags` and `LOGS_DIR` to `/mnt/airflow/logs` inside the cluster nodes.
- Creates an `airflow` namespace.
- Prints available storage classes (a default class should be present).
- Deploys an `airflow-mount-test` pod that writes `minikube mount works` to the mounted DAGs directory.

After the script completes, verify the mount:

```bash
kubectl -n airflow exec airflow-mount-test -- cat /mnt/dags/test.txt
ls airflow_dags
```

You should see the `test.txt` file both in the pod and in the host directory.

## Verification

- `kubectl get nodes` shows one control-plane node and at least one worker.
- `kubectl get storageclass` lists a default storage class (marked `(default)`).
- The test pod output confirms the host directory is writable from the cluster.

## Cleanup

```bash
kubectl delete pod airflow-mount-test -n airflow
minikube delete -p airflow-dev
```
