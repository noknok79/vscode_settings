#!/usr/bin/env bash
set -euo pipefail

VALIDATOR="${COPILOT_HOME:-$HOME/.copilot}/skills/devsecops-validation/scripts/validate.sh"

test -f "$VALIDATOR"

for tool in gitleaks jq; do
    command -v "$tool" >/dev/null
done

unset DEVSECOPS_JSON_REPORT
unset DEVSECOPS_REPORT_DIR
unset DEVSECOPS_SCANNER_DIR
unset DEVSECOPS_RESULTS_FILE

TEST_DIR=$(mktemp -d /tmp/devsecops-gitleaks-regression.XXXXXX)
trap 'rm -rf -- "$TEST_DIR"' EXIT

mkdir -p "$TEST_DIR/clean" "$TEST_DIR/findings"

printf '%s\n' "Harmless test fixture" \
    > "$TEST_DIR/clean/example.txt"

cat > "$TEST_DIR/gitleaks.toml" <<'CONFIG_EOF'
title = "DevSecOps Regression"

[[rules]]
id = "devsecops-test-marker"
description = "Synthetic test marker"
regex = '''DEVSECOPS_TEST_SECRET_[A-Z0-9]{12}'''
keywords = ["DEVSECOPS_TEST_SECRET_"]
CONFIG_EOF

printf '%s\n' "DEVSECOPS_TEST_SECRET_ABC123DEF456" \
    > "$TEST_DIR/findings/example.txt"

failures=0

run_case() {
    local name="$1"
    local expected="$2"
    local directory="$3"
    local status="$4"
    local report="$TEST_DIR/$name.json"
    local actual=0

    GITLEAKS_CONFIG="$TEST_DIR/gitleaks.toml" \
        bash "$VALIDATOR" \
        --json-report "$report" \
        --secrets "$directory" \
        >"$TEST_DIR/$name.log" 2>&1 || actual=$?

    if [[ "$actual" -ne "$expected" ]]; then
        echo "[FAIL] $name: expected=$expected actual=$actual"
        ((failures+=1))
        return 0
    fi

    if [[ ! -f "$report" ]]; then
        echo "[FAIL] $name: report missing"
        ((failures+=1))
        return 0
    fi

    if ! jq -e \
        --argjson code "$expected" \
        --arg status "$status" \
        '
        .exitCode == $code
        and any(.checks[];
            .tool == "gitleaks"
            and .check == "secret-scan"
            and .status == $status
            and (
                if $status == "PASS"
                then .findings == 0
                else .findings > 0
                end
            ))
        ' "$report" >/dev/null; then

        echo "[FAIL] $name: JSON mismatch"
        ((failures+=1))
        return 0
    fi

    echo "[PASS] $name"
}

run_case "GITLEAKS-001" 0 "$TEST_DIR/clean" PASS
run_case "GITLEAKS-002" 1 "$TEST_DIR/findings" FAIL

echo "Gitleaks regression failures: $failures"

if (( failures > 0 )); then
    exit 1
fi

echo "[PASS] Gitleaks regression suite"
