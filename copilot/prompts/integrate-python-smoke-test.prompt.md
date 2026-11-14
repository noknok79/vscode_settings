---
description: "Integrate an attached Python image-validation (smoke test) script into the Azure DevOps pipeline."
agent: devops-engineer
---

# Objective
Integrate the attached Python smoke-test script `{{scriptPath}}` into `{{pipelineFile}}` so it gates the image before any push.

# Constraints
- Place the script where the repository convention suggests and say why; prefer the recommended option over asking.
- Keep business logic in Python; the pipeline only builds the config, runs the script, and publishes results.
- Make the minimal script edits needed (for example, use the locally built image, pass env vars) and disclose them.
- Run in both the PR validation job and the push job; publish JUnit results with `succeededOrFailed()`.
- Do not queue, commit, or push.

# Process (6 phases, trillion sanity verify)

# Validation
YAML parse, `bash -n`, ShellCheck, `py_compile`, and a mock-docker simulation of pass, probe failure, and container exit.

# Output
Root cause or gap; Files changed; Validation; Remaining risks; unverified agent prerequisites (docker, scanner).
