#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO="${COPILOT_MAINTENANCE_REPO:-$(cd -- "$SCRIPT_DIR/../.." && pwd)}"

echo "=== RESTORE REGRESSION ==="

for file in \
    restore.sh \
    restore_files.py \
    Restore-Copilot.ps1 \
    tests/test_restore.py
do
    if [[ ! -f "$REPO/$file" ]]; then
        echo "[FAIL] Missing restore component: $file"
        exit 2
    fi
done

echo "[PASS] Restore components available"

cd "$REPO"

python3 -B -m unittest \
    tests.test_restore.RestoreTests \
    -v

echo "[PASS] Restore regression suite"
