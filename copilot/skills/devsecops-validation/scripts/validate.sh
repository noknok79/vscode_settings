#!/usr/bin/env bash

set -uo pipefail

usage() {
    cat <<'EOF'
Usage:
  validate.sh <file-or-directory>

Supported checks:
  Terraform: terraform fmt -check, TFLint
  Bash:      bash -n, ShellCheck

This version performs local, non-destructive checks.
EOF
}

DEVSECOPS_SCANNER_DIR=""

# shellcheck disable=SC2329
# Invoked indirectly through the EXIT trap.
devsecops_cleanup() {
    if [[ -n "${DEVSECOPS_SCANNER_DIR:-}" ]]; then
        rm -rf -- "$DEVSECOPS_SCANNER_DIR"
    fi

    if [[ -n "${DEVSECOPS_REPORT_DIR:-}" ]]; then
        rm -rf -- "$DEVSECOPS_REPORT_DIR"
    fi
}

devsecops_scanner_init() {
    if [[ -n "${DEVSECOPS_SCANNER_DIR:-}" ]]; then
        return 0
    fi

    DEVSECOPS_SCANNER_DIR=$(mktemp -d /tmp/devsecops-scanners.XXXXXX) || return 2

    chmod 700 "$DEVSECOPS_SCANNER_DIR"
}

record_mode_result() {
    local tool="$1"
    local check="$2"
    local status="$3"
    local exit_code="$4"
    local findings="${5:-}"

    if [[ -z "${DEVSECOPS_JSON_REPORT:-}" ]]; then
        return 0
    fi

    if [[ -n "$findings" ]]; then
        devsecops_record "$tool" "$check" "$status" "$exit_code" "$findings"
    else
        devsecops_record "$tool" "$check" "$status" "$exit_code"
    fi
}

