<#
.SYNOPSIS
    Build a fully self-contained offline Velociraptor collector environment.

.DESCRIPTION
    • Downloads Velociraptor binaries (Win/Linux/macOS) for a given or latest release.
    • Downloads & extracts the official artifact_pack (all built-in artifact YAMLs).
    • Scans those YAMLs for any external tool URLs, downloads & unpacks them.
    • Writes a CSV manifest of all external tools.
    • Copies this script into the workspace root.
    • Compresses everything into offline_builder_v<version>.zip.

.PARAMETER Version
    Tag to use (e.g. "0.74.1"); omit to auto-detect the latest release.

.PARAMETER OutputPath
    Base directory for offline environment. Default: C:\tools\offline_builder

.PARAMETER SkipCompression
    Skip creating the final ZIP archive

.EXAMPLE
    # Auto-detect latest version
    .\Prepare_OfflineCollector_Env.ps1

    # Pin to specific version
    .\Prepare_OfflineCollector_Env.ps1 -Version '0.74.1'

    # Custom output location
    .\Prepare_OfflineCollector_Env.ps1 -OutputPath 'D:\VelociraptorOffline'
#>

[CmdletBinding()]
param(
    [string]$Version,
    [string]$OutputPath = 'C:\tools\offline_builder',
    [switch]$SkipCompression
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Write-OfflineLog {
    param([string]$Message, [string]$Level = 'Info')
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        default { 'White' }
    }
    
    Write-Host "[$timestamp] $Message" -ForegroundColor $color
}

