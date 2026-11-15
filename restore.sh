#!/usr/bin/env bash
set -euo pipefail
umask 077

if (( $# < 2 )); then
  echo 'Usage: bash restore.sh audit|health|install-prerequisites|prepare|apply|verify|rollback|install-cli|extensions-status RUN_DIRECTORY [ARGUMENTS]' >&2
  exit 2
fi

action=$1
run=$2
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
[[ $HOME == /* && $HOME != / && $HOME != */ && $run == "$HOME"/copilot-restore-* &&
   ${run#"$HOME"/copilot-restore-} =~ ^[a-f0-9]{32}$ ]] || {
  echo 'FAIL: Run directory must be under HOME, named copilot-restore- followed by a 32-character hexadecimal ID' >&2
  exit 2
}
[[ -d $HOME && $(stat -c %u "$HOME") == "$(id -u)" ]] || {
  echo 'FAIL: HOME must exist and be owned by the current user' >&2; exit 1;
}
[[ $(cd -- "$HOME" && pwd -P) == "$HOME" ]] || {
  echo 'FAIL: HOME must be a canonical path without symlinks' >&2; exit 1;
}
[[ ! -L $run ]] || { echo 'FAIL: Run directory cannot be a symlink' >&2; exit 1; }
if [[ -e $run ]]; then
  [[ -d $run && $(stat -c %u "$run") == "$(id -u)" && $(stat -c %a "$run") == 700 ]] || {
    echo 'FAIL: Run directory must be private and owned by the current user' >&2; exit 1;
  }
fi
[[ -z ${COPILOT_HOME:-} ]] || { echo 'FAIL: COPILOT_HOME is set; adapt the restore target first' >&2; exit 1; }
# shellcheck source=/dev/null
. /etc/os-release
[[ $ID == ubuntu ]] || { echo 'FAIL: This installer targets Ubuntu only' >&2; exit 1; }
(( ${VERSION_ID%%.*} >= 22 )) || { echo 'FAIL: Ubuntu 22.04 or newer is required' >&2; exit 1; }

missing_packages() {
  local pair
  for pair in git:git ssh:openssh-client python3:python3 curl:curl tar:tar gzip:gzip; do
    command -v "${pair%%:*}" >/dev/null 2>&1 || printf '%s\n' "${pair#*:}"
  done
  [[ -s /etc/ssl/certs/ca-certificates.crt ]] || printf '%s\n' ca-certificates
  return 0
}

windows_mount() {
  local target=$1 source point type options rest best='' best_source='' best_type='' best_options=''
  while read -r source point type options rest; do
    printf -v source '%b' "$source"
    printf -v point '%b' "$point"
    if [[ $point == / || $target == "$point" || $target == "$point"/* ]] &&
       (( ${#point} >= ${#best} )); then
      best=$point best_source=$source best_type=$type best_options=$options
    fi
  done
  [[ $best_source =~ ^[[:alpha:]]:([\\])?$ ]] &&
    { [[ $best_type == drvfs ]] ||
      [[ $best_type == 9p && ,$best_options, == *",aname=drvfs;"* ]]; }
}

case "$action" in
  audit)
    (( $# == 2 )) || { echo 'FAIL: Unexpected arguments' >&2; exit 2; }
    audit_status=0
    printf 'Ubuntu %s; user %s; HOME %s\n' "$VERSION_ID" "$(id -un)" "$HOME"
    for tool in git ssh python3 curl tar gzip copilot gitleaks; do
      if command -v "$tool" >/dev/null 2>&1; then
        printf 'PASS: %s available\n' "$tool"
      else
        printf 'NOT VERIFIED: %s unavailable\n' "$tool"
        audit_status=3
      fi
    done
    if command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' 2>/dev/null; then
      echo 'PASS: PyYAML available'
    else
      echo 'NOT VERIFIED: PyYAML unavailable'
      audit_status=3
    fi
    if command -v python3 >/dev/null 2>&1 && python3 -c 'import sys; sys.exit(sys.version_info < (3, 9))'; then
      echo 'PASS: Python 3.9 or newer'
    else
      echo 'NOT VERIFIED: Python 3.9 or newer unavailable'
      audit_status=3
    fi
    if [[ -s /etc/ssl/certs/ca-certificates.crt ]]; then
      echo 'PASS: CA certificates available'
    else
      echo 'NOT VERIFIED: CA certificates unavailable'
      audit_status=3
    fi
    echo 'NOT VERIFIED: SSH identity, Copilot subscription, authentication, and runtime acceptance'
    exit "$audit_status"
    ;;
  health)
    (( $# == 2 )) || { echo 'FAIL: Unexpected arguments' >&2; exit 2; }
    if [[ -f $script_dir/scripts/copilot-health-check.py && -d $HOME/.copilot ]] &&
       command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' 2>/dev/null; then
      python3 -B "$script_dir/scripts/copilot-health-check.py" --home "$HOME/.copilot"
    else
      echo 'NOT VERIFIED: Health checker, target configuration, Python 3, or PyYAML unavailable'
      exit 3
    fi
    ;;
  install-prerequisites)
    (( $# == 2 )) || { echo 'FAIL: Unexpected arguments' >&2; exit 2; }
    mapfile -t packages < <(missing_packages)
    if (( ${#packages[@]} )); then
      printf 'Missing Ubuntu packages: %s\n' "${packages[*]}"
      read -r -p 'Type INSTALL to authorize installation of these packages: ' answer
      [[ $answer == INSTALL ]] || { echo 'FAIL: Package installation not approved' >&2; exit 1; }
      if (( $(id -u) == 0 )); then
        apt-get update
        apt-get install -y --no-install-recommends "${packages[@]}"
      else
        command -v sudo >/dev/null 2>&1 || { echo 'FAIL: sudo is required for package installation' >&2; exit 1; }
        sudo apt-get update
        sudo apt-get install -y --no-install-recommends "${packages[@]}"
      fi
      mapfile -t packages < <(missing_packages)
      (( ${#packages[@]} == 0 )) || { echo 'FAIL: Prerequisites remain missing' >&2; exit 1; }
    fi
    ;;
  prepare)
    (( $# == 3 || $# == 4 )) || { echo 'FAIL: prepare requires the Windows VS Code User directory' >&2; exit 2; }
    if ! [[ $3 == /* && -d $3 && $(cd -- "$3" && pwd -P) == "$3" ]] ||
       ! windows_mount "$3" < /proc/mounts; then
      echo 'FAIL: Windows VS Code User directory must be a canonical path on a mounted Windows drive' >&2; exit 1;
    fi
    settings=()
    if (( $# == 4 )); then
      [[ $4 == --cli-settings ]] || { echo 'FAIL: Unknown prepare option' >&2; exit 2; }
      settings=(--cli-settings)
    fi
    mapfile -t packages < <(missing_packages)
    if (( ${#packages[@]} )); then
      echo 'FAIL: Missing prerequisites; run install-prerequisites with explicit approval first' >&2
      printf 'Missing: %s\n' "${packages[*]}" >&2
      exit 1
    fi
    python3 -c 'import sys; sys.exit(sys.version_info < (3, 9))' || {
      echo 'FAIL: Python 3.9 or newer is required' >&2; exit 1;
    }
    mkdir -m 700 -- "$run"
    printf 'Run directory: %s\n' "$run"
    if greeting=$(ssh -o StrictHostKeyChecking=yes -T git@github-noknok79 2>&1); then
      status=0
    else
      status=$?
    fi
    if [[ $greeting != *"Hi noknok79!"* ]] || (( status != 0 && status != 1 )); then
      echo 'FAIL: SSH did not authenticate as noknok79. Complete runbook section 2, including host fingerprint verification.' >&2
      exit 1
    fi
    export GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=yes'
    remote='git@github-noknok79:noknok79/vscode_settings.git'
    remote_sha=$(git ls-remote --exit-code "$remote" refs/heads/main)
    remote_sha=${remote_sha%%$'\t'*}
    git -c core.autocrlf=false clone --branch main --single-branch "$remote" "$run/source"
    [[ $(git -C "$run/source" rev-parse HEAD) == "$remote_sha" ]] || {
      echo 'FAIL: Remote main changed during cloning; start a new run' >&2
      exit 1
    }
    git -C "$run/source" fsck --full --no-reflogs
    python3 "$script_dir/restore_files.py" prepare "$run" --windows-user "$3" "${settings[@]}"
    ;;
  apply|verify)
    (( $# == 2 )) || { echo 'FAIL: Unexpected arguments' >&2; exit 2; }
    python3 "$script_dir/restore_files.py" "$action" "$run"
    ;;
  rollback)
    (( $# == 2 )) || { echo 'FAIL: Unexpected arguments' >&2; exit 2; }
    read -r -p "Type ROLLBACK to restore the recorded previous files from $run: " answer
    [[ $answer == ROLLBACK ]] || { echo 'Cancelled' >&2; exit 1; }
    python3 "$script_dir/restore_files.py" rollback "$run"
    ;;
  install-cli)
    (( $# == 2 )) || { echo 'FAIL: Unexpected arguments' >&2; exit 2; }
    PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
    export PATH
    if ! command -v copilot >/dev/null 2>&1; then
      read -r -p 'Type INSTALL to authorize installation of GitHub Copilot CLI: ' answer
      [[ $answer == INSTALL ]] || { echo 'SKIPPED: Copilot CLI installation not approved'; exit 3; }
      [[ -d $run ]] || mkdir -m 700 -- "$run"
      [[ ! -e $run/copilot-install.sh && ! -L $run/copilot-install.sh ]] || {
        echo 'FAIL: Installer file already exists; use a new run directory' >&2; exit 1;
      }
      curl --proto '=https' --proto-redir '=https' --tlsv1.2 -fsSL \
        https://gh.io/copilot-install -o "$run/copilot-install.sh"
      echo 'Downloaded official GitHub installer SHA-256 (audit record, not a publisher signature):'
      sha256sum "$run/copilot-install.sh"
      if (( $(id -u) == 0 )); then
        VERSION=latest PREFIX=/usr/local bash "$run/copilot-install.sh"
      else
        VERSION=latest PREFIX="$HOME/.local" bash "$run/copilot-install.sh"
      fi
      hash -r
    fi
    [[ -d $run ]] || mkdir -m 700 -- "$run"
    [[ ! -L $run/copilot-status.txt ]] || { echo 'FAIL: Unsafe status file' >&2; exit 1; }
    copilot --version | tee "$run/copilot-status.txt"
    ;;
  extensions-status)
    [[ -f $run/plan.json ]] || { echo 'FAIL: No prepared restore plan' >&2; exit 1; }
    [[ ! -L $run/extensions-status.txt ]] || { echo 'FAIL: Unsafe status file' >&2; exit 1; }
    if (( $# == 2 )); then
      echo 'Extension installation deferred; no extensions changed.' > "$run/extensions-status.txt"
    else
      printf 'Verified Windows Local extension: %s\n' "${@:3}" > "$run/extensions-status.txt"
    fi
    ;;
  *)
    echo "FAIL: Unknown action: $action" >&2
    exit 2
    ;;
esac
