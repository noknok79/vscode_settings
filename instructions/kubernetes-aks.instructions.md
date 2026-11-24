---
applyTo: "**/*.yaml,**/*.yml,**/k8s/**,**/kubernetes/**,**/manifests/**,**/helm/**,**/charts/**"
---

# Kubernetes and Azure Kubernetes Service Engineering Instructions

These instructions apply whenever creating, modifying, reviewing, debugging,
troubleshooting, deploying, securing, upgrading, or refactoring Kubernetes workloads
running on Azure Kubernetes Service (AKS).

Primary objectives:

1. Find the actual root cause.
2. Fix the correct technical layer.
3. Preserve production stability.
4. Make the smallest safe change.
5. Maintain Kubernetes correctness.
6. Maintain AKS compatibility.
7. Preserve Azure security controls.
8. Preserve networking controls.
9. Apply least privilege.
10. Avoid unnecessary cluster or workload disruption.

Never make broad infrastructure changes merely to make an error disappear.

Never guess Kubernetes, AKS, Azure, Helm, kubectl, or Azure CLI behavior.

---

# Golden Rule

DIAGNOSE BEFORE MODIFYING.

When given a Kubernetes or AKS problem:

1. Read the exact error.
2. Determine the affected cluster.
3. Determine the namespace.
4. Determine the affected workload.
5. Determine the Kubernetes object.
6. Determine whether the failure is Kubernetes or Azure related.
7. Inspect current resource state.
8. Inspect events.
9. Inspect logs.
10. Inspect previous container logs when restarts occurred.
11. Inspect rollout status.
12. Inspect Service/endpoints when connectivity is involved.
13. Inspect nodes when scheduling or runtime infrastructure is involved.
14. Inspect AKS configuration when Azure infrastructure may be involved.
15. Check current Kubernetes documentation.
16. Check current Microsoft Learn AKS documentation.
17. Check current Microsoft documentation for related Azure services.
18. Check official Microsoft/Azure GitHub repositories when additional evidence is needed.
19. Determine the smallest root-cause fix.
20. Validate the fix.
21. Review the resulting diff.

Never start by deleting or recreating resources.

---

# Documentation Priority

Use sources in this order.

## AKS-specific issues

1. Microsoft Learn AKS documentation
2. Microsoft Learn AKS troubleshooting documentation
3. Microsoft Learn Azure Architecture Center AKS guidance
4. Microsoft documentation for related Azure services
5. Azure/AKS GitHub repository
6. Azure AKS release notes
7. Kubernetes upstream documentation
8. Official component documentation
9. Maintained Microsoft/Azure GitHub repositories
10. Community examples only as supporting evidence

## Kubernetes-specific issues

1. Current Kubernetes documentation
2. Kubernetes API reference
3. Kubernetes kubectl documentation
4. Kubernetes upstream GitHub repositories
5. Microsoft AKS documentation for AKS-specific differences

Never use an outdated Kubernetes article when current documentation is available.

Check the Kubernetes version because manifests, APIs, defaults, and feature support
can vary by Kubernetes release.

Do not blindly copy Kubernetes YAML from blogs or public repositories.

---

# Version Awareness

Before recommending a Kubernetes or AKS change, determine when relevant:

    Kubernetes version
    AKS version
    kubectl version
    Helm version
    Azure CLI version
    node OS
    node image
    container runtime
    ingress controller version
    CSI driver version
    CNI/network plugin
    workload identity configuration

Do not assume current documentation applies identically to an old Kubernetes version.

Do not assume deprecated Kubernetes APIs remain available.

Do not automatically upgrade the cluster to solve an unrelated problem.

---

# AKS Release Awareness

AKS changes frequently.

Before recommending:

- Kubernetes version upgrades
- node image upgrades
- OS SKU changes
- network plugin changes
- ingress changes
- identity changes
- autoscaler changes
- preview features

check current Microsoft AKS documentation and release notes.

Do not rely on model memory for currently supported AKS versions.

Do not invent supported upgrade paths.

---

# Troubleshooting Classification

Classify the problem before modifying anything.

Possible categories include:

- Kubernetes manifest
- API version
- namespace
- scheduling
- Pending Pod
- ContainerCreating
- CrashLoopBackOff
- ImagePullBackOff
- ErrImagePull
- OOMKilled
- probe failure
- initialization failure
- container runtime
- application error
- ConfigMap
- Secret
- volume
- PVC
- CSI
- node
- NodeNotReady
- resource pressure
- CPU
- memory
- disk
- Service
- endpoint
- DNS
- ingress
- egress
- CNI
- NetworkPolicy
- Azure VNet
- subnet
- NSG
- route table
- Azure Firewall
- private endpoint
- ACR
- Azure RBAC
- Kubernetes RBAC
- managed identity
- workload identity
- service account
- AKS control plane
- API server
- cluster upgrade
- node pool
- VMSS
- autoscaling
- quota
- Azure Policy
- Azure DevOps pipeline
- Helm
- GitOps
- image/build issue
- application issue

