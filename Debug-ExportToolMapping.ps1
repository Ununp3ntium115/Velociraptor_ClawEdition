#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Debug script to isolate the Export-ToolMapping Count property issue
#>

[CmdletBinding()]
param()

Write-Host "=== Debugging Export-ToolMapping Count Property Issue ===" -ForegroundColor Cyan

try {
    # Import module
    Import-Module "./modules/VelociraptorDeployment" -Force
    
    # Create a minimal test case
    Write-Host "`n1. Creating minimal test data..." -ForegroundColor Yellow
    
    $testResults = @{
        Artifacts = @(
            @{
                Name = "TestArtifact"
                Path = "./test.yaml"
                Type = "Test"
                Author = "Test"
                Description = "Test artifact"
                Tools = @(
                    @{
                        Name = "TestTool"
                        Url = "https://example.com/tool.exe"
                        Version = "1.0"
                    }
                )
            }
        )
        ToolDatabase = @{
            "TestTool" = @{
                Name = "TestTool"
                Url = "https://example.com/tool.exe"
                Version = "1.0"
                UsedByArtifacts = @("TestArtifact")
                DownloadStatus = "Pending"
            }
        }
        ScanTime = Get-Date
    }
    
    Write-Host "✓ Test data created" -ForegroundColor Green
    Write-Host "  - Artifacts: $($testResults.Artifacts.Count)" -ForegroundColor Gray
    Write-Host "  - Tools: $($testResults.ToolDatabase.Count)" -ForegroundColor Gray
    
    # Test individual components that might cause Count issues
    Write-Host "`n2. Testing individual components..." -ForegroundColor Yellow
    
    # Test artifact list conversion
    $artifactList = if ($testResults.Artifacts) { @($testResults.Artifacts) } else { @() }
    Write-Host "✓ Artifact list conversion: $($artifactList.Count) items" -ForegroundColor Green
    
    # Test tool database conversion
    $toolDatabase = if ($testResults.ToolDatabase) { $testResults.ToolDatabase } else { @{} }
    Write-Host "✓ Tool database conversion: $($toolDatabase.Count) items" -ForegroundColor Green
    
    # Test Where-Object operations that might fail
    Write-Host "`n3. Testing Where-Object operations..." -ForegroundColor Yellow
    
    try {
        $artifactsWithTools = $artifactList | Where-Object { 
            $_.Tools -and (@($_.Tools)).Count -gt 0 
        }
        Write-Host "✓ Artifacts with tools: $($artifactsWithTools.Count)" -ForegroundColor Green
    } catch {
        Write-Host "✗ Error in artifacts with tools: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    try {
        $artifactsWithoutTools = $artifactList | Where-Object { 
            -not $_.Tools -or (@($_.Tools)).Count -eq 0 
        }
        Write-Host "✓ Artifacts without tools: $($artifactsWithoutTools.Count)" -ForegroundColor Green
    } catch {
        Write-Host "✗ Error in artifacts without tools: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test tool processing
    Write-Host "`n4. Testing tool processing..." -ForegroundColor Yellow
    
    foreach ($toolName in $toolDatabase.Keys) {
        $tool = $toolDatabase[$toolName]
        try {
            $usedByList = if ($tool.UsedByArtifacts) { @($tool.UsedByArtifacts) } else { @() }
            Write-Host "✓ Tool '$toolName' used by: $($usedByList.Count) artifacts" -ForegroundColor Green
        } catch {
            Write-Host "✗ Error processing tool '$toolName': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Test CSV data generation
    Write-Host "`n5. Testing CSV data generation..." -ForegroundColor Yellow
    
    try {
        $csvData = @()
        foreach ($artifact in $artifactList) {
            $toolList = if ($artifact.Tools) { @($artifact.Tools) } else { @() }
            Write-Host "  Processing artifact '$($artifact.Name)' with $($toolList.Count) tools" -ForegroundColor Gray
            
            if ($toolList.Count -eq 0) {
                $csvData += [PSCustomObject]@{
                    ArtifactName = $artifact.Name
                    ToolName = "None"
                }
            } else {
                foreach ($tool in $toolList) {
                    $csvData += [PSCustomObject]@{
                        ArtifactName = $artifact.Name
                        ToolName = $tool.Name
                    }
                }
            }
        }
        Write-Host "✓ CSV data generation: $($csvData.Count) rows" -ForegroundColor Green
    } catch {
        Write-Host "✗ Error in CSV data generation: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "`n=== Debug Complete - All Components Working ===" -ForegroundColor Green
    Write-Host "The issue may be in a specific line not tested here." -ForegroundColor Yellow
    
} catch {
    Write-Host "`n✗ Debug failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}