#!/usr/bin/env bash
# resolve-finding.sh — Mark a finding as resolved in Security Hub
# Usage: ./resolve-finding.sh FINDING_ID PRODUCT_ARN "Remediation note"

set -euo pipefail

FINDING_ID="${1:?Usage: resolve-finding.sh FINDING_ID PRODUCT_ARN NOTE}"
PRODUCT_ARN="${2:?Usage: resolve-finding.sh FINDING_ID PRODUCT_ARN NOTE}"
NOTE="${3:-Remediated via kiro-security-hub-skill}"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"

source "$(dirname "$0")/lib/preflight.sh"

echo "Resolving finding: $FINDING_ID"
echo "Note: $NOTE"

aws securityhub batch-update-findings \
  --region "$REGION" \
  --finding-identifiers "[{\"Id\":\"$FINDING_ID\",\"ProductArn\":\"$PRODUCT_ARN\"}]" \
  --workflow '{"Status":"RESOLVED"}' \
  --note "{\"Text\":\"$NOTE\",\"UpdatedBy\":\"kiro-security-hub-skill\"}"

echo "Finding marked as RESOLVED."
