---
description: Diagnose AKS and Kubernetes configuration or runtime failures
agent: agent
argument-hint: "cluster symptom, manifest, or log"
---

# Troubleshoot Aks

Target: use the user's chat input and selected files; if none is specified, use relevant workspace context.

## Task
Investigate manifests, events, pods, networking, DNS, ingress, identities, RBAC, secrets references, storage, and node scheduling based on evidence. Suggest read-only kubectl/az diagnostics first. Avoid cluster mutations, restarts, or credential disclosure without approval. Validate manifests where feasible.

## Operating rules
- Inspect relevant workspace files and existing project instructions before proposing edits.
- Identify the root cause; avoid speculative or unrelated changes.
- Preserve existing behavior, interfaces, naming, and deployment intent unless a change is necessary and explained.
- Prefer the smallest maintainable correction. Avoid redundant guards, nested branches, broad exception handling, and unnecessary abstractions.
- Never print, commit, or expose secrets. Never execute destructive commands or apply infrastructure changes without explicit approval.
- Consult official documentation when tools are available; distinguish verified guidance from assumptions.
- Run available non-destructive validation. Report commands run, outcomes, and checks that could not be performed. Never claim a check passed unless executed.
- Finish with: Root cause; Files changed; Validation; Remaining risks.
