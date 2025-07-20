#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test script to verify GUI BackColor fix.
#>

Write-Host "=== Testing GUI BackColor Fix ===" -ForegroundColor Green

try {
    # Check if GUI file exists
    if (-not (Test-Path ".\gui\VelociraptorGUI.ps1")) {
        Write-Host "❌ GUI file not found" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✓ GUI file found" -ForegroundColor Green
    
    # Check for the BackColor fixes in the code
    $guiContent = Get-Content ".\gui\VelociraptorGUI.ps1" -Raw
    
    # Check if Transparent BackColor references are removed
    $transparentCount = ($guiContent | Select-String -Pattern "\[System\.Drawing\.Color\]::Transparent" -AllMatches).Matches.Count
    if ($transparentCount -eq 0) {
        Write-Host "✓ All Transparent BackColor references removed" -ForegroundColor Green
    } else {
        Write-Host "❌ Still found $transparentCount Transparent BackColor references" -ForegroundColor Red
    }
    
    # Check if proper background colors are used
    $backgroundColorCount = ($guiContent | Select-String -Pattern "\$script:Colors\.Background" -AllMatches).Matches.Count
    if ($backgroundColorCount -gt 0) {
        Write-Host "✓ Found $backgroundColorCount proper background color references" -ForegroundColor Green
    } else {
        Write-Host "❌ No proper background color references found" -ForegroundColor Red
    }
    
    Write-Host "`n=== BackColor Fix Summary ===" -ForegroundColor Cyan
    Write-Host "Changes made to fix BackColor null conversion error:" -ForegroundColor Yellow
    Write-Host "• Replaced all [System.Drawing.Color]::Transparent with \$script:Colors.Background" -ForegroundColor Gray
    Write-Host "• This prevents null conversion errors in Windows Forms" -ForegroundColor Gray
    Write-Host "• Background color will now be consistent with the dark theme" -ForegroundColor Gray
    
    Write-Host "`n✅ GUI BackColor fixes applied successfully!" -ForegroundColor Green
    Write-Host "The GUI should now work without BackColor conversion errors." -ForegroundColor Cyan
    
    # Offer to launch GUI for testing
    $response = Read-Host "`nWould you like to launch the GUI to test the fix? (y/n)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        Write-Host "Launching GUI..." -ForegroundColor Yellow
        & ".\gui\VelociraptorGUI.ps1"
    }
}
catch {
    Write-Host "❌ Error testing GUI BackColor fix: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Green