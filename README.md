# Unified VS Code + GitHub Copilot Backup, Verification and Restoration

**Updated:** 13 November 2026  
**Repository:** `noknok79/vscode_settings` (`main`)  
**Verified recovery commit:** `31ddb70dbffba778d85082afb88436152b32d353`  
**Target:** Windows VS Code Stable + WSL Ubuntu (`root`, `/root/.copilot`)  
**Purpose:** Recover approved Copilot customizations and the DevSecOps toolchain without restoring credentials or transient runtime data.

> **Safety and scope:** The sanitized repository was published and independently cloned from GitHub on 13 November 2026. Git integrity, 230 tracked files, and Gitleaks checks passed. This does **not** certify full restoration on a second PC or complete absence of confidential material. Never back up tokens, private keys, `~/.copilot/config.json`, session history, caches, or authentication state. Only use approved software sources and review employer-confidential content before publishing to a personal repository.

## 1. Choose your workflow

| Goal | Sections |
|---|---|
| Restore Windows VS Code and WSL Copilot configuration | 2–6, 11 |
| Restore DevSecOps skill **and applications** | 2–3, 7, **7.1**, 11 |
| Restore Technical Writer | 2–3, 8, 11 |
| Use six-phase script/pipeline refactoring | 9 |
| Maintain and back up future changes | 10 |

## 2. Prerequisites and identities

- Windows VS Code Stable, WSL Ubuntu 22.04+, Windows PowerShell, Git, SSH, and Python 3.
- Documented WSL user: `root`, `HOME=/root`. Adapt paths if using another user or `COPILOT_HOME`.
- Preserve the `github-noknok79` SSH alias separately from `dbg-mark-villanueva`. Verify GitHub's official SSH host-key fingerprint before trusting it.
- Git SSH, Copilot subscription, and MCP authentication are different identities.
- Before full restoration, review the scripts, close VS Code/Copilot CLI, and pause Settings Sync.

```bash
whoami
printf 'HOME=%s\nCOPILOT_HOME=%s\n' "$HOME" "${COPILOT_HOME:-<unset>}"
cat /etc/os-release | grep -E '^(NAME|VERSION_ID|VERSION_CODENAME)='
dpkg --print-architecture
git --version
python3 --version
ssh -T git@github-noknok79
```

A successful GitHub SSH greeting may return status 1. Verify the greeting identifies `noknok79`.

## 3. Download and verify the current GitHub snapshot

**Current recovery checkpoint:** `31ddb70dbffba778d85082afb88436152b32d353`. The old history was replaced. Historical commits `6cc087d`, `8c073e6`, and `271f691` are **not** current restoration targets.

```bash
bash --noprofile --norc <<'SCRIPT'
set -euo pipefail
REMOTE='git@github-noknok79:noknok79/vscode_settings.git'
EXPECTED='31ddb70dbffba778d85082afb88436152b32d353'
CLONE="/root/vscode_settings_review_$(date +%Y%m%d-%H%M%S)"
git clone --branch main --single-branch "$REMOTE" "$CLONE"
test "$(git -C "$CLONE" rev-parse HEAD)" = "$EXPECTED"
test "$(git ls-remote --exit-code "$REMOTE" refs/heads/main | awk '{print $1}')" = "$EXPECTED"
git -C "$CLONE" fsck --full --no-reflogs
test -z "$(git -C "$CLONE" status --porcelain)"
test "$(git -C "$CLONE" ls-files | wc -l)" -eq 230
gitleaks git "$CLONE" --redact=100 --no-banner --no-color
printf 'PASS: verified clone %s at %s\n' "$CLONE" "$EXPECTED"
SCRIPT
```

This verifies the pinned commit, Git integrity, inventory count, and scanner results, not runtime functionality. If `main` legitimately advances, review and record the new approved checkpoint instead of silently bypassing the pinned check.

## 4. Full automated restoration

Keep these three restore implementation files together at the chosen working-directory root:

```text
Restore-Copilot.ps1
restore.sh
restore_files.py
```

