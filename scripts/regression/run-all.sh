#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

REQUIRED_SUITES=(
    test-bash.sh
    test-checkov.sh
    test-cleanup.sh
    test-gitleaks.sh
    test-helm.sh
    test-json.sh
    test-prompts.sh
    test-recording.sh
    test-restore.sh
    test-security.sh
    test-trivy.sh
)

echo "========================================"
echo " COPILOT DEVSECOPS REGRESSION"
echo "========================================"

echo
echo "=== SUITE INVENTORY VALIDATION ==="

declare -A expected=()

for name in "${REQUIRED_SUITES[@]}"; do
    expected["$name"]=1

    file="$SCRIPT_DIR/$name"

    if [[ ! -f "$file" || -L "$file" || ! -r "$file" ]]; then
        echo "[FAIL] Required suite unavailable: $name"
        exit 2
    fi
done

for file in "$SCRIPT_DIR"/test-*.sh; do
    [[ -e "$file" || -L "$file" ]] || continue

    name="${file##*/}"

    if [[ -z "${expected[$name]:-}" ]]; then
        echo "[FAIL] Unexpected suite: $name"
        exit 2
    fi
done

echo "[PASS] All eleven required suites verified"

passed=0
failed=0
skipped=0

for name in "${REQUIRED_SUITES[@]}"; do
    echo
    echo "=== TEST SUITE: $name ==="

    result=0
    bash "$SCRIPT_DIR/$name" || result=$?

    case "$result" in
        0)
            echo "[PASS] $name"
            ((passed+=1))
            ;;
        3)
            echo "[SKIP] $name"
            ((skipped+=1))
            ;;
        *)
            echo "[FAIL] $name (exit=$result)"
            ((failed+=1))
            ;;
    esac
done

echo
echo "========================================"
echo " REGRESSION SUMMARY"
echo "========================================"

echo "Passed: $passed"
echo "Failed: $failed"
echo "Skipped: $skipped"

if (( failed > 0 )); then
    echo "[FAIL] Regression execution failed"
    exit 1
fi

if (( skipped > 0 )); then
    echo "[FAIL] Required regression suites were skipped"
    exit 3
fi

if (( passed != ${#REQUIRED_SUITES[@]} )); then
    echo "[FAIL] Incomplete regression execution"
    exit 2
fi

echo "[PASS] Regression execution complete"
