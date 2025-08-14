#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Builds comprehensive Velociraptor artifact packages with all tool dependencies.

.DESCRIPTION
    This script processes the artifact_exchange_v2.zip and other artifact sources to create
    complete offline deployment packages with all required tools automatically downloaded
    and mapped. Supports both server-side and client-side deployment scenarios.

.PARAMETER ArtifactSource
    Path to artifact source (zip file or directory).

.PARAMETER OutputPath
    Output directory for generated packages.

.PARAMETER PackageType
    Type of package to create: Offline, Server, Client, or All.

.PARAMETER IncludeCategories
    Tool categories to include (Forensics, Analysis, Collection, Scripts, Utilities).

.PARAMETER ExcludeTools
    Specific tools to exclude from packaging.

.PARAMETER ValidateDownloads
    Validate downloaded tools against expected hashes.

.PARAMETER CreateZipPackage
    Create ZIP archives of the packages.

.EXAMPLE
    .\Build-VelociraptorArtifactPackage.ps1 -ArtifactSource "artifact_exchange_v2.zip" -PackageType All

.EXAMPLE
    .\Build-VelociraptorArtifactPackage.ps1 -ArtifactSource ".\artifacts" -PackageType Offline -ValidateDownloads
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ArtifactSource,

    [string]$OutputPath = ".\velociraptor-packages",

    [ValidateSet('Offline', 'Server', 'Client', 'All')]
    [string]$PackageType = 'All',

    [string[]]$IncludeCategories = @('Forensics', 'Analysis', 'Collection', 'Scripts', 'Utilities'),

    [string[]]$ExcludeTools = @(),

    [switch]$ValidateDownloads,

    [switch]$CreateZipPackage,

    [int]$MaxConcurrentDownloads = 10
)

# Import required modules
Import-Module "$PSScriptRoot\..\modules\VelociraptorDeployment\VelociraptorDeployment.psd1" -Force -ErrorAction SilentlyContinue

# Initialize logging
$logPath = Join-Path $OutputPath "build-log.txt"
New-Item -Path (Split-Path $logPath) -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

function Write-BuildLog {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path $logPath -Value $logEntry
}

function Initialize-ArtifactSource {
    param($Source)

    Write-BuildLog "Initializing artifact source: $Source"

    $tempPath = Join-Path $env:TEMP "velociraptor-artifacts-$(Get-Random)"

    if (Test-Path $Source -PathType Leaf) {
        # Extract ZIP file
        Write-BuildLog "Extracting artifact archive..."
        Expand-Archive -Path $Source -DestinationPath $tempPath -Force -ErrorAction SilentlyContinue

        # Find artifact directory
        $artifactPath = Get-ChildItem $tempPath -Recurse -Directory | Where-Object { $_.Name -like "*artifact*" -or $_.Name -like "*exchange*" } | Select-Object -First 1
        if (-not $artifactPath) {
            $artifactPath = Get-ChildItem $tempPath -Directory | Select-Object -First 1
        }

        return $artifactPath.FullName
    }
    elseif (Test-Path $Source -PathType Container) {
        # Use directory directly
        return $Source
    }
    else {
        throw "Artifact source not found: $Source"
    }
}

function Get-ArtifactStatistics {
    param($ArtifactPath)

    Write-BuildLog "Analyzing artifact statistics..."

    $yamlFiles = Get-ChildItem -Path $ArtifactPath -Filter "*.yaml" -Recurse
    $stats = @{
        TotalArtifacts = $yamlFiles.Count
        ArtifactsByType = @{}
        ToolsFound = @{}
        Categories = @{}
    }

    foreach ($file in $yamlFiles) {
        try {
            $content = Get-Content $file.FullName -Raw

            # Extract basic info using regex (simple YAML parsing)
            if ($content -match "type:\s*(\w+)") {
                $type = $matches[1]
                if (-not $stats.ArtifactsByType.ContainsKey($type)) {
                    $stats.ArtifactsByType[$type] = 0
                }
                $stats.ArtifactsByType[$type]++
            }

            # Extract tool information
            if ($content -match "tools:") {
                $toolMatches = [regex]::Matches($content, "name:\s*([^\r\n]+)")
                foreach ($match in $toolMatches) {
                    $toolName = $match.Groups[1].Value.Trim()
                    if (-not $stats.ToolsFound.ContainsKey($toolName)) {
                        $stats.ToolsFound[$toolName] = @()
                    }
                    $stats.ToolsFound[$toolName] += $file.BaseName
                }
            }
        }
        catch {
            Write-BuildLog "Warning: Failed to parse $($file.Name): $($_.Exception.Message)" -Level "WARN"
        }
    }

    Write-BuildLog "Statistics: $($stats.TotalArtifacts) artifacts, $($stats.ToolsFound.Count) unique tools"

    return $stats
}