The launcher clones the separate payload (`copilot/`, `vscode/`, `wsl/`). Review script-relative paths and the restoration allowlist. From standalone Windows PowerShell in the directory containing the three files:

```powershell
$Required = 'Restore-Copilot.ps1','restore.sh','restore_files.py'
foreach ($Name in $Required) {
    if (-not (Test-Path -LiteralPath (Join-Path (Get-Location) $Name) -PathType Leaf)) {
        throw "Missing: $Name"
    }
}
.\Restore-Copilot.ps1 -Distro Ubuntu
```

Use the exact installed WSL distribution name. Follow the launcher's approval gates:

1. **PREPARE:** approve reviewed prerequisite work and cloning, not file replacement.
2. Review the plan, commit, destinations, hooks, MCP definitions, and machine-specific settings.
3. **RESTORE:** authorize only reviewed replacements; preserve the `/root/copilot-restore-...` run directory and rollback inventory.
4. **INSTALL (optional):** authorize Copilot CLI or Windows-local extensions separately. WSL extensions need their own scope review.
5. Inspect `verification.json`, `rollback.json`, and other reports. File hashes alone do not establish runtime success.

Do not bypass PowerShell execution policy, overwrite authentication, run `rm -rf ~/.copilot`, or use `rsync --delete`.

Explicit rollback from WSL, with actual paths:

```bash
bash /path/to/restore.sh rollback '/root/copilot-restore-<actual-run-id>'
```

Rollback does not automatically reverse installed applications or extensions. The full launcher has not been verified end-to-end on a second machine.

## 5. Manual selective restoration

Use when only a few reviewed files are missing. Reject symlinks, preserve differing destinations, and verify bytes and executable modes. Set `CLONE` to the verified checkout from Section 3:

```bash
SRC="$CLONE/copilot/skills/devsecops-validation/SKILL.md"
DST="$HOME/.copilot/skills/devsecops-validation/SKILL.md"
test -s "$SRC"
if [ -e "$DST" ]; then
  cmp -s "$SRC" "$DST" || { echo 'STOP: Existing file differs'; exit 1; }
else
  mkdir -p "$(dirname "$DST")"
  cp -p "$SRC" "$DST"
fi
cmp -s "$SRC" "$DST" && echo 'PASS: File bytes match'
```

Never blindly restore SSH configuration, shell profiles, corporate settings, MCP credentials, or machine-specific Windows paths.

## 6. Sanitized inventory and security model

**230 tracked files** at the verified commit, including:

| Definition category | Verified count |
|---|---:|
| Agents (`*.agent.md`) | 21 |
| Instructions (`*.instructions.md`) | 16 |
| Prompts (`*.prompt.md`) | 27 |
| Skills (`SKILL.md`) | 46 |
| Hook JSON configurations | 10 |

These 120 definitions are part of the 230 files, alongside scripts, references, settings, and restoration files. Compare against the selected Git commit, not older inventory counts.

Excluded from the new history: session-state, sidebar sessions, session databases, logs, lock files, caches, Python bytecode, the `#.agent.md` placeholder, and Windows `Zone.Identifier`/GUID metadata. Markdown permissions were normalized; required executable scripts retained executable modes.

**History remediation (13 November 2026):** Old `main` at `271f691` was replaced with the isolated sanitized history ending at `31ddb70`. A fresh GitHub clone passed `git fsck`, 230-file inventory, and Gitleaks with zero findings. Old Git objects may still exist in GitHub caches, other refs, or clones. Rotate confirmed exposed credentials and follow applicable reporting procedures.

Private old-history artifacts, **never republish**:

```text
/root/copilot-git-recovery-20261113-232147/repository.git
/root/copilot-git-recovery-20261113-232147/recovery.bundle
/root/vscode_settings_old-20261113-234030
```

Active configuration `/root/.copilot` was not modified by Git history migration. Current clean backup checkout: `/root/vscode_settings_clean`.

## 7. DevSecOps validation skill

**Destination:** `~/.copilot/skills/devsecops-validation/`  
**Backup:** `copilot/skills/devsecops-validation/`

