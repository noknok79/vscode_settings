#requires -Version 5.1
[CmdletBinding()]
param(
    [ValidatePattern('^[A-Za-z0-9._-]+$')]
    [string]$Distro = 'Ubuntu',
    [string]$CodeCommand = 'code.cmd',
    [switch]$RestoreCliSettings,
    [ValidateSet('Audit', 'Restore', 'Install', 'Full')]
    [string]$Mode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$legacy = -not $PSBoundParameters.ContainsKey('Mode')
if ($legacy) { $Mode = 'Full' }
$report = [ordered]@{
    Environment = 'NOT VERIFIED'
    Health = 'NOT VERIFIED'
    Prerequisites = 'SKIPPED'
    Restore = 'SKIPPED'
    CopilotInstall = 'SKIPPED'
    Extensions = 'SKIPPED'
    Runtime = 'NOT VERIFIED'
}
$phase = 'Environment'
$failed = $false
$runWindows = $null

function Invoke-Wsl {
    param([string[]]$LinuxArguments, [int[]]$AllowedExitCodes = @(0))
    & $wsl --distribution $Distro --user $linuxAccount --exec @LinuxArguments
    if ($LASTEXITCODE -notin $AllowedExitCodes) {
        throw "WSL command failed with exit code $LASTEXITCODE. Stop; do not assume recovery completed."
    }
}

function Test-WslDirectory {
    param([string]$Account, [string]$Path)
    & $wsl --distribution $Distro --user $Account --exec test -d $Path
    if ($LASTEXITCODE -gt 1) { throw "Cannot inspect WSL directory for $Account." }
    return $LASTEXITCODE -eq 0
}

function Update-Health {
    Invoke-Wsl -LinuxArguments @('bash', $linuxScript, 'health', $run) -AllowedExitCodes @(0, 3)
    if ($LASTEXITCODE -eq 0) { $report.Health = 'PASS' }
    else { $report.Health = 'NOT VERIFIED' }
}

function Test-RestoreFiles {
    Invoke-Wsl -LinuxArguments @('bash', $linuxScript, 'verify', $run)
    foreach ($file in @($plan.files | Where-Object { $_.windows })) {
        $target = (Invoke-Wsl -LinuxArguments @('wslpath', '-w', $file.target) | Out-String).Trim()
        if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $file.sha256) {
            throw "Windows-side SHA-256 verification failed: $target"
        }
    }
}

