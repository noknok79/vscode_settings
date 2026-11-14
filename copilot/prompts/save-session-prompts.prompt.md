---
description: "Save the prompts used in a session as reusable user-level prompt files with an index."
agent: Copilot Configuration Maintainer Agent
---

# Objective
Save the prompts used in this session as reusable files in `~/.copilot/prompts/`.

# Steps
1. Group the session's user messages by purpose and merge near-duplicates.
2. List the purposes and wait for confirmation.
3. Create `<kebab-name>.prompt.md` per confirmed purpose, with frontmatter (`description`, `agent`) and Objective, Constraints, Validation, and Output sections.
4. Replace environment-specific values with placeholders such as `{{pipelineFile}}`, `{{acrName}}`, `{{repository}}`, `{{containerApp}}`, `{{resourceGroup}}`.
5. Add or update `~/.copilot/prompts/README.md`, one line per prompt.

# Constraints
- User-level location only; no repository-level Copilot files.
- Do not overwrite an existing file; show a diff and ask.
- No secrets, tokens, subscription IDs, or service connection names.
- Do not modify product code or commit.

# Output
A table of files created or updated, plus anything skipped and why.