```text
devsecops-validation/
├── SKILL.md
├── references/validation-policy.md
└── scripts/
    ├── validate.sh
    ├── results.sh
    ├── report.py
    └── publish.py
```

The original-machine validator baseline SHA-256 was `261bbbe26e32097be09162989ca957b0e6aeca991bd28f48426d98c70ac191bf`. Check this only when restoring that exact content. Six files were previously hash-verified, and 16 isolated regression scenarios passed. The sanitized backup retained the validator and executable mode.

The skill supports applicable Bash, Terraform, IaC, Kubernetes, Helm and secret scanning. A skipped or unavailable scanner is **not** a pass. The external toolchain must be installed separately using Section 7.1.

## 7.1 DevSecOps Toolchain Installation and Restoration

### 7.1.1 Principles and installation order

The backup contains **configuration and scripts, not installed Linux packages**. After a PC reformat, first install WSL Ubuntu and restore the configuration, then audit installed tools, install only the missing approved dependencies, and run safe fixture tests.

**Recommended order:**

1. Confirm Ubuntu release and architecture (`/etc/os-release`, `dpkg --print-architecture`).
2. Install core Ubuntu packages.
3. Install Terraform and ShellCheck.
4. Install TFLint, Checkov, Trivy, Gitleaks and Helm as required.
5. Install kubectl and Azure CLI only for relevant workflows.
6. Install Docker, PowerShell, Bicep CLI or additional scanners only when needed.
7. Record versions and run the non-destructive acceptance checks below.

Do not blindly reinstall tools that already work. Use signed vendor repositories or verified release binaries; do not run unreviewed `curl | bash`. Pin compatible versions when projects require them. All commands below are **manual examples**, not an unattended installer. Review each before running; commands that install packages or write under `/etc` or `/usr/local/bin` change the machine.

### 7.1.2 Core Ubuntu packages

**Read-only preflight:**

```bash
cat /etc/os-release | grep -E '^(NAME|VERSION_ID|VERSION_CODENAME)='
dpkg --print-architecture
id -u
command -v apt-get
```

**Install (requires approval; root WSL shown):**

```bash
apt-get update
apt-get install -y ca-certificates curl wget gnupg git python3 python3-venv \
  python3-pip pipx jq shellcheck unzip tar lsb-release
```

If not running as root, use `sudo` for the `apt-get` commands. Do not run a general `apt upgrade` as part of restoring one toolchain without separate approval.

**Verify:**

```bash
bash --version | head -n 1
python3 --version
git --version
shellcheck --version
jq --version
pipx --version
```

### 7.1.3 Terraform CLI (HashiCorp signed APT repository)