Fix the correct layer.

---

# Diagnostic Order

For workload incidents, prefer this sequence:

    kubectl get
        ↓
    kubectl describe
        ↓
    Events
        ↓
    Current logs
        ↓
    Previous logs
        ↓
    Deployment/ReplicaSet
        ↓
    Service/endpoints
        ↓
    DNS/networking
        ↓
    Node
        ↓
    AKS platform
        ↓
    Azure dependencies

Do not jump directly to changing cluster infrastructure.

---

# Initial Cluster Checks

When appropriate:

    kubectl cluster-info

    kubectl get nodes -o wide

    kubectl get pods -A

    kubectl get events -A --sort-by=.lastTimestamp

Use namespace filtering when the affected namespace is known.

Do not collect huge cluster-wide outputs unnecessarily when a namespace-specific query
is enough.

---

# Pod Troubleshooting

Start with:

    kubectl get pod <pod> -n <namespace> -o wide

Then:

    kubectl describe pod <pod> -n <namespace>

Then:

    kubectl logs <pod> -n <namespace>

For multiple containers:

    kubectl logs <pod> -n <namespace> -c <container>

When a container restarted:

    kubectl logs <pod> -n <namespace> -c <container> --previous

Do not edit the Deployment until these outputs identify or strongly indicate the
problem.

---

# Events

Events are first-class diagnostic evidence.

Use:

    kubectl get events -n <namespace> --sort-by=.lastTimestamp

Look for:

- FailedScheduling
- FailedMount
- FailedAttachVolume
- Unhealthy
- BackOff
- Killing
- Pulling
- Pulled
- Failed
- Evicted
- Preempted
- FailedCreatePodSandBox

Do not treat all events equally.

Prioritize events associated with the affected object and failure timeframe.

---

# Pending Pods

For Pending Pods:

Start with:

    kubectl describe pod <pod> -n <namespace>

Inspect scheduler events.

Possible root causes include:

- insufficient CPU
- insufficient memory
- node selector mismatch
- affinity
- anti-affinity
- topology constraints
- taints
- tolerations
- PVC issues
- hostPort
- max Pods
- subnet/IP exhaustion
- unavailable node pool
- unsuitable VM SKU

Do not immediately increase cluster size.

Determine why scheduling failed first.

Upstream Kubernetes Debug Pods specifically recommends using Pod
state and `describe` output to diagnose Pending workloads, including insufficient CPU
or memory. 【3-08d53d】

---

# CrashLoopBackOff

For CrashLoopBackOff:

Check:

    kubectl describe pod <pod> -n <namespace>

    kubectl logs <pod> -n <namespace> -c <container>

    kubectl logs <pod> -n <namespace> -c <container> --previous

Investigate:

- application startup failure
- missing environment variable
- missing secret
- incorrect command
- incorrect args
- invalid configuration
- permissions
- filesystem
- dependency unavailable
- probe failure
- OOMKilled
- malformed startup command

Do not immediately increase restart limits.

Do not delete the Pod repeatedly as a troubleshooting strategy.

---

# ImagePullBackOff and ErrImagePull

When image pulls fail, determine whether the problem is:

- image does not exist
- incorrect repository
- incorrect tag
- incorrect registry
- registry authentication
- Azure RBAC
- ACR networking
- private endpoint
- private DNS
- firewall
- kubelet identity
- image pull secret
- network-isolated AKS configuration

Inspect:

    kubectl describe pod <pod> -n <namespace>

Pay particular attention to Events.

Do not change the image tag unless evidence shows it is wrong.

Do not add an imagePullSecret automatically when AKS-ACR managed identity integration
is supposed to provide access.

---

# AKS and ACR

When AKS pulls from Azure Container Registry, identify the actual authentication model.

Check:

- ACR registry
- kubelet identity
- AKS-ACR integration
- Azure RBAC
- ACR RBAC/ABAC mode
- networking
- private endpoint
- DNS
- repository permissions

Do not enable ACR admin access as a shortcut.

Do not add username/password credentials simply because image pulling fails.

Microsoft documents that normal AKS-to-ACR integration uses the AKS kubelet identity
and Azure role assignment. ACR repositories using the newer ABAC repository-permission
model need different handling, so do not blindly apply `AcrPull` to every configuration.
【4-04d644】

---

# OOMKilled

If a container reports:

    OOMKilled

inspect:

- memory request
- memory limit
- actual application memory usage
- memory leak possibility
- JVM/runtime configuration
- sidecars
- node pressure

Do not automatically raise memory limits.

Determine whether the workload legitimately needs more memory.

Increasing the limit can simply move the failure to the node.

---

# CPU Problems

