#!/usr/bin/env bash
set -euo pipefail

VALIDATOR="${COPILOT_HOME:-$HOME/.copilot}/skills/devsecops-validation/scripts/validate.sh"

test -f "$VALIDATOR"

TEST_DIR=$(mktemp -d /tmp/devsecops-security-regression.XXXXXX)
trap 'rm -rf -- "$TEST_DIR"' EXIT

printf '%s\n' "Safe fixture" > "$TEST_DIR/valid.txt"
printf '%s\n' "ORIGINAL_REPORT" > "$TEST_DIR/existing.json"

ln -s "$TEST_DIR/valid.txt" "$TEST_DIR/link.txt"

failures=0

run_case() {
    local name="$1"
    local expected="$2"
    shift 2

    local actual=0

    bash "$VALIDATOR" "$@" \
        >"$TEST_DIR/$name.log" 2>&1 || actual=$?

    if [[ "$actual" -eq "$expected" ]]; then
        echo "[PASS] $name"
    else
        echo "[FAIL] $name: expected=$expected actual=$actual"
        ((failures+=1))
    fi
}

run_case "SEC-001" 2 \
    --json-report "$TEST_DIR/existing.json" "$TEST_DIR/valid.txt"

if [[ "$(cat "$TEST_DIR/existing.json")" != "ORIGINAL_REPORT" ]]; then
    echo "[FAIL] SEC-001: Existing report modified"
    ((failures+=1))
fi

run_case "SEC-002" 2 "$TEST_DIR/missing.sh"

run_case "SEC-003" 2 "$TEST_DIR/link.txt"

run_case "SEC-004" 2 --json-report

run_case "SEC-005" 2 \
    --json-report "$TEST_DIR/nonexistent/report.json" \
    "$TEST_DIR/valid.txt"

echo
echo "Security regression failures: $failures"

if (( failures > 0 )); then
    exit 1
fi

echo "[PASS] Security regression suite"