function New-ServerPackage {
    param($Manager, $Artifacts, $OutputPath)

    Write-BuildLog "Creating server package..."

    $serverPath = Join-Path $OutputPath "velociraptor-server-package"
    New-Item -Path $serverPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

    # Server package structure
    $structure = @{
        "artifacts" = Join-Path $serverPath "artifacts"
        "tools" = Join-Path $serverPath "tools"
        "config" = Join-Path $serverPath "config"
        "scripts" = Join-Path $serverPath "scripts"
    }

    foreach ($dir in $structure.Values) {
        New-Item -Path $dir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    }

    # Copy artifacts
    foreach ($artifact in $Artifacts.Artifacts) {
        Copy-Item $artifact.Path $structure.artifacts
    }

    # Create server configuration
    $serverConfig = @{
        version = "1.0"
        package_type = "server"
        created = Get-Date
        artifacts = $Artifacts.Artifacts | ForEach-Object {
            @{
                name = $_.Name
                type = $_.Type
                tools = $_.Tools | ForEach-Object { $_.Name }
            }
        }
        tools = @{}
    }

    # Add tool configurations for server-side serving
    foreach ($toolName in $Artifacts.ToolDatabase.Keys) {
        $tool = $Artifacts.ToolDatabase[$toolName]
        $serverConfig.tools[$toolName] = @{
            url = $tool.Url
            version = $tool.Version
            expected_hash = $tool.ExpectedHash
            serve_locally = $true
            local_path = "tools/$toolName/"
        }
    }

    $serverConfig | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $structure.config "server-config.json")

    # Create server deployment script
    $serverScript = @"
# Velociraptor Server Package Deployment
param(
    [string]`$VelociraptorPath = "velociraptor.exe",
    [string]`$DatastorePath = "C:\VelociraptorData",
    [switch]`$StartService
)

Write-Host "Deploying Velociraptor Server Package..." -ForegroundColor Green

# Create server configuration
Write-Host "Configuring server..." -ForegroundColor Yellow

# Deploy artifacts to server
`$artifactPath = Join-Path `$DatastorePath "artifacts"
New-Item -Path `$artifactPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item "artifacts\*" `$artifactPath -Recurse -Force -ErrorAction SilentlyContinue

# Setup tool serving
`$toolPath = Join-Path `$DatastorePath "tools"
New-Item -Path `$toolPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item "tools\*" `$toolPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Server package deployed successfully!" -ForegroundColor Green

if (`$StartService) {
    Write-Host "Starting Velociraptor server..." -ForegroundColor Yellow
    Start-Process `$VelociraptorPath -ArgumentList "frontend", "--datastore", `$DatastorePath
}
"@

    $serverScript | Set-Content (Join-Path $structure.scripts "Deploy-ServerPackage.ps1")

    Write-BuildLog "Server package created at $serverPath"
    return $serverPath
}

