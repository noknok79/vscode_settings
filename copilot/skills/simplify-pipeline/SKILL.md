---
name: simplify-pipeline
description: "Simplify Bash, PowerShell, and Azure DevOps pipelines while preserving behavior."
disable-model-invocation: true
---
# Simplify Pipeline

Refactor the selected Bash, PowerShell, or Azure DevOps pipeline.

Follow existing global instructions:

- bash.instructions.md
- powershell.instructions.md
- azure-pipelines.instructions.md
- devops-global.instructions.md

## Objectives

1. Reduce unnecessary complexity.
2. Improve readability.
3. Reduce redundant conditional logic.
4. Remove excessive comments.
5. Preserve existing behavior.
6. Keep simple commands inline.
7. Extract complex logic only when beneficial.

## Existing Pipeline Refactoring

When an Azure DevOps pipeline already exists:

1. Treat the existing pipeline as the primary implementation.
2. Use original Bash, PowerShell, or Python scripts as behavioral references.
3. Prefer improving the existing pipeline over rebuilding it.
4. Preserve working stages, jobs, tasks, and dependencies.
5. Preserve triggers, variables, parameters, and output contracts.
6. Preserve service connections, authentication, and approvals.
7. Remove redundant conditions, unnecessary wrappers, and verbose comments.
8. Keep simple commands inline.
9. Extract complex inline logic only when it improves maintainability.
10. Preserve existing exit codes and failure behavior.
11. Do not introduce new dependencies without justification.
12. Never remove necessary security or retention safeguards.
13. Compare original and refactored behavior using appropriate tests.
14. Present proposed changes before modifying files.

## Automatic Target Selection

Determine the target using this priority:

1. Explicitly supplied file or directory.
2. Selected or attached file.
3. Active editor file.
4. Unambiguous pipeline in the current workspace.

If multiple pipelines are plausible, ask which one to use.

Do not require the user to repeat the requirements
already defined in this prompt.

## Refactoring Decision

- Existing working pipeline: simplify it.
- Existing broken pipeline: identify and fix the root cause first.
- Python/Bash/PowerShell script without a pipeline:
  propose a new Azure DevOps pipeline.
- Existing pipeline with complex inline scripts:
  consider extracting the complex logic.
- Simple inline commands: leave them inline.

Do not rebuild a working pipeline solely to reduce its line count.

## Six-Phase Refactoring Workflow

Automatically follow this workflow for Bash, PowerShell,
Python, and Azure DevOps pipeline refactoring.

### Phase 1 - Audit

- Inspect the existing implementation and related dependencies.
- Identify repository, branch, and Git status.
- Record original hashes, inputs, outputs, and exit codes.
- Identify existing tests and security controls.
- Preserve unrelated modifications.

### Phase 2 - Propose

- Recommend minimal, behavior-preserving improvements.
- Explain affected files, risks, and expected benefits.
- Prefer improving existing pipelines over rebuilding.
- Recommend the best evidence-supported approach.
- Avoid unnecessary technical clarification questions.

STOP after Phase 2.
Do not modify files until explicitly approved.

### Phase 3 - Implement

After approval:

- Modify only approved files.
- Preserve stages, jobs, tasks, triggers, and dependencies.
- Preserve variables, parameters, authentication,
  approvals, output contracts, and failure behavior.
- Avoid unnecessary abstractions and dependencies.

### Phase 4 - Validate

- Bash: bash -n, ShellCheck, shfmt when available.
- PowerShell: parser, PSScriptAnalyzer, Pester when available.
- Python: syntax, tests, configured linters.
- Azure DevOps: YAML, tasks, paths, variables,
  expressions, authentication, and approvals.
- Run applicable security validation.

### Phase 5 - Compare

- Compare original and refactored behavior.
- Verify inputs, outputs, exit codes, and failure handling.
- Verify generated commands and external dependencies.
- Use mocks when appropriate.
- Stop if unexpected behavior changes.

### Phase 6 - Report

Provide:

- Original and updated complexity.
- Exact files changed.
- Git diff --stat and --numstat.
- Validation and regression results.
- Remaining risks and recommended next actions.

## Safety

Never automatically:

- Push Git changes.
- Commit Git changes.
- Deploy infrastructure.
- Run terraform apply or destroy.
- Delete ACR images.
- Push Docker images.
- Bypass approvals.
- Modify unrelated files.
- Expose secrets.

Do not modify source files until the user explicitly approves the proposed changes.

Do not claim equivalence unless supported by tests.

## Output

Provide:

1. Original complexity.
2. Refactored complexity.
3. Files changed.
4. Validation results.
5. Regression results.
6. Remaining risks.
7. Final recommendation.
