#!/usr/bin/env bash
set -euo pipefail

VALIDATOR="${COPILOT_HOME:-$HOME/.copilot}/skills/devsecops-validation/scripts/validate.sh"

test -f "$VALIDATOR"

for tool in trivy jq python3; do
    command -v "$tool" >/dev/null
done

unset DEVSECOPS_JSON_REPORT
unset DEVSECOPS_REPORT_DIR
unset DEVSECOPS_SCANNER_DIR
unset DEVSECOPS_RESULTS_FILE

TEST_DIR=$(mktemp -d /tmp/devsecops-trivy-regression.XXXXXX)
trap 'rm -rf -- "$TEST_DIR"' EXIT

cat > "$TEST_DIR/secure.yaml" <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: devsecops-regression
data:
  environment: test
EOF

cat > "$TEST_DIR/insecure.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: insecure-regression
spec:
  replicas: 1
  selector:
    matchLabels:
      app: insecure-regression
  template:
    metadata:
      labels:
        app: insecure-regression
    spec:
      hostNetwork: true
      hostPID: true
      containers:
        - name: insecure
          image: nginx:latest
          securityContext:
            privileged: true
            allowPrivilegeEscalation: true
            runAsUser: 0
EOF

failures=0

run_case() {
    local name="$1"
    local expected="$2"
    local target="$3"
    local status="$4"
    local report="$TEST_DIR/$name.json"
    local actual=0

    bash "$VALIDATOR" \
        --json-report "$report" "$target" \
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
            .tool == "trivy"
            and .check == "kubernetes-security"
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

run_case "TRIVY-001" 0 "$TEST_DIR/secure.yaml" PASS
run_case "TRIVY-002" 1 "$TEST_DIR/insecure.yaml" FAIL

echo "Trivy regression failures: $failures"

if (( failures > 0 )); then
    exit 1
fi

echo "[PASS] Trivy regression suite"
