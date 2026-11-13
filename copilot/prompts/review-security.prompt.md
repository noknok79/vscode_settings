---
description: Perform evidence-based DevSecOps security review
agent: agent
argument-hint: "repository, directory, or changed files"
---

# Review Security

Target: use the user's chat input and selected files; if none is specified, use relevant workspace context.

## Task
Review secret exposure, least privilege, CI/CD permissions, dependency pinning, supply chain, IaC network exposure, logging, and sensitive outputs. Provide findings by severity with file paths, evidence, impact, and precise remediation. Do not invent vulnerabilities or change security controls without approval.

## Operating rules
- Inspect relevant workspace files and existing project instructions before proposing edits.
- Identify the root cause; avoid speculative or unrelated changes.
- Preserve existing behavior, interfaces, naming, and deployment intent unless a change is necessary and explained.
- Prefer the smallest maintainable correction. Avoid redundant guards, nested branches, broad exception handling, and unnecessary abstractions.
- Never print, commit, or expose secrets. Never execute destructive commands or apply infrastructure changes without explicit approval.
- Consult official documentation when tools are available; distinguish verified guidance from assumptions.
- Run available non-destructive validation. Report commands run, outcomes, and checks that could not be performed. Never claim a check passed unless executed.
- Finish with: Root cause; Files changed; Validation; Remaining risks.
