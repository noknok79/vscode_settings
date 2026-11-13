---
description: "Run OWASP and P-01 to P-10 security compliance audit with prioritized findings"
name: "Security Audit"
argument-hint: "Scope to audit: full solution, BFF, infra, or folder"
agent: "Security Auditor Agent"
---
Run a security and compliance audit for the requested scope.

Inputs to use:
- docs/Standards/Review.MD
- .github/copilot-instructions.md
- Security posture across BFF, Functions, and Terraform (`infrastructure/apim-terraform/`)

Execution requirements:
1. Validate OWASP Top 10 risks and controls.
2. Validate P-01 to P-10 alignment with evidence.
3. Highlight hardcoded secrets, auth gaps, insecure defaults, and data sovereignty issues.
4. Provide prioritized remediation plan with actionable fixes.

Output format:
- Findings by severity
- Impact and exploitability notes
- Recommended fixes
- Validation steps for each remediation