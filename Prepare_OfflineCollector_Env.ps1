#
# NOTE: This script builds a self-contained offline Velociraptor collector environment.
# Refer to the comment block at the top of the script for detailed usage.
#
<#
.SYNOPSIS
    Build a fully self-contained offline Velociraptor collector environment.

.DESCRIPTION
    • Downloads Velociraptor binaries (Win/Linux/macOS) for a given or latest release.
    • Downloads & extracts the official artifact_pack (all built-in artifact YAMLs).
    • Scans those YAMLs for any external tool URLs (ChopChopGo, KnockKnock, CYLR, UAC, c_gimphash_windows.exe), downloads & unpacks them.
    • Writes a CSV manifest of all external tools.
    • Copies this script into the workspace root.
    • Compresses everything into offline_builder_v<version>.zip, placing the archive alongside the version folder.

.PARAMETER Version
    Tag to use (e.g. "0.74.1"); omit to auto-detect the latest release.

.EXAMPLE
    # Auto-detect latest
    PS C:\tools> .\Prepare_OfflineCollector_Env.ps1

    # Pin to v0.74.1
    PS C:\tools> .\Prepare_OfflineCollector_Env.ps1 -Version '0.74.1'
#>

param(
    [string]$Version
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$m)
    Write-Host "[$(Get-Date -Format u)] $m"
}

# Backward compatibility alias
Set-Alias -Name Log -Value Write-Log

