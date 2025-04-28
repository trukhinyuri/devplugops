#!/usr/bin/env bash
# Source the colors utility
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/colors.sh"
# Source the colors utility
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/colors.sh"

print_yellow "Connection attempt to: auth.staging.example.org:8443"
print_yellow "TLS handshake initiated at: $(date '+%Y-%m-%d %H:%M:%S')"
print_error "Error: handshake failure: certificate has expired"
print_yellow "Certificate details:"
print_detail "  Subject: CN=auth.staging.example.org, O=Example Organization, C=UK"
print_detail "  Issuer: CN=Let's Encrypt Authority X3, O=Let's Encrypt, C=US"
print_detail "  Serial: 03:A1:B2:C3:D4:E5:F6:A7:B8:C9:D0:E1:F2:A3:B4:C5"
print_detail "  Valid from: 2023-04-20 12:30:45 UTC"
print_detail "  Valid until: 2024-04-19 12:30:45 UTC (EXPIRED)"
print_detail "  Fingerprint: SHA256:1A:2B:3C:4D:5E:6F:7A:8B:9C:0D:1E:2F:3A:4B:5C:6D"
print_yellow "Trace ID: trc_2a3b4c5d6e7f8a9b"
print_yellow "Recommendation: Please renew the TLS certificate for auth.staging.example.org"
print_yellow "Contact: security-team@example.org"