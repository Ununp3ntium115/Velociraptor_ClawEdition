#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test Windows Forms initialization to debug the SetCompatibleTextRenderingDefault error
#>

Write-Host "=== Testing Windows Forms Initialization ===" -ForegroundColor Green

try {
    Write-Host "`n1. Loading assemblies..." -ForegroundColor Cyan
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    Write-Host "✓ Assemblies loaded successfully" -ForegroundColor Green
    
    Write-Host "`n2. Checking current state..." -ForegroundColor Cyan
    $renderWithVisualStyles = [System.Windows.Forms.Application]::RenderWithVisualStyles
    Write-Host "RenderWithVisualStyles: $renderWithVisualStyles" -ForegroundColor Yellow
    
    Write-Host "`n3. Attempting initialization..." -ForegroundColor Cyan
    
    # Try the safe initialization order
    try {
        [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
        Write-Host "✓ SetCompatibleTextRenderingDefault succeeded" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ SetCompatibleTextRenderingDefault failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    try {
        [System.Windows.Forms.Application]::EnableVisualStyles()
        Write-Host "✓ EnableVisualStyles succeeded" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ EnableVisualStyles failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "`n4. Testing simple form creation..." -ForegroundColor Cyan
    try {
        $testForm = New-Object System.Windows.Forms.Form
        $testForm.Text = "Test Form"
        $testForm.Size = New-Object System.Drawing.Size(300, 200)
        Write-Host "✓ Form created successfully" -ForegroundColor Green
        $testForm.Dispose()
    }
    catch {
        Write-Host "✗ Form creation failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "`n=== Test Complete ===" -ForegroundColor Green
    Write-Host "If all tests passed, the GUI should work." -ForegroundColor White
    
} catch {
    Write-Host "Critical error during testing: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
}