try {
    Write-OfflineLog 'Starting offline Velociraptor environment preparation...' -Level 'Success'
    
    # ─── 1) Fetch release metadata ─────────────────────────────────
    Write-OfflineLog 'Fetching Velociraptor release information...'
    
    $headers = @{ 'User-Agent' = 'VelociraptorOfflineBuilder/2.0' }
    
    if ($Version) {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/Velocidex/velociraptor/releases/tags/v$Version" -Headers $headers -TimeoutSec 30
    } else {
        $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/Velocidex/velociraptor/releases/latest' -Headers $headers -TimeoutSec 30
    }
    
    $tag = $release.tag_name.TrimStart('v')
    Write-OfflineLog "Using release v$tag" -Level 'Success'

    # ─── 2) Prepare workspace ─────────────────────────
    $workspaceRoot = Join-Path $OutputPath "v$tag"
    $binariesDir = Join-Path $workspaceRoot 'binaries'
    $artifactsDir = Join-Path $workspaceRoot 'artifact_definitions'
    $toolsDir = Join-Path $workspaceRoot 'external_tools'
    $configDir = Join-Path $workspaceRoot 'configurations'
    
    foreach ($dir in @($binariesDir, $artifactsDir, $toolsDir, $configDir)) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
        }
    }
    
    Write-OfflineLog "Workspace created at $workspaceRoot" -Level 'Success'

    # ─── 3) Download Velociraptor binaries ─────────────────
    Write-OfflineLog 'Downloading Velociraptor binaries...'
    
    $platformMap = @{
        'windows-amd64' = @{ Pattern = 'windows-amd64\.exe$'; Output = 'velociraptor.exe'; Executable = $true }
        'linux-amd64'   = @{ Pattern = 'linux-amd64$';       Output = 'velociraptor';     Executable = $true }
        'darwin-amd64'  = @{ Pattern = 'darwin-amd64$';      Output = 'velociraptor';     Executable = $true }
    }
    
    $downloadedBinaries = @()
    
    foreach ($platform in $platformMap.Keys) {
        $info = $platformMap[$platform]
        $asset = $release.assets | Where-Object { $_.name -match $info.Pattern } | Select-Object -First 1
        
        if (-not $asset) {
            Write-OfflineLog "WARNING: No $platform asset found in v$tag" -Level 'Warning'
            continue
        }
        
        $platformDir = Join-Path $binariesDir $platform
        if (-not (Test-Path $platformDir)) {
            New-Item -Path $platformDir -ItemType Directory -Force | Out-Null
        }
        
        $destinationPath = Join-Path $platformDir $info.Output
        
        Write-OfflineLog "Downloading $($asset.name) ($([math]::Round($asset.size/1MB, 2)) MB)..."
        
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $destinationPath -UseBasicParsing -Headers $headers -TimeoutSec 300
        
        # Set executable permissions for non-Windows platforms
        if ($info.Executable -and $platform -ne 'windows-amd64') {
            # This would be handled differently in actual cross-platform deployment
            Write-OfflineLog "Binary saved: $destinationPath"
        } else {
            Write-OfflineLog "Binary saved: $destinationPath"
        }
        
        $downloadedBinaries += @{
            Platform = $platform
            Path = $destinationPath
            Size = (Get-Item $destinationPath).Length
        }
    }

    # ─── 4) Download & extract artifact pack ──────────────
    Write-OfflineLog 'Downloading artifact definitions...'
    
    $artifactAsset = $release.assets | Where-Object { $_.name -match '^artifact_pack.*\.zip$' } | Select-Object -First 1
    
    if ($artifactAsset) {
        $artifactZipPath = Join-Path $workspaceRoot 'artifact_pack.zip'
        
        Write-OfflineLog "Downloading $($artifactAsset.name)..."
        Invoke-WebRequest -Uri $artifactAsset.browser_download_url -OutFile $artifactZipPath -UseBasicParsing -Headers $headers -TimeoutSec 300
        
        Write-OfflineLog "Extracting artifact definitions..."
        Expand-Archive -Path $artifactZipPath -DestinationPath $artifactsDir -Force
        
        # Clean up zip file
        Remove-Item $artifactZipPath -Force
        
        $artifactCount = (Get-ChildItem -Path $artifactsDir -Recurse -Filter '*.yaml').Count
        Write-OfflineLog "Extracted $artifactCount artifact definitions" -Level 'Success'
    } else {
        Write-OfflineLog 'WARNING: artifact_pack.zip not found in release assets' -Level 'Warning'
    }

    # ─── 5) Scan & download external tools ──────────────────
    Write-OfflineLog 'Scanning artifacts for external tool dependencies...'
    
    $externalTools = @()
    $yamlFiles = Get-ChildItem -Path $artifactsDir -Recurse -Filter '*.yaml' -ErrorAction SilentlyContinue
    
    foreach ($yamlFile in $yamlFiles) {
        try {
            $content = Get-Content $yamlFile.FullName -Raw
            $currentArtifact = $null
            
            # Simple YAML parsing for tool URLs
            $content -split "`n" | ForEach-Object {
                $line = $_.Trim()
                if ($line -match '^\s*-\s*name:\s*(.+)$') {
                    $currentArtifact = $matches[1].Trim()
                }
                elseif ($line -match '^\s*url:\s*(.+)$') {
                    $url = $matches[1].Trim().Trim('"').Trim("'")
                    if ($url -match '^https?://') {
                        $externalTools += [PSCustomObject]@{
                            Artifact = $currentArtifact
                            Url = $url
                            FileName = Split-Path $url -Leaf
                        }
                    }
                }
            }
        }
        catch {
            Write-OfflineLog "Warning: Failed to parse $($yamlFile.Name)" -Level 'Warning'
        }
    }
    
    # Remove duplicates
    $externalTools = $externalTools | Sort-Object Url -Unique
    
    Write-OfflineLog "Found $($externalTools.Count) external tool dependencies"
    
    # Download external tools
    $downloadedTools = @()
    foreach ($tool in $externalTools) {
        try {
            $fileName = $tool.FileName
            if ([string]::IsNullOrEmpty($fileName)) {
                $fileName = "tool_$(Get-Random)"
            }
            
            $toolPath = Join-Path $toolsDir $fileName
            
            Write-OfflineLog "Downloading [$($tool.Artifact)] → $fileName"
            Invoke-WebRequest -Uri $tool.Url -OutFile $toolPath -UseBasicParsing -Headers $headers -TimeoutSec 120
            
            $extractedPath = ''
            # Extract ZIP files
            if ($fileName -match '\.zip$') {
                try {
                    $extractDir = Join-Path $toolsDir ($tool.Artifact -replace '[^\w\-_]', '_')
                    if (-not (Test-Path $extractDir)) {
                        New-Item -Path $extractDir -ItemType Directory -Force | Out-Null
                    }
                    
                    Expand-Archive -Path $toolPath -DestinationPath $extractDir -Force
                    $extractedPath = $extractDir
                    Write-OfflineLog "Extracted to: $extractDir"
                }
                catch {
                    Write-OfflineLog "Warning: Failed to extract $fileName" -Level 'Warning'
                }
            }
            
            $downloadedTools += [PSCustomObject]@{
                Artifact = $tool.Artifact
                Url = $tool.Url
                FileName = $fileName
                FilePath = $toolPath
                ExtractedTo = $extractedPath
                Size = (Get-Item $toolPath).Length
            }
        }
        catch {
            Write-OfflineLog "Warning: Failed to download $($tool.Url) - $($_.Exception.Message)" -Level 'Warning'
        }
    }

    # ─── 6) Generate manifests and documentation ─────────────
    Write-OfflineLog 'Generating manifests and documentation...'
    
    # External tools manifest
    if ($downloadedTools.Count -gt 0) {
        $downloadedTools | Export-Csv -Path (Join-Path $workspaceRoot 'external_tools_manifest.csv') -NoTypeInformation -Encoding UTF8
    }
    
    # Binaries manifest
    $downloadedBinaries | ConvertTo-Json -Depth 3 | Out-File (Join-Path $workspaceRoot 'binaries_manifest.json') -Encoding UTF8
    
    # Environment info
    $environmentInfo = @{
        CreatedDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        VelociraptorVersion = $tag
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        OSVersion = [System.Environment]::OSVersion.ToString()
        BinariesCount = $downloadedBinaries.Count
        ArtifactsCount = $yamlFiles.Count
        ExternalToolsCount = $downloadedTools.Count
        TotalSizeMB = [math]::Round(((Get-ChildItem $workspaceRoot -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB), 2)
    }
    
    $environmentInfo | ConvertTo-Json -Depth 3 | Out-File (Join-Path $workspaceRoot 'environment_info.json') -Encoding UTF8
    
    # Create README for the offline environment
    $readmeContent = @"
# Velociraptor Offline Environment v$tag

Generated on: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))

