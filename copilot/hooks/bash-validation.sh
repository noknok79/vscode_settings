#!/usr/bin/env bash

FILE="${1:-}"

if [[ -z "$FILE" || ! -f "$FILE" ]]; then
    echo "Usage: bash-validation.sh <script.sh>" >&2
    exit 2
fi

echo "Validating: $FILE"

bash -n "$FILE" || exit 1
shellcheck "$FILE" || exit 1

echo "PASS: Bash syntax and ShellCheck validation"
