#!/usr/bin/env bash
# Source the colors utility
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/colors.sh"
# Source the colors utility
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/colors.sh"

print_yellow "Kubernetes cluster: staging-west2"
print_yellow "Namespace: frontend"
print_error "pod/user-service-8d7c9 ✖ CrashLoopBackOff — back-off 3m0s"
print_yellow "Events:"
print_detail "  Type     Reason     Age                From               Message"
print_detail "  ----     ------     ----               ----               -------"
print_detail "  Warning  BackOff    8s (x4 over 1m)    kubelet            Back-off restarting failed container"
print_detail "  Normal   Pulling    35s                kubelet            Pulling image \"registry.company.io/user-service:v2.0.1\""
print_detail "  Normal   Pulled     32s                kubelet            Successfully pulled image \"registry.company.io/user-service:v2.0.1\""
print_detail "  Normal   Created    31s                kubelet            Created container user-service"
print_detail "  Normal   Started    30s                kubelet            Started container user-service"
print_detail "  Warning  Unhealthy  20s (x2 over 30s)  kubelet            Readiness probe failed: connection refused"