## Contents

### Binaries ($($downloadedBinaries.Count) platforms)
$(($downloadedBinaries | ForEach-Object { "- $($_.Platform): $($_.Path)" }) -join "`n")

### Artifact Definitions
- Location: artifact_definitions/
- Count: $($yamlFiles.Count) YAML files

### External Tools ($($downloadedTools.Count) tools)
- Location: external_tools/
- Manifest: external_tools_manifest.csv

### Configurations
- Location: configurations/
- Sample configurations and templates

## Usage

1. Copy this entire directory to your offline environment
2. Use the appropriate binary for your platform from the binaries/ directory
3. Reference artifact definitions from artifact_definitions/
4. External tools are available in external_tools/

## Total Size
$($environmentInfo.TotalSizeMB) MB

"@
    
    $readmeContent | Out-File (Join-Path $workspaceRoot 'README.md') -Encoding UTF8
    
    # Copy this script to the workspace
    Copy-Item $MyInvocation.MyCommand.Path -Destination (Join-Path $workspaceRoot (Split-Path $MyInvocation.MyCommand.Path -Leaf)) -Force

    # ─── 7) Create sample configurations ─────────────
    Write-OfflineLog 'Creating sample configurations...'
    
    # Basic standalone config template
    $standaloneConfig = @"
# Velociraptor Standalone Configuration Template
# Generated for offline environment v$tag

# Basic settings
datastore_path: "./datastore"
gui_port: 8889
log_level: INFO

# Offline artifact path
artifact_definitions_path: "./artifact_definitions"

# External tools path  
tools_path: "./external_tools"

# Note: Modify paths as needed for your deployment
"@
    
    $standaloneConfig | Out-File (Join-Path $configDir 'standalone_template.yaml') -Encoding UTF8

    # ─── 8) Compress workspace (optional) ─────────────
    if (-not $SkipCompression) {
        Write-OfflineLog 'Creating compressed archive...'
        
        $archiveName = "offline_builder_v${tag}.zip"
        $archivePath = Join-Path (Split-Path $workspaceRoot -Parent) $archiveName
        
        if (Test-Path $archivePath) {
            Remove-Item $archivePath -Force
        }
        
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [IO.Compression.ZipFile]::CreateFromDirectory($workspaceRoot, $archivePath)
        
        $archiveSize = [math]::Round((Get-Item $archivePath).Length / 1MB, 2)
        Write-OfflineLog "Archive created: $archivePath ($archiveSize MB)" -Level 'Success'
    }

    # ─── Summary ────────────────────────────────────────
    Write-OfflineLog '' 
    Write-OfflineLog '✓ Offline Velociraptor environment ready!' -Level 'Success'
    Write-OfflineLog "  Workspace: $workspaceRoot"
    Write-OfflineLog "  Version: v$tag"
    Write-OfflineLog "  Binaries: $($downloadedBinaries.Count) platforms"
    Write-OfflineLog "  Artifacts: $($yamlFiles.Count) definitions"
    Write-OfflineLog "  External Tools: $($downloadedTools.Count) tools"
    Write-OfflineLog "  Total Size: $($environmentInfo.TotalSizeMB) MB"
    
    if (-not $SkipCompression) {
        Write-OfflineLog "  Archive: $archivePath"
    }
    
    Write-OfflineLog ''
    Write-OfflineLog 'Ready for offline deployment!' -Level 'Success'
}
catch {
    Write-OfflineLog "ERROR: $($_.Exception.Message)" -Level 'Error'
    throw
}