---
name: generate-missing-tests
description: "Generate missing BFF and UI tests based on repository testing conventions"
disable-model-invocation: true
argument-hint: "Target file, feature, or endpoint to test"
---
Generate missing tests for the specified target.

Inputs to use:
- Target handler/controller/component/hook from the user
- Existing tests in tests/unit, tests/integration, and tests/e2e
- Conventions in .github/instructions/tests.instructions.md
- Canonical test-plan Markdown files from the location defined in `.github/instructions/tests.instructions.md`, including the index, requirement coverage, relevant feature-area document, and validation/open-items document
- Service-specific test traceability in `docs/Solution/Overview/Testing/INDEX.md` and the matching `PID26-*.md` document

Execution requirements:
1. Read the applicable test-plan Markdown files before designing tests.
2. Identify missing unit, integration, and UI tests and map each gap to requirement IDs and scenarios.
3. Follow Arrange-Act-Assert style and existing naming patterns.
4. Add focused positive, negative, boundary, authorization, and state-transition tests required by the plan.
5. Keep tests deterministic and avoid flaky assertions.
6. Run relevant test tasks and summarize pass/fail status, requirement mappings, uncovered scenarios, and any plan/implementation discrepancies.

Output format:
- Test gaps found
- New tests created
- Commands run and results
- Residual risk or remaining test gaps