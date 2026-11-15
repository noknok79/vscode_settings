#!/usr/bin/env python3

import argparse
import json
import os
import tempfile
import stat
import uuid
from datetime import datetime, timezone
from pathlib import Path


def require_count(value, name):
    if type(value) is not int or value < 0:
        raise ValueError(f"Invalid count: {name}")
    return value


def validate(data):
    if not isinstance(data, dict):
        raise ValueError("Report input must be an object")

    required = (
        "mode",
        "gitCommit",
        "validatorSha256",
        "health",
        "drift",
        "regression",
        "exitCode",
    )

    for field in required:
        if field not in data:
            raise ValueError(f"Missing field: {field}")

    if data["mode"] not in ("maintenance", "regression", "full"):
        raise ValueError("Invalid mode")

    if not isinstance(data["gitCommit"], str):
        raise ValueError("Invalid Git commit")

    if not isinstance(data["validatorSha256"], str):
        raise ValueError("Invalid validator checksum")

    require_count(data["exitCode"], "exitCode")

    for section, fields in {
        "health": ("passed", "warnings", "failed"),
        "drift": ("passed", "warnings", "failed"),
        "regression": (
            "passedSuites",
            "failedSuites",
            "skippedSuites",
        ),
    }.items():
        values = data[section]

        if not isinstance(values, dict):
            raise ValueError(f"Invalid section: {section}")

        for field in fields:
            value = values.get(field)

            if value is not None:
                require_count(value, f"{section}.{field}")

    return data


def markdown(data):
    lines = [
        "# Copilot Maintenance Report",
        "",
        f"Timestamp: {data['timestamp']}",
        f"Mode: {data['mode']}",
        f"Git commit: {data['gitCommit']}",
        f"Validator SHA-256: {data['validatorSha256']}",
        f"Exit code: {data['exitCode']}",
        "",
        "## Validation Summary",
        "",
        "| Category | Passed | Warnings | Failed |",
        "|---|---:|---:|---:|",
    ]

    for section in ("health", "drift"):
        values = data[section]

        lines.append(
            f"| {section.title()} | "
            f"{values['passed']} | "
            f"{values['warnings']} | "
            f"{values['failed']} |"
        )

    regression = data["regression"]

    lines.extend([
        "",
        "## Regression Suites",
        "",
        f"- Passed: {regression['passedSuites']}",
        f"- Failed: {regression['failedSuites']}",
        f"- Skipped: {regression['skippedSuites']}",
        "",
    ])

    return "\n".join(lines)



def verify_directory(path):
    if path.is_symlink():
        raise ValueError("Symlinked directory rejected")

    if not path.is_dir():
        raise ValueError("Directory missing or invalid")

    mode = path.stat().st_mode

    if stat.S_IMODE(mode) & 0o077:
        raise ValueError("Directory permissions are not private")


def publish(output, json_content, md_content):
    output.mkdir(parents=True, exist_ok=True, mode=0o700)
    verify_directory(output)

    history = output / "history"
    history.mkdir(mode=0o700, exist_ok=True)
    verify_directory(history)

    run_id = (
        datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        + "-"
        + uuid.uuid4().hex
    )

    staging = Path(
        tempfile.mkdtemp(
            prefix=".staging-",
            dir=history,
        )
    )

    published = history / run_id

    try:
        for name, content in (
            ("report.json", json_content),
            ("report.md", md_content),
        ):
            target = staging / name

            fd = os.open(
                target,
                os.O_WRONLY | os.O_CREAT | os.O_EXCL,
                0o600,
            )

            with os.fdopen(fd, "w", encoding="utf-8") as stream:
                stream.write(content)
                stream.flush()
                os.fsync(stream.fileno())

        os.replace(staging, published)

        pointer = output / "latest"

        if pointer.exists() and not pointer.is_symlink():
            raise ValueError("Unsafe latest pointer")

        temporary_pointer = output / (
            ".latest-" + uuid.uuid4().hex
        )

        try:
            temporary_pointer.symlink_to(
                Path("history") / run_id
            )

            os.replace(temporary_pointer, pointer)

        finally:
            if temporary_pointer.is_symlink():
                temporary_pointer.unlink()

    finally:
        if staging.exists():
            staging.rmdir()

    return published

def main():
    parser = argparse.ArgumentParser()

    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)

    args = parser.parse_args()

    if args.output_dir.is_symlink():
        parser.error("Output directory cannot be a symlink")

    try:
        data = json.loads(args.input.read_text(encoding="utf-8"))
        data = validate(data)
    except (OSError, ValueError, TypeError) as exc:
        parser.error(str(exc))

    data["schemaVersion"] = 1
    data["timestamp"] = datetime.now(timezone.utc).isoformat()

    output = args.output_dir

    if output.exists() and not output.is_dir():
        parser.error("Output destination is not a directory")

    json_content = json.dumps(data, indent=2) + "\n"
    md_content = markdown(data)

    published = publish(output, json_content, md_content)

    print("[PASS] JSON report generated")
    print("[PASS] Markdown report generated")
    print(f"[PASS] Published report: {published}")


if __name__ == "__main__":
    main()
