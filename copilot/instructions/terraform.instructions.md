---
applyTo: "**/*.tf,**/*.tfvars,**/*.tf.json,**/.terraform.lock.hcl"
---

# Terraform on Azure Development, Troubleshooting, and Refactoring Instructions

These instructions apply whenever creating, modifying, debugging, troubleshooting,
reviewing, optimizing, or refactoring Terraform infrastructure, especially Terraform
used with Microsoft Azure.

# Core Principle

Never guess Terraform syntax, provider behavior, Azure resource properties,
provider capabilities, API behavior, state behavior, or deployment behavior.

Before modifying Terraform:

1. Understand the existing configuration.
2. Identify the exact error or requested change.
3. Identify the Terraform resource, module, provider, backend, or expression involved.
4. Check the current official documentation.
5. Determine provider and Terraform version compatibility.
6. Determine whether the proposed change affects Terraform state.
7. Determine whether the proposed change can recreate or destroy infrastructure.
8. Make the smallest safe change.
9. Format and validate the configuration.
10. Run or recommend a Terraform plan.
11. Review the plan before recommending apply.

Do not rewrite working Terraform unnecessarily.

# Documentation and Research Priority

When solving Terraform problems, use sources in this order:

1. HashiCorp Terraform documentation
2. Terraform Registry documentation for the exact provider/resource/data source
3. Microsoft Learn Terraform on Azure documentation
4. Official Azure service documentation
5. Official HashiCorp GitHub repositories
6. Official Microsoft GitHub repositories
7. Official provider GitHub repositories
8. Official GitHub repository for any integrated technology
9. Well-maintained community repositories only as supporting examples

For AzureRM:

- Check the HashiCorp AzureRM provider documentation.
- Check the AzureRM provider changelog when behavior may be version-specific.
- Check the terraform-provider-azurerm GitHub repository when documentation does not
  explain known behavior, regressions, deprecations, or implementation details.

For AzAPI:

- Check Microsoft documentation.
- Check the official AzAPI provider documentation.
- Verify the Azure Resource Manager API version.
- Verify that the property actually exists in that API version.

Never use Stack Overflow, Reddit, blogs, or community GitHub repositories as the
primary authority when official documentation exists.

Do not copy Terraform from GitHub without verifying it against the current provider
documentation.

# Version Awareness

Before changing provider-specific configuration, inspect:

- required_version
- required_providers
- provider constraints
- .terraform.lock.hcl
- current provider version
- module version constraints
- Terraform CLI version

Do not assume examples written for another major provider version are compatible.

Do not automatically upgrade:

- Terraform
- AzureRM
- AzAPI
- AzureAD
- Microsoft Graph providers
- modules

just to resolve an error.

If an upgrade is actually required:

1. Explain why.
2. Check release notes/changelog.
3. Identify breaking changes.
4. Determine state impact.
5. Determine configuration migrations.
6. Upgrade intentionally.

Never remove version constraints merely to solve dependency resolution.

# Required Providers

Prefer explicit provider declarations.

Example:

    terraform {
      required_version = ">= 1.x"

      required_providers {
        azurerm = {
          source  = "hashicorp/azurerm"
          version = "~> x.x"
        }
      }
    }

Do not invent provider version numbers.

Inspect the project's existing requirements before recommending changes.

# AzureRM Provider

For every AzureRM resource or data source modification:

1. Identify its exact Terraform resource type.
2. Check the official AzureRM provider documentation.
3. Verify that every proposed argument exists.
4. Verify required arguments.
5. Verify optional arguments.
6. Verify nested block structure.
7. Verify computed/read-only attributes.
8. Check ForceNew/replacement behavior where relevant.
9. Check provider-version compatibility.
10. Check Azure service requirements.

Never infer an AzureRM property from its ARM/Bicep equivalent.

ARM, Bicep, Azure CLI, Azure PowerShell, AzureRM Terraform, and AzAPI schemas are not
interchangeable.

