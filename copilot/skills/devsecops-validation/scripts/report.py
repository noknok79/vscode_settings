#!/usr/bin/env python3

"""Generate structured DevSecOps validation reports."""

import argparse
import json
import os
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

VALID_STATUSES = {
    "PASS",
    "FAIL",
    "ERROR",
    "SKIPPED",
    "UNAVAILABLE",
}


def validate_record(record):
    if not isinstance(record, dict):
        raise ValueError("Each check must be an object")

    required = {"tool", "check", "status", "exitCode"}

    missing = required - set(record)

    if missing:
        raise ValueError(
            f"Missing required fields: {sorted(missing)}"
        )

    if record["status"] not in VALID_STATUSES:
        raise ValueError("Invalid check status")

    if not isinstance(record["tool"], str):
        raise ValueError("Invalid tool name")

    if not isinstance(record["check"], str):
        raise ValueError("Invalid check name")

    if type(record["exitCode"]) is not int:
        raise ValueError("Invalid exit code")

    status = record["status"]
    exit_code = record["exitCode"]

    if exit_code < 0:
        raise ValueError("Exit code cannot be negative")

    if status == "PASS" and exit_code != 0:
        raise ValueError("PASS requires exit code 0")

    if status in {"FAIL", "ERROR"} and exit_code == 0:
        raise ValueError(
            f"{status} requires a nonzero exit code"
        )

    if status == "SKIPPED" and exit_code != 3:
        raise ValueError("SKIPPED requires exit code 3")

    if status == "UNAVAILABLE" and exit_code != 2:
        raise ValueError("UNAVAILABLE requires exit code 2")

    allowed = {
        "tool",
        "check",
        "status",
        "exitCode",
        "findings",
    }

    unexpected = set(record) - allowed

    if unexpected:
        raise ValueError(
            f"Unexpected fields: {sorted(unexpected)}"
        )

    if "findings" in record:
        value = record["findings"]

        if type(value) is not int or value < 0:
            raise ValueError("Invalid findings count")

    return {
        key: record[key]
        for key in allowed
        if key in record
    }


def calculate_status(checks):
    statuses = [item["status"] for item in checks]

    if any(
        status in {"ERROR", "UNAVAILABLE"}
        for status in statuses
    ):
        return "ERROR", 2

    if "FAIL" in statuses:
        return "FAIL", 1

    if not statuses or all(
        status == "SKIPPED"
        for status in statuses
    ):
        return "SKIPPED", 3

    return "PASS", 0


def create_report(scope, checks):
    validated = [
        validate_record(item)
        for item in checks
    ]

    status, exit_code = calculate_status(validated)

    summary = {
        "passed": sum(
            item["status"] == "PASS"
            for item in validated
        ),
        "failed": sum(
            item["status"] == "FAIL"
            for item in validated
        ),
        "skipped": sum(
            item["status"] == "SKIPPED"
            for item in validated
        ),
        "errors": sum(
            item["status"] in {"ERROR", "UNAVAILABLE"}
            for item in validated
        ),
    }

    return {
        "schemaVersion": "1.0",
        "tool": "devsecops-validation",
        "timestamp": datetime.now(
            timezone.utc
        ).isoformat(),
        "scope": scope,
        "status": status,
        "exitCode": exit_code,
        "summary": summary,
        "checks": validated,
    }


def write_report(path, report):
    path = Path(path).resolve()

    if not path.parent.is_dir():
        raise ValueError("Report directory does not exist")

    descriptor, temporary = tempfile.mkstemp(
        prefix=".devsecops-report-",
        suffix=".json",
        dir=path.parent,
    )

    try:
        os.fchmod(descriptor, 0o600)

        with os.fdopen(
            descriptor,
            "w",
            encoding="utf-8",
        ) as output:
            json.dump(
                report,
                output,
                indent=2,
                sort_keys=True,
            )
            output.write("\n")

        os.replace(temporary, path)

    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--scope",
        required=True,
    )

    parser.add_argument(
        "--input",
        required=True,
    )

    parser.add_argument(
        "--output",
        required=True,
    )

    args = parser.parse_args()

    try:
        with open(
            args.input,
            encoding="utf-8",
        ) as source:
            checks = json.load(source)

        if not isinstance(checks, list):
            raise ValueError(
                "Input must be an array of checks"
            )

        report = create_report(
            args.scope,
            checks,
        )

        write_report(
            args.output,
            report,
        )

    except (
        OSError,
        ValueError,
        TypeError,
        json.JSONDecodeError,
    ) as error:
        print(
            f"ERROR: Report generation failed: {error}",
            file=sys.stderr,
        )
        return 2

    print(
        f"Report status: {report['status']}"
    )

    print(
        f"Report exit code: {report['exitCode']}"
    )

    print(
        f"Report written: {args.output}"
    )

    return 0


if __name__ == "__main__":
    sys.exit(main())
