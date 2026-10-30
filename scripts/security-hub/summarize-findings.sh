#!/usr/bin/env bash
# summarize-findings.sh — Get a quick posture summary across all severities
# Usage: ./summarize-findings.sh

set -euo pipefail

REGION="${AWS_DEFAULT_REGION:-us-east-1}"

source "$(dirname "$0")/lib/preflight.sh"

echo "Security Hub Posture Summary"
echo "============================"
echo "Region: $REGION"
echo "Date: $(date -u '+%Y-%m-%d %H:%M UTC')"
echo ""

for severity in CRITICAL HIGH MEDIUM LOW; do
  count=$(aws securityhub get-findings \
    --region "$REGION" \
    --filters "{
      \"SeverityLabel\": [{\"Value\": \"$severity\", \"Comparison\": \"EQUALS\"}],
      \"RecordState\": [{\"Value\": \"ACTIVE\", \"Comparison\": \"EQUALS\"}],
      \"WorkflowStatus\": [
        {\"Value\": \"NEW\", \"Comparison\": \"EQUALS\"},
        {\"Value\": \"NOTIFIED\", \"Comparison\": \"EQUALS\"}
      ]
    }" \
    --query 'length(Findings)' \
    --output text 2>/dev/null | awk '{sum += $1} END {print sum + 0}')
  
  echo "$severity: $count active findings"
done

echo ""
echo "Run './get-findings.sh CRITICAL' for detailed findings."
