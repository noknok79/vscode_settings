---
name: bff-feature-builder
description: "Build a complete BFF feature from requirements using Clean Architecture and CQRS"
disable-model-invocation: true
argument-hint: "Feature requirement and acceptance criteria"
---
Build a complete BFF feature from the provided requirement.

Inputs to use:
- Feature requirement text from the user
- Existing APIs and domain models in this repository
- Project standards in docs/Standards/Review.MD
- Conventions in .github/instructions/bff-domain.instructions.md

Execution requirements:
1. Implement Domain, Application, Infrastructure, and API changes in correct order.
2. Enforce Clean Architecture dependency rule and MediatR CQRS.
3. Use ErrorOr for expected failures and ApiResponse envelope for endpoints.
4. Add validator and static mapper.
5. Add or update tests for the new behavior.
6. Run build and relevant tests, then report file-by-file change summary.

Output format:
- Solution approach summary
- Files changed with purpose
- Validation results (build/tests)
- Follow-up recommendations if any remain