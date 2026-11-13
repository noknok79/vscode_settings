---
name: python-to-azure-pipeline
description: "Refactor Python scripts into simple, secure, maintainable Azure DevOps pipelines while preserving existing behavior."
disable-model-invocation: true
---
# Python to Azure DevOps Pipeline

Convert or refactor the selected Python workflow into an
Azure DevOps YAML pipeline.

Follow the existing global DevOps and Azure Pipelines instructions.

## Objectives

1. Preserve existing Python functionality.
2. Generate minimal, readable Azure DevOps YAML.
3. Avoid unnecessary stages, jobs, tasks, and conditions.
4. Keep complex Python logic in version-controlled .py files.
5. Use the pipeline to orchestrate Python execution.
6. Preserve existing authentication and security controls.
7. Avoid unnecessary defensive programming.
8. Prefer native Azure DevOps tasks and Python commands.

## Automatic Target Selection

Determine the target using this priority:

1. Explicitly supplied file or directory.
2. Current editor selection or attached file.
3. Active Python file and its related project directory.
4. Current workspace, when the relevant Python project is unambiguous.

Do not assume an unrelated Python directory is the target.

If multiple plausible projects exist, present the candidates
and ask which one to use.

Do not require the user to repeat the requirements in this prompt.

Default behavior:

- Inspect the selected workflow.
- Identify the Python entry point and dependencies.
- Identify existing Azure DevOps pipeline conventions.
- Propose the simplest behavior-preserving implementation.
- Explain important security and approval requirements.
- Do not modify files until explicitly approved.

## Phase 1: Inspect

- Read the selected Python script and relevant dependencies.
- Identify the repository and current branch.
- Inspect Git status.
- Identify script arguments and environment variables.
- Identify Python version requirements.
- Identify requirements.txt or pyproject.toml.
- Identify input files and generated outputs.
- Identify external services and authentication requirements.
- Identify existing tests and pipeline conventions.

## Phase 2: Design

Choose the simplest supported Azure DevOps pipeline structure.

Prefer:

- One stage when sufficient.
- One job when sufficient.
- Minimal task configuration.
- Existing agent pools.
- Existing service connections.
- Existing repository conventions.
- Reusable templates only when genuinely beneficial.

Do not introduce unnecessary abstractions.

## Phase 3: Python Integration

- Keep Python business logic in .py files.
- Do not rewrite working Python unnecessarily.
- Use python or python3 consistently with the agent environment.
- Install dependencies only when required.
- Prefer dependency lock files when available.
- Preserve command-line arguments.
- Preserve environment variables.
- Preserve meaningful exit codes.
- Preserve generated artifacts and output paths.

## Phase 4: Azure DevOps

- Use documented Azure Pipelines YAML syntax.
- Preserve existing triggers and branch conditions.
- Preserve service connections and authentication.
- Preserve environment approvals.
- Preserve output variables and artifact contracts.
- Verify checkout and working directories.
- Avoid hard-coded secrets.
- Avoid unnecessary retry and error-handling logic.

When Azure authentication is required, prefer existing
service connections rather than embedded credentials.

## Phase 5: Simplification

- Remove redundant YAML.
- Avoid unnecessary nested conditions.
- Avoid verbose comments.
- Avoid unnecessary wrapper scripts.
- Keep straightforward Python execution inline.
- Extract complex logic only when it improves readability.
- Prefer clarity over minimum line count.

## Phase 6: Validation

Validate the affected components.

Python:
- Compile or parse Python syntax.
- Use existing project tests.
- Use Ruff or other configured linters when available.
- Verify dependencies and entry points.

Azure DevOps:
- Validate YAML syntax.
- Verify task inputs against official documentation.
- Verify paths and working directories.
- Verify variables and expressions.
- Verify service connections and approvals.

## Phase 7: Behavior Comparison

Compare the original workflow with the proposed pipeline.

Verify:

- Inputs
- Outputs
- Exit codes
- Dependencies
- Authentication
- Artifacts
- Environment variables
- Failure behavior

Use mocks for external services when appropriate.

Do not claim behavioral equivalence without evidence.

## Phase 8: Review

Present:

1. Original workflow summary.
2. Proposed pipeline structure.
3. Python files retained or modified.
4. YAML files created or modified.
5. Simplifications made.
6. Validation results.
7. Remaining risks.
8. Git diff summary.

## Safety

Never automatically:

- Commit or push Git changes.
- Deploy infrastructure.
- Run destructive Azure commands.
- Execute terraform apply or destroy.
- Delete ACR images.
- Push Docker images.
- Bypass environment approvals.
- Expose credentials.
- Modify unrelated files.

First inspect the workflow and propose the changes.

Do not modify source files until the user explicitly
approves the proposed changes.

After approval, perform the implementation and
non-destructive verification.

Stop when behavior differs unexpectedly.

## Final Rule

Prefer the simplest correct Azure DevOps pipeline
that executes the existing Python workflow.

Do not replace understandable Python code with
complicated YAML or inline scripts.
