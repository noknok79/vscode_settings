# Unified VS Code + GitHub Copilot Backup, Verification and Restoration

**Updated:** 12 November 2026  
**Repository:** `noknok79/vscode_settings` (`main`)  
**Target:** Windows VS Code Stable + WSL Ubuntu (`root`, `/root/.copilot`)  
**Purpose:** Restore approved Copilot customizations, validate them, and recover safely without overwriting credentials or unrelated configuration.

> **Safety:** This guide describes a tested backup and selected clean-clone checks on the original machine. It does **not** certify a full restore on a second machine. Review the repository for secrets and employer-confidential material before storing it in a personal GitHub account. Never back up tokens, private SSH keys, session state or `~/.copilot/config.json`.

## 1. Choose your workflow

| Goal | Sections |
|---|---|
| Restore all approved VS Code and Copilot customizations | 2–6, then 9–10 |
| Restore only DevSecOps validation | 2–3, 7, 9 |
| Restore Technical Writer components | 2–3, 8, 9 |
| Use Bash, PowerShell, Python and pipeline simplification | 9 |
| Back up new local changes | 10 |

## 2. Prerequisites

- Windows VS Code Stable, WSL Ubuntu 22.04+, Windows PowerShell, Git, SSH, Python 3 and authorized access to the backup repository.
- The documented target uses WSL user `root` with `HOME=/root`. Adapt paths if using another user or `COPILOT_HOME`.
- Keep the `github-noknok79` SSH identity separate from `dbg-mark-villanueva`. Verify GitHub's published host key before trusting it. Do not overwrite existing keys.
- The intended GitHub Copilot subscription account, SSH identity and MCP authentication identity are separate and must be verified separately.
- Inspect any proposed changes before restoring; close VS Code/Copilot CLI and pause Settings Sync for full restoration.

Check the environment in WSL:

```bash
whoami
printf 'HOME=%s\nCOPILOT_HOME=%s\n' "$HOME" "${COPILOT_HOME:-<unset>}"
git --version
python3 --version
ssh -T git@github-noknok79
```

GitHub's successful SSH greeting can return exit status 1. Confirm the greeting says `Hi noknok79!`; don't treat the exit code alone as proof.

## 3. Download and verify the backup snapshot

Use a fresh, empty clone location:

```bash
set -euo pipefail
REMOTE='git@github-noknok79:noknok79/vscode_settings.git'
CLONE="/root/vscode_settings_review_$(date +%Y%m%d-%H%M%S)"
git clone --branch main --single-branch "$REMOTE" "$CLONE"
LOCAL=$(git -C "$CLONE" rev-parse HEAD)
REMOTE_SHA=$(git ls-remote --exit-code "$REMOTE" refs/heads/main | awk '{print $1}')
test "$LOCAL" = "$REMOTE_SHA"
git -C "$CLONE" fsck --full --no-reflogs
test -z "$(git -C "$CLONE" status --porcelain)"
printf 'Verified commit: %s\nClone: %s\n' "$LOCAL" "$CLONE"
```

Commit equality and Git object integrity do not establish that the content is safe, current or compatible. Review tracked files and history before restoration.

**Historical verified commits:**

- Technical Writer four-component backup: `6cc087d310468f6232932175df9b29dc91508bd0`.
- DevSecOps six-file backup and clean-clone comparison: `8c073e6180b424357b15b4810f57868a7140a60c`.

These are **historical checkpoints**, not assertions about the current `main` commit. Never replace a current checkout with an older commit without reviewing changes.

## 4. Full automated restoration

The restore launcher requires three implementation files **together at the chosen working directory root**, not inside an assumed `restore-copilot/` subfolder:

```text
Restore-Copilot.ps1
restore.sh
restore_files.py
```

The repository backup payload (`copilot/`, `vscode/`, `wsl/`) is a separate source that the launcher clones. Do not move the payload into the script directory or change relative paths without inspecting the scripts.

From a standalone **Windows PowerShell** terminal in the directory containing these three scripts:

```powershell
$Required = 'Restore-Copilot.ps1','restore.sh','restore_files.py'
foreach ($Name in $Required) {
    if (-not (Test-Path -LiteralPath (Join-Path (Get-Location) $Name) -PathType Leaf)) {
        throw "Missing: $Name"
    }
}
.\Restore-Copilot.ps1 -Distro Ubuntu
```

