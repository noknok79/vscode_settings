#!/usr/bin/env python3
"""Allowlisted configuration restore; never execute files from the backup."""

import argparse
import ast
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import subprocess
import sys
import tempfile


CATEGORIES = ("agents", "instructions", "prompts", "skills", "hooks")
SECRETS = re.compile(
    rb"(?:gh[opsur]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}"
    rb"|-----BEGIN [A-Z ]*PRIVATE KEY-----|Bearer [A-Za-z0-9_.-]{20,})"
)


def fail(message):
    raise ValueError(message)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save(path, value):
    with path.open("x", encoding="utf-8") as file:
        json.dump(value, file, indent=2)
        file.write("\n")


def git(source, *arguments):
    return subprocess.check_output(["git", "-C", str(source), *arguments])


def safe_path(path):
    for item in (path, *path.parents):
        if item.is_symlink():
            fail(f"Symlink is not allowed: {item}")
    if path.exists() and not path.is_dir():
        if not path.is_file() or path.stat().st_nlink != 1:
            fail(f"Not an independent regular file: {path}")


def jsonc(data):
    # Keep JSON strings intact while removing comments and trailing commas.
    strings = r'"(?:\\.|[^"\\])*"'
    clean = re.sub(
        f"({strings})|//[^\\r\\n]*|/\\*[\\s\\S]*?\\*/",
        lambda match: match.group(1) if match.group(1) else " ",
        data.decode("utf-8-sig"),
    )
    clean = re.sub(
        f"({strings})|,(\\s*[}}\\]])",
        lambda match: match.group(1) if match.group(1) else match.group(2),
        clean,
    )
    return json.loads(clean)


def targets(relative, home, windows, cli_settings):
    parts = relative.parts
    if len(parts) >= 3 and parts[0] == "copilot" and parts[1] in CATEGORIES:
        return home / ".copilot" / Path(*parts[1:])
    if str(relative) == "copilot/config/mcp-config.json":
        return home / ".copilot/mcp-config.json"
    if str(relative) == "copilot/config/settings.json" and cli_settings:
        return home / ".copilot/settings.json"
    if str(relative) in ("vscode/user/settings.json", "vscode/user/keybindings.json"):
        return windows / relative.name
    if len(parts) >= 4 and parts[:3] == ("vscode", "user", "snippets"):
        return windows / Path(*parts[2:])
    if str(relative) == "vscode/remote/settings.json":
        return home / ".vscode-server/data/Machine/settings.json"
    return None


