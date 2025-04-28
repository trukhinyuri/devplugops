#!/usr/bin/env bash
# Source the colors utility
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/colors.sh"
# Source the colors utility
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/colors.sh"

print_yellow "Connection attempt to: api.production.example.com:443"
print_yellow "TLS handshake initiated at: $(date '+%Y-%m-%d %H:%M:%S')"
print_error "Error: handshake failure: certificate has expired"
print_yellow "Certificate details:"
print_detail "  Subject: CN=api.production.example.com, O=Example Corp, C=US"
print_detail "  Issuer: CN=Example Root CA, O=Example Corp, C=US"
print_detail "  Serial: 4B:6D:8A:2F:1C:B9:5E:7A:91:D4:70:13:C8:6F:2D:E4"
print_detail "  Valid from: 2023-01-15 00:00:00 UTC"
print_detail "  Valid until: 2024-01-15 23:59:59 UTC (EXPIRED)"
print_detail "  Fingerprint: SHA256:8F:E5:D3:B2:7A:1E:C9:4B:8D:0A:6F:E7:B1:5D:C3:9E:F4:A1:B8:D7"
print_yellow "Trace ID: trc_f8e92a7d3b5c1e90"
print_yellow "Recommendation: Please renew the TLS certificate for api.production.example.com"