validate_secrets_mode() (
    set -uo pipefail

    if [[ $# -ne 1 ]]; then
        echo "Usage: validate.sh --secrets <directory>"
        exit 2
    fi

    local target="$1"
    local report_dir
    local report
    local scan_exit
    local findings

    if [[ ! -d "$target" || -L "$target" ]]; then
        echo "ERROR: Expected a real directory"
        record_mode_result "gitleaks" "secret-scan" "ERROR" 2
        exit 2
    fi

    if ! command -v gitleaks >/dev/null 2>&1; then
        echo "UNAVAILABLE: gitleaks"
        record_mode_result "gitleaks" "secret-scan" "UNAVAILABLE" 2
        exit 2
    fi

    if ! command -v jq >/dev/null 2>&1; then
        echo "UNAVAILABLE: jq"
        record_mode_result "gitleaks" "secret-scan" "UNAVAILABLE" 2
        exit 2
    fi

    target=$(realpath -- "$target") || {
        record_mode_result "gitleaks" "secret-scan" "ERROR" 2
        exit 2
    }

    report_dir=$(mktemp -d /tmp/devsecops-gitleaks.XXXXXX) || {
        record_mode_result "gitleaks" "secret-scan" "ERROR" 2
        exit 2
    }
    chmod 700 "$report_dir"

    trap 'rm -rf -- "$report_dir"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM

    report="$report_dir/findings.json"

    echo "======================================"
    echo " GITLEAKS SECRET VALIDATION"
    echo "======================================"

    echo "Scope: $target"

    gitleaks dir "$target" \
        --report-format json \
        --report-path "$report" \
        --redact=100 \
        --exit-code 1 \
        --no-banner \
        --no-color

    scan_exit=$?

    if [[ ! -s "$report" ]]; then
        echo "ERROR: Gitleaks report missing"
        record_mode_result "gitleaks" "secret-scan" "ERROR" 2
        exit 2
    fi

    if ! jq -e 'type == "array"' "$report" >/dev/null 2>&1; then
        echo "ERROR: Invalid Gitleaks JSON report"
        record_mode_result "gitleaks" "secret-scan" "ERROR" 2
        exit 2
    fi

    findings=$(jq 'length' "$report") || {
        record_mode_result "gitleaks" "secret-scan" "ERROR" 2
        exit 2
    }

    echo "Detected findings: $findings"

    if [[ "$scan_exit" -eq 0 && "$findings" -eq 0 ]]; then
        echo "PASS: No secrets detected"
        record_mode_result "gitleaks" "secret-scan" "PASS" 0 0
        exit 0
    elif [[ "$scan_exit" -eq 1 && "$findings" -gt 0 ]]; then
        echo "FAIL: Potential secrets detected"
        echo "Secret values are intentionally not displayed"
        record_mode_result "gitleaks" "secret-scan" "FAIL" 1 "$findings"
        exit 1
    else
        echo "ERROR: Gitleaks execution/report mismatch"
        echo "Scanner exit code: $scan_exit"
        record_mode_result "gitleaks" "secret-scan" "ERROR" 2
        exit 2
    fi
)

validate_helm_mode() (
    set -uo pipefail

    if [[ $# -ne 1 ]]; then
        echo "Usage: validate.sh --helm <chart-directory>"
        exit 2
    fi

    local chart="$1"
    local report_dir
    local rendered
    local lint_exit
    local template_exit
    local resources

    if [[ ! -d "$chart" || -L "$chart" ]]; then
        echo "ERROR: Invalid chart directory"
        record_mode_result "helm" "chart-validation" "ERROR" 2
        exit 2
    fi

    chart=$(realpath -- "$chart") || {
        record_mode_result "helm" "chart-validation" "ERROR" 2
        exit 2
    }

    if [[ ! -f "$chart/Chart.yaml" ]]; then
        echo "ERROR: Chart.yaml missing"
        record_mode_result "helm" "chart-validation" "ERROR" 2
        exit 2
    fi

    if ! command -v helm >/dev/null 2>&1; then
        echo "UNAVAILABLE: helm"
        record_mode_result "helm" "chart-validation" "UNAVAILABLE" 2
        exit 2
    fi

    report_dir=$(mktemp -d /tmp/devsecops-helm.XXXXXX) || {
        record_mode_result "helm" "chart-validation" "ERROR" 2
        exit 2
    }
    chmod 700 "$report_dir"

    trap 'rm -rf -- "$report_dir"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM

    rendered="$report_dir/rendered.yaml"

    echo "======================================"
    echo " HELM CHART VALIDATION"
    echo "======================================"

    echo "Chart: $chart"

    echo
    echo "=== HELM LINT ==="

    if helm lint "$chart"; then
        lint_exit=0
    else
        lint_exit=$?
    fi

    echo
    echo "=== HELM TEMPLATE ==="

    if helm template devsecops-validation "$chart" \
        > "$rendered"; then
        template_exit=0
    else
        template_exit=$?
    fi

    if [[ "$template_exit" -eq 0 ]]; then
        if [[ ! -s "$rendered" ]]; then
            echo "FAIL: No rendered manifests"
            template_exit=1
        else
            resources=$(grep -c '^kind:' "$rendered" || true)
            echo "Rendered resources: $resources"

            if [[ "$resources" -lt 1 ]]; then
                echo "FAIL: No Kubernetes resources rendered"
                template_exit=1
            fi
        fi
    fi

    echo
    echo "=== HELM VALIDATION SUMMARY ==="

    echo "Lint exit code: $lint_exit"
    echo "Template exit code: $template_exit"

    if [[ "$lint_exit" -eq 0 && "$template_exit" -eq 0 ]]; then
        echo "PASS: Helm chart validation"
        record_mode_result "helm" "chart-validation" "PASS" 0
        exit 0
    elif [[ "$lint_exit" -eq 126 || "$lint_exit" -eq 127 ||
            "$template_exit" -eq 126 || "$template_exit" -eq 127 ]]; then
        echo "ERROR: Helm command execution failed"
        record_mode_result "helm" "chart-validation" "ERROR" 2
        exit 2
    else
        echo "FAIL: Helm chart validation"
        record_mode_result "helm" "chart-validation" "FAIL" 1
        exit 1
    fi
)

DEVSECOPS_JSON_REPORT=""

if [[ "${1:-}" == "--json-report" ]]; then

    if [[ $# -ne 3 && $# -ne 4 ]]; then
        echo "Usage:"
        echo "  validate.sh --json-report <output.json> <target>"
        echo "  validate.sh --json-report <output.json> --secrets <directory>"
        echo "  validate.sh --json-report <output.json> --helm <chart>"
        exit 2
    fi

    if [[ $# -eq 4 ]]; then
        case "$3" in
            --secrets|--helm)
                ;;
            *)
                echo "ERROR: Unsupported JSON validation mode"
                exit 2
                ;;
        esac
    fi

    DEVSECOPS_JSON_REPORT="$2"
    shift 2

    if [[ -e "$DEVSECOPS_JSON_REPORT" ]]; then
        echo "ERROR: Report destination already exists"
        exit 2
    fi

    REPORT_PARENT=$(dirname -- "$DEVSECOPS_JSON_REPORT")

    if [[ ! -d "$REPORT_PARENT" ]]; then
        echo "ERROR: Report directory does not exist"
        exit 2
    fi

    DEVSECOPS_REPORT_DIR=$(mktemp -d /tmp/devsecops-json.XXXXXX) || exit 2

    chmod 700 "$DEVSECOPS_REPORT_DIR"

    trap 'devsecops_cleanup' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM

    # shellcheck source=results.sh
    source "$(dirname -- "${BASH_SOURCE[0]}")/results.sh"

    devsecops_results_init "$DEVSECOPS_REPORT_DIR"

    echo "INFO: Structured reporting initialized"

fi

finalize_specialized_report() {
    local scope="$1"
    local expected_exit="$2"

    if [[ -z "${DEVSECOPS_JSON_REPORT:-}" ]]; then
        return 0
    fi

    local checks_json="$DEVSECOPS_REPORT_DIR/checks.json"
    local internal_report="$DEVSECOPS_REPORT_DIR/report.json"

    if ! devsecops_results_finalize "$checks_json"; then
        echo "ERROR: Specialized result finalization failed"
        return 2
    fi

    if ! python3 "$(dirname -- "${BASH_SOURCE[0]}")/report.py" \
        --scope "$scope" \
        --input "$checks_json" \
        --output "$internal_report"; then

        echo "ERROR: Specialized JSON generation failed"
        return 2
    fi

    if ! jq -e \
        --argjson code "$expected_exit" \
        '.exitCode == $code and (.checks | length > 0)' \
        "$internal_report" >/dev/null; then

        echo "ERROR: Specialized JSON result mismatch"
        return 2
    fi

    if ! python3 "$(dirname -- "${BASH_SOURCE[0]}")/publish.py" \
        "$internal_report" "$DEVSECOPS_JSON_REPORT"; then
        echo "ERROR: Specialized report publishing failed"
        return 2
    fi

    echo "PASS: Specialized JSON report generated"
}

if [[ "${1:-}" == "--helm" ]]; then
    shift

    if validate_helm_mode "$@"; then
        MODE_EXIT=0
    else
        MODE_EXIT=$?
    fi

    if ! finalize_specialized_report "${1:-}" "$MODE_EXIT"; then
        exit 2
    fi

    exit "$MODE_EXIT"
fi

if [[ "${1:-}" == "--secrets" ]]; then
    shift

    if validate_secrets_mode "$@"; then
        MODE_EXIT=0
    else
        MODE_EXIT=$?
    fi

    if ! finalize_specialized_report "${1:-}" "$MODE_EXIT"; then
        exit 2
    fi

    exit "$MODE_EXIT"
fi

if [[ $# -ne 1 ]]; then
    usage
    exit 2
fi

TARGET="$1"

trap 'devsecops_cleanup' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if [[ ! -e "$TARGET" ]]; then
    echo "ERROR: Target does not exist"
    exit 2
fi

if [[ -L "$TARGET" ]]; then
    echo "ERROR: Symlink targets are not supported"
    exit 2
fi

TARGET=$(realpath -- "$TARGET")

PASS=0
FAIL=0
SKIP=0
ERRORS=0

record_validation_result() {
    local tool="$1"
    local check="$2"
    local status="$3"
    local exit_code="$4"

    if [[ -z "${DEVSECOPS_JSON_REPORT:-}" ]]; then
        return 0
    fi

    devsecops_record \
        "$tool" \
        "$check" \
        "$status" \
        "$exit_code"
}

run_check() {
    local name="$1"
    shift

    echo
    echo "=== CHECK: $name ==="

    local result
    local tool
    local check
    local status

    tool="${1##*/}"
    check="$name"

    "$@"
    result=$?

    if [[ "$result" -eq 0 ]]; then
        status="PASS"
        echo "PASS: $name"
        ((PASS+=1))

    elif [[ "$result" -eq 126 || "$result" -eq 127 ]]; then
        status="ERROR"
        echo "ERROR: $name (exit=$result)"
        ((ERRORS+=1))

    else
        status="FAIL"
        echo "FAIL: $name (exit=$result)"
        ((FAIL+=1))
    fi

    record_validation_result \
        "$tool" \
        "$check" \
        "$status" \
        "$result"
}

check_tool() {
    command -v "$1" >/dev/null 2>&1
}

record_security_result() {
    local tool="$1"
    local check="$2"
    local status="$3"
    local exit_code="$4"
    local findings="${5:-}"

    if [[ -z "${DEVSECOPS_JSON_REPORT:-}" ]]; then
        return 0
    fi

    if [[ -n "$findings" ]]; then
        devsecops_record "$tool" "$check" "$status" "$exit_code" "$findings"
    else
        devsecops_record "$tool" "$check" "$status" "$exit_code"
    fi
}

validate_terraform() {
    local directory="$1"

    if check_tool terraform; then
        run_check \
            "Terraform formatting" \
            terraform -chdir="$directory" fmt -check -diff
    else
        echo "UNAVAILABLE: terraform"
        ((ERRORS+=1))
        record_validation_result "terraform" "format" "UNAVAILABLE" 2
    fi

    if check_tool tflint; then
        run_check \
            "TFLint" \
            tflint --chdir="$directory" --format compact
    else
        echo "UNAVAILABLE: tflint"
        ((ERRORS+=1))
        record_validation_result "tflint" "lint" "UNAVAILABLE" 2
    fi

    echo "SKIPPED: terraform validate"
    echo "Reason: Provider initialization not performed"
    ((SKIP+=1))
    record_validation_result "terraform" "validate" "SKIPPED" 3

    if check_tool checkov; then
        echo
        echo "=== CHECK: Checkov Terraform Security ==="

        local checkov_result
        local checkov_report
        local checkov_error
        local findings

        devsecops_scanner_init || {
            echo "ERROR: Scanner workspace initialization failed"
            ((ERRORS+=1))
            record_security_result "checkov" "terraform-security" "ERROR" 2
            return 0
        }

        checkov_report="$DEVSECOPS_SCANNER_DIR/checkov-report.json"
        checkov_error="$DEVSECOPS_SCANNER_DIR/checkov-error.log"

        checkov \
            -d "$directory" \
            --framework terraform \
            --download-external-modules false \
            --quiet \
            --compact \
            --output json \
            > "$checkov_report" 2> "$checkov_error"

        checkov_result=$?

        if ! jq -e 'type == "object"' "$checkov_report" >/dev/null 2>&1; then
            echo "ERROR: Checkov JSON report invalid"
            ((ERRORS+=1))
            record_security_result "checkov" "terraform-security" "ERROR" 2
        else
            findings=$(jq -r '
                .summary.failed // 0
            ' "$checkov_report")

            echo "Checkov failed checks: $findings"

            if [[ "$checkov_result" -eq 0 && "$findings" -eq 0 ]]; then
                echo "PASS: Checkov Terraform Security"
                ((PASS+=1))
                record_security_result "checkov" "terraform-security" "PASS" 0 0
            elif [[ "$checkov_result" -eq 1 && "$findings" -gt 0 ]]; then
                echo "FAIL: Checkov detected security findings"
                ((FAIL+=1))
                record_security_result "checkov" "terraform-security" "FAIL" "$checkov_result" "$findings"
            else
                echo "ERROR: Checkov execution or report mismatch"
                ((ERRORS+=1))
                record_security_result "checkov" "terraform-security" "ERROR" 2
            fi
        fi

        if [[ -s "$checkov_error" ]]; then
            echo "INFO: Checkov emitted diagnostics"
            echo "Review locally if troubleshooting is required"
        fi

        rm -f "$checkov_report" "$checkov_error"
    else
        echo "UNAVAILABLE: checkov"
        ((ERRORS+=1))
        record_security_result "checkov" "terraform-security" "UNAVAILABLE" 2
    fi
}

is_kubernetes_yaml() {
    local file="$1"

    if ! check_tool jq; then
        return 1
    fi

    if ! check_tool python3; then
        return 1
    fi

    python3 - "$file" <<'PYCLASS'
import sys
from pathlib import Path

path = Path(sys.argv[1])

try:
    import yaml
except ImportError:
    raise SystemExit(2)

try:
    documents = list(yaml.safe_load_all(path.read_text()))
except (OSError, UnicodeError, yaml.YAMLError):
    raise SystemExit(2)

for document in documents:
    if not isinstance(document, dict):
        continue

    api_version = document.get("apiVersion")
    kind = document.get("kind")

    if isinstance(api_version, str) and isinstance(kind, str):
        raise SystemExit(0)

raise SystemExit(1)
PYCLASS
}

validate_kubernetes_trivy() {
    local target="$1"

    echo
    echo "=== CHECK: Trivy Kubernetes Security ==="

    if ! check_tool trivy; then
        echo "UNAVAILABLE: trivy"
        ((ERRORS+=1))
        record_security_result "trivy" "kubernetes-security" "UNAVAILABLE" 2
        return 0
    fi

    local report_dir
    local report
    local scan_exit
    local findings

    devsecops_scanner_init || {
        echo "ERROR: Scanner workspace initialization failed"
        ((ERRORS+=1))
        record_security_result "trivy" "kubernetes-security" "ERROR" 2
        return 0
    }

    report_dir="$DEVSECOPS_SCANNER_DIR/trivy"

    if ! mkdir -m 700 -- "$report_dir"; then
        echo "ERROR: Cannot create Trivy report directory"
        ((ERRORS+=1))
        record_security_result "trivy" "kubernetes-security" "ERROR" 2
        return 0
    fi

    report="$report_dir/findings.json"

    trivy config \
        --skip-check-update \
        --severity HIGH,CRITICAL \
        --exit-code 1 \
        --format json \
        --output "$report" \
        "$target"

    scan_exit=$?

    if [[ ! -s "$report" ]] ||
       ! jq -e '.Results | type == "array"' \
           "$report" >/dev/null 2>&1; then

        echo "ERROR: Trivy report missing or invalid"
        ((ERRORS+=1))
        record_security_result "trivy" "kubernetes-security" "ERROR" 2

    else

        findings=$(jq '
          [
            .Results[]?.Misconfigurations[]?
            | select(
                .Severity == "HIGH"
                or .Severity == "CRITICAL"
              )
          ] | length
        ' "$report")

        echo "HIGH/CRITICAL findings: $findings"

        if [[ "$scan_exit" -eq 0 && "$findings" -eq 0 ]]; then

            echo "PASS: Trivy Kubernetes Security"
            ((PASS+=1))
            record_security_result "trivy" "kubernetes-security" "PASS" 0 0

        elif [[ "$scan_exit" -eq 1 && "$findings" -gt 0 ]]; then

            echo "FAIL: Trivy detected security findings"
            ((FAIL+=1))
            record_security_result "trivy" "kubernetes-security" "FAIL" "$scan_exit" "$findings"

        else

            echo "ERROR: Trivy execution/report mismatch"
            ((ERRORS+=1))
            record_security_result "trivy" "kubernetes-security" "ERROR" 2

        fi
    fi

    rm -f -- "$report"
    rmdir -- "$report_dir"
}

validate_bash() {
    local file="$1"

    if check_tool bash; then
        run_check \
            "Bash syntax: $file" \
            bash -n "$file"
    else
        echo "UNAVAILABLE: bash"
        ((ERRORS+=1))
        record_validation_result "bash" "syntax" "UNAVAILABLE" 2
    fi

    if check_tool shellcheck; then
        run_check \
            "ShellCheck: $file" \
            shellcheck "$file"
    else
        echo "UNAVAILABLE: shellcheck"
        ((ERRORS+=1))
        record_validation_result "shellcheck" "bash-lint" "UNAVAILABLE" 2
    fi
}

echo "======================================"
echo " DEVSECOPS VALIDATION"
echo "======================================"

echo "Target: $TARGET"

if [[ -f "$TARGET" ]]; then

    case "$TARGET" in
        *.tf)
            validate_terraform "$(dirname "$TARGET")"
            ;;
        *.sh)
            validate_bash "$TARGET"
            ;;
        *.yaml|*.yml)
            if is_kubernetes_yaml "$TARGET"; then
                yaml_result=0
            else
                yaml_result=$?
            fi

            case "$yaml_result" in
                0)
                    validate_kubernetes_trivy "$TARGET"
                    ;;
                1)
                    echo "SKIPPED: Non-Kubernetes YAML"
                    ((SKIP+=1))
                    record_validation_result "yaml" "classification" "SKIPPED" 3
                    ;;
                *)
                    echo "ERROR: YAML parsing or classification failed"
                    ((ERRORS+=1))
                    record_validation_result "yaml" "classification" "ERROR" 2
                    ;;
            esac
            ;;
        *)
            echo "SKIPPED: Unsupported file type"
            ((SKIP+=1))
            record_validation_result "validator" "unsupported-file" "SKIPPED" 3
            ;;
    esac

elif [[ -d "$TARGET" ]]; then

    if find "$TARGET" -maxdepth 1 \
        -type f -name '*.tf' -print -quit \
        | grep -q .; then

        validate_terraform "$TARGET"
    fi

    while IFS= read -r -d '' file; do
        if is_kubernetes_yaml "$file"; then
            yaml_result=0
        else
            yaml_result=$?
        fi

        case "$yaml_result" in
            0)
                validate_kubernetes_trivy "$file"
                ;;
            1)
                echo "SKIPPED: Non-Kubernetes YAML: $file"
                ((SKIP+=1))
                record_validation_result "yaml" "classification" "SKIPPED" 3
                ;;
            *)
                echo "ERROR: YAML parsing or classification failed: $file"
                ((ERRORS+=1))
                record_validation_result "yaml" "classification" "ERROR" 2
                ;;
        esac
    done < <(
        find "$TARGET"             -maxdepth 1             -type f             \( -name '*.yaml' -o -name '*.yml' \)             -print0
    )

    while IFS= read -r -d '' file; do
        validate_bash "$file"
    done < <(
        find "$TARGET" \
            -maxdepth 1 \
            -type f \
            -name '*.sh' \
            -print0
    )

