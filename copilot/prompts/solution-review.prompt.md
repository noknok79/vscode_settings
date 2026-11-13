---
description: "Run a standards-driven solution review for architecture, SOLID, performance, and quality"
name: "Solution Review"
argument-hint: "Scope to review: full solution, BFF, infra, or folder"
agent: "Solution Review Agent"
---
Perform a solution review for the requested scope.

Inputs to use:
- docs/Standards/Review.MD (P-01 to P-10)
- Clean Architecture rules from .github/copilot-instructions.md
- Existing tests and implementation under the requested scope

Execution requirements:
1. Prioritize findings by severity with evidence.
2. Focus on defects, regressions, risk, and missing tests.
3. Include file references and clear remediation guidance.
4. Keep summaries brief after listing findings.

Output format:
- Findings ordered by severity
- Open questions/assumptions
- Optional concise change summary
- Recommended next actions