#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick test to verify the Export-ToolMapping fix works.
#>

Write-Host "=== Testing Export-ToolMapping Fix ===" -ForegroundColor Green

try {
    # Import module
    Import-Module ".\modules\VelociraptorDeployment\VelociraptorDeployment.psd1" -Force
    Write-Host "✓ Module imported successfully" -ForegroundColor Green
    
    # Test just the scan action (which includes export)
    Write-Host "`nTesting artifact scanning with export..." -ForegroundColor Yellow
    $result = New-ArtifactToolManager -Action Scan -ArtifactPath ".\content\exchange\artifacts" -OutputPath ".\test-export-fix"
    
    if ($result.Success) {
        Write-Host "✅ SUCCESS: Export fix working!" -ForegroundColor Green
        Write-Host "Result: $($result | ConvertTo-Json -Depth 2)" -ForegroundColor Cyan
        
        # Check for output files
        if (Test-Path ".\test-export-fix") {
            $files = Get-ChildItem ".\test-export-fix" -Recurse
            Write-Host "`nGenerated files:" -ForegroundColor Cyan
            foreach ($file in $files) {
                Write-Host "  - $($file.Name) ($($file.Length) bytes)" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "❌ FAILED: $($result.Error)" -ForegroundColor Red
    }
}
catch {
    Write-Host "❌ EXCEPTION: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Green