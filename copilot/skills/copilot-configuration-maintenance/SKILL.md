---
name: copilot-configuration-maintenance
description: "Safely review and improve workspace GitHub Copilot agents, prompts, instructions, skills, hooks, and registries using repository or session evidence. Use when: update Copilot configuration, self-enhance agent config, fix frontmatter, repair discovery descriptions, validate customization links, or identify stale agent guidance."
user-invocable: true
---

# Copilot Configuration Maintenance

Use this workflow for evidence-based maintenance of repository Copilot customizations.

## Evidence Collection

1. Inventory `.github/copilot-instructions.md`, `.github/agents/`, `.github/prompts/`, `.github/instructions/`, `.github/skills/`, and `.github/hooks/`.
2. Read the nearest README or registry and verify every listed path.
3. Check implementation claims against current source, project files, tests, and verified commands.
4. Treat session history as supporting evidence, not as policy authority.

## Decision Gate

Classify every candidate change:

- `apply`: directly supported, configuration-only, bounded, and does not weaken controls.
- `propose`: useful but ambiguous, policy-sensitive, cross-repository, or autonomy-expanding.
- `reject`: changes product code, weakens security/governance, accesses secrets, enables deployment, or creates recursive self-modification.

## Validation

- Parse every changed JSON file.
- Verify each Markdown customization has valid YAML frontmatter where required.
- Require quoted, trigger-rich `description` values for discoverable agents, prompts, instructions, and skills.
- Verify relative Markdown links and referenced local paths exist.
- Inspect `git diff` and `git status` to preserve unrelated changes.
- Report checks that could not be run; do not substitute assertions for validation.

## Safety Boundary

Only change Copilot customization files and their hook scripts. Never modify application, test, infrastructure, requirement, or CI/CD files through this workflow.