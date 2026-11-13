---
name: optimize-terraform
description: Review and safely simplify Terraform infrastructure code
---

# Optimize Terraform

Target: use the user's chat input and selected files; if none is specified, use relevant workspace context.

## Task
Inspect providers, versions, state implications, modules, variables, outputs, dependencies, and resource addresses. Prefer behavior-preserving simplification. Run terraform fmt -check and terraform validate when initialized and feasible. Do not run apply, destroy, import, state changes, or automatic migration. Flag any change that could replace infrastructure.

## Operating rules
- Inspect relevant workspace files and existing project instructions before proposing edits.
- Identify the root cause; avoid speculative or unrelated changes.
- Preserve existing behavior, interfaces, naming, and deployment intent unless a change is necessary and explained.
- Prefer the smallest maintainable correction. Avoid redundant guards, nested branches, broad exception handling, and unnecessary abstractions.
- Never print, commit, or expose secrets. Never execute destructive commands or apply infrastructure changes without explicit approval.
- Consult official documentation when tools are available; distinguish verified guidance from assumptions.
- Run available non-destructive validation. Report commands run, outcomes, and checks that could not be performed. Never claim a check passed unless executed.
- Finish with: Root cause; Files changed; Validation; Remaining risks.
