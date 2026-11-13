---
description: Diagnose and minimally fix Azure DevOps YAML pipeline failures
agent: agent
argument-hint: "pipeline YAML, stage, or error"
---

# Fix Azure Pipeline

Target: use the user's chat input and selected files; if none is specified, use relevant workspace context.

## Task
Inspect templates, parameters, variables, conditions, dependencies, service connections, and task versions. Trace compile-time versus runtime expressions and job/stage boundaries. Verify Azure Pipelines syntax and task behavior against Microsoft Learn where accessible. Apply a minimal fix and validate YAML syntax; do not queue or deploy without approval.

## Operating rules
- Inspect relevant workspace files and existing project instructions before proposing edits.
- Identify the root cause; avoid speculative or unrelated changes.
- Preserve existing behavior, interfaces, naming, and deployment intent unless a change is necessary and explained.
- Prefer the smallest maintainable correction. Avoid redundant guards, nested branches, broad exception handling, and unnecessary abstractions.
- Never print, commit, or expose secrets. Never execute destructive commands or apply infrastructure changes without explicit approval.
- Consult official documentation when tools are available; distinguish verified guidance from assumptions.
- Run available non-destructive validation. Report commands run, outcomes, and checks that could not be performed. Never claim a check passed unless executed.
- Finish with: Root cause; Files changed; Validation; Remaining risks.
