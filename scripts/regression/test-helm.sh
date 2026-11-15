#!/usr/bin/env bash
set -euo pipefail

VALIDATOR="${COPILOT_HOME:-$HOME/.copilot}/skills/devsecops-validation/scripts/validate.sh"

test -f "$VALIDATOR"

for tool in helm jq python3; do
    command -v "$tool" >/dev/null
done

unset DEVSECOPS_JSON_REPORT
unset DEVSECOPS_REPORT_DIR
unset DEVSECOPS_SCANNER_DIR
unset DEVSECOPS_RESULTS_FILE

TEST_DIR=$(mktemp -d /tmp/devsecops-helm-regression.XXXXXX)
trap 'rm -rf -- "$TEST_DIR"' EXIT

mkdir -p \
    "$TEST_DIR/valid/templates" \
    "$TEST_DIR/invalid/templates" \
    "$TEST_DIR/missing"

cat > "$TEST_DIR/valid/Chart.yaml" <<'EOF'
apiVersion: v2
name: devsecops-test
description: Temporary regression chart
type: application
version: 0.1.0
appVersion: "1.0"
EOF

cat > "$TEST_DIR/valid/templates/configmap.yaml" <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: devsecops-test
data:
  status: "valid"
EOF

cp "$TEST_DIR/valid/Chart.yaml" \
   "$TEST_DIR/invalid/Chart.yaml"

cat > "$TEST_DIR/invalid/templates/configmap.yaml" <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Values.broken
EOF

failures=0

run_case() {
    local name="$1"
    local expected="$2"
    local chart="$3"
    local status="$4"
    local report="$TEST_DIR/$name.json"
    local actual=0

    bash "$VALIDATOR" \
        --json-report "$report" \
        --helm "$chart" \
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
            .tool == "helm"
            and .check == "chart-validation"
            and .status == $status)
        ' "$report" >/dev/null; then

        echo "[FAIL] $name: JSON mismatch"
        ((failures+=1))
        return 0
    fi

    echo "[PASS] $name"
}

run_case "HELM-001" 0 "$TEST_DIR/valid" PASS
run_case "HELM-002" 1 "$TEST_DIR/invalid" FAIL
run_case "HELM-003" 2 "$TEST_DIR/missing" ERROR

echo "Helm regression failures: $failures"

if (( failures > 0 )); then
    exit 1
fi

echo "[PASS] Helm regression suite"