# AzureRM vs AzAPI

Prefer AzureRM when the Azure resource or capability is properly supported.

Consider AzAPI when:

- AzureRM does not yet expose the required Azure capability.
- A required property is only available through the ARM API.
- Microsoft documentation specifically recommends AzAPI for that capability.

Do not replace stable AzureRM resources with AzAPI unnecessarily.

Before using AzAPI:

1. Verify the resource provider namespace.
2. Verify the resource type.
3. Verify the API version.
4. Verify the request schema.
5. Verify parent resource hierarchy.
6. Verify required properties.
7. Verify output handling.

Never guess an ARM API version.

# Error Diagnosis

When given a Terraform error, do not immediately rewrite the configuration.

Use this sequence:

    Exact error
       ↓
    Terraform phase
       ↓
    Resource/provider/module involved
       ↓
    Root cause
       ↓
    Official documentation
       ↓
    Minimal safe fix
       ↓
    terraform fmt
       ↓
    terraform validate
       ↓
    terraform plan
       ↓
    Review plan

Classify the failure first.

Possible categories include:

- initialization
- backend initialization
- provider installation
- dependency/version resolution
- syntax
- validation
- provider configuration
- authentication
- authorization/RBAC
- state
- state locking
- resource import
- drift
- planning
- Azure API validation
- Azure Policy
- networking
- DNS
- quota
- deployment
- timeout
- provider regression
- module contract
- dependency graph
- destroy/replacement
- concurrent execution

Prioritize the first meaningful error rather than cascading secondary errors.

Do not treat warnings as root causes unless evidence shows they contribute to the
failure.

# Minimal Change Principle

When fixing existing Terraform:

- Preserve working resources.
- Preserve existing names.
- Preserve resource addresses.
- Preserve module paths.
- Preserve variable names.
- Preserve output names.
- Preserve backend configuration.
- Preserve provider aliases.
- Preserve data-source behavior.
- Preserve dependencies.
- Preserve environment-specific configuration.

Do not:

- refactor unrelated resources
- rename resources unnecessarily
- move resources unnecessarily
- recreate modules unnecessarily
- reorganize files merely for style
- introduce unrelated variables
- change providers unnecessarily
- upgrade versions unnecessarily

Fix the smallest affected portion first.

# Terraform State Safety

Treat Terraform state as critical infrastructure data.

Never:

- manually edit terraform.tfstate
- recommend deleting state as a normal fix
- remove resources from state without understanding consequences
- force-unlock state casually
- disable state locking simply to make a pipeline pass
- copy state between environments casually
- commit Terraform state to Git
- expose state contents containing secrets
- use `terraform apply -refresh-only` without understanding its consequences

Before any state-changing operation, explain the impact.

Commands requiring special caution include:

    terraform state rm
    terraform state mv
    terraform import
    terraform force-unlock
    terraform apply
    terraform destroy

Do not execute or recommend destructive state operations as an automatic fix.

# State Lock Errors

When Terraform reports a state lock error:

1. Determine which backend is being used.
2. Determine whether another Terraform operation is running.
3. Identify the lock owner when available.
4. Determine whether the operation is genuinely stale.
5. Check CI/CD pipelines for concurrent operations.
6. Check whether another engineer or process is running Terraform.
7. Do not use `-lock=false` as the standard fix.
8. Do not use force-unlock until the stale lock has been verified.

Never bypass state locking merely to make Terraform continue.

# Azure Remote State

For Azure-backed remote state, inspect:

- storage account
- resource group
- storage container
- blob/key name
- authentication method
- RBAC
- network restrictions
- private endpoints
- firewall rules
- DNS
- backend configuration

Do not confuse provider authentication with backend authentication.

Terraform can authenticate successfully to the provider while backend authentication
still fails.

# Terraform Validation

When Terraform files are changed, use:

    terraform fmt -check -recursive

Then:

    terraform init -backend=false

when backend connectivity is unnecessary for configuration validation.

Then:

    terraform validate

