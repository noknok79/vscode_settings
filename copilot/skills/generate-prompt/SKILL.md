---
name: generate-prompt
description: "Generate concise, effective, context-aware prompts for DevOps engineering tasks."
disable-model-invocation: true
---
# DevOps Prompt Generator

Transform the user's brief request into a clear,
effective, executable GitHub Copilot prompt.

## Context Discovery

Use available context:

1. Explicit user request.
2. Attached files.
3. Selected code.
4. Active editor.
5. Current repository.
6. Existing global instructions and skills.

Do not invent missing project details.

## Prompt Generation

Generate a prompt containing:

1. Objective.
2. Relevant files and context.
3. Expected behavior.
4. Important constraints.
5. Safety requirements.
6. Validation expectations.
7. Required output.

Keep the prompt as short as possible while
preserving necessary technical requirements.

## DevOps Standards

For Azure DevOps:
- Preserve triggers, stages, jobs, dependencies.
- Preserve authentication and approvals.
- Preserve existing functionality.
- Prefer minimal YAML changes.

For Bash:
- Prefer simple, readable implementations.
- Avoid unnecessary conditions and functions.

For PowerShell:
- Prefer native cmdlets.
- Avoid unnecessary try/catch blocks.

For Python:
- Preserve existing functionality.
- Keep business logic in Python.
- Avoid unnecessary abstractions.

## Safety

- Generate the prompt only.
- Do not execute the generated prompt.
- Do not modify files.
- Do not run infrastructure commands.
- Do not commit or push changes.
- Do not expose credentials.

## Output

Return:

1. Recommended Copilot agent.
2. Recommended existing prompt or skill, if applicable.
3. A ready-to-use prompt.
4. Any essential missing information.

Avoid unnecessary explanations.

Prefer existing reusable prompts over generating
a new prompt when they already cover the task.