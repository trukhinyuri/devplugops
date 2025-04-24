terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
  required_version = ">= 1.0"
}

# Configure the Kubernetes provider to use Docker Desktop's Kubernetes
provider "kubernetes" {
  config_path    = "~/.kube/config"  # Default path to kubeconfig file
  config_context = "docker-desktop"  # Docker Desktop's Kubernetes context
}

# Create a namespace for our application
resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.namespace
    labels = {
      environment = var.environment
      project     = var.project_name
      managed_by  = "terraform"
    }
  }
}

# Output the namespace name
output "namespace" {
  value = kubernetes_namespace.app_namespace.metadata[0].name
}

# Output the Kubernetes context
output "kubernetes_context" {
  value = "docker-desktop"
}

# Output the cluster name
output "cluster_name" {
  value = "docker-desktop"
}
