NAMESPACE ?= airflow
RELEASE ?= airflow
MINIKUBE_PROFILE ?= airflow-poc

.PHONY: deploy start label pv helm wait test clean

deploy: start label pv helm wait test

start:
	mkdir -p logs
	minikube -p $(MINIKUBE_PROFILE) status >/dev/null 2>&1 || \
		minikube start -p $(MINIKUBE_PROFILE) --nodes 2 --driver=docker --mount --mount-string="$(CURDIR):/repo"

label:
	control=$$(kubectl get nodes --no-headers | head -n1 | awk '{print $$1}'); \
	worker=$$(kubectl get nodes --no-headers | tail -n1 | awk '{print $$1}'); \
	kubectl label nodes $$control role=airflow-control --overwrite; \
	kubectl label nodes $$worker role=airflow-worker --overwrite

pv:
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
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
  namespace: $(NAMESPACE)
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
  namespace: $(NAMESPACE)
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  volumeName: logs-pv
PV

helm:
	helm repo add apache-airflow https://airflow.apache.org || true
	helm repo update
	helm upgrade --install $(RELEASE) apache-airflow/airflow -n $(NAMESPACE) -f values.yaml

wait:
	kubectl -n $(NAMESPACE) wait --for=condition=Ready pod -l app.kubernetes.io/instance=$(RELEASE) --timeout=600s

test:
	./tests/test_poc.sh

clean:
	helm uninstall $(RELEASE) -n $(NAMESPACE) || true
	kubectl delete pvc -n $(NAMESPACE) dags-pvc logs-pvc || true
	kubectl delete pv dags-pv logs-pv || true
	kubectl delete namespace $(NAMESPACE) || true
	minikube -p $(MINIKUBE_PROFILE) delete || true
