---
inclusion: manual
description: "Pulls the latest critical and high severity findings from AWS Security Hub on demand, summarizes them, provides tangible remediation next steps, and compares posture against AWS Well-Architected best practices."
---

Run the Security Hub get-findings script for both CRITICAL and HIGH severities, then produce a report in three sections. Follow the guidance in #[[file:security-hub.md]].

Commands to run:
1. bash "./scripts/security-hub/get-findings.sh" CRITICAL 25
2. bash "./scripts/security-hub/get-findings.sh" HIGH 25

Note: each script prints a status line before the JSON, so strip the first line before parsing (e.g. pipe through `tail -n +2 | jq ...`). Base every claim only on findings actually returned; never invent data.

## Section 1 - Findings Summary
A table grouped by severity showing: Control ID, Title, Resource ID, AWS Account, and Compliance Status. Include finding counts per severity and call out the top affected resources.

## Section 2 - Tangible Remediation Next Steps
For each finding (CRITICAL first), give a concrete, actionable step the user can take now, including the exact AWS CLI command or IaC change where one exists. Prioritize by severity and blast radius, flag quick wins (single account-level toggles) versus changes needing a workload owner or redeploy, and note reversibility. Do NOT execute any remediation - present the steps and wait for the user to choose.

## Section 3 - Well-Architected Comparison
Compare the current state against the AWS Well-Architected Framework Security Pillar using the mapping in the steering file. Output a table: Best Practice Area | Status (Aligned/At Risk/Gap/Unknown) | Evidence (which findings). Only mark an area Aligned/At Risk/Gap when a returned finding supports it; otherwise mark Unknown.

## Section 4 - Security / Compliance / Governance Services
Recommend AWS services (e.g. AWS Config, GuardDuty, Inspector, IAM Access Analyzer, Organizations/SCPs, Control Tower, Firewall Manager, Macie, Audit Manager, CloudTrail, Systems Manager) that would help prevent, detect, or continuously manage the returned findings. Tie each recommendation to specific findings or best-practice areas, prefer preventive controls over one-time manual fixes when a finding is likely to recur, and only list services connected to what was returned. Use the service mapping in the steering file.

End by asking which finding the user wants to remediate first.
