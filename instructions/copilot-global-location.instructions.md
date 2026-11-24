---
description: Prefer user-level locations for reusable Copilot customizations.
applyTo: "**"
---

# Global Copilot Configuration Policy

When creating or updating reusable Copilot customizations:

- Prefer user-level configuration over repository-level configuration.
- Store reusable agents under ~/.copilot/agents/.
- Store reusable instructions under ~/.copilot/instructions/.
- Store reusable prompts under ~/.copilot/prompts/.
- Store reusable skills under ~/.copilot/skills/.
- Store Copilot CLI hooks under ~/.copilot/hooks/.
- Keep user-level MCP server configuration outside Git repositories.
- Do not create repository-level Copilot configuration files unless explicitly requested.
- Do not commit authentication tokens, credentials, or local Copilot configuration.
- Preserve existing repository configuration unless explicitly asked to migrate or remove it.
- Continue creating and modifying normal application source code in the active repository.
