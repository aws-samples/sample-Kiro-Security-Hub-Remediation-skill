#!/usr/bin/env bash
# preflight.sh — Shared prerequisite checks for the Security Hub scripts.
# Source this at the top of each script:  source "$(dirname "$0")/lib/preflight.sh"
#
# Verifies (in order):
#   1. AWS CLI is installed and on PATH
#   2. Credentials are configured and valid
#   3. Security Hub is enabled in the target region
#
# Set SKIP_SECURITYHUB_CHECK=1 to skip the (extra API call) Security Hub check.

# Resolve the region the same way the calling scripts do.
_PREFLIGHT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

_preflight_fail() {
  echo "[preflight] ERROR: $1" >&2
  exit 1
}

# 1. AWS CLI present?
if ! command -v aws >/dev/null 2>&1; then
  _preflight_fail "AWS CLI not found on PATH. Install AWS CLI v2: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
fi

# 2. Credentials valid?
if ! aws sts get-caller-identity >/dev/null 2>&1; then
  _preflight_fail "Unable to authenticate with AWS. Configure credentials (aws configure, aws sso login, or set AWS_PROFILE) and try again."
fi

# 3. Security Hub enabled in this region?
if [[ "${SKIP_SECURITYHUB_CHECK:-0}" != "1" ]]; then
  if ! aws securityhub describe-hub --region "$_PREFLIGHT_REGION" >/dev/null 2>&1; then
    _preflight_fail "Security Hub does not appear to be enabled in region '$_PREFLIGHT_REGION' (or the caller lacks securityhub:DescribeHub). Enable it: aws securityhub enable-security-hub --region $_PREFLIGHT_REGION"
  fi
fi
