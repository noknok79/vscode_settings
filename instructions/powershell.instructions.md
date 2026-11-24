---
description: Keep PowerShell scripts simple, readable, secure, and behavior-preserving.
applyTo: "**/*.ps1,**/*.psm1,**/*.psd1"
---

# PowerShell Development and Refactoring Instructions

These instructions apply when creating, modifying, reviewing,
or refactoring PowerShell scripts.

## Core Principles

- Prefer the simplest correct implementation.
- Keep scripts concise, readable, and maintainable.
- Do not add functionality unless requested.
- Avoid unnecessary defensive programming.
- Prefer native PowerShell cmdlets.
- Avoid unnecessary abstractions and wrapper functions.
- Preserve existing behavior and external interfaces.

## Simplification

- Reduce unnecessary if/else nesting.
- Prefer early returns when they improve clarity.
- Remove redundant conditions.
- Remove duplicated logic.
- Avoid unnecessary loops.
- Avoid unnecessary temporary variables.
- Avoid excessive pipeline chaining.
- Do not sacrifice readability to reduce line count.

## Error Handling

- Use try/catch only when recovery, cleanup, or additional
  error context is genuinely required.
- Avoid wrapping every command in try/catch.
- Preserve meaningful error behavior.
- Use -ErrorAction Stop when terminating errors are required.
- Check $LASTEXITCODE when external command results matter.
- Never silently suppress meaningful failures.
- Do not add retries without a technical reason.

## PowerShell Style

- Use clear Verb-Noun function names.
- Prefer approved PowerShell verbs.
- Use descriptive variable names.
- Prefer objects over parsing formatted text.
- Use splatting when commands have many parameters.
- Avoid unnecessary aliases in scripts.
- Keep functions focused on one responsibility.

## Comments

- Explain why, not obvious command behavior.
- Preserve security and business-rule explanations.
- Remove excessive AI-generated comments.
- Avoid large comment blocks without maintenance value.

## Azure DevOps

- Preserve service connections and authentication.
- Preserve environment approvals.
- Preserve pipeline triggers and conditions.
- Preserve output-variable contracts.
- Keep straightforward commands inline.
- Extract complex logic only when doing so improves clarity.
- Never remove required security controls.

## Behavior Preservation

Unless explicitly requested:

- Do not rename externally consumed variables.
- Do not change parameters.
- Do not change output formats.
- Do not change exit-code behavior.
- Do not change file paths.
- Do not change deployment behavior.
- Do not introduce new dependencies.

## Validation

- Verify PowerShell syntax.
- Use PSScriptAnalyzer when available.
- Use Invoke-Formatter when available.
- Review the final diff.
- Verify behavior against the original implementation.
- Never claim validation passed unless it was executed.

## Final Review

Before completing a PowerShell change, verify:

1. Is the implementation easy to understand?
2. Are all conditions necessary?
3. Can nested logic be reduced?
4. Is error handling appropriate?
5. Are functions genuinely useful?
6. Are comments concise?
7. Is behavior preserved?
8. Were appropriate checks executed?

Prefer straightforward PowerShell over elaborate defensive code.
