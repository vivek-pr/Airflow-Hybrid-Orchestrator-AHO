# Airflow Hybrid Orchestrator

This repository provides configuration for deploying Apache Airflow 3 on Kubernetes using the official Helm chart.

## Contents
- `values.yaml`: Custom values enabling `KubernetesExecutor`, persistent DAG and log volumes, node selectors and tolerations for control and worker nodes, a NodePort webserver service, built-in PostgreSQL, and StatsD metrics.
- `minikube-config.yaml`: Example Minikube cluster configuration with separate control-plane and worker nodes and host path mounts for DAGs and logs.

## Prerequisites
- Helm 3
- `kubectl` with access to a Kubernetes cluster (e.g., Minikube using `minikube-config.yaml`)

## Deployment

Add or update the Airflow Helm repository:

```bash
helm repo add apache-airflow https://airflow.apache.org
helm repo update
```

Install or upgrade the Airflow release with the included values:

```bash
helm upgrade --install airflow apache-airflow/airflow \
  -n airflow -f values.yaml --debug
```

Wait for all Airflow pods to become ready:

```bash
kubectl -n airflow wait --for=condition=Ready pod \
  --selector=app.kubernetes.io/instance=airflow --timeout=5m
```

List pods and their nodes:

```bash
kubectl -n airflow get pods -o wide
```

Check scheduler and webserver logs for errors:

```bash
kubectl -n airflow logs deploy/airflow-scheduler
kubectl -n airflow logs deploy/airflow-webserver
```

All core pods (scheduler, webserver, triggerer, statsd, postgresql) should be in the `Running` state and the scheduler logs should include "Started single scheduler process".

