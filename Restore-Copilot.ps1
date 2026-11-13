#requires -Version 5.1
[CmdletBinding()]
param(
    [ValidatePattern('^[A-Za-z0-9._-]+$')]
    [string]$Distro = 'Ubuntu',
    [string]$CodeCommand = 'code.cmd',
    [switch]$RestoreCliSettings
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') {
    throw 'Run this launcher in Windows PowerShell, not inside WSL.'
}
$wsl = (Get-Command wsl.exe -ErrorAction Stop).Source
$code = (Get-Command $CodeCommand -ErrorAction Stop).Source
$windowsUser = Join-Path $env:APPDATA 'Code\User'
if (-not (Test-Path -LiteralPath $windowsUser -PathType Container)) {
    throw "VS Code stable User directory not found: $windowsUser. Install/open VS Code first."
}
if (@(Get-Process -Name Code -ErrorAction SilentlyContinue).Count -gt 0) {
    throw 'Close all VS Code windows and Copilot CLI sessions. Launch from a standalone PowerShell window.'
}

function Invoke-Wsl {
    param([string[]]$LinuxArguments)
    & $wsl --distribution $Distro --user root --exec @LinuxArguments
    if ($LASTEXITCODE -ne 0) {
        throw "WSL command failed with exit code $LASTEXITCODE. Stop; do not assume restoration completed."
    }
}

$scriptPath = Join-Path $PSScriptRoot 'restore.sh'
$helperPath = Join-Path $PSScriptRoot 'restore_files.py'
foreach ($file in @($scriptPath, $helperPath)) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "Missing restore component: $file"
    }
}
$linuxScript = (Invoke-Wsl -LinuxArguments @('wslpath', '-a', '-u', $scriptPath) | Out-String).Trim()
$linuxUser = (Invoke-Wsl -LinuxArguments @('wslpath', '-a', '-u', $windowsUser) | Out-String).Trim()
$run = '/root/copilot-restore-' + [Guid]::NewGuid().ToString('N')
$runWindows = (Invoke-Wsl -LinuxArguments @('wslpath', '-w', $run) | Out-String).Trim()

Write-Host "Target: Windows VS Code default profile ($windowsUser), WSL $Distro as root"
Write-Host 'Prerequisites: approved personal backup, working github-noknok79 SSH alias and trusted GitHub host key.'
Write-Host 'No SSH keys, tokens, credentials, shell profiles or managed policies will be restored.'
Write-Host 'Missing Ubuntu packages may be installed. Existing packages and Copilot CLI will not be upgraded.'
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
Write-Host "Review plan as WSL root: $planPath"
Write-Host "Read with: wsl --distribution $Distro --user root --exec cat $planPath"
$plan.files | Select-Object source, target, sha256 | Format-Table -AutoSize | Out-Host
Write-Host 'Read the full plan/source files, including MCP commands, hooks and machine-specific settings.'
Write-Host 'Keep root-specific paths unchanged only when valid on this machine. Do not approve confidential/secret files.'
if ((Read-Host 'Type RESTORE to confirm approval, back up destinations and replace these files') -cne 'RESTORE') {
    throw "Cancelled; configuration unchanged. Inspection files remain in $runWindows"
}
if ((Invoke-Wsl -LinuxArguments @('sha256sum', $planPath) | Out-String).Trim().Split(' ')[0] -ne $planHash) {
    throw 'Restore plan changed after preparation. Start a new run.'
}
if (@(Get-Process -Name Code -ErrorAction SilentlyContinue).Count -gt 0) {
    throw 'VS Code was opened during review. Close it before starting a new run.'
}
Invoke-Wsl -LinuxArguments @('bash', $linuxScript, 'apply', $run)

Write-Host 'Optional Copilot install uses the official https://gh.io/copilot-install script if CLI is missing.'
if ((Read-Host 'Type INSTALL to install/check WSL Copilot CLI; Enter to defer') -ceq 'INSTALL') {
    Invoke-Wsl -LinuxArguments @('bash', $linuxScript, 'install-cli', $run)
} else {
    Write-Warning 'Copilot CLI installation/version check deferred; runtime sign-off is incomplete.'
}

$approved = @()
if (@($plan.extensions).Count -gt 0) {
    Write-Host ('Backup extension inventory: ' + ($plan.extensions -join ', '))
    Write-Host 'This inventory has no installation-scope metadata. Only Windows Local extensions are installed here.'
    $selection = Read-Host 'Enter approved LOCAL IDs separated by commas; Enter defers extension restoration'
    if (-not [string]::IsNullOrWhiteSpace($selection)) {
        $approved = @($selection.Split(',') | ForEach-Object { $_.Trim().ToLowerInvariant() } | Select-Object -Unique)
        foreach ($id in $approved) {
            if ($id -notmatch '^[a-z0-9][a-z0-9-]*\.[a-z0-9][a-z0-9._-]*$' -or $id -notin $plan.extensions) {
                throw "Not an approved inventory ID: $id"
            }
        }
    }
} else {
    Write-Warning 'No extension inventory in backup. Use the VS Code Extensions view to install approved extensions.'
}
foreach ($id in $approved) {
    & $code --install-extension $id
    if ($LASTEXITCODE -ne 0) { throw "Extension installation failed: $id. Config backup remains in $runWindows" }
    $installed = @(& $code --list-extensions)
    if ($LASTEXITCODE -ne 0 -or $id -notin $installed) { throw "Extension verification failed: $id" }
}
Invoke-Wsl -LinuxArguments (@('bash', $linuxScript, 'extensions-status', $run) + $approved)

Invoke-Wsl -LinuxArguments @('bash', $linuxScript, 'verify', $run)
foreach ($file in @($plan.files | Where-Object { $_.windows })) {
    $target = (Invoke-Wsl -LinuxArguments @('wslpath', '-w', $file.target) | Out-String).Trim()
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $file.sha256) {
        throw "Windows-side SHA-256 verification failed: $target"
    }
}
Write-Host "FILE RESTORE VERIFIED. Report and rollback inventory: $runWindows"
Write-Warning 'Runtime acceptance is still required: sign in to Copilot, connect VS Code to WSL, install WSL-scoped extensions from its Extensions view, and test skills/MCP/hooks.'
Write-Warning 'MCP and SSH identity do not prove which account supplies the Copilot subscription. Check the Copilot account separately.'
