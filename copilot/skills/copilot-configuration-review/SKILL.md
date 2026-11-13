---
name: copilot-configuration-review
description: "Audit and safely refresh workspace Copilot customizations from repository and session evidence. Use when: review Copilot config, update agents, fix prompt discovery, validate hooks, or self-enhance configuration."
disable-model-invocation: true
argument-hint: "Optional scope or evidence to review"
---
Review the requested GitHub Copilot customization scope and apply bounded improvements when evidence is sufficient.

Requirements:

1. Inspect `.github/copilot-instructions.md`, agents, prompts, instructions, skills, hooks, and their README or registry entries as applicable.
2. Compare configuration claims with current repository implementation and supplied session evidence.
3. Modify only the configuration allowlist defined by the selected agent.
4. Preserve governance and security controls; proposal-only for ambiguous or policy-sensitive changes.
5. Validate JSON, YAML frontmatter, discovery descriptions, links, referenced paths, and the final diff.
6. Return exact changed files, validation results, rejected proposals, and residual risks.