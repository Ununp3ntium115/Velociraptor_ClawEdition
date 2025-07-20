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

# Enhanced YAML parser for Velociraptor artifacts
function ConvertFrom-Yaml {
    param($Content)
    
    # Parse Velociraptor artifact YAML and extract tool references from VQL queries
    $result = @{
        name = ""
        description = ""
        author = ""
        type = ""
        tools = @()
        sources = @()
        parameters = @()
        precondition = ""
    }
    
    if ([string]::IsNullOrWhiteSpace($Content)) {
        return $result
    }
    
    try {
        $lines = $Content -split "`r?`n"
        $currentSection = $null
        $currentQuery = ""
        $inMultilineString = $false
        $multilineDelimiter = ""
        
        foreach ($line in $lines) {
            # Skip empty lines and comments (but not in multiline strings)
            if (-not $inMultilineString -and ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#'))) {
                continue
            }
            
            $trimmedLine = $line.Trim()
            
            # Handle multiline strings
            if ($inMultilineString) {
                if ($line.Trim() -eq $multilineDelimiter) {
                    $inMultilineString = $false
                    $multilineDelimiter = ""
                } else {
                    $currentQuery += "`n$line"
                }
                continue
            }
            
            # Check for multiline string start
            if ($line -match "^\s*\|" -or $line -match "^\s*>") {
                $inMultilineString = $true
                $multilineDelimiter = ""  # YAML multiline strings end with dedent
                continue
            }
            
            # Handle top-level properties
            if ($line -match "^(\w+):\s*(.*)$") {
                $key = $matches[1].ToLower()
                $value = $matches[2].Trim()
                
                # Clean up value
                $value = $value -replace '^["\''](.*)["\'']\s*$', '$1'
                
                switch ($key) {
                    "name" { $result.name = $value }
                    "description" { 
                        if ($value -eq "|" -or $value -eq ">") {
                            $inMultilineString = $true
                            $currentQuery = ""
                        } else {
                            $result.description = $value
                        }
                    }
                    "author" { $result.author = $value }
                    "type" { $result.type = $value }
                    "precondition" { $result.precondition = $value }
                    "sources" { $currentSection = "sources" }
                    "parameters" { $currentSection = "parameters" }
                    default {
                        $result[$key] = $value
                    }
                }
            }
            # Handle query content (look for tool references)
            elseif ($line -match "query:\s*\|" -or $line -match "^\s*-\s*\|") {
                $inMultilineString = $true
                $currentQuery = ""
            }
            # Process completed queries for tool extraction
            elseif ($currentQuery -and -not $inMultilineString) {
                $extractedTools = Extract-ToolsFromVQL -VQLQuery $currentQuery
                foreach ($tool in $extractedTools) {
                    $result.tools += $tool
                }
                $currentQuery = ""
            }
        }
        
        # Process any remaining query
        if ($currentQuery) {
            $extractedTools = Extract-ToolsFromVQL -VQLQuery $currentQuery
            foreach ($tool in $extractedTools) {
                $result.tools += $tool
            }
        }
        
        # Ensure we have basic required properties
        if (-not $result.name) { $result.name = "Unknown" }
        if (-not $result.author) { $result.author = "Unknown" }
        if (-not $result.type) { $result.type = "CLIENT" }
        
        return $result
    }
    catch {
        Write-VelociraptorLog "YAML parsing error for artifact: $($_.Exception.Message)" -Level Warning
        return @{
            name = "Parse_Error_$(Get-Random)"
            description = "Failed to parse artifact YAML"
            author = "Unknown"
            type = "CLIENT"
            tools = @()
            parse_error = $_.Exception.Message
        }
    }
}

