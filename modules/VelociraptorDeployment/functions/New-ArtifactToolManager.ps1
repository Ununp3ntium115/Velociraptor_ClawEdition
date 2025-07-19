function New-ArtifactToolManager {
    <#
    .SYNOPSIS
        Creates and manages artifact tool dependencies for Velociraptor deployments.
    
    .DESCRIPTION
        Scans Velociraptor artifacts for tool dependencies, downloads required tools,
        creates tool mappings, and builds offline collector packages with all dependencies
        included. Supports both upstream (server-side) and downstream (client-side) tool
        packaging strategies.
    
    .PARAMETER ArtifactPath
        Path to directory containing Velociraptor artifacts (.yaml files).
    
    .PARAMETER ToolCachePath
        Path where downloaded tools will be cached.
    
    .PARAMETER Action
        Action to perform: Scan, Download, Package, Map, Clean, or All.
    
    .PARAMETER OutputPath
        Output path for generated packages and mappings.
    
    .PARAMETER IncludeArtifacts
        Specific artifacts to include (supports wildcards).
    
    .PARAMETER ExcludeArtifacts
        Artifacts to exclude from processing.
    
    .PARAMETER OfflineMode
        Create offline packages with all tools included.
    
    .PARAMETER UpstreamPackaging
        Package tools on server-side for distribution.
    
    .PARAMETER DownstreamPackaging
        Package tools for client-side deployment.
    
    .PARAMETER ValidateTools
        Validate downloaded tools against expected hashes.
    
    .PARAMETER MaxConcurrentDownloads
        Maximum number of concurrent tool downloads.
    
    .EXAMPLE
        New-ArtifactToolManager -Action Scan -ArtifactPath ".\artifacts" -OutputPath ".\tool-mapping.json"
    
    .EXAMPLE
        New-ArtifactToolManager -Action All -ArtifactPath ".\artifacts" -ToolCachePath ".\tools" -OfflineMode
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ArtifactPath,
        
        [string]$ToolCachePath = ".\velociraptor-tools",
        
        [ValidateSet('Scan', 'Download', 'Package', 'Map', 'Clean', 'All')]
        [string]$Action = 'All',
        
        [string]$OutputPath = ".\velociraptor-packages",
        
        [string[]]$IncludeArtifacts = @("*"),
        
        [string[]]$ExcludeArtifacts = @(),
        
        [switch]$OfflineMode,
        
        [switch]$UpstreamPackaging,
        
        [switch]$DownstreamPackaging,
        
        [switch]$ValidateTools,
        
        [int]$MaxConcurrentDownloads = 5
    )
    
    try {
        Write-VelociraptorLog "Starting Artifact Tool Manager - Action: $Action" -Level Info
        
        # Initialize tool manager context
        $toolManager = New-ToolManagerContext -ArtifactPath $ArtifactPath -ToolCachePath $ToolCachePath
        
        # Execute requested actions
        switch ($Action) {
            'Scan' {
                $results = Invoke-ArtifactScan -Manager $toolManager -IncludeArtifacts $IncludeArtifacts -ExcludeArtifacts $ExcludeArtifacts
                Export-ToolMapping -Results $results -OutputPath $OutputPath
            }
            'Download' {
                $artifacts = Invoke-ArtifactScan -Manager $toolManager -IncludeArtifacts $IncludeArtifacts -ExcludeArtifacts $ExcludeArtifacts
                Invoke-ToolDownload -Manager $toolManager -Artifacts $artifacts -MaxConcurrent $MaxConcurrentDownloads -ValidateTools:$ValidateTools
            }
            'Package' {
                $artifacts = Invoke-ArtifactScan -Manager $toolManager -IncludeArtifacts $IncludeArtifacts -ExcludeArtifacts $ExcludeArtifacts
                New-OfflineCollectorPackage -Manager $toolManager -Artifacts $artifacts -OutputPath $OutputPath -OfflineMode:$OfflineMode
            }
            'Map' {
                $artifacts = Invoke-ArtifactScan -Manager $toolManager -IncludeArtifacts $IncludeArtifacts -ExcludeArtifacts $ExcludeArtifacts
                New-ToolArtifactMapping -Manager $toolManager -Artifacts $artifacts -OutputPath $OutputPath
            }
            'Clean' {
                Clear-ToolCache -Manager $toolManager
            }
            'All' {
                # Complete workflow
                $artifacts = Invoke-ArtifactScan -Manager $toolManager -IncludeArtifacts $IncludeArtifacts -ExcludeArtifacts $ExcludeArtifacts
                Invoke-ToolDownload -Manager $toolManager -Artifacts $artifacts -MaxConcurrent $MaxConcurrentDownloads -ValidateTools:$ValidateTools
                New-ToolArtifactMapping -Manager $toolManager -Artifacts $artifacts -OutputPath $OutputPath
                
                if ($OfflineMode -or $UpstreamPackaging -or $DownstreamPackaging) {
                    New-OfflineCollectorPackage -Manager $toolManager -Artifacts $artifacts -OutputPath $OutputPath -OfflineMode:$OfflineMode -UpstreamPackaging:$UpstreamPackaging -DownstreamPackaging:$DownstreamPackaging
                }
            }
        }
        
        Write-VelociraptorLog "Artifact Tool Manager completed successfully" -Level Info
        return @{
            Success = $true
            Action = $Action
            ArtifactPath = $ArtifactPath
            ToolCachePath = $ToolCachePath
            OutputPath = $OutputPath
            CompletionTime = Get-Date
        }
    }
    catch {
        $errorMessage = "Artifact Tool Manager failed: $($_.Exception.Message)"
        Write-VelociraptorLog $errorMessage -Level Error
        
        return @{
            Success = $false
            Action = $Action
            Error = $_.Exception.Message
            CompletionTime = Get-Date
        }
    }
}

