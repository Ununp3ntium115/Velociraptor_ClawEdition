<#
.SYNOPSIS
    Fully removes **any** Velociraptor deployment from a Windows host – now
    including offline‑collector artefacts placed under **C:\tools** and the
    legacy **vrserver** service. Combines the breadth of the original
    Cleanup_Velociraptor.ps1 with the specific paths and confirmation logic
    from cleanup_velo.ps1.

.DESCRIPTION
    • Stops and deletes all Velociraptor services (names starting with
      "Velociraptor" **or exactly "vrserver"**).
    • Terminates remaining Velociraptor processes.
    • Removes scheduled tasks whose names contain "Velociraptor" or the
      specific **Velociraptor_Audit_Runner** task used by some offline packs.
    • Deletes Velociraptor firewall rules, registry keys, event log, and both
      standard and offline‑deploy file locations:

        ├─ %ProgramFiles%\Velociraptor
        ├─ %ProgramData%\Velociraptor
        ├─ C:\tools\vr.yaml
        ├─ C:\tools\artifact_pack
        ├─ C:\tools\toolcache_tmp
        └─ C:\VelociraptorData

      plus anything supplied via **‑AdditionalPaths**.

.PARAMETER Force
    Skip the confirmation prompt and proceed immediately.

.PARAMETER AdditionalPaths
    Extra files or directories to purge (array).

.PARAMETER SkipFirewallRuleRemoval / SkipEventLogClear
    Opt‑out of those steps if required.

.PARAMETER WhatIf
    Built‑in PowerShell switch – shows what *would* happen without making
    changes (thanks to [CmdletBinding(SupportsShouldProcess)]).

.NOTES
    ▸ Requires PowerShell 7.5+ – run *as Administrator*.
    ▸ Logs every action to %ProgramData%\VelociraptorCleanup\cleanup.log.
    ▸ A reboot is recommended after completion.

.LINK
    Velociraptor Admin.Client.Uninstall artifact – docs.velociraptor.app
    Manual uninstall gist – gist.github.com/scudette/44540483c9fcf577507434259735e891
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string[]]$AdditionalPaths = @(),
    [switch]$SkipFirewallRuleRemoval,
    [switch]$SkipEventLogClear,
    [switch]$Force
)

function Test-AdminPrivileges {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        throw "This script must be run from an elevated PowerShell session.";
    }
}

# Backward compatibility alias
Set-Alias -Name Test-Admin -Value Test-AdminPrivileges

function Write-Log {
    param ([string]$Message)
    $logDir = Join-Path $Env:ProgramData 'VelociraptorCleanup'
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $logFile = Join-Path $logDir 'cleanup.log'
    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    "$timestamp `t $Message" | Out-File -FilePath $logFile -Encoding utf8 -Append
    Write-Host $Message
}

function Confirm-Action {
    param([switch]$Force)
    if ($Force) { return }
    $resp = Read-Host "!!! This will DELETE all Velociraptor data & configuration – continue? (y/N)"
    if ($resp -notmatch '^[Yy]') {
        Write-Log 'Operation cancelled by user.'
        exit
    }
}

Test-AdminPrivileges
$ErrorActionPreference = 'Stop'

Write-Log "Starting Velociraptor cleanup…"
Confirm-Action -Force:$Force

# ───────────── 1. Stop & Remove Services ─────────────
$services = Get-Service -ErrorAction SilentlyContinue
$serviceNames = @()
if ($services) {
    $serviceNames = $services | 
        Where-Object { $_ -and $_.Name -and ($_.Name -match '^Velociraptor' -or $_.Name -eq 'vrserver') } |
        Select-Object -ExpandProperty Name -Unique
}

foreach ($svc in $serviceNames) {
    try {
        $svcObj = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($svcObj -and $svcObj.Status -ne 'Stopped') {
            Write-Log "Stopping service: $svc"
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        }
        Write-Log "Deleting service: $svc"
        sc.exe delete $svc | Out-Null
    } catch {
        Write-Log "Failed to handle service $svc : $_"
    }
}

# ───────────── 2. Kill Residual Processes ─────────────
$processes = Get-Process -ErrorAction SilentlyContinue
$procs = @()
if ($processes) {
    $procs = $processes | Where-Object { $_ -and $_.Name -and $_.Name -match 'velociraptor' }
}
foreach ($p in $procs) {
    if ($p -and $p.Name -and $p.Id) {
        Write-Log "Killing process $($p.Name) (PID=$($p.Id))"
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
    }
}

# ───────────── 3. Remove Scheduled Tasks ─────────────
$allTasks = Get-ScheduledTask -ErrorAction SilentlyContinue
$tasks = @()
if ($allTasks) {
    $tasks = $allTasks | Where-Object { $_ -and $_.TaskName -and ($_.TaskName -match 'Velociraptor' -or $_.TaskName -eq 'Velociraptor_Audit_Runner') }
}
foreach ($t in $tasks) {
    if ($t -and $t.TaskName) {
        Write-Log "Removing scheduled task: $($t.TaskName)"
        Unregister-ScheduledTask -TaskName $t.TaskName -Confirm:$false
    }
}

# ───────────── 4. Remove Firewall Rules ─────────────
if (-not $SkipFirewallRuleRemoval) {
    $fwRules = Get-NetFirewallRule -PolicyStore ActiveStore -DisplayName "Velociraptor*" -ErrorAction SilentlyContinue
    foreach ($r in $fwRules) {
        Write-Log "Deleting firewall rule: $($r.DisplayName)"
        Remove-NetFirewallRule -Name $r.Name -Confirm:$false
    }
}

# ───────────── 5. Remove Registry Keys ─────────────
$regPaths = @(
    'HKLM:\SYSTEM\CurrentControlSet\Services\Velociraptor',
    'HKLM:\SYSTEM\CurrentControlSet\Services\vrserver',
    'HKLM:\SOFTWARE\Velociraptor',
    'HKLM:\SOFTWARE\WOW6432Node\Velociraptor'
)
foreach ($reg in $regPaths) {
    if (Test-Path $reg) {
        Write-Log "Removing registry key: $reg"
        Remove-Item -Path $reg -Recurse -Force
    }
}

# ───────────── 6. Remove Files & Directories ─────────────
$paths = @(
    "$Env:ProgramFiles\Velociraptor",
    "$Env:ProgramData\Velociraptor",
    'C:\tools\vr.yaml',
    'C:\tools\artifact_pack',
    'C:\tools\toolcache_tmp',
    'C:\VelociraptorData',
    "$Env:ProgramData\VelociraptorCleanup"  # remove our own log dir last
) + $AdditionalPaths

foreach ($p in $paths) {
    if (Test-Path $p) {
        Write-Log "Deleting $p"
        Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ───────────── 7. Clear Event Log ─────────────
if (-not $SkipEventLogClear) {
    if (Get-WinEvent -ListLog Velociraptor -ErrorAction SilentlyContinue) {
        Write-Log "Clearing Velociraptor event log"
        wevtutil cl Velociraptor
    }
}

Write-Log "Velociraptor cleanup completed successfully. A reboot is recommended."
