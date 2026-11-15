#!/usr/bin/env bash
set -euo pipefail

VALIDATOR="${COPILOT_HOME:-$HOME/.copilot}/skills/devsecops-validation/scripts/validate.sh"

test -f "$VALIDATOR"

for tool in bash shellcheck jq python3; do
    command -v "$tool" >/dev/null
done

unset DEVSECOPS_JSON_REPORT
unset DEVSECOPS_REPORT_DIR
unset DEVSECOPS_SCANNER_DIR
unset DEVSECOPS_RESULTS_FILE

TEST_DIR=$(mktemp -d /tmp/devsecops-json-regression.XXXXXX)
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
    local expected_exit="$2"
    local expected_pass="$3"
    local expected_fail="$4"
    local expected_skip="$5"
    local target="$6"

    local report="$TEST_DIR/$name.json"
    local actual=0

    bash "$VALIDATOR" \
        --json-report "$report" "$target" \
        >"$TEST_DIR/$name.log" 2>&1 || actual=$?

    if [[ "$actual" -ne "$expected_exit" ]]; then
        echo "[FAIL] $name: unexpected exit $actual"
        ((failures+=1))
        return 0
    fi

    if [[ ! -f "$report" ]]; then
        echo "[FAIL] $name: report missing"
        ((failures+=1))
        return 0
    fi

    if ! jq -e \
        --argjson code "$expected_exit" \
        --argjson passed "$expected_pass" \
        --argjson failed "$expected_fail" \
        --argjson skipped "$expected_skip" \
        '
        .exitCode == $code
        and .summary.passed == $passed
        and .summary.failed == $failed
        and .summary.skipped == $skipped
        and .summary.errors == 0
        ' "$report" >/dev/null; then

        echo "[FAIL] $name: JSON summary mismatch"
        ((failures+=1))
        return 0
    fi

    echo "[PASS] $name"
}

run_case "JSON-001" 0 2 0 0 "$TEST_DIR/valid.sh"
run_case "JSON-002" 1 0 2 0 "$TEST_DIR/invalid.sh"
run_case "JSON-003" 3 0 0 1 "$TEST_DIR/unsupported.txt"

echo
echo "JSON regression failures: $failures"

if (( failures > 0 )); then
    exit 1
fi

echo "[PASS] JSON regression suite"
