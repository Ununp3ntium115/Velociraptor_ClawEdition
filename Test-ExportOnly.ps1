#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test only the Export-ToolMapping functionality with real artifact data
#>

[CmdletBinding()]
param()

Write-Host "=== Testing Export-ToolMapping with Real Data ===" -ForegroundColor Cyan

try {
    # Import module
    Import-Module "./modules/VelociraptorDeployment" -Force
    
    # Run artifact scan to get real data
    Write-Host "`n1. Running artifact scan to get real data..." -ForegroundColor Yellow
    
    # Use a small subset to isolate the issue
    $result = New-ArtifactToolManager -Action Scan -ArtifactPath "./content/exchange/artifacts" -IncludeArtifacts @("*") -OutputPath "./test-export-debug" -ErrorAction Continue
    
    if ($result -and $result.Success) {
        Write-Host "✓ Artifact scan completed successfully" -ForegroundColor Green
        Write-Host "  Result type: $($result.GetType().Name)" -ForegroundColor Gray
        Write-Host "  Success: $($result.Success)" -ForegroundColor Gray
    } else {
        Write-Host "✗ Artifact scan failed" -ForegroundColor Red
        if ($result) {
            Write-Host "  Error: $($result.Error)" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "`n✗ Test failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    
    # Let's try to get more specific error information
    Write-Host "`nDetailed error information:" -ForegroundColor Yellow
    Write-Host "Exception type: $($_.Exception.GetType().Name)" -ForegroundColor Gray
    Write-Host "Inner exception: $($_.Exception.InnerException)" -ForegroundColor Gray
    
    if ($_.Exception.ScriptStackTrace) {
        Write-Host "Script stack trace:" -ForegroundColor Gray
        Write-Host $_.Exception.ScriptStackTrace -ForegroundColor Gray
    }
} finally {
    # Cleanup
    if (Test-Path "./test-export-debug") {
        Remove-Item "./test-export-debug" -Recurse -Force -ErrorAction SilentlyContinue
    }
}