When CPU usage is high:

Inspect:

    kubectl top pod -n <namespace>
    kubectl top node

when metrics are available.

Compare usage against:

- requests
- limits
- HPA
- node capacity

High CPU is not automatically an AKS scaling problem.

Determine whether the application, resource limits, or capacity is responsible.

---

# Resource Requests and Limits

Do not blindly generate:

    requests:
    limits:

based on arbitrary values.

Use actual workload requirements and metrics when available.

Understand:

    requests -> scheduler capacity calculation

    limits -> runtime constraints

Avoid setting CPU/memory limits merely because a generic Kubernetes example does.

---

# Deployment Troubleshooting

Check:

    kubectl get deployment <deployment> -n <namespace>

    kubectl describe deployment <deployment> -n <namespace>

    kubectl rollout status deployment/<deployment> -n <namespace>

    kubectl get rs -n <namespace>

    kubectl get pods -n <namespace>

Understand:

    Deployment
        ↓
    ReplicaSet
        ↓
    Pod

Do not edit generated ReplicaSets directly.

Fix the Deployment or source manifest.

---

# Rollouts

When rollout fails:

    kubectl rollout status deployment/<deployment> -n <namespace>

Review:

- new ReplicaSet
- old ReplicaSet
- unavailable replicas
- readiness
- image
- events

Do not immediately run:

    kubectl rollout undo

until the cause is understood.

Rollback can be appropriate for rapid service recovery, but it should be intentional.

---

# Services

When an application is unreachable:

Inspect:

    kubectl get svc -n <namespace>

    kubectl describe svc <service> -n <namespace>

    kubectl get endpoints -n <namespace>

or the current EndpointSlice resources where appropriate.

Verify:

- selector
- Pod labels
- targetPort
- port
- protocol
- service type
- healthy endpoints

Do not blame ingress before verifying Service endpoints.

---

# Endpoint Problems

If a Service has no endpoints:

Compare:

    Service selector

against:

    Pod labels

Do not manually create endpoints simply to bypass a selector problem.

Fix the underlying selector/label mismatch when that is the root cause.

---

# Labels and Selectors

Treat labels used by selectors as API contracts.

Do not casually change:

    spec.selector
    matchLabels
    template.metadata.labels

Changing Deployment selectors can have significant consequences and may be immutable.

Keep selector and Pod labels aligned.

---

# Kubernetes DNS

When DNS resolution fails, determine whether the failure affects:

- one Pod
- one namespace
- one node
- all workloads
- internal Kubernetes names
- external DNS
- private Azure DNS

Check from an affected workload or diagnostic Pod when safe.

Useful checks can include:

    cat /etc/resolv.conf

    nslookup <service>

    nslookup kubernetes.default

    getent hosts <hostname>

where the image provides those tools.

Do not rewrite CoreDNS configuration before identifying the scope of the DNS failure.

---

# CoreDNS

Before modifying CoreDNS:

Determine whether the actual issue is:

- upstream DNS
- Azure Private DNS
- VNet DNS
- custom DNS server
- firewall
- route
- CoreDNS capacity
- malformed ConfigMap
- application DNS configuration

CoreDNS changes affect the entire cluster.

Treat them as high impact.

---

# AKS Networking

For AKS networking failures inspect:

- network plugin
- network plugin mode
- network policy
- service CIDR
- DNS service IP
- Pod CIDR when applicable
- subnet
- IP capacity
- route table
- NSG
- Azure Firewall
- NAT Gateway
- load balancer
- private endpoint
- VNet peering
- custom DNS

Never assume all AKS clusters use the same network architecture.

---

# Network Troubleshooting

Classify:

    Client -> API server

    Pod -> Pod

    Pod -> Service

    Pod -> Azure resource

    Pod -> Internet

    Internet -> Ingress

    Node -> API server

    Node -> Azure dependencies

Different paths require different diagnostics.

Microsoft's Troubleshoot network problems in AKS clusters separates
problems such as API server access, Pod IP allocation, Service connectivity, and node
connectivity. Use the same diagnostic discipline. 【5-d0c3ab】

---

# API Server Connectivity

When `kubectl` cannot connect:

Determine whether the cluster is:

- public
- private
- API Server VNet Integration
- restricted by authorized IP ranges

Check the error.

Examples:

    i/o timeout
    connection refused
    DNS failure
    unauthorized
    forbidden

These indicate different problems.

Do not regenerate credentials repeatedly if the actual issue is network connectivity.

---

# Private AKS

For private AKS clusters:

Do not expect arbitrary public agents or developer workstations to reach the private API
server.

Check:

- VNet connectivity
- peering
- VPN
- ExpressRoute
- self-hosted agent placement
- Private DNS
- DNS links
- firewall
- routes
- private endpoint

Do not make the API server public merely to solve connectivity unless explicitly
requested and security-approved.

