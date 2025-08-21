#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Simple test of the New-ArtifactToolManager function
#>

Write-Host "=== Simple Artifact Manager Test ===" -ForegroundColor Green

try {
    # Import the module
    Import-Module "./modules/VelociraptorDeployment/VelociraptorDeployment.psd1" -Force
    Write-Host "✓ Module imported successfully" -ForegroundColor Green
    
    # Test with a very small subset
    Write-Host "Testing with small artifact subset..." -ForegroundColor Yellow
    
    $result = New-ArtifactToolManager -Action Scan -ArtifactPath "./content/exchange/artifacts" -IncludeArtifacts @("Windows.System.Services*") -OutputPath "./simple-test-output"
    
    if ($result -and $result.Success) {
        Write-Host "✓ SUCCESS: New-ArtifactToolManager working!" -ForegroundColor Green
        Write-Host "  Action: $($result.Action)" -ForegroundColor Cyan
        Write-Host "  Path: $($result.ArtifactPath)" -ForegroundColor Cyan
        Write-Host "  Output: $($result.OutputPath)" -ForegroundColor Cyan
        
        # Check for output files
        if (Test-Path "./simple-test-output") {
            $files = Get-ChildItem "./simple-test-output" -Recurse
            Write-Host "  Generated $($files.Count) output files" -ForegroundColor Cyan
        }
    } else {
        Write-Host "✗ FAILED: Function failed to execute properly" -ForegroundColor Red
        if ($result -and $result.Error) {
            Write-Host "  Error: $($result.Error)" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "✗ EXCEPTION: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
} finally {
    # Cleanup
    if (Test-Path "./simple-test-output") {
        Remove-Item "./simple-test-output" -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "=== Test Complete ===" -ForegroundColor Green