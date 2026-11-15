#!/usr/bin/env python3

import argparse
import re
import sys
from pathlib import Path

import yaml


def read_metadata(path):
    text = path.read_text(encoding="utf-8")

    if not text.startswith("---\n"):
        raise ValueError("Missing YAML frontmatter")

    parts = text.split("---", 2)

    if len(parts) < 3:
        raise ValueError("Incomplete YAML frontmatter")

    metadata = yaml.safe_load(parts[1])

    if not isinstance(metadata, dict):
        raise ValueError("Invalid YAML metadata")

    return metadata


def validate(base):
    prompts = base / "prompts"
    agents = base / "agents"

    failures = []
    warnings = []
    identifiers = set()
    agent_names = {"agent"}

    if not prompts.is_dir():
        return ["Prompt directory missing"], warnings, 0

    if not agents.is_dir():
        warnings.append("Agent directory missing")
    else:
        for path in agents.glob("*.agent.md"):
            agent_names.add(path.name.removesuffix(".agent.md"))

            try:
                metadata = read_metadata(path)
                name = metadata.get("name")

                if isinstance(name, str):
                    agent_names.add(name)

            except (ValueError, yaml.YAMLError, UnicodeError):
                warnings.append(f"Agent metadata unreadable: {path.name}")

    for path in sorted(prompts.glob("*.prompt.md")):
        identifier = path.name.removesuffix(".prompt.md")

        if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", identifier):
            failures.append(f"Invalid filename: {path.name}")

        if identifier in identifiers:
            failures.append(f"Duplicate identifier: {identifier}")

        identifiers.add(identifier)

        try:
            metadata = read_metadata(path)

        except (ValueError, yaml.YAMLError, UnicodeError) as exc:
            failures.append(f"{path.name}: {exc}")
            continue

        description = metadata.get("description")

        if not isinstance(description, str) or not description.strip():
            warnings.append(f"Missing description: {path.name}")

        agent = metadata.get("agent")

        if agent is not None and agent not in agent_names:
            warnings.append(f"Unresolved agent: {path.name}: {agent}")

    readme = prompts / "README.md"

    if readme.is_file():
        for line in readme.read_text(encoding="utf-8").splitlines():
            if not line.startswith("|"):
                continue

            columns = [part.strip() for part in line.strip("|").split("|")]

            if not columns:
                continue

            identifier = columns[0]

            if identifier in {"Prompt", "---", ""}:
                continue

            if set(identifier) == {"-"}:
                continue

            if identifier not in identifiers:
                warnings.append(f"README reference missing: {identifier}")

    return failures, warnings, len(identifiers)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--home",
        type=Path,
        default=Path.home() / ".copilot",
    )
    args = parser.parse_args()

    failures, warnings, count = validate(args.home)

    print(f"Prompts checked: {count}")
    print(f"Warnings: {len(warnings)}")
    print(f"Failures: {len(failures)}")

    for item in warnings:
        print(f"[WARN] {item}")

    for item in failures:
        print(f"[FAIL] {item}")

    if failures:
        return 1

    print("[PASS] Prompt validation")
    return 0


if __name__ == "__main__":
    sys.exit(main())