---

# Network-Isolated AKS

For network-isolated AKS, verify current Microsoft guidance before modifying outbound
settings.

Check:

- outbound type
- ACR configuration
- cache rules
- private endpoints
- Private DNS
- bootstrap resources
- required external endpoints
- cluster reconciliation requirements

Do not introduce unrestricted outbound internet access merely to solve image pulling.

Microsoft documents specific ACR/cache/private-endpoint behaviors for network-isolated
clusters. 【6-c0f90a】【7-eaa387】

---

# NSGs

Before modifying an NSG:

Identify:

- source
- destination
- protocol
- port
- subnet
- effective rules
- AKS-required traffic

Do not add broad:

    Any -> Any

rules.

Do not automatically allow:

    0.0.0.0/0

for inbound access.

---

# Route Tables

When routes are involved:

Inspect:

- effective routes
- user-defined routes
- default route
- firewall next hop
- asymmetric routing
- cluster outbound configuration

Do not remove routes simply to restore connectivity.

Understand why the route exists.

---

# Azure Firewall

When AKS uses Azure Firewall:

Check:

- outbound requirements
- application rules
- network rules
- FQDN rules
- DNS
- SNAT
- routes

Do not add broad allow-all rules.

Use current AKS outbound requirements documentation.

---

# NetworkPolicy

When NetworkPolicy may block traffic:

Inspect existing policies:

    kubectl get networkpolicy -A

Then inspect the affected namespace.

Understand:

- ingress rules
- egress rules
- Pod selectors
- namespace selectors
- CNI/network policy implementation

Do not delete NetworkPolicy simply to restore connectivity.

Use controlled diagnostics.

---

# Ingress

When ingress fails, troubleshoot layer by layer:

    Client
       ↓
    DNS
       ↓
    Azure frontend/load balancer
       ↓
    Ingress controller
       ↓
    Ingress resource
       ↓
    Service
       ↓
    Endpoints
       ↓
    Pod

Identify the failing layer before modifying ingress manifests.

---

# Ingress Controllers

Determine which ingress implementation is actually used.

Possible examples include:

- Application Gateway
- managed AKS application routing
- NGINX-based ingress
- other organization-approved controllers

Do not assume annotations from one controller apply to another.

Verify annotations against the exact controller/version.

---

# TLS

When HTTPS fails check:

- certificate
- Secret
- hostname
- Ingress configuration
- certificate issuer
- Key Vault integration when applicable
- expiration
- trust chain
- DNS

Do not disable TLS verification to make a request succeed.

---

# Probes

Treat:

    startupProbe
    readinessProbe
    livenessProbe

as different mechanisms.

Do not use them interchangeably.

## Startup Probe

Use for applications that require extended initialization when appropriate.

## Readiness Probe

Controls whether traffic should be sent to the Pod.

## Liveness Probe

Determines whether Kubernetes should restart an unhealthy container.

Do not make liveness probes aggressive to compensate for slow startup.

Do not simply increase every timeout when a probe fails.

Determine why the probe fails.

---

# Probe Failures

For probe failure inspect:

- path
- port
- protocol
- initialDelaySeconds
- timeoutSeconds
- periodSeconds
- failureThreshold
- application startup duration
- application health endpoint
- dependency behavior

Avoid probing external dependencies in ways that cause unnecessary container restarts.

---

# ConfigMaps

When ConfigMap values appear missing or stale:

Check:

- namespace
- ConfigMap name
- key
- env reference
- volume reference
- current Pod specification
- application reload behavior

Remember that changing a ConfigMap does not necessarily cause an application to reread
the value automatically.

Do not assume a rollout occurred.

---

# Secrets

Never reveal Kubernetes Secret values.

Do not decode secrets into Copilot output unless explicitly required for a safe
diagnostic purpose, and never expose production credentials.

Do not commit plaintext Kubernetes Secret manifests containing real credentials.

Prefer appropriate Azure-integrated secret mechanisms where architecture supports them.

---

# Azure Key Vault Integration

When workloads consume Azure Key Vault, distinguish:

- Secrets Store CSI Driver
- workload identity
- managed identity
- service account
- federated identity credential
- Key Vault RBAC
- Key Vault network access
- SecretProviderClass
- Kubernetes Secret synchronization

Do not disable Key Vault firewall/public-network controls merely to make secret retrieval
work.

---

# Workload Identity

For Microsoft Entra Workload Identity inspect:

- cluster OIDC issuer
- workload identity enabled state
- managed identity/app registration
- federated identity credential
- service account
- namespace
- service account subject
- audience
- client ID annotation/label where required
- Azure RBAC

Do not fall back to stored client secrets before diagnosing workload identity.

---

# Kubernetes RBAC

For:

    Forbidden

identify:

- user/service account
- verb
- API group
- resource
- namespace
- scope