# Extract tool references from VQL queries
function Extract-ToolsFromVQL {
    param($VQLQuery)
    
    $tools = @()
    
    if ([string]::IsNullOrWhiteSpace($VQLQuery)) {
        return $tools
    }
    
    # Common tool patterns in VQL queries
    $toolPatterns = @{
        # External executables
        'execve\(' = @{ name = 'execve'; type = 'system_call' }
        'powershell\.exe' = @{ name = 'powershell'; type = 'interpreter' }
        'cmd\.exe' = @{ name = 'cmd'; type = 'interpreter' }
        'python\.exe' = @{ name = 'python'; type = 'interpreter' }
        'python3' = @{ name = 'python3'; type = 'interpreter' }
        'bash' = @{ name = 'bash'; type = 'shell' }
        'sh\s' = @{ name = 'sh'; type = 'shell' }
        
        # Forensic tools
        'volatility' = @{ name = 'volatility'; type = 'memory_analysis' }
        'yara' = @{ name = 'yara'; type = 'pattern_matching' }
        'sigcheck' = @{ name = 'sigcheck'; type = 'signature_verification' }
        'strings' = @{ name = 'strings'; type = 'text_extraction' }
        'file\s+command' = @{ name = 'file'; type = 'file_identification' }
        'xxd' = @{ name = 'xxd'; type = 'hex_dump' }
        'hexdump' = @{ name = 'hexdump'; type = 'hex_dump' }
        
        # Network tools
        'netstat' = @{ name = 'netstat'; type = 'network_analysis' }
        'ss\s' = @{ name = 'ss'; type = 'network_analysis' }
        'lsof' = @{ name = 'lsof'; type = 'file_analysis' }
        'tcpdump' = @{ name = 'tcpdump'; type = 'network_capture' }
        'wireshark' = @{ name = 'wireshark'; type = 'network_analysis' }
        
        # System tools
        'ps\s' = @{ name = 'ps'; type = 'process_listing' }
        'tasklist' = @{ name = 'tasklist'; type = 'process_listing' }
        'wmic' = @{ name = 'wmic'; type = 'wmi_query' }
        'reg\s+query' = @{ name = 'reg'; type = 'registry_query' }
        'regedit' = @{ name = 'regedit'; type = 'registry_editor' }
        
        # Log analysis
        'grep' = @{ name = 'grep'; type = 'text_search' }
        'awk' = @{ name = 'awk'; type = 'text_processing' }
        'sed' = @{ name = 'sed'; type = 'text_processing' }
        'cut' = @{ name = 'cut'; type = 'text_processing' }
        'sort' = @{ name = 'sort'; type = 'text_processing' }
        'uniq' = @{ name = 'uniq'; type = 'text_processing' }
        
        # Compression/Archive
        'zip' = @{ name = 'zip'; type = 'compression' }
        'unzip' = @{ name = 'unzip'; type = 'compression' }
        'tar' = @{ name = 'tar'; type = 'archive' }
        'gzip' = @{ name = 'gzip'; type = 'compression' }
        '7z' = @{ name = '7zip'; type = 'compression' }
    }
    
    # Search for tool patterns in the VQL query
    foreach ($pattern in $toolPatterns.Keys) {
        if ($VQLQuery -match $pattern) {
            $toolInfo = $toolPatterns[$pattern]
            $tools += @{
                name = $toolInfo.name
                type = $toolInfo.type
                pattern_matched = $pattern
                context = "VQL_Query"
                url = ""
                version = "Unknown"
                expected_hash = ""
                serve_locally = $false
                IsExecutable = $true
            }
        }
    }
    
    # Look for specific executable calls
    $executableMatches = [regex]::Matches($VQLQuery, '(?i)(?:execve|exec|run|execute|call)\s*\(\s*["\''](.*?)["\'']\s*\)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    foreach ($match in $executableMatches) {
        $executable = $match.Groups[1].Value
        if ($executable -and $executable -notmatch '^\$' -and $executable -notmatch '^%') {
            $toolName = Split-Path $executable -Leaf
            $tools += @{
                name = $toolName
                type = "executable"
                pattern_matched = "execve_call"
                context = "VQL_Executable_Call"
                full_path = $executable
                url = ""
                version = "Unknown"
                expected_hash = ""
                serve_locally = $false
                IsExecutable = $true
            }
        }
    }
    
    # Remove duplicates
    $uniqueTools = @()
    $seenTools = @{}
    foreach ($tool in $tools) {
        $key = "$($tool.name)_$($tool.type)"
        if (-not $seenTools.ContainsKey($key)) {
            $seenTools[$key] = $true
            $uniqueTools += $tool
        }
    }
    
    return $uniqueTools
}

