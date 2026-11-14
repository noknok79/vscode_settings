---
description: "Automate selecting an existing ACR image version in a rollback pipeline instead of typing a tag."
agent: devops-engineer
---

# Objective
In `{{rollbackPipelineFile}}`, automate choosing the existing image version from `{{acrName}}/{{repository}}` so the user does not type a tag.

# Constraints
- Azure Pipelines parameters cannot be populated dynamically; resolve at run time inside the job.
- Default `targetTag` to `previous`: the newest `vN` older than the serving image with a different digest. Still allow an explicit `vN`.
- Log the retained versions and digests every run.
- Only edit `{{rollbackPipelineFile}}`; preserve the existing rollback flow and approvals.
- Do not queue, commit, or push.

# Process (6 phases, trillion sanity verify)

# Validation
YAML parse, `bash -n`, ShellCheck, and a `jq` selection test with sample tags for digest and tag references.

# Output
Root cause or gap; Files changed; Validation; Unverified (RBAC for `show-tags`, output format).
