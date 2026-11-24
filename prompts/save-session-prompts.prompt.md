---
description: "Review and save approved reusable prompts from the current Copilot CLI session."
agent: Copilot Configuration Maintainer Agent
---

# Objective
Curate genuinely reusable prompts from user messages visible in the current session, then save approved prompts in `~/.copilot/prompts/`.

# Workflow
1. Inspect only user prompts visible in the current session. Group related prompts and merge near-duplicates; never claim access to other sessions.
2. Exclude one-time troubleshooting instructions and project-specific configuration. Remove credentials, tokens, and authentication state; replace reusable environment-specific values with placeholders such as `{{repository}}` or `{{resourceGroup}}`.
3. Compare candidates with existing global prompts and the README index. Prefer proposing an improvement to an existing prompt over a duplicate.
4. Propose each candidate's purpose, overlaps, filename, global or workspace placement, and files to change. Default cross-project prompts to global. Stop and wait for approval before writing any files.
5. After approval, create `<kebab-name>.prompt.md` files or update only approved prompts. Use frontmatter (`description`, `agent`) and the sections Objective, Constraints, Validation, and Output. For an existing file, show the proposed diff and obtain approval before changing it.
6. Add or update `~/.copilot/prompts/README.md`, one line per global prompt.

# Constraints
- Save prompts globally by default. Treat workspace placement as proposal-only; make workspace changes only after explicit approval.
- Never silently replace an existing file; show a diff and obtain approval.
- Do not save credentials, tokens, subscription IDs, service connection names, or authentication state.
- Do not modify product code, agents, skills, hooks, or MCP configuration. Do not commit or push.

# Output
Before approval, report candidates, overlaps, proposed filenames and placement, and files that would change; then stop. After approved changes, report files changed, skipped candidates and why, and validation results.
