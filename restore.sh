#!/usr/bin/env bash
set -euo pipefail
umask 077

if (( $# < 2 )); then
  echo 'Usage: bash restore.sh prepare|apply|verify|rollback|install-cli|extensions-status RUN_DIRECTORY [ARGUMENTS]' >&2
  exit 2
fi

action=$1
run=$2
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
[[ $run =~ ^/root/copilot-restore-[a-f0-9]{32}$ ]] || {
  echo 'FAIL: Run directory must be /root/copilot-restore- followed by a 32-character hexadecimal ID' >&2
  exit 2
}
[[ $(id -u) == 0 && $HOME == /root ]] || { echo 'FAIL: Run as root with HOME=/root' >&2; exit 1; }
[[ -z ${COPILOT_HOME:-} ]] || { echo 'FAIL: COPILOT_HOME is set; adapt the restore target first' >&2; exit 1; }
# shellcheck source=/dev/null
. /etc/os-release
[[ $ID == ubuntu ]] || { echo 'FAIL: This installer targets Ubuntu only' >&2; exit 1; }
(( ${VERSION_ID%%.*} >= 22 )) || { echo 'FAIL: Ubuntu 22.04 or newer is required' >&2; exit 1; }

case "$action" in
  prepare)
    (( $# == 3 || $# == 4 )) || { echo 'FAIL: prepare requires the Windows VS Code User directory' >&2; exit 2; }
    [[ -d $3 && $3 == /mnt/* ]] || { echo 'FAIL: Windows VS Code User directory not found under /mnt' >&2; exit 1; }
    settings=()
    if (( $# == 4 )); then
      [[ $4 == --cli-settings ]] || { echo 'FAIL: Unknown prepare option' >&2; exit 2; }
      settings=(--cli-settings)
    fi
    mkdir -m 700 -- "$run"
    printf 'Run directory: %s\n' "$run"
    packages=()
    for pair in git:git ssh:openssh-client python3:python3 curl:curl tar:tar gzip:gzip; do
      command -v "${pair%%:*}" >/dev/null 2>&1 || packages+=("${pair#*:}")
    done
    [[ -s /etc/ssl/certs/ca-certificates.crt ]] || packages+=(ca-certificates)
    if (( ${#packages[@]} )); then
      printf 'Installing missing Ubuntu packages: %s\n' "${packages[*]}"
      apt-get update
      apt-get install -y --no-install-recommends "${packages[@]}"
    fi
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
    [[ -f $run/plan.json ]] || { echo 'FAIL: Prepare the reviewed restore first' >&2; exit 1; }
    if ! command -v copilot >/dev/null 2>&1; then
      curl --proto '=https' --proto-redir '=https' --tlsv1.2 -fsSL \
        https://gh.io/copilot-install -o "$run/copilot-install.sh"
      echo 'Downloaded official GitHub installer SHA-256 (audit record, not a publisher signature):'
      sha256sum "$run/copilot-install.sh"
      PATH="/usr/local/bin:$PATH" VERSION=latest PREFIX=/usr/local bash "$run/copilot-install.sh"
      hash -r
    fi
    PATH="/usr/local/bin:$PATH" copilot --version | tee "$run/copilot-status.txt"
    ;;
  extensions-status)
    [[ -f $run/plan.json ]] || { echo 'FAIL: No prepared restore plan' >&2; exit 1; }
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