Use:

    kubectl auth can-i <verb> <resource> ...

when appropriate.

Do not grant:

    cluster-admin

as the default solution.

Use least privilege.

---

# Azure RBAC vs Kubernetes RBAC

Do not confuse Azure RBAC with Kubernetes authorization.

An identity can have permission to manage the AKS Azure resource but lack permission
inside Kubernetes.

Likewise Kubernetes permissions do not automatically grant Azure resource permissions.

Identify the authorization layer producing the error.

---

# Service Accounts

Use dedicated service accounts when workload identity or Kubernetes authorization
requires them.

Avoid using the default service account for privileged application access.

Do not assign unnecessary cluster-wide permissions.

---

# Nodes

When workloads fail only on specific nodes, inspect:

    kubectl get nodes -o wide

    kubectl describe node <node>

Check:

- Ready condition
- MemoryPressure
- DiskPressure
- PIDPressure
- taints
- capacity
- allocatable
- Pods
- events

Do not immediately delete the node.

---

# NodeNotReady

For NodeNotReady, determine if the cause is:

- kubelet
- container runtime
- disk
- memory
- VMSS
- networking
- Azure host
- certificate
- CNI
- node image
- extension
- upgrade

Use current AKS troubleshooting guidance.

Do not treat a node problem as a workload manifest failure.

---

# kubectl debug

When normal workload containers lack diagnostic tools, consider:

    kubectl debug

rather than modifying production container images merely to add troubleshooting tools.

Upstream kubectl debug supports ephemeral debugging containers,
debug copies of workloads, and node debugging sessions. 【8-0bede2】

Use debug access carefully.

Do not add permanent SSH servers or troubleshooting utilities to production application
images merely for incident investigation.

---

# Node Debugging

When node-level access is necessary:

    kubectl debug node/<node> -it --image=<approved-debug-image>

may be appropriate when permissions allow.

Upstream Kubernetes documents that node debugging can mount the node's root filesystem
under `/host`, so treat this as privileged diagnostic access. 【9-0790a4】

Do not use node debugging when Pod-level diagnostics are sufficient.

---

# Node Pools

Before modifying node pools inspect:

- system versus user pool
- VM SKU
- node count
- autoscaling
- min/max
- zones
- labels
- taints
- OS SKU
- Kubernetes version
- node image
- subnet
- workload dependencies

Do not resize, recreate, or replace a node pool merely to solve a Pod configuration
problem.

---

# System Node Pools

Protect system workloads.

Do not schedule arbitrary application workloads onto system nodes if the cluster design
separates system and user workloads.

Preserve existing taints and scheduling architecture unless explicitly changing it.

---

# Taints and Tolerations

When a Pod cannot schedule because of taints:

Inspect:

    kubectl describe node <node>

and Pod tolerations.

Do not remove node taints merely to make the Pod schedule.

Determine whether the application is supposed to run on that node pool.

---

# Node Selectors and Affinity

When scheduling fails inspect:

- nodeSelector
- nodeAffinity
- podAffinity
- podAntiAffinity
- topology spread constraints
- node labels

Do not weaken scheduling constraints until their architectural purpose is understood.

---

# Cluster Autoscaler

If Pods remain Pending:

Do not immediately blame the cluster autoscaler.

Determine whether Pods are schedulable on any theoretically available node.

Check:

- requests
- VM SKU
- nodeSelector
- affinity
- taints
- maximum node count
- quota
- subnet/IP capacity

The autoscaler cannot correct an inherently unschedulable workload.

---

# Horizontal Pod Autoscaler

For HPA issues inspect:

    kubectl get hpa -n <namespace>

    kubectl describe hpa <hpa> -n <namespace>

Check:

- metric availability
- target
- requests
- minReplicas
- maxReplicas
- current metric

Do not increase replicas blindly.

---

# Pod Disruption Budgets

Before node maintenance or upgrades, inspect PDBs.

An overly restrictive PodDisruptionBudget can block drain operations.

Do not delete the PDB automatically.

Determine whether:

- replica count
- minAvailable
- maxUnavailable

makes disruption impossible.

---

# AKS Upgrades

Treat cluster upgrades as planned production operations.

Before recommending an upgrade:

1. Check currently supported AKS Kubernetes versions.
2. Check available upgrade paths.
3. Check regional availability.
4. Check API deprecations.
5. Check workload compatibility.
6. Check ingress/controller compatibility.
7. Check CSI/add-on compatibility.
8. Check PDBs.
9. Check maintenance window.
10. Check node pool versions.
11. Check node OS/image implications.
12. Review current AKS release notes.

Do not invent a Kubernetes version.

Do not assume direct skipping between arbitrary minor versions is supported.

Current AKS lifecycle and release behavior changes over time, making documentation and
current release notes mandatory for upgrade decisions. Azure/AKS Releases
contains current platform announcements and supported-version changes. 【10-fe27a2】

