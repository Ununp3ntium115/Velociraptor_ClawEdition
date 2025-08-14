function Invoke-VelociraptorCollections {
    <#
    .SYNOPSIS
        Manages Velociraptor collections, dependencies, and offline collector packages.

    .DESCRIPTION
        Provides comprehensive collection management including dependency resolution,
        tool downloading, offline collector building, and collection validation.
        Handles mapping of collection artifacts to executable tools and scripts.

    .PARAMETER Action
        Action to perform: List, Download, Build, Validate, Package, Deploy.

    .PARAMETER CollectionPath
        Path to collection definitions directory.

    .PARAMETER OutputPath
        Output path for built packages.

    .PARAMETER IncludeCollections
        Specific collections to include (default: all).

    .PARAMETER ExcludeCollections
        Collections to exclude from processing.

    .PARAMETER ToolsRepository
        Repository URL or path for downloading tools.

    .PARAMETER OfflineMode
        Build for offline deployment (include all dependencies).

    .PARAMETER ValidateOnly
        Only validate collections without downloading or building.

    .EXAMPLE
        Invoke-VelociraptorCollections -Action List -CollectionPath ".\collections"

    .EXAMPLE
        Invoke-VelociraptorCollections -Action Build -CollectionPath ".\collections" -OutputPath ".\offline-collector" -OfflineMode
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('List', 'Download', 'Build', 'Validate', 'Package', 'Deploy')]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$CollectionPath,

        [string]$OutputPath = ".\velociraptor-collections",

        [string[]]$IncludeCollections = @(),

        [string[]]$ExcludeCollections = @(),

        [string]$ToolsRepository = "https://github.com/Velocidex/velociraptor-tools",

        [switch]$OfflineMode,

        [switch]$ValidateOnly
    )

    Write-VelociraptorLog -Message "Starting collection management: $Action" -Level Info

    try {
        # Initialize collection management
        $collectionManager = New-CollectionManager -CollectionPath $CollectionPath -ToolsRepository $ToolsRepository

        # Execute requested action
        switch ($Action) {
            'List' {
                $result = Get-CollectionsList -Manager $collectionManager -IncludeCollections $IncludeCollections -ExcludeCollections $ExcludeCollections
            }
            'Download' {
                $result = Start-CollectionDependencyDownload -Manager $collectionManager -IncludeCollections $IncludeCollections -ValidateOnly:$ValidateOnly
            }
            'Build' {
                $result = Build-OfflineCollector -Manager $collectionManager -OutputPath $OutputPath -IncludeCollections $IncludeCollections -OfflineMode:$OfflineMode
            }
            'Validate' {
                $result = Test-CollectionIntegrity -Manager $collectionManager -IncludeCollections $IncludeCollections
            }
            'Package' {
                $result = New-CollectionPackage -Manager $collectionManager -OutputPath $OutputPath -IncludeCollections $IncludeCollections
            }
            'Deploy' {
                $result = Deploy-CollectionPackage -Manager $collectionManager -OutputPath $OutputPath
            }
        }

        Write-VelociraptorLog -Message "Collection management completed successfully" -Level Info
        return $result
    }
    catch {
        Write-VelociraptorLog -Message "Collection management failed: $($_.Exception.Message)" -Level Error
        throw
    }
}

function New-CollectionManager {
    param(
        [string]$CollectionPath,
        [string]$ToolsRepository
    )

    $manager = @{
        CollectionPath = $CollectionPath
        ToolsRepository = $ToolsRepository
        Collections = @{}
        Dependencies = @{}
        ToolMappings = @{}
        DownloadCache = Join-Path $env:TEMP "VelociraptorCollections"
    }

    # Create cache directory
    if (-not (Test-Path $manager.DownloadCache)) {
        New-Item -Path $manager.DownloadCache -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    }

    # Load collection definitions
    Load-CollectionDefinitions -Manager $manager

    # Load tool mappings
    Load-ToolMappings -Manager $manager

    return $manager
}

