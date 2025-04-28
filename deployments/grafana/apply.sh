#!/bin/bash

# Apply all resources using kustomize
echo "Applying resources using kustomize..."
kubectl apply -k deployments/grafana

# Wait for Grafana pod to be ready
echo "Waiting for Grafana pod to be ready..."
kubectl wait --namespace monitoring --for=condition=ready pod --selector=app=grafana --timeout=300s

# Get the NodePort URL
echo "Grafana is ready!"
echo "Access Grafana at: http://localhost:30000"
echo "Username: admin"
echo "Password: admin"
echo ""
echo "Go to Alerting -> Alert rules to see the firing alerts"
