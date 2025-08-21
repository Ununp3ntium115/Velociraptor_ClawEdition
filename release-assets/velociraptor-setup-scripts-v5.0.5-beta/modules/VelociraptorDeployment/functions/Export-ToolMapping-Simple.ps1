function Export-ToolMapping {
    param(
        [Parameter(Mandatory = $true)]
        $Results,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    Write-VelociraptorLog "Exporting tool mapping results..." -Level Info
    
    try {
        # Ensure output directory exists
        $outputDir = Split-Path $OutputPath -Parent
        if ($outputDir -and -not (Test-Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        # Debug logging
        Write-VelociraptorLog "Export-ToolMapping: Results type: $($Results.GetType().Name)" -Level Debug
        Write-VelociraptorLog "Export-ToolMapping: Results properties: $($Results.PSObject.Properties.Name -join ', ')" -Level Debug
        
        # Safe collection handling
        $artifactList = if ($Results.Artifacts) { @($Results.Artifacts) } else { @() }
        $toolDatabase = if ($Results.ToolDatabase) { $Results.ToolDatabase } else { @{} }
        
        Write-VelociraptorLog "Export-ToolMapping: Artifact list type: $($artifactList.GetType().Name), Count: $(@($artifactList).Count)" -Level Debug
        Write-VelociraptorLog "Export-ToolMapping: Tool database type: $($toolDatabase.GetType().Name)" -Level Debug
        
        # Safe counting with explicit checks
        $artifactCount = 0
        $toolCount = 0
        $artifactsWithTools = 0
        $artifactsWithoutTools = 0
        
        if ($artifactList) {
            # Use safe Count access with array conversion
            $artifactArray = @($artifactList)
            $artifactCount = $artifactArray.Count
            $artifactList = $artifactArray
            
            foreach ($artifact in $artifactList) {
                if ($artifact.Tools) {
                    $toolArray = @($artifact.Tools)
                    if ($toolArray.Count -gt 0) {
                        $artifactsWithTools++
                    } else {
                        $artifactsWithoutTools++
                    }
                } else {
                    $artifactsWithoutTools++
                }
            }
        }
        
        if ($toolDatabase -and $toolDatabase.Keys) {
            # Handle hashtable keys collection with safe Count access
            $keysArray = @($toolDatabase.Keys)
            $toolCount = $keysArray.Count
        }
        
        # Create simplified mapping report
        $mappingReport = @{
            GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            ScanTime = $Results.ScanTime
            Summary = @{
                TotalArtifacts = $artifactCount
                TotalTools = $toolCount
                ArtifactsWithTools = $artifactsWithTools
                ArtifactsWithoutTools = $artifactsWithoutTools
            }
            Artifacts = @()
            Tools = @()
        }
        
        # Process artifacts safely
        foreach ($artifact in $artifactList) {
            try {
                $toolList = if ($artifact.Tools) { @($artifact.Tools) } else { @() }
                $toolNames = @()
                
                # Safe count check using array conversion
                $toolArray = @($toolList)
                $toolListCount = $toolArray.Count
                $toolList = $toolArray
                
                if ($toolListCount -gt 0) {
                    $toolNames = $toolList | ForEach-Object { 
                        if ($_ -and $_.Name) { $_.Name } else { $_ }
                    }
                }
                
                $artifactInfo = @{
                    Name = if ($artifact.Name) { $artifact.Name } else { "Unknown" }
                    Path = if ($artifact.Path) { $artifact.Path } else { "" }
                    Type = if ($artifact.Type) { $artifact.Type } else { "CLIENT" }
                    Author = if ($artifact.Author) { $artifact.Author } else { "Unknown" }
                    Description = if ($artifact.Description) { $artifact.Description } else { "" }
                    ToolCount = $toolListCount
                    Tools = $toolNames
                }
                $mappingReport.Artifacts += $artifactInfo
            }
            catch {
                Write-VelociraptorLog "Error processing artifact: $($_.Exception.Message)" -Level Warning
                # Add minimal artifact info even on error
                $artifactInfo = @{
                    Name = if ($artifact.Name) { $artifact.Name } else { "Unknown" }
                    Path = if ($artifact.Path) { $artifact.Path } else { "" }
                    Type = "CLIENT"
                    Author = "Unknown"
                    Description = "Error processing artifact"
                    ToolCount = 0
                    Tools = @()
                }
                $mappingReport.Artifacts += $artifactInfo
            }
        }
        
        # Process tools safely
        $keys = @($toolDatabase.Keys)
        foreach ($toolName in $keys) {
            try {
                $tool = $toolDatabase[$toolName]
                $usedByList = if ($tool.UsedByArtifacts) { @($tool.UsedByArtifacts) } else { @() }
                
                # Safe count check for used by list using array conversion
                $usedByArray = @($usedByList)
                $usedByCount = $usedByArray.Count
                $usedByList = $usedByArray
                
                $toolInfo = @{
                    Name = if ($tool.Name) { $tool.Name } else { $toolName }
                    Url = if ($tool.Url) { $tool.Url } else { "" }
                    Version = if ($tool.Version) { $tool.Version } else { "Unknown" }
                    ExpectedHash = if ($tool.ExpectedHash) { $tool.ExpectedHash } else { "" }
                    UsedByArtifacts = $usedByList
                    ArtifactCount = $usedByCount
                    DownloadStatus = if ($tool.DownloadStatus) { $tool.DownloadStatus } else { "Pending" }
                    LocalPath = if ($tool.LocalPath) { $tool.LocalPath } else { "" }
                }
                $mappingReport.Tools += $toolInfo
            }
            catch {
                Write-VelociraptorLog "Error processing tool $toolName`: $($_.Exception.Message)" -Level Warning
                # Add minimal tool info even on error
                $toolInfo = @{
                    Name = $toolName
                    Url = ""
                    Version = "Unknown"
                    ExpectedHash = ""
                    UsedByArtifacts = @()
                    ArtifactCount = 0
                    DownloadStatus = "Error"
                    LocalPath = ""
                }
                $mappingReport.Tools += $toolInfo
            }
        }
        
        # Export to JSON
        $jsonPath = if ($OutputPath -like "*.json") { $OutputPath } else { "$OutputPath.json" }
        $mappingReport | ConvertTo-Json -Depth 10 | Set-Content $jsonPath -Encoding UTF8
        Write-VelociraptorLog "Tool mapping exported to JSON: $jsonPath" -Level Info
        
        # Create simple summary
        $summaryPath = $jsonPath -replace "\.json$", "_summary.txt"
        $summaryContent = @"
Velociraptor Artifact Tool Mapping Report
Generated: $($mappingReport.GeneratedAt)

SUMMARY:
========
Total Artifacts Scanned: $artifactCount
Artifacts with Tools: $artifactsWithTools
Artifacts without Tools: $artifactsWithoutTools
Total Unique Tools: $toolCount

FILES GENERATED:
===============
- JSON Report: $jsonPath
- Summary Report: $summaryPath
"@
        
        Set-Content -Path $summaryPath -Value $summaryContent -Encoding UTF8
        Write-VelociraptorLog "Summary report exported: $summaryPath" -Level Info
        
        return @{
            Success = $true
            JsonPath = $jsonPath
            SummaryPath = $summaryPath
            ArtifactCount = $artifactCount
            ToolCount = $toolCount
        }
    }
    catch {
        $errorMsg = "Failed to export tool mapping: $($_.Exception.Message)"
        Write-VelociraptorLog $errorMsg -Level Error
        throw $errorMsg
    }
}