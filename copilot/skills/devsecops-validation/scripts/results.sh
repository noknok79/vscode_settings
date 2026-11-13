#!/usr/bin/env bash

# Structured DevSecOps validation result collection.
# Intended to be sourced by validate.sh.

devsecops_results_init() {
    local directory="$1"

    if [[ ! -d "$directory" ]]; then
        return 2
    fi

    DEVSECOPS_RESULTS_FILE="$directory/checks.jsonl"

    : > "$DEVSECOPS_RESULTS_FILE"

    chmod 600 "$DEVSECOPS_RESULTS_FILE"

    export DEVSECOPS_RESULTS_FILE
}

devsecops_record() {
    local tool="$1"
    local check="$2"
    local status="$3"
    local exit_code="$4"
    local findings="${5:-}"

    if [[ -z "${DEVSECOPS_RESULTS_FILE:-}" ]]; then
        echo "ERROR: Result collector not initialized" >&2
        return 2
    fi

    case "$status" in
        PASS|FAIL|ERROR|SKIPPED|UNAVAILABLE)
            ;;
        *)
            echo "ERROR: Invalid result status" >&2
            return 2
            ;;
    esac

    if [[ ! "$exit_code" =~ ^[0-9]+$ ]]; then
        echo "ERROR: Invalid exit code" >&2
        return 2
    fi

    if [[ -n "$findings" ]] &&
       [[ ! "$findings" =~ ^[0-9]+$ ]]; then
        echo "ERROR: Invalid findings count" >&2
        return 2
    fi

    if [[ -n "$findings" ]]; then

        jq -cn \
            --arg tool "$tool" \
            --arg check "$check" \
            --arg status "$status" \
            --argjson exitCode "$exit_code" \
            --argjson findings "$findings" \
            '{
                tool: $tool,
                check: $check,
                status: $status,
                exitCode: $exitCode,
                findings: $findings
            }' >> "$DEVSECOPS_RESULTS_FILE"

    else

        jq -cn \
            --arg tool "$tool" \
            --arg check "$check" \
            --arg status "$status" \
            --argjson exitCode "$exit_code" \
            '{
                tool: $tool,
                check: $check,
                status: $status,
                exitCode: $exitCode
            }' >> "$DEVSECOPS_RESULTS_FILE"

    fi
}

devsecops_results_finalize() {
    local output="$1"

    if [[ -z "${DEVSECOPS_RESULTS_FILE:-}" ]]; then
        return 2
    fi

    jq -s '.' "$DEVSECOPS_RESULTS_FILE" > "$output"

    chmod 600 "$output"
}
