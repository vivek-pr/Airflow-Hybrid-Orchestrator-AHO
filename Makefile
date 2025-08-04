NAMESPACE ?= airflow
RELEASE ?= airflow
MINIKUBE_PROFILE ?= airflow-poc

.PHONY: deploy test clean start-worker stop-worker

deploy: ## Provision cluster, install Airflow, run DAG and tests
	./deploy.sh
	./tests/test_external_trigger.sh

test: ## Re-run validation tests only
	./tests/test_external_trigger.sh

clean: ## Tear everything down
	./teardown.sh

start-worker: ## Start the standalone worker manually
	pip install -r worker/requirements.txt
	python worker/app.py & echo $$! > worker/worker.pid

stop-worker: ## Stop the standalone worker
	@if [ -f worker/worker.pid ]; then kill `cat worker/worker.pid` 2>/dev/null || true; rm worker/worker.pid; fi
