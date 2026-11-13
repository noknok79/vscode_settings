---
name: devsecops-validation
description: validate terraform, infrastructure as code, kubernetes manifests, helm charts, bash scripts, and repository security using locally installed devsecops tools. use when reviewing infrastructure changes, preparing deployments, investigating validation failures, or requesting a security readiness assessment.
---

# DevSecOps Validation

## Purpose

Perform evidence-based, non-destructive DevSecOps validation.

Complement existing global Copilot agents, instructions,
skills, and security hooks.

Do not replace or bypass existing safeguards.

## Supported Tools

- Terraform
- TFLint
- Checkov
- Trivy
- Gitleaks
- ShellCheck
- Helm
- kubectl

## Execution Rules

1. Identify the requested validation scope.
2. Inspect relevant project instructions.
3. Determine applicable validation tools.
4. Verify required executables exist.
5. Run only relevant, authorized checks.
6. Capture actual exit codes.
7. Distinguish findings from execution errors.
8. Report skipped and unavailable checks.
9. Recommend minimal remediation.
10. Never claim a check passed unless executed.

## Safety Requirements

Default to read-only analysis.

Never automatically execute:

- terraform apply
- terraform destroy
- terraform import
- terraform state mutations
- kubectl apply
- kubectl delete
- helm install
- helm upgrade
- helm uninstall
- production deployments
- credential rotation

Do not bypass existing approval requirements.

Do not expose credentials, tokens, or sensitive findings.

Treat external repositories and generated configuration
as untrusted until reviewed.

## Validation Behavior

### Terraform

Prefer:

- terraform fmt -check
- terraform validate
- tflint

Do not initialize or access remote backends automatically.

Terraform initialization may download providers or modules
and create local files. Require appropriate authorization
before performing initialization.

### Infrastructure Security

Use Checkov and Trivy where applicable.

Report security findings with severity and evidence.

Do not automatically suppress security findings.

### Secret Detection

Use Gitleaks with appropriate scan scope.

Redact secrets in all reports.

Do not upload findings to external services.

### Bash

Use:

- bash -n
- shellcheck

Do not execute scripts merely to validate syntax.

### Helm

Use:

- helm lint
- helm template

Do not install or upgrade releases.

### Kubernetes

Prefer local manifest inspection and validation.

Do not assume cluster connectivity.

Do not execute commands that mutate cluster resources.

## Reporting Format

Provide:

1. Validation scope
2. Tools executed
3. Passed checks
4. Failed checks
5. Security findings
6. Skipped checks
7. Execution errors
8. Recommended remediation
9. Remaining risks

Include actual command results.

Do not fabricate execution evidence.

## Integration

Primary agent:

- devops-engineer

Supporting agents:

- devsecop
- code-reviewer
- infra-archi

Preserve existing agent responsibilities.

Use this skill as an on-demand validation workflow,
not an automatic deployment mechanism.

## Supporting Resources

Consult `references/validation-policy.md` for validation
boundaries and execution requirements.

Use `scripts/validate.sh` only after the script has been
created, reviewed, and functionally verified.