Replace `Ubuntu` with the exact installed distribution name. The documented launcher uses approval gates:

1. **PREPARE:** permit reviewed prerequisite checks/installation and cloning; do not approve replacement yet.
2. Inspect the generated plan, selected commit, file paths, hashes, hooks, MCP definitions and settings. Preserve the printed `/root/copilot-restore-...` run directory.
3. **RESTORE:** authorize only the reviewed replacements; the helper snapshots existing destinations and checks hashes.
4. Optional **INSTALL:** install/check Copilot CLI only if authorized; optionally choose approved Windows-local extension IDs. WSL extensions need their own scope review.
5. Inspect `verification.json`, `verification.md` if present, and `rollback.json`. A file-hash success is not runtime success.

**Do not** bypass PowerShell execution policy, run `rm -rf ~/.copilot`, use `rsync --delete`, force-push, or replace authentication state. If restoration fails, preserve the run directory and inspect rollback metadata before retrying.

For explicit rollback, from WSL root and with the actual paths:

```bash
bash /path/to/restore.sh rollback '/root/copilot-restore-<actual-run-id>'
```

The rollback action requires confirmation and checks recorded hashes; package, CLI and extension installations are not automatically rolled back.

## 5. Manual selective restoration

Use this when only a few files are missing, or when the automated allowlist does not include recent additions.

1. Review the selected tracked source files from the verified clone.
2. Check destination paths for symlinks and existing files.
3. If a destination differs, **stop and review** rather than overwriting it automatically.
4. Copy only approved absent files or approved replacements after saving rollback copies.
5. Verify each copied file with `cmp` and SHA-256, including executable modes where relevant.

Example for a reviewed file:

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

Never blindly copy shell profiles, SSH configuration, machine-specific Windows settings, MCP credentials, or corporate configuration to another device.

## 6. Configuration inventory and security review

Expected backup categories, when present:

```text
copilot/agents/
copilot/instructions/
copilot/prompts/
copilot/skills/
copilot/hooks/
copilot/config/mcp-config.json
vscode/user/
vscode/remote/
wsl/
```

The older guide's **20 agents / 14 instructions / 25 prompts / 27 skills / 10 hooks** counts are historical only. Compare the restored inventory with the **same selected Git commit**, not with fixed old counts.

```bash
COPILOT="$HOME/.copilot"
for category in agents instructions prompts skills hooks; do
  printf '%s: ' "$category"
  case "$category" in
    agents) find "$COPILOT/$category" -type f -name '*.agent.md' | wc -l ;;
    instructions) find "$COPILOT/$category" -type f -name '*.instructions.md' | wc -l ;;
    prompts) find "$COPILOT/$category" -type f -name '*.prompt.md' | wc -l ;;
    skills) find "$COPILOT/$category" -type f -name SKILL.md | wc -l ;;
    hooks) find "$COPILOT/$category" -maxdepth 1 -type f -name '*.json' | wc -l ;;
  esac
done
```

Run secret scanning on the reviewed payload and inspect repository history. A clean scanner result is not proof of absence of confidential material. Never restore `~/.copilot/config.json`, OAuth tokens, `mcp-oauth-config/`, private keys, caches or session-state.

## 7. DevSecOps validation skill: verified addition

**Global destination:** `~/.copilot/skills/devsecops-validation/`  
**Backup path:** `copilot/skills/devsecops-validation/`

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

Supported local validation includes Bash/ShellCheck, Terraform formatting/TFLint/Checkov, Trivy Kubernetes checks, Gitleaks and Helm. Applicability depends on installed tools and input type; a skipped check is not a pass.

**Verified baseline for `scripts/validate.sh`:**

```text
261bbbe26e32097be09162989ca957b0e6aeca991bd28f48426d98c70ac191bf
```

**Evidence on original machine (12 Nov 2026):** 16 regression scenarios passed; JSON report status, exit codes, atomic publication, permissions and temporary cleanup were checked. The six skill files passed source/backup SHA-256 comparisons, GitHub push verification, executable-mode checks and a fresh-clone comparison at commit `8c073e6180b424357b15b4810f57868a7140a60c`.

