#!/usr/bin/env python3

import argparse
import hashlib
import json
import os
import tempfile
import stat
import re
import subprocess
import sys
from pathlib import Path


def parse_counts(lines, labels):
    results = {}

    for label in labels:
        matches = [
            int(match.group(1))
            for line in lines
            if (match := re.fullmatch(
                rf"{re.escape(label)}:\s*(\d+)",
                line.strip(),
            ))
        ]

        if len(matches) > 1:
            raise ValueError(f"Duplicate summary: {label}")

        results[label] = matches[0] if matches else None

    return results


def section(lines, start, end):
    try:
        begin = lines.index(start) + 1
    except ValueError:
        return []

    try:
        finish = lines.index(end, begin)
    except ValueError:
        finish = len(lines)

    return lines[begin:finish]



def collect(text, mode, exit_code):
    if mode not in ("maintenance", "regression", "full"):
        raise ValueError("Invalid execution mode")

    if type(exit_code) is not int or exit_code < 0 or exit_code > 255:
        raise ValueError("Invalid exit code")

    lines = text.splitlines()

    headers = (
        "=== 1. CONFIGURATION HEALTH ===",
        "=== 2. CONFIGURATION DRIFT ===",
        "=== 3. GIT STATUS ===",
        "=== 6. DEVSECOPS REGRESSION ===",
        " REGRESSION SUMMARY",
    )

    for header in headers:
        if lines.count(header) > 1:
            raise ValueError(f"Duplicate section: {header}")

    health_lines = section(
        lines,
        headers[0],
        headers[1],
    )

    drift_lines = section(
        lines,
        headers[1],
        headers[2],
    )

    regression_lines = section(
        lines,
        headers[4],
        "[PASS] Regression execution complete",
    )

    health = parse_counts(
        health_lines,
        ("PASS", "WARN", "FAIL"),
    )

    drift = parse_counts(
        drift_lines,
        ("PASS", "WARN", "FAIL"),
    )

    regression = parse_counts(
        regression_lines,
        ("Passed", "Failed", "Skipped"),
    )

    if exit_code == 0:
        if mode in ("maintenance", "full"):
            for name, values in (
                ("health", health),
                ("drift", drift),
            ):
                if any(value is None for value in values.values()):
                    raise ValueError(f"Incomplete successful {name} summary")

                if values["FAIL"] != 0:
                    raise ValueError(f"Contradictory successful {name} summary")

        if mode in ("regression", "full"):
            if any(value is None for value in regression.values()):
                raise ValueError("Incomplete successful regression summary")

            if regression["Failed"] != 0 or regression["Skipped"] != 0:
                raise ValueError("Contradictory successful regression summary")

            if regression["Passed"] == 0:
                raise ValueError("No successful regression suites")

            if lines.count("[PASS] Regression execution complete") != 1:
                raise ValueError("Regression completion marker missing")

    return {
        "mode": mode,
        "health": {
            "passed": health["PASS"],
            "warnings": health["WARN"],
            "failed": health["FAIL"],
        },
        "drift": {
            "passed": drift["PASS"],
            "warnings": drift["WARN"],
            "failed": drift["FAIL"],
        },
        "regression": {
            "passedSuites": regression["Passed"],
            "failedSuites": regression["Failed"],
            "skippedSuites": regression["Skipped"],
        },
        "exitCode": exit_code,
    }


def secure_write(path, content):
    if path.is_symlink():
        raise ValueError("Symlinked output rejected")

    parent = path.parent

    if parent.is_symlink():
        raise ValueError("Symlinked output parent rejected")

    if not parent.is_dir():
        raise ValueError("Output parent missing")

    mode = parent.stat().st_mode

    if stat.S_IMODE(mode) & 0o077:
        raise ValueError("Output parent permissions are not private")

    fd, temporary = tempfile.mkstemp(
        prefix=".collector-",
        dir=path.parent,
    )

    try:
        os.fchmod(fd, 0o600)

        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())

        os.replace(temporary, path)

    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument("--log", type=Path, required=True)
    parser.add_argument("--mode", choices=("maintenance", "regression", "full"), required=True)
    parser.add_argument("--exit-code", type=int, required=True)
    parser.add_argument("--repo", type=Path, required=True)
    parser.add_argument("--validator", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)

    args = parser.parse_args()

    if args.exit_code < 0:
        parser.error("Invalid exit code")

    text = args.log.read_text(encoding="utf-8")

    data = collect(text, args.mode, args.exit_code)

    result = subprocess.run(
        ["git", "-C", str(args.repo), "rev-parse", "HEAD"],
        capture_output=True,
        text=True,
        check=True,
    )

    data["gitCommit"] = result.stdout.strip()

    data["validatorSha256"] = hashlib.sha256(
        args.validator.read_bytes()
    ).hexdigest()

    secure_write(
        args.output,
        json.dumps(data, indent=2) + "\n",
    )

    print("[PASS] Maintenance results collected")


if __name__ == "__main__":
    sys.exit(main())
