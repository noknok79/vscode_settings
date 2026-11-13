---
applyTo: "**/*.bicep,**/*.bicepparam,**/bicepconfig.json"
---

# Azure Bicep Engineering, Troubleshooting, Security, and Refactoring Instructions

These instructions apply whenever creating, modifying, reviewing, debugging,
troubleshooting, optimizing, validating, or refactoring Azure Bicep infrastructure.

Primary objectives:

1. Correctness
2. Production safety
3. Security
4. Minimal changes
5. Current Azure API compatibility
6. Predictable deployment behavior
7. Maintainability
8. Idempotency
9. Least privilege
10. Clear validation before deployment

Never optimize merely for generating more code.

Never rewrite working Bicep unnecessarily.

Never guess Azure Resource Manager behavior.

---

# Golden Rule

NEVER GUESS:

- Bicep syntax
- resource types
- resource properties
- API versions
- deployment scopes
- resource scopes
- ARM behavior
- Azure service behavior
- RBAC roles
- resource provider capabilities
- module interfaces
- CLI arguments
- PowerShell arguments

Before changing Bicep:

1. Read the relevant existing files.
2. Understand the deployment architecture.
3. Read the exact error when available.
4. Identify the resource/module causing the problem.
5. Identify the deployment scope.
6. Identify the Azure resource provider.
7. Identify the resource type.
8. Identify the API version.
9. Check current Microsoft Learn documentation.
10. Check the official Bicep resource reference.
11. Check the exact API version schema.
12. Check the official Azure service documentation when required.
13. Check Microsoft-owned GitHub repositories when additional implementation examples are useful.
14. Compare documentation with the repository's existing implementation.
15. Determine whether the change affects existing Azure resources.
16. Determine whether it can cause replacement, deletion, public exposure, or permission changes.
17. Make the smallest safe correction.
18. Validate before recommending deployment.

Do not make speculative changes merely because they might fix the deployment.

---

# Source Priority

When researching Bicep or Azure behavior, use sources in this order:

1. Microsoft Learn Bicep documentation
2. Microsoft Learn Bicep resource reference
3. Microsoft Learn Azure Resource Manager documentation
4. Microsoft Learn documentation for the specific Azure service
5. Microsoft-owned Bicep GitHub repositories
6. Azure Verified Modules documentation and repository
7. Microsoft-owned Azure examples
8. Official vendor documentation for integrated technologies
9. Mature public GitHub repositories only as supporting examples

Microsoft documentation is authoritative.

Community examples are supporting evidence only.

Never blindly copy Bicep from:

- Stack Overflow
- Reddit
- blogs
- random repositories
- old tutorials
- AI-generated examples

Always verify community examples against current Microsoft documentation.

---

# Official Bicep Sources

For Bicep-specific questions, prioritize:

- Microsoft Learn Bicep documentation
- Microsoft Learn Bicep resource reference
- Azure/Bicep GitHub repository
- Azure Verified Modules
- Azure/Bicep Registry Modules

The official Azure/Bicep repository is an appropriate source for current language,
CLI, compiler, issue, release, and implementation information.

Use GitHub issues only as supporting evidence.

Do not treat an open GitHub issue as documented product behavior unless verified.

---

# Resource Provider Verification

Every Azure resource declaration must use a real, supported resource type.

Example:

    resource storage 'Microsoft.Storage/storageAccounts@<api-version>' = {
      ...
    }

Before modifying the resource:

1. Identify provider namespace.
2. Identify resource type.
3. Identify API version.
4. Open the current Microsoft resource reference.
5. Verify proposed properties.
6. Verify nested resource structure.
7. Verify allowed values.
8. Verify required properties.
9. Verify read-only properties.
10. Verify deployment scope.

Never infer a Bicep property from:

- Terraform AzureRM
- Terraform AzAPI
- Azure CLI
- Azure PowerShell
- Azure Portal
- REST examples
- another Azure service

Schemas are not interchangeable.

---

# API Versions

Never invent API versions.

Never mechanically replace an API version with a newer-looking date.

Before changing:

    @YYYY-MM-DD

verify:

1. Resource provider
2. Resource type
3. Microsoft resource reference
4. Supported property set
5. Azure region/cloud compatibility when relevant
6. Preview versus stable status
7. behavioral changes
8. deprecated properties
9. newly required properties

Prefer stable API versions unless a required capability exists only in preview.

Do not move production infrastructure to a preview API merely because it is newer.

Do not change an API version during an unrelated bug fix unless required.

---

# Bicep Version Awareness

Before using recently introduced Bicep syntax or functionality:

1. Determine the project's expected Bicep CLI version.
2. Check CI/CD agent Bicep version.
3. Check local Bicep version.
4. Check whether Azure CLI supplies the required Bicep version.
5. Verify feature compatibility.

Do not assume every environment runs the latest Bicep CLI.

When needed, check:

    az bicep version

or:

    bicep --version

Do not upgrade the Bicep CLI solely because a newer version exists.

Upgrade intentionally.

---

# Bicep Linter

Treat the Bicep linter as a mandatory development signal.

Microsoft's Bicep linter checks syntax and best-practice violations and is integrated
with the Bicep CLI and VS Code extension.

Do not suppress linter warnings casually.

Before suppressing a warning:

1. Understand the rule.
2. Determine why the configuration triggers it.
3. Determine whether correcting the Bicep is preferable.
4. Suppress only genuine false positives.
5. Document why suppression is safe.

Never disable an entire linter category merely to make CI pass.

Relevant linter concerns include:

- unnecessary dependsOn
- unused parameters
- unused variables
- unused existing resources
- unused imports
- hard-coded environment URLs
- secret exposure
- insecure parameter defaults
- secret output
- unnecessary interpolation
- deprecated patterns
- resource-reference patterns

---

# bicepconfig.json

Preserve repository-specific configuration.

Do not rewrite:

    bicepconfig.json

without understanding existing organizational controls.

When modifying linter configuration:

- preserve existing rule levels
- preserve module aliases
- preserve cloud settings
- preserve extension configuration
- preserve organization security controls

Do not downgrade:

    error -> warning

or:

    warning -> off

merely to make validation succeed.

Fix the actual Bicep issue first.

---

# Build Validation

Before considering Bicep syntax valid, build it.

Prefer:

    az bicep build --file main.bicep

or, when the standalone CLI is intentionally used:

    bicep build main.bicep

For multiple changed files, validate the affected entry points.

Do not claim the Bicep is valid merely because it visually appears correct.

Compilation does not prove the Azure deployment is safe or authorized.

---

# Error Classification

Before fixing a Bicep failure, classify it.

Possible categories include:

- syntax
- compiler
- linter
- module restore
- module reference
- API version
- resource type
- unsupported property
- incorrect data type
- parameter
- parameter-file
- scope
- existing resource
- dependency
- RBAC
- authentication
- authorization
- Azure Policy
- networking
- Azure API validation
- quota
- resource state
- deployment
- deployment stack
- template spec
- Azure CLI
- Azure PowerShell
- Azure DevOps Pipeline
- GitHub Actions

Fix the correct layer.

---

# Troubleshooting Sequence

When an error is provided:

    Exact Azure/Bicep error
            ↓
    First meaningful failure
            ↓
    Deployment scope
            ↓
    Resource/module
            ↓
    Resource provider
            ↓
    API version
            ↓
    Documentation check
            ↓
    Root cause
            ↓
    Minimal correction
            ↓
    Build/lint
            ↓
    Validate
            ↓
    What-if
            ↓
    Deployment

Prioritize the original failure over cascading secondary errors.

Do not rewrite unrelated infrastructure.

---

# Deployment Scope

Always understand the target scope.

Possible scopes include:

    targetScope = 'resourceGroup'
    targetScope = 'subscription'
    targetScope = 'managementGroup'
    targetScope = 'tenant'

Never move resources between scopes merely to resolve compilation errors.

Before changing scope, determine:

- intended ownership
- target subscription
- management group
- resource group
- required location
- RBAC requirements
- module scope
- extension-resource behavior

Scope changes can materially alter where infrastructure is deployed.

---

# Resource Group Scope

For resource-group deployments, understand which resources belong to the deployment's
resource group.

Do not unnecessarily specify scope when normal resource-group deployment behavior is
sufficient.

When referencing another resource group, use documented Bicep scope mechanisms.

---

# Subscription Scope

Subscription-scope deployments often manage:

- resource groups
- policy assignments
- role assignments
- subscription-level resources

Verify:

    targetScope = 'subscription'

when appropriate.

Do not accidentally convert a resource-group deployment into a subscription-level
deployment.

---

# Management Group Scope

Treat management-group deployments as high-impact.

They can affect:

- policies
- initiatives
- RBAC
- governance
- subscriptions beneath the management group

Apply additional caution before changing:

- policy assignments
- role assignments
- management group structure
- deny settings

---

# Tenant Scope

Treat tenant-scope deployments as highly sensitive.

Do not introduce tenant-scope deployment merely because another scope is inconvenient.

Verify tenant-level permissions and intended blast radius.

---

# Resource Symbolic Names

Use clear symbolic names.

Example:

    resource storageAccount 'Microsoft.Storage/storageAccounts@...' = {
      ...
    }