# --- 1) Fetch release metadata -----------------------------------
Write-Log 'Fetching Velociraptor release info...'
if ($Version) {
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/Velocidex/velociraptor/releases/tags/v$Version" `
    -Headers @{ 'User-Agent' = 'OfflinePrepScript' }
} else {
    $rel = Invoke-RestMethod -Uri 'https://api.github.com/repos/Velocidex/velociraptor/releases/latest' `
    -Headers @{ 'User-Agent' = 'OfflinePrepScript' }
}
$tag = $rel.tag_name.TrimStart('v')
Write-Log "Using release v$tag"

# --- 2) Prepare workspace ---------------------------------
$Root    = "C:\tools\offline_builder\v$tag"
$BinsDir = Join-Path $Root 'binaries'
$ArtDir  = Join-Path $Root 'artifact_definitions'
$ExtDir  = Join-Path $Root 'external_tools'
New-Item -Path $BinsDir,$ArtDir,$ExtDir -ItemType Directory -Force | Out-Null
Write-Log "Workspace created at $Root"

# --- 3) Download Velociraptor binaries -----------------
$assetMap = @{
    'windows-amd64' = @{ Pattern='windows-amd64\.exe$'; Output='velociraptor.exe' }
    'linux-amd64'   = @{ Pattern='linux-amd64$';        Output='velociraptor'     }
    'darwin-amd64'  = @{ Pattern='darwin-amd64$';       Output='velociraptor'     }
}
if (-not $rel -or -not $rel.assets) {
    Log "ERROR: Failed to retrieve release information from GitHub API"
    exit 1
}

foreach ($key in $assetMap.Keys) {
    $info  = $assetMap[$key]
    if (-not $info -or -not $info.Pattern) {
        Log "WARNING: Invalid asset info for $key"
        continue
    }
    
    $asset = $rel.assets | Where-Object { $_.name -match $info.Pattern } | Select-Object -First 1
    if (-not $asset) {
        Log "WARNING: no $key asset in v$tag"
        continue
    }
    
    if (-not $asset.browser_download_url -or -not $asset.name) {
        Log "WARNING: Asset information incomplete for $key"
        continue
    }
    
    $dest = Join-Path $BinsDir $info.Output
    Log "Downloading $($asset.name)..."
    Invoke-WebRequest -Uri $asset.browser_download_url `
                    -OutFile "$dest.download" -UseBasicParsing `
                    -Headers @{ 'User-Agent'='OfflinePrepScript' }
    Move-Item "$dest.download" $dest -Force
    if ($key -ne 'windows-amd64') {
        icacls $dest /grant '*S-1-1-0:RX' | Out-Null
    }
    Log "Saved -> $dest"
}

# --- 4) Download & extract artifact_pack.zip --------------
$zipPath = Join-Path $Root 'artifact_pack.zip'

# Check for local artifact pack first
$localArtifactPack = Join-Path $PSScriptRoot 'artifact_pack.zip'
if (Test-Path $localArtifactPack) {
    Log "Using local artifact_pack.zip from script directory"
    Copy-Item $localArtifactPack $zipPath -Force
    Log "Extracting YAMLs -> $ArtDir"
    Expand-Archive -Path $zipPath -DestinationPath $ArtDir -Force
} else {
    # Fall back to downloading from GitHub release assets
    $artifactZip = $null
    if ($rel.assets) {
        $artifactZip = $rel.assets |
            Where-Object { $_ -and $_.name -and $_.name -match '^artifact_pack.*\.zip$' } |
            Select-Object -First 1
    }
    if ($artifactZip -and $artifactZip.browser_download_url) {
        Log "Downloading $($artifactZip.name)..."
        Invoke-WebRequest -Uri $artifactZip.browser_download_url `
                    -OutFile "$zipPath.download" -UseBasicParsing `
                    -Headers @{ 'User-Agent'='OfflinePrepScript' }
        Move-Item "$zipPath.download" $zipPath -Force
        Log "Extracting YAMLs -> $ArtDir"
        Expand-Archive -Path $zipPath -DestinationPath $ArtDir -Force
    } else {
        Log 'WARNING: artifact_pack.zip not found in assets or local directory.'
        Log 'INFO: Will use enhanced artifact scanning from content/exchange/artifacts if available.'
        
        # Enhanced fallback: Use our improved artifact discovery
        $exchangeArtifacts = Join-Path $PSScriptRoot 'content\exchange\artifacts'
        if (Test-Path $exchangeArtifacts) {
            Log "Using enhanced artifact discovery from $exchangeArtifacts"
            # Copy artifacts from our enhanced collection
            if (-not (Test-Path $ArtDir)) {
                New-Item -ItemType Directory -Path $ArtDir -Force | Out-Null
            }
            Get-ChildItem $exchangeArtifacts -Filter '*.yaml' | ForEach-Object {
                Copy-Item $_.FullName $ArtDir -Force
            }
            Log "Copied $((Get-ChildItem $ArtDir -Filter '*.yaml').Count) artifact files"
        }
    }
}

# --- 5) Scan & download external tools --------------------
Log 'Scanning artifact YAMLs for external tools...'
$tools = @()
Get-ChildItem -Path $ArtDir -Recurse -Filter '*.yaml' | ForEach-Object {
    $name = $null
    Get-Content $_.FullName | ForEach-Object {
        if ($_ -match '^\s*-\s*name:\s*(\S+)') { $name = $matches[1] }
        elseif ($_ -match '^\s*url:\s*(\S+)')  {
            $tools += [pscustomobject]@{ Artifact=$name; Url=$matches[1] }
        }
    }
}
$tools = $tools | Sort-Object Url -Unique

$manifest = foreach ($t in $tools) {
    $file = Split-Path $t.Url -Leaf
    $dest = Join-Path $ExtDir $file
    Log "Downloading [$($t.Artifact)] -> $file"
    Invoke-WebRequest -Uri $t.Url -OutFile "$dest.download" -UseBasicParsing `
                    -Headers @{ 'User-Agent'='OfflinePrepScript' }
    Move-Item "$dest.download" $dest -Force

    $extracted = ''
    if ($file -match '\.zip$') {
        $out = Join-Path $ExtDir $t.Artifact
        Log "Extracting $file -> $out"
        Expand-Archive -Path $dest -DestinationPath $out -Force
        $extracted = $out
    }

    [pscustomobject]@{
        Artifact    = $t.Artifact
        Url         = $t.Url
        FileName    = $file
        ExtractedTo = $extracted
    }
}

# --- 6) Write CSV manifest -------------------------
$manifest | Export-Csv -Path (Join-Path $Root 'external_tools_manifest.csv') `
    -NoTypeInformation -Encoding UTF8
Log 'External tools manifest written.'

# --- 7) Copy this script into the workspace ------------
Copy-Item $MyInvocation.MyCommand.Path `
    -Destination (Join-Path $Root (Split-Path $MyInvocation.MyCommand.Path -Leaf)) `
    -Force
Log 'Script included in workspace.'

# --- 8) Zip up the entire workspace ---------------
$zipName   = "offline_builder_v${tag}.zip"
$ArchiveDir = Split-Path $Root -Parent
$zipPath   = Join-Path $ArchiveDir $zipName
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Log "Creating archive $zipName in $ArchiveDir... (this may take a moment)"
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($Root, $zipPath)
Log "Archive created -> $zipPath"

# --- done ----------------------------------------
Log "`n✔ Offline build environment ready!"
Log "  Folder : $Root"
Log "  Archive: $zipPath"