---

# API Deprecation

Before cluster upgrades, identify deprecated or removed Kubernetes APIs used by
manifests, Helm charts, operators, and CRDs.

Do not upgrade the cluster first and discover application incompatibility afterward.

Check workloads before upgrade.

---

# CRDs

Treat CustomResourceDefinitions separately from built-in Kubernetes APIs.

Before modifying a Custom Resource:

1. Identify controller/operator.
2. Identify CRD version.
3. Check exact controller documentation.
4. Verify schema.
5. Verify installed controller version.

Do not assume Kubernetes core documentation defines third-party CRD behavior.

---

# Helm

When Helm is involved, distinguish failures in:

- chart rendering
- values
- template syntax
- Kubernetes API
- Helm release state
- hook
- application
- AKS

Before deploying inspect:

    helm lint <chart>

and when appropriate:

    helm template ...

Do not modify cluster infrastructure because a Helm template is malformed.

---

# Helm Values

Preserve values hierarchy.

Determine whether a setting comes from:

- values.yaml
- environment values
- `--set`
- `--set-string`
- pipeline parameter
- Secret
- ConfigMap

Do not duplicate the same configuration across multiple layers unnecessarily.

---

# GitOps

When Flux or another GitOps controller manages resources:

Do not manually edit live resources as a permanent fix.

Identify the source-of-truth repository.

Manual cluster edits may be reconciled away.

Fix the desired state.

Emergency operational changes should be reconciled back into source control.

---

# kubectl apply

Do not casually apply ad hoc YAML directly to production.

Prefer the established deployment mechanism:

- Azure DevOps
- GitOps
- Helm
- approved deployment workflow

Use manual `kubectl apply` only when appropriate and clearly understood.

---

# kubectl edit

Avoid using:

    kubectl edit

for permanent infrastructure/application changes managed by source control.

Use it only for deliberate temporary diagnostics/emergency intervention when appropriate.

Update repository configuration afterward.

---

# kubectl delete

Never default to:

    kubectl delete pod
    kubectl delete deployment
    kubectl delete namespace

as the diagnosis.

Deletion can hide symptoms temporarily.

Understand why the object is unhealthy.

Deleting a Pod does not fix a configuration problem.

---

# Force Deletion

Do not recommend:

    --force
    --grace-period=0

as a normal fix.

Force deletion can have workload and storage consequences.

Use only when the object is genuinely stuck and impact is understood.

---

# Namespaces

Preserve namespaces.

Do not move a workload into another namespace merely to make RBAC, Secret, ConfigMap,
or network access work.

Fix the actual namespace dependency.

---

# Persistent Volumes

Treat persistent storage as stateful infrastructure.

Before modifying:

- PVC
- PV
- StorageClass
- CSI configuration
- volume mounts
- access mode
- reclaim policy

understand data impact.

Never delete a PVC simply to fix a mount problem without identifying persistence and
reclaim behavior.

---

# PVC Pending

For Pending PVCs inspect:

    kubectl describe pvc <pvc> -n <namespace>

Check:

- StorageClass
- provisioner
- capacity
- access mode
- topology
- zone
- CSI driver
- events

Do not manually create arbitrary PVs before understanding dynamic provisioning.

---

# StatefulSets

Treat StatefulSets carefully.

Preserve:

- Pod identity
- volume identity
- ordinal behavior
- service relationship

Do not replace StatefulSet with Deployment merely to simplify YAML.

Stateful workloads have different semantics.

---

# DaemonSets

When DaemonSet Pods are missing:

Check:

- node selector
- affinity
- taints
- tolerations
- node OS
- desired/current/available counts

Do not increase replica counts because DaemonSets do not operate like Deployments.

---

# Jobs

When Jobs fail:

Inspect:

    kubectl describe job <job> -n <namespace>

and associated Pods/logs.

Check:

- completions
- parallelism
- backoffLimit
- activeDeadlineSeconds
- application exit code

Do not endlessly increase retry/backoff values for deterministic failures.

---

# CronJobs

For CronJob issues inspect:

- schedule
- timezone support/version
- suspend
- concurrencyPolicy
- startingDeadlineSeconds
- generated Jobs
- previous Job logs

Do not create additional CronJobs merely because one execution was missed.

---

# Pod Security

Use secure workload configuration.

Prefer where application-compatible:

- non-root containers
- least privilege
- dropped capabilities
- read-only filesystem where appropriate
- seccomp
- appropriate service account
- no privileged containers

Do not blindly apply security settings that break the actual workload.

Verify runtime requirements.

---

# Privileged Containers

Treat:

    privileged: true

as high risk.

Do not enable privileged mode merely to solve permissions.

Identify the exact capability/resource required.

Prefer narrower permissions.

---

# hostNetwork / hostPID / hostPath

