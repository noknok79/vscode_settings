---
description: "Review the ACR-to-Container-App rollback process and pipeline steps against industry standard."
agent: code-reviewer
---

# Objective
Review the rollback process in `{{rollbackPipelineFile}}` and `{{pipelineFile}}` against industry standard, and list the Azure pipeline steps to roll `{{containerApp}}` back to a retained ACR image.

# Constraints
- Read-only; do not edit files.
- Use Microsoft Learn, GitHub, and StackOverflow practice; cite only sources actually fetched; mark the rest unverified.
- Clarify that rollback redeploys an existing image and does not push to ACR.
- Findings need severity (High/Medium/Low), file evidence, and a minimal fix.

# Process
6 phases, trillion sanity verify.

# Output
Ordered pipeline steps, findings by severity, unverified items, and a recommended next action.
