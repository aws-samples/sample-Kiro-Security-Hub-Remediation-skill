# Kiro Security Hub Skill

A shareable Kiro skill for monitoring and remediating AWS Security Hub findings directly from your IDE. Drop it into any project and your team gets on-demand security posture checks, guided remediation, and IaC fix generation.

## Quick Start

```bash
# 1. Copy into your project
cp -r .kiro/ /path/to/your/project/.kiro/
cp -r scripts/security-hub/ /path/to/your/project/scripts/security-hub/

# 2. Make scripts executable
chmod +x /path/to/your/project/scripts/security-hub/*.sh

# 3. Verify AWS access
aws securityhub get-findings --max-items 1
```

That's it. Open Kiro and click the **Security Hub Check** button in the Agent Hooks panel.

## What Gets Deployed

```
.kiro/
├── skills/
│   └── security-hub-monitor.md       # Skill definition (entry point)
├── steering/
│   ├── security-hub.md               # Agent guidance for remediation workflows
│   └── security-hub-check.md         # Manual steering version of the Security Hub Check report prompt
└── hooks/
    └── security-hub-check.kiro.hook  # On-demand hook — pulls CRITICAL + HIGH findings

scripts/security-hub/
├── get-findings.sh                   # Query findings by severity
├── get-findings-by-resource.sh       # Query findings by resource type
├── summarize-findings.sh             # Quick posture summary
├── resolve-finding.sh                # Mark finding as resolved
├── suppress-finding.sh               # Suppress a finding with justification
└── lib/
    └── preflight.sh                  # Shared prerequisite checks sourced by every script
```

### How It Works Together

| Component | Role |
|-----------|------|
| **Hook** (`security-hub-check.kiro.hook`) | One-click trigger that runs the scan and asks the agent to summarize |
| **Steering** (`security-hub.md`) | Tells the agent how to triage, remediate, and format findings |
| **Skill** (`security-hub-monitor.md`) | Registers the capability so users can reference it with `#security-hub` |
| **Scripts** | Thin wrappers around `aws securityhub` CLI for repeatability |

### About the "legacy" badge

In Kiro 1.0+ the IDE may show a **legacy** badge next to the Security Hub Check hook. This is expected and harmless:

- The hook uses the `.kiro.hook` file format, which Kiro labels "legacy" in newer versions.
- **It is fully functional** — the badge is informational only. It does not disable the hook, degrade behavior, or block anything. The hook runs exactly as it always has.
- `security-hub-check.kiro.hook` is the file Kiro executes for this hook.

If you'd rather not see the badge, you can recreate the hook through the Kiro Hook UI (command palette → **Open Kiro Hook UI**), which writes it in the current format. This is optional — there's no functional reason to migrate.

## Prerequisites

