---
description: "Plan and implement Azure APIM configuration changes in Terraform with security and reliability checks"
name: "Azure Infra Change"
argument-hint: "Requested infrastructure change and environment"
agent: "agent"
---
Plan and implement the requested Azure APIM configuration change in this solution.

Inputs to use:
- infrastructure/apim-terraform/main.tf and related .tf files
- .github/instructions/infra-terraform.instructions.md
- docs/Standards/Review.MD and .github/copilot-instructions.md

Execution requirements:
1. Call Azure best-practice guidance first when Azure-specific implementation is needed.
2. Implement smallest safe Terraform changes that satisfy the request.
3. Preserve region/data sovereignty constraints and managed identity patterns.
4. Include RBAC, diagnostics, and resilience considerations where relevant.
5. Validate configuration and provide `terraform plan`/`apply` commands.

Output format:
- Proposed architecture delta
- Files changed with rationale
- Validation commands and expected output
- Rollback/mitigation notes