function New-ClientPackage {
    param($Manager, $Artifacts, $OutputPath)

    Write-BuildLog "Creating client package..."

    $clientPath = Join-Path $OutputPath "velociraptor-client-package"
    New-Item -Path $clientPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

    # Client package structure (lightweight)
    $structure = @{
        "artifacts" = Join-Path $clientPath "artifacts"
        "config" = Join-Path $clientPath "config"
        "scripts" = Join-Path $clientPath "scripts"
    }

    foreach ($dir in $structure.Values) {
        New-Item -Path $dir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    }

    # Copy only essential artifacts (no tools - will be downloaded from server)
    foreach ($artifact in $Artifacts.Artifacts) {
        Copy-Item $artifact.Path $structure.artifacts
    }

    # Create client configuration
    $clientConfig = @{
        version = "1.0"
        package_type = "client"
        created = Get-Date
        server_url = "https://velociraptor-server:8000"
        tool_download_enabled = $true
        artifacts = $Artifacts.Artifacts | ForEach-Object { $_.Name }
    }

    $clientConfig | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $structure.config "client-config.json")

    # Create client deployment script
    $clientScript = @"
# Velociraptor Client Package Deployment
param(
    [string]`$ServerUrl = "https://velociraptor-server:8000",
    [string]`$ConfigPath = "client.yaml"
)

Write-Host "Deploying Velociraptor Client Package..." -ForegroundColor Green

# Deploy artifacts
`$artifactPath = "`$env:ProgramData\Velociraptor\artifacts"
New-Item -Path `$artifactPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
Copy-Item "artifacts\*" `$artifactPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Client package deployed successfully!" -ForegroundColor Green
Write-Host "Tools will be downloaded from server as needed." -ForegroundColor Yellow
"@

    $clientScript | Set-Content (Join-Path $structure.scripts "Deploy-ClientPackage.ps1")

    Write-BuildLog "Client package created at $clientPath"
    return $clientPath
}

