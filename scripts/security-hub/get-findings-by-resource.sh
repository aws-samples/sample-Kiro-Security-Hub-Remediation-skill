#!/usr/bin/env bash
# get-findings-by-resource.sh — Query findings for a specific resource type
# Usage: ./get-findings-by-resource.sh RESOURCE_TYPE [MAX_ITEMS]
# Example: ./get-findings-by-resource.sh AwsS3Bucket 20
#          ./get-findings-by-resource.sh AwsIamRole 10
#          ./get-findings-by-resource.sh AwsEc2SecurityGroup 15

set -euo pipefail

RESOURCE_TYPE="${1:?Usage: get-findings-by-resource.sh RESOURCE_TYPE [MAX_ITEMS]}"
MAX_ITEMS="${2:-20}"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"

source "$(dirname "$0")/lib/preflight.sh"

echo "Querying findings for resource type: $RESOURCE_TYPE (Region: $REGION)..."

aws securityhub get-findings \
  --region "$REGION" \
  --filters "{
    \"ResourceType\": [{\"Value\": \"$RESOURCE_TYPE\", \"Comparison\": \"EQUALS\"}],
    \"RecordState\": [{\"Value\": \"ACTIVE\", \"Comparison\": \"EQUALS\"}],
    \"WorkflowStatus\": [
      {\"Value\": \"NEW\", \"Comparison\": \"EQUALS\"},
      {\"Value\": \"NOTIFIED\", \"Comparison\": \"EQUALS\"}
    ]
  }" \
  --sort-criteria '[{"Field":"SeverityNormalized","SortOrder":"desc"}]' \
  --max-items "$MAX_ITEMS" \
  --output json
