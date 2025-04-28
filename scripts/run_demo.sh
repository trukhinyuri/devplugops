#!/usr/bin/env bash

# Source the colors utility
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/colors.sh"

print_info "Starting DevOps Error Demo Runner"
print_info "This script will run all error demo scripts with 1-second pauses"
print_info "Press Ctrl+C to stop at any time"
echo ""

# List of all error scripts
SCRIPTS=(
  "kubernetes_crashloopbackoff_A.sh"
  "kubernetes_crashloopbackoff_B.sh"
  "terraform_statelock_A.sh"
  "terraform_statelock_B.sh"
  "helm_upgrade_A.sh"
  "helm_upgrade_B.sh"
  "git_merge_conflict_A.sh"
  "git_merge_conflict_B.sh"
  "mysql_connections_A.sh"
  "mysql_connections_B.sh"
  "aws_throttling_A.sh"
  "aws_throttling_B.sh"
  "container_oomkilled_A.sh"
  "container_oomkilled_B.sh"
  "tls_certificate_A.sh"
  "tls_certificate_B.sh"
  "pagerduty_incident_A.sh"
  "pagerduty_incident_B.sh"
  "prometheus_tsdb_A.sh"
  "prometheus_tsdb_B.sh"
)

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Run each script with a pause
for script in "${SCRIPTS[@]}"; do
  print_info "Running: $script"
  print_info "----------------------------------------"

  # Run the script
  "$SCRIPT_DIR/$script"

  print_info "----------------------------------------"
  echo ""

  # Pause for 1 second
  sleep 1
done

print_info "All demo scripts completed!"
