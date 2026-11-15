#!/usr/bin/env bash
set -euo pipefail

REPO="${COPILOT_MAINTENANCE_REPO:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
CHECKER="$REPO/scripts/copilot-health-check.py"
COPILOT_DIR="${COPILOT_HOME:-$HOME/.copilot}"

REGRESSION_RUNNER="${COPILOT_REGRESSION_RUNNER:-$REPO/scripts/regression/run-all.sh}"

usage() {
  cat <<'USAGE'
Usage: copilot-maintenance.sh [--regression|--full|--help]

No arguments   Run existing maintenance checks.
--regression   Run regression suites only.
--full         Run maintenance followed by regression.
--help         Show this help.
USAGE
}

MODE="${1:-maintenance}"

if [[ $# -gt 1 ]]; then
  usage
  exit 2
fi

case "$MODE" in
  maintenance)
    ;;
  --regression|--full)
    if [[ ! -f "$REGRESSION_RUNNER" ]]; then
      echo "[FAIL] Regression runner missing"
      exit 2
    fi
    ;;
  --help)
    usage
    exit 0
    ;;
  *)
    usage
    exit 2
    ;;
esac

if [[ "$MODE" == "--regression" ]]; then
  exec bash "$REGRESSION_RUNNER"
fi

echo "========================================"
echo " COPILOT CONFIGURATION MAINTENANCE"
echo "========================================"

echo
echo "=== 1. CONFIGURATION HEALTH ==="

python3 -B "$CHECKER" \
  --home "$COPILOT_DIR" |
  tail -6

echo
echo "=== 2. CONFIGURATION DRIFT ==="

python3 -B "$CHECKER" \
  --home "$COPILOT_DIR" \
  --drift \
  --backup "$REPO/copilot" |
  grep -E '^\[WARN\]|^PASS:|^WARN:|^FAIL:'

echo
echo "=== 3. GIT STATUS ==="

git -C "$REPO" status -sb

if [ -n "$(git -C "$REPO" status --porcelain)" ]; then
  echo "[WARN] Backup repository has uncommitted changes"
else
  echo "[PASS] Backup repository working tree clean"
fi

echo
echo "=== 4. SECRET SCAN ==="

gitleaks dir "$REPO" \
  --no-banner \
  --redact=100 \
  --exit-code 1

echo

echo
echo "=== 5. REUSABLE PROMPT BACKUP ==="

GLOBAL_PROMPTS="$COPILOT_DIR/prompts"
BACKUP_PROMPTS="$REPO/copilot/prompts"

if [[ ! -d "$GLOBAL_PROMPTS" || ! -d "$BACKUP_PROMPTS" ]]; then
  echo "[FAIL] Prompt directory missing"
  exit 1
fi

if [[ ! -f "$GLOBAL_PROMPTS/save-session-prompts.prompt.md" ]]; then
  echo "[WARN] Session-saving prompt missing"
fi

missing=0
different=0
matched=0
backup_only=0

for file in "$GLOBAL_PROMPTS"/*.prompt.md; do
  [[ -f "$file" ]] || continue

  name="${file##*/}"

  if [[ ! -f "$BACKUP_PROMPTS/$name" ]]; then
    echo "[WARN] Not backed up: $name"
    ((missing+=1))
  elif ! cmp -s -- "$file" "$BACKUP_PROMPTS/$name"; then
    echo "[WARN] Content differs: $name"
    ((different+=1))
  else
    ((matched+=1))
  fi
done

for file in "$BACKUP_PROMPTS"/*.prompt.md; do
  [[ -f "$file" ]] || continue

  name="${file##*/}"

  if [[ ! -f "$GLOBAL_PROMPTS/$name" ]]; then
    echo "[INFO] Backup-only prompt: $name"
    ((backup_only+=1))
  fi
done

echo "Matched prompts: $matched"
echo "Missing backups: $missing"
echo "Content differences: $different"
echo "Backup-only prompts: $backup_only"

if (( missing == 0 && different == 0 )); then
  echo "[PASS] All active reusable prompts backed up"
else
  echo "[WARN] Reusable prompt backup requires review"
fi

echo "========================================"
echo " MAINTENANCE CHECK COMPLETE"
echo "========================================"

if [[ "$MODE" == "--full" ]]; then
  echo
  echo "=== 6. DEVSECOPS REGRESSION ==="
  bash "$REGRESSION_RUNNER"
fi
