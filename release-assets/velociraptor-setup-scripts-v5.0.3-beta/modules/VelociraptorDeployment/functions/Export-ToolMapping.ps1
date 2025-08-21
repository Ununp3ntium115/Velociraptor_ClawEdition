function Export-ToolMapping {
    <#
    .SYNOPSIS
        Exports tool mapping results to various formats.

    .DESCRIPTION
        This function exports artifact tool mapping results to JSON, CSV, and summary formats.
        It handles edge cases and null values gracefully to prevent count property errors.

    .PARAMETER Results
        The results object containing artifacts and tool database information.

    .PARAMETER OutputPath
        The output path for the exported files.

    .EXAMPLE
        Export-ToolMapping -Results $scanResults -OutputPath ".\tool-mapping"
    #>
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
        $artifactList = if ($Results -and $Results.Artifacts) { @($Results.Artifacts) } else { @() }
        $toolDatabase = if ($Results -and $Results.ToolDatabase) { $Results.ToolDatabase } else { @{} }

        # Safe counting with explicit checks and null handling
        $artifactCount = 0
        $toolCount = 0
        $artifactsWithTools = 0
        $artifactsWithoutTools = 0

        # Handle artifact counting with comprehensive null checks
        if ($artifactList -and $artifactList -ne $null) {
            try {
                # Handle both single objects and arrays
                if ($artifactList -is [array]) {
                    $artifactCount = $artifactList.Count
                } elseif ($artifactList -is [System.Collections.ICollection]) {
                    $artifactCount = $artifactList.Count
                } elseif ($artifactList) {
                    $artifactCount = 1
                    $artifactList = @($artifactList)
                }

                # Count artifacts with and without tools
                foreach ($artifact in $artifactList) {
                    if ($artifact -and $artifact.Tools) {
                        $toolList = @($artifact.Tools)
                        $toolListCount = if ($toolList -is [array]) { $toolList.Count } elseif ($toolList) { 1 } else { 0 }
                        if ($toolListCount -gt 0) {
                            $artifactsWithTools++
                        } else {
                            $artifactsWithoutTools++
                        }
                    } else {
                        $artifactsWithoutTools++
                    }
                }
            }
            catch {
                Write-VelociraptorLog "Warning: Error counting artifacts: $($_.Exception.Message)" -Level Warning
                $artifactCount = if ($artifactList) { 1 } else { 0 }
            }
        }

        # Handle tool counting with comprehensive null checks
        if ($toolDatabase -and $toolDatabase -ne $null) {
            try {
                if ($toolDatabase -is [hashtable] -and $toolDatabase.Keys) {
                    $keys = @($toolDatabase.Keys)
                    $toolCount = $keys.Count
                } elseif ($toolDatabase -is [System.Collections.IDictionary] -and $toolDatabase.Keys) {
                    $keys = @($toolDatabase.Keys)
                    $toolCount = $keys.Count
                } elseif ($toolDatabase.Count -ne $null) {
                    $toolCount = $toolDatabase.Count
                }
            }
            catch {
                Write-VelociraptorLog "Warning: Error counting tools: $($_.Exception.Message)" -Level Warning
                $toolCount = 0
            }
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
                # Ensure artifact is not null
                if (-not $artifact) {
                    Write-VelociraptorLog "Warning: Null artifact encountered, skipping" -Level Warning
                    continue
                }

                $toolList = @()
                $toolNames = @()
                $toolListCount = 0

                # Safe tool list extraction
                try {
                    if ($artifact.Tools) { 
                        $toolList = @($artifact.Tools) 
                    }
                } catch {
                    Write-VelociraptorLog "Warning: Error accessing Tools property: $($_.Exception.Message)" -Level Warning
                }

                # Safe count check
                if ($toolList -is [array]) {
                    $toolListCount = $toolList.Count
                } elseif ($toolList) {
                    $toolListCount = 1
                    $toolList = @($toolList)
                }

                if ($toolListCount -gt 0) {
                    try {
                        $toolNames = $toolList | ForEach-Object {
                            if ($_ -and $_.Name) { $_.Name } else { $_ }
                        }
                    } catch {
                        Write-VelociraptorLog "Warning: Error processing tool names: $($_.Exception.Message)" -Level Warning
                        $toolNames = @()
                    }
                }

                # Safe property access for artifact info
                $artifactName = "Unknown"
                $artifactPath = ""
                $artifactType = "CLIENT"
                $artifactAuthor = "Unknown"
                $artifactDescription = ""

                try {
                    if ($artifact.Name) { $artifactName = $artifact.Name }
                } catch {
                    Write-VelociraptorLog "Warning: Unable to extract artifact name: $($_.Exception.Message)" -Level Warning
                    $artifactName = "Unknown"
                }
                
                try {
                    if ($artifact.Path) { $artifactPath = $artifact.Path }
                } catch {
                    Write-VelociraptorLog "Warning: Unable to extract artifact path: $($_.Exception.Message)" -Level Warning
                    $artifactPath = "Unknown"
                }
                
                try {
                    if ($artifact.Type) { $artifactType = $artifact.Type }
                } catch {
                    Write-VelociraptorLog "Warning: Unable to extract artifact type: $($_.Exception.Message)" -Level Warning
                    $artifactType = "Unknown"
                }
                
                try {
                    if ($artifact.Author) { $artifactAuthor = $artifact.Author }
                } catch {
                    Write-VelociraptorLog "Warning: Unable to extract artifact author: $($_.Exception.Message)" -Level Warning
                    $artifactAuthor = "Unknown"
                }
                
                try {
                    if ($artifact.Description) { $artifactDescription = $artifact.Description }
                } catch {
                    Write-VelociraptorLog "Warning: Unable to extract artifact description: $($_.Exception.Message)" -Level Warning
                    $artifactDescription = "Unknown"
                }

                $artifactInfo = @{
                    Name = $artifactName
                    Path = $artifactPath
                    Type = $artifactType
                    Author = $artifactAuthor
                    Description = $artifactDescription
                    ToolCount = $toolListCount
                    Tools = $toolNames
                }
                $mappingReport.Artifacts += $artifactInfo
            }
            catch {
                Write-VelociraptorLog "Error processing artifact: $($_.Exception.Message)" -Level Warning
                # Add minimal artifact info even on error - use safe property access
                $artifactName = "Unknown"
                $artifactPath = ""
                try {
                    if ($artifact -and $artifact.Name) { $artifactName = $artifact.Name }
                    if ($artifact -and $artifact.Path) { $artifactPath = $artifact.Path }
                } catch { 
                    # Ignore errors in error handler
                }
                
                $artifactInfo = @{
                    Name = $artifactName
                    Path = $artifactPath
                    Type = "CLIENT"
                    Author = "Unknown"
                    Description = "Error processing artifact"
                    ToolCount = 0
                    Tools = @()
                }
                $mappingReport.Artifacts += $artifactInfo
            }
        }

        # Process tools safely with comprehensive error handling
        if ($toolDatabase -and $toolDatabase.Keys) {
            try {
                $keys = @($toolDatabase.Keys)
                foreach ($toolName in $keys) {
                    try {
                        $tool = $toolDatabase[$toolName]
                        if (-not $tool) {
                            Write-VelociraptorLog "Warning: Tool $toolName has null value in database" -Level Warning
                            continue
                        }

                        $usedByList = if ($tool.UsedByArtifacts) { @($tool.UsedByArtifacts) } else { @() }

                        # Safe count check for used by list with multiple fallbacks
                        $usedByCount = 0
                        try {
                            if ($usedByList -is [array]) {
                                $usedByCount = $usedByList.Count
                            } elseif ($usedByList -is [System.Collections.ICollection]) {
                                $usedByCount = $usedByList.Count
                            } elseif ($usedByList) {
                                $usedByCount = 1
                                $usedByList = @($usedByList)
                            }
                        }
                        catch {
                            Write-VelociraptorLog "Warning: Error counting used by list for tool $toolName`: $($_.Exception.Message)" -Level Warning
                            $usedByCount = 0
                            $usedByList = @()
                        }

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
            }
            catch {
                Write-VelociraptorLog "Error processing tool database: $($_.Exception.Message)" -Level Warning
            }
        }

        # Export to JSON with safe path handling
        $jsonPath = if ($OutputPath -and $OutputPath -like "*.json") { $OutputPath } else { "$OutputPath.json" }
        
        if ($mappingReport) {
            $mappingReport | ConvertTo-Json -Depth 10 | Set-Content $jsonPath -Encoding UTF8
            Write-VelociraptorLog "Tool mapping exported to JSON: $jsonPath" -Level Info
        } else {
            Write-VelociraptorLog "Warning: No mapping report to export" -Level Warning
        }

        # Create simple summary with safe property access
        $summaryPath = if ($jsonPath) { $jsonPath -replace "\.json$", "_summary.txt" } else { "$OutputPath_summary.txt" }
        $generatedAt = if ($mappingReport -and $mappingReport.GeneratedAt) { $mappingReport.GeneratedAt } else { Get-Date -Format "yyyy-MM-dd HH:mm:ss" }
        
        $summaryContent = @"
Velociraptor Artifact Tool Mapping Report
Generated: $generatedAt

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