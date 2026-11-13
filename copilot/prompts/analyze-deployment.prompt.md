---
description: Investigate failed deployments end to end
agent: agent
argument-hint: "deployment error, logs, or environment"
---

# Analyze Deployment

Target: use the user's chat input and selected files; if none is specified, use relevant workspace context.

## Task
Trace build artifact, pipeline stage, configuration, identity, registry, target service, health checks, and rollback readiness. Separate symptoms from proven root causes. Recommend least-risk diagnostics first; never deploy or roll back without explicit approval.

## Operating rules
- Inspect relevant workspace files and existing project instructions before proposing edits.
- Identify the root cause; avoid speculative or unrelated changes.
- Preserve existing behavior, interfaces, naming, and deployment intent unless a change is necessary and explained.
- Prefer the smallest maintainable correction. Avoid redundant guards, nested branches, broad exception handling, and unnecessary abstractions.
- Never print, commit, or expose secrets. Never execute destructive commands or apply infrastructure changes without explicit approval.
- Consult official documentation when tools are available; distinguish verified guidance from assumptions.
- Run available non-destructive validation. Report commands run, outcomes, and checks that could not be performed. Never claim a check passed unless executed.
- Finish with: Root cause; Files changed; Validation; Remaining risks.