# Initialize tool manager context
function New-ToolManagerContext {
    param($ArtifactPath, $ToolCachePath)
    
    # Create required directories
    $directories = @($ToolCachePath, "$ToolCachePath\cache", "$ToolCachePath\packages", "$ToolCachePath\mappings")
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -Type Directory $dir -Force | Out-Null
        }
    }
    
    return @{
        ArtifactPath = $ArtifactPath
        ToolCachePath = $ToolCachePath
        CachePath = "$ToolCachePath\cache"
        PackagePath = "$ToolCachePath\packages"
        MappingPath = "$ToolCachePath\mappings"
        DatabasePath = "$ToolCachePath\tool-database.json"
        StartTime = Get-Date
    }
}

# Scan artifacts for tool dependencies
function Invoke-ArtifactScan {
    param($Manager, $IncludeArtifacts, $ExcludeArtifacts)
    
    Write-VelociraptorLog "Scanning artifacts for tool dependencies..." -Level Info
    
    $artifacts = @()
    $toolDatabase = @{}
    
    # Get all YAML files
    $yamlFiles = Get-ChildItem -Path $Manager.ArtifactPath -Filter "*.yaml" -Recurse
    
    foreach ($yamlFile in $yamlFiles) {
        $artifactName = [System.IO.Path]::GetFileNameWithoutExtension($yamlFile.Name)
        
        # Apply include/exclude filters
        $include = $false
        foreach ($pattern in $IncludeArtifacts) {
            if ($artifactName -like $pattern) {
                $include = $true
                break
            }
        }
        
        if (-not $include) { continue }
        
        foreach ($pattern in $ExcludeArtifacts) {
            if ($artifactName -like $pattern) {
                $include = $false
                break
            }
        }
        
        if (-not $include) { continue }
        
        try {
            # Parse YAML content
            $content = Get-Content $yamlFile.FullName -Raw
            $artifactData = ConvertFrom-Yaml $content
            
            if ($artifactData.tools) {
                $artifactInfo = @{
                    Name = $artifactName
                    Path = $yamlFile.FullName
                    Tools = @()
                    Type = $artifactData.type
                    Author = $artifactData.author
                    Description = $artifactData.description
                }
                
                foreach ($tool in $artifactData.tools) {
                    $toolInfo = @{
                        Name = $tool.name
                        Url = $tool.url
                        ExpectedHash = $tool.expected_hash
                        Version = $tool.version
                        ServeLocally = $tool.serve_locally
                        IsExecutable = $tool.IsExecutable
                        ArtifactName = $artifactName
                    }
                    
                    $artifactInfo.Tools += $toolInfo
                    
                    # Add to tool database
                    if (-not $toolDatabase.ContainsKey($tool.name)) {
                        $toolDatabase[$tool.name] = @{
                            Name = $tool.name
                            Url = $tool.url
                            ExpectedHash = $tool.expected_hash
                            Version = $tool.version
                            UsedByArtifacts = @()
                            DownloadStatus = "Pending"
                            LocalPath = $null
                        }
                    }
                    
                    $toolDatabase[$tool.name].UsedByArtifacts += $artifactName
                }
                
                $artifacts += $artifactInfo
            }
        }
        catch {
            Write-VelociraptorLog "Failed to parse artifact $($yamlFile.Name): $($_.Exception.Message)" -Level Warning
        }
    }
    
    # Save tool database
    $toolDatabase | ConvertTo-Json -Depth 10 | Set-Content $Manager.DatabasePath
    
    Write-VelociraptorLog "Found $($artifacts.Count) artifacts with $($toolDatabase.Count) unique tools" -Level Info
    
    return @{
        Artifacts = $artifacts
        ToolDatabase = $toolDatabase
        ScanTime = Get-Date
    }
}