def prepare(run, windows, home, cli_settings=False):
    source = run / "source"
    safe_path(run)
    safe_path(windows)
    safe_path(home)
    if not windows.is_dir():
        fail(f"Windows VS Code User directory missing: {windows}")
    if git(source, "status", "--porcelain", "--untracked-files=all").strip():
        fail("Backup checkout is not clean")
    files = []
    seen = set()
    extensions = []
    for entry in git(source, "ls-files", "--stage", "-z").split(b"\0"):
        if not entry:
            continue
        metadata, raw_path = entry.split(b"\t", 1)
        mode, _, stage = metadata.decode().split()
        name = raw_path.decode("utf-8")
        relative = PurePosixPath(name)
        if relative.is_absolute() or ".." in relative.parts or any(ord(c) < 32 for c in name):
            fail("Invalid tracked path in backup")
        target = targets(relative, home, windows, cli_settings)
        inventory = name == "vscode/extensions/extensions.txt"
        if target is None and not inventory:
            continue
        if mode not in ("100644", "100755") or stage != "0":
            fail(f"Symlinks/submodules/unmerged paths are unsupported: {name}")
        file = source / name
        safe_path(file)
        data = file.read_bytes()
        blob = git(source, "cat-file", "blob", f"HEAD:{name}")
        if data != blob:
            fail(f"Checkout bytes differ from Git blob: {name}")
        if SECRETS.search(data):
            fail(f"Potential secret in {name}; review and sanitize the backup (value not printed)")
        if inventory:
            extensions = sorted(set(line.strip().lower() for line in data.decode("utf-8-sig").splitlines() if line.strip()))
            if any(not re.fullmatch(r"[a-z0-9][a-z0-9-]*\.[a-z0-9][a-z0-9._-]*", item) for item in extensions):
                fail("Extension inventory must contain publisher.extension IDs only, without versions or CLI arguments")
            continue
        if any(part in (".git", ".ssh", "session-state", "mcp-oauth-config", "mcp-secrets") for part in relative.parts):
            fail(f"Forbidden runtime/credential directory: {name}")
        if relative.name in ("config.json", "auth.json", "credentials", "id_rsa", "id_ed25519"):
            fail(f"Forbidden credential/state filename: {name}")
        safe_path(target)
        if target.exists() and not target.is_file():
            fail(f"Destination is not a regular file: {target}")
        key = str(target).casefold() if target.is_relative_to(windows) else str(target)
        if key in seen:
            fail(f"Destination collision: {name}")
        seen.add(key)
        if target.is_relative_to(windows):
            for part in target.relative_to(windows).parts:
                if re.search(r'[<>:"\\|?*]', part) or part.endswith((".", " ")):
                    fail(f"Invalid Windows filename: {name}")
                if re.fullmatch(r"(?i)(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])", part.split(".")[0]):
                    fail(f"Reserved Windows filename: {name}")
        if name.endswith((".json", ".code-snippets")):
            value = jsonc(data)
            settings_files = {
                "copilot/config/settings.json", "vscode/user/settings.json",
                "vscode/remote/settings.json",
            }
            if (name in settings_files or name.endswith(".code-snippets")) and not isinstance(value, dict):
                fail(f"Settings/snippets must be a JSON object: {name}")
            if name == "vscode/user/keybindings.json" and not isinstance(value, list):
                fail("Windows keybindings must be a JSON array")
            if name == "copilot/config/mcp-config.json":
                value = json.loads(data.decode("utf-8-sig"))
                if not isinstance(value, dict) or not isinstance(value.get("mcpServers"), dict):
                    fail("MCP configuration requires a top-level mcpServers object")
            if name.startswith("copilot/hooks/"):
                value = json.loads(data.decode("utf-8-sig"))
                if not isinstance(value, dict) or type(value.get("version")) is not int or value.get("version") != 1 or not isinstance(value.get("hooks"), dict):
                    fail(f"Unsupported hook JSON schema: {name}")
                if any(not isinstance(entries, list) or any(not isinstance(entry, dict) for entry in entries) for entries in value["hooks"].values()):
                    fail(f"Hook events must contain arrays of hook objects: {name}")
        if name.endswith(".py"):
            ast.parse(data.decode("utf-8-sig"), filename=name)
        if name.endswith(".sh"):
            subprocess.run(["bash", "-n", str(file)], check=True)
        files.append({
            "source": name, "target": str(target), "sha256": hashlib.sha256(data).hexdigest(),
            "mode": int(mode[-3:], 8), "windows": target.is_relative_to(windows),
        })
    required = {"copilot/config/mcp-config.json", "vscode/user/settings.json"}
    if not required.issubset({item["source"] for item in files}):
        fail("Backup lacks required tracked MCP or Windows settings files")
    for category in CATEGORIES:
        if not any(item["source"].startswith(f"copilot/{category}/") for item in files):
            fail(f"Backup lacks tracked files in copilot/{category}")
    plan = {
        "commit": git(source, "rev-parse", "HEAD").decode().strip(),
        "source": str(source), "home": str(home), "windows_user": str(windows),
        "files": files, "extensions": extensions,
    }
    save(run / "plan.json", plan)
    print(f"Prepared {len(files)} files and {len(extensions)} extension IDs. Review {run / 'plan.json'}")
    return plan


def load_plan(run):
    safe_path(run / "plan.json")
    return json.loads((run / "plan.json").read_text(encoding="utf-8"))


def check_sources(plan):
    source = Path(plan["source"])
    if git(source, "rev-parse", "HEAD").decode().strip() != plan["commit"]:
        fail("Prepared Git commit changed")
    if git(source, "status", "--porcelain", "--untracked-files=all").strip():
        fail("Prepared checkout changed; start a new run")
    for item in plan["files"]:
        file = source / item["source"]
        safe_path(file)
        if digest(file) != item["sha256"]:
            fail(f"Source SHA-256 mismatch: {item['source']}")
        target = Path(item["target"])
        safe_path(target)
        if target.exists() and not target.is_file():
            fail(f"Destination is not a file: {target}")


