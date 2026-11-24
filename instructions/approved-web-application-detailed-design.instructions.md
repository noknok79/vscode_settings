---
applyTo: "docs/Solution/Web Application Detailed Design.md"
description: "Protect the approved web application detailed design baseline. Use when: edit detailed design, update architecture baseline, record implementation status, or propose an approved-design amendment."
---

# Approved Web Application Detailed Design Protection

`docs/Solution/Web Application Detailed Design.md` is an approved architecture
baseline. Treat it as read-only by default.

- Do not edit this document for implementation progress, temporary deployment
  arrangements, local developer workflow, test execution status, review
  findings, or DevOps transition updates.
- Record mutable delivery and operational status in an appropriate separate
  document under `docs/Solution/Overview/` and link to the approved baseline
  when architectural context is needed.
- Make a change to this approved document only when the user explicitly
  authorizes an approved-design amendment. Preserve the version-control record
  and state the approval source, date, and architectural rationale.
- When a proposed change is uncertain, ask for confirmation before editing this
  document.