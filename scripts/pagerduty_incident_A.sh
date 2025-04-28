#!/usr/bin/env bash
# Source the colors utility
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/colors.sh"
# Source the colors utility
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/colors.sh"

print_yellow "[PagerDuty] Incident #P-123456 - $(date '+%Y-%m-%d %H:%M:%S')"
print_error "SEV-1 incident triggered: ServiceLatencyHigh"
print_yellow "Service: payment-processing-api"
print_yellow "Environment: production"
print_yellow "Region: us-east-1"
print_detail "Alert details:"
print_detail "  - Threshold: p99 latency > 500ms for 5 minutes"
print_detail "  - Current value: 782ms"
print_detail "  - Started at: $(date -v-5M '+%Y-%m-%d %H:%M:%S')"
print_detail "  - Affected endpoints: /api/v1/payments/process, /api/v1/payments/verify"
print_detail "  - Impact: Potential payment processing delays for customers"
print_yellow "Assigned to: primary-oncall@example.com"
print_yellow "Escalation policy: payment-team-escalation"
print_yellow "Runbook: https://runbooks.example.com/payment-api/high-latency"
print_yellow "Dashboard: https://grafana.example.com/d/payment-api-overview"