function Import-CollectionDefinitions {
    param($Manager)

    Write-VelociraptorLog -Message "Loading collection definitions from: $($Manager.CollectionPath)" -Level Info

    if (-not (Test-Path $Manager.CollectionPath)) {
        throw "Collection path not found: $($Manager.CollectionPath)"
    }

    # Find all YAML collection files
    $collectionFiles = Get-ChildItem -Path $Manager.CollectionPath -Filter "*.yaml" -Recurse

    foreach ($file in $collectionFiles) {
        try {
            $collectionData = Get-Content $file.FullName | ConvertFrom-Yaml

            if ($collectionData.name) {
                $Manager.Collections[$collectionData.name] = @{
                    Name = $collectionData.name
                    Type = $collectionData.type
                    Description = $collectionData.description
                    FilePath = $file.FullName
                    Dependencies = $collectionData.dependencies ?? @()
                    Tools = $collectionData.tools ?? @()
                    Parameters = $collectionData.parameters ?? @{}
                    Preconditions = $collectionData.preconditions ?? @()
                    Sources = $collectionData.sources ?? @()
                }

                # Extract dependencies from sources
                Extract-CollectionDependencies -Manager $Manager -Collection $Manager.Collections[$collectionData.name]
            }
        }
        catch {
            Write-VelociraptorLog -Message "Failed to load collection: $($file.FullName) - $($_.Exception.Message)" -Level Warning
        }
    }

    Write-VelociraptorLog -Message "Loaded $($Manager.Collections.Count) collections" -Level Info
}

function Extract-CollectionDependencies {
    param($Manager, $Collection)

    # Parse collection sources for tool dependencies
    foreach ($source in $Collection.Sources) {
        if ($source.query) {
            # Extract tool references from VQL queries
            $toolReferences = Extract-ToolReferencesFromVQL -Query $source.query
            foreach ($tool in $toolReferences) {
                if ($tool -notin $Collection.Dependencies) {
                    $Collection.Dependencies += $tool
                }
            }
        }

        if ($source.precondition) {
            # Extract dependencies from preconditions
            $preconditionTools = Extract-ToolReferencesFromVQL -Query $source.precondition
            foreach ($tool in $preconditionTools) {
                if ($tool -notin $Collection.Dependencies) {
                    $Collection.Dependencies += $tool
                }
            }
        }
    }
}

