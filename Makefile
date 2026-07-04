# CoreBank Enterprise Architecture - Developer Automation Hub
# This Makefile provides 1-click commands for local development, building, and GitOps deployment.

# Variables
DOCKER_USER := ashish97webdev1devops
VERSION := latest

.PHONY: help build-all push-all deploy observability-dashboard clean

help: ## Show this help message
	@echo "CoreBank Developer Automation Commands:"
	@echo "---------------------------------------"
	@echo "  make build-all             - Build all microservice images locally"
	@echo "  make push-all              - Tag and push images to Docker Hub ($(DOCKER_USER))"
	@echo "  make deploy                - Apply ArgoCD manifests to the cluster"
	@echo "  make observability         - Port-forward the Grafana metrics dashboard to localhost:3000"
	@echo "  make clean                 - Delete all K8s deployments in the prod-fintech namespace"

build-all: ## Build all Docker images
	@echo "Building Frontend..."
	docker build -t corebank-workspace-frontend:$(VERSION) ./corebank-workspace/corebank-frontend
	@echo "Building API Gateway..."
	docker build -t corebank-workspace-api-gateway:$(VERSION) ./corebank-workspace/corebank-api-gateway
	@echo "Building Identity Service..."
	docker build -t corebank-workspace-identity-service:$(VERSION) ./corebank-workspace/corebank-identity-go
	@echo "Building Transaction Engine..."
	docker build -t corebank-workspace-transaction-engine:$(VERSION) ./corebank-workspace/corebank-transaction-python
	@echo "All images built successfully!"

push-all: build-all ## Tag and push all images to Docker Hub
	@echo "Tagging and pushing images to $(DOCKER_USER)..."
	docker tag corebank-workspace-frontend:$(VERSION) $(DOCKER_USER)/corebank-frontend:$(VERSION)
	docker push $(DOCKER_USER)/corebank-frontend:$(VERSION)
	docker tag corebank-workspace-api-gateway:$(VERSION) $(DOCKER_USER)/corebank-api-gateway:$(VERSION)
	docker push $(DOCKER_USER)/corebank-api-gateway:$(VERSION)
	docker tag corebank-workspace-identity-service:$(VERSION) $(DOCKER_USER)/corebank-identity-service:$(VERSION)
	docker push $(DOCKER_USER)/corebank-identity-service:$(VERSION)
	docker tag corebank-workspace-transaction-engine:$(VERSION) $(DOCKER_USER)/corebank-transaction-engine:$(VERSION)
	docker push $(DOCKER_USER)/corebank-transaction-engine:$(VERSION)
	@echo "All images pushed to Docker Hub!"

deploy: ## Apply ArgoCD configurations
	@echo "Telling ArgoCD to sync the Git repository..."
	kubectl apply -f corebank-workspace/corebank-argocd-app.yaml
	kubectl apply -f corebank-workspace/corebank-observability-app.yaml
	@echo "Deployments triggered! Check ArgoCD UI."

observability: ## Port-forward Grafana
	@echo "Port-forwarding Grafana to http://localhost:3000"
	@echo "Username: admin | Password: prom-operator"
	kubectl port-forward svc/prometheus-stack-grafana -n monitoring 3000:80

clean: ## Remove K8s deployments to force a clean ArgoCD sync
	@echo "Deleting Deployments in prod-fintech namespace..."
	kubectl delete deployment --all -n prod-fintech
	@echo "ArgoCD will self-heal and recreate them shortly."