Symbolic names are Bicep identifiers.

Do not confuse symbolic names with Azure resource names.

Preserve existing symbolic names when unnecessary renaming would create noise.

---

# Resource References

Prefer symbolic resource references.

Prefer:

    storageAccount.id

over manually constructing a resource ID.

Prefer:

    resourceGroup().id

or documented resource ID functions where appropriate rather than manual string
concatenation.

Avoid manually constructing Azure resource IDs unless there is a clear requirement.

---

# Existing Resources

When infrastructure already exists and Bicep should reference rather than deploy it,
consider:

    existing

Example:

    resource storage 'Microsoft.Storage/storageAccounts@...' existing = {
      name: storageAccountName
    }

Microsoft documents that an `existing` resource references infrastructure without
redeploying it.

Never convert a resource from managed to `existing` simply to make deployment succeed.

First determine ownership.

For existing resources verify:

- exact name
- exact scope
- subscription
- resource group
- resource type

If an existing resource returns NotFound, investigate name and scope first.

---

# Parent and Child Resources

Use documented child-resource patterns.

Prefer clear parent relationships when supported.

Do not manually reconstruct child resource names unless required.

Check whether the correct form is:

    parent:

versus a nested declaration or full resource name.

Do not assume every Azure child resource behaves identically.

---

# Dependencies

Prefer implicit dependencies created through symbolic references.

Example:

    resourceB.properties.someId = resourceA.id

often establishes the dependency automatically.

Do not add:

    dependsOn: [
      resourceA
    ]

when the symbolic reference already establishes the dependency.

The Bicep linter includes detection for unnecessary `dependsOn`.

Use explicit `dependsOn` only when Bicep/ARM cannot infer the required dependency.

---

# Loops

Use loops only when multiple logically similar resources are required.

Prefer readable loops.

Do not introduce loops merely to reduce a few lines.

Be careful with resource identity and naming inside loops.

Verify:

- loop index
- unique names
- dependencies
- batch behavior
- outputs
- conditional resources

Do not refactor existing individually named resources into loops without understanding
deployment and resource identity implications.

---

# Conditions

Use conditional resources intentionally.

Example:

    resource optionalResource '...' = if (deployResource) {
      ...
    }

Before changing conditions:

- inspect dependent resources
- inspect outputs
- inspect resource references
- inspect nullable behavior
- inspect safe dereference usage

Do not make resource deployment conditional if downstream resources require it
unconditionally.

---

# Parameters

Parameters form the external contract of the Bicep deployment.

Preserve parameter names unless a breaking change is intentional.

Use strong types wherever practical.

Typical parameter types include:

    string
    int
    bool
    array
    object

Do not use overly broad types when a clear type is available.

Use decorators when useful:

    @description(...)
    @allowed(...)
    @minLength(...)
    @maxLength(...)
    @minValue(...)
    @maxValue(...)
    @secure()

Do not add decorators merely for verbosity.

---

# Parameter Defaults

Use defaults only when a safe and logical default exists.

Do not provide insecure defaults for sensitive values.

Do not hard-code production-specific defaults into reusable modules.

Avoid defaults that silently deploy expensive or publicly accessible infrastructure.

---

# Secure Parameters

Passwords, secrets, tokens, credentials, and similar values must use secure handling.

Use:

    @secure()
    param secretValue string

when appropriate.

Do not hard-code secrets.

Do not provide secret defaults.

Do not place actual secrets in:

- .bicep
- .bicepparam
- JSON parameter files
- bicepconfig.json
- pipeline YAML
- Git
- comments

---

# Secret Outputs

Never put secrets in Bicep outputs.

Microsoft's Bicep linter specifically warns against outputs that can expose secret
information.

Deployment outputs are retained as deployment information and can create unintended
secret exposure.

Do not output:

- passwords
- access keys
- SAS tokens
- client secrets
- private keys
- database passwords
- storage keys

Prefer outputting resource IDs and retrieving secrets securely when required.

---

# listKeys and list* Functions

Treat:

    listKeys()
    listSecrets()
    listCredentials()

and similar functions as potentially sensitive.

Do not expose their results through outputs.

Use them only where the secret value is actually required by the dependent resource.

Avoid storing secret-returning function results in unnecessary variables.

---

# Variables

Use variables for meaningful calculated or repeated values.

Do not create variables that merely rename a parameter without adding clarity.

Prefer direct symbolic references when clearer.

Avoid chains such as:

    parameter -> variable -> variable -> module parameter

unless each layer provides useful abstraction.

---

# Outputs

Create outputs only when:

- another deployment consumes the value
- pipeline automation requires the value
- operators genuinely need it
- module composition requires it

Avoid unnecessary outputs.

