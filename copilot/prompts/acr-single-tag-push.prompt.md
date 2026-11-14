---
description: "Stop an Azure pipeline from pushing extra tags (e.g. commit SHA) to ACR; push one vN tag only."
agent: devops-engineer
---

# Objective
In `{{pipelineFile}}`, make the ACR push create exactly one tag, `vN`, for `{{acrName}}/{{repository}}`. Remove any additional tag (for example a commit-SHA tag, or `latest`).

# Constraints
- Only edit `{{pipelineFile}}`.
- Preserve version resolution, retention, and existing triggers, stages, and approvals.
- Do not queue, commit, or push.

# Process (6 phases, trillion sanity verify)
Understand, inspect the build/push steps, find where the extra tag is created, make the minimal fix, validate, review risks.

# Validation
YAML parse, `bash -n`, ShellCheck, and a mocked `docker`/`az` run proving only one tag is pushed. Never claim an unrun check passed.

# Output
Root cause; Files changed; Validation; Remaining risks. Mention anything that may still pull the removed tag.
