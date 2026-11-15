import importlib.util
import hashlib
import base64
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
TEST_RUNTIME = os.environ.get("TEST_PWSH_RUNTIME", "powershell-7")


def select_pwsh(runtime, override=None):
    executables = {"powershell-7": "pwsh", "windows-powershell-5.1": "powershell.exe"}
    if runtime not in executables:
        raise ValueError(f"Unknown TEST_PWSH_RUNTIME: {runtime}")
    return override or shutil.which(executables[runtime])


spec = importlib.util.spec_from_file_location("restore_files", ROOT / "restore_files.py")
restore = importlib.util.module_from_spec(spec)
spec.loader.exec_module(restore)


class RestoreTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        base = Path(self.tmp.name)
        self.run = base / "run"
        self.source = self.run / "source"
        self.home = base / "home"
        self.windows = base / "windows"
        for directory in (self.source, self.home, self.windows):
            directory.mkdir(parents=True)
        files = {
            "copilot/agents/example.agent.md": "agent\n",
            "copilot/instructions/example.instructions.md": "instruction\n",
            "copilot/prompts/example.prompt.md": "prompt\n",
            "copilot/skills/example/SKILL.md": "skill\n",
            "copilot/hooks/example.json": '{"version": 1, "hooks": {}}\n',
            "copilot/config/mcp-config.json": '{"mcpServers": {}}\n',
            "vscode/user/settings.json": '{"editor.tabSize": 2}\n',
            "vscode/extensions/extensions.txt": "publisher.extension\n",
        }
        for name, contents in files.items():
            path = self.source / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(contents, encoding="utf-8")
        subprocess.run(["git", "init", "-q", str(self.source)], check=True)
        self.commit()

    def commit(self):
        subprocess.run(["git", "-C", str(self.source), "add", "."], check=True)
        subprocess.run(
            ["git", "-C", str(self.source), "-c", "user.name=Test",
             "-c", "user.email=test@example.invalid", "commit", "-qm", "fixture"],
            check=True,
        )

    def test_existing_and_new_files_restore_and_rollback(self):
        existing = self.windows / "settings.json"
        existing.write_text('{"previous": true}\n', encoding="utf-8")
        existing.chmod(0o600)
        plan = restore.prepare(self.run, self.windows, self.home)
        restore.apply(self.run)
        self.assertEqual(restore.digest(existing), next(
            item["sha256"] for item in plan["files"] if item["windows"]
        ))
        new = self.home / ".copilot/agents/example.agent.md"
        self.assertTrue(new.is_file())
        restore.rollback(self.run)
        self.assertEqual(existing.read_text(), '{"previous": true}\n')
        self.assertEqual(existing.stat().st_mode & 0o777, 0o600)
        self.assertFalse(new.exists())
        self.assertFalse((self.run / "verification.json").exists())

    def test_rollback_conflict_preserves_changed_files(self):
        existing = self.windows / "settings.json"
        existing.write_text("before")
        restore.prepare(self.run, self.windows, self.home)
        restore.apply(self.run)
        existing.write_text("changed after restore")
        with self.assertRaisesRegex(ValueError, "Rollback conflict"):
            restore.rollback(self.run)
        self.assertEqual(existing.read_text(), "changed after restore")

    def test_tampered_backup_is_rejected_before_rollback(self):
        existing = self.windows / "settings.json"
        existing.write_text("before")
        restore.prepare(self.run, self.windows, self.home)
        restore.apply(self.run)
        states = json.loads((self.run / "rollback.json").read_text())
        backup = next(Path(item["backup"]) for item in states if item["backup"])
        backup.write_text("tampered")
        with self.assertRaisesRegex(ValueError, "backup SHA-256 mismatch"):
            restore.rollback(self.run)

    def test_symlink_destination_is_rejected(self):
        (self.home / ".copilot").symlink_to(self.windows, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "Symlink is not allowed"):
            restore.prepare(self.run, self.windows, self.home)

    def test_hardlinked_destination_is_rejected(self):
        target = self.windows / "settings.json"
        target.write_text("{}")
        os.link(target, self.windows / "other.json")
        with self.assertRaisesRegex(ValueError, "Not an independent regular file"):
            restore.prepare(self.run, self.windows, self.home)

    def test_forbidden_credential_file_is_rejected(self):
        (self.source / "copilot/skills/example/.env").write_text("placeholder")
        self.commit()
        with self.assertRaisesRegex(ValueError, "Forbidden credential"):
            restore.prepare(self.run, self.windows, self.home)

    def test_session_directory_is_rejected(self):
        path = self.source / "copilot/skills/example/session-state"
        path.mkdir()
        (path / "state.json").write_text("{}")
        self.commit()
        with self.assertRaisesRegex(ValueError, "Forbidden runtime"):
            restore.prepare(self.run, self.windows, self.home)

    def test_cli_settings_are_included_only_when_requested(self):
        (self.source / "copilot/config/settings.json").write_text("{}\n")
        self.commit()
        plan = restore.prepare(self.run, self.windows, self.home)
        self.assertNotIn("copilot/config/settings.json", [item["source"] for item in plan["files"]])
        (self.run / "plan.json").unlink()
        plan = restore.prepare(self.run, self.windows, self.home, cli_settings=True)
        self.assertIn("copilot/config/settings.json", [item["source"] for item in plan["files"]])

    def test_source_change_after_review_is_rejected(self):
        restore.prepare(self.run, self.windows, self.home)
        (self.source / "copilot/agents/example.agent.md").write_text("changed")
        with self.assertRaisesRegex(ValueError, "checkout changed"):
            restore.apply(self.run)
        self.assertFalse((self.run / "rollback.json").exists())

    def test_tracked_snapshot_restores_in_isolation(self):
        base = Path(self.tmp.name)
        run = base / "snapshot-run"
        home = base / "snapshot-home"
        windows = base / "snapshot-windows"
        run.mkdir()
        home.mkdir()
        windows.mkdir()
        subprocess.run(
            ["git", "-c", "core.hooksPath=/dev/null", "clone", "-q", "--no-local",
             str(ROOT), str(run / "source")],
            check=True,
        )
        plan = restore.prepare(run, windows, home)
        self.assertGreater(len(plan["files"]), 7)
        restore.apply(run)
        restore.rollback(run)
        self.assertFalse((home / ".copilot/mcp-config.json").exists())


class ShellSafetyTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.bin = self.home / "bin"
        self.bin.mkdir()
        for name in ("id", "stat", "dirname"):
            (self.bin / name).symlink_to(shutil.which(name))
        self.env = os.environ.copy()
        self.env.update(HOME=str(self.home), PATH=str(self.bin))
        self.env.pop("COPILOT_HOME", None)
        self.run = str(self.home / ("copilot-restore-" + "a" * 32))

    def invoke(self, action, run=None, *args):
        return subprocess.run(
            ["/bin/bash", str(ROOT / "restore.sh"), action, run or self.run, *args],
            input="\n", text=True, capture_output=True, env=self.env,
        )

    def test_rejects_unsafe_run_directory(self):
        result = self.invoke("audit", str(self.home / "../outside"))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Run directory must be under HOME", result.stderr)

    def test_rejects_symlink_and_non_private_run_directory(self):
        Path(self.run).symlink_to(self.bin, target_is_directory=True)
        result = self.invoke("audit")
        self.assertIn("cannot be a symlink", result.stderr)
        Path(self.run).unlink()
        Path(self.run).mkdir(mode=0o755)
        Path(self.run).chmod(0o755)
        result = self.invoke("audit")
        self.assertIn("must be private", result.stderr)

    def test_missing_packages_are_not_installed_without_approval(self):
        result = self.invoke("install-prerequisites")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("installation not approved", result.stderr)
        self.assertFalse(Path(self.run).exists())

    def test_cli_install_decline_does_not_create_run(self):
        mock = self.home / "mock-shell-env"
        mock.write_text(
            'command() { if [[ $1 == -v && $2 == copilot ]]; then return 1; fi; '
            'builtin command -v "$2"; }\n',
            encoding="utf-8",
        )
        self.env["BASH_ENV"] = str(mock)
        result = self.invoke("install-cli")
        self.assertEqual(result.returncode, 3)
        self.assertIn("SKIPPED", result.stdout)
        self.assertFalse(Path(self.run).exists())

    def test_audit_reports_missing_tools_as_not_verified(self):
        result = self.invoke("audit")
        self.assertEqual(result.returncode, 3)
        self.assertIn("NOT VERIFIED: git unavailable", result.stdout)
        self.assertIn("NOT VERIFIED: PyYAML unavailable", result.stdout)

    def test_audit_reports_available_tools_as_pass(self):
        for name in ("git", "ssh", "python3", "curl", "tar", "gzip", "copilot", "gitleaks"):
            (self.bin / name).symlink_to("/bin/true")
        result = self.invoke("audit")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("PASS: git available", result.stdout)
        self.assertIn("PASS: PyYAML available", result.stdout)
        self.assertIn("NOT VERIFIED: SSH identity", result.stdout)

    def test_windows_mount_identifies_nearest_drive_mount(self):
        script = (ROOT / "restore.sh").read_text(encoding="utf-8")
        body = script.split("windows_mount() {", 1)[1].split("\n}\n", 1)[0]
        command = "windows_mount() {" + body + '\n}\nwindows_mount "$1" < "$2"'
        mounts = self.home / "mounts"
        mounts.write_text(
            "/dev/sda / ext4 rw 0 0\n"
            "C:\\134 /drives\\040shared/c 9p rw,aname=drvfs;path=C:\\134 0 0\n"
            "D: /windir/d drvfs rw 0 0\n"
            "server /network 9p rw,aname=drvfs;path=C:\\134 0 0\n"
            "E:\\134 /other 9p rw,aname=other;path=E:\\134 0 0\n"
            "/dev/sdb /drives\\040shared/c/nested ext4 rw 0 0\n",
            encoding="utf-8",
        )
        cases = {
            "/drives shared/c/Users/example": True,
            "/windir/d/Users/example": True,
            "/drives shared/c/nested/User": False,
            "/drives shared/c-other/User": False,
            "/mnt/c/Users/example": False,
            "/network/User": False,
            "/other/User": False,
        }
        for target, allowed in cases.items():
            with self.subTest(target=target):
                result = subprocess.run(
                    ["/bin/bash", "-c", command, "test", target, str(mounts)],
                    capture_output=True, text=True, env=self.env,
                )
                self.assertEqual(result.returncode == 0, allowed, result.stderr)

    def test_prepare_rejects_linux_and_symlink_destinations(self):
        directory = self.home / "windows"
        directory.mkdir()
        link = self.home / "link"
        link.symlink_to(directory, target_is_directory=True)
        for destination in (directory, link):
            with self.subTest(destination=destination):
                result = self.invoke("prepare", None, str(destination))
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("canonical path on a mounted Windows drive", result.stderr)
                self.assertFalse(Path(self.run).exists())