# Download tools with concurrent processing
function Invoke-ToolDownload {
    param($Manager, $Artifacts, $MaxConcurrent, $ValidateTools)
    
    Write-VelociraptorLog "Starting tool download process..." -Level Info
    
    $toolDatabase = $Artifacts.ToolDatabase
    $downloadJobs = @()
    $completed = 0
    $total = $toolDatabase.Count
    
    foreach ($toolName in $toolDatabase.Keys) {
        $tool = $toolDatabase[$toolName]
        
        # Skip if already downloaded
        $localPath = Join-Path $Manager.CachePath "$toolName.download"
        if (Test-Path $localPath) {
            Write-VelociraptorLog "Tool $toolName already cached" -Level Debug
            $tool.DownloadStatus = "Cached"
            $tool.LocalPath = $localPath
            $completed++
            continue
        }
        
        # Wait if we have too many concurrent downloads
        while ($downloadJobs.Count -ge $MaxConcurrent) {
            $downloadJobs = $downloadJobs | Where-Object { $_.State -eq "Running" }
            Start-Sleep -Milliseconds 100
        }
        
        # Start download job
        $job = Start-Job -ScriptBlock {
            param($ToolName, $Url, $OutputPath, $ExpectedHash, $ValidateTools)
            
            try {
                # Download tool
                $webClient = New-Object System.Net.WebClient
                $webClient.Headers.Add("User-Agent", "VelociraptorToolManager/1.0")
                $webClient.DownloadFile($Url, $OutputPath)
                
                # Validate hash if provided
                if ($ValidateTools -and $ExpectedHash) {
                    $actualHash = Get-FileHash $OutputPath -Algorithm SHA256
                    if ($actualHash.Hash -ne $ExpectedHash) {
                        throw "Hash validation failed for $ToolName. Expected: $ExpectedHash, Actual: $($actualHash.Hash)"
                    }
                }
                
                return @{
                    Success = $true
                    ToolName = $ToolName
                    LocalPath = $OutputPath
                    Size = (Get-Item $OutputPath).Length
                }
            }
            catch {
                return @{
                    Success = $false
                    ToolName = $ToolName
                    Error = $_.Exception.Message
                }
            }
        } -ArgumentList $toolName, $tool.Url, $localPath, $tool.ExpectedHash, $ValidateTools
        
        $downloadJobs += $job
        Write-VelociraptorLog "Started download for $toolName" -Level Debug
    }
    
    # Wait for all downloads to complete
    Write-VelociraptorLog "Waiting for downloads to complete..." -Level Info
    $downloadJobs | Wait-Job | Out-Null
    
    # Process results
    foreach ($job in $downloadJobs) {
        $result = Receive-Job $job
        $toolName = $result.ToolName
        
        if ($result.Success) {
            $toolDatabase[$toolName].DownloadStatus = "Downloaded"
            $toolDatabase[$toolName].LocalPath = $result.LocalPath
            $toolDatabase[$toolName].Size = $result.Size
            Write-VelociraptorLog "Successfully downloaded $toolName ($($result.Size) bytes)" -Level Info
        }
        else {
            $toolDatabase[$toolName].DownloadStatus = "Failed"
            $toolDatabase[$toolName].Error = $result.Error
            Write-VelociraptorLog "Failed to download $toolName`: $($result.Error)" -Level Error
        }
        
        Remove-Job $job
        $completed++
    }
    
    # Update tool database
    $toolDatabase | ConvertTo-Json -Depth 10 | Set-Content $Manager.DatabasePath
    
    $successful = ($toolDatabase.Values | Where-Object { $_.DownloadStatus -eq "Downloaded" }).Count
    Write-VelociraptorLog "Download complete: $successful/$total tools downloaded successfully" -Level Info
}