Never expose secret material.

Prefer resource IDs and non-sensitive endpoints where appropriate.

---

# Modules

Prefer Bicep modules over manually creating nested ARM deployments.

Microsoft's resource documentation recommends considering Bicep modules instead of
direct `Microsoft.Resources/deployments` resources.

Use modules for meaningful isolation and reuse.

Do not create a module merely to wrap a trivial resource if it adds no reusable
abstraction.

---

# Module Contracts

Treat module parameters and outputs as APIs.

Before changing a module:

1. Inspect its callers.
2. Inspect parameters.
3. Inspect outputs.
4. Inspect scope.
5. Inspect dependencies.
6. Inspect existing deployment environments.

Do not rename module parameters casually.

Do not remove outputs consumed elsewhere.

Avoid unnecessary breaking changes.

---

# Module Scope

Explicitly reason about module scope.

Example:

    module networking './networking.bicep' = {
      name: 'networking'
      scope: resourceGroup(networkResourceGroup)
      params: {
        ...
      }
    }

Verify that the module's declared target scope is compatible with the provided scope.

Do not move modules between subscriptions/resource groups without understanding
resource ownership and RBAC.

---

# Azure Verified Modules

When introducing reusable Azure modules, consider Azure Verified Modules when they fit
the requirement.

Microsoft identifies Azure Verified Modules as its standard for reusable Bicep
modules.

Do not automatically replace established internal modules with AVM.

Before adopting AVM:

1. Check whether an appropriate module exists.
2. Check its version.
3. Review its interface.
4. Review defaults.
5. Review security controls.
6. Review its outputs.
7. Compare with internal standards.
8. Evaluate migration impact.

Pin versions where deterministic deployments are required.

Do not automatically use the newest module version without checking changes.

---

# Public Bicep Registry

Treat module dependencies like software dependencies.

Do not use an arbitrary registry module merely because it produces shorter Bicep.

Prefer:

1. organization-approved modules
2. Azure Verified Modules
3. trusted internal registry modules
4. vetted official modules

Avoid arbitrary third-party modules in production infrastructure.

---

# Module Version Upgrades

Do not upgrade a module during an unrelated bug fix.

Before upgrading:

1. Check release notes.
2. Compare inputs.
3. Compare outputs.
4. Check resource changes.
5. Check API-version changes.
6. Run build.
7. Run what-if.
8. Review replacement/deletion risk.

---

# Bicep Parameter Files

For `.bicepparam`:

- preserve environment-specific values
- preserve using references
- preserve parameter names
- do not add secrets
- do not duplicate defaults unnecessarily

Do not mix environment values accidentally.

Be particularly cautious about:

    dev
    test
    sit
    uat
    staging
    prod

Never copy production resource identifiers into development parameter files merely
because they resolve an error.

---

# Environment Separation

Keep environment-specific configuration clearly separated.

Do not make test/non-production deployments mutate production resources.

When shared infrastructure exists, explicitly model it as existing or shared
infrastructure using documented patterns.

Never infer that similarly named resources belong to the same environment.

---

# Azure Locations

Do not change resource locations casually.

Before changing region, consider:

- resource availability
- resource replacement
- data residency
- availability zones
- service compatibility
- network architecture
- latency
- private endpoints
- paired-region design
- compliance

Do not change location merely because an online example uses another region.

---

# Resource Names

Preserve established Azure naming conventions.

Before generating or changing resource names verify:

- maximum length
- minimum length
- allowed characters
- uniqueness requirement
- global uniqueness requirement
- case behavior
- replacement impact

Do not rename existing resources for style.

---

# Tags

Preserve organizational tagging conventions.

Typical tags may include:

- environment
- application
- owner
- cost center
- project
- business unit
- managedBy

Do not invent organizational tag values.

Avoid overwriting inherited or existing tags unless that is intentional.

---

# RBAC

Treat role assignments as security-sensitive.

Before adding:

    Microsoft.Authorization/roleAssignments

verify:

1. principal
2. principal type
3. scope
4. role definition
5. minimum required permission
6. deterministic role-assignment name
7. cross-subscription implications

Never automatically grant:

- Owner
- Contributor
- User Access Administrator

just to make deployment succeed.

Apply least privilege.

---

# Role Assignment IDs

Use documented deterministic patterns where role assignment names need stable GUIDs.

Do not generate unstable identifiers that cause role assignments to be recreated.

Never guess role definition IDs.

Verify built-in Azure role definitions using current Microsoft documentation.

---

# Managed Identity

Prefer managed identity when supported.

Distinguish:

- system-assigned managed identity
- user-assigned managed identity
- Microsoft Entra service principal
- workload identity federation

