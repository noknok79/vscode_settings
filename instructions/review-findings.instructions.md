---
description: "Use when producing review documentation, audit findings, architecture assessment, or standards compliance reports. Ensures date-tagged findings files under docs/Review and prevents baseline template overwrite."
---

# Review Findings Instructions

- Governing standard: [docs/Standards/Review.MD](../../docs/Standards/Review.MD)
- Skill guide: [docs/Review/Solution-Review-Skill.md](../../docs/Review/Solution-Review-Skill.md)

## Required Behavior

- Do not update [docs/Review/ReviewChecklist.md](../../docs/Review/ReviewChecklist.md).
- Create a new findings report file with this pattern: `docs/Review/Review-Findings-YYYY-MM-DD.md`.
- Include metadata: Review Date, Reviewer, Scope, Status.
- Include sections: Executive Summary, Findings by Severity, Checklist Status, P-01 to P-10 Status, Action Plan, Test Coverage and Gaps.

## Evidence Quality

- Link each major finding to concrete repository evidence.
- Mark unverifiable items as Not Verified.
