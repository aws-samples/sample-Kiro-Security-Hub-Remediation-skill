#!/usr/bin/env bash
# get-findings.sh — Query Security Hub for active findings by severity
# Usage: ./get-findings.sh [SEVERITY] [MAX_ITEMS]
# Example: ./get-findings.sh CRITICAL 25

set -euo pipefail

SEVERITY="${1:-CRITICAL}"
MAX_ITEMS="${2:-25}"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"

source "$(dirname "$0")/lib/preflight.sh"

echo "Querying Security Hub findings (Severity: $SEVERITY, Region: $REGION)..."

aws securityhub get-findings \
  --region "$REGION" \
  --filters "{
    \"SeverityLabel\": [{\"Value\": \"$SEVERITY\", \"Comparison\": \"EQUALS\"}],
    \"RecordState\": [{\"Value\": \"ACTIVE\", \"Comparison\": \"EQUALS\"}],
    \"WorkflowStatus\": [
      {\"Value\": \"NEW\", \"Comparison\": \"EQUALS\"},
      {\"Value\": \"NOTIFIED\", \"Comparison\": \"EQUALS\"}
    ]
  }" \
  --max-items "$MAX_ITEMS" \
  --output json