Do not replace one identity model with another during an unrelated fix.

When assigning identities verify:

- identity creation
- principal ID availability
- RBAC propagation
- resource dependency
- target scope

---

# Key Vault

Treat Key Vault changes as security-sensitive.

Check:

- RBAC authorization
- legacy access policies
- private endpoints
- public network access
- firewall
- soft delete
- purge protection
- diagnostic settings
- deployment identity

Never resolve deployment access by automatically:

- enabling public access
- disabling firewall
- broadening network rules
- granting Owner
- exposing secrets

Identify the exact failing identity first.

---

# Storage Accounts

Before changing Storage Account security verify:

- public network access
- HTTPS-only requirement
- minimum TLS version
- shared key access
- blob public access
- firewall
- network ACLs
- private endpoints
- private DNS
- identity-based access
- encryption

Do not weaken security merely to make deployment succeed.

---

# Azure Container Registry

For ACR check:

- SKU
- public network access
- admin account
- managed identity
- RBAC
- AcrPull
- AcrPush
- private endpoints
- private DNS
- network rules

Do not enable:

    adminUserEnabled: true

as a shortcut around proper authentication.

---

# AKS

For AKS Bicep modifications verify:

- Kubernetes version
- identity model
- OIDC issuer
- workload identity
- Azure RBAC
- networking
- network plugin
- network policy
- node pools
- VM SKU
- subnet
- private cluster
- API server access
- ACR integration
- DNS
- availability zones

Do not recreate an AKS cluster merely to solve a localized configuration issue.

Treat changes that force cluster replacement as high risk.

---

# App Service

For App Service resources distinguish correctly among:

- App Service plan
- Linux web app
- Windows web app
- Function App
- deployment slots
- private endpoint
- VNet integration
- managed identity
- application settings
- connection strings

Do not apply Linux-specific schema to a Windows resource or vice versa.

Check the exact resource reference.

---

# Azure Networking

Treat networking as high-impact infrastructure.

Before modifying:

- virtual networks
- subnets
- Network Security Groups
- route tables
- Azure Firewall
- NAT Gateway
- Application Gateway
- load balancers
- public IPs
- private endpoints
- Private DNS
- peering
- DNS resolvers

understand existing topology.

Never solve a network problem by automatically opening:

    0.0.0.0/0

or unrestricted inbound access.

---

# Subnets

Before changing a subnet check:

- address prefix
- existing resources
- delegation
- private endpoints
- service endpoints
- NSG
- route table
- NAT Gateway
- private endpoint network policy
- service requirements

Subnet changes can have significant blast radius.

Do not recreate subnets casually.

---

# Private Endpoints

For private endpoint failures verify:

1. target resource
2. private-link subresource/group ID
3. subnet
4. private DNS zone
5. DNS zone group
6. VNet links
7. approval state
8. public network access
9. DNS resolution

Do not automatically re-enable public access when private connectivity fails.

---

# Azure Firewall

When changing Azure Firewall verify:

- firewall SKU
- policy
- IP configuration
- public IP
- subnet
- routing
- rule collection groups
- priorities
- DNS proxy settings
- threat intelligence
- network/application rules

Do not add broad allow-any rules as a debugging shortcut.

---

# Azure Policy

When deployment fails because of Azure Policy:

DO NOT bypass or remove organizational policy.

Identify:

- policy assignment
- policy definition
- effect
- denied property
- allowed locations
- required tags
- SKU restrictions
- networking restrictions

Modify infrastructure to comply when appropriate.

---

# Resource Locks

If deployment fails because of resource locks:

Identify:

- lock level
- lock scope
- ownership
- reason for existence

Do not automatically delete locks.

Locks may intentionally protect production infrastructure.

---

# Deployment Scripts

Use deployment scripts only when declarative Bicep cannot reasonably perform the
required operation.

Do not use deployment scripts as a workaround for poor infrastructure modeling.

Before creating one:

1. Verify that Bicep/ARM cannot perform the operation directly.
2. Verify identity and permissions.
3. Avoid secrets in command lines.
4. Ensure idempotency.
5. Ensure cleanup behavior.
6. Minimize external dependencies.

Deployment scripts should be exceptional, not default.

---

# Extensions

When using Bicep extensibility or provider features:

Check current Microsoft documentation.

Do not introduce experimental or preview extension features into production
infrastructure without verifying organizational acceptance and runtime support.

---

# Complete vs Incremental Behavior

Treat destructive deployment semantics with extreme caution.

Do not change deployment mode or deployment-stack ownership behavior casually.

If Complete-mode-like behavior, deployment stacks, or resource deletion semantics are
involved, explicitly identify the deletion risk.

Never recommend destructive deployment behavior merely to clean up drift.

---

# Deployment Stacks

Deployment stacks can manage resource lifecycle and cleanup behavior.

Before modifying a deployment stack inspect:

- deployment scope
- managed resources
- deny settings
- actionOnUnmanage
- excluded principals
- excluded actions
- deletion behavior

Treat:

    actionOnUnmanage

as potentially destructive.

Never change deployment stack lifecycle policy without identifying which resources can
be deleted or detached.

---

# Deployment History

Remember Azure deployment history can retain:

- parameter information
- outputs
- deployment metadata

This is one reason secret material must not be placed into outputs.

Do not assume something is safe because it is not printed in pipeline logs.

---

# What-If

Use Azure what-if for significant infrastructure changes when environment access is
available.

Depending on scope, use the appropriate deployment command.

Resource-group example:

    az deployment group what-if \
      --resource-group <resource-group> \
      --template-file main.bicep \
      --parameters <parameter-file>

Do not blindly copy this command for subscription, management-group, or tenant scope.

Choose the correct deployment command for the template's target scope.

---

# What-If Interpretation

What-if is a change preview.

Review it for:

- Create
- Modify
- Delete
- Deploy
- Ignore
- NoChange

Do not interpret a successful what-if as proof that the deployment is operationally
safe.

Investigate unexpected:

- deletion
- modification
- replacement-like behavior
- security changes
- public exposure
- RBAC changes
- networking changes

STOP before deployment if the planned changes are materially different from intent.

---

# Validation

Compilation, ARM validation, and what-if answer different questions.

Do not treat them as interchangeable.

Preferred flow:

    Bicep source
        ↓
    Linter
        ↓
    Bicep build
        ↓
    ARM deployment validation
        ↓
    What-if
        ↓
    Human/change review
        ↓
    Deployment

Use the appropriate validation scope.

---

# Azure CLI Deployment

Before modifying Azure CLI deployment commands determine target scope.

Examples include:

    az deployment group
    az deployment sub
    az deployment mg
    az deployment tenant

Do not substitute one scope command for another.

Verify CLI arguments against current Microsoft Azure CLI documentation.

---

# Azure PowerShell Deployment

When PowerShell is used, distinguish the relevant deployment command by scope.

Do not translate Azure CLI arguments mechanically into PowerShell parameters.

Check current Microsoft documentation.

---

# Azure DevOps Pipelines Integration

When Bicep deployment occurs in Azure Pipelines, troubleshoot separate layers:

1. YAML
2. template expansion
3. parameters
4. agent
5. service connection
6. Azure CLI/PowerShell
7. Bicep CLI
8. Bicep build
9. Bicep validation
10. Azure authentication
11. Azure RBAC
12. Azure Policy
13. Bicep/ARM deployment

Do not modify Bicep if the actual failure is Azure DevOps YAML or agent configuration.

---

# Azure DevOps Service Connections

When Bicep deployment fails from Azure DevOps:

Check:

- service connection name
- service connection type
- identity
- tenant
- subscription
- scope
- pipeline authorization
- Azure RBAC
- workload identity federation
- network restrictions

Do not embed Azure credentials into Bicep to bypass a service-connection problem.

---

# Authentication

Distinguish:

- Azure CLI local login
- Azure DevOps service connection
- service principal
- managed identity
- workload identity federation
- GitHub OIDC
- deployment identity

Do not change authentication architecture without need.

Prefer secretless authentication when supported and appropriate.

---

# GitHub Actions Integration

When Bicep is deployed from GitHub Actions:

Prefer current Microsoft-supported authentication patterns.

OIDC/federated identity is generally preferable to persistent client secrets when
supported.

Do not introduce stored client secrets simply because an older example uses them.

---

# Resource Replacement and Data Loss

Bicep itself does not expose Terraform-style replacement plans in source code.

Therefore always inspect the deployment preview and Azure service behavior.

Treat modifications to stateful resources carefully, including:

- databases
- storage
- disks
- Key Vault
- AKS
- networking
- private endpoints
- managed identities
- public IPs

Never assume changing a property is an in-place operation.

Check Azure resource documentation.

---

# Idempotency

Infrastructure deployments should be repeatable.

Avoid patterns causing different resources or values on every deployment unless
intentional.

Be careful with:

- utcNow()
- newGuid()
- deployment scripts
- unstable naming
- dynamic external state

Use nondeterministic functions only within documented constraints.

---

# Naming Determinism

Prefer deterministic names when appropriate.

When using:

    uniqueString()

understand the scope/input determining the result.

Do not change the seed casually because that may change resource names.

Changing a resource name may create an entirely different Azure resource.

---

# Hard-Coded Environment Values

Avoid unnecessarily hard-coded:

- tenant IDs
- subscription IDs
- environment-specific resource groups
- regions
- endpoints
- URLs
- environment names

But do not over-parameterize constant architectural values.

Use parameters where variation is genuinely required.

---

# Public Cloud vs Sovereign Clouds

Do not assume all Azure environments use the same endpoints.

When the organization targets sovereign clouds, verify:

- Azure environment
- service endpoints
- authentication endpoint
- resource manager endpoint
- service availability

Do not hard-code public Azure URLs unnecessarily.

---

# Security Review

Before completing Bicep changes inspect for:

- hard-coded credentials
- secret outputs
- public network exposure
- anonymous access
- broad NSG rules
- excessive RBAC
- Key Vault exposure
- ACR admin enablement
- public storage
- weak TLS
- unnecessary public IPs
- disabled authentication
- disabled firewall
- disabled private networking
- insecure deployment scripts

Do not weaken security merely to make deployment succeed.

---

# Production Safety

Assume infrastructure may affect production unless context clearly indicates otherwise.

For potentially destructive changes:

STOP.

Identify the impact explicitly.

Do not casually change:

- database configuration
- persistent storage
- networking
- DNS
- identity
- RBAC
- Key Vault
- private endpoints
- production AKS
- resource locks
- Azure Policy
- deployment stacks

when diagnosing an unrelated problem.

---

# No Overengineering

Prefer straightforward declarative infrastructure.

Avoid:

- unnecessary modules
- unnecessary variables
- unnecessary parameters
- unnecessary outputs
- unnecessary dependencies
- unnecessary loops
- unnecessary conditions
- unnecessary deployment scripts
- unnecessary abstractions
- unnecessary resource ID construction
- unnecessary transformations

If direct Bicep is clearer, use direct Bicep.

Do not convert a 20-line resource definition into several modules simply because
modularization is possible.

---

# Comments

Preserve comments explaining:

- architecture
- business requirements
- security restrictions
- Azure limitations
- deliberate workarounds
- unusual API behavior

Avoid comments merely restating Bicep syntax.

Do not flood Bicep files with AI-generated commentary.

---

# Refactoring Rules

When refactoring Bicep:

Preserve:

- resource names
- scopes
- parameter contracts
- module interfaces
- outputs consumed elsewhere
- identity
- RBAC
- networking
- API behavior
- deployment behavior

Remove when safe:

- unused variables
- unused parameters
- unused imports
- redundant expressions
- obsolete comments
- unnecessary dependsOn
- unnecessary interpolation
- duplicated expressions

Do not mix large refactoring with an emergency deployment fix.

---

# Minimal Change Principle

For production troubleshooting:

Change only what is required.

Do not:

- upgrade every API version
- upgrade every module
- rename symbolic resources
- restructure all modules
- reformat unrelated files
- change subscription layout
- change regions
- change identities
- change RBAC
- change networking
- change deployment strategy

unless directly required.

Prefer small, reviewable diffs.

---

# Git Diff Review

Before finalizing Bicep modifications, inspect:

    git diff -- '*.bicep' '*.bicepparam' 'bicepconfig.json'

Check:

- unexpected resource deletion
- renamed Azure resources
- changed resource types
- changed API versions
- changed locations
- changed SKUs
- changed identity
- changed RBAC
- changed networking
- changed public access
- changed parameters
- changed module versions
- secret exposure
- unrelated formatting

Remove unrelated changes.

---

# Validation Workflow

For modified Bicep:

## Step 1: Lint and compile

Use:

    az bicep build --file <entrypoint>.bicep

Resolve meaningful compiler and linter findings.

## Step 2: Check deployment scope

Determine whether deployment is:

- resource group
- subscription
- management group
- tenant

## Step 3: Validate

Use the corresponding current Azure deployment validation command.

Do not guess scope-specific CLI syntax.

Verify with current Microsoft documentation.

## Step 4: What-if

For meaningful infrastructure changes, perform what-if where access permits.

Review every unexpected:

- Create
- Modify
- Delete

## Step 5: Security Review

Check:

- networking
- identities
- RBAC
- secrets
- public access
- encryption
- Key Vault
- resource exposure

## Step 6: Deploy

Only recommend deployment after the expected changes are understood.

---

# Emergency Fix Workflow

When the user provides a failing pipeline or deployment and asks for a fix:

DO NOT redesign the infrastructure.

Follow:

    Error
      ↓
    Exact Bicep/ARM resource
      ↓
    Current API version
      ↓
    Microsoft Learn resource reference
      ↓
    Root cause
      ↓
    Smallest code change
      ↓
    Bicep build
      ↓
    Azure validation
      ↓
    What-if if appropriate
      ↓
    Deployment

