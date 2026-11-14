#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CHECKER="$REPO/scripts/copilot-health-check.py"
COPILOT_DIR="${COPILOT_HOME:-$HOME/.copilot}"

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
echo "========================================"
echo " MAINTENANCE CHECK COMPLETE"
echo "========================================"