`terraform validate` checks configuration syntax and internal consistency, but it does
not validate remote APIs or deployed Azure infrastructure.

For deployment-specific correctness, use:

    terraform plan

Do not claim that `terraform validate` proves an Azure deployment will succeed.

# Terraform Format

Terraform formatting should be handled by:

    terraform fmt

Do not manually enforce formatting that conflicts with terraform fmt.

Prefer:

    terraform fmt -recursive

when validating a repository.

Avoid unrelated formatting changes outside the affected Terraform code when a minimal
diff is important.

# Terraform Plan

Before recommending `terraform apply`, inspect or request:

    terraform plan

Prefer saving a plan in automation when the workflow requires controlled plan/apply
separation.

Never assume a successful `terraform plan` means the change is safe.

Review for:

    + create
    ~ update in-place
    - destroy
    -/+ replace
    +/- replacement patterns

Treat unexpected destruction or replacement as a blocking concern.

If Terraform proposes recreation unexpectedly:

STOP.

Investigate:

1. Which argument caused replacement?
2. Was the configuration changed?
3. Did the provider behavior change?
4. Did an Azure-side property drift?
5. Did a resource address change?
6. Was count/for_each modified?
7. Was a module/resource renamed?
8. Is a moved block required?

Do not continue toward apply until unexpected replacement is understood.

# Terraform Apply

Never recommend automatic apply immediately after changing infrastructure code.

Preferred sequence:

    terraform fmt
    terraform validate
    terraform plan
    review plan
    terraform apply

In CI/CD, preserve existing approval/environment controls.

Do not introduce:

    terraform apply -auto-approve

unless the existing automation intentionally uses unattended apply and the request
requires it.

Never use auto-approve merely for convenience.

# Destroy Safety

Treat:

    terraform destroy

as destructive.

Do not recommend destroy/recreate as a first-line troubleshooting technique.

Before destruction, evaluate:

- production impact
- data loss
- persistent disks
- databases
- Key Vault contents
- private endpoints
- networking dependencies
- DNS
- identities
- role assignments
- resource locks
- downstream consumers

Prefer repairing configuration/state relationships over destroying infrastructure.

# Lifecycle Rules

Do not add:

    lifecycle {
      ignore_changes = [...]
    }

merely to hide drift.

Before using ignore_changes:

1. Identify why drift exists.
2. Determine who owns the property.
3. Determine whether Azure modifies it automatically.
4. Determine whether another deployment system controls it.
5. Determine whether ignoring it creates configuration divergence.

Use ignore_changes only when ownership of that property is deliberately outside
Terraform or the provider/Azure service requires it.

Do not routinely use:

    prevent_destroy = true

as a substitute for proper CI/CD controls.

Do not use:

    create_before_destroy = true

without considering Azure naming constraints and duplicate-resource limitations.

# depends_on

Prefer Terraform's implicit dependency graph.

Do not add explicit `depends_on` merely because one resource conceptually follows
another.

Use `depends_on` when Terraform cannot infer a required dependency from references.

Remove redundant depends_on relationships when safe.

Avoid module-level depends_on unless genuinely required because it can create overly
broad dependency relationships.

# count and for_each

Use count or for_each intentionally.

Prefer `for_each` when resources have stable logical identities.

Be extremely careful converting:

    count

to:

    for_each

on existing infrastructure.

Such changes can alter resource addresses and cause unexpected recreation unless
state/resource addresses are migrated correctly.

Before changing count/for_each:

1. Inspect current resource addresses.
2. Determine state impact.
3. Determine whether moved blocks are needed.
4. Review the resulting plan.

Never perform this conversion only as a stylistic refactor.

# moved Blocks

When refactoring resource addresses, consider Terraform `moved` blocks rather than
destroying and recreating infrastructure.

Use moved blocks when appropriate for:

- resource renaming
- module restructuring
- count/for_each migrations
- resource movement into modules

Always verify the exact source and destination addresses.

# import Blocks and terraform import