else
    echo "ERROR: Unsupported target type"
    exit 2
fi

echo
echo "======================================"
echo " VALIDATION SUMMARY"
echo "======================================"

echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo "SKIPPED: $SKIP"
echo "ERROR: $ERRORS"

if [[ "$ERRORS" -gt 0 ]]; then
    FINAL_EXIT=2
elif [[ "$FAIL" -gt 0 ]]; then
    FINAL_EXIT=1
elif [[ "$PASS" -eq 0 ]]; then
    echo "SKIPPED: No applicable validation checks executed"
    FINAL_EXIT=3
else
    FINAL_EXIT=0
fi

if [[ -n "${DEVSECOPS_JSON_REPORT:-}" ]]; then

    CHECKS_JSON="$DEVSECOPS_REPORT_DIR/checks.json"
    INTERNAL_REPORT="$DEVSECOPS_REPORT_DIR/report.json"

    if ! devsecops_results_finalize "$CHECKS_JSON"; then
        echo "ERROR: Result finalization failed"
        exit 2
    fi

    if ! python3 "$(dirname -- "${BASH_SOURCE[0]}")/report.py" \
        --scope "$TARGET" \
        --input "$CHECKS_JSON" \
        --output "$INTERNAL_REPORT"; then

        echo "ERROR: JSON generation failed"
        exit 2
    fi

    if ! jq -e \
        --argjson passed "$PASS" \
        --argjson failed "$FAIL" \
        --argjson skipped "$SKIP" \
        --argjson errors "$ERRORS" \
        --argjson code "$FINAL_EXIT" \
        '
          .summary.passed == $passed
          and .summary.failed == $failed
          and .summary.skipped == $skipped
          and .summary.errors == $errors
          and .exitCode == $code
        ' "$INTERNAL_REPORT" >/dev/null; then

        echo "ERROR: JSON report does not match validation results"
        exit 2
    fi

    if [[ -e "$DEVSECOPS_JSON_REPORT" ]]; then
        echo "ERROR: Report destination already exists"
        exit 2
    fi

    if ! python3 "$(dirname -- "${BASH_SOURCE[0]}")/publish.py" \
        "$INTERNAL_REPORT" "$DEVSECOPS_JSON_REPORT"; then
        echo "ERROR: Cannot publish JSON report"
        exit 2
    fi

    echo "PASS: JSON report generated"
fi

exit "$FINAL_EXIT"
