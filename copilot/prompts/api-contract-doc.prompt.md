---
description: "Generate or update endpoint contract documentation under docs/API Inventory"
name: "API Contract Doc"
argument-hint: "Endpoint route or controller action"
agent: "API Docs Agent"
---
Generate or update API contract documentation for the specified endpoint.

Inputs to use:
- Controller action and route
- Related Command/Query, DTOs, validators, and response models
- API naming rules in docs/API Inventory/api-doc-naming-standard.md

Execution requirements:
1. Produce or update a standards-compliant API markdown file.
2. Document request, response, validation rules, errors, and examples.
3. Keep naming consistent with existing API Inventory docs.
4. Cross-check behavior with implementation and tests.

Output format:
- Documentation file path created/updated
- Key contract details captured
- Any mismatches found between docs and code