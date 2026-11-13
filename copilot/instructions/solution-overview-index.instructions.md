---
applyTo: "docs/Solution/Overview/index.html"
description: "Keep the solution overview index aligned with verified implementation evidence. Use when: update requirement status, latest implementation changes, last-modified date, or remaining-work gaps."
---

# Solution Overview Index Instructions

Keep `docs/Solution/Overview/index.html` aligned with the latest verified implementation state whenever a BFF, Function, infrastructure, or UI integration change affects a listed requirement.

## Required Update

- Update the visible `Last modified` date and its ISO `datetime` value on every implementation-status change.
- Update the `Latest implementation changes` section with concise, verified changes and remaining gaps.
- Reconcile affected requirement rows so BFF status, completed work, and remaining work match the code and tests.
- Use `Implemented locally` or `Partial` when production data, authorization, CRM, or source-system validation is still outstanding.
- Do not mark a requirement complete based only on a unit test, placeholder adapter, or assumed CRM design.
- Preserve the existing navigation, accessible labels, responsive table behavior, and status vocabulary.

## Evidence Required

Before changing the page, check the relevant controller/handler/repository or Function implementation, its tests, and the current implementation review under `docs/Review/`. Record unresolved discrepancies in the page's remaining-work text rather than silently presenting them as complete.