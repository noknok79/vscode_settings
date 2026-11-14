---
description: "Recommend tools to install on the build agent pool to guarantee a quality Docker image before ACR push."
agent: code-reviewer
---

# Objective
Besides the Python smoke test, which tools should be installed on agent pool `{{agentPool}}` to test Docker images for `{{pipelineFile}}` and its Dockerfile?

# Constraints
- Read-only review.
- Rank as Must-have, Should-have, Optional. For each: purpose, where it plugs into the pipeline, and why it matters.
- Cover image scanning, Dockerfile lint, dependency audit, secret scanning, SBOM, signing, and structure tests.
- Base on industry standard and official docs actually fetched; mark unverified claims.
- Include concrete Dockerfile and requirements findings.

# Process
6 phases, trillion sanity verify.

# Output
Ranked table, Dockerfile findings, install and wiring order, and risks.