When infrastructure already exists in Azure:

Do not automatically recreate it.

Evaluate whether it should be imported into Terraform.

Before importing:

1. Confirm the Azure resource identity.
2. Confirm the Terraform resource type.
3. Confirm the correct import ID format.
4. Create matching Terraform configuration.
5. Import the resource.
6. Run terraform plan.
7. Reconcile configuration until unexpected changes disappear.

Do not assume the Azure resource ID is always the exact import syntax required by
the provider documentation.

# Variables

Prefer typed variables.

Example:

    variable "environment" {
      description = "Deployment environment."
      type        = string
    }

Use validation blocks when they enforce a meaningful contract.

Do not create variables for values that should remain internal implementation details
unless reuse/configurability is needed.

Do not hard-code environment-specific values when the project already uses variables.

Do not over-parameterize modules.

# Locals

Use locals to simplify repeated expressions or derive values.

Do not create locals that merely rename a value without improving readability.

Prefer:

    local.resource_name

when a meaningful derived naming convention is reused.

Avoid layers of locals that make tracing values difficult.

# Outputs

Create outputs only when they are consumed or operationally useful.

Mark sensitive outputs:

    sensitive = true

when appropriate.

Remember that `sensitive = true` primarily controls display behavior.

Do not assume it removes the value from Terraform state.

Never output secrets unnecessarily.

# Secrets

Never hard-code:

- passwords
- PATs
- service principal secrets
- client secrets
- certificates containing private keys
- API keys
- connection strings
- database credentials
- storage account keys

Never commit secrets in:

- .tf
- .tfvars
- *.auto.tfvars
- backend configuration
- scripts
- pipeline YAML
- examples

Prefer:

- Azure workload identity federation
- managed identities
- Azure Key Vault
- Azure DevOps secret variables
- secure CI/CD environment variables

Avoid client secrets when workload identity federation or managed identity is
appropriate.

# Sensitive Data and State

Assume Terraform state can contain sensitive values.

Do not print entire state files into:

- CI/CD logs
- Copilot prompts
- tickets
- Git commits
- debugging output

Use targeted Terraform state commands only when necessary.

Never recommend:

    cat terraform.tfstate

as routine troubleshooting.

# Azure Authentication

Distinguish among:

- Azure CLI authentication
- service principals
- managed identity
- workload identity federation
- Azure DevOps service connections
- backend authentication
- provider authentication

Do not automatically convert one authentication model into another.

For local development, respect the repository's established authentication method.

For CI/CD, prefer non-interactive identity mechanisms.

Never recommend storing Azure client secrets directly inside Terraform files.

# Azure RBAC

When Terraform receives authorization errors:

1. Read the exact Azure error.
2. Identify the caller identity.
3. Identify the scope.
4. Identify the denied action.
5. Determine the minimum required role/permission.
6. Check current Microsoft documentation.
7. Consider RBAC propagation delay when appropriate.

Do not automatically recommend Owner or Contributor.

Use least privilege.

Do not assign broad permissions merely to make Terraform succeed.

# Azure Resource Names

Preserve existing enterprise naming conventions.

Do not rename existing Azure resources for stylistic reasons.

Remember that Azure naming constraints differ by service.

Before generating a resource name:

1. Check service-specific naming restrictions.
2. Check length.
3. Check allowed characters.
4. Check uniqueness requirements.
5. Check whether changing the name causes replacement.

# Azure Locations

Do not change Azure regions casually.

Before changing location, consider:

- resource recreation
- service availability
- availability zones
- data residency
- network topology
- latency
- private endpoints
- paired regions
- existing resource dependencies

Never change region merely because an example uses another location.

# Azure Resource IDs

Prefer Terraform resource references rather than manually reconstructing Azure resource
IDs.

Prefer:

    azurerm_resource_group.example.id

over manually concatenating an Azure resource ID.

Use explicit IDs only when there is a legitimate reason or the resource is external
to Terraform.

# Data Sources

