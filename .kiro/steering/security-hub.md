---
inclusion: manual
---

# AWS Security Hub — Agent Guidance

## Context
You are assisting with AWS Security Hub finding triage and remediation. Always prioritize findings by severity: CRITICAL > HIGH > MEDIUM > LOW > INFORMATIONAL.

## Workflow

### 1. Querying Findings
Use the helper scripts in `scripts/security-hub/` or run AWS CLI commands directly:
```bash
# Get critical/high findings (active, not suppressed)
aws securityhub get-findings \
  --filters '{"SeverityLabel":[{"Value":"CRITICAL","Comparison":"EQUALS"}],"RecordState":[{"Value":"ACTIVE","Comparison":"EQUALS"}],"WorkflowStatus":[{"Value":"NEW","Comparison":"EQUALS"},{"Value":"NOTIFIED","Comparison":"EQUALS"}]}' \
  --max-items 25
```

### 2. Triaging Findings
When presenting findings to the user:
- Group by resource type (S3, IAM, EC2, RDS, Lambda, etc.)
- Show: Title, Severity, Resource ARN, Account ID, First Observed, Compliance Status
- Highlight quick wins (findings with known automated fixes)
- Flag findings that affect multiple resources

### 3. Remediation Approach
For each finding, determine the remediation path:
- **Automated**: Generate and apply IaC patches or CLI commands
- **Guided**: Walk the user through manual steps with verification
- **Suppress**: Mark as false positive or accepted risk with justification

### 4. Common Remediation Patterns

#### S3 Public Access
```bash
aws s3api put-public-access-block --bucket BUCKET_NAME \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

#### Security Group Open to World
```bash
aws ec2 revoke-security-group-ingress --group-id SG_ID --protocol tcp --port PORT --cidr 0.0.0.0/0
```

#### IAM Policy Too Permissive
Generate a scoped-down policy using Access Analyzer recommendations.

#### Encryption Not Enabled
```bash
aws s3api put-bucket-encryption --bucket BUCKET_NAME \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms"}}]}'
```

### 5. After Remediation
- Verify the fix by re-running the relevant check
- Update the finding workflow status to RESOLVED
- Document what was changed and why

```bash
aws securityhub batch-update-findings \
  --finding-identifiers '[{"Id":"FINDING_ID","ProductArn":"PRODUCT_ARN"}]' \
  --workflow '{"Status":"RESOLVED"}' \
  --note '{"Text":"Remediated by applying X","UpdatedBy":"kiro-security-hub-skill"}'
```

## Well-Architected Comparison
After summarizing findings, compare the current posture against the AWS Well-Architected Framework **Security Pillar**. AWS publishes a Config conformance pack that maps controls to this pillar; use it as the reference model.
Reference: https://docs.aws.amazon.com/config/latest/developerguide/operational-best-practices-for-wa-Security-Pillar.html

Map each finding to the Security Pillar best-practice area it violates, then state whether that area is **Aligned**, **At Risk**, or **Gap**:

| Best Practice Area | What "good" looks like | Common Security Hub controls in this area |
|--------------------|------------------------|-------------------------------------------|
| Security Foundations | Account-level guardrails on; secure-by-default settings | SSM.7, EC2.182, account-level block-public settings |
| Identity & Access Management | Least privilege, no overly permissive policies, MFA | IAM.*, scoped policies, Access Analyzer |
| Detection | Threat detection and monitoring enabled everywhere | GuardDuty.*, Inspector.*, Config, CloudTrail |
| Infrastructure Protection | No open ingress, network segmentation, private-by-default | EC2.2, security-group controls, VPC/network mode (BedrockAgentCore.1) |
| Data Protection | Encryption at rest/in transit, no public data exposure | S3 public access, EBS/RDS encryption, snapshot public access |
| Incident Response | Findings triaged, workflow tracked, runbooks exist | Workflow status hygiene, suppression with justification |
| Application Security | AuthN/AuthZ on app entry points, code scanning | BedrockAgentCore.2 (gateway auth), Inspector Lambda scanning |

For the comparison output, produce a short table: **Best Practice Area | Status (Aligned/At Risk/Gap) | Evidence (which findings)**. Keep it grounded only in findings actually returned — do not assume areas are aligned if there is no evidence either way; mark those **Unknown**.

## Security / Compliance / Governance Service Recommendations
After the Well-Architected comparison, recommend AWS security, compliance, and governance services that would help prevent, detect, or continuously manage the returned findings. Tie each recommendation to the findings or best-practice areas it supports; do not list services with no connection to what was returned.

Reference mapping of common services to what they solve:

| Service | Category | Helps with |
|---------|----------|------------|
| AWS Config | Governance / Detection | Continuous config recording + rules; backs most Security Hub controls (SSM.7, EC2.2, EC2.182) and drives auto-remediation |
| AWS Security Hub (standards + automation rules) | Governance | Central finding aggregation, standards scoring, automation rules to auto-set workflow status |
| Amazon GuardDuty | Detection | Threat detection incl. Runtime/EKS monitoring (GuardDuty.7, GuardDuty.11) |
| Amazon Inspector | Detection | Continuous vulnerability + code scanning for EC2, ECR, Lambda (Inspector.3) |
| AWS IAM Access Analyzer | IAM / Data Protection | Finds public/cross-account access and over-permissive policies; policy validation |
| AWS Organizations + SCPs | Governance | Org-wide guardrails to prevent public sharing / risky actions before they happen |
| AWS Control Tower | Governance | Landing zone with preventive + detective guardrails across accounts |
| AWS Firewall Manager | Infrastructure Protection | Central management of security groups / WAF rules (EC2.2 at scale) |
| Amazon Macie | Data Protection | Discovers and classifies sensitive data in S3 |
| AWS Audit Manager | Compliance | Maps evidence to frameworks (CIS, PCI DSS, etc.) for audits |
| AWS CloudTrail | Detection / Incident Response | API audit logging, foundation for investigation |
| AWS Systems Manager (Automation / Quick Setup) | Governance / Remediation | Runbooks and auto-remediation wired to Config rules |

Prefer preventive controls (SCPs, Config auto-remediation, Firewall Manager) over one-time manual fixes when a finding is likely to recur, and say so. Keep recommendations grounded in the findings actually returned.

## Safety Rules
- NEVER apply remediation without user confirmation for production resources
- Always show the exact commands/changes before executing
- For IAM changes, show a diff of the policy before and after
- Flag if a remediation could cause service disruption
- Suggest testing in a non-production account first when possible

## Output Format
When presenting findings, use this structure:
```
## [SEVERITY] Finding Title
- **Resource**: arn:aws:service:region:account:resource
- **Account**: 123456789012
- **First Seen**: 2026-07-01
- **Status**: NEW
- **Remediation**: [Automated|Guided|Suppress]
- **Suggested Fix**: Brief description
```
