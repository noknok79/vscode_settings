---
name: technical-documentation
description: Generate and review technical documentation, architecture designs, deployment guides, and operational runbooks from verified engineering sources.
---

# Technical Documentation Skill

## Purpose

Provide a reusable documentation workflow for
software engineering, DevOps, cloud infrastructure,
and operational support.

## Supported Documentation

- README
- Architecture Design Document
- High-Level Design
- Low-Level Design
- CI/CD Pipeline Documentation
- Infrastructure Documentation
- Deployment Runbook
- Troubleshooting Guide
- Standard Operating Procedure
- Disaster Recovery Documentation
- Knowledge Transfer Documentation

## Execution Workflow

### Step 1: Discovery

Inspect relevant repository files, including:

- README files
- YAML pipelines
- Terraform configurations
- Bicep templates
- Kubernetes manifests
- Dockerfiles
- Shell scripts
- Application configuration

### Step 2: Analysis

Identify:

- Architecture
- Components
- Dependencies
- Deployment workflows
- Configuration
- Security controls
- Operational requirements

### Step 3: Documentation

Generate Markdown with:

1. Overview
2. Scope
3. Prerequisites
4. Architecture
5. Components
6. Configuration
7. Procedures
8. Validation
9. Troubleshooting
10. References

Adapt sections to the document type.

### Step 4: Diagram Generation

Use Mermaid when diagrams are useful.

Supported diagrams include:

- Flowcharts
- Sequence diagrams
- Architecture relationships
- Deployment workflows
- Dependency diagrams

### Step 5: Quality Validation

Check:

- Technical accuracy
- Markdown structure
- Command syntax
- Source references
- Security considerations
- Missing information
- Documentation completeness

## Safety Rules

- Do not invent technical facts.
- Do not expose secrets.
- Do not assume successful deployments.
- Do not execute destructive commands.
- Do not modify infrastructure without authorization.
- Identify unsupported or unverified statements.

## Completion Criteria

Documentation must be readable, technically grounded,
well-structured, and suitable for version control.