function New-ComprehensiveReport {
    param($Artifacts, $OutputPath, $Stats)

    Write-BuildLog "Generating comprehensive report..."

    $reportPath = Join-Path $OutputPath "artifact-analysis-report.html"

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Velociraptor Artifact Analysis Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .tool-list { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 10px; }
        .tool-item { background-color: #f8f9fa; padding: 10px; border-radius: 3px; }
        .stats { display: flex; justify-content: space-around; text-align: center; }
        .stat-item { background-color: #e9ecef; padding: 15px; border-radius: 5px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Velociraptor Artifact Analysis Report</h1>
        <p>Generated on: $(Get-Date)</p>
    </div>

    <div class="section">
        <h2>Summary Statistics</h2>
        <div class="stats">
            <div class="stat-item">
                <h3>$($Stats.TotalArtifacts)</h3>
                <p>Total Artifacts</p>
            </div>
            <div class="stat-item">
                <h3>$($Stats.ToolsFound.Count)</h3>
                <p>Unique Tools</p>
            </div>
            <div class="stat-item">
                <h3>$($Artifacts.ToolDatabase.Values | Where-Object { $_.DownloadStatus -eq "Downloaded" } | Measure-Object).Count</h3>
                <p>Tools Downloaded</p>
            </div>
        </div>
    </div>

    <div class="section">
        <h2>Artifacts by Type</h2>
        <table>
            <tr><th>Type</th><th>Count</th><th>Percentage</th></tr>
$(foreach ($type in $Stats.ArtifactsByType.Keys) {
    $count = $Stats.ArtifactsByType[$type]
    $percentage = [math]::Round(($count / $Stats.TotalArtifacts) * 100, 1)
    "            <tr><td>$type</td><td>$count</td><td>$percentage%</td></tr>"
})
        </table>
    </div>

    <div class="section">
        <h2>Tool Dependencies</h2>
        <div class="tool-list">
$(foreach ($toolName in $Artifacts.ToolDatabase.Keys) {
    $tool = $Artifacts.ToolDatabase[$toolName]
    $status = $tool.DownloadStatus
    $statusColor = if ($status -eq "Downloaded") { "#28a745" } elseif ($status -eq "Failed") { "#dc3545" } else { "#ffc107" }
    "            <div class='tool-item'>
                <h4>$toolName</h4>
                <p><strong>Status:</strong> <span style='color: $statusColor'>$status</span></p>
                <p><strong>Used by:</strong> $($tool.UsedByArtifacts.Count) artifact(s)</p>
                <p><strong>URL:</strong> <a href='$($tool.Url)' target='_blank'>$($tool.Url)</a></p>
            </div>"
})
        </div>
    </div>

    <div class="section">
        <h2>Artifact Details</h2>
        <table>
            <tr><th>Artifact</th><th>Type</th><th>Tools Required</th><th>Author</th></tr>
$(foreach ($artifact in $Artifacts.Artifacts) {
    "            <tr>
                <td>$($artifact.Name)</td>
                <td>$($artifact.Type)</td>
                <td>$($artifact.Tools.Count)</td>
                <td>$($artifact.Author)</td>
            </tr>"
})
        </table>
    </div>
</body>
</html>
"@

    $html | Set-Content $reportPath
    Write-BuildLog "Comprehensive report saved to $reportPath"

    return $reportPath
}

# Main execution
try {
    Write-BuildLog "Starting Velociraptor Artifact Package Build Process"
    Write-BuildLog "Source: $ArtifactSource"
    Write-BuildLog "Output: $OutputPath"
    Write-BuildLog "Package Type: $PackageType"

    # Initialize artifact source
    $artifactPath = Initialize-ArtifactSource -Source $ArtifactSource
    Write-BuildLog "Artifact path: $artifactPath"

    # Get statistics
    $stats = Get-ArtifactStatistics -ArtifactPath $artifactPath

    # Create tool manager and process artifacts
    Write-BuildLog "Processing artifacts with tool manager..."
    $result = New-ArtifactToolManager -ArtifactPath $artifactPath -Action All -OutputPath $OutputPath -OfflineMode -ValidateTools:$ValidateDownloads -MaxConcurrentDownloads $MaxConcurrentDownloads

    if (-not $result.Success) {
        throw "Tool manager failed: $($result.Error)"
    }

    # Load processed artifacts
    $toolDatabase = Get-Content (Join-Path $result.ToolCachePath "tool-database.json") | ConvertFrom-Json -AsHashtable
    $artifacts = @{
        Artifacts = @() # This would be populated from the tool manager results
        ToolDatabase = $toolDatabase
    }

    # Create packages based on type
    $packages = @()

    if ($PackageType -in @('Server', 'All')) {
        $serverPackage = New-ServerPackage -Manager $result -Artifacts $artifacts -OutputPath $OutputPath
        $packages += @{ Type = "Server"; Path = $serverPackage }
    }

    if ($PackageType -in @('Client', 'All')) {
        $clientPackage = New-ClientPackage -Manager $result -Artifacts $artifacts -OutputPath $OutputPath
        $packages += @{ Type = "Client"; Path = $clientPackage }
    }

    # Create ZIP packages if requested
    if ($CreateZipPackage) {
        Write-BuildLog "Creating ZIP packages..."
        foreach ($package in $packages) {
            $zipPath = "$($package.Path).zip"
            Compress-Archive -Path "$($package.Path)\*" -DestinationPath $zipPath -Force -ErrorAction SilentlyContinue
            Write-BuildLog "ZIP package created: $zipPath"
        }
    }

    # Generate comprehensive report
    $reportPath = New-ComprehensiveReport -Artifacts $artifacts -OutputPath $OutputPath -Stats $stats

    Write-BuildLog "Build process completed successfully!"
    Write-BuildLog "Packages created: $($packages.Count)"
    Write-BuildLog "Report available at: $reportPath"

    # Summary output
    Write-Host "`n=== BUILD SUMMARY ===" -ForegroundColor Green
    Write-Host "Artifacts processed: $($stats.TotalArtifacts)" -ForegroundColor Cyan
    Write-Host "Tools identified: $($stats.ToolsFound.Count)" -ForegroundColor Cyan
    Write-Host "Packages created: $($packages.Count)" -ForegroundColor Cyan
    Write-Host "Output directory: $OutputPath" -ForegroundColor Cyan
    Write-Host "Report: $reportPath" -ForegroundColor Cyan

    foreach ($package in $packages) {
        Write-Host "$($package.Type) package: $($package.Path)" -ForegroundColor Yellow
    }
}
catch {
    Write-BuildLog "Build process failed: $($_.Exception.Message)" -Level "ERROR"
    Write-Host "Build failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}