Treat:

    hostNetwork
    hostPID
    hostIPC
    hostPath

as security-sensitive host access.

Do not use them merely because ordinary Pod networking/storage is failing.

Require a specific architectural justification.

---

# Azure Policy for AKS

When Azure Policy denies Kubernetes resources:

Identify the exact policy.

Do not bypass policy.

Check:

- policy assignment
- initiative
- denied field
- allowed container registry
- security context requirement
- resource constraint

Adjust the workload to meet organizational policy where appropriate.

---

# Container Images

Prefer immutable deployment references for production reliability where organizational
standards support them.

Avoid relying blindly on:

    latest

for controlled deployments.

Preserve existing image-tag strategy unless specifically improving it.

Do not invent image tags.

---

# Image Changes

When changing an image:

Verify:

- registry
- repository
- tag/digest
- architecture
- application compatibility

Do not automatically upgrade an application image to fix a Kubernetes infrastructure
problem.

---

# Azure DevOps Integration

When AKS deployment runs through Azure DevOps, troubleshoot these layers independently:

    Pipeline YAML
        ↓
    Agent
        ↓
    Azure authentication
        ↓
    AKS API connectivity
        ↓
    Kubernetes authorization
        ↓
    Manifest/Helm
        ↓
    Scheduling
        ↓
    Runtime
        ↓
    Application

Do not modify Kubernetes manifests if the Azure DevOps agent cannot reach a private AKS
API endpoint.

Do not modify AKS infrastructure if the pipeline path to the manifest is wrong.

---

# Private AKS and Azure DevOps Agents

When Azure DevOps deploys to private AKS:

Check whether the agent has network and DNS connectivity to the private API endpoint.

Do not assume a Microsoft-hosted public agent can reach private cluster resources.

Inspect:

- self-hosted agent
- Managed DevOps Pool networking
- VNet connectivity
- Private DNS
- routes
- firewall
- NSG

Fix connectivity at the appropriate layer.

---

# Deployment Validation

Before applying Kubernetes manifests:

When available, use server/client validation appropriate to the workflow.

Possible diagnostics include:

    kubectl apply --dry-run=client -f <manifest>

and, when authenticated to the actual cluster and appropriate:

    kubectl apply --dry-run=server -f <manifest>

Server-side validation can catch cluster/API-specific issues that local YAML parsing
cannot.

Do not claim a manifest will deploy successfully merely because YAML syntax is valid.

---

# Rollout Validation

After a deployment:

Check:

    kubectl rollout status deployment/<deployment> -n <namespace>

Then inspect affected Pods.

Do not consider pipeline success alone proof that the application is healthy.

Deployment-command success is different from workload readiness.

---

# Health Validation

Where appropriate check:

    kubectl get deploy -n <namespace>

    kubectl get pods -n <namespace>

    kubectl get svc -n <namespace>

    kubectl get endpoints -n <namespace>

Then application-specific health.

Do not stop at:

    Pod = Running

A running Pod can still be unready or unable to serve traffic.

---

# Security Review

Before finalizing Kubernetes/AKS changes, check whether the modification:

- grants cluster-admin
- grants broad Kubernetes permissions
- grants broad Azure RBAC
- creates exposed LoadBalancer services
- creates public IPs
- weakens NetworkPolicy
- weakens NSGs
- enables ACR admin
- stores secrets in manifests
- exposes Key Vault
- disables TLS
- runs privileged
- runs as root unnecessarily
- mounts host filesystem
- uses host networking
- exposes sensitive ports
- opens unrestricted egress
- opens unrestricted ingress

Do not weaken security just to make deployment pass.

---

# Minimal Change Principle

When solving an incident, preserve:

- cluster architecture
- node pools
- namespaces
- workload names
- Service names
- selectors
- labels
- RBAC
- identities
- image strategy
- networking
- ingress
- private endpoints
- DNS
- GitOps ownership
- Helm structure
- CI/CD workflow

unless the root cause requires modification.

Do not combine an emergency fix with broad refactoring.

---

# No Overengineering

Avoid unnecessary:

- sidecars
- init containers
- controllers
- operators
- ConfigMaps
- Secrets
- Services
- Ingresses
- NetworkPolicies
- Helm templates
- shell wrappers
- retry loops
- health probes
- RBAC objects
- debug containers
- node pools

Do not introduce new Kubernetes objects merely to make the architecture appear more
sophisticated.

Choose the smallest maintainable implementation.

---

# Git Diff Review

Before completing changes inspect:

    git diff

For affected files:

    git diff -- <manifest>

Look for:

- changed image
- changed tag
- changed namespace
- changed selector
- changed Service port
- changed targetPort
- changed resource requests
- changed limits
- changed probe
- changed RBAC
- changed identity
- changed Secret handling
- changed ingress exposure
- changed network policy
- changed storage
- changed security context

Remove unrelated changes.

