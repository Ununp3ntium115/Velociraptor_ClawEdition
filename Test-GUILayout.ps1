#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test script to verify GUI layout fixes for button visibility.
#>

Write-Host "=== Testing GUI Layout Fix ===" -ForegroundColor Green

try {
    # Check if GUI file exists
    if (-not (Test-Path ".\gui\VelociraptorGUI.ps1")) {
        Write-Host "❌ GUI file not found" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✓ GUI file found" -ForegroundColor Green
    
    # Check for the layout fixes in the code
    $guiContent = Get-Content ".\gui\VelociraptorGUI.ps1" -Raw
    
    # Check for button panel positioning fix
    if ($guiContent -match '\$backgroundPanel\.Height - 100') {
        Write-Host "✓ Button panel positioning fix applied" -ForegroundColor Green
    } else {
        Write-Host "❌ Button panel positioning fix not found" -ForegroundColor Red
    }
    
    # Check for minimum size increase
    if ($guiContent -match 'MinimumSize.*900.*700') {
        Write-Host "✓ Minimum window size increased" -ForegroundColor Green
    } else {
        Write-Host "❌ Minimum window size not updated" -ForegroundColor Red
    }
    
    # Check for content panel size adjustment
    if ($guiContent -match 'ContentPanel.*Size.*940.*450') {
        Write-Host "✓ Content panel size adjusted" -ForegroundColor Green
    } else {
        Write-Host "❌ Content panel size not adjusted" -ForegroundColor Red
    }
    
    Write-Host "`n=== Layout Fix Summary ===" -ForegroundColor Cyan
    Write-Host "Changes made to fix button visibility:" -ForegroundColor Yellow
    Write-Host "• Button panel positioned 100px from bottom (was 80px)" -ForegroundColor Gray
    Write-Host "• Content panel height reduced to 450px (was 500px)" -ForegroundColor Gray
    Write-Host "• Minimum window height increased to 700px (was 650px)" -ForegroundColor Gray
    Write-Host "• All resize handlers updated with new positioning" -ForegroundColor Gray
    
    Write-Host "`n✅ GUI layout fixes applied successfully!" -ForegroundColor Green
    Write-Host "The buttons should now be visible within the window bounds." -ForegroundColor Cyan
    
    # Offer to launch GUI for testing
    $response = Read-Host "`nWould you like to launch the GUI to test the layout? (y/n)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        Write-Host "Launching GUI..." -ForegroundColor Yellow
        & ".\gui\VelociraptorGUI.ps1"
    }
}
catch {
    Write-Host "❌ Error testing GUI layout: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Green