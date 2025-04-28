#!/usr/bin/env bash

# Source the colors utility
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/colors.sh"

print_yellow "Kubernetes cluster: production-east1"
print_yellow "Namespace: backend-api"
print_error "pod/web-api-6fbdc ✖ CrashLoopBackOff — back-off 5m0s"
print_yellow "Events:"
print_detail "  Type     Reason     Age                From               Message"
print_detail "  ----     ------     ----               ----               -------"
print_detail "  Warning  BackOff    12s (x6 over 2m)   kubelet            Back-off restarting failed container"
print_detail "  Normal   Pulling    42s                kubelet            Pulling image \"registry.company.io/web-api:v1.2.3\""
print_detail "  Normal   Pulled     40s                kubelet            Successfully pulled image \"registry.company.io/web-api:v1.2.3\""
print_detail "  Normal   Created    39s                kubelet            Created container web-api"
print_detail "  Normal   Started    38s                kubelet            Started container web-api"
print_detail "  Warning  Unhealthy  28s (x3 over 38s)  kubelet            Liveness probe failed: HTTP probe failed with statuscode: 500"
