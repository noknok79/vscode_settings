---
description: "Fix an Azure DevOps pipeline error or failing build/test/smoke-test step from a supplied log, in 6 phases."
agent: devops-engineer
---

# Objective
Fix `{{pipelineFile}}` for this error or log:

{{errorOrLog}}

# Constraints
- Do not touch any other file unless the root cause is outside the pipeline; disclose and justify any such edit.
- Keep the pipeline filename `{{pipelineFile}}` unchanged.
- A working pipeline, if supplied, is a reference only. Do not copy it.
- Preserve triggers, stages, jobs, dependencies, variables, approvals, and service connections.
- Do not queue, deploy, commit, or push.
- Verify behavior against Microsoft Learn; mark anything not verified.

# Process (6 phases, trillion sanity verify)
1. Understand the error. 2. Inspect the YAML, templates, and log. 3. Identify the root cause from evidence.
4. Apply the smallest fix. 5. Validate (YAML parse, `bash -n`, ShellCheck, and a mock failure simulation where feasible).
6. Review security and remaining risks.

# Output
Root cause; Files changed; Validation (only what actually ran); Remaining risks.