Use data sources for existing infrastructure Terraform should reference but not own.

Do not replace managed resources with data sources without understanding ownership.

Do not use data sources merely to avoid properly modeling resource dependencies.

Understand the difference between:

- infrastructure Terraform creates
- infrastructure Terraform manages
- infrastructure Terraform only reads

# Modules

Before modifying a module:

1. Understand its public interface.
2. Review variables.
3. Review outputs.
4. Review provider requirements.
5. Review callers.
6. Determine potential breaking changes.

Preserve backwards compatibility when practical.

Do not introduce a module simply to wrap a single trivial resource unless there is a
clear reuse or organizational benefit.

Prefer cohesive modules representing meaningful infrastructure capabilities.

Avoid mega-modules containing unrelated infrastructure.

Avoid excessive module nesting.

# Module Sources

Use trusted module sources.

Prefer:

1. internal organization-approved modules
2. verified Terraform Registry modules
3. Microsoft/HashiCorp-supported modules where appropriate
4. vetted source-controlled modules

Pin module versions when the project requires reproducible builds.

Do not automatically pull an unversioned module from an arbitrary Git repository.

# Provider Aliases

Preserve provider aliases.

Provider aliases often represent:

- subscriptions
- tenants
- regions
- management contexts

Do not remove an alias because it appears redundant without inspecting module/provider
relationships.

When modules require aliased providers, verify providers mapping.

# Multi-Subscription Azure Deployments

When Terraform manages multiple Azure subscriptions:

- Verify provider alias.
- Verify subscription ID source.
- Verify tenant.
- Verify authentication context.
- Verify resource references.
- Verify cross-subscription permissions.

Do not assume the default provider targets the correct subscription.

# Azure Networking

Treat networking changes as high impact.

Before changing:

- VNets
- subnets
- NSGs
- route tables
- private endpoints
- private DNS
- Application Gateway
- Azure Firewall
- load balancers
- NAT gateways
- peering

determine existing dependencies.

Pay particular attention to:

- subnet delegation
- service endpoints
- private endpoint policies
- address-space overlap
- DNS zone links
- routing
- NSG rules
- public network access

Never solve connectivity problems by broadly opening:

    0.0.0.0/0

unless explicitly required and security implications are understood.

# Azure Key Vault

Never weaken Key Vault security simply to resolve Terraform access problems.

Distinguish:

- Azure RBAC
- legacy access policies
- network restrictions
- private endpoints
- firewall rules
- deployment identity
- Terraform execution identity

Identify the exact failing identity.

Do not disable Key Vault firewall or public-network restrictions as the default fix.

# Azure Container Registry

For ACR issues, distinguish:

- Azure RBAC
- AcrPull
- AcrPush
- authentication
- admin account
- managed identity
- networking
- private endpoints
- DNS
- repository permissions

Do not enable the ACR admin account simply to bypass proper authentication.

# AKS

For AKS Terraform changes:

Check:

- Kubernetes version
- node pool configuration
- VM SKU availability
- subnet configuration
- managed identity
- workload identity
- OIDC issuer
- networking plugin
- DNS
- private cluster settings
- Azure RBAC
- ACR integration

Do not recreate an AKS cluster to solve a localized configuration problem unless
replacement is unavoidable and explicitly understood.

# App Service

For App Service Terraform changes, distinguish among:

- App Service Plan
- Linux Web App
- Windows Web App
- deployment slots
- managed identity
- application settings
- connection strings
- VNet integration
- private endpoints
- public network access

Check provider documentation for the exact AzureRM resource because schemas differ
between App Service resource types.

# Terraform and Azure DevOps Pipelines

When Terraform runs from Azure DevOps:

Check separately:

1. YAML correctness.
2. Pipeline variable availability.
3. Service connection.
4. Terraform authentication.
5. Backend authentication.
6. Terraform CLI version.
7. Provider versions.
8. workingDirectory.
9. tfvars files.
10. initialization.
11. state locking.
12. plan.
13. artifact handling.
14. approval gates.
15. apply.