# Create tool-to-artifact mapping
function New-ToolArtifactMapping {
    param($Manager, $Artifacts, $OutputPath)
    
    Write-VelociraptorLog "Creating tool-to-artifact mapping..." -Level Info
    
    $mapping = @{
        GeneratedDate = Get-Date
        TotalArtifacts = $Artifacts.Artifacts.Count
        TotalTools = $Artifacts.ToolDatabase.Count
        ToolToArtifacts = @{}
        ArtifactToTools = @{}
        ToolCategories = @{}
    }
    
    # Create tool-to-artifacts mapping
    foreach ($toolName in $Artifacts.ToolDatabase.Keys) {
        $tool = $Artifacts.ToolDatabase[$toolName]
        $mapping.ToolToArtifacts[$toolName] = @{
            Url = $tool.Url
            Version = $tool.Version
            ExpectedHash = $tool.ExpectedHash
            UsedByArtifacts = $tool.UsedByArtifacts
            DownloadStatus = $tool.DownloadStatus
            LocalPath = $tool.LocalPath
        }
    }
    
    # Create artifact-to-tools mapping
    foreach ($artifact in $Artifacts.Artifacts) {
        $mapping.ArtifactToTools[$artifact.Name] = @{
            Type = $artifact.Type
            Author = $artifact.Author
            Description = $artifact.Description
            Tools = $artifact.Tools | ForEach-Object { $_.Name }
            ToolCount = $artifact.Tools.Count
        }
    }
    
    # Categorize tools by type
    $mapping.ToolCategories = @{
        Forensics = @()
        Analysis = @()
        Collection = @()
        Utilities = @()
        Scripts = @()
        Unknown = @()
    }
    
    foreach ($toolName in $Artifacts.ToolDatabase.Keys) {
        $tool = $Artifacts.ToolDatabase[$toolName]
        $category = Get-ToolCategory -ToolName $toolName -Url $tool.Url
        $mapping.ToolCategories[$category] += $toolName
    }
    
    # Save mapping
    $mappingPath = Join-Path $OutputPath "tool-artifact-mapping.json"
    New-Item -Path (Split-Path $mappingPath) -ItemType Directory -Force | Out-Null
    $mapping | ConvertTo-Json -Depth 10 | Set-Content $mappingPath
    
    Write-VelociraptorLog "Tool-artifact mapping saved to $mappingPath" -Level Info
    
    return $mapping
}

