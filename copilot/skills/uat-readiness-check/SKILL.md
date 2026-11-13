---
name: uat-readiness-check
description: "Run a UAT readiness check across architecture, testing, security, observability, and delivery risks"
disable-model-invocation: true
argument-hint: "Scope and target date"
---
Perform a UAT readiness assessment for the requested scope.

Inputs to use:
- docs/WorkPlan/bff-uat-workplan.md
- docs/WorkPlan/bff-uat-dependencies-risks-issues.md
- docs/Standards/Review.MD
- Current code, tests, and infrastructure configuration

Execution requirements:
1. Evaluate readiness across feature completeness, testing, security, observability, and deployment confidence.
2. Identify blockers, high risks, and unresolved dependencies.
3. Provide a gap-to-action plan with owners and suggested sequencing.
4. Highlight quick wins and critical path tasks.

Output format:
- Readiness scorecard by category
- Blocking issues
- Prioritized action plan
- Suggested timeline checkpoints