variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "devopsplus"
}

variable "namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "dev"
}
