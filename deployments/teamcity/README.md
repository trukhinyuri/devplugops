# TeamCity Kubernetes Deployment

This directory contains Kubernetes configuration files for deploying TeamCity in a local Kubernetes cluster for experimentation purposes.

## Components

The deployment consists of:

1. **TeamCity Server** - The main TeamCity application server
2. **TeamCity Agent** - A build agent that connects to the TeamCity server
3. **Persistent Volumes** - For storing TeamCity data and logs

## Prerequisites

- A running Kubernetes cluster (e.g., minikube, kind, k3s)
- kubectl configured to communicate with your cluster

## Deployment

To deploy TeamCity to your Kubernetes cluster:

```bash
kubectl apply -f deployment.yaml
```

## Accessing TeamCity

Once deployed, TeamCity will be accessible at:

- URL: http://[NODE_IP]:30111
- Where [NODE_IP] is the IP address of any node in your Kubernetes cluster

For local development with minikube, you can get the URL with:

```bash
minikube service teamcity-server --url
```

## Initial Setup

When you first access TeamCity, you'll need to:

1. Accept the license agreement
2. Create an administrator account
3. Configure the server URL (use the external URL you're accessing it with)

## Connecting Additional Build Agents

The deployment includes one build agent. To add more agents, you can scale the agent deployment:

```bash
kubectl scale deployment teamcity-agent --replicas=3
```

## Cleanup

To remove the TeamCity deployment:

```bash
kubectl delete -f deployment.yaml
```

Note: This will not delete the persistent volumes. To delete them as well:

```bash
kubectl delete pvc teamcity-data teamcity-logs
```