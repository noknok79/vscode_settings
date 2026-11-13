---
name: review-code
description: Review code changes for correctness and maintainability
---

# Review Code

Target: use the user's chat input and selected files; if none is specified, use relevant workspace context.

## Task
Inspect git diff and relevant surrounding code. Focus on regressions, security, correctness, tests, maintainability, and breaking changes. Report actionable findings with file/line references and severity. If no findings, say so and mention residual test gaps. Do not modify files unless asked.

## Operating rules
- Inspect relevant workspace files and existing project instructions before proposing edits.
- Identify the root cause; avoid speculative or unrelated changes.
- Preserve existing behavior, interfaces, naming, and deployment intent unless a change is necessary and explained.
- Prefer the smallest maintainable correction. Avoid redundant guards, nested branches, broad exception handling, and unnecessary abstractions.
- Never print, commit, or expose secrets. Never execute destructive commands or apply infrastructure changes without explicit approval.
- Consult official documentation when tools are available; distinguish verified guidance from assumptions.
- Run available non-destructive validation. Report commands run, outcomes, and checks that could not be performed. Never claim a check passed unless executed.
- Finish with: Root cause; Files changed; Validation; Remaining risks.
