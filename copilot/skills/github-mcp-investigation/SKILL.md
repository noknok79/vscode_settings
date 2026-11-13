---
name: github-mcp-investigation
description: investigate github repositories, pull requests, issues, commits, branches, code, and actions failures using available authorized github mcp tools. use for read-only remote github discovery, devops troubleshooting, security review, or evidence-based repository investigation when the user asks about github-hosted information.
---
# GitHub MCP Investigation

Investigate remote GitHub evidence using the available **authorized** MCP tools. Start read-only; do not alter repositories, PRs, issues, workflows, secrets, or settings unless the user explicitly requests an action and applicable policy permits it.

## Preconditions

1. Establish the repository owner/name and intended branch, PR, issue, workflow, or time range. If unspecified, discover candidates and label the scope used.
2. Inspect tools exposed in the **current session**. Do not assume the MCP server is named `github-personal` or that `get_me` exists. The previously observed server was `github-mcp-server`, with `search_repositories` working; names and capabilities may change.
3. Confirm the active session is authorized to use MCP. A server marked Running does not prove tool access or policy permission. Never use a personal identity to circumvent corporate MCP restrictions.
4. Distinguish the Copilot model account, MCP authenticated identity, and repository owner. Public repository search does **not** prove MCP authentication identity.
5. Prefer local workspace files for uncommitted changes. Remote MCP results reflect the selected remote revision, not necessarily the working tree.

## Investigation workflow

1. **Discover**: Use `search_repositories` to locate candidates; establish canonical owner/repo, visibility, default branch, and source URL when returned.
2. **Locate evidence**: Use `search_code` for matching paths or symbols; `get_file_contents` for specific files and branch/revision; `list_branches` for branch comparisons. Scope queries narrowly and avoid indiscriminate repository scans.
3. **Trace change**: Use `get_commit` for commit evidence; `list_pull_requests` and available PR-reading tools for review context; `search_issues` or `list_issues` for related reports. Do not treat issue speculation as verified root cause.
4. **Investigate CI**: Use available `actions_list` capabilities to locate workflow runs/jobs, `get_job_logs` to retrieve failure evidence, and `get_file_contents` to inspect the workflow YAML at the relevant revision. Correlate job, commit SHA, branch, run timestamp, and error text. Do not conflate GitHub Actions with Azure DevOps pipelines; GitHub MCP may not expose Azure DevOps runs.
5. **Cross-check**: Reconcile branch, SHA, environment, file version, and timing. Cite concrete remote URLs or file paths, line ranges when available, PR/issue/run identifiers, and commit hashes.
6. **Report**: Separate observed evidence, likely explanation, gaps, and recommendations. Clearly say which tools actually executed and whether any checks were unavailable.

## Tool-selection guide

- Repository discovery: `search_repositories`
- Source patterns and configuration: `search_code`, then `get_file_contents`
- Issue/incident research: `search_issues`, `list_issues`
- Pull-request triage: `list_pull_requests`, then available PR detail tools
- Revision investigation: `get_commit`, `list_branches`
- CI troubleshooting: `actions_list`, `get_job_logs`, `get_file_contents`

Tool names are indicative, not guaranteed. Discover the exact registered tool before invoking it; do not invent missing tools or their outputs. Read [references/investigation-checklists.md](references/investigation-checklists.md) for detailed task-specific checks when needed.

## Security and permissions

- Use least privilege and read-only retrieval by default. Do not trigger reruns, pushes, merges, comments, branch deletion, or settings changes without explicit request and permission.
- Do not output access tokens, authorization headers, private keys, secret values, or unredacted sensitive log content.
- Never claim authenticated identity based on a public repository query. Verify identity only through an available identity tool or an authorized account-management view.
- Respect repository access boundaries and enterprise MCP policies. If blocked, state the restriction and use permitted local evidence; do not suggest policy workarounds.
- Avoid automatically sending confidential enterprise code to a personal-account MCP server.

## Required response format

### Scope
- Repository, branch/commit, and investigation objective.

### Findings
- Severity or impact (where appropriate), evidence, and exact source reference.
- Distinguish **verified** facts from **hypotheses**.

### Tool execution
- List actual MCP tools invoked, their purpose, and any failed/unavailable tools.

### Recommendations
- Prioritized, actionable next steps and safe validation commands or tests.
- State that no changes were made unless an authorized action actually occurred.

## Example requests

- "Investigate why the GitHub Actions deployment failed in owner/repo on main; do not change anything."
- "Review open PRs touching Terraform or Bicep in owner/repo and identify deployment risks."
- "Trace a regression from commit SHA and related issues, with source links."
- "Compare the deployment workflow in two remote branches and flag environment-routing differences."
