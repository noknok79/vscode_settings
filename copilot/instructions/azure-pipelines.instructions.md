---
applyTo: "**/azure-pipelines.yml,**/azure-pipelines.yaml,**/*pipeline*.yml,**/*pipeline*.yaml,**/pipelines/**/*.yml,**/pipelines/**/*.yaml"
---

# Azure DevOps Pipelines Engineering, Troubleshooting, and Refactoring Instructions

These instructions apply whenever creating, reviewing, debugging, fixing,
optimizing, or refactoring Azure DevOps YAML pipelines.

The primary objectives are:

1. Correctness
2. Root-cause resolution
3. Minimal changes
4. Security
5. Reliability
6. Maintainability
7. Current Microsoft-supported syntax
8. Predictable CI/CD behavior

Do not optimize for generating more code.

Do not rewrite a pipeline unnecessarily.

# Golden Rule

NEVER GUESS AZURE PIPELINES SYNTAX OR BEHAVIOR.

Before changing Azure Pipelines YAML:

1. Read the existing pipeline completely enough to understand the affected flow.
2. Read the exact error message when one is available.
3. Identify the failing stage, job, step, task, template, expression, script, or external service.
4. Determine when the failure occurs.
5. Determine the smallest likely root cause.
6. Check current Microsoft Learn documentation.
7. Check the Azure Pipelines YAML schema when YAML structure is involved.
8. Check the official Azure Pipelines task reference when a task is involved.
9. Check current Microsoft-owned GitHub repositories when implementation examples or task behavior need additional verification.
10. Check official technology documentation when Terraform, Bicep, Docker, Kubernetes, Azure CLI, PowerShell, Node, Python, .NET, or another tool is involved.
11. Compare the documentation against the repository's existing implementation.
12. Make the smallest safe correction.
13. Validate the final YAML and affected scripts.
14. Review the final diff for unintended changes.

Never make speculative edits merely because they might solve the problem.

# Source Priority

When researching Azure Pipelines behavior, use sources in this order:

1. Microsoft Learn Azure DevOps documentation
2. Microsoft Learn Azure Pipelines YAML schema
3. Microsoft Learn Azure Pipelines task reference
4. Microsoft Azure documentation
5. Microsoft-owned Azure DevOps GitHub repositories
6. MicrosoftDocs GitHub repositories
7. Official repository/documentation for the integrated technology
8. Official vendor documentation
9. Mature and actively maintained public GitHub repositories
10. Community sources only when official sources do not answer the question

When official documentation and a GitHub example conflict, prefer current official
Microsoft documentation unless there is strong evidence of a documented product issue.

Do not blindly copy YAML from:

- Stack Overflow
- Reddit
- blogs
- tutorials
- old Microsoft blog posts
- archived GitHub repositories
- random GitHub repositories
- AI-generated examples

Community examples are supporting evidence, not authoritative documentation.

Check publication/update dates when behavior may have changed.

# Version Awareness

Azure DevOps Services changes over time.

When documentation provides a version selector, determine whether the pipeline uses:

- Azure DevOps Services
- Azure DevOps Server
- Azure DevOps Server 2022
- another supported on-premises version

Do not assume a feature available in Azure DevOps Services exists in an older
Azure DevOps Server installation.

Check current task and agent behavior before recommending changes.

# Problem Classification

Before modifying the pipeline, classify the failure.

Possible categories include:

- YAML syntax
- YAML indentation
- YAML schema
- template expansion
- compile-time expression
- runtime expression
- macro variable
- variable group
- parameter
- output variable
- dependency
- condition
- trigger
- PR trigger
- repository checkout
- Git authentication
- submodules
- Git LFS
- agent initialization
- hosted agent image
- self-hosted agent
- missing tool
- PATH
- working directory
- file permissions
- Bash
- PowerShell
- Azure CLI
- Azure authentication
- service connection
- workload identity federation
- Azure RBAC
- Key Vault
- ACR
- AKS
- App Service
- Terraform
- Bicep
- ARM
- Docker
- Kubernetes
- artifact publishing
- artifact downloading
- caching
- test failure
- deployment failure
- Azure API failure
- networking
- DNS
- Azure Policy
- quota
- timeout
- environment approval
- exclusive lock
- concurrency

