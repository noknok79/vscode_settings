#!/usr/bin/env bash
set -euo pipefail

VALIDATOR="${COPILOT_HOME:-$HOME/.copilot}/skills/devsecops-validation/scripts/validate.sh"

test -f "$VALIDATOR"

python3 -B - "$VALIDATOR" <<'PYTHON_EOF'
from pathlib import Path
import re
import subprocess
import sys

source = Path(sys.argv[1]).read_text()

functions = [
    "devsecops_record_result",
    "record_mode_result",
    "record_validation_result",
    "record_security_result",
]

def extract(name):
    pattern = rf"(?m)^{re.escape(name)}\(\) \{{\n"
    match = re.search(pattern, source)

    if not match:
        raise RuntimeError(f"Missing function: {name}")

    end = source.find("\n}", match.end())

    if end < 0:
        raise RuntimeError(f"Unterminated function: {name}")

    return source[match.start():end + 2]

definitions = "\n\n".join(extract(name) for name in functions)

cases = [
    ("record_mode_result", ["gitleaks", "secret-scan", "PASS", "0", "0"]),
    ("record_mode_result", ["gitleaks", "secret-scan", "FAIL", "1", "2"]),
    ("record_mode_result", ["helm", "chart-validation", "PASS", "0"]),
    ("record_validation_result", ["bash", "syntax", "PASS", "0"]),
    ("record_validation_result", ["yaml", "classification", "SKIPPED", "3"]),
    ("record_security_result", ["checkov", "terraform-security", "FAIL", "1", "3"]),
    ("record_security_result", ["trivy", "kubernetes-security", "PASS", "0", "0"]),
    ("record_security_result", ["trivy", "kubernetes-security", "ERROR", "2"]),
]

def run_case(function, args, enabled):
    script = """
set -uo pipefail

devsecops_record() {
    printf '%s\\n' "$#"
    printf '%s\\n' "$@"
}

""" + definitions + """

DEVSECOPS_JSON_REPORT="$1"
shift

function_name="$1"
shift

"$function_name" "$@"
"""

    return subprocess.run(
        ["bash", "-c", script, "regression", enabled, function, *args],
        capture_output=True,
        text=True,
        check=False,
    )

failures = 0
total = 0

for enabled in ("", "enabled"):
    for function, args in cases:
        total += 1

        result = run_case(function, args, enabled)

        if enabled:
            expected_args = args[:4]
            if len(args) > 4 and args[4] != "":
                expected_args.append(args[4])

            expected_stdout = (
                str(len(expected_args)) + "\n"
                + "\n".join(expected_args) + "\n"
            )
        else:
            expected_stdout = ""

        if (
            result.returncode == 0
            and result.stdout == expected_stdout
            and result.stderr == ""
        ):
            print(f"[PASS] {function}: {args[2]} JSON={bool(enabled)}")
        else:
            failures += 1
            print(f"[FAIL] {function}: {args[2]} JSON={bool(enabled)}")
            print("Exit:", result.returncode)
            print("Actual stdout:", repr(result.stdout))
            print("Expected stdout:", repr(expected_stdout))
            print("Stderr:", repr(result.stderr))

print()
print(f"Recording scenarios: {total}")
print(f"Passed: {total - failures}")
print(f"Failed: {failures}")

if failures:
    sys.exit(1)

print("[PASS] Portable recording regression suite")
PYTHON_EOF