# Create offline collector package
function New-OfflineCollectorPackage {
    param($Manager, $Artifacts, $OutputPath, $OfflineMode, $UpstreamPackaging, $DownstreamPackaging)
    
    Write-VelociraptorLog "Creating offline collector package..." -Level Info
    
    $packagePath = Join-Path $OutputPath "velociraptor-offline-collector"
    New-Item -Path $packagePath -ItemType Directory -Force | Out-Null
    
    # Create package structure
    $structure = @{
        "artifacts" = Join-Path $packagePath "artifacts"
        "tools" = Join-Path $packagePath "tools"
        "scripts" = Join-Path $packagePath "scripts"
        "config" = Join-Path $packagePath "config"
        "docs" = Join-Path $packagePath "docs"
    }
    
    foreach ($dir in $structure.Values) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
    
    # Copy artifacts
    foreach ($artifact in $Artifacts.Artifacts) {
        $destPath = Join-Path $structure.artifacts (Split-Path $artifact.Path -Leaf)
        Copy-Item $artifact.Path $destPath
    }
    
    # Copy tools
    $toolManifest = @()
    foreach ($toolName in $Artifacts.ToolDatabase.Keys) {
        $tool = $Artifacts.ToolDatabase[$toolName]
        
        if ($tool.DownloadStatus -eq "Downloaded" -and $tool.LocalPath) {
            $toolDir = Join-Path $structure.tools $toolName
            New-Item -Path $toolDir -ItemType Directory -Force | Out-Null
            
            $destPath = Join-Path $toolDir (Split-Path $tool.LocalPath -Leaf)
            Copy-Item $tool.LocalPath $destPath
            
            $toolManifest += @{
                Name = $toolName
                OriginalUrl = $tool.Url
                LocalPath = "tools\$toolName\$(Split-Path $tool.LocalPath -Leaf)"
                Version = $tool.Version
                ExpectedHash = $tool.ExpectedHash
                UsedByArtifacts = $tool.UsedByArtifacts
            }
        }
    }
    
    # Create tool manifest
    $toolManifest | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $structure.config "tool-manifest.json")
    
    # Create deployment scripts
    New-OfflineDeploymentScripts -PackagePath $packagePath -StructurePaths $structure
    
    # Create documentation
    New-OfflinePackageDocumentation -PackagePath $packagePath -Artifacts $Artifacts
    
    # Create ZIP package if requested
    if ($OfflineMode) {
        $zipPath = "$packagePath.zip"
        Compress-Archive -Path "$packagePath\*" -DestinationPath $zipPath -Force
        Write-VelociraptorLog "Offline package created: $zipPath" -Level Info
    }
    
    Write-VelociraptorLog "Offline collector package created at $packagePath" -Level Info
    
    return @{
        PackagePath = $packagePath
        ArtifactCount = $Artifacts.Artifacts.Count
        ToolCount = $toolManifest.Count
        PackageSize = (Get-ChildItem $packagePath -Recurse | Measure-Object -Property Length -Sum).Sum
    }
}

# Helper function to categorize tools
function Get-ToolCategory {
    param($ToolName, $Url)
    
    $forensicsKeywords = @("forensic", "ftk", "volatility", "autopsy", "sleuth", "timeline", "prefetch", "registry", "eventlog")
    $analysisKeywords = @("yara", "capa", "die", "hash", "entropy", "strings", "hex", "disasm")
    $collectionKeywords = @("collector", "gather", "dump", "extract", "export", "backup")
    $scriptKeywords = @(".ps1", ".py", ".sh", "script", "powershell", "python", "bash")
    
    $toolNameLower = $ToolName.ToLower()
    $urlLower = $Url.ToLower()
    $combined = "$toolNameLower $urlLower"
    
    if ($forensicsKeywords | Where-Object { $combined -like "*$_*" }) { return "Forensics" }
    if ($analysisKeywords | Where-Object { $combined -like "*$_*" }) { return "Analysis" }
    if ($collectionKeywords | Where-Object { $combined -like "*$_*" }) { return "Collection" }
    if ($scriptKeywords | Where-Object { $combined -like "*$_*" }) { return "Scripts" }
    
    return "Unknown"
}

