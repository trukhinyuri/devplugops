# Local Jenkins Deployment for Kubernetes

This directory contains a simple Kubernetes deployment for Jenkins that can be used for local development and learning purposes.

## Prerequisites

- Kubernetes cluster running locally (e.g., Minikube, Kind, Docker Desktop with Kubernetes enabled)
- kubectl command-line tool installed and configured

## Deployment Instructions

1. Apply the deployment manifest:

```bash
kubectl apply -f deployment.yaml
```

   Note: The jenkins namespace will be automatically created if it doesn't exist yet, as it's defined in the deployment.yaml file.

   Important: Do not specify a different namespace (like `--namespace=default`) when applying this deployment, as all resources in the file are already configured to use the `jenkins` namespace. If you need to explicitly specify a namespace, use `--namespace=jenkins`.

2. Wait for the Jenkins pod to be ready:

```bash
kubectl -n jenkins get pods -w
```

3. Access Jenkins UI:
   - The Jenkins UI will be available at http://localhost:30080
   - If you're using Minikube, you may need to run `minikube service jenkins -n jenkins` to access it

## Initial Setup

When you first access Jenkins, you'll need to retrieve the initial admin password:

```bash
kubectl -n jenkins exec -it $(kubectl -n jenkins get pods -l app=jenkins -o jsonpath='{.items[0].metadata.name}') -- cat /var/jenkins_home/secrets/initialAdminPassword
```

## Cleanup

To remove the Jenkins deployment:

```bash
kubectl delete -f deployment.yaml
```

Note: Similar to the deployment, do not specify a different namespace when deleting. If you need to explicitly specify a namespace, use `--namespace=jenkins`.

## Configuration Notes

- The deployment uses a PersistentVolumeClaim to store Jenkins data
- Resource limits are set to be minimal (1 CPU, 1Gi memory)
- Jenkins is exposed via a NodePort service on port 30080
