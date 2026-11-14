---
description: "Create a manual Azure pipeline that rolls the Container App back to a retained ACR image version."
agent: devops-engineer
---

# Objective
Create `{{rollbackPipelineFile}}`, a manual pipeline that rolls `{{containerApp}}` (resource group `{{resourceGroup}}`) back to a retained version of `{{acrName}}/{{repository}}`, following the existing `{{pipelineFile}}` pattern.

# Behavior
1. Parameter `targetTag` (vN, or `previous` to auto-select the newest older retained version).
2. Resolve the tag to its digest; fail before touching the app if it is gone.
3. Read the serving revision from the traffic table (not latestReady); skip if already running.
4. Save the traffic table; pin traffic; deploy the digest as a new revision with a unique suffix.
5. Wait for Provisioned/Running/Healthy; probe `/health` at the revision address; then shift traffic.
6. On failure restore saved traffic and deactivate the new revision without masking the original error.

# Constraints
- Never rebuild, push, or delete images. Reuse the existing environment, service connection, and pool.
- `trigger: none`, manual only, `lockBehavior: sequential`.
- Do not queue, deploy, commit, or push.

# Process (6 phases, trillion sanity verify)

# Validation
YAML parse, `bash -n`, ShellCheck, mocked `az` simulation of success, failure, already-running, and missing-tag cases.

# Output
Root cause or gap; Files changed; Validation; Unverified (RBAC, revision mode, ingress reach); Next action.