Review the current [HashiCorp installation instructions](https://developer.hashicorp.com/terraform/install) and signing-key fingerprint before installation. The following is an Ubuntu APT pattern:

```bash
# As root in WSL Ubuntu; skip if Terraform is already installed and approved.
install -d -m 0755 /usr/share/keyrings
curl -fsSL https://apt.releases.hashicorp.com/gpg \
  | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
# Verify the key fingerprint against HashiCorp's current official documentation.
CODENAME=$(. /etc/os-release; echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
printf 'deb [arch=%s signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com %s main\n' \
  "$(dpkg --print-architecture)" "$CODENAME" \
  > /etc/apt/sources.list.d/hashicorp.list
apt-get update
apt-get install -y terraform
terraform version
```

If the Ubuntu release is unsupported, stop and use the vendor's verified binary method. Never substitute another Ubuntu codename without reviewing compatibility.

### 7.1.4 TFLint (verified release asset)

The TFLint project publishes binary archives, checksums and GitHub artifact attestations. Select the asset matching the WSL architecture and a reviewed version from [TFLint releases](https://github.com/terraform-linters/tflint/releases). For an **amd64** system, the project documents this release-asset workflow:

```bash
# Run in an empty temporary directory; inspect the release and asset names first.
mkdir -p /tmp/tflint-install-review
cd /tmp/tflint-install-review
curl -fL -O https://github.com/terraform-linters/tflint/releases/latest/download/tflint_linux_amd64.zip
curl -fL -O https://github.com/terraform-linters/tflint/releases/latest/download/checksums.txt
# If GitHub CLI is installed, verify the publisher attestation:
gh attestation verify checksums.txt -R terraform-linters/tflint
sha256sum --ignore-missing -c checksums.txt
unzip -o tflint_linux_amd64.zip
# After checksum and publisher verification, and with approval:
install -m 0755 tflint /usr/local/bin/tflint
tflint --version
```

For arm64 or other architectures, select the corresponding verified asset. Plugin initialization (`tflint --init`) may download plugins and should be run only for an approved project and ruleset.

### 7.1.5 Checkov (isolated Python installation)

Use [Checkov's official installation guide](https://www.checkov.io/2.Basics/Installing%20Checkov.html). Avoid modifying the system Python environment with `pip --break-system-packages`.

```bash
# Root WSL example: pipx provides an isolated application environment.
pipx ensurepath
pipx install checkov
# Start a new shell if the pipx bin directory was just added to PATH.
checkov --version
```

If `pipx` is not suitable, create an explicit Python virtual environment and install Checkov inside it. Checkov version and Python compatibility must be checked before installation. Use approved local IaC fixtures for testing; no Azure login is needed for basic static scans.

### 7.1.6 Trivy (Aqua Security signed APT repository)

Review [Trivy's official installation guide](https://trivy.dev/docs/latest/getting-started/installation/). Ubuntu repository example:

```bash
# As root, after reviewing the publisher's signing key.
curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key \
  | gpg --dearmor -o /usr/share/keyrings/trivy.gpg
printf '%s\n' \
  'deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main' \
  > /etc/apt/sources.list.d/trivy.list
apt-get update
apt-get install -y trivy
trivy --version
```

The first vulnerability database download may require network access and disk space. Do not treat a missing database or failed update as a successful scan.

### 7.1.7 Gitleaks (official release and checksum)

Use the [official Gitleaks releases](https://github.com/gitleaks/gitleaks/releases) and the matching checksum file. Select the reviewed release version and architecture rather than hardcoding a stale download. Example for **Linux x86-64**, with an explicit approved version:

```bash
# Set VERSION to a reviewed version from the official releases page.
VERSION='8.30.1'
mkdir -p /tmp/gitleaks-install-review
cd /tmp/gitleaks-install-review
curl -fL -O "https://github.com/gitleaks/gitleaks/releases/download/v${VERSION}/gitleaks_${VERSION}_linux_x64.tar.gz"
curl -fL -O "https://github.com/gitleaks/gitleaks/releases/download/v${VERSION}/gitleaks_${VERSION}_checksums.txt"
grep "gitleaks_${VERSION}_linux_x64.tar.gz" "gitleaks_${VERSION}_checksums.txt" | sha256sum -c -
tar -xzf "gitleaks_${VERSION}_linux_x64.tar.gz" gitleaks
# After reviewing the asset and checksum:
install -m 0755 gitleaks /usr/local/bin/gitleaks
gitleaks version
```

For other architectures, use the matching official release archive. Never display raw secret findings in shared logs; use `--redact=100`.

### 7.1.8 Helm (official verified binary)

The [Helm installation guide](https://helm.sh/docs/intro/install/) documents official binaries and verification. Choose the major version compatible with the projects you maintain. Do not assume Helm 4 is compatible with every existing Helm 3 workflow.

1. Select the desired official Helm release and Linux architecture.
2. Download the binary archive and its checksum/signature files from the official release instructions.
3. Verify checksum and publisher signature as documented.
4. Extract and install the verified `helm` binary into `/usr/local/bin`.
5. Verify:

```bash
helm version --short
helm lint /path/to/approved/test-chart
```

Do not run `helm install` or `helm upgrade` merely to test the CLI; those can modify clusters.

### 7.1.9 kubectl (Kubernetes verified binary)

Use the [official kubectl Linux guide](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/). Choose a version within **one minor version** of the target cluster. Example for Linux **amd64** (adjust architecture and version as required):

```bash
mkdir -p /tmp/kubectl-install-review
cd /tmp/kubectl-install-review
KVER=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
curl -fL -o kubectl "https://dl.k8s.io/release/${KVER}/bin/linux/amd64/kubectl"
curl -fL -o kubectl.sha256 "https://dl.k8s.io/release/${KVER}/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
# After compatibility and checksum review:
install -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

Installing `kubectl` does not install a Kubernetes cluster. Do not restore kubeconfig secrets from the personal backup; configure cluster access separately through approved authentication.

### 7.1.10 Azure CLI (Microsoft signed APT repository)

Follow the current [Microsoft Learn Azure CLI Ubuntu instructions](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux). Confirm the Ubuntu release is supported. The signed-repository pattern is:

```bash
# As root; review Microsoft signing key and supported Ubuntu codename first.
install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
  | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg
CODENAME=$(. /etc/os-release; echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
printf 'deb [arch=%s signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ %s main\n' \
  "$(dpkg --print-architecture)" "$CODENAME" \
  > /etc/apt/sources.list.d/azure-cli.list
apt-get update
apt-get install -y azure-cli
az version
```

Do not copy `$HOME/.azure` authentication caches into the GitHub backup. Sign in interactively only when a workflow actually requires Azure access.

### 7.1.11 Optional tools

These were not all installed in the previously audited environment and are **not universally required**:

| Tool | Install only when | Official source |
|---|---|---|
| Docker Engine/Desktop | Container build/run or local image tests are needed | [Docker Ubuntu installation](https://docs.docker.com/engine/install/ubuntu/) |
| PowerShell (`pwsh`) | PowerShell validation or Pester/PSScriptAnalyzer is needed | [Microsoft Learn PowerShell on Ubuntu](https://learn.microsoft.com/en-us/powershell/scripting/install/install-ubuntu) |
| Bicep CLI | Direct Bicep validation is needed; Azure CLI also has Bicep integration | [Microsoft Learn Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install) |
| Semgrep | SAST rules require it | [Semgrep installation](https://semgrep.dev/docs/getting-started/quickstart) |
| Hadolint | Dockerfile linting requires it | [Hadolint releases](https://github.com/hadolint/hadolint/releases) |
| kubeconform | Kubernetes schema checks require it | [Kubeconform releases](https://github.com/yannh/kubeconform/releases) |
| tfsec | Legacy workflow explicitly depends on it | [tfsec repository](https://github.com/aquasecurity/tfsec) |

Do not install optional tools merely to eliminate a `MISSING` label. First verify which scanners the actual skill invokes.

### 7.1.12 Read-only installed-tool audit

Run this **before** and **after** installation:

```bash
bash --noprofile --norc <<'SCRIPT'
set -euo pipefail
TOOLS=(bash python3 git jq shellcheck terraform tflint checkov trivy gitleaks helm kubectl az docker pwsh bicep semgrep hadolint kubeconform)
found=0; missing=0
for tool in "${TOOLS[@]}"; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf 'AVAILABLE: %-14s %s\n' "$tool" "$(command -v "$tool")"
    ((found+=1))
  else
    printf 'MISSING: %s\n' "$tool"
    ((missing+=1))
  fi
done
printf 'Available=%d Missing=%d Total=%d\n' "$found" "$missing" "${#TOOLS[@]}"
SCRIPT
```

**Version inventory:** run only for tools actually installed, and keep the output local. Typical commands:

```bash
python3 --version
shellcheck --version
terraform version
tflint --version
checkov --version
trivy --version
gitleaks version
helm version --short
kubectl version --client
az version
jq --version
```

Record versions in a local maintenance log. Do not commit environment-variable dumps, authentication output, or tokens.

### 7.1.13 Post-installation acceptance and troubleshooting

1. Verify each required executable is on the WSL `PATH` and note its installed version.
2. Confirm Python reporting dependencies can be imported, if required by the skill scripts.
3. Run `bash -n` and ShellCheck on the validator.
4. Execute only approved **non-destructive** fixtures relevant to the enabled scanners.
5. Inspect JSON reports, per-check `PASS`/`FAIL`/`SKIPPED`, and exit codes. Missing tools are not passes.
6. Confirm the skill is discoverable in Copilot CLI and in the intended VS Code WSL harness separately.
7. Record any unverified integration, and do not claim a complete second-machine restore until actual runtime acceptance passes.

```bash
SKILL="$HOME/.copilot/skills/devsecops-validation"
test -s "$SKILL/SKILL.md"
test -x "$SKILL/scripts/validate.sh"
bash -n "$SKILL/scripts/validate.sh"
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck -x -P "$SKILL/scripts" "$SKILL/scripts/validate.sh"
else
  echo 'SKIPPED: ShellCheck not installed'
fi
```

**Troubleshooting:**

- `command not found`: check `PATH`, installation scope, `pipx ensurepath`, and whether the terminal is in Windows or WSL.
- APT signing error: stop and recheck the vendor's current signing key; never disable signature checks.
- Unsupported Ubuntu codename: stop and use the vendor's documented supported distribution or verified binary method.
- Python externally-managed environment: use `pipx` or a virtual environment; do not force system-wide pip changes.
- Scanner requires network/database: distinguish an unavailable database from a successful scan.
- Docker CLI installed but daemon unavailable: CLI presence does not establish container-runtime functionality.
- `kubectl` installed but no cluster access: this is a separate authentication/context setup, not a failed binary installation.

## 8. Technical Writer components

```text
copilot/agents/technical-writer.agent.md
copilot/prompts/runbook.prompt.md
copilot/skills/runbook/SKILL.md
copilot/skills/technical-documentation/SKILL.md
```

These are retained in the sanitized backup. The historical `/runbook` prompt used `agent: agent`, not automatic `technical-writer` selection. Verify agent/prompt/skill discovery in the intended VS Code harness and generate a safe sample runbook.

## 9. Global scripting standards and six-phase refactoring

```text
~/.copilot/instructions/bash.instructions.md
~/.copilot/instructions/powershell.instructions.md
~/.copilot/instructions/azure-pipelines.instructions.md
~/.copilot/instructions/devops-global.instructions.md
~/.copilot/prompts/simplify-pipeline.prompt.md
```

The `/simplify-pipeline` workflow uses `devops-engineer` for Bash, PowerShell, Python and Azure DevOps YAML:

1. **Audit:** root cause, dependencies, Git baseline, interfaces and security controls.
2. **Propose:** smallest safe changes, documentation for version-dependent behavior and risks. **Stop for approval.**
3. **Implement:** only approved files, backups and rollback readiness.
4. **Validate:** relevant syntax, lint, unit and security checks.
5. **Compare:** behavior, outputs, exit codes, external calls and approvals.
6. **Report:** diff, line counts, acceptance results, skipped checks and unresolved risks.

Never automatically commit, push, deploy, delete images, bypass approvals, or execute destructive infrastructure operations. The prompt is included in the sanitized backup. Fresh-machine discovery remains untested.

The `python-to-azure-pipeline` workflow is represented by a skill in the backup. Do not assume a corresponding slash-command prompt file exists unless verified in the selected snapshot.

## 10. Maintain and update the backup safely

**Active configuration:** `/root/.copilot`  
**Approved backup checkout:** `/root/vscode_settings_clean`  
**Remote:** `git@github-noknok79:noknok79/vscode_settings.git`

1. Modify only the intended active customization.
2. Validate metadata, dependencies, and behavior; preserve unrelated work.
3. Compare against the backup and copy only approved changes.
4. Exclude sessions, databases, logs, caches, tokens and credentials. Review employer-confidential content.
5. Run Gitleaks, `git diff --check`, and inspect the staged diff. Stage explicit paths, not `git add .`.
6. Commit and push normally after review. **Never force-push routine updates.**
7. Verify remote SHA, fresh-clone recovery and changed-file hashes; update this README's checkpoint.

```bash
cd /root/vscode_settings_clean || exit 1
git status -sb
git remote -v
git diff --check
# After copying, reviewing, and explicitly staging approved changes:
# git diff --cached --check
# git diff --cached
# git commit -m "Update approved Copilot customizations"
# git push origin main
# git ls-remote origin refs/heads/main
```

A matching Git commit does not prove `/root/.copilot` is identical to the backup. Compare hashes for the actual changed files. Validate after every change, check drift weekly, audit compatibility monthly, and verify recovery before PC reformat.

## 11. Runtime acceptance and sign-off

- [x] Sanitized GitHub `main` published at `31ddb70dbffba778d85082afb88436152b32d353`.
- [x] Fresh GitHub clone, Git integrity, 230 tracked files and Gitleaks checks passed on the original machine.
- [x] Local backup checkout rebuilt from sanitized GitHub history.
- [ ] Confirm target Windows profile, WSL user/home, extension scopes and tool versions.
- [ ] Install and verify required DevSecOps tools using Section 7.1.
- [ ] Run approved restore; inspect hashes, rollback inventory and reports.
- [ ] Confirm agents, prompts, instructions and skills load in the intended VS Code/Copilot CLI runtime.
- [ ] Execute a safe DevSecOps fixture and verify JSON output and exit code.
- [ ] Test `/simplify-pipeline` approval gate.
- [ ] Exercise an authorized MCP tool call and safe hook test if configured.
- [ ] Confirm user-level customizations in a second workspace.
- [ ] Complete a full second-machine restoration before claiming cross-device success.

**Four separate proofs:** Git integrity, byte equality, static validation, and runtime behavior. Passing one does not imply the others.

## 12. Troubleshooting

| Symptom | Safe response |
|---|---|
| Wrong SSH identity | Check `ssh -G github-noknok79` and GitHub greeting; preserve other identities. |
| `fetch first` | Fetch and review divergence; do not force-push routine changes. |
| Prompt missing in VS Code | Check profile, WSL extension host, harness and supported prompt location. |
| Skill exists but not loaded | Check `SKILL.md`, metadata, scope and runtime discovery. |
| Scanner missing | Use Section 7.1, install only approved required tools, rerun fixtures. |
| MCP running but tools absent | Verify policy, authentication and actual tool-call trace. |
| PowerShell execution policy blocks restore | Follow approved signing/policy process; do not bypass. |
| Hash mismatch | Preserve rollback state; compare source commit and destination paths. |
| Old-history clone detected | Do not push from it; use a fresh sanitized clone. |
| Historical exposure concern | Review credential rotation and GitHub's sensitive-data removal guidance. |

## Official references

- [VS Code prompt files](https://code.visualstudio.com/docs/agent-customization/prompt-files)
- [VS Code WSL development](https://code.visualstudio.com/docs/remote/wsl)
- [VS Code Profiles](https://code.visualstudio.com/docs/configure/profiles)
- [VS Code Settings Sync](https://code.visualstudio.com/docs/configure/settings-sync)
- [GitHub Copilot agent skills](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills)
- [GitHub Copilot CLI setup](https://docs.github.com/en/copilot/how-tos/copilot-cli/set-up-copilot-cli/install-copilot-cli)
- [GitHub SSH verification](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/testing-your-ssh-connection)
- [GitHub secret scanning](https://docs.github.com/en/code-security/concepts/secret-security/secret-scanning)
- [GitHub removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [HashiCorp Terraform installation](https://developer.hashicorp.com/terraform/install)
- [TFLint installation](https://github.com/terraform-linters/tflint)
- [Checkov installation](https://www.checkov.io/2.Basics/Installing%20Checkov.html)
- [Trivy installation](https://trivy.dev/docs/latest/getting-started/installation/)
- [Gitleaks releases](https://github.com/gitleaks/gitleaks/releases)
- [Helm installation](https://helm.sh/docs/intro/install/)
- [kubectl installation](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [Azure CLI Linux installation](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux)
- [Microsoft WSL commands](https://learn.microsoft.com/en-us/windows/wsl/basic-commands)
- [PowerShell Get-FileHash](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-filehash?view=powershell-5.1)

---

**Maintenance note:** This README documents the sanitized GitHub recovery baseline verified on 13 November 2026. Update the checkpoint and toolchain version evidence after future approved backups. Do not republish the private historical recovery mirror or bundle.