try {
    if ($env:OS -ne 'Windows_NT') {
        throw 'Run this launcher in Windows PowerShell, not inside WSL.'
    }
    $wsl = (Get-Command wsl.exe -ErrorAction Stop).Source
    $scriptPath = Join-Path $PSScriptRoot 'restore.sh'
    $helperPath = Join-Path $PSScriptRoot 'restore_files.py'
    foreach ($file in @($scriptPath, $helperPath)) {
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
            throw "Missing restore component: $file"
        }
    }

    $linuxAccount = 'root'
    if (-not $legacy) {
        $linuxAccount = (& $wsl --distribution $Distro --exec id -un | Out-String).Trim()
        if ($LASTEXITCODE -ne 0 -or $linuxAccount -notmatch '^[a-z_][a-z0-9_-]*\$?$') {
            throw 'Cannot determine the default WSL user.'
        }
        if ($linuxAccount -ne 'root') {
            $defaultHome = ((Invoke-Wsl -LinuxArguments @('getent', 'passwd', $linuxAccount) | Out-String).Trim() -split ':')[5]
            if (-not $defaultHome.StartsWith('/')) { throw 'Cannot determine the default WSL home.' }
            $defaultExists = Test-WslDirectory -Account $linuxAccount -Path "$defaultHome/.copilot"
            $rootExists = Test-WslDirectory -Account 'root' -Path '/root/.copilot'
            if ($rootExists -and -not $defaultExists) {
                $linuxAccount = 'root'
                Write-Host 'Existing Copilot configuration found for root, not the default user; selecting root.'
            } elseif ($rootExists -and $defaultExists) {
                $selection = Read-Host "Both root and $linuxAccount have Copilot configuration. Type ROOT or DEFAULT to select the target"
                if ($selection -ceq 'ROOT') { $linuxAccount = 'root' }
                elseif ($selection -cne 'DEFAULT') { throw 'Target selection cancelled.' }
            }
        }
    }
    $accountRecord = (Invoke-Wsl -LinuxArguments @('getent', 'passwd', $linuxAccount) | Out-String).Trim() -split ':'
    if ($accountRecord.Count -lt 7 -or -not $accountRecord[5].StartsWith('/')) {
        throw "Cannot determine home directory for WSL user $linuxAccount."
    }
    $linuxHome = $accountRecord[5].TrimEnd('/')
    if ([string]::IsNullOrWhiteSpace($linuxHome)) { throw 'WSL home cannot be the filesystem root.' }
    $actualHome = (Invoke-Wsl -LinuxArguments @('printenv', 'HOME') | Out-String).Trim().TrimEnd('/')
    if ($actualHome -ne $linuxHome) { throw 'WSL HOME does not match the selected account home; resolve it before recovery.' }
    $linuxScript = (Invoke-Wsl -LinuxArguments @('wslpath', '-a', '-u', $scriptPath) | Out-String).Trim()
    $run = $linuxHome + '/copilot-restore-' + [Guid]::NewGuid().ToString('N')
    $runWindows = (Invoke-Wsl -LinuxArguments @('wslpath', '-w', $run) | Out-String).Trim()
    Write-Host "Mode: $Mode. WSL target: $Distro, user $linuxAccount, home $linuxHome."
    Write-Host 'Identities are separate: backup noknok79; Copilot CLI dbg-mark-villanueva; corporate mark-a-b-villanueva_accent.'
    Write-Host 'Credentials, SSH private keys, authentication sessions, and employer-confidential data must not be restored.'
    Write-Host 'Source scanning cannot prove content is safe; review provenance and all proposed files.'
    $windowsReady = $true
    if (Get-Command $CodeCommand -ErrorAction SilentlyContinue) {
        Write-Host "PASS: Windows VS Code command $CodeCommand available."
    } else {
        Write-Host "NOT VERIFIED: Windows VS Code command $CodeCommand unavailable."
        $windowsReady = $false
    }
    if ($env:APPDATA -and (Test-Path -LiteralPath (Join-Path $env:APPDATA 'Code\User') -PathType Container)) {
        Write-Host 'PASS: Windows VS Code default-profile directory exists.'
    } else {
        Write-Host 'NOT VERIFIED: Windows VS Code default-profile directory unavailable.'
        $windowsReady = $false
    }
    Invoke-Wsl -LinuxArguments @('bash', $linuxScript, 'audit', $run) -AllowedExitCodes @(0, 3)
    if ($LASTEXITCODE -eq 0 -and $windowsReady) { $report.Environment = 'PASS' }

    $phase = 'Health'
    Update-Health

    if ($Mode -in @('Restore', 'Full')) {
        $phase = 'Restore'
        $code = (Get-Command $CodeCommand -ErrorAction Stop).Source
        $windowsUser = Join-Path $env:APPDATA 'Code\User'
        if (-not (Test-Path -LiteralPath $windowsUser -PathType Container)) {
            throw "VS Code stable User directory not found: $windowsUser. Install/open VS Code first."
        }
        if (@(Get-Process -Name Code -ErrorAction SilentlyContinue).Count -gt 0) {
            throw 'Close all VS Code windows and Copilot CLI sessions. Launch from a standalone PowerShell window.'
        }
        $linuxUser = (Invoke-Wsl -LinuxArguments @('wslpath', '-a', '-u', $windowsUser) | Out-String).Trim()
    }

    if ($Mode -ne 'Audit') {
        $phase = 'Prerequisites'
        Invoke-Wsl -LinuxArguments @('bash', $linuxScript, 'install-prerequisites', $run)
        $report.Prerequisites = 'PASS'
    }

    if ($Mode -in @('Restore', 'Full')) {
        $phase = 'Restore'
        Write-Host "Windows VS Code default profile: $windowsUser"
        Write-Host 'Prerequisites: approved personal backup, working github-noknok79 SSH alias and trusted GitHub host key.'
        Write-Host 'Keep VS Code and Copilot closed; pause Settings Sync. Review provenance/history before approving files.'
        if ((Read-Host 'Type PREPARE to clone and validate the backup') -cne 'PREPARE') {
            throw 'Cancelled before preparation.'
        }
        $prepare = @('bash', $linuxScript, 'prepare', $run, $linuxUser)
        if ($RestoreCliSettings) { $prepare += '--cli-settings' }
        Invoke-Wsl -LinuxArguments $prepare
        $planPath = "$run/plan.json"
        $planHash = (Invoke-Wsl -LinuxArguments @('sha256sum', $planPath) | Out-String).Trim().Split(' ')[0]
        $plan = (Invoke-Wsl -LinuxArguments @('cat', $planPath) | Out-String) | ConvertFrom-Json
        Write-Host "Prepared commit: $($plan.commit)"
        Write-Host "Review source: $(Join-Path $runWindows 'source')"
        Write-Host "Review plan: wsl --distribution $Distro --user $linuxAccount --exec cat $planPath"
        $plan.files | Select-Object source, target, sha256 | Format-Table -AutoSize | Out-Host
        Write-Host 'Read the full plan and source, including MCP commands, hooks and machine-specific settings.'
        Write-Host 'Do not approve confidential or secret files. Verify paths are suitable for this machine.'
        if ((Read-Host 'Type RESTORE to approve replacements and create rollback backups') -cne 'RESTORE') {
            throw "Cancelled; configuration unchanged. Inspection files remain in $runWindows"
        }
        if ((Invoke-Wsl -LinuxArguments @('sha256sum', $planPath) | Out-String).Trim().Split(' ')[0] -ne $planHash) {
            throw 'Restore plan changed after preparation. Start a new run.'
        }
        if (@(Get-Process -Name Code -ErrorAction SilentlyContinue).Count -gt 0) {
            throw 'VS Code was opened during review. Close it before starting a new run.'
        }
        Invoke-Wsl -LinuxArguments @('bash', $linuxScript, 'apply', $run)
        Test-RestoreFiles
        $report.Restore = 'PASS'
        Write-Host "FILE RESTORE VERIFIED. Report and rollback inventory: $runWindows"
        $phase = 'Health'
        Update-Health
    }

    if ($Mode -in @('Install', 'Full')) {
        $phase = 'CopilotInstall'
        Write-Host 'If missing, Copilot CLI can be installed from the official GitHub installer after approval.'
        Invoke-Wsl -LinuxArguments @('bash', $linuxScript, 'install-cli', $run) -AllowedExitCodes @(0, 3)
        if ($LASTEXITCODE -eq 0) { $report.CopilotInstall = 'PASS' }
        else { Write-Warning 'Copilot CLI installation deferred.' }
    }

    if ($Mode -eq 'Full') {
        $phase = 'Extensions'
        $approved = @()
        if (@($plan.extensions).Count -gt 0) {
            Write-Host ('Backup extension inventory: ' + ($plan.extensions -join ', '))
            Write-Host 'This inventory has no scope metadata. Only Windows Local extensions can be installed here.'
            $selection = Read-Host 'Enter approved LOCAL IDs separated by commas; Enter defers extension restoration'
            if (-not [string]::IsNullOrWhiteSpace($selection)) {
                $approved = @($selection.Split(',') | ForEach-Object { $_.Trim().ToLowerInvariant() } | Select-Object -Unique)
                foreach ($id in $approved) {
                    if ($id -notmatch '^[a-z0-9][a-z0-9-]*\.[a-z0-9][a-z0-9._-]*$' -or $id -notin $plan.extensions) {
                        throw "Not an approved inventory ID: $id"
                    }
                }
            }
        }
        foreach ($id in $approved) {
            & $code --install-extension $id
            if ($LASTEXITCODE -ne 0) { throw "Extension installation failed: $id. Config backup remains in $runWindows" }
            $installed = @(& $code --list-extensions)
            if ($LASTEXITCODE -ne 0 -or $id -notin $installed) { throw "Extension verification failed: $id" }
        }
        Invoke-Wsl -LinuxArguments (@('bash', $linuxScript, 'extensions-status', $run) + $approved)
        if ($approved.Count -gt 0) { $report.Extensions = 'PASS' }
        $phase = 'Restore'
        Test-RestoreFiles
    }
} catch {
    $report[$phase] = 'FAIL'
    $failed = $true
    Write-Host "FAIL: $($_.Exception.Message)"
} finally {
    Write-Host "`nRECOVERY REPORT"
    foreach ($entry in $report.GetEnumerator()) { Write-Host "$($entry.Key): $($entry.Value)" }
    Write-Host 'NOT VERIFIED: Copilot account/subscription, corporate access, MCP, hooks, VS Code/WSL runtime, and second-machine recovery.'
    if ($runWindows) {
        Write-Host "Run location, if created: $runWindows. Preserve rollback inventory; rollback does not uninstall software or extensions."
    }
}
if ($failed) { exit 1 }
