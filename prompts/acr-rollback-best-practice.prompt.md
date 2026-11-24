---
description: "Add industry-standard rollback safeguards to the ACR build/push pipeline."
agent: devops-engineer
---

# Objective
In `{{pipelineFile}}`, implement rollback best practice for pushing images to `{{acrName}}/{{repository}}`:
1. Build, run pytest, and smoke-test the container before the push.
2. Lock the tag after the push (`az acr repository update --write-enabled false`) and export the pushed tag and digest.
3. Make retention digest-aware: keep v1, the newest N versions, and any digest an active or inactive revision of `{{containerApp}}` in `{{resourceGroup}}` uses. Unlock before delete; delete by digest.
4. Roll back at the Container App by digest; no rebuild.

# Constraints
- Focus on the Azure pipeline only; do not touch unrelated files.
- Preserve triggers, environment, approvals, and authentication.
- Cite Microsoft Learn pages actually fetched (tag and version images, delete images, lock images) and other sources if found. Mark unverified items.
- Do not queue, commit, or push.

# Process (6 phases, trillion sanity verify)
Understand, inspect, root cause or gap, minimal change, validate, review risks.

# Validation
YAML parse, `bash -n`, ShellCheck, mocked `az` retention simulation.

# Output
Root cause or gap; Files changed; Validation; Remaining risks.
