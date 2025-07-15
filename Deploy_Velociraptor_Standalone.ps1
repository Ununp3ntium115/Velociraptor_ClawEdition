#
# .SYNOPSIS
#     Interactive installer for a **stand-alone Velociraptor client / offline collector**.
#
# .DESCRIPTION
#     Guides an administrator through:
#       1. Choosing (and optionally downloading) a Velociraptor Windows release.
#       2. Selecting install & data directories (defaults to C:\tools and C:\VelociraptorData).
#       3. Generating a minimal client configuration (vr.yaml) suitable for local GUI use.
#       4. Launching Velociraptor in **stand-alone GUI** mode.
#
#     No service is installed and no connectivity to a Velociraptor server is required.
#
# .NOTES
#     ▸ Requires PowerShell 7.5+ and Internet access if you choose to download.
#     ▸ Run *as Administrator* so the data directory can be created under C:\.
#     ▸ Logs a transcript to $Env:ProgramData\VelociraptorDeploy\deploy.log.
#     ▸ You can re-run the script to update Velociraptor by selecting a newer version.
#
# .EXAMPLE
#     PS> .\Deploy_Velociraptor_Standalone.ps1
#
[CmdletBinding()]
param()

function Test-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        throw "This script must be run from an elevated PowerShell session.";
    }
}

function Write-Log {
    param([string]$Message)
    $logDir = Join-Path $Env:ProgramData 'VelociraptorDeploy'
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $logFile = Join-Path $logDir 'deploy.log'
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    "$ts`t$Message" | Out-File -FilePath $logFile -Encoding utf8 -Append
    Write-Host $Message
}

function Prompt-Path {
    param(
        [string]$Prompt,
        [string]$Default
    )
    $resp = Read-Host "$Prompt [$Default]"
    if ([string]::IsNullOrWhiteSpace($resp)) { return $Default }
    return $resp
}

function Get-LatestReleaseTag {
    Write-Log 'Querying GitHub for latest Velociraptor release…'
    try {
        $api = 'https://api.github.com/repos/Velocidex/velociraptor/releases/latest'
        $json = Invoke-RestMethod -Uri $api -Headers @{ 'User-Agent' = 'PS1' }
        return $json.tag_name.TrimStart('v')
    } catch {
        Write-Warning "Could not retrieve latest version automatically: $_"
        return $null
    }
}

function Download-Release {
    param(
        [string]$Version,
        [string]$DestinationDir
    )
    $fileName = "velociraptor-v$Version-windows-amd64.exe"
    $url = "https://github.com/Velocidex/velociraptor/releases/download/v$Version/$fileName"
    $destPath = Join-Path $DestinationDir 'velociraptor.exe'

    Write-Log "Downloading $url …"
    try {
        if (-not (Test-Path $DestinationDir)) { New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null }
        Invoke-WebRequest -Uri $url -OutFile $destPath -UseBasicParsing
        Write-Log "Downloaded to $destPath"
    } catch {
        throw "Failed to download Velociraptor ${Version}: $_"
    }

    return $destPath
}

function Generate-Config {
    param(
        [string]$ExePath,
        [string]$ConfigPath,
        [string]$DataRoot
    )
    Write-Log "Generating client configuration…"
    & $ExePath config generate -f $ConfigPath -- --client.mode=client --client.disablesigning=true --server.datastore_path=$DataRoot 2>&1 | Out-Null
    Write-Log "Config written to $ConfigPath"
}

Test-Admin

Write-Log '==== Velociraptor Stand-alone Client Deployment Started ===='

# 1. Choose binary
$defaultInstall = 'C:\tools'
$binPath = Prompt-Path 'Enter Velociraptor install directory' $defaultInstall
$binPath = Resolve-Path -Path $binPath | Select-Object -ExpandProperty Path

$exePath = Join-Path $binPath 'velociraptor.exe'
if (-not (Test-Path $exePath)) {
    $latest = Get-LatestReleaseTag
    $verPrompt = if ($latest) { "Enter version to download [$latest]" } else { 'Enter version to download (e.g., 0.7.2)' }
    $chosenVer = Read-Host $verPrompt
    if ([string]::IsNullOrWhiteSpace($chosenVer)) { $chosenVer = $latest }
    $exePath = Download-Release -Version $chosenVer -DestinationDir $binPath
} else {
    Write-Log "Using existing binary at $exePath"
}

# 2. Choose data directory
$defaultData = 'C:\VelociraptorData'
$dataRootPrompt = Prompt-Path 'Enter Velociraptor data directory' $defaultData
$dataRoot = Resolve-Path -LiteralPath $dataRootPrompt -ErrorAction SilentlyContinue
if (-not $dataRoot) {
    New-Item -ItemType Directory -Path $dataRootPrompt -Force | Out-Null
    $dataRoot = $dataRootPrompt
}

# 3. Generate configuration
$cfgPath = Join-Path $binPath 'vr.yaml'
if (-not (Test-Path $cfgPath)) {
    Generate-Config -ExePath $exePath -ConfigPath $cfgPath -DataRoot $dataRoot
} else {
    Write-Log "Config already exists at $cfgPath – skipping generation"
}

# 4. Launch GUI?
$launch = Read-Host 'Launch Velociraptor GUI now? (y/N)'
if ($launch -match '^[Yy]') {
    Write-Log 'Launching Velociraptor GUI (instant mode)…'
    # NOTE: Using plain `gui` without --config – Velociraptor will create its
    # own temporary server & client configs and listen on 127.0.0.1:8889.
    $p = Start-Process -FilePath $exePath -ArgumentList 'gui -v' -WorkingDirectory $binPath -PassThru
    # Give the binary a few seconds to start and then check if it is still alive.
    Start-Sleep -Seconds 3
    if ($p.HasExited) {
        Write-Warning 'Velociraptor exited unexpectedly – run it manually in the console to see errors:'
        Write-Host "`n   $exePath gui -v`n"
    } else {
        Write-Log 'Velociraptor GUI running. Navigate to http://127.0.0.1:8889 (user: admin / password)'
    }
} else {
    Write-Log 'You can start the GUI later with:'
    Write-Host "`n   $exePath gui -v`n"
}

Write-Log '==== Deployment finished ===='

