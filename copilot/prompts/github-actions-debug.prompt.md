---
name: github-actions-debug
description: Investigate GitHub Actions failures using MCP.
agent: agent
---

# GitHub Actions Troubleshooting

Investigate the GitHub repository and workflow specified by the user.

## Workflow

1. Identify the repository.
2. Use actions_list to locate relevant workflow runs.
3. Use get_job_logs to retrieve failure details.
4. Use get_file_contents to inspect workflow YAML.
5. Use get_commit to identify relevant changes.
6. Determine the likely root cause.
7. Recommend corrective actions.

## Rules

- Use GitHub MCP tools only when available and authorized.
- Do not modify files.
- Do not rerun workflows automatically.
- Do not expose credentials.
- Report unavailable evidence.

## Output

Provide:

1. Repository and workflow
2. Failed job
3. Relevant error messages
4. Root-cause assessment
5. Recommended fix
6. Validation steps