# Export tool mapping results to various formats
function Export-ToolMapping {
    param(
        [Parameter(Mandatory = $true)]
        $Results,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    Write-VelociraptorLog "Exporting tool mapping results..." -Level Info
    
    try {
        Write-VelociraptorLog "Export-ToolMapping: Starting export process" -Level Debug
        
        # Ensure output directory exists
        $outputDir = Split-Path $OutputPath -Parent
        if ($outputDir -and -not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Ensure we have valid collections - simplified approach
        $artifactList = if ($Results.Artifacts) { @($Results.Artifacts) } else { @() }
        $toolDatabase = if ($Results.ToolDatabase) { $Results.ToolDatabase } else { @{} }
        
        # Safe counting
        $artifactCount = if ($artifactList) { $artifactList.Count } else { 0 }
        $toolCount = if ($toolDatabase -and $toolDatabase.Keys) { $toolDatabase.Keys.Count } else { 0 }
        
        Write-VelociraptorLog "Export-ToolMapping: Processing $artifactCount artifacts and $toolCount tools" -Level Info
        
        # Create comprehensive mapping report
        $mappingReport = @{
            GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            ScanTime = $Results.ScanTime
            Summary = @{
                TotalArtifacts = $artifactList.Count
                TotalTools = $toolDatabase.Count
                ArtifactsWithTools = ($artifactList | Where-Object { 
                    $_.Tools -and (@($_.Tools)).Count -gt 0 
                }).Count
                ArtifactsWithoutTools = ($artifactList | Where-Object { 
                    -not $_.Tools -or (@($_.Tools)).Count -eq 0 
                }).Count
            }
            Artifacts = @()
            Tools = @()
            ToolsByArtifact = @{}
            ArtifactsByTool = @{}
        }
        
        # Process artifacts
        foreach ($artifact in $artifactList) {
            $toolList = if ($artifact.Tools) { @($artifact.Tools) } else { @() }
            $artifactInfo = @{
                Name = $artifact.Name
                Path = $artifact.Path
                Type = $artifact.Type
                Author = $artifact.Author
                Description = $artifact.Description
                ToolCount = $toolList.Count
                Tools = $toolList | ForEach-Object { $_.Name }
            }
            $mappingReport.Artifacts += $artifactInfo
            $mappingReport.ToolsByArtifact[$artifact.Name] = $toolList | ForEach-Object { $_.Name }
        }
        
        # Process tools
        foreach ($toolName in $toolDatabase.Keys) {
            $tool = $toolDatabase[$toolName]
            $usedByList = if ($tool.UsedByArtifacts) { @($tool.UsedByArtifacts) } else { @() }
            $toolInfo = @{
                Name = $tool.Name
                Url = $tool.Url
                Version = $tool.Version
                ExpectedHash = $tool.ExpectedHash
                UsedByArtifacts = $usedByList
                ArtifactCount = $usedByList.Count
                DownloadStatus = $tool.DownloadStatus
                LocalPath = $tool.LocalPath
            }
            $mappingReport.Tools += $toolInfo
            $mappingReport.ArtifactsByTool[$toolName] = $usedByList
        }
        
        # Export to JSON
        $jsonPath = if ($OutputPath -like "*.json") { $OutputPath } else { "$OutputPath.json" }
        $mappingReport | ConvertTo-Json -Depth 10 | Set-Content $jsonPath -Encoding UTF8
        Write-VelociraptorLog "Tool mapping exported to JSON: $jsonPath" -Level Info
        
        # Export to CSV for easy analysis
        $csvPath = $jsonPath -replace "\.json$", ".csv"
        $csvData = @()
        foreach ($artifact in $artifactList) {
            $toolList = if ($artifact.Tools) { @($artifact.Tools) } else { @() }
            if ($toolList.Count -eq 0) {
                $csvData += [PSCustomObject]@{
                    ArtifactName = $artifact.Name
                    ArtifactType = $artifact.Type
                    ArtifactAuthor = $artifact.Author
                    ToolName = "None"
                    ToolUrl = ""
                    ToolVersion = ""
                    ToolStatus = "No tools required"
                }
            } else {
                foreach ($tool in $toolList) {
                    $toolStatus = if ($toolDatabase.ContainsKey($tool.Name)) { 
                        $toolDatabase[$tool.Name].DownloadStatus 
                    } else { 
                        "Unknown" 
                    }
                    $csvData += [PSCustomObject]@{
                        ArtifactName = $artifact.Name
                        ArtifactType = $artifact.Type
                        ArtifactAuthor = $artifact.Author
                        ToolName = $tool.Name
                        ToolUrl = $tool.Url
                        ToolVersion = $tool.Version
                        ToolStatus = $toolStatus
                    }
                }
            }
        }
        $csvData | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-VelociraptorLog "Tool mapping exported to CSV: $csvPath" -Level Info
        
        # Export summary report
        $summaryPath = $jsonPath -replace "\.json$", "_summary.txt"
        $summaryContent = @"
Velociraptor Artifact Tool Mapping Report
Generated: $($mappingReport.GeneratedAt)
Scan Time: $($Results.ScanTime)

SUMMARY:
========
Total Artifacts Scanned: $($mappingReport.Summary.TotalArtifacts)
Artifacts with Tools: $($mappingReport.Summary.ArtifactsWithTools)
Artifacts without Tools: $($mappingReport.Summary.ArtifactsWithoutTools)
Total Unique Tools: $($mappingReport.Summary.TotalTools)

TOP TOOLS BY USAGE:
==================
$((($mappingReport.Tools | Sort-Object ArtifactCount -Descending | Select-Object -First 10) | ForEach-Object { "- $($_.Name): Used by $($_.ArtifactCount) artifacts" }) -join "`n")

ARTIFACTS WITHOUT TOOLS:
=======================
$(($artifactList | Where-Object { -not $_.Tools -or $_.Tools.Count -eq 0 } | ForEach-Object { "- $($_.Name)" }) -join "`n")

FILES GENERATED:
===============
- JSON Report: $jsonPath
- CSV Export: $csvPath
- Summary Report: $summaryPath
"@
        
        Set-Content -Path $summaryPath -Value $summaryContent -Encoding UTF8
        Write-VelociraptorLog "Summary report exported: $summaryPath" -Level Info
        
        return @{
            Success = $true
            JsonPath = $jsonPath
            CsvPath = $csvPath
            SummaryPath = $summaryPath
            ArtifactCount = $mappingReport.Summary.TotalArtifacts
            ToolCount = $mappingReport.Summary.TotalTools
        }
    }
    catch {
        $errorMsg = "Failed to export tool mapping: $($_.Exception.Message)"
        Write-VelociraptorLog $errorMsg -Level Error
        throw $errorMsg
    }
}

# Export the main function
Export-ModuleMember -Function New-ArtifactToolManager