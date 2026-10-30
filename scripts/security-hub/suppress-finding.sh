#!/usr/bin/env bash
# suppress-finding.sh — Suppress a finding (mark as false positive or accepted risk)
# Usage: ./suppress-finding.sh FINDING_ID PRODUCT_ARN "Justification"

set -euo pipefail

FINDING_ID="${1:?Usage: suppress-finding.sh FINDING_ID PRODUCT_ARN JUSTIFICATION}"
PRODUCT_ARN="${2:?Usage: suppress-finding.sh FINDING_ID PRODUCT_ARN JUSTIFICATION}"
JUSTIFICATION="${3:?Please provide a justification for suppression}"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"

source "$(dirname "$0")/lib/preflight.sh"

echo "Suppressing finding: $FINDING_ID"
echo "Justification: $JUSTIFICATION"

aws securityhub batch-update-findings \
  --region "$REGION" \
  --finding-identifiers "[{\"Id\":\"$FINDING_ID\",\"ProductArn\":\"$PRODUCT_ARN\"}]" \
  --workflow '{"Status":"SUPPRESSED"}' \
  --note "{\"Text\":\"Suppressed: $JUSTIFICATION\",\"UpdatedBy\":\"kiro-security-hub-skill\"}"

echo "Finding SUPPRESSED."