class RuntimeSelectionTests(unittest.TestCase):
    def test_runtime_selection_never_silently_substitutes_another_edition(self):
        with mock.patch("shutil.which", side_effect=lambda name: "/fixture/" + name):
            self.assertEqual(select_pwsh("powershell-7"), "/fixture/pwsh")
            self.assertEqual(select_pwsh("windows-powershell-5.1"), "/fixture/powershell.exe")
            self.assertEqual(select_pwsh("powershell-7", "/custom/pwsh"), "/custom/pwsh")
        with mock.patch("shutil.which", side_effect=lambda name: None if name == "pwsh" else "/fixture/powershell.exe"):
            self.assertIsNone(select_pwsh("powershell-7"))
        with self.assertRaises(ValueError):
            select_pwsh("auto")


class LauncherTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.pwsh = select_pwsh(TEST_RUNTIME, os.environ.get("TEST_PWSH"))
        if not cls.pwsh:
            raise unittest.SkipTest(f"{TEST_RUNTIME} unavailable; launcher behavior NOT VERIFIED")
        cls.windows_powershell = TEST_RUNTIME == "windows-powershell-5.1"
        if cls.windows_powershell and not shutil.which("wslpath"):
            raise unittest.SkipTest("WSL path translation unavailable; Windows launcher behavior NOT VERIFIED")
        probe = subprocess.run(
            [cls.pwsh, "-NoLogo", "-NoProfile", "-NonInteractive", "-Command",
             '"{0}|{1}.{2}|{3}" -f $PSVersionTable.PSEdition, '
             '$PSVersionTable.PSVersion.Major, $PSVersionTable.PSVersion.Minor, (Get-ExecutionPolicy)'],
            text=True, capture_output=True,
        )
        if probe.returncode:
            raise RuntimeError(f"Cannot identify {TEST_RUNTIME}: {probe.stderr}")
        identity = probe.stdout.strip().split("|")
        expected = ("Desktop", "5.1") if cls.windows_powershell else ("Core", "7")
        if len(identity) != 3 or identity[0] != expected[0] or (
            identity[1] != "5.1" if cls.windows_powershell else not identity[1].startswith("7.")
        ):
            raise RuntimeError(f"Selected {TEST_RUNTIME}, but runtime reports {probe.stdout.strip()!r}")
        print(f"Launcher test runtime: {TEST_RUNTIME} ({identity[0]} {identity[1]}; policy {identity[2]})",
              file=sys.stderr)
        if cls.windows_powershell and identity[2] == "Restricted":
            raise unittest.SkipTest("Windows PowerShell execution policy is Restricted; launcher behavior NOT VERIFIED")

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        base = Path(self.tmp.name)
        self.log = base / "calls.jsonl"
        binary = base / "bin"
        binary.mkdir()
        wsl = binary / "wsl.exe"
        wsl.write_text("""#!/usr/bin/python3
import json, os, sys
args = sys.argv[1:]
with open(os.environ["MOCK_LOG"], "a") as out:
    out.write(json.dumps(args) + "\\n")
cmd = args[args.index("--exec") + 1:]
if cmd[:2] == ["id", "-un"]:
    print("demo")
elif cmd[:2] == ["getent", "passwd"]:
    name = cmd[2]
    print(name + ":x:1000:1000::" + ("/root" if name == "root" else "/home/demo") + ":/bin/bash")
elif cmd[:2] == ["printenv", "HOME"]:
    name = args[args.index("--user") + 1]
    print("/root" if name == "root" else "/home/demo")
elif cmd[:2] == ["test", "-d"]:
    name = args[args.index("--user") + 1]
    sys.exit(0 if name in os.environ.get("MOCK_EXISTING", "").split(",") else 1)
elif cmd[0] == "wslpath":
    print(cmd[-1])
elif cmd[0] == "sha256sum":
    changed = os.environ.get("MOCK_PLAN_CHANGE") and open(os.environ["MOCK_LOG"]).read().count('"sha256sum"') > 1
    print(("changed" if changed else "abc") + "  " + cmd[1])
elif cmd[0] == "cat":
    print(json.dumps({"commit": "fixture", "files": [{"source": "vscode/user/settings.json",
          "target": os.environ["MOCK_TARGET"], "sha256": os.environ["MOCK_HASH"], "windows": True}],
          "extensions": []}))
elif cmd[0] == "bash":
    action = cmd[2]
    if action not in ("audit", "health", "install-prerequisites", "prepare", "apply",
                      "verify", "install-cli", "extensions-status"):
        sys.exit(2)
    if action == os.environ.get("MOCK_FAIL"):
        sys.exit(2)
    if action == "audit":
        sys.exit(int(os.environ.get("MOCK_AUDIT_EXIT", "0")))
    if action == "health":
        sys.exit(3)
    if action == "install-cli":
        sys.exit(int(os.environ.get("MOCK_CLI_EXIT", "0")))
else:
    sys.exit(2)
""", encoding="utf-8")
        wsl.chmod(0o755)
        code = binary / "code.cmd"
        code.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
        code.chmod(0o755)
        appdata = base / "appdata"
        (appdata / "Code/User").mkdir(parents=True)
        target = appdata / "Code/User/settings.json"
        target.write_text("{}\n", encoding="utf-8")
        self.env = os.environ.copy()
        self.env.update(
            PATH=str(binary) + os.pathsep + os.environ.get("PATH", ""),
            APPDATA=str(appdata), MOCK_LOG=str(self.log), LAUNCHER=str(ROOT / "Restore-Copilot.ps1"),
            MOCK_TARGET=str(target), MOCK_HASH=hashlib.sha256(target.read_bytes()).hexdigest(),
            DOTNET_SYSTEM_GLOBALIZATION_INVARIANT="1",
        )

    def launch(self, mode=None, **extra):
        if self.windows_powershell:
            return self.launch_windows(mode, **extra)
        env = self.env.copy()
        env.update(extra)
        env["MODE"] = mode or ""
        command = r"""
$env:OS = 'Windows_NT'
if ($env:MOCK_MISSING_APPDATA) { $env:APPDATA = Join-Path $env:APPDATA 'missing' }
function global:Get-Command {
    param($Name, $ErrorAction)
    if ($Name -eq 'code.cmd' -and $env:MOCK_MISSING_CODE) { return }
    Microsoft.PowerShell.Core\Get-Command -Name $Name -ErrorAction $ErrorAction
}
function global:Read-Host {
    param($Prompt)
    if ($Prompt -like '*Both root*') { return $env:MOCK_CHOICE }
    if ($Prompt -like '*PREPARE*') { return 'PREPARE' }
    if ($Prompt -like '*RESTORE*' -and -not $env:MOCK_DENY) { return 'RESTORE' }
    return ''
}
function global:Get-Process { param($Name, $ErrorAction) }
if ($env:MODE) { & $env:LAUNCHER -Distro Ubuntu -Mode $env:MODE }
else { & $env:LAUNCHER -Distro Ubuntu }
"""
        result = subprocess.run(
            [self.pwsh, "-NoLogo", "-NoProfile", "-NonInteractive", "-Command", command],
            env=env, text=True, capture_output=True,
        )
        calls = [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []
        actions = [call[call.index("--exec") + 3] for call in calls
                   if "--exec" in call and call[call.index("--exec") + 1] == "bash"]
        return result, calls, actions

    def launch_windows(self, mode=None, **extra):
        def windows_path(path):
            return subprocess.check_output(
                ["wslpath", "-w", str(path)], text=True,
            ).strip()

        base = Path(self.tmp.name)
        settings = {
            "APPDATA": windows_path(base / "appdata"),
            "MOCK_LOG": windows_path(self.log),
            "MOCK_TARGET": windows_path(base / "appdata/Code/User/settings.json"),
            "MOCK_RUN": windows_path(base / "mock-run"),
            "MOCK_HASH": self.env["MOCK_HASH"],
            "MODE": mode or "",
            "MOCK_CHOICE": "",
            "MOCK_EXISTING": "",
            "MOCK_DENY": "",
            "MOCK_FAIL": "",
            "MOCK_CLI_EXIT": "0",
            "MOCK_PLAN_CHANGE": "",
            "MOCK_PROBE_UNKNOWN": "",
            "MOCK_AUDIT_EXIT": "0",
            "MOCK_MISSING_CODE": "",
            "MOCK_MISSING_APPDATA": "",
        }
        settings.update(extra)
        config = base / "windows-settings.json"
        config.write_text(json.dumps(settings), encoding="utf-8")
        env = self.env.copy()
        env.update(
            TEST_CONFIG=str(config),
            TEST_LAUNCHER=str(ROOT / "Restore-Copilot.ps1"),
            WSLENV="TEST_CONFIG/pw:TEST_LAUNCHER/pw",
        )
        command = r"""
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $env:TEST_CONFIG -PathType Leaf) -or
    -not (Test-Path -LiteralPath $env:TEST_LAUNCHER -PathType Leaf)) {
    throw 'Test fixture or launcher is inaccessible.'
}
$settings = [IO.File]::ReadAllText($env:TEST_CONFIG, [Text.Encoding]::UTF8) | ConvertFrom-Json
foreach ($property in $settings.PSObject.Properties) {
    [Environment]::SetEnvironmentVariable($property.Name, [string]$property.Value, 'Process')
}
if ($env:MOCK_MISSING_APPDATA) { $env:APPDATA = Join-Path $env:APPDATA 'missing' }
$global:MockHashCalls = 0
function global:Get-Command {
    param($Name, $ErrorAction)
    if ($Name -eq 'wsl.exe') { return [pscustomobject]@{ Source = 'Invoke-TestWsl' } }
    if ($Name -eq 'code.cmd' -and -not $env:MOCK_MISSING_CODE) { return [pscustomobject]@{ Source = 'Invoke-TestCode' } }
    if ($Name -eq 'code.cmd') { return }
    throw "Unexpected command discovery: $Name"
}
function global:Invoke-TestCode { throw 'Unexpected VS Code invocation.' }
function global:Invoke-TestWsl {
    $call = @($args)
    $line = ConvertTo-Json -InputObject $call -Compress
    [IO.File]::AppendAllText($env:MOCK_LOG, $line + "`n", [Text.UTF8Encoding]::new($false))
    $global:LASTEXITCODE = 0
    $index = [Array]::IndexOf($call, '--exec')
    if ($index -lt 0 -or $index -ge $call.Count - 1) { throw 'Unexpected WSL arguments.' }
    $cmd = @($call[($index + 1)..($call.Count - 1)])
    if ($cmd.Count -eq 2 -and $cmd[0] -eq 'id' -and $cmd[1] -eq '-un') {
        return 'demo'
    }
    if ($cmd.Count -eq 3 -and $cmd[0] -eq 'getent' -and $cmd[1] -eq 'passwd' -and $cmd[2] -in @('demo', 'root')) {
        $homePath = if ($cmd[2] -eq 'root') { '/root' } else { '/home/demo' }
        return "$($cmd[2]):x:1000:1000::$($homePath):/bin/bash"
    }
    if ($cmd.Count -eq 2 -and $cmd[0] -eq 'printenv' -and $cmd[1] -eq 'HOME') {
        $userIndex = [Array]::IndexOf($call, '--user')
        if ($userIndex -lt 0) { throw 'Missing mock WSL user.' }
        if ($call[$userIndex + 1] -eq 'root') { return '/root' }
        if ($call[$userIndex + 1] -eq 'demo') { return '/home/demo' }
        throw 'Unexpected mock WSL user.'
    }
    if ($cmd.Count -eq 3 -and $cmd[0] -eq 'test' -and $cmd[1] -eq '-d') {
        $userIndex = [Array]::IndexOf($call, '--user')
        if ($userIndex -lt 0 -or $call[$userIndex + 1] -notin @('root', 'demo')) { throw 'Unexpected mock WSL user.' }
        if ($call[$userIndex + 1] -notin $env:MOCK_EXISTING.Split(',')) { $global:LASTEXITCODE = 1 }
        return
    }
    if ($cmd[0] -eq 'wslpath' -and
        (($cmd.Count -eq 3 -and $cmd[1] -eq '-w') -or
         ($cmd.Count -eq 4 -and $cmd[1] -eq '-a' -and $cmd[2] -eq '-u'))) {
        if ($cmd[1] -eq '-w' -and $cmd[-1] -match '/copilot-restore-[a-f0-9]{32}$') { return $env:MOCK_RUN }
        return $cmd[-1]
    }
    if ($cmd.Count -eq 2 -and $cmd[0] -eq 'sha256sum') {
        $global:MockHashCalls++
        $hash = if ($env:MOCK_PLAN_CHANGE -and $global:MockHashCalls -gt 1) { 'changed' } else { 'abc' }
        return "$hash  $($cmd[1])"
    }
    if ($cmd.Count -eq 2 -and $cmd[0] -eq 'cat' -and $cmd[1] -like '*/plan.json') {
        $plan = @{
            commit = 'fixture'
            files = @(@{ source = 'vscode/user/settings.json'; target = $env:MOCK_TARGET; sha256 = $env:MOCK_HASH; windows = $true })
            extensions = @()
        }
        return (ConvertTo-Json -InputObject $plan -Depth 5 -Compress)
    }
    if ($cmd.Count -ge 4 -and $cmd[0] -eq 'bash' -and
        $cmd[2] -in @('audit', 'health', 'install-prerequisites', 'prepare', 'apply', 'verify', 'install-cli', 'extensions-status')) {
        if ($cmd[2] -eq $env:MOCK_FAIL) { $global:LASTEXITCODE = 2 }
        elseif ($cmd[2] -eq 'audit') { $global:LASTEXITCODE = [int]$env:MOCK_AUDIT_EXIT }
        elseif ($cmd[2] -eq 'health') { $global:LASTEXITCODE = 3 }
        elseif ($cmd[2] -eq 'install-cli') { $global:LASTEXITCODE = [int]$env:MOCK_CLI_EXIT }
        return
    }
    throw 'Unexpected mock WSL command.'
}
function global:Read-Host {
    param($Prompt)
    if ($Prompt -like '*Both root*') { return $env:MOCK_CHOICE }
    if ($Prompt -like '*PREPARE*') { return 'PREPARE' }
    if ($Prompt -like '*RESTORE*' -and -not $env:MOCK_DENY) { return 'RESTORE' }
    return ''
}
function global:Get-Process { param($Name, $ErrorAction) }
if ($env:MOCK_PROBE_UNKNOWN) {
    try { Invoke-TestWsl --exec bash fixture unexpected fixture; exit 1 }
    catch { Write-Host 'Unexpected command blocked'; exit 0 }
}
if ($env:MODE) { & $env:TEST_LAUNCHER -Distro Ubuntu -Mode $env:MODE }
else { & $env:TEST_LAUNCHER -Distro Ubuntu }
"""
        encoded = base64.b64encode(command.encode("utf-16le")).decode("ascii")
        result = subprocess.run(
            [self.pwsh, "-NoLogo", "-NoProfile", "-NonInteractive", "-EncodedCommand", encoded],
            env=env, text=True, capture_output=True,
        )
        calls = [json.loads(line) for line in self.log.read_text(encoding="utf-8").splitlines()] if self.log.exists() else []
        actions = [call[call.index("--exec") + 3] for call in calls
                   if "--exec" in call and call[call.index("--exec") + 1] == "bash"]
        return result, calls, actions

    def test_audit_does_not_prepare_or_install(self):
        if self.windows_powershell:
            result, calls, actions = self.launch("Audit", MOCK_PROBE_UNKNOWN="1")
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("Unexpected command blocked", result.stdout)
            self.log.unlink()
        result, calls, actions = self.launch("Audit")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(actions, ["audit", "health"])
        self.assertIn("Restore: SKIPPED", result.stdout)
        self.assertTrue(any("demo" in call for call in calls))

    def test_audit_status_propagates_without_stopping_other_modes(self):
        for extra in ({"MOCK_AUDIT_EXIT": "3"}, {"MOCK_MISSING_CODE": "1"},
                      {"MOCK_MISSING_APPDATA": "1"}):
            with self.subTest(extra=extra):
                result, calls, actions = self.launch("Install", **extra)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("Environment: NOT VERIFIED", result.stdout)
                self.assertIn("install-cli", actions)
                self.log.unlink()
        result, calls, actions = self.launch("Audit", MOCK_FAIL="audit")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Environment: FAIL", result.stdout)
        self.assertNotIn("health", actions)

    def test_full_and_legacy_route_through_existing_engine(self):
        result, calls, actions = self.launch("Full")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(actions, ["audit", "health", "install-prerequisites", "prepare", "apply",
                                   "verify", "health", "install-cli", "extensions-status", "verify"])
        self.assertIn("Restore: PASS", result.stdout)
        self.log.unlink()
        result, calls, actions = self.launch()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(all(call[call.index("--user") + 1] == "root" for call in calls
                            if "--user" in call))
        self.assertIn("apply", actions)

    def test_install_can_defer_cli_without_preparing_restore(self):
        result, calls, actions = self.launch("Install", MOCK_CLI_EXIT="3")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(actions, ["audit", "health", "install-prerequisites", "install-cli"])
        self.assertIn("CopilotInstall: SKIPPED", result.stdout)

    def test_prepare_failure_stops_and_reports_failure(self):
        result, calls, actions = self.launch("Restore", MOCK_FAIL="prepare")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Restore: FAIL", result.stdout)
        self.assertNotIn("apply", actions)

    def test_denied_restore_and_changed_plan_never_apply(self):
        result, calls, actions = self.launch("Restore", MOCK_DENY="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("apply", actions)
        self.log.unlink()
        result, calls, actions = self.launch("Restore", MOCK_PLAN_CHANGE="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Restore plan changed", result.stdout)
        self.assertNotIn("apply", actions)

    def test_missing_prerequisite_failure_stops_before_prepare(self):
        result, calls, actions = self.launch("Full", MOCK_FAIL="install-prerequisites")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Prerequisites: FAIL", result.stdout)
        self.assertNotIn("prepare", actions)

    def test_ambiguous_accounts_require_explicit_selection(self):
        result, calls, actions = self.launch("Audit", MOCK_EXISTING="root,demo", MOCK_CHOICE="ROOT")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        audits = [call for call in calls if "audit" in call]
        self.assertEqual(audits[0][audits[0].index("--user") + 1], "root")


if __name__ == "__main__":
    unittest.main()