Fix the appropriate layer.

Do not treat every Azure Pipelines error as a YAML problem.

# Error-First Troubleshooting

When the user provides logs:

DO NOT immediately rewrite the YAML.

Use this sequence:

    Exact error
        ↓
    First meaningful failure
        ↓
    Stage
        ↓
    Job
        ↓
    Step/task
        ↓
    Failure category
        ↓
    Root cause
        ↓
    Documentation verification
        ↓
    Minimal fix
        ↓
    Validation
        ↓
    Diff review

Prioritize the first meaningful error.

Later errors may only be consequences of the original failure.

Do not fix unrelated warnings unless they contribute to the actual failure.

# Failure Phase

Determine where the failure happens.

## Pipeline parsing

Examples:

- invalid YAML
- unexpected mapping
- incorrect indentation
- duplicate key
- malformed sequence

## Template compilation

Examples:

- unexpected parameter
- missing template
- incorrect parameter type
- invalid template expression
- unavailable compile-time variable

## Pipeline runtime

Examples:

- condition evaluation
- missing runtime variable
- output variable unavailable
- stage dependency issue

## Agent initialization

Examples:

- pool unavailable
- demand not satisfied
- agent offline
- agent capability missing

## Checkout

Examples:

- Git authentication
- shallow clone
- repository permissions
- submodules
- Git LFS

## Task execution

Examples:

- incorrect task input
- unsupported task version
- missing executable
- incorrect working directory

## Azure operation

Examples:

- authentication
- RBAC
- Azure Policy
- resource state
- network access
- quota
- Azure API validation

Diagnosis must correspond to the actual failure phase.

# Minimal Change Principle

When repairing an existing pipeline:

PRESERVE:

- pipeline architecture
- stage names
- job names
- deployment job names
- step names when referenced
- variables
- variable groups
- parameters
- template contracts
- service connections
- environments
- agent pools
- artifact names
- artifact paths
- working directories
- branch behavior
- trigger behavior
- output-variable contracts
- security controls

unless one of those elements is the actual problem.

Do not:

- rewrite the entire YAML
- rename working objects
- reorganize unrelated stages
- refactor unrelated templates
- change formatting everywhere
- modify unrelated scripts
- add unnecessary variables
- introduce new templates unnecessarily
- change service connections unnecessarily
- change agent pools unnecessarily
- upgrade every task unnecessarily

Prefer:

    smallest failing section
        ↓
    smallest valid correction
        ↓
    validate

# Azure Pipelines YAML Structure

Before adding or moving YAML elements, verify their schema location.

Pay particular attention to:

- trigger
- pr
- schedules
- resources
- parameters
- variables
- pool
- stages
- stage
- jobs
- job
- deployment
- strategy
- steps
- task
- script
- bash
- powershell
- pwsh
- checkout
- download
- publish
- template
- extends
- condition
- dependsOn
- environment

Never invent YAML properties.

Never assume similarly named GitHub Actions, GitLab CI, Jenkins, or CircleCI syntax
works in Azure Pipelines.

# YAML Formatting

Use spaces.

Never use tabs for YAML indentation.

Prefer consistent 2-space indentation unless the repository already follows another
valid convention.

When fixing logic, avoid unrelated repository-wide formatting changes.

Do not reorder working YAML merely for aesthetics.

# Expressions

Azure Pipelines expression forms are NOT interchangeable.

Always identify which expression type is required.

## Template / compile-time expressions

    ${{ ... }}

Use when the value must be known during template expansion or pipeline compilation.

Compile-time expressions can work with parameters and statically available values.

## Runtime expressions

    $[ ... ]

Use for runtime expression evaluation, particularly variables and conditions where
runtime context is required.

Runtime expression context differs from compile-time context.

## Macro variables

    $(variableName)

Macro variables are generally expanded for task execution.

## Environment variables

Bash:

    $VARIABLE
    ${VARIABLE}

PowerShell:

    $env:VARIABLE

Do not confuse these forms.

Before changing any expression, ask:

1. When must this value exist?
2. Is it known at compile time?
3. Is it known only at runtime?
4. Is it a template parameter?
5. Is it a pipeline variable?
6. Is it an output variable?
7. Is it an environment variable?
8. Is it generated by another job?
9. Is it generated by another stage?

