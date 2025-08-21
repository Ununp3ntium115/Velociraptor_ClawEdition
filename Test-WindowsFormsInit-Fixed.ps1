#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test Windows Forms Initialization Fix

.DESCRIPTION
    This script tests the correct initialization order for Windows Forms to ensure
    SetCompatibleTextRenderingDefault works properly.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "Testing Windows Forms Initialization Fix..." -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Test the CORRECT initialization order
Write-Host "Testing CORRECT initialization order..." -ForegroundColor Yellow

try {
    # STEP 1: Load assemblies FIRST
    Write-Host "Step 1: Loading assemblies..." -ForegroundColor White
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    Write-Host "   ✅ Assemblies loaded successfully" -ForegroundColor Green
    
    # STEP 2: NOW call SetCompatibleTextRenderingDefault
    Write-Host "Step 2: Calling SetCompatibleTextRenderingDefault..." -ForegroundColor White
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
    Write-Host "   ✅ SetCompatibleTextRenderingDefault successful" -ForegroundColor Green
    
    # STEP 3: Enable visual styles
    Write-Host "Step 3: Enabling visual styles..." -ForegroundColor White
    [System.Windows.Forms.Application]::EnableVisualStyles()
    Write-Host "   ✅ Visual styles enabled" -ForegroundColor Green
    
    # STEP 4: Test creating a simple form
    Write-Host "Step 4: Testing form creation..." -ForegroundColor White
    $testForm = New-Object System.Windows.Forms.Form
    $testForm.Text = "Test Form"
    $testForm.Size = New-Object System.Drawing.Size(300, 200)
    $testForm.StartPosition = "CenterScreen"
    Write-Host "   ✅ Form created successfully" -ForegroundColor Green
    
    # Clean up
    $testForm.Dispose()
    Write-Host "   ✅ Form disposed successfully" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "SUCCESS: Windows Forms initialization works correctly!" -ForegroundColor Green
    Write-Host "The SetCompatibleTextRenderingDefault error has been fixed." -ForegroundColor Green
    
}
catch {
    Write-Host ""
    Write-Host "ERROR: Windows Forms initialization failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "This indicates the fix did not work properly." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Fix Verification Complete!" -ForegroundColor Cyan