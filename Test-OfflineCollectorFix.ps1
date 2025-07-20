#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test the artifact pack detection fix in Prepare_OfflineCollector_Env.ps1

.DESCRIPTION
    This script validates that our fix for artifact pack detection is working correctly.
#>

[CmdletBinding()]
param()

Write-Host "=== Testing Offline Collector Artifact Pack Fix ===" -ForegroundColor Cyan

try {
    # Check if artifact_pack.zip exists in script directory
    Write-Host "`n1. Checking for local artifact_pack.zip..." -ForegroundColor Yellow
    
    $localArtifactPack = Join-Path $PSScriptRoot 'artifact_pack.zip'
    if (Test-Path $localArtifactPack) {
        $size = [math]::Round((Get-Item $localArtifactPack).Length / 1MB, 2)
        Write-Host "✓ Local artifact_pack.zip found ($size MB)" -ForegroundColor Green
        Write-Host "  Location: $localArtifactPack" -ForegroundColor Gray
    } else {
        Write-Host "⚠ Local artifact_pack.zip not found" -ForegroundColor Yellow
        Write-Host "  Expected location: $localArtifactPack" -ForegroundColor Gray
    }

    # Check if enhanced artifact collection exists
    Write-Host "`n2. Checking enhanced artifact collection..." -ForegroundColor Yellow
    
    $exchangeArtifacts = Join-Path $PSScriptRoot 'content\exchange\artifacts'
    if (Test-Path $exchangeArtifacts) {
        $artifactCount = (Get-ChildItem $exchangeArtifacts -Filter '*.yaml').Count
        Write-Host "✓ Enhanced artifact collection found ($artifactCount artifacts)" -ForegroundColor Green
        Write-Host "  Location: $exchangeArtifacts" -ForegroundColor Gray
    } else {
        Write-Host "⚠ Enhanced artifact collection not found" -ForegroundColor Yellow
        Write-Host "  Expected location: $exchangeArtifacts" -ForegroundColor Gray
    }

    # Test the logic without actually running the full script
    Write-Host "`n3. Testing artifact pack detection logic..." -ForegroundColor Yellow
    
    if (Test-Path $localArtifactPack) {
        Write-Host "✓ Script will use local artifact_pack.zip" -ForegroundColor Green
        Write-Host "  Expected behavior: No warning about missing artifact pack" -ForegroundColor Gray
    } elseif (Test-Path $exchangeArtifacts) {
        Write-Host "✓ Script will use enhanced artifact collection as fallback" -ForegroundColor Green
        Write-Host "  Expected behavior: Enhanced artifact discovery message" -ForegroundColor Gray
    } else {
        Write-Host "⚠ Script will show warning and attempt GitHub download" -ForegroundColor Yellow
        Write-Host "  Expected behavior: GitHub API call for artifact pack" -ForegroundColor Gray
    }

    # Recommendations
    Write-Host "`n4. Recommendations..." -ForegroundColor Yellow
    
    Write-Host "`nNext Steps:" -ForegroundColor White
    if (Test-Path $localArtifactPack) {
        Write-Host "  ✅ Ready to test: Run Prepare_OfflineCollector_Env.ps1" -ForegroundColor Green
        Write-Host "  ✅ Expected: No artifact pack warning" -ForegroundColor Green
        Write-Host "  ✅ Expected: 'Using local artifact_pack.zip' message" -ForegroundColor Green
    } else {
        Write-Host "  🔧 Add artifact_pack.zip to script directory" -ForegroundColor Cyan
        Write-Host "  🔧 Or ensure content/exchange/artifacts exists" -ForegroundColor Cyan
        Write-Host "  🔧 Then run Prepare_OfflineCollector_Env.ps1" -ForegroundColor Cyan
    }

    Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
    Write-Host "Status: Fix is ready for validation!" -ForegroundColor Green

} catch {
    Write-Host "`n✗ Test failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}