Microsoft documents `${{ }}` as compile-time and `$[]` as runtime syntax, with
different available contexts. Do not substitute one for another mechanically.

# Parameters vs Variables

Parameters and variables have different purposes.

Parameters are primarily compile-time constructs.

Variables can participate in runtime behavior.

Do not convert between a parameter and variable unless evaluation timing supports it.

Before changing one, understand:

- type
- default
- source
- scope
- evaluation time
- consumer
- whether it contains sensitive information

Parameters should not be used for secrets.

# Conditions

Before changing `condition:`, check current Microsoft Learn expression and condition
documentation.

Understand these functions when relevant:

    succeeded()
    failed()
    always()
    succeededOrFailed()
    canceled()

Preserve existing success/failure semantics.

Remember that overriding a default condition can unintentionally cause jobs or stages
to run in situations where they previously would not.

Avoid unnecessary nested:

    and()
    or()
    not()

Prefer the simplest documented expression that preserves behavior.

# Branch Conditions

Never guess branch variable formats.

Pay attention to:

    Build.SourceBranch
    Build.SourceBranchName

Azure Pipelines branch references may use forms such as:

    refs/heads/main

Verify which variable is being compared before changing the condition.

Do not compare:

    Build.SourceBranch

against:

    main

when the existing semantics require:

    refs/heads/main

unless documentation and context confirm otherwise.

# Dependencies and dependsOn

Do not add `dependsOn` merely because two stages appear sequential.

Understand Azure Pipelines default dependencies first.

Before changing `dependsOn`, inspect:

- stage dependency
- job dependency
- condition
- output variables
- failure propagation

Removing or changing dependencies can alter execution concurrency and condition
behavior.

# Output Variables

Output variables require careful syntax and scope handling.

Before changing an output variable:

1. Identify the step setting it.
2. Check whether the step has a `name`.
3. Verify `isOutput=true` when required.
4. Identify the consuming job/stage.
5. Verify `dependencies` or `stageDependencies`.
6. Verify compile-time/runtime syntax.
7. Verify variable scope.

Never guess output-variable reference syntax.

# Templates

Azure Pipelines supports multiple template patterns.

Distinguish between:

- include templates
- extends templates
- stage templates
- job templates
- step templates
- variable templates

Microsoft documents include and extends templates as different mechanisms.

Include templates insert reusable content.

Extends templates can define and enforce pipeline structure.

Do not treat them as equivalent.

# Template Parameters

For each template parameter:

Verify:

- name
- type
- default
- accepted values
- calling location
- consuming expression

Common types can include:

- string
- boolean
- number
- object
- step
- stepList
- job
- jobList
- stage
- stageList

Do not pass runtime values into places requiring compile-time template values without
verifying support.

# Template Paths

When a template cannot be found:

Check:

- repository root
- relative path
- calling YAML location
- repository resource
- alias
- ref
- branch
- checkout
- path case sensitivity

Do not blindly prefix paths with additional `../`.

# Cross-Repository Templates

When templates come from another repository:

Verify:

- resources.repositories
- repository alias
- endpoint/service connection
- repository name
- ref
- template syntax
- permissions

Preserve pinned references when reproducibility/security requires them.

Do not automatically switch templates to `main` or another floating branch.

# Tasks

Before modifying any Azure Pipelines task:

1. Identify the exact task.
2. Identify the exact major version.
3. Open current Microsoft task documentation.
4. Verify every modified input.
5. Verify required inputs.
6. Verify optional inputs.
7. Verify defaults.
8. Verify task platform support.
9. Verify authentication method.
10. Check deprecation notices.
11. Check whether the task version is supported.

Never invent a task input.

Do not assume input names from one task apply to another.

Do not assume inputs supported by one major version exist in another.

Examples requiring documentation checks include:

- AzureCLI
- AzurePowerShell
- Bash
- PowerShell
- Docker
- DockerCompose
- Kubernetes
- KubernetesManifest
- HelmDeploy
- AzureWebApp
- AzureRmWebAppDeployment
- DotNetCoreCLI
- UseDotNet
- NodeTool
- PublishPipelineArtifact
- DownloadPipelineArtifact
- PublishBuildArtifacts
- DownloadBuildArtifacts
- Cache
- Terraform-related extension tasks

