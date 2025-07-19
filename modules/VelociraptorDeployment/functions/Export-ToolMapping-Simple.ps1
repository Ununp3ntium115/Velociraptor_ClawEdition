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
        
        # Safe collection handling
        $artifactList = if ($Results.Artifacts) { @($Results.Artifacts) } else { @() }
        $toolDatabase = if ($Results.ToolDatabase) { $Results.ToolDatabase } else { @{} }
        
        # Safe counting with explicit checks
        $artifactCount = 0
        $toolCount = 0
        $artifactsWithTools = 0
        $artifactsWithoutTools = 0
        
        if ($artifactList) {
            $artifactCount = $artifactList.Count
            foreach ($artifact in $artifactList) {
                if ($artifact.Tools -and $artifact.Tools.Count -gt 0) {
                    $artifactsWithTools++
                } else {
                    $artifactsWithoutTools++
                }
            }
        }
        
        if ($toolDatabase -and $toolDatabase.Keys) {
            $toolCount = $toolDatabase.Keys.Count
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
        }
        
        # Process tools safely
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