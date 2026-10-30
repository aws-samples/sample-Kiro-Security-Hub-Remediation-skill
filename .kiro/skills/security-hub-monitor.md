# Security Hub Monitor & Remediation

## Description
A Kiro skill for querying AWS Security Hub findings, triaging them by severity, and applying automated or guided remediation. Designed for security engineers and DevOps teams who want to stay on top of their cloud security posture directly from the IDE.

## Capabilities
- Query Security Hub findings filtered by severity, resource type, compliance status, or account
- Summarize findings with actionable context
- Suggest and apply remediation steps (IAM policy tightening, S3 bucket hardening, security group fixes, etc.)
- Generate infrastructure-as-code patches (CloudFormation/Terraform) for persistent fixes
- Track remediation progress and suppress resolved findings
- Export findings summaries as markdown reports

## Prerequisites
- AWS CLI v2 installed and configured with appropriate credentials
- IAM permissions: `securityhub:GetFindings`, `securityhub:BatchUpdateFindings`, `securityhub:GetInsights`
- Optional: `iam:*`, `s3:*`, `ec2:*` permissions for automated remediation

## Usage
Ask Kiro to:
- "Show me critical Security Hub findings"
- "What are the top unresolved findings for my S3 buckets?"
- "Remediate finding [ARN] by tightening the IAM policy"
- "Generate a Terraform fix for this security group issue"
- "Suppress this finding as a false positive"
- "Give me a weekly security posture report"

## Included Components
- **Steering file**: `.kiro/steering/security-hub.md` — Always-on context for Security Hub interactions
- **Hook**: `security-hub-check` — On-demand trigger to pull latest critical findings
- **Scripts**: Helper scripts in `scripts/security-hub/` for common operations