# Task Version Upgrades

Do not upgrade a task simply because a newer major version exists.

Before upgrading:

1. Check documentation.
2. Check release notes.
3. Check breaking changes.
4. Check removed inputs.
5. Check new defaults.
6. Check agent requirements.
7. Check whether the existing integration depends on old behavior.

Upgrade only when:

- required for compatibility
- required for security
- existing version is deprecated/retired
- explicitly requested
- necessary for the fix

# Script Steps

For:

    bash:
    script:
    powershell:
    pwsh:

distinguish Azure Pipelines YAML problems from script-language problems.

Do not rewrite a Bash script because the YAML task configuration is incorrect.

Do not rewrite PowerShell because the Azure service connection lacks RBAC.

Fix the correct layer.

# Bash

For Bash steps:

- Preserve existing behavior.
- Prefer straightforward Bash.
- Avoid excessive defensive logic.
- Check quoting.
- Check exit codes.
- Check working directory.
- Check executable availability.
- Use `bash -n` when possible.
- Use ShellCheck when possible.

Do not add unnecessary wrappers or try/catch-style logic.

# PowerShell

For PowerShell steps:

- Identify PowerShell versus PowerShell Core.
- Distinguish `powershell` from `pwsh`.
- Preserve error behavior.
- Verify Az module requirements.
- Check `$LASTEXITCODE` when external commands are involved.
- Check `$ErrorActionPreference` assumptions.
- Do not add elaborate exception handling without need.

# Working Directories

Before changing paths:

Inspect:

    $(Build.SourcesDirectory)
    $(Build.Repository.LocalPath)
    $(System.DefaultWorkingDirectory)
    $(Pipeline.Workspace)
    $(Agent.BuildDirectory)

Do not assume these locations are interchangeable.

When a command reports:

    file not found
    directory not found

verify the actual checkout and working-directory configuration before changing file
paths.

# Repository Checkout

Before modifying checkout behavior, inspect current Microsoft documentation.

Relevant options can include:

- clean
- fetchDepth
- fetchFilter
- fetchTags
- lfs
- persistCredentials
- submodules
- path
- sparseCheckoutDirectories
- sparseCheckoutPatterns
- workspaceRepo

Do not enable:

    persistCredentials: true

unless subsequent Git operations genuinely require the credentials.

Microsoft's checkout schema says the default is not to leave the OAuth token in Git
configuration.

# Shallow Fetch

When Git history or tags are missing, check:

    fetchDepth
    fetchTags

before rewriting Git commands.

Commands requiring Git history can fail on shallow repositories.

Do not automatically use:

    fetchDepth: 0

unless full history is actually required.

# Multiple Repositories

When multiple repositories are checked out:

Check:

- resources.repositories
- repository aliases
- checkout steps
- checkout path
- default working directory
- template paths

Do not assume all repositories live directly under the same source directory layout.

# Agents

Always determine whether the pipeline uses:

- Microsoft-hosted agent
- self-hosted agent
- Managed DevOps Pool
- container job

Agent type materially affects troubleshooting.

# Microsoft-Hosted Agents

Do not assume tools persist between jobs or pipeline runs.

Check currently supported images and installed software when tool availability matters.

Do not assume an executable exists merely because an old pipeline example uses it.

# Self-Hosted Agents

Check:

- agent status
- version
- OS
- architecture
- capabilities
- demands
- PATH
- installed tooling
- permissions
- workspace state
- disk space
- Docker access
- network access
- proxy
- certificates

Do not automatically modify YAML when the actual problem is agent configuration.

# Agent Pools

Do not change:

    pool:
    vmImage:
    demands:

without understanding why the existing configuration fails.

Changing an agent pool can create:

- tool differences
- network differences
- security differences
- performance differences
- licensing/capacity differences
- access differences

# Authentication

Always distinguish between:

- Azure DevOps identity
- Azure service connection
- Azure Resource Manager authentication
- service principal
- managed identity
- workload identity federation
- System.AccessToken
- PAT
- Azure CLI login
- Terraform provider authentication
- Terraform backend authentication
- Kubernetes authentication
- ACR authentication

These are not interchangeable.

# Service Connections

When troubleshooting a service connection:

Check:

1. service connection type
2. authentication mechanism
3. identity
4. tenant
5. subscription
6. scope
7. pipeline authorization
8. Azure RBAC
9. service connection permissions
10. network/access restrictions

Do not recreate a service connection immediately.

Identify why the current connection fails first.

# Workload Identity Federation

Prefer secretless authentication when supported and appropriate.

Microsoft currently documents Microsoft Entra workload identity-based service
connections as a way to avoid PATs or persistent secrets.

Do not convert existing authentication architecture during an unrelated bug fix unless
requested.

When designing a new Azure authentication flow, prefer:

- workload identity federation
- managed identities

over long-lived secrets when supported.

# Service Connection Security

Apply least privilege.

Do not automatically:

- grant Owner
- grant Contributor at subscription scope
- authorize a service connection to every pipeline
- expose credentials to arbitrary scripts
- enable broad permissions

Determine the minimum required scope.

# Secrets

Never print:

- PATs
- client secrets
- passwords
- storage keys
- private keys
- access tokens
- refresh tokens
- SAS tokens
- connection strings
- service principal secrets

Do not place secrets directly in YAML.

Do not echo secret variables for troubleshooting.

Prefer:

- secret variables
- variable groups
- Azure Key Vault
- service connections
- workload identity federation
- managed identity

# Variable Groups

When a pipeline references:

    variables:
    - group: ...

verify:

- variable group existence
- authorization
- variable names
- secret handling
- pipeline permissions

Do not duplicate variable-group values into YAML merely to bypass a permissions
problem.

# Azure Key Vault

When Key Vault is involved, distinguish:

- service connection authentication
- Azure RBAC
- Key Vault access policies
- Key Vault RBAC
- firewall
- private endpoint
- DNS
- public network access
- pipeline identity

Do not solve Key Vault access by disabling security controls.

Never expose retrieved secrets in logs.

# Azure RBAC

For authorization failures:

1. Identify the caller.
2. Identify the exact denied action.
3. Identify the Azure resource scope.
4. Check role assignments.
5. Determine minimum required permission.
6. Check Microsoft documentation.
7. Consider propagation delay when applicable.

Do not automatically grant Owner.

Do not automatically grant Contributor at subscription scope.

Use least privilege.

# Azure CLI

For AzureCLI tasks:

Check:

- task version
- service connection
- scriptType
- scriptLocation
- inlineScript
- workingDirectory
- CLI extension requirements
- Azure CLI version
- account/subscription context

Do not manually run `az login` when the AzureCLI task already provides an authenticated
context unless the scenario explicitly requires separate authentication.

# Azure PowerShell

For AzurePowerShell tasks:

Check:

- service connection
- task version
- ScriptType
- ScriptPath
- Inline
- azurePowerShellVersion
- preferredAzurePowerShellVersion
- PowerShell environment
- Az module compatibility

Do not confuse Azure CLI syntax and Azure PowerShell syntax.

# Terraform in Azure Pipelines

When Terraform is executed from Azure Pipelines, troubleshoot at multiple layers:

1. YAML
2. template expansion
3. agent
4. Terraform installation
5. provider installation
6. working directory
7. authentication
8. backend
9. state
10. state locking
11. variables
12. tfvars
13. init
14. validate
15. plan
16. apply

Never assume the Terraform configuration itself is responsible merely because a
Terraform step failed.

# Terraform Authentication

Distinguish:

- Terraform provider authentication
- Terraform backend authentication
- Azure DevOps service connection authentication

Success at one layer does not prove success at another.

# Terraform Safety

When pipeline modifications affect Terraform:

Do not automatically add:

    -auto-approve
    -lock=false
    -target
    lifecycle.ignore_changes

Do not delete state or lock files to force the pipeline through.

Preserve plan/apply separation when already implemented.

Treat unexpected destruction or replacement as blocking.

# Terraform Plan and Apply

Where plan and apply are separate stages:

Preserve:

- saved plan
- artifact
- environment
- approval
- dependency

Do not silently generate a new plan during apply when the workflow expects an approved
saved plan.

# Bicep and ARM

When pipeline deployment uses Bicep or ARM:

Check:

- Azure CLI/Azure PowerShell task
- Bicep CLI availability
- Bicep version
- deployment scope
- resource group/subscription/management group
- parameter files
- service connection
- RBAC
- Azure Policy
- API version