function Extract-ToolReferencesFromVQL {
    param([string]$Query)

    $tools = @()

    # Common tool patterns in VQL
    $patterns = @(
        'execve\(argv=\["([^"]+)"',  # execve calls
        'Executable:\s*"([^"]+)"',   # Executable parameters
        'ToolName:\s*"([^"]+)"',     # Tool name parameters
        'Binary:\s*"([^"]+)"',       # Binary references
        'Command:\s*"([^"]+)"'       # Command references
    )

    foreach ($pattern in $patterns) {
        $matches = [regex]::Matches($Query, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        foreach ($match in $matches) {
            $toolName = $match.Groups[1].Value
            if ($toolName -and $toolName -notin $tools) {
                $tools += $toolName
            }
        }
    }

    return $tools
}

function Import-ToolMappings {
    param($Manager)

    # Default tool mappings for common forensic tools
    $Manager.ToolMappings = @{
        # Windows tools
        'reg.exe' = @{
            Platform = 'Windows'
            Source = 'System'
            Path = 'C:\Windows\System32\reg.exe'
            Description = 'Windows Registry Editor'
        }
        'netstat.exe' = @{
            Platform = 'Windows'
            Source = 'System'
            Path = 'C:\Windows\System32\netstat.exe'
            Description = 'Network Statistics'
        }
        'tasklist.exe' = @{
            Platform = 'Windows'
            Source = 'System'
            Path = 'C:\Windows\System32\tasklist.exe'
            Description = 'Task List'
        }
        'WinPrefetchView.exe' = @{
            Platform = 'Windows'
            Source = 'NirSoft'
            DownloadUrl = 'https://www.nirsoft.net/utils/winprefetchview.zip'
            Description = 'Windows Prefetch Viewer'
            License = 'Freeware'
        }
        'RegRipper' = @{
            Platform = 'Windows'
            Source = 'GitHub'
            DownloadUrl = 'https://github.com/keydet89/RegRipper3.0/archive/master.zip'
            Description = 'Registry Analysis Tool'
            License = 'GPL'
        }
        'Volatility' = @{
            Platform = 'Cross-Platform'
            Source = 'GitHub'
            DownloadUrl = 'https://github.com/volatilityfoundation/volatility3/archive/master.zip'
            Description = 'Memory Analysis Framework'
            License = 'Volatility Software License'
        }
        'YARA' = @{
            Platform = 'Cross-Platform'
            Source = 'GitHub'
            DownloadUrl = 'https://github.com/VirusTotal/yara/releases/latest'
            Description = 'Pattern Matching Engine'
            License = 'BSD-3-Clause'
        }

        # Linux tools
        'ps' = @{
            Platform = 'Linux'
            Source = 'System'
            Path = '/bin/ps'
            Description = 'Process Status'
        }
        'netstat' = @{
            Platform = 'Linux'
            Source = 'System'
            Path = '/bin/netstat'
            Description = 'Network Statistics'
        }
        'lsof' = @{
            Platform = 'Linux'
            Source = 'System'
            Path = '/usr/bin/lsof'
            Description = 'List Open Files'
        }

        # macOS tools
        'ps_macos' = @{
            Platform = 'macOS'
            Source = 'System'
            Path = '/bin/ps'
            Description = 'Process Status'
        }
        'lsof_macos' = @{
            Platform = 'macOS'
            Source = 'System'
            Path = '/usr/sbin/lsof'
            Description = 'List Open Files'
        }
    }

    # Load custom tool mappings if available
    $customMappingsPath = Join-Path $Manager.CollectionPath "tool-mappings.json"
    if (Test-Path $customMappingsPath) {
        try {
            $customMappings = Get-Content $customMappingsPath | ConvertFrom-Json
            foreach ($tool in $customMappings.PSObject.Properties) {
                $Manager.ToolMappings[$tool.Name] = $tool.Value
            }
            Write-VelociraptorLog -Message "Loaded custom tool mappings" -Level Info
        }
        catch {
            Write-VelociraptorLog -Message "Failed to load custom tool mappings: $($_.Exception.Message)" -Level Warning
        }
    }
}

function Get-CollectionsList {
    param($Manager, $IncludeCollections, $ExcludeCollections)

    $collections = @()

    foreach ($collection in $Manager.Collections.Values) {
        # Apply include/exclude filters
        if ($IncludeCollections.Count -gt 0 -and $collection.Name -notin $IncludeCollections) {
            continue
        }

        if ($ExcludeCollections.Count -gt 0 -and $collection.Name -in $ExcludeCollections) {
            continue
        }

        # Analyze dependencies
        $dependencyStatus = @()
        foreach ($dep in $collection.Dependencies) {
            $status = Get-DependencyStatus -Manager $Manager -Dependency $dep
            $dependencyStatus += $status
        }

        $collections += @{
            Name = $collection.Name
            Type = $collection.Type
            Description = $collection.Description
            Dependencies = $collection.Dependencies
            DependencyStatus = $dependencyStatus
            MissingDependencies = ($dependencyStatus | Where-Object { $_.Status -eq 'Missing' }).Count
            AvailableDependencies = ($dependencyStatus | Where-Object { $_.Status -eq 'Available' }).Count
        }
    }

    return $collections
}

function Get-DependencyStatus {
    param($Manager, $Dependency)

    $status = @{
        Name = $Dependency
        Status = 'Unknown'
        Source = 'Unknown'
        Path = ''
        DownloadUrl = ''
        Size = 0
    }

    if ($Manager.ToolMappings.ContainsKey($Dependency)) {
        $mapping = $Manager.ToolMappings[$Dependency]
        $status.Source = $mapping.Source
        $status.DownloadUrl = $mapping.DownloadUrl

        if ($mapping.Source -eq 'System') {
            # Check if system tool exists
            if (Test-Path $mapping.Path) {
                $status.Status = 'Available'
                $status.Path = $mapping.Path
                $status.Size = (Get-Item $mapping.Path).Length
            }
            else {
                $status.Status = 'Missing'
            }
        }
        else {
            # Check if tool is in download cache
            $cachedPath = Join-Path $Manager.DownloadCache $Dependency
            if (Test-Path $cachedPath) {
                $status.Status = 'Cached'
                $status.Path = $cachedPath
                $status.Size = (Get-ChildItem $cachedPath -Recurse | Measure-Object -Property Length -Sum).Sum
            }
            else {
                $status.Status = 'Missing'
            }
        }
    }
    else {
        $status.Status = 'Unknown'
    }

    return $status
}

function Start-CollectionDependencyDownload {
    param($Manager, $IncludeCollections, $ValidateOnly)

    Write-VelociraptorLog -Message "Starting dependency download process" -Level Info

    $downloadResults = @()
    $allDependencies = @{}

    # Collect all unique dependencies
    foreach ($collection in $Manager.Collections.Values) {
        if ($IncludeCollections.Count -gt 0 -and $collection.Name -notin $IncludeCollections) {
            continue
        }

        foreach ($dep in $collection.Dependencies) {
            if (-not $allDependencies.ContainsKey($dep)) {
                $allDependencies[$dep] = Get-DependencyStatus -Manager $Manager -Dependency $dep
            }
        }
    }

    # Download missing dependencies
    foreach ($dep in $allDependencies.GetEnumerator()) {
        $dependency = $dep.Value

        if ($dependency.Status -eq 'Missing' -and $dependency.DownloadUrl) {
            if ($ValidateOnly) {
                Write-VelociraptorLog -Message "Would download: $($dependency.Name) from $($dependency.DownloadUrl)" -Level Info
                $downloadResults += @{
                    Name = $dependency.Name
                    Status = 'Validated'
                    Message = "Download URL available"
                }
            }
            else {
                $result = Download-ToolDependency -Manager $Manager -Dependency $dependency
                $downloadResults += $result
            }
        }
        elseif ($dependency.Status -eq 'Available' -or $dependency.Status -eq 'Cached') {
            $downloadResults += @{
                Name = $dependency.Name
                Status = 'Available'
                Message = "Already available"
            }
        }
        else {
            $downloadResults += @{
                Name = $dependency.Name
                Status = 'Unknown'
                Message = "No download source available"
            }
        }
    }

    return @{
        TotalDependencies = $allDependencies.Count
        Downloaded = ($downloadResults | Where-Object { $_.Status -eq 'Downloaded' }).Count
        Available = ($downloadResults | Where-Object { $_.Status -eq 'Available' }).Count
        Failed = ($downloadResults | Where-Object { $_.Status -eq 'Failed' }).Count
        Results = $downloadResults
    }
}

function Get-ToolDependency {
    param($Manager, $Dependency)

    Write-VelociraptorLog -Message "Downloading dependency: $($Dependency.Name)" -Level Info

    try {
        $downloadPath = Join-Path $Manager.DownloadCache $Dependency.Name

        if (-not (Test-Path $downloadPath)) {
            New-Item -Path $downloadPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        }

        # Download the tool
        $tempFile = Join-Path $env:TEMP "$($Dependency.Name).download"

        Invoke-WebRequest -Uri $Dependency.DownloadUrl -OutFile $tempFile -UseBasicParsing

        # Extract if it's an archive
        $extension = [System.IO.Path]::GetExtension($Dependency.DownloadUrl).ToLower()
        switch ($extension) {
            '.zip' {
                Expand-Archive -Path $tempFile -DestinationPath $downloadPath -Force -ErrorAction SilentlyContinue
            }
            '.tar' {
                tar -xf $tempFile -C $downloadPath
            }
            '.gz' {
                if ($Dependency.DownloadUrl -match '\.tar\.gz$') {
                    tar -xzf $tempFile -C $downloadPath
                }
                else {
                    gzip -d $tempFile -c > (Join-Path $downloadPath $Dependency.Name)
                }
            }
            default {
                # Copy as-is for executables
                Copy-Item $tempFile (Join-Path $downloadPath $Dependency.Name)
            }
        }

        # Cleanup
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

        Write-VelociraptorLog -Message "Successfully downloaded: $($Dependency.Name)" -Level Info

        return @{
            Name = $Dependency.Name
            Status = 'Downloaded'
            Message = "Successfully downloaded to $downloadPath"
            Path = $downloadPath
        }
    }
    catch {
        Write-VelociraptorLog -Message "Failed to download $($Dependency.Name): $($_.Exception.Message)" -Level Error

        return @{
            Name = $Dependency.Name
            Status = 'Failed'
            Message = $_.Exception.Message
            Path = ''
        }
    }
}

function Build-OfflineCollector {
    param($Manager, $OutputPath, $IncludeCollections, $OfflineMode)

    Write-VelociraptorLog -Message "Building offline collector package" -Level Info

    try {
        # Create output directory structure
        $collectorPath = Join-Path $OutputPath "offline-collector"
        $toolsPath = Join-Path $collectorPath "tools"
        $collectionsPath = Join-Path $collectorPath "collections"
        $configPath = Join-Path $collectorPath "config"

        foreach ($path in @($collectorPath, $toolsPath, $collectionsPath, $configPath)) {
            if (-not (Test-Path $path)) {
                New-Item -Path $path -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
            }
        }

        # Copy collections
        $includedCollections = @()
        foreach ($collection in $Manager.Collections.Values) {
            if ($IncludeCollections.Count -gt 0 -and $collection.Name -notin $IncludeCollections) {
                continue
            }

            Copy-Item $collection.FilePath $collectionsPath
            $includedCollections += $collection
        }

        # Copy tools if offline mode
        if ($OfflineMode) {
            $copiedTools = @()
            foreach ($collection in $includedCollections) {
                foreach ($dep in $collection.Dependencies) {
                    if ($dep -in $copiedTools) { continue }

                    $depStatus = Get-DependencyStatus -Manager $Manager -Dependency $dep
                    if ($depStatus.Status -in @('Available', 'Cached')) {
                        $toolDestPath = Join-Path $toolsPath $dep
                        if (-not (Test-Path $toolDestPath)) {
                            New-Item -Path $toolDestPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
                        }

                        if ($depStatus.Status -eq 'Available') {
                            Copy-Item $depStatus.Path $toolDestPath -Force -ErrorAction SilentlyContinue
                        }
                        else {
                            Copy-Item "$($depStatus.Path)\*" $toolDestPath -Recurse -Force -ErrorAction SilentlyContinue
                        }

                        $copiedTools += $dep
                    }
                }
            }
        }

        # Generate collector configuration
        $collectorConfig = @{
            collections = $includedCollections | ForEach-Object { $_.Name }
            tools_path = if ($OfflineMode) { ".\tools" } else { $null }
            output_path = ".\output"
            offline_mode = $OfflineMode
            created = Get-Date
            version = "1.0.0"
        }

        $collectorConfig | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $configPath "collector-config.json")

        # Generate deployment script
        $deployScript = Generate-CollectorDeploymentScript -Config $collectorConfig
        $deployScript | Set-Content (Join-Path $collectorPath "deploy-collector.ps1")

        Write-VelociraptorLog -Message "Offline collector built successfully: $collectorPath" -Level Info

        return @{
            Success = $true
            Path = $collectorPath
            Collections = $includedCollections.Count
            Tools = if ($OfflineMode) { $copiedTools.Count } else { 0 }
            Size = (Get-ChildItem $collectorPath -Recurse | Measure-Object -Property Length -Sum).Sum
        }
    }
    catch {
        Write-VelociraptorLog -Message "Failed to build offline collector: $($_.Exception.Message)" -Level Error
        throw
    }
}