Do not assume every Terraform failure reported by Azure Pipelines is a Terraform
configuration error.

It may instead be:

- YAML
- agent
- authentication
- networking
- permissions
- environment
- working directory
- missing file
- secret handling
- pipeline runtime expression

Troubleshoot the correct layer.

# CI/CD Plan and Apply Separation

When the existing organization uses separate plan and apply stages:

Preserve that architecture.

Do not merge plan/apply into one stage merely for simplicity.

When saved plans are used:

Ensure apply consumes the intended plan artifact.

Do not create one plan and silently regenerate another before apply unless the
pipeline intentionally works that way.

# Parallel Pipeline Runs

Be cautious with multiple Terraform pipelines targeting the same state.

Check:

- concurrent builds
- environment locks
- Azure DevOps exclusive locks
- backend state locking
- branch triggers
- deployment environments

Do not solve concurrency issues by disabling Terraform locking.

# Drift

When plan shows unexpected drift:

Determine who owns the changed configuration:

- Terraform
- Azure Policy
- Azure platform
- another Terraform workspace
- another pipeline
- manual Azure Portal change
- Azure CLI
- PowerShell
- Bicep/ARM
- Kubernetes controller
- external automation

Do not immediately add ignore_changes.

Find the actual source of drift first.

# Azure Policy

If Azure denies Terraform deployment:

Inspect the exact policy violation.

Do not attempt to bypass organizational policy.

Identify:

- policy assignment
- policy definition
- denied property
- required tag
- allowed location
- SKU restriction
- network restriction

Modify Terraform to comply with policy when appropriate.

# Resource Recreation

Whenever Terraform proposes replacement, explicitly identify it.

Do not hide:

    must be replaced

from the user.

Determine the reason.

For production resources, treat unexpected replacement as high risk.

Do not recommend apply until replacement is understood.

# Timeouts

Do not increase Terraform resource timeouts immediately.

First determine why the operation timed out.

Possible causes:

- Azure provisioning delay
- networking
- policy
- quota
- provider issue
- dependency
- API problem
- service health

Increase timeouts only when the operation is legitimately expected to take longer.

# Retrying Operations

Do not wrap Terraform commands in arbitrary retry loops.

Terraform/provider retries already exist for many API operations.

When retries are appropriate, verify the failure is transient.

Never retry deterministic validation, syntax, authorization, or configuration errors
without changing the root cause.

# Deprecated Resources and Arguments

When documentation marks something deprecated:

- Identify the replacement.
- Check migration instructions.
- Check provider version.
- Check state migration implications.
- Check whether migration causes replacement.

Do not rewrite deprecated resources during unrelated bug fixes unless the deprecation
blocks the requested work.

# Terraform Lock File

Treat:

    .terraform.lock.hcl

as part of dependency reproducibility.

Do not casually delete it to solve provider problems.

Do not regenerate it unnecessarily.

When provider constraints change intentionally, update the lock file through normal
Terraform initialization workflows.

Do not hand-edit provider hashes.

# Files That Must Not Be Committed

Warn if encountered:

    terraform.tfstate
    terraform.tfstate.*
    crash.log
    *.tfplan
    .terraform/
    secret *.tfvars files

Do not automatically delete unknown files.

Prefer properly maintaining `.gitignore`.

# Terraform Repository Hygiene

Typical exclusions should protect:

    .terraform/
    *.tfstate
    *.tfstate.*
    crash.log
    crash.*.log
    *.tfplan

Do not blindly ignore all `.tfvars` because some repositories intentionally commit
non-secret configuration.

Evaluate repository conventions first.

# Code Simplification

When refactoring Terraform:

Remove when safe:

- duplicated expressions
- useless locals
- redundant depends_on
- obsolete commented-out resources
- duplicated tags
- repeated naming expressions
- unnecessary interpolation
- unnecessary conditionals

Prefer direct expressions where clear.