Do not modify Bicep merely because an Azure Pipelines task is incorrectly configured.

# Docker

For Docker pipeline failures:

Distinguish among:

- Docker installation
- Docker daemon
- Dockerfile
- build context
- image tag
- registry authentication
- ACR authorization
- networking
- Docker task configuration
- push permission

Do not automatically rewrite the Dockerfile when authentication is the root cause.

# Azure Container Registry

For ACR:

Check:

- registry name
- login server
- service connection
- managed identity
- workload identity
- AcrPull
- AcrPush
- repository permissions
- firewall
- private endpoint
- DNS

Do not enable the ACR admin account simply to bypass authentication.

# AKS and Kubernetes

For AKS deployment failures, distinguish:

- Azure authentication
- Kubernetes authentication
- cluster RBAC
- Azure RBAC
- manifest syntax
- namespace
- image
- imagePullSecret
- ACR permission
- pod failure
- networking
- ingress
- DNS
- private cluster connectivity

Do not recreate a cluster to fix a localized pipeline/deployment problem.

# App Service

For App Service deployments, check:

- Linux versus Windows
- runtime
- deployment task
- service connection
- subscription
- resource group
- app name
- slot
- package path
- artifact availability
- startup command
- application settings
- networking

Do not swap deployment mechanisms without identifying why the current mechanism fails.

# Artifacts

Distinguish:

- Pipeline Artifacts
- Build Artifacts
- Azure Artifacts packages
- pipeline cache

They are not interchangeable.

Pipeline artifacts are used to move required produced files between jobs/stages or
retain them.

Pipeline caching is a performance optimization for reusable dependency-like content.

Microsoft documentation explicitly distinguishes pipeline artifacts from pipeline
caching.

Do not use a cache as a replacement for an artifact required by another stage.

# Pipeline Cache

Before adding caching:

Determine whether restoring/saving the cache is actually faster than recreating the
content.

Use appropriate keys.

Include dependency lock files when appropriate.

Remember caches are immutable.

Do not use outdated preview caching tasks from archived repositories.

Prefer the supported built-in Cache task.

# Build and Deployment Artifacts

When a downstream stage reports missing artifacts:

Check:

1. artifact was created
2. publishing step executed
3. publishing condition passed
4. artifact name
5. download step
6. download source
7. destination path
8. working directory
9. stage/job dependencies

Do not simply hard-code an alternate path without determining where the artifact was
actually downloaded.

# Environments

When deployment jobs use Azure DevOps environments:

Check:

- environment name
- resource
- permissions
- approvals
- checks
- exclusive locks
- service connection
- deployment strategy

Do not bypass approvals/checks merely to make deployment proceed.

# Approvals and Checks

Treat approvals and checks as security/governance controls.

Do not remove:

- approvals
- branch controls
- required templates
- business-hours checks
- exclusive locks
- Azure Function checks
- REST API checks
- environment protections

merely to fix a pipeline.

Identify why the check is failing.

# Deployment Jobs

For:

    deployment:

verify:

- environment
- strategy
- runOnce
- rolling
- canary
- lifecycle hooks
- artifact availability

Do not replace deployment jobs with ordinary jobs merely to bypass environment
behavior.

# Triggers

Before changing:

    trigger:
    pr:
    schedules:

determine:

- branches
- include
- exclude
- paths
- batch
- repository type
- branch policies
- pipeline-resource triggers

Do not broaden triggers just to make a test run easier.

# PR Pipelines

Do not assume YAML `pr:` behaves identically for every repository/provider setup.

Check repository type and current Azure DevOps documentation.

When Azure Repos Git branch policies control validation, distinguish policy behavior
from YAML trigger behavior.

# Pipeline Resources

For:

    resources:
      pipelines:

check:

- source pipeline
- project
- branch
- trigger
- alias
- permissions

Do not confuse pipeline-resource triggers with repository triggers.

# Repository Resources

For:

    resources:
      repositories:

verify:

- repository type
- name
- ref
- endpoint
- alias
- authentication

Do not guess cross-project or cross-organization permissions.

# Package Management

When npm, NuGet, Maven, Python, or other package restoration fails:

Distinguish:

- Azure Artifacts authentication
- package manager configuration
- feed permissions
- upstream sources
- proxy/network
- lockfile
- package availability
- task configuration

Do not rewrite build tasks when feed authentication is the actual issue.

# Azure Artifacts

Before modifying authentication:

Check current Microsoft-supported authentication mechanisms.

Avoid hard-coded credentials.

Do not expose tokens in `.npmrc`, `nuget.config`, `pip.conf`, or logs.

# Continue on Error

Do not add:

    continueOnError: true

merely to make the pipeline green.

Use it only when failure is intentionally non-blocking.

Never hide a deployment, security, test, Terraform, or validation failure by default.

# Condition always()

Do not add:

    condition: always()

to ordinary build/deployment steps without understanding consequences.

`always()` can cause execution after failures or cancellation conditions that differ
from the original behavior.

Use it primarily for deliberately required cleanup/diagnostic scenarios where
documented behavior matches the requirement.

# Retry Logic

Do not automatically add:

    retryCountOnTaskFailure

or script-level retry loops.

First determine whether the error is genuinely transient.

Do not retry:

- YAML errors
- syntax errors
- authorization failures
- deterministic validation failures
- invalid configuration
- missing required inputs

Retries should not hide root causes.

# Timeouts

Do not immediately increase:

    timeoutInMinutes

when a task times out.

Determine why it is slow or blocked.

Possible causes include:

- networking
- deadlock
- Azure provisioning
- agent capacity
- dependency download
- resource lock
- service problem

Increase timeout only when longer execution is legitimately expected.

# Performance Optimization

Do not optimize before understanding pipeline behavior.

Potential improvements include:

- caching
- shallow checkout
- sparse checkout
- parallel jobs
- template reuse
- artifact optimization
- avoiding repeated dependency installs

But never sacrifice reproducibility or correctness merely to reduce runtime.

# Security Review

Before considering a pipeline change complete, check whether the modification:

- exposes secrets
- weakens RBAC
- broadens service-connection scope
- exposes System.AccessToken
- enables unnecessary persistCredentials
- introduces PATs
- hard-codes credentials
- disables security checks
- bypasses approvals
- opens Azure networking
- enables public access
- disables Key Vault restrictions
- enables ACR admin
- adds excessive Azure permissions

If so, reconsider the implementation.

# No Overengineering

Do not turn a small fix into a pipeline redesign.

Avoid:

- unnecessary templates
- excessive parameters
- wrapper scripts without benefit
- duplicated validation
- excessive retry logic
- unnecessary error handlers
- unnecessary logging
- unnecessary conditions
- speculative fallbacks
- unnecessary stages

If a five-line change safely fixes the problem, do not generate fifty lines.

# Comments

Preserve comments that explain:

- business logic
- deployment requirements
- security constraints
- environment behavior
- workarounds
- unusual Azure behavior

Remove or avoid comments that merely repeat obvious YAML.

Do not flood pipeline files with AI-generated explanation.

# Logging

Add diagnostic output only when useful.

Never log secrets.

When troubleshooting, useful diagnostic commands can include operational context such
as:

    pwd
    ls
    az account show
    terraform version
    docker version
    kubectl version --client

but only when appropriate.

Sanitize sensitive output.

Do not add permanent verbose logging after the issue is resolved unless operationally
valuable.

# Validation

Before considering an Azure Pipeline change complete:

1. Validate YAML syntax.
2. Validate indentation.
3. Validate Azure Pipelines schema.
4. Validate template references.
5. Validate parameter names/types.
6. Validate expression syntax.
7. Validate expression evaluation timing.
8. Validate variables.
9. Validate output variables.
10. Validate conditions.
11. Validate dependencies.
12. Validate task names.
13. Validate task major versions.
14. Validate task inputs.
15. Validate agent compatibility.
16. Validate paths.
17. Validate service connection references.
18. Validate security.
19. Validate artifacts.
20. Review the final Git diff.

# Script Validation

If Bash was modified:

    bash -n script.sh
    shellcheck script.sh

when available.

If Terraform was modified:

    terraform fmt -check -recursive
    terraform init -backend=false
    terraform validate

and when environment access is appropriate:

    terraform plan

If Bicep was modified:

validate/build/lint it with appropriate current Microsoft-supported tooling.

