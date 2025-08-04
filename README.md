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

## Accessing the Airflow Web UI

The webserver Service is exposed as a NodePort so that the UI can be reached from the host.

1. Retrieve the port that the cluster assigned:

   ```bash
   kubectl -n airflow get svc airflow-webserver -o=jsonpath='{.spec.ports[0].nodePort}'
   ```

2. Open `http://localhost:<NodePort>` in a browser and log in with the default credentials (`admin`/`admin` unless changed).
3. The home page should list the built-in example DAGs or any test DAGs you deploy.

If you cannot access the Service directly, you can temporarily port‑forward the webserver:

```bash
kubectl -n airflow port-forward svc/airflow-webserver 8080:8080
```

Then navigate to `http://localhost:8080/`.



## Monitoring the Cluster and Airflow

### Kubernetes Dashboard

1. Deploy the dashboard:
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
   ```
2. Create an admin service account and cluster role binding:
   ```bash
   kubectl apply -f dashboard-adminuser.yaml
   ```
3. Get a login token:
   ```bash
   kubectl -n kubernetes-dashboard create token admin-user
   ```
4. Launch the local proxy and open the UI:
   ```bash
   kubectl proxy
   ```
   Navigate to:
   `http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/`
   Log in with the token and verify that nodes and pods are visible. A 403 error usually indicates missing RBAC permissions.

### Airflow Metrics

`values.yaml` enables StatsD metrics emission:

```yaml
config:
  metrics:
    statsd_on: true
statsd:
  enabled: true
```

1. Port‑forward the StatsD exporter:
   ```bash
   kubectl -n airflow port-forward svc/airflow-statsd 9125:9125
   ```
2. Query the metrics endpoint:
   ```bash
   curl http://localhost:9125/metrics
   ```
   Prometheus-style metrics such as `airflow_dag_processing_import_errors` should be returned. An empty response indicates metrics are disabled.

#### Optional: Prometheus

Install a minimal Prometheus server and scrape the Airflow metrics:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitor prometheus-community/prometheus \
  --namespace monitoring --create-namespace \
  --set server.persistentVolume.enabled=false
```

Add the following scrape configuration (via `server.extraScrapeConfigs` or a ConfigMap):

```yaml
- job_name: airflow
  static_configs:
    - targets:
      - airflow-statsd.airflow.svc.cluster.local:9125
```

Port‑forward the Prometheus service to view collected metrics:

```bash
kubectl -n monitoring port-forward svc/monitor-prometheus-server 9090:9090
```