Focus on restoring correct deployment behavior first.

Refactoring can happen separately.

---

# Troubleshooting Response Format

When explaining a Bicep failure, prefer:

## Root Cause

State the actual likely cause concisely.

## Evidence

Identify the relevant compiler, ARM, Azure API, pipeline, or deployment error.

## Microsoft Documentation Verification

Identify the Microsoft documentation or official source supporting the diagnosis.

## Minimal Fix

Show the smallest Bicep change required.

## Validation

Provide exact validation steps appropriate to the deployment scope.

## Expected Result

Explain what should happen after the fix.

## Risk

Call out destruction, replacement, networking, RBAC, security, or downtime risk when
material.

Do not bury the actual fix under generic Bicep explanations.

---

# When Information Is Missing

Never invent:

- subscription IDs
- tenant IDs
- resource groups
- Azure regions
- resource names
- Key Vault names
- ACR names
- AKS names
- subnet IDs
- service connection names
- principal IDs
- role IDs
- credentials
- API versions

Reuse repository values when clearly available.

If a value cannot safely be determined, preserve the existing configuration or use an
obvious placeholder.

Never fabricate production infrastructure details.

---

# Microsoft Documentation Verification Checklist

Before making a significant correction, determine whether current Microsoft
documentation needs to be checked for:

- Bicep syntax
- compiler behavior
- linter rule
- resource provider
- resource type
- API version
- property
- module behavior
- module version
- deployment scope
- existing resource
- networking
- RBAC
- identity
- Key Vault
- policy
- deployment stack
- Azure CLI deployment
- Azure PowerShell deployment

Research only what is relevant to the actual problem.

---

# GitHub Verification

When Microsoft Learn does not provide enough implementation detail, inspect
Microsoft-owned repositories.

Prioritize:

1. Azure/bicep
2. Azure/bicep-registry-modules
3. Other relevant Azure/Microsoft repositories
4. Official repositories for integrated technologies

Before using repository code:

1. Verify repository owner.
2. Check whether it is archived.
3. Check recent maintenance.
4. Check version compatibility.
5. Compare with current Microsoft Learn documentation.

Never treat an arbitrary GitHub implementation as authoritative.

---

# Final Safety Checklist

Before accepting a Bicep change, check:

- Does it compile?
- Does the linter pass relevant checks?
- Is the resource type valid?
- Is the API version verified?
- Are properties valid for that API version?
- Is the deployment scope correct?
- Are module scopes correct?
- Are resource names preserved?
- Is location preserved?
- Is resource identity preserved?
- Are dependencies correct?
- Are parameters correct?
- Are outputs safe?
- Are secrets protected?
- Is RBAC least privilege?
- Is public exposure unchanged or explicitly intended?
- Is networking behavior understood?
- Are Key Vault controls preserved?
- Are policies respected?
- Are resource locks respected?
- Are deployment-stack deletion semantics understood?
- Has what-if been reviewed when appropriate?
- Does the Git diff contain only intended changes?

---

# Final Rules

Always:

1. Read the exact error.
2. Identify the first meaningful failure.
3. Identify the correct deployment layer.
4. Understand the existing architecture.
5. Check current Microsoft Learn documentation.
6. Check the exact Bicep resource reference.
7. Verify the exact API version.
8. Never invent resource properties.
9. Never invent API versions.
10. Never invent Azure CLI arguments.
11. Never invent RBAC roles.
12. Prefer symbolic resource references.
13. Prefer implicit dependencies.
14. Use existing resources correctly.
15. Preserve module contracts.
16. Protect secrets.
17. Never output secrets.
18. Preserve security controls.
19. Use least privilege.
20. Protect networking.
21. Respect Azure Policy.
22. Respect resource locks.
23. Be cautious with stateful resources.
24. Do not introduce preview APIs unnecessarily.
25. Do not upgrade modules unnecessarily.
26. Do not hide linter findings without justification.
27. Do not redesign working infrastructure during a bug fix.
28. Make the smallest correct change.
29. Build before deployment.
30. Validate against Azure when appropriate.
31. Run what-if for consequential infrastructure changes.
32. Review the final diff.
33. Stop on unexpected destructive changes.

When multiple implementations are valid, choose the implementation that:

- follows current Microsoft documentation
- uses supported Azure resource APIs
- matches the existing repository architecture
- makes the smallest change
- preserves deployed infrastructure
- maintains least privilege
- maintains network security
- does not expose secrets
- introduces the least complexity
- is easiest to validate
- is easiest to review
- is safest to deploy through Azure DevOps

Never solve a localized Bicep deployment failure by unnecessarily redesigning the
Azure infrastructure.