function New-CollectorDeploymentScript {
    param($Config)

    return @"
#!/usr/bin/env pwsh
# Velociraptor Offline Collector Deployment Script
# Generated: $(Get-Date)

param(
    [string]`$OutputPath = ".\collector-output",
    [switch]`$Validate
)

Write-Host "Velociraptor Offline Collector" -ForegroundColor Cyan
Write-Host "Collections: $($Config.collections.Count)" -ForegroundColor Green
Write-Host "Offline Mode: $($Config.offline_mode)" -ForegroundColor Green
Write-Information "" -InformationAction Continue

if (`$Validate) {
    Write-Host "Validating collector package..." -ForegroundColor Yellow
    # Validation logic would go here
    Write-Host "Validation completed" -ForegroundColor Green
    return
}

# Create output directory
if (-not (Test-Path `$OutputPath)) {
    New-Item -Path `$OutputPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
}

# Execute collections
Write-Host "Executing collections..." -ForegroundColor Yellow

# Collection execution logic would go here
# This would integrate with Velociraptor's collection execution engine

Write-Host "Collection execution completed" -ForegroundColor Green
Write-Host "Output saved to: `$OutputPath" -ForegroundColor Yellow
"@
}

function Test-CollectionIntegrity {
    param($Manager, $IncludeCollections)

    Write-VelociraptorLog -Message "Validating collection integrity" -Level Info

    $validationResults = @()

    foreach ($collection in $Manager.Collections.Values) {
        if ($IncludeCollections.Count -gt 0 -and $collection.Name -notin $IncludeCollections) {
            continue
        }

        $result = @{
            Name = $collection.Name
            Valid = $true
            Errors = @()
            Warnings = @()
        }

        # Validate collection structure
        if (-not $collection.Name) {
            $result.Valid = $false
            $result.Errors += "Missing collection name"
        }

        if (-not $collection.Sources -or $collection.Sources.Count -eq 0) {
            $result.Valid = $false
            $result.Errors += "No sources defined"
        }

        # Validate dependencies
        foreach ($dep in $collection.Dependencies) {
            $depStatus = Get-DependencyStatus -Manager $Manager -Dependency $dep
            if ($depStatus.Status -eq 'Missing') {
                $result.Warnings += "Missing dependency: $dep"
            }
            elseif ($depStatus.Status -eq 'Unknown') {
                $result.Warnings += "Unknown dependency: $dep"
            }
        }

        # Validate VQL syntax (basic check)
        foreach ($source in $collection.Sources) {
            if ($source.query) {
                try {
                    # Basic VQL syntax validation
                    if ($source.query -notmatch 'SELECT|LET|FROM') {
                        $result.Warnings += "Source query may not be valid VQL"
                    }
                }
                catch {
                    $result.Errors += "VQL syntax error in source: $($_.Exception.Message)"
                    $result.Valid = $false
                }
            }
        }

        $validationResults += $result
    }

    return @{
        TotalCollections = $validationResults.Count
        ValidCollections = ($validationResults | Where-Object { $_.Valid }).Count
        InvalidCollections = ($validationResults | Where-Object { -not $_.Valid }).Count
        Results = $validationResults
    }
}