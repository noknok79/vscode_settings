# Bash Development and Refactoring Instructions

These instructions apply whenever creating, modifying, fixing, reviewing, or refactoring Bash and shell scripts.

## Core Principles

- Prefer the simplest implementation that preserves existing behavior.
- Keep Bash scripts concise, readable, predictable, and maintainable.
- Do not add functionality unless explicitly requested.
- Do not over-engineer solutions.
- Do not expand a simple script into substantially more code without a clear technical requirement.
- When two implementations provide equivalent behavior, prefer the simpler and shorter implementation.
- Preserve the original intent and behavior of the script.

## Simplification and Refactoring

When refactoring existing Bash code:

- Remove redundant `if`, `else`, and `elif` blocks.
- Remove conditions that do not materially affect behavior.
- Reduce deeply nested conditional logic.
- Prefer early exits and fail-fast logic over nested branches.
- Remove unnecessary defensive checks when the underlying command already provides adequate failure handling.
- Remove duplicated logic.
- Consolidate repeated commands when doing so improves clarity.
- Remove unnecessary wrapper functions.
- Remove functions that provide no meaningful abstraction.
- Remove unnecessary temporary variables.
- Remove unnecessary subshells.
- Remove unnecessary command substitutions.
- Remove unnecessary pipelines.
- Remove unnecessary loops when a simpler shell construct provides equivalent behavior.
- Remove unreachable or dead code.
- Remove obsolete commented-out code.
- Remove excessive error-handling logic.
- Do not introduce try/catch-style error-handling patterns.
- Do not introduce elaborate fallback mechanisms unless explicitly required.
- Do not add retries unless explicitly requested or required by existing behavior.

## Bash Style

- Prefer standard Bash built-ins and common Unix utilities.
- Use Bash features when they make the implementation simpler and clearer.
- Quote variable expansions correctly.
- Use arrays where word splitting would otherwise be unsafe.
- Prefer `[[ ... ]]` for Bash conditional expressions when appropriate.
- Prefer arithmetic expressions such as `(( ... ))` for numeric operations.
- Avoid unnecessary uses of `cat`, `grep`, `awk`, `sed`, or other external processes when Bash can perform the operation clearly.
- Do not sacrifice readability merely to reduce line count.
- Do not use clever or obscure shell tricks when a straightforward implementation is easier to maintain.

## Error Handling

- Prefer simple fail-fast behavior.
- Preserve meaningful exit codes.
- Do not silently suppress meaningful errors.
- Do not append `|| true` merely to hide failures.
- Do not redirect errors to `/dev/null` unless suppression is intentional and necessary.
- Avoid unnecessary custom exception-style handling.
- Do not create complicated error-handler functions for simple commands.
- Do not add traps unless cleanup or signal handling genuinely requires them.
- Do not add `set -euo pipefail` blindly.
- If `set -euo pipefail` already exists, preserve it unless there is a concrete reason to change it.

## Comments

- Remove verbose comments that merely repeat what the command already says.
- Remove AI-generated explanatory comments that provide no maintenance value.
- Preserve comments explaining business rules, workarounds, unusual behavior, security requirements, or non-obvious decisions.
- Prefer short comments explaining why something exists rather than describing what an obvious command does.
- Do not add large explanatory comment blocks unless explicitly requested.

## Preserve Existing Behavior

Unless explicitly requested otherwise:

- Do not change command-line arguments.
- Do not rename environment variables.
- Do not rename externally consumed variables.
- Do not change expected input.
- Do not change output consumed by another process.
- Do not change exit-code behavior.
- Do not change file paths.
- Do not change deployment behavior.
- Do not change external interfaces.
- Do not change CI/CD behavior.
- Do not change authentication or security behavior.
- Do not add new dependencies.
- Do not replace existing tools merely because another tool is preferred.

## Refactoring Priority

Use this priority when making changes:

1. Preserve existing behavior.
2. Fix actual defects.
3. Remove unnecessary complexity.
4. Reduce conditional nesting.
5. Remove duplicated logic.
6. Remove unnecessary error handling.
7. Remove redundant code.
8. Improve readability.
9. Reduce unnecessary lines.
10. Validate the resulting script.

## Validation

Before considering a Bash modification complete, validate syntax with:

    bash -n <script>

When ShellCheck is available, also validate with:

    shellcheck <script>

Resolve relevant ShellCheck findings when the fix does not alter intended behavior.

Do not make unrelated changes solely to satisfy stylistic warnings.

After refactoring, verify that the script remains functionally equivalent to the original unless behavioral changes were explicitly requested.

## Final Review

Before completing a Bash change, check:

- Is every new line necessary?
- Can nested logic be simplified?
- Can an `else` be eliminated with an early return or exit?
- Is any condition redundant?
- Is any error handling excessive?
- Is any logic duplicated?
- Is any function unnecessary?
- Is any variable unnecessary?
- Are there unnecessary external commands?
- Are there unnecessary comments?
- Did the refactoring accidentally introduce new functionality?
- Is the result easier to understand than the original?
- Is the resulting script no longer than necessary?

Prefer a smaller, straightforward, maintainable Bash script over a larger defensive implementation.
