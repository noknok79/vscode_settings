#!/usr/bin/env python3
"""Read-only GitHub Copilot configuration health check."""

import argparse
import json
import sys
from pathlib import Path

import yaml


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--home",
        type=Path,
        default=Path.home() / ".copilot",
    )
    parser.add_argument(
        "--drift",
        action="store_true",
        help="Compare active Copilot configuration with backup",
    )
    parser.add_argument(
        "--backup",
        type=Path,
        default=Path("/root/vscode_settings_clean/copilot"),
    )
    args = parser.parse_args()

    base = args.home
    passed = 0
    warnings = 0
    failures = 0

    def report(status, message):
        nonlocal passed, warnings, failures

        print(f"[{status}] {message}")

        if status == "PASS":
            passed += 1
        elif status == "WARN":
            warnings += 1
        else:
            failures += 1

    print("========================================")
    print(" COPILOT CONFIGURATION HEALTH CHECK")
    print("========================================")

    if not base.is_dir():
        report("FAIL", "Copilot directory missing")
        return 1

    categories = (
        "agents",
        "skills",
        "prompts",
        "instructions",
        "hooks",
    )

    print("\n=== CONFIGURATION DIRECTORIES ===")

    for category in categories:
        directory = base / category

        if directory.is_dir():
            report("PASS", f"{category}/ exists")
        else:
            report("WARN", f"{category}/ missing")

    print("\n=== JSON VALIDATION ===")

    for directory_name in ("hooks",):
        directory = base / directory_name

        if not directory.is_dir():
            continue

        for path in sorted(directory.glob("*.json")):
            try:
                json.loads(path.read_text(encoding="utf-8"))
                report("PASS", f"JSON: {path.name}")
            except (json.JSONDecodeError, UnicodeError) as exc:
                report("FAIL", f"JSON: {path.name}: {exc}")

    print("\n=== MCP CONFIGURATION ===")

    mcp = base / "mcp-config.json"

    if mcp.exists():
        try:
            config = json.loads(mcp.read_text(encoding="utf-8"))

            servers = config.get("mcpServers")

            if isinstance(servers, dict):
                report(
                    "PASS",
                    f"MCP configuration: {len(servers)} server(s)",
                )
            else:
                report("FAIL", "Invalid MCP server structure")

        except (json.JSONDecodeError, UnicodeError) as exc:
            report("FAIL", f"MCP configuration: {exc}")
    else:
        report("WARN", "MCP configuration missing")

    print("\n=== SKILL ENTRYPOINTS ===")

    skills = base / "skills"

    if skills.is_dir():
        for directory in sorted(skills.iterdir()):
            if not directory.is_dir():
                continue

            entrypoint = directory / "SKILL.md"

            if not entrypoint.exists():
                report("FAIL", f"Skill missing SKILL.md: {directory.name}")
            else:
                report("PASS", f"Skill: {directory.name}")

    print("\n=== YAML FRONTMATTER ===")

    patterns = {
        "agents": "*.agent.md",
        "prompts": "*.prompt.md",
        "instructions": "*.instructions.md",
    }

    for category, pattern in patterns.items():
        directory = base / category

        if not directory.is_dir():
            continue

        for path in sorted(directory.glob(pattern)):
            try:
                text = path.read_text(encoding="utf-8")

                if not text.startswith("---\n"):
                    if category == "instructions" and text.strip():
                        report("PASS", f"Markdown instruction: {path.name}")
                        continue

                    report("FAIL", f"Frontmatter missing: {path.name}")
                    continue

                parts = text.split("---", 2)

                if len(parts) < 3:
                    report("FAIL", f"Frontmatter incomplete: {path.name}")
                    continue

                metadata = yaml.safe_load(parts[1])

                if not isinstance(metadata, dict):
                    report("FAIL", f"Frontmatter invalid: {path.name}")
                else:
                    report("PASS", f"Frontmatter: {path.name}")

            except (yaml.YAMLError, UnicodeError) as exc:
                report("FAIL", f"Frontmatter: {path.name}: {exc}")


    if args.drift:
        import hashlib

        print("\\n=== CONFIGURATION DRIFT ===")

        backup = args.backup

        def digest(path):
            return hashlib.sha256(path.read_bytes()).hexdigest()

        for category in categories:
            active_dir = base / category
            backup_dir = backup / category

            if not active_dir.is_dir() or not backup_dir.is_dir():
                report("WARN", f"Drift comparison unavailable: {category}")
                continue

            def eligible(path):
                name = path.name

                # Compare only actual prompt definitions.
                if category == "prompts" and not name.endswith(".prompt.md"):
                    return False

                if "__pycache__" in path.parts:
                    return False

                # Ignore historical backup directories.
                if any(
                    part.startswith("backup-")
                    for part in path.parts
                ):
                    return False

                if name.endswith((".pyc", ".pyo", ".log", ".bak")):
                    return False

                # Ignore Windows alternate-data-stream artifacts.
                if ":" in name:
                    return False

                if ".backup-" in name or ".pre-" in name:
                    return False

                return True

            active_files = {
                str(p.relative_to(active_dir)): p
                for p in active_dir.rglob("*")
                if p.is_file() and eligible(p)
            }

            backup_files = {
                str(p.relative_to(backup_dir)): p
                for p in backup_dir.rglob("*")
                if p.is_file() and eligible(p)
            }

            for name in sorted(active_files.keys() | backup_files.keys()):
                a = active_files.get(name)
                b = backup_files.get(name)

                if a is None:
                    report("WARN", f"Backup only: {category}/{name}")
                elif b is None:
                    report("WARN", f"Active only: {category}/{name}")
                elif digest(a) != digest(b):
                    report("WARN", f"Modified: {category}/{name}")

        active_mcp = base / "mcp-config.json"
        backup_mcp = backup / "config" / "mcp-config.json"

        if active_mcp.is_file() and backup_mcp.is_file():
            if digest(active_mcp) == digest(backup_mcp):
                report("PASS", "MCP configuration matches backup")
            else:
                report("WARN", "MCP configuration differs from backup")
        else:
            report("WARN", "MCP drift comparison unavailable")

    print("\n========================================")
    print(" HEALTH CHECK SUMMARY")
    print("========================================")

    print(f"PASS: {passed}")
    print(f"WARN: {warnings}")
    print(f"FAIL: {failures}")

    if failures:
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