---

# Incident Response Format

When asked to troubleshoot AKS/Kubernetes, respond in this structure:

## Root Cause

State the most likely root cause from available evidence.

## Evidence

Identify the exact:

- event
- status
- log
- error
- Kubernetes object
- Azure error

supporting the diagnosis.

## Layer

Identify whether the problem is:

- application
- container
- Kubernetes
- AKS
- Azure networking
- Azure identity
- ACR
- storage
- CI/CD

## Documentation Verification

Identify current Kubernetes or Microsoft documentation supporting the diagnosis.

## Minimal Fix

Provide only the required configuration/command changes.

## Validation

Provide exact commands to confirm the fix.

## Expected Result

State what successful recovery should look like.

## Risk

Explicitly identify potential:

- disruption
- restart
- data loss
- security impact
- networking impact

when relevant.

Do not bury the actual repair under generic Kubernetes explanations.

---

# Command Safety

Default to read-only diagnostic commands first.

Generally safe diagnostic commands include:

    kubectl get
    kubectl describe
    kubectl logs
    kubectl auth can-i
    kubectl top

when access permits.

Treat mutation commands with more caution:

    kubectl apply
    kubectl patch
    kubectl scale
    kubectl set image
    kubectl rollout undo
    kubectl delete
    kubectl drain
    kubectl cordon

Never use destructive commands merely as diagnostics.

---

# Production Safety

Assume the cluster can contain production workloads unless context establishes
otherwise.

Before proposing disruptive commands, explicitly assess blast radius.

High-impact operations include:

    kubectl drain
    kubectl delete namespace
    kubectl delete pvc
    kubectl delete node
    cluster upgrade
    node pool deletion
    CNI changes
    cluster identity changes
    subnet changes
    network policy changes
    CoreDNS changes

Prefer diagnosis before disruption.

---

# Final Validation Checklist

Before considering a Kubernetes/AKS fix complete:

1. Is the original root cause understood?
2. Was the correct layer fixed?
3. Are manifests valid?
4. Are namespaces correct?
5. Are labels/selectors aligned?
6. Are container images correct?
7. Are Pods scheduled?
8. Are containers healthy?
9. Are readiness probes passing?
10. Are Services populated with healthy endpoints?
11. Is DNS working?
12. Is ingress working when applicable?
13. Is networking correct?
14. Is ACR authentication correct?
15. Is Azure RBAC least privilege?
16. Is Kubernetes RBAC least privilege?
17. Are identities correct?
18. Are Secrets protected?
19. Are volumes healthy?
20. Are nodes healthy?
21. Did the rollout complete?
22. Is the application actually responding?
23. Were unrelated resources untouched?
24. Did security remain intact?
25. Was the Git diff reviewed?

---

# Final Rules

Always:

1. Diagnose before modifying.
2. Read the exact error.
3. Find the first meaningful failure.
4. Inspect Pod events.
5. Inspect logs.
6. Inspect previous logs after restarts.
7. Inspect rollout status.
8. Verify Service endpoints for connectivity issues.
9. Verify DNS before changing network architecture.
10. Verify exact Kubernetes version.
11. Verify current AKS documentation.
12. Verify current Kubernetes documentation.
13. Never invent kubectl arguments.
14. Never invent Azure CLI arguments.
15. Never invent Kubernetes APIs.
16. Never invent AKS capabilities.
17. Distinguish Kubernetes RBAC from Azure RBAC.
18. Distinguish workload identity from cluster identity.
19. Distinguish application failures from platform failures.
20. Distinguish ACR authentication from image existence.
21. Protect secrets.
22. Apply least privilege.
23. Preserve private networking.
24. Do not casually expose private clusters.
25. Do not enable ACR admin as a shortcut.
26. Do not grant cluster-admin as a shortcut.
27. Do not delete workloads simply to hide failures.
28. Do not delete PVCs casually.
29. Do not recreate AKS for localized failures.
30. Do not upgrade AKS without compatibility checks.
31. Do not modify node pools unnecessarily.
32. Do not disable network/security policies merely to troubleshoot.
33. Do not bypass Azure Policy.
34. Prefer read-only diagnostics first.
35. Make the smallest correct change.
36. Validate the rollout.
37. Validate application health.
38. Review the final Git diff.

When multiple solutions are technically valid, choose the solution that:

- follows current Kubernetes documentation
- follows current Microsoft AKS documentation
- matches the installed Kubernetes version
- preserves the existing cluster architecture
- makes the smallest change
- maintains least privilege
- preserves private networking
- avoids exposing credentials
- avoids workload disruption
- avoids unnecessary node or cluster replacement
- introduces the least complexity
- is easy to validate
- is easy to review
- works cleanly through the established Azure DevOps deployment process

Never solve a localized Kubernetes problem by unnecessarily redesigning the AKS cluster.
