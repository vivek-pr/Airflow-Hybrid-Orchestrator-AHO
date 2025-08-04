# Airflow Hybrid Orchestrator POC

This repository contains a complete proof‑of‑concept for running **Apache Airflow 3** on a local [Minikube](https://minikube.sigs.k8s.io/) Kubernetes cluster using the **KubernetesExecutor**.  The control plane (Scheduler and Webserver) is pinned to one node while task pods run on a separate worker node, demonstrating a clear separation between orchestration and execution layers.

## Architecture
- **Control plane** – Airflow Scheduler and Webserver run on the node labelled `role=airflow-control`.
- **Data plane** – every task is executed as a separate pod scheduled on the node labelled `role=airflow-worker`.
- **Shared volumes** – DAGs and logs are stored on host directories and exposed to the cluster through `hostPath` PersistentVolumes.

## Repository Layout
```
├── Makefile                # one‑click deployment and teardown
├── minikube-profile.yaml   # example multi‑node Minikube profile
├── values.yaml             # Helm values overriding the official chart
├── dags/
│   └── poc_test_dag.py     # sample DAG with echo and sleep tasks
├── logs/                   # hostPath log directory
├── tests/
│   └── test_poc.sh         # automated validation script
└── README.md
```

## Prerequisites
- Linux host with Docker
- [Minikube](https://minikube.sigs.k8s.io/) 1.32+
- [Helm](https://helm.sh/) 3.x
- `kubectl` and `make`

## One‑Click Deployment
```bash
make deploy
```
This target performs the following:
1. Starts Minikube with two nodes and mounts the repository into the cluster.
2. Labels the nodes for control (`role=airflow-control`) and data (`role=airflow-worker`).
3. Creates the `airflow` namespace plus hostPath PVs/PVCs for `dags` and `logs`.
4. Installs/updates Airflow using the official Helm chart and waits for readiness.
5. Runs `tests/test_poc.sh` which:
   - Unpauses and triggers the `poc_test` DAG.
   - Confirms that task pods land on the worker node.
   - Verifies that log files are written to the shared volume and accessible via `airflow tasks logs`.

### Accessing the Web UI
After deployment the webserver can be reached locally:
```bash
kubectl -n airflow port-forward svc/airflow-webserver 8080:8080
```
Navigate to [http://localhost:8080](http://localhost:8080) and log in with the default `admin / admin` credentials.

## Teardown
```bash
make clean
```
This removes the Helm release, deletes the namespace and PVs, and tears down the Minikube cluster.

## Extending for Production
- Replace the bundled PostgreSQL with an external managed database.
- Enable high availability by increasing scheduler and webserver replicas.
- Integrate an object store (e.g. S3, GCS) for DAGs and logs instead of hostPath volumes.
- Configure a load balancer or ingress for the webserver.

## Troubleshooting
`kubectl -n airflow get pods -o wide` shows where each pod is scheduled.  Logs for failed tasks are available under `logs/` on the host or via `kubectl exec` using `airflow tasks logs`.