def copy_atomic(source, target, mode=None):
    safe_path(target)
    target.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=".copilot-restore-", dir=target.parent)
    temporary = Path(temporary)
    try:
        with os.fdopen(descriptor, "wb") as file:
            file.write(source.read_bytes())
            file.flush()
            os.fsync(file.fileno())
        if mode is not None:
            temporary.chmod(mode)
        os.replace(temporary, target)
    finally:
        temporary.unlink(missing_ok=True)


def apply(run):
    plan = load_plan(run)
    check_sources(plan)
    backup = run / "rollback"
    backup.mkdir(mode=0o700)
    previous = []
    for index, item in enumerate(plan["files"]):
        target = Path(item["target"])
        saved = backup / str(index)
        state = {"target": str(target), "backup": None, "sha256": None, "mode": None, "restored_sha256": item["sha256"]}
        if target.exists():
            state.update(backup=str(saved), sha256=digest(target), mode=stat.S_IMODE(target.stat().st_mode))
            shutil.copyfile(target, saved)
            if digest(saved) != state["sha256"]:
                fail(f"Rollback backup mismatch: {target}")
        previous.append(state)
    save(run / "rollback.json", previous)
    print(f"Rollback inventory saved: {run / 'rollback.json'}", flush=True)
    for item, before in zip(plan["files"], previous):
        target = Path(item["target"])
        safe_path(target)
        if (target.exists() and digest(target) != before["sha256"]) or (not target.exists() and before["backup"]):
            fail(f"Destination changed after backup: {target}; inspect rollback inventory")
        copy_atomic(Path(plan["source"]) / item["source"], target, None if item["windows"] else item["mode"])
        if digest(target) != item["sha256"]:
            fail(f"Destination SHA-256 mismatch: {target}; inspect rollback inventory")
    verify(run)


def verify(run):
    (run / "verification.json").unlink(missing_ok=True)
    plan = load_plan(run)
    check_sources(plan)
    for item in plan["files"]:
        target = Path(item["target"])
        if not target.is_file() or digest(target) != item["sha256"]:
            fail(f"Destination SHA-256 mismatch: {target}")
    report = {
        "status": "FILE_HASHES_VERIFIED_RUNTIME_NOT_VERIFIED",
        "checked_at": datetime.now(timezone.utc).isoformat(),
        "commit": plan["commit"], "verified_files": len(plan["files"]),
        "rollback": str(run / "rollback.json"),
        "runtime": "Manual sign-in, VS Code/WSL discovery, MCP execution and hook behavior tests required",
    }
    (run / "verification.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"SHA-256 verified for {len(plan['files'])} restored files. Report: {run / 'verification.json'}")


def rollback(run):
    states = json.loads((run / "rollback.json").read_text(encoding="utf-8"))
    for item in states:
        target = Path(item["target"])
        safe_path(target)
        if target.exists() and digest(target) not in (item["sha256"], item["restored_sha256"]):
            fail(f"Rollback conflict; destination changed after restore: {target}")
        if item["backup"] and digest(Path(item["backup"])) != item["sha256"]:
            fail(f"Rollback backup SHA-256 mismatch: {target}")
    for item in states:
        target = Path(item["target"])
        if item["backup"]:
            copy_atomic(Path(item["backup"]), target, item["mode"])
            if digest(target) != item["sha256"]:
                fail(f"Rollback verification failed: {target}")
        else:
            target.unlink(missing_ok=True)
    (run / "verification.json").unlink(missing_ok=True)
    print("Rollback verified. Only files recorded as newly created were removed; directories and extra files were retained.")


def main():
    if sys.version_info < (3, 9):
        fail("Python 3.9 or later is required; use Ubuntu 22.04 or newer")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("prepare", "apply", "verify", "rollback"))
    parser.add_argument("run", type=Path)
    parser.add_argument("--windows-user", type=Path)
    parser.add_argument("--cli-settings", action="store_true")
    args = parser.parse_args()
    run = args.run.absolute()
    if args.action == "prepare":
        if args.windows_user is None:
            parser.error("--windows-user is required for prepare")
        prepare(run, args.windows_user.absolute(), Path.home(), args.cli_settings)
    else:
        {"apply": apply, "verify": verify, "rollback": rollback}[args.action](run)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError, SyntaxError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
