#!/usr/bin/env bash
set -euo pipefail

VALIDATOR="${COPILOT_HOME:-$HOME/.copilot}/skills/devsecops-validation/scripts/validate.sh"

test -f "$VALIDATOR"
command -v jq >/dev/null
command -v shellcheck >/dev/null

unset DEVSECOPS_JSON_REPORT
unset DEVSECOPS_REPORT_DIR
unset DEVSECOPS_SCANNER_DIR
unset DEVSECOPS_RESULTS_FILE

TEST_DIR=$(mktemp -d /tmp/devsecops-cleanup-regression.XXXXXX)
trap 'rm -rf -- "$TEST_DIR"' EXIT

cat > "$TEST_DIR/valid.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "Valid"
EOF

cat > "$TEST_DIR/invalid.sh" <<'EOF'
#!/usr/bin/env bash
if then
    echo "Invalid"
fi
EOF

printf '%s\n' "Unsupported" > "$TEST_DIR/unsupported.txt"

failures=0

run_case() {
    local name="$1"
    local expected="$2"
    local target="$3"
    local report="$TEST_DIR/$name.json"
    local log="$TEST_DIR/$name.log"
    local actual=0
    local internal_dir

    bash "$VALIDATOR" \
        --json-report "$report" "$target" \
        >"$log" 2>&1 || actual=$?

    if [[ "$actual" -ne "$expected" ]]; then
        echo "[FAIL] $name: unexpected exit $actual"
        ((failures+=1))
        return 0
    fi

    internal_dir=$(
        sed -n \
            's|^Report written: \(/tmp/devsecops-json\.[^/]*\)/report.json$|\1|p' \
            "$log" | tail -n 1
    )

    if [[ -z "$internal_dir" ]]; then
        echo "[FAIL] $name: temporary directory not identified"
        ((failures+=1))
        return 0
    fi

    if [[ -e "$internal_dir" ]]; then
        echo "[FAIL] $name: temporary directory remains"
        ((failures+=1))
        return 0
    fi

    if [[ ! -f "$report" ]]; then
        echo "[FAIL] $name: published report missing"
        ((failures+=1))
        return 0
    fi

    if ! jq -e \
        --argjson code "$expected" \
        '.exitCode == $code' "$report" >/dev/null; then
        echo "[FAIL] $name: JSON exit code mismatch"
        ((failures+=1))
        return 0
    fi

    echo "[PASS] $name"
}

run_case "CLEAN-001" 0 "$TEST_DIR/valid.sh"
run_case "CLEAN-002" 1 "$TEST_DIR/invalid.sh"
run_case "CLEAN-003" 3 "$TEST_DIR/unsupported.txt"

echo
echo "Cleanup regression failures: $failures"

if (( failures > 0 )); then
    exit 1
fi

echo "[PASS] Cleanup regression suite"
