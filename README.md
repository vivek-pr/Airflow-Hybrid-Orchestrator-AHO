# Airflow External Worker Proof-of-Concept

This repository demonstrates an **Apache Airflow 3** control plane running inside a local [Minikube](https://minikube.sigs.k8s.io/) Kubernetes cluster while tasks are executed by a **standalone worker** process that lives entirely on the host machine. Airflow uses the `KubernetesExecutor` but instead of running task code in Kubernetes pods, a sample DAG sends an HTTP request to the external worker.

## Architecture
- **Control plane** – Airflow Scheduler and Webserver run inside the Minikube cluster.
- **Data plane** – a Python Flask service (`worker/app.py`) runs on the host and performs work when triggered.
- **Communication** – Airflow tasks call `http://host.minikube.internal:5000/run-task` to request work from the external service.

## Repository Layout
```
├── Makefile               # one‑click entry points
├── deploy.sh              # provisioning script
├── teardown.sh            # cleanup script
├── minikube-profile.yaml  # sample Minikube profile
├── values.yaml            # Helm values for Airflow
├── dags/
│   └── external_trigger_dag.py  # DAG that calls the external worker
├── worker/
│   ├── app.py             # Flask worker
│   └── requirements.txt   # worker dependencies
├── tests/
│   └── test_external_trigger.sh # validation script
└── README.md
```

## Prerequisites
- Linux host with Docker
- [Minikube](https://minikube.sigs.k8s.io/) 1.32+
- [Helm](https://helm.sh/) 3.x
- `kubectl`, `curl`, and `make`
- Python 3 for the standalone worker

## One‑Click Usage
```bash
make deploy   # spin up everything, trigger the DAG and run tests
make test     # re-run validation tests
make clean    # tear everything down
```
`make deploy` performs the following steps:
1. Starts Minikube and creates an `airflow` namespace.
2. Labels the node and provisions hostPath volumes for DAGs and logs.
3. Installs Airflow via the official Helm chart using the `KubernetesExecutor`.
4. Launches the standalone worker on the host at `http://localhost:5000`.
5. Triggers `external_trigger_dag` which POSTs to the worker.
6. Runs `tests/test_external_trigger.sh` to verify that the worker executed and the DAG completed successfully.

The Airflow web UI is exposed via NodePort `32080`:
```bash
kubectl -n airflow port-forward svc/airflow-webserver 8080:8080
# then browse http://localhost:8080
```

## Extending the POC
- Secure the worker endpoint with authentication or TLS.
- Run the worker on a different host and update the DAG URL accordingly.
- Replace hostPath volumes with object storage for production setups.

## Teardown
```bash
make clean
```
This stops the worker, uninstalls the Helm release, deletes the namespace and volumes, and removes the Minikube cluster.
