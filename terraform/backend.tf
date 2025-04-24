terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# Using local backend for Docker Desktop Kubernetes deployment
# This keeps the state file in the local directory, which is simpler for local development
