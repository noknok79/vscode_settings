---
description: "Diagnose and minimally fix Azure DevOps YAML pipeline failures."
agent: agent
argument-hint: "pipeline YAML, failing stage or logs, and optional acceptance criteria"
---

# Fix Azure Pipeline

Use the [fix-azure-pipeline skill](../skills/fix-azure-pipeline/SKILL.md) with the user's pipeline, logs, and acceptance criteria. If the target or failure is unclear, ask for the missing information.

- Focus changes on the pipeline; ask before modifying application scripts.
- Diagnose the root cause before applying the smallest safe fix. Check relevant templates, expressions, conditions, dependencies, and acceptance criteria.
- Preserve triggers, stages, jobs, variables, authentication, service connections, environments, and approvals unless the user explicitly requests a change.
- Validate the fix with available non-destructive checks, including a representative simulation where feasible. Distinguish local checks from an actual Azure Pipelines run.
- Never expose secrets, commit, push, queue a pipeline, or deploy without explicit approval.
- Report the root cause, files changed, validation results, unverified behavior, and remaining risks.
