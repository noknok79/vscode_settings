---
description: "Check whether an Azure DevOps Run pipeline form or parameter menu matches the YAML."
agent: code-reviewer
---

# Objective
Verify that the attached Run pipeline screenshot or form matches the parameters declared in `{{pipelineFile}}`.

# Constraints
- Read-only; do not edit files.
- Compare each displayed field, label, default, and Required marker with the YAML `parameters:` block.
- Note branch selection, approvals, and environment checks that affect the run; mark unverified items.

# Output
Verdict (correct or not), a match table, things to check on the form, and fixes if any.
