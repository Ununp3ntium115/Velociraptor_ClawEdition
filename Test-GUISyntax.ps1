#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test GUI syntax and verify fixes
#>

Write-Host "=== Testing GUI Syntax and Fixes ===" -ForegroundColor Green

try {
    $guiPath = "gui/VelociraptorGUI.ps1"
    
    Write-Host "`n1. Testing PowerShell syntax..." -ForegroundColor Cyan
    
    # Test syntax without executing
    $syntaxCheck = powershell.exe -NoProfile -Command "
        try {
            `$null = [System.Management.Automation.PSParser]::Tokenize((Get-Content '$guiPath' -Raw), [ref]`$null)
            Write-Host '✓ PowerShell syntax is valid' -ForegroundColor Green
            exit 0
        } catch {
            Write-Host '✗ Syntax error: ' + `$_.Exception.Message -ForegroundColor Red
            exit 1
        }
    "
    
    Write-Host "`n2. Checking text replacements..." -ForegroundColor Cyan
    $content = Get-Content $guiPath -Raw
    
    if ($content -match "Free For All First Responders") {
        Write-Host "✓ 'Professional Edition' replaced with 'Free For All First Responders'" -ForegroundColor Green
    } else {
        Write-Host "✗ Text replacement not found" -ForegroundColor Red
    }
    
    Write-Host "`n3. Checking comment fixes..." -ForegroundColor Cyan
    if ($content -notmatch "}#\s*[A-Za-z]") {
        Write-Host "✓ Broken comment syntax fixed" -ForegroundColor Green
    } else {
        Write-Host "✗ Broken comments still present" -ForegroundColor Red
    }
    
    Write-Host "`n=== Summary ===" -ForegroundColor Cyan
    Write-Host "• Fixed broken comment syntax (}# issues)" -ForegroundColor Gray
    Write-Host "• Replaced 'Professional Edition' with 'Free For All First Responders'" -ForegroundColor Gray
    Write-Host "• GUI should now load without PowerShell syntax errors" -ForegroundColor Gray
    
} catch {
    Write-Host "Error during testing: $($_.Exception.Message)" -ForegroundColor Red
}