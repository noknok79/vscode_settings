# Investigation checklists

## GitHub Actions failure
- Confirm owner/repo, run ID, job ID, workflow path, branch, SHA, trigger, and timestamp.
- Use an available Actions listing tool to identify the run and job; use `get_job_logs` for errors.
- Retrieve workflow YAML at the run's SHA, not only the current default branch.
- Check dependencies, secrets references (never values), environment names, permissions, runner selection, artifact availability, and conditional stage routing.
- Report the exact failing step and a safe reproduction or validation plan.

## Pull request or security review
- Confirm base/head SHA, changed files, PR status, and scope.
- Inspect changes with available PR tools; supplement with `get_file_contents` at relevant refs.
- Examine authentication/authorization, secret handling, injection, dependency changes, CI permissions, and tests.
- Cite file/line or commit references; do not invent line numbers.
- Distinguish actionable defects from speculative concerns.

## Infrastructure-as-code review
- Search Terraform, Bicep, Kubernetes, and GitHub Actions configuration relevant to the request.
- Confirm branch and environment mappings and any policy-as-code references.
- Repository files are desired-state evidence, not proof of deployed state. Do not assert drift without actual state/plan/resource evidence.
- Never apply, destroy, deploy, or mutate infrastructure during read-only investigation.

## Identity and policy
- A successful `search_repositories` for public `user:noknok79` repositories confirms a tool call, not identity.
- If identity tools are missing, explicitly mark authentication identity unverified.
- Do not use personal MCP to bypass restrictions imposed on corporate Copilot sessions.
