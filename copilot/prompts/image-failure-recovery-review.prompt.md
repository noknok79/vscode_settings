---
description: "Review and simulate what happens on smoke-test failure or a distrusted pushed image, and how to automate recovery."
agent: code-reviewer
---

# Objective
For `{{pipelineFile}}`, explain with a concrete simulation (start with ACR latest = v{{N}}):
1. A smoke-test failure: does the pipeline fail, what reaches ACR, which version does the rerun push?
2. A smoke test that passes but the image is distrusted afterwards: what recovery applies and what do you recommend?
3. How to automate that recovery: deploy the digest at 0% traffic, check `/health` on the new revision, shift traffic, otherwise roll back; retention afterwards.

# Constraints
- Read-only review; do not edit files.
- Base the answer on the actual YAML and on Microsoft Learn, GitHub, and StackOverflow practice. Cite only sources actually fetched; mark the rest unverified.
- List prerequisites (revision mode, RBAC, probes, agent network reach) and what is unverified.

# Process
6 phases, trillion sanity verify.

# Output
Step-by-step scenario table, recommendation, automation design, and risks.
