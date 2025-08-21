#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Demonstrate Windows Forms Initialization Error (Before Fix)

.DESCRIPTION
    This script demonstrates the WRONG initialization order that caused the error:
    "SetCompatibleTextRenderingDefault must be called before the first IWin32Window object is created"
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host "Demonstrating Windows Forms Initialization Error (Before Fix)..." -ForegroundColor Red
Write-Host "================================================================" -ForegroundColor Red

# Test the WRONG initialization order that caused the error
Write-Host "Testing WRONG initialization order (what caused the error)..." -ForegroundColor Yellow

try {
    # WRONG: Try to call SetCompatibleTextRenderingDefault BEFORE loading assemblies
    Write-Host "Step 1: Attempting SetCompatibleTextRenderingDefault before loading assemblies..." -ForegroundColor White
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
    Write-Host "   This should fail because the assembly isn't loaded yet!" -ForegroundColor Red
    
}
catch {
    Write-Host ""
    Write-Host "ERROR (Expected): $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "This demonstrates why the assemblies must be loaded FIRST!" -ForegroundColor Yellow
    Write-Host ""
    
    # Now show the correct way
    Write-Host "Now demonstrating the CORRECT way..." -ForegroundColor Green
    
    try {
        # CORRECT: Load assemblies FIRST
        Write-Host "Step 1: Loading assemblies FIRST..." -ForegroundColor White
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        Write-Host "   ✅ Assemblies loaded successfully" -ForegroundColor Green
        
        # CORRECT: NOW call SetCompatibleTextRenderingDefault
        Write-Host "Step 2: NOW calling SetCompatibleTextRenderingDefault..." -ForegroundColor White
        [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
        Write-Host "   ✅ SetCompatibleTextRenderingDefault successful" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "SUCCESS: Correct initialization order works!" -ForegroundColor Green
        
    }
    catch {
        Write-Host "ERROR: Even correct order failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Demonstration Complete!" -ForegroundColor Cyan
Write-Host "Key Lesson: Load assemblies FIRST, then call SetCompatibleTextRenderingDefault" -ForegroundColor Yellow