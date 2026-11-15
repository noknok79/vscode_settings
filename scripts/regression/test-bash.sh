#!/usr/bin/env bash
set -euo pipefail

VALIDATOR="${COPILOT_HOME:-$HOME/.copilot}/skills/devsecops-validation/scripts/validate.sh"

test -f "$VALIDATOR"
command -v shellcheck >/dev/null

TEST_DIR=$(mktemp -d /tmp/devsecops-bash-regression.XXXXXX)
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
    local actual=0

    bash "$VALIDATOR" "$target" \
        >"$TEST_DIR/$name.log" 2>&1 || actual=$?

    if [[ "$actual" -eq "$expected" ]]; then
        echo "[PASS] $name"
    else
        echo "[FAIL] $name: expected=$expected actual=$actual"
        ((failures+=1))
    fi
}

run_case "BASH-001" 0 "$TEST_DIR/valid.sh"
run_case "BASH-002" 1 "$TEST_DIR/invalid.sh"
run_case "BASH-003" 3 "$TEST_DIR/unsupported.txt"

echo "Bash regression failures: $failures"

if (( failures > 0 )); then
    exit 1
fi

echo "[PASS] Bash regression suite"
