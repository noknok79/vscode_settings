#!/usr/bin/env python3

import json
import re
import subprocess
import sys

from datetime import datetime, timezone
from pathlib import Path


HOOK_DIR = Path.home() / ".copilot" / "hooks"
LOG_FILE = HOOK_DIR / "bash-validation.log"

PATH_KEYS = {
    "file_path",
    "filepath",
    "path",
    "file",
    "target_file",
    "filename",
}

PATCH_KEYS = {
    "patch",
    "patch_text",
    "patch_content",
    "input",
}


def log(message):
    timestamp = datetime.now(timezone.utc).isoformat()

    with LOG_FILE.open("a", encoding="utf-8") as file:
        file.write(f"{timestamp} | {message}\n")


def collect_paths(value):
    paths = set()

    if isinstance(value, dict):
        for key, item in value.items():
            key = key.lower()

            if key in PATH_KEYS and isinstance(item, str):
                if item.endswith(".sh"):
                    paths.add(item)

            elif key in PATCH_KEYS and isinstance(item, str):
                paths.update(extract_patch_paths(item))

            elif isinstance(item, (dict, list)):
                paths.update(collect_paths(item))

    elif isinstance(value, list):
        for item in value:
            paths.update(collect_paths(item))

    return paths


def extract_patch_paths(patch):
    paths = set()

    patterns = [
        r"^\*\*\* (?:Add|Update|Move to) File:\s*(.+\.sh)$",
        r"^\+\+\+\s+(?:b/)?(.+\.sh)$",
    ]

    for line in patch.splitlines():
        for pattern in patterns:
            match = re.match(pattern, line.strip())

            if match:
                paths.add(match.group(1).strip())

    return paths


def validate_file(path):
    errors = []

    commands = [
        ["bash", "-n", str(path)],
        ["shellcheck", str(path)],
    ]

    for command in commands:
        name = command[0]

        try:
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=20,
                check=False,
            )

        except (OSError, subprocess.TimeoutExpired) as exc:
            message = f"CHECK ERROR | {path} | {name}: {exc}"

            log(message)
            errors.append(message)
            continue

        if result.returncode != 0:
            details = (
                result.stdout + result.stderr
            ).strip()

            message = (
                f"FAILED | {path} | {name}\n"
                f"{details[:3000]}"
            )

            log(message)
            errors.append(message)

    if not errors:
        log(f"PASS | {path}")

    return errors


def main():
    event = json.load(sys.stdin)

    cwd = Path(event.get("cwd") or ".").resolve()
    tool_name = event.get("toolName", "unknown")
    tool_args = event.get("toolArgs", {})

    log(f"TRIGGERED | tool={tool_name}")
    log(f"EVENT KEYS | {list(event.keys())}")

    if isinstance(tool_args, str):
        try:
            tool_args = json.loads(tool_args)

        except json.JSONDecodeError:
            tool_args = {"patch": tool_args}

    if isinstance(tool_args, dict):
        log(f"TOOL ARGUMENT KEYS | {list(tool_args.keys())}")

    paths = collect_paths(tool_args)

    if not paths:
        log(f"NO BASH FILES DETECTED | tool={tool_name}")
        print("{}")
        return

    messages = []

    for filename in sorted(paths):
        path = Path(filename)

        if not path.is_absolute():
            path = cwd / path

        path = path.resolve()

        if not path.is_relative_to(cwd):
            log(f"SKIPPED outside workspace: {path}")
            continue

        if not path.is_file():
            log(f"SKIPPED missing file: {path}")
            continue

        log(f"VALIDATING | {path}")

        messages.extend(validate_file(path))

    if messages:
        print(json.dumps({
            "additionalContext": (
                "Automatic Bash validation detected errors. "
                "Correct the following issues before "
                "declaring the task successful:\n\n"
                + "\n\n".join(messages)
            )
        }))

    else:
        print("{}")


if __name__ == "__main__":
    try:
        main()

    except Exception as exc:
        log(f"HOOK ERROR | {exc}")
        print("{}")