After restoring, verify the known validator hash if restoring that exact baseline:

```bash
SKILL="$HOME/.copilot/skills/devsecops-validation"
test -s "$SKILL/SKILL.md"
test -x "$SKILL/scripts/validate.sh"
sha256sum "$SKILL/scripts/validate.sh"
bash -n "$SKILL/scripts/validate.sh"
shellcheck -x -P "$SKILL/scripts" "$SKILL/scripts/validate.sh"
```

For runtime acceptance, open VS Code in WSL, confirm the skill is discoverable, invoke a **read-only** validation against an approved test fixture, and inspect the actual JSON report and exit code. A fresh-machine scanner installation and full runtime integration have not been independently verified by the clean-clone test.

## 8. Technical Writer components: focused restore

Restore and verify these four files against the selected reviewed snapshot:

```text
copilot/agents/technical-writer.agent.md
copilot/prompts/runbook.prompt.md
copilot/skills/runbook/SKILL.md
copilot/skills/technical-documentation/SKILL.md
```

The verified historical backup commit is `6cc087d310468f6232932175df9b29dc91508bd0`. It was validated by source hashes and fresh clones on the original machine, not by a complete second-machine runtime test. The historical `/runbook` prompt used `agent: agent`; it did not inherently select the `technical-writer` agent.

After restoration, verify file bytes, inspect skill discovery and agent selection in VS Code, and generate a sample non-sensitive technical runbook. Do not claim success solely from file existence.

## 9. Scripting standards and six-phase refactoring

The current setup includes global simplicity guidance for Bash, PowerShell and Azure Pipelines:

```text
~/.copilot/instructions/bash.instructions.md
~/.copilot/instructions/powershell.instructions.md
~/.copilot/instructions/azure-pipelines.instructions.md
~/.copilot/instructions/devops-global.instructions.md
```

**Reusable prompts:**

```text
~/.copilot/prompts/simplify-pipeline.prompt.md
~/.copilot/prompts/python-to-azure-pipeline.prompt.md
```

- **`/simplify-pipeline`:** Improve an existing Bash, PowerShell, Python script or Azure Pipeline. When both pipeline and original script exist, the pipeline is the primary implementation and the script is a behavioral reference. Do not rebuild a working pipeline unnecessarily.
- **`/python-to-azure-pipeline`:** Propose a new pipeline for a Python workflow when no suitable pipeline exists.
- **`devops-engineer`:** Preferred agent for these workflows.

The updated `/simplify-pipeline` prompt has a **six-phase workflow**:

1. **Audit:** inspect dependencies, Git state, hashes, line counts and controls.
2. **Propose:** smallest safe changes, risks and expected benefits. **Stop for explicit approval.**
3. **Implement:** preserve a baseline and change only approved files.
4. **Validate:** Bash/ShellCheck/shfmt, PowerShell parser/PSScriptAnalyzer/Pester, Python syntax/tests/linters, or relevant YAML/schema checks.
5. **Compare:** inputs, outputs, exit codes, external commands, approvals and security; use isolated mocks for destructive services.
6. **Report:** line counts, `git diff --stat`, `git diff --numstat`, tests, gaps and untracked files.

Never commit, push, deploy, remove ACR manifests, or execute destructive infrastructure operations automatically as part of this workflow.

**Local synchronization evidence:** The updated six-phase prompt was installed in WSL and copied to the Windows VS Code user prompt directory; both copies matched SHA-256 `9736db3f85dc0cbab649bdeb95a4e95553b8a779f44cbe33f8e0c6a129420abf` on 12 Nov 2026. This does **not** prove the updated prompt has been committed to GitHub or that a fresh-machine Copilot harness will load it.

**Prompt discovery caveat:** Local and Copilot Fusion harnesses may expose prompt files differently. Verify the active VS Code profile, WSL extension host, recognized prompt settings, and actual slash-command availability. Do not assume an absolute Linux path in Windows user settings is valid. Skills and prompts are different customization mechanisms; migrating to a skill may change how a workflow is invoked.

## 10. Back up subsequent changes and verify recovery

**Known gap:** The DevSecOps six-file backup is verified on GitHub. The newer PowerShell instruction and two updated refactoring prompts were verified locally, but their latest GitHub backup has **not** been established by the evidence recorded here.

