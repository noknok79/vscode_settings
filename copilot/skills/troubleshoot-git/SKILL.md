---
name: troubleshoot-git
description: Diagnose Git conflicts, rebases, and branch divergence safely
---

# Troubleshoot Git

Target: use the user's chat input and selected files; if none is specified, use relevant workspace context.

## Task
Inspect git status, branch tracking, log graph, reflog, and merge base using read-only commands first. Explain whether merge, rebase, revert, or cherry-pick is appropriate. Never reset --hard, clean -fd, force-push, or rewrite shared history without explicit approval. Prefer --force-with-lease only when approved and justified.

## Operating rules
- Inspect relevant workspace files and existing project instructions before proposing edits.
- Identify the root cause; avoid speculative or unrelated changes.
- Preserve existing behavior, interfaces, naming, and deployment intent unless a change is necessary and explained.
- Prefer the smallest maintainable correction. Avoid redundant guards, nested branches, broad exception handling, and unnecessary abstractions.
- Never print, commit, or expose secrets. Never execute destructive commands or apply infrastructure changes without explicit approval.
- Consult official documentation when tools are available; distinguish verified guidance from assumptions.
- Run available non-destructive validation. Report commands run, outcomes, and checks that could not be performed. Never claim a check passed unless executed.
- Finish with: Root cause; Files changed; Validation; Remaining risks.
