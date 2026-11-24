---
description: "Check which GitHub account and Copilot login are active in gh CLI and VS Code."
agent: devops-engineer
---

# Objective
Report which GitHub account is logged in for GitHub Copilot, via the `gh` CLI and VS Code.

# Constraints
- Read-only. Do not log in, log out, or change any account or setting.
- Never print tokens; use `gh auth status` without `--show-token`.
- Do not modify files, commit, or push.

# Steps
1. Run `gh auth status` and report host, account, active account, and token scopes.
2. Check the VS Code GitHub and Copilot sign-in where tools allow; otherwise say it could not be verified.
3. Compare the accounts and flag any mismatch.

# Validation
Report only commands actually run and their results. Mark anything unverifiable as Not Verified.

# Output
Table: Source | Account | Host | Status. Then mismatches and the next action, if any.