From the existing clean backup checkout:

```bash
cd /root/vscode_settings_clean || exit 1
git status -sb
git remote -v
```

Before copying, verify that the backup is authorized and sanitized. Copy only reviewed customizations to their matching `copilot/` paths, compare source and destination hashes, and run Gitleaks or an approved scanner. Stage **explicit paths only**; do not use `git add .` with local backups or unrelated files present.

Example of intended staged paths after reviewing and copying:

```bash
git add -- \
  copilot/instructions/powershell.instructions.md \
  copilot/prompts/simplify-pipeline.prompt.md \
  copilot/prompts/python-to-azure-pipeline.prompt.md
git diff --cached --check
git diff --cached --stat
git diff --cached --name-status
```

Review `git diff --cached` for sensitive data, then commit and push only when authorized. Fetch remote history first; do not force-push. Verify the pushed remote commit with `git ls-remote`, then perform a fresh-clone file/hash comparison. Updating this README does not by itself back up the files it describes.

## 11. Runtime acceptance and final sign-off

- [ ] Approved, sanitized source and intended GitHub identity confirmed.
- [ ] Selected Git commit cloned, matched remote, and passed `git fsck`.
- [ ] Correct Windows profile, WSL user/home, extension scope and target paths confirmed.
- [ ] Existing destination files backed up and reviewed before replacement.
- [ ] Restored files matched source hashes; executable modes preserved where applicable.
- [ ] Agents, prompts, skills and instructions appear in the intended VS Code/Copilot runtime.
- [ ] DevSecOps skill executed a safe check and produced a verified JSON report.
- [ ] Six-phase prompt stopped after proposal and required approval before edits.
- [ ] MCP tool execution and a non-destructive hook test observed, if configured.
- [ ] A second workspace confirms user-level customization availability.
- [ ] Verification reports, rollback inventory, commit ID and remaining gaps recorded.

**Four distinct proofs:** Git integrity, byte equality, syntax/static checks and runtime behavior. Passing one does not imply the others.

## 12. Troubleshooting

| Symptom | Safe response |
|---|---|
| Wrong GitHub SSH account | Inspect `ssh -G github-noknok79` and test SSH; don't change other identities. |
| `fetch first` on push | Fetch and review divergence; rebase only after inspection; never force-push. |
| Prompt missing from slash commands | Check active profile, harness, WSL/local extension host and supported prompt locations; file existence alone is insufficient. |
| Missing skill after restore | Verify `SKILL.md`, metadata, intended home and runtime discovery. |
| `diff -qr` produces no output | Confirm exit code 0 before calling it equal. |
| MCP server shows Running but tools absent | Inspect actual tool-call trace, permissions and authentication. |
| PowerShell execution policy blocks launcher | Stop and use approved signing/policy procedure; don't bypass restrictions. |
| Restore hash mismatch | Preserve rollback inventory; compare paths and source snapshot before retrying. |
| Extra local files after restore | This procedure deliberately avoids blanket deletion; inspect extras manually. |

## Official references

- [VS Code prompt files](https://code.visualstudio.com/docs/agent-customization/prompt-files)
- [VS Code WSL development](https://code.visualstudio.com/docs/remote/wsl)
- [VS Code Profiles](https://code.visualstudio.com/docs/configure/profiles)
- [VS Code Settings Sync](https://code.visualstudio.com/docs/configure/settings-sync)
- [GitHub Copilot agent skills](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills)
- [GitHub Copilot CLI setup](https://docs.github.com/en/copilot/how-tos/copilot-cli/set-up-copilot-cli/install-copilot-cli)
- [GitHub SSH verification](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/testing-your-ssh-connection)
- [GitHub secret scanning](https://docs.github.com/en/code-security/concepts/secret-security/secret-scanning)
- [Microsoft WSL commands](https://learn.microsoft.com/en-us/windows/wsl/basic-commands)
- [PowerShell Get-FileHash](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-filehash?view=powershell-5.1)

---

**Maintenance note:** This is a single consolidated README for the currently discussed setup. Historical commits and test results are explicitly labeled. Update the file inventory, tested commit, and runtime evidence after future backups and restorations.
