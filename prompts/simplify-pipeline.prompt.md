---
description: Simplify Bash, PowerShell, and Azure DevOps pipelines while preserving behavior.
agent: devops-engineer
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
4. Preserve working stages, jobs, tasks, and dependencies; consolidate or remove redundant stages, jobs, or tasks only when their behavior and dependency relationships remain equivalent.
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

For Azure DevOps refactoring, prefer suitable built-in tasks, then Azure CLI
for Azure operations, then existing tested tools, and finally minimal Bash or
Python when justified. Preserve existing behavior and security controls.

## Six-Phase Refactoring Workflow

Apply this workflow to existing Bash, PowerShell,
Python, and Azure DevOps YAML.

### Phase 1 - Audit
- Identify the repository and current branch.
- Identify existing tests and external dependencies.

- Inspect relevant files and dependencies.
- Record Git status, SHA-256 hashes, and line counts.
- Identify interfaces, inputs, outputs, and exit codes.
- Identify existing security and deployment controls.
- Preserve unrelated changes.

### Phase 2 - Propose

- Recommend minimal, behavior-preserving simplifications.
- Prioritize readability over line count.
- Identify affected files and expected reductions.
- Explain risks and unverified behavior.

STOP after Phase 2.
Do not modify files until explicitly approved.

### Phase 3 - Implement
- Preserve triggers, conditions, environment variables,
  output contracts, authentication, and approval gates.
- Extract complex inline scripts only when beneficial.

After approval:
- Preserve a verified baseline.
- Modify only approved files.
- Preserve functionality, security, and external interfaces.
- Avoid unnecessary abstractions.

### Phase 4 - Validate

- Bash: bash -n, ShellCheck, shfmt when available.
- PowerShell: parser, PSScriptAnalyzer, Pester when available.
- Python: syntax, tests, configured linters.
- Azure DevOps: YAML, task configuration, paths,
  variables, expressions, and approvals.

### Phase 5 - Compare
- Preserve failure handling and generated commands.
- Never execute destructive infrastructure operations.

- Compare original and refactored behavior.
- Verify exit codes, inputs, outputs, and external commands.
- Use mocks when appropriate.
- Stop if unexpected behavior changes.

### Phase 6 - Report
- List exact files changed and explain simplifications.
- Identify unverified behavior and necessary follow-up checks.

Provide:
- Original and refactored line counts.
- Added, removed, and net line changes.
- Git diff --stat and --numstat.
- Validation and regression results.
- Remaining risks.

Never automatically commit, push, deploy, or execute
destructive infrastructure operations.

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