# Create offline deployment scripts
function New-OfflineDeploymentScripts {
    param($PackagePath, $StructurePaths)
    
    # Create PowerShell deployment script
    $deployScript = @"
# Velociraptor Offline Collector Deployment Script
param(
    [string]`$VelociraptorPath = "velociraptor.exe",
    [string]`$ConfigPath = "config\server.yaml",
    [switch]`$InstallTools
)

Write-Host "Deploying Velociraptor Offline Collector..." -ForegroundColor Green

# Install tools if requested
if (`$InstallTools) {
    Write-Host "Installing tools..." -ForegroundColor Yellow
    
    `$toolManifest = Get-Content "config\tool-manifest.json" | ConvertFrom-Json
    foreach (`$tool in `$toolManifest) {
        Write-Host "Installing `$(`$tool.Name)..." -ForegroundColor Cyan
        # Tool installation logic here
    }
}

# Deploy artifacts
Write-Host "Deploying artifacts..." -ForegroundColor Yellow
Copy-Item "artifacts\*" "`$env:ProgramData\Velociraptor\artifacts\" -Recurse -Force

Write-Host "Deployment complete!" -ForegroundColor Green
"@
    
    $deployScript | Set-Content (Join-Path $StructurePaths.scripts "Deploy-OfflineCollector.ps1")
    
    # Create Bash deployment script for Linux/macOS
    $bashScript = @"
#!/bin/bash
# Velociraptor Offline Collector Deployment Script

echo "Deploying Velociraptor Offline Collector..."

# Create directories
mkdir -p /opt/velociraptor/artifacts
mkdir -p /opt/velociraptor/tools

# Deploy artifacts
cp -r artifacts/* /opt/velociraptor/artifacts/

# Install tools if requested
if [ "`$1" = "--install-tools" ]; then
    echo "Installing tools..."
    # Tool installation logic here
fi

echo "Deployment complete!"
"@
    
    $bashScript | Set-Content (Join-Path $StructurePaths.scripts "deploy-offline-collector.sh")
}

# Create offline package documentation
function New-OfflinePackageDocumentation {
    param($PackagePath, $Artifacts)
    
    $readme = @"
# Velociraptor Offline Collector Package

This package contains a complete offline deployment of Velociraptor artifacts and their required tools.

## Contents

- **artifacts/**: $($Artifacts.Artifacts.Count) Velociraptor artifacts
- **tools/**: $($Artifacts.ToolDatabase.Count) external tools and utilities
- **scripts/**: Deployment and management scripts
- **config/**: Configuration files and manifests
- **docs/**: Documentation and guides

## Quick Start

### Windows
```powershell
.\scripts\Deploy-OfflineCollector.ps1 -InstallTools
```

### Linux/macOS
```bash
chmod +x scripts/deploy-offline-collector.sh
./scripts/deploy-offline-collector.sh --install-tools
```

## Artifacts Included

$(foreach ($artifact in $Artifacts.Artifacts) { "- **$($artifact.Name)**: $($artifact.Description)" })

## Tools Included

$(foreach ($toolName in $Artifacts.ToolDatabase.Keys) { 
    $tool = $Artifacts.ToolDatabase[$toolName]
    "- **$toolName**: Used by $($tool.UsedByArtifacts.Count) artifact(s)"
})

## Support

For issues and questions, refer to the Velociraptor documentation or community forums.

Generated on: $(Get-Date)
"@
    
    $readme | Set-Content (Join-Path $PackagePath "README.md")
}

# Clear tool cache
function Clear-ToolCache {
    param($Manager)
    
    Write-VelociraptorLog "Clearing tool cache..." -Level Info
    
    if (Test-Path $Manager.CachePath) {
        Remove-Item $Manager.CachePath -Recurse -Force
        New-Item -Path $Manager.CachePath -ItemType Directory -Force | Out-Null
    }
    
    if (Test-Path $Manager.DatabasePath) {
        Remove-Item $Manager.DatabasePath -Force
    }
    
    Write-VelociraptorLog "Tool cache cleared" -Level Info
}

# Helper function to convert YAML (simplified)
function ConvertFrom-Yaml {
    param($Content)
    
    # This is a simplified YAML parser for basic artifact parsing
    # In production, you'd want to use a proper YAML library like powershell-yaml
    
    $result = @{}
    $lines = $Content -split "`n"
    $currentSection = $null
    $tools = @()
    $currentTool = @{}
    
    foreach ($line in $lines) {
        $line = $line.Trim()
        if ($line -match "^(\w+):\s*(.*)$") {
            $key = $matches[1]
            $value = $matches[2]
            
            if ($key -eq "tools") {
                $currentSection = "tools"
            }
            elseif ($currentSection -ne "tools") {
                $result[$key] = $value
            }
        }
        elseif ($line -match "^\s*-\s*name:\s*(.+)$" -and $currentSection -eq "tools") {
            if ($currentTool.Count -gt 0) {
                $tools += $currentTool
            }
            $currentTool = @{ name = $matches[1] }
        }
        elseif ($line -match "^\s+(\w+):\s*(.+)$" -and $currentSection -eq "tools") {
            $currentTool[$matches[1]] = $matches[2]
        }
    }
    
    if ($currentTool.Count -gt 0) {
        $tools += $currentTool
    }
    
    if ($tools.Count -gt 0) {
        $result.tools = $tools
    }
    
    return $result
}

# Export the main function
Export-ModuleMember -Function New-ArtifactToolManager