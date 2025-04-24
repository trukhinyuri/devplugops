# DevOpsPlus Makefile

.PHONY: all build test clean run docker-build docker-push bootstrap deploy run-logs

# Variables
APP_NAME := api
DOCKER_REPO := ghcr.io/jetbrains/devopsplus/api
DOCKER_TAG ?= latest
NAMESPACE ?= dev

# Go build flags
GOOS ?= $(shell go env GOOS)
GOARCH ?= $(shell go env GOARCH)
GO_BUILD_FLAGS := -ldflags="-w -s"

# Kubernetes context
K8S_CONTEXT ?= docker-desktop

all: build

# Build the application
build:
	@echo "Building $(APP_NAME)..."
	@go build $(GO_BUILD_FLAGS) -o bin/$(APP_NAME) ./cmd/api

# Run tests with coverage
test:
	@echo "Running tests with coverage..."
	@go test -v -race -coverprofile=coverage.out ./...
	@go tool cover -func=coverage.out

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf bin/
	@rm -f coverage.out

# Run the application locally
run:
	@echo "Running $(APP_NAME) locally..."
	@go run ./cmd/api

# Build Docker image
docker-build:
	@echo "Building Docker image $(DOCKER_REPO):$(DOCKER_TAG)..."
	@docker build -t $(DOCKER_REPO):$(DOCKER_TAG) .

# Push Docker image
docker-push: docker-build
	@echo "Pushing Docker image $(DOCKER_REPO):$(DOCKER_TAG)..."
	@docker push $(DOCKER_REPO):$(DOCKER_TAG)

# Bootstrap local development environment
bootstrap:
	@echo "Bootstrapping local development environment..."
	@echo "Checking if Docker Desktop Kubernetes is enabled..."
	@kubectl config use-context docker-desktop || (echo "Error: Docker Desktop Kubernetes is not enabled. Please enable it in Docker Desktop settings." && exit 1)
	@echo "Applying Terraform configuration..."
	@cd terraform && terraform init && terraform apply -auto-approve
	@echo "Installing Prometheus operator..."
	@helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
	@helm repo update
	@helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
		--namespace monitoring --create-namespace
	@echo "Building Docker image..."
	@docker build -t $(APP_NAME):$(DOCKER_TAG) .
	@echo "Deploying application to Docker Desktop Kubernetes..."
	@helm upgrade --install $(APP_NAME) ./helm/chart \
		--set image.repository=$(APP_NAME) \
		--set image.tag=$(DOCKER_TAG) \
		--namespace $(NAMESPACE) --create-namespace

# Deploy to Kubernetes
deploy:
	@echo "Deploying $(APP_NAME) to Kubernetes..."
	@kubectl config use-context $(K8S_CONTEXT) || (echo "Error: Could not switch to $(K8S_CONTEXT) context." && exit 1)
	@helm upgrade --install $(APP_NAME) ./helm/chart \
		--set image.repository=$(APP_NAME) \
		--set image.tag=$(DOCKER_TAG) \
		--namespace $(NAMESPACE) --create-namespace

# Tail logs from the application
run-logs:
	@echo "Tailing logs from $(APP_NAME) in namespace $(NAMESPACE)..."
	@kubectl config use-context $(K8S_CONTEXT) || (echo "Error: Could not switch to $(K8S_CONTEXT) context." && exit 1)
	@kubectl logs -f -l app=$(APP_NAME) -n $(NAMESPACE) --tail=100
