#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VALIDATOR="$SCRIPT_DIR/../validate-prompts.py"
COPILOT_DIR="${COPILOT_HOME:-$HOME/.copilot}"

test -f "$VALIDATOR"
command -v python3 >/dev/null

TEST_DIR=$(mktemp -d /tmp/copilot-prompt-regression.XXXXXX)
trap 'rm -rf -- "$TEST_DIR"' EXIT

mkdir -p "$TEST_DIR/prompts" "$TEST_DIR/agents"

cat > "$TEST_DIR/prompts/valid.prompt.md" <<'EOF'
---
description: Valid regression prompt
agent: agent
---

# Valid Prompt
EOF

failures=0

run_case() {
    local name="$1"
    local expected="$2"
    local actual=0

    python3 -B "$VALIDATOR" \
        --home "$TEST_DIR" \
        >"$TEST_DIR/$name.log" 2>&1 || actual=$?

    if [[ "$actual" -eq "$expected" ]]; then
        echo "[PASS] $name"
    else
        echo "[FAIL] $name: expected=$expected actual=$actual"
        ((failures+=1))
    fi
}

run_case "PROMPT-001" 0

printf '%s\n' '# Missing frontmatter' \
    > "$TEST_DIR/prompts/missing.prompt.md"

run_case "PROMPT-002" 1
rm "$TEST_DIR/prompts/missing.prompt.md"

printf '%s\n' \
    '---' \
    'description: [invalid' \
    '---' \
    '# Invalid YAML' \
    > "$TEST_DIR/prompts/invalid.prompt.md"

run_case "PROMPT-003" 1
rm "$TEST_DIR/prompts/invalid.prompt.md"

printf '%s\n' \
    '---' \
    'description: Invalid filename' \
    '---' \
    '# Invalid Name' \
    > "$TEST_DIR/prompts/Invalid_Name.prompt.md"

run_case "PROMPT-004" 1
rm "$TEST_DIR/prompts/Invalid_Name.prompt.md"

printf '%s\n' \
    '---' \
    'description: Unresolved agent reference' \
    'agent: nonexistent-agent' \
    '---' \
    '# Unresolved Agent' \
    > "$TEST_DIR/prompts/unresolved.prompt.md"

run_case "PROMPT-005" 0

if ! grep -Fq '[WARN] Unresolved agent:' \
    "$TEST_DIR/PROMPT-005.log"; then
    echo "[FAIL] PROMPT-005: warning missing"
    ((failures+=1))
fi

echo
echo "=== ACTIVE PROMPT VALIDATION ==="

python3 -B "$VALIDATOR" --home "$COPILOT_DIR"

echo
echo "Prompt regression failures: $failures"

if (( failures > 0 )); then
    exit 1
fi

echo "[PASS] Prompt regression suite"