Do not claim validation succeeded unless it actually ran successfully.

# Git Diff Review

Always prefer reviewing:

    git diff

or the affected file:

    git diff -- path/to/file

Before finishing, check:

- Are unrelated files modified?
- Did YAML formatting change unrelated sections?
- Did a variable name change?
- Did a task version unexpectedly change?
- Did a service connection change?
- Did an environment change?
- Did branch behavior change?
- Did artifact names change?
- Did a secret appear?
- Did security weaken?
- Did deployment order change?
- Did a condition change semantics?

Remove unrelated modifications.

# Troubleshooting Response Format

When explaining an Azure Pipeline problem, prefer:

## Root Cause

Identify the actual problem in one or two sentences.

## Evidence

Identify the relevant pipeline line, task output, or error.

## Documentation Verification

State which Microsoft Azure DevOps documentation or official repository confirms the
behavior.

## Fix

Provide the smallest code/configuration change necessary.

## Why This Fix Works

Briefly describe the Azure Pipelines behavior involved.

## Validation

Provide commands or steps to verify the fix.

## Expected Result

State exactly what should change on the next run.

Do not bury the solution under generic DevOps theory.

# When Information Is Missing

Do not invent:

- subscription IDs
- tenant IDs
- resource groups
- service connection names
- variable-group names
- Azure regions
- agent pools
- repository names
- environment names
- Key Vault names
- ACR names
- cluster names
- application names
- credentials
- secrets

Reuse values already present in the repository when clearly identifiable.

If a required value cannot be determined safely, preserve the existing value or use an
obvious placeholder rather than inventing production information.

# Azure Documentation Verification Checklist

Before making a potentially significant pipeline correction, determine whether current
Microsoft documentation needs to be checked for:

- YAML schema
- expressions
- conditions
- variables
- runtime parameters
- templates
- tasks
- triggers
- checkout
- agents
- service connections
- environments
- approvals/checks
- deployment jobs
- artifacts
- cache
- Azure integration

Only research areas relevant to the issue.

# GitHub Verification

When Microsoft Learn alone does not provide sufficient implementation detail, inspect
relevant Microsoft-owned GitHub repositories.

Examples include repositories containing:

- Azure DevOps documentation
- Azure Pipelines agent source
- Azure Pipelines tasks
- Azure Pipelines YAML examples
- Azure SDK integrations

Before using GitHub code as guidance:

1. Check repository owner.
2. Check whether the repository is archived.
3. Check recent maintenance.
4. Check version compatibility.
5. Check task/API versions.
6. Compare against current Microsoft Learn documentation.

Never use an archived implementation as the preferred modern solution when a supported
replacement exists.

# Fix Priority

Always prioritize:

1. Production safety
2. Security
3. Root cause
4. Correctness
5. Existing behavior
6. Minimal change
7. Reliability
8. Maintainability
9. Performance
10. Style

Never prioritize making the pipeline green over security or correctness.

# Final Rules

Always:

1. Read the exact failure.
2. Find the first meaningful error.
3. Identify the failing layer.
4. Understand the existing pipeline.
5. Check current Microsoft documentation.
6. Check YAML schema when appropriate.
7. Check exact task documentation.
8. Cross-check Microsoft GitHub repositories when useful.
9. Never invent Azure Pipeline syntax.
10. Never invent task inputs.
11. Never invent CLI flags.
12. Never invent Azure properties.
13. Distinguish compile time from runtime.
14. Distinguish parameters from variables.
15. Distinguish Azure authentication layers.
16. Preserve service connections.
17. Preserve security controls.
18. Preserve approvals.
19. Protect secrets.
20. Use least privilege.
21. Do not hide errors.
22. Do not blindly retry errors.
23. Do not rewrite working code.
24. Do not perform unrelated refactoring.
25. Make the smallest correct change.
26. Validate affected technologies.
27. Review the final diff.

When multiple solutions are valid, choose the solution that:

- is supported by current Microsoft documentation
- matches the repository's existing architecture
- makes the smallest change
- preserves existing behavior
- preserves security
- avoids new dependencies
- minimizes operational risk
- is easy to review
- is easy to validate
- is maintainable by another DevOps engineer

Never solve a localized Azure Pipeline failure by unnecessarily redesigning the entire
pipeline.