- **AWS CLI v2** — [Install guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **IAM Permissions** (minimum for read-only):
  ```json
  {
    "Effect": "Allow",
    "Action": [
      "securityhub:GetFindings",
      "securityhub:BatchUpdateFindings",
      "securityhub:GetInsights",
      "securityhub:ListMembers"
    ],
    "Resource": "*"
  }
  ```
- **For automated remediation** (optional): additional permissions for target services (IAM, S3, EC2, etc.)

> The scripts run a **preflight check** before calling AWS. They verify the AWS CLI is installed, your credentials are valid, and Security Hub is enabled in the target region, then exit with a clear message if anything is missing. To skip the Security Hub enablement check (one extra API call), set `SKIP_SECURITYHUB_CHECK=1`.

## Usage

### On-Demand Hook (Recommended)

Click **Security Hub Check** in the Agent Hooks panel or trigger it from the command palette. It will:

1. Run `get-findings.sh` for CRITICAL and HIGH severities
2. Present a table grouped by severity with Title, Resource ID, Account, and Compliance Status
3. Recommend next steps and remediation priorities

### In Kiro Chat

Reference the skill with `#security-hub`, then ask:

- "Show me all critical findings"
- "What S3 buckets have public access issues?"
- "Remediate the open security group finding for sg-abc123"
- "Generate a Terraform fix for this IAM finding"
- "Suppress finding X as accepted risk — we need public access for this CDN bucket"
- "Give me a security posture report"

### Scripts Directly

```bash
./scripts/security-hub/get-findings.sh CRITICAL           # Critical findings
./scripts/security-hub/get-findings.sh HIGH 50            # Up to 50 high findings
./scripts/security-hub/get-findings-by-resource.sh AwsS3Bucket
./scripts/security-hub/summarize-findings.sh              # Quick counts
./scripts/security-hub/resolve-finding.sh "finding-id" "product-arn" "Fixed by applying encryption"
./scripts/security-hub/suppress-finding.sh "finding-id" "product-arn" "Accepted risk: public docs bucket"
```

## Worked Example: Remediating a Finding End-to-End

Here's a complete flow for a real CRITICAL finding — **SSM.7: SSM documents should have the block public sharing setting enabled**.

**1. Find it.** Run the hook, or the script directly:

```bash
./scripts/security-hub/get-findings.sh CRITICAL 25
```

The script prints a status line before the JSON, so strip it before parsing with `jq`:

```bash
./scripts/security-hub/get-findings.sh CRITICAL 25 2>/dev/null | tail -n +2 \
  | jq -r '.Findings[] | [.Compliance.SecurityControlId, .Title, .Compliance.Status] | @tsv'
# SSM.7    SSM documents should have the block public sharing setting enabled    FAILED
```

**2. Confirm the current (insecure) state.** SSM.7 fails when public sharing is *allowed* (`Enable`):

```bash
aws ssm get-service-setting --region us-east-1 \
  --setting-id /ssm/documents/console/public-sharing-permission
# "SettingValue": "Enable"   <- public sharing permitted
```

**3. Remediate.** Block public sharing (note: `Disable` = the secure choice, it disables the ability to share publicly):

```bash
aws ssm update-service-setting --region us-east-1 \
  --setting-id /ssm/documents/console/public-sharing-permission \
  --setting-value Disable
```

**4. Verify the change landed** (the API returns no output on success, so check explicitly):

```bash
aws ssm get-service-setting --region us-east-1 \
  --setting-id /ssm/documents/console/public-sharing-permission
# "SettingValue": "Disable", "Status": "Customized"
```

**5. (Optional) Mark it resolved in Security Hub.** Security Hub re-evaluates on the backing AWS Config rule's next run (usually within a few hours) and will flip to `PASSED` on its own. If you want to close the workflow immediately:

```bash
./scripts/security-hub/resolve-finding.sh "<finding-id>" "<product-arn>" \
  "Blocked public SSM document sharing at the account level"
```

**Rollback**, if ever needed, is symmetric: re-run step 3 with `--setting-value Enable`.

> Rule of thumb: prefer *preventive* controls for findings that recur. For account-wide settings like this one, an AWS Organizations SCP that denies re-enabling public sharing stops the finding from coming back at all.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `AWS_DEFAULT_REGION` | `us-east-1` | Region for Security Hub queries |
| `AWS_PROFILE` | default profile | Named profile for credentials |

### Multi-Account

If you use Security Hub with a delegated administrator or cross-region aggregation, everything works against your aggregated view automatically. Just ensure your credentials have the right cross-account access.

## Customization

- **Add remediation patterns**: Edit `.kiro/steering/security-hub.md` to add resource-specific fix templates
- **Change severity thresholds**: Edit the hook prompt in `.kiro/hooks/security-hub-check.kiro.hook`
- **Add automated triggers**: Create additional hooks with `fileEdited` or `promptSubmit` events

## Sharing

### Option A: Copy directories
```bash
cp -r .kiro/ /path/to/target/.kiro/
cp -r scripts/security-hub/ /path/to/target/scripts/security-hub/
chmod +x /path/to/target/scripts/security-hub/*.sh
```

### Option B: Git submodule
```bash
git submodule add <this-repo-url> .kiro-skills/security-hub
ln -s .kiro-skills/security-hub/.kiro/hooks/security-hub-check.kiro.hook .kiro/hooks/security-hub-check.kiro.hook
ln -s .kiro-skills/security-hub/.kiro/skills/security-hub-monitor.md .kiro/skills/security-hub-monitor.md
ln -s .kiro-skills/security-hub/.kiro/steering/security-hub.md .kiro/steering/security-hub.md
ln -s .kiro-skills/security-hub/.kiro/steering/security-hub-check.md .kiro/steering/security-hub-check.md
```

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the [LICENSE](LICENSE) file.