Do not make clever one-line expressions that reduce maintainability.

Simplicity means fewer unnecessary concepts, not merely fewer lines.

# Dynamic Blocks

Do not use dynamic blocks when ordinary static blocks are clearer.

Use dynamic blocks when variable-length nested configuration genuinely requires them.

Do not introduce dynamic blocks merely to demonstrate abstraction.

# HCL Expressions

Prefer native Terraform expressions.

Avoid deprecated interpolation-only syntax.

Prefer:

    name = var.name

rather than unnecessary interpolation:

    name = "${var.name}"

Use string interpolation when actually combining strings.

# Security Review

Before completing Azure Terraform changes, check for:

- hard-coded credentials
- overly broad RBAC
- public network exposure
- unrestricted NSG rules
- insecure storage settings
- exposed Key Vault
- insecure ACR access
- unnecessary public IP addresses
- disabled TLS enforcement
- secrets in outputs
- secrets in logs
- secrets in state
- unnecessary Contributor/Owner roles

Do not weaken security without explicit, justified requirements.

# Production Safety

Assume infrastructure may be production unless context establishes otherwise.

Before recommending destructive changes:

STOP and clearly identify the impact.

Do not automatically execute or recommend:

    terraform destroy
    terraform state rm
    terraform force-unlock
    terraform apply -auto-approve
    terraform apply -replace
    terraform taint

without understanding consequences.

# Troubleshooting Output

When explaining a Terraform failure, use this structure:

## Root Cause

State the most likely root cause based on the actual error.

## Evidence

Quote or identify the relevant error message or configuration.

## Documentation Check

State which official Terraform, provider, or Microsoft documentation supports the
diagnosis.

## Minimal Fix

Provide the smallest required code/configuration change.

## Validation

Provide exact validation commands.

## Expected Result

Explain what should change after the fix.

Do not bury the actual fix beneath generic Terraform theory.

# Validation Workflow

When tools and environment permit, prefer this validation sequence:

    terraform fmt -check -recursive
    terraform init -backend=false
    terraform validate

When testing against the actual environment:

    terraform init
    terraform plan

Do not run apply automatically unless explicitly requested and appropriate.

# Final Diff Review

Before considering a Terraform modification complete:

Review the diff.

Check:

- Did unrelated files change?
- Did formatting create unnecessary repository-wide changes?
- Were resource addresses changed?
- Were variables renamed?
- Were providers changed?
- Was the lock file unexpectedly changed?
- Did any secret appear?
- Did any resource gain public exposure?
- Did any lifecycle rule hide drift?
- Did any resource become scheduled for destruction/replacement?
- Were dependencies changed?
- Did the change introduce additional unnecessary complexity?

Prefer a small, reviewable diff.

# Final Terraform Rules

Always follow these principles:

1. Never guess Terraform/provider syntax.
2. Check current official documentation.
3. Verify the exact provider version.
4. Understand state impact.
5. Protect remote state.
6. Preserve state locking.
7. Never expose credentials.
8. Use least privilege.
9. Diagnose drift instead of hiding it.
10. Avoid unnecessary resource replacement.
11. Avoid unnecessary provider upgrades.
12. Avoid unnecessary refactoring.
13. Prefer implicit dependencies.
14. Preserve module contracts.
15. Treat production changes cautiously.
16. Run terraform fmt.
17. Run terraform validate.
18. Run terraform plan.
19. Review destructive changes.
20. Make the smallest safe fix.

When several solutions are technically valid, prefer the solution that:

- follows current HashiCorp documentation
- follows current Microsoft Azure guidance
- matches the installed provider version
- preserves existing Terraform state
- produces the smallest infrastructure change
- uses the least privilege
- introduces the least complexity
- is easiest to validate
- is easiest to review in Git
- is safest to deploy through Azure DevOps

Do not optimize Terraform merely for shorter code.

Optimize for predictable infrastructure, safe state transitions, security,
maintainability, and minimal deployment risk.
