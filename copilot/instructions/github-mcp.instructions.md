---
description: GitHub MCP integration guidelines for DevOps workflows.
applyTo: "**"
---

# GitHub MCP Integration

## Tool Usage

When GitHub MCP tools are available and authorized:

- Use search_repositories to discover repositories.
- Use search_code to locate implementation details.
- Use search_issues to investigate bugs and incidents.
- Use list_pull_requests to inspect active PRs.
- Use list_issues to retrieve issue information.
- Use get_file_contents to inspect remote files.
- Use get_commit to investigate commit changes.
- Use list_branches to inspect branch availability.
- Use get_job_logs to investigate failed workflows.
- Use actions_list for supported GitHub Actions operations.

## Execution Rules

1. Prefer read-only operations during investigation.
2. Never modify repositories without explicit authorization.
3. Never expose authentication tokens or credentials.
4. Verify repository ownership before accessing resources.
5. Do not assume MCP authentication matches the Copilot account.
6. Do not bypass organization-level MCP restrictions.
7. Report when an MCP tool is unavailable.
8. Never fabricate MCP results.
9. Distinguish remote repository data from local workspace data.
10. Prefer local files for uncommitted changes.

## Output Requirements

For GitHub investigations, report:

- Repository
- Branch or commit
- Relevant files
- Findings
- Evidence
- Recommended actions

## Fallback

If MCP is unavailable:

- Use authorized local repository tools.
- Clearly explain which remote checks could not be performed.