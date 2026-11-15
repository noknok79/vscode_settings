#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

REPO="${COPILOT_MAINTENANCE_REPO:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"
COPILOT_DIR="${COPILOT_HOME:-$HOME/.copilot}"

MAINTENANCE="$REPO/scripts/copilot-maintenance.sh"
COLLECTOR="$SCRIPT_DIR/maintenance-collect.py"
REPORTER="$SCRIPT_DIR/maintenance-report.py"

REPORT_DIR="${COPILOT_MAINTENANCE_REPORT_DIR:-$COPILOT_DIR/reports/maintenance}"

MODE="${1:---full}"

case "$MODE" in
    --full)
        REPORT_MODE="full"
        ;;
    --regression)
        REPORT_MODE="regression"
        ;;
    *)
        echo "Usage: copilot-maintenance-report.sh [--full|--regression]"
        exit 2
        ;;
esac

if (( $# > 1 )); then
    echo "[FAIL] Too many arguments"
    exit 2
fi

for file in "$MAINTENANCE" "$COLLECTOR" "$REPORTER"; do
    if [[ ! -f "$file" ]]; then
        echo "[FAIL] Missing component: $file"
        exit 2
    fi
done

umask 077

TEMP_DIR=$(mktemp -d /tmp/copilot-maintenance-report.XXXXXX)
chmod 700 "$TEMP_DIR"

trap 'rm -rf -- "$TEMP_DIR"' EXIT

LOG="$TEMP_DIR/maintenance.log"
COLLECTED="$TEMP_DIR/collected.json"

echo "=== COPILOT MAINTENANCE REPORTING ==="

validation_exit=0

bash "$MAINTENANCE" "$MODE" \
    >"$LOG" 2>&1 || validation_exit=$?

cat "$LOG"

echo
echo "Maintenance exit code: $validation_exit"

collector_exit=0

python3 -B "$COLLECTOR" \
    --log "$LOG" \
    --mode "$REPORT_MODE" \
    --exit-code "$validation_exit" \
    --repo "$REPO" \
    --validator "$COPILOT_DIR/skills/devsecops-validation/scripts/validate.sh" \
    --output "$COLLECTED" || collector_exit=$?

if (( collector_exit != 0 )); then
    echo "[FAIL] Result collection failed"
    if (( validation_exit != 0 )); then
        exit "$validation_exit"
    fi
    exit 1
fi

report_exit=0

python3 -B "$REPORTER" \
    --input "$COLLECTED" \
    --output-dir "$REPORT_DIR" || report_exit=$?

if (( report_exit != 0 )); then
    echo "[FAIL] Report publication failed"
    if (( validation_exit != 0 )); then
        exit "$validation_exit"
    fi
    exit 1
fi

echo "[PASS] Reporting workflow completed"

exit "$validation_exit"
