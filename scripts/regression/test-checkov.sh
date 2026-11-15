#!/usr/bin/env bash
set -euo pipefail

VALIDATOR="${COPILOT_HOME:-$HOME/.copilot}/skills/devsecops-validation/scripts/validate.sh"

test -f "$VALIDATOR"

for tool in terraform tflint checkov jq python3; do
    command -v "$tool" >/dev/null
done

unset DEVSECOPS_JSON_REPORT
unset DEVSECOPS_REPORT_DIR
unset DEVSECOPS_SCANNER_DIR
unset DEVSECOPS_RESULTS_FILE

TEST_DIR=$(mktemp -d /tmp/devsecops-checkov-regression.XXXXXX)
trap 'rm -rf -- "$TEST_DIR"' EXIT

mkdir -p "$TEST_DIR/clean" "$TEST_DIR/findings"

cat > "$TEST_DIR/clean/main.tf" <<'EOF'
terraform {
  required_version = ">= 1.0"
}

output "environment" {
  value = "test"
}
EOF

cat > "$TEST_DIR/findings/main.tf" <<'EOF'
terraform {
  required_version = ">= 1.0"
}

resource "azurerm_storage_account" "test" {
  name                     = "devsecopsregression001"
  resource_group_name      = "devsecops-test"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version                 = "TLS1_0"
  allow_nested_items_to_be_public = true
}
EOF

terraform fmt "$TEST_DIR/findings/main.tf" >/dev/null

failures=0

run_case() {
    local name="$1"
    local expected="$2"
    local directory="$3"
    local status="$4"
    local report="$TEST_DIR/$name.json"
    local actual=0

    bash "$VALIDATOR" \
        --json-report "$report" "$directory" \
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
            .tool == "checkov"
            and .check == "terraform-security"
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

run_case "CHECKOV-001" 0 "$TEST_DIR/clean" PASS
run_case "CHECKOV-002" 1 "$TEST_DIR/findings" FAIL

echo "Checkov regression failures: $failures"

if (( failures > 0 )); then
    exit 1
fi

echo "[PASS] Checkov regression suite"
