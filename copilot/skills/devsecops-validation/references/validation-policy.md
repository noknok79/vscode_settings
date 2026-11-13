# DevSecOps Validation Policy

## 1. Purpose

Define safe, repeatable, evidence-based validation
for infrastructure, automation, and CI/CD configurations.

This policy complements existing global Copilot
instructions, skills, agents, and hooks.

Existing security restrictions take precedence.

## 2. Default Execution Mode

Default to non-destructive validation.

Do not modify infrastructure, deployment state,
cloud resources, credentials, or production systems.

Inspect the requested scope before running tools.

## 3. Tool Selection

Run only tools applicable to the selected files.

| File Type | Validation |
|---|---|
| Terraform | terraform fmt, terraform validate, TFLint |
| Terraform / IaC | Checkov, Trivy |
| Shell scripts | bash -n, ShellCheck |
| Helm charts | helm lint, helm template |
| Kubernetes YAML | Trivy configuration scanning |
| Repository files | Gitleaks |

Do not run every scanner indiscriminately.

## 4. Terraform Safety

Permitted for appropriate local configurations:

- terraform fmt -check
- terraform validate
- tflint

Terraform validation may require initialization.

Do not automatically execute terraform init.

Initialization can download providers or modules,
create local files, and interact with configured backends.

Never automatically execute:

- terraform apply
- terraform destroy
- terraform import
- terraform state
- terraform force-unlock

Require explicit authorization for consequential operations.

## 5. Kubernetes Safety

Prefer offline configuration inspection.

Never automatically execute:

- kubectl apply
- kubectl delete
- kubectl replace
- kubectl patch
- kubectl scale
- kubectl rollout restart

Do not assume that client-side dry-run is completely
independent of cluster connectivity.

Do not access a live cluster without authorization.

## 6. Helm Safety

Permitted for reviewed local charts:

- helm lint
- helm template

Do not automatically execute:

- helm install
- helm upgrade
- helm uninstall
- helm rollback

Do not fetch chart dependencies or remote repositories
without appropriate authorization.

## 7. Security Scanning

### Checkov

Run against relevant Infrastructure-as-Code files.

Report failed policies and affected resources.

Do not automatically suppress findings.

### Trivy

Run relevant local misconfiguration scans.

Vulnerability scans may download databases.

Report database availability and scan limitations.

### Gitleaks

Use explicit scan scope.

Do not print detected secret values.

Redact findings.

Do not upload security reports to external services.

## 8. Bash Validation

Use:

- bash -n
- shellcheck

Do not execute scripts merely to validate their syntax.

Avoid scanning unrelated repositories.

## 9. Result Classification

Classify each check as:

- PASS: Completed successfully.
- FAIL: Completed and identified validation failures.
- ERROR: Tool execution failed.
- SKIPPED: Not applicable or intentionally excluded.
- UNAVAILABLE: Required tool or prerequisite missing.

Do not classify an execution error as a security finding.

Do not classify a skipped check as passed.

## 10. Reporting Requirements

Include:

1. Scope
2. Files inspected
3. Tools executed
4. Commands executed
5. Exit codes
6. Passed checks
7. Failed checks
8. Security findings
9. Skipped checks
10. Execution errors
11. Recommended remediation
12. Remaining risks

Do not fabricate validation results.

## 11. Production Safeguards

Assume infrastructure may affect production unless
the environment is explicitly identified.

Require authorization before infrastructure-changing
operations.

Preserve existing organizational approval gates.

Do not bypass existing security hooks.

## 12. Integration

Primary agent:

- devops-engineer

Supporting agents:

- devsecop
- code-reviewer
- infra-archi

Use the validation workflow on demand.

Do not automatically execute every scanner after
every Copilot tool call.

## 13. Evidence and Auditability

Record actual execution outcomes.

Keep reports within approved local storage.

Avoid storing credentials or sensitive findings
inside Git repositories.

Use clear, actionable remediation recommendations.

Distinguish verified facts from assumptions.
