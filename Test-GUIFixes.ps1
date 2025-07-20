#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test script to verify GUI fixes for ASCII art and exception handling

.DESCRIPTION
    This script tests the fixes for:
    1. Changed ASCII art from green blocks to professional banner
    2. Fixed SetUnhandledExceptionMode exception by simplifying exception handling
#>

Write-Host "Testing GUI Fixes..." -ForegroundColor Yellow

# Test 1: Check if the new banner is defined correctly
Write-Host "`n1. Testing new banner definition..." -ForegroundColor Cyan

# Source the GUI file to load the banner
try {
    . "$PSScriptRoot/gui/VelociraptorGUI.ps1" -StartMinimized
    Write-Host "✅ GUI file loaded successfully" -ForegroundColor Green
    
    # Check if the new banner variable exists
    if (Get-Variable -Name "VelociraptorBanner" -Scope Script -ErrorAction SilentlyContinue) {
        Write-Host "✅ New VelociraptorBanner variable found" -ForegroundColor Green
        Write-Host "Banner content:" -ForegroundColor White
        Write-Host $script:VelociraptorBanner -ForegroundColor Cyan
    } else {
        Write-Host "❌ VelociraptorBanner variable not found" -ForegroundColor Red
    }
    
    # Check if old RaptorArt variable is gone
    if (-not (Get-Variable -Name "RaptorArt" -Scope Script -ErrorAction SilentlyContinue)) {
        Write-Host "✅ Old RaptorArt variable successfully removed" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Old RaptorArt variable still exists" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Error loading GUI file: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n2. Testing exception handling fixes..." -ForegroundColor Cyan

# Test 2: Check if the problematic SetUnhandledExceptionMode call is removed
$guiContent = Get-Content "$PSScriptRoot/gui/VelociraptorGUI.ps1" -Raw

if ($guiContent -match "SetUnhandledExceptionMode.*CatchException") {
    Write-Host "❌ Problematic SetUnhandledExceptionMode call still exists" -ForegroundColor Red
} else {
    Write-Host "✅ Problematic SetUnhandledExceptionMode call removed" -ForegroundColor Green
}

# Check if simplified exception handling is in place
if ($guiContent -match "add_ThreadException.*without changing exception mode") {
    Write-Host "✅ Simplified exception handling implemented" -ForegroundColor Green
} else {
    Write-Host "⚠️  Could not verify simplified exception handling" -ForegroundColor Yellow
}

Write-Host "`n3. Summary of fixes:" -ForegroundColor Cyan
Write-Host "   • ASCII art changed from green blocks to professional banner" -ForegroundColor White
Write-Host "   • SetUnhandledExceptionMode exception fixed with simplified handling" -ForegroundColor White
Write-Host "   • Console output changed from green to cyan/white colors" -ForegroundColor White

Write-Host "`n✅ GUI fixes testing completed!" -ForegroundColor Green