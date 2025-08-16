#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Windows Forms Diagnostic Tool

.DESCRIPTION
    Tests Windows Forms functionality and identifies common issues.
#>

Write-Host "🔍 Windows Forms Diagnostic Tool" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Test 1: PowerShell Version
Write-Host "`n1. Testing PowerShell Version..." -ForegroundColor Yellow
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor White
Write-Host "Edition: $($PSVersionTable.PSEdition)" -ForegroundColor White

if ($PSVersionTable.PSEdition -eq "Core") {
    Write-Host "⚠️  You're using PowerShell Core. Windows Forms support may be limited." -ForegroundColor Yellow
    Write-Host "💡 Try using Windows PowerShell 5.1 instead: powershell.exe" -ForegroundColor Cyan
}

# Test 2: Assembly Loading
Write-Host "`n2. Testing Assembly Loading..." -ForegroundColor Yellow

try {
    Write-Host "   Testing System.Windows.Forms..." -ForegroundColor Gray
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Write-Host "   ✅ System.Windows.Forms loaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "   ❌ System.Windows.Forms failed: $($_.Exception.Message)" -ForegroundColor Red
}

try {
    Write-Host "   Testing System.Drawing..." -ForegroundColor Gray
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    Write-Host "   ✅ System.Drawing loaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "   ❌ System.Drawing failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: SetCompatibleTextRenderingDefault
Write-Host "`n3. Testing SetCompatibleTextRenderingDefault..." -ForegroundColor Yellow

try {
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
    Write-Host "   ✅ SetCompatibleTextRenderingDefault successful" -ForegroundColor Green
}
catch {
    Write-Host "   ❌ SetCompatibleTextRenderingDefault failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Message -like "*must be called before*") {
        Write-Host "   💡 This error means a Windows Forms object was already created" -ForegroundColor Yellow
    }
}

# Test 4: Basic Form Creation
Write-Host "`n4. Testing Basic Form Creation..." -ForegroundColor Yellow

try {
    $testForm = New-Object System.Windows.Forms.Form
    $testForm.Text = "Test Form"
    $testForm.Size = New-Object System.Drawing.Size(300, 200)
    Write-Host "   ✅ Basic form creation successful" -ForegroundColor Green
    
    # Test label creation
    $testLabel = New-Object System.Windows.Forms.Label
    $testLabel.Text = "Test Label"
    Write-Host "   ✅ Label creation successful" -ForegroundColor Green
    
    # Cleanup
    $testForm.Dispose()
}
catch {
    Write-Host "   ❌ Form creation failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Color Creation
Write-Host "`n5. Testing Color Creation..." -ForegroundColor Yellow

try {
    $testColor = [System.Drawing.Color]::FromArgb(32, 32, 32)
    Write-Host "   ✅ Color creation successful" -ForegroundColor Green
}
catch {
    Write-Host "   ❌ Color creation failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: Environment Information
Write-Host "`n6. Environment Information..." -ForegroundColor Yellow
Write-Host "   OS: $([System.Environment]::OSVersion)" -ForegroundColor White
Write-Host "   .NET Version: $([System.Environment]::Version)" -ForegroundColor White
Write-Host "   Is 64-bit: $([System.Environment]::Is64BitProcess)" -ForegroundColor White

# Test 7: Execution Policy
Write-Host "`n7. Execution Policy..." -ForegroundColor Yellow
Write-Host "   Current Policy: $(Get-ExecutionPolicy)" -ForegroundColor White
if ((Get-ExecutionPolicy) -eq "Restricted") {
    Write-Host "   ⚠️  Execution policy is Restricted. This may cause issues." -ForegroundColor Yellow
    Write-Host "   💡 Run: Set-ExecutionPolicy Bypass -Scope Process -Force" -ForegroundColor Cyan
}

# Summary and Recommendations
Write-Host "`n📋 SUMMARY & RECOMMENDATIONS:" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

if ($PSVersionTable.PSEdition -eq "Core") {
    Write-Host "🔧 RECOMMENDATION: Use Windows PowerShell instead of PowerShell Core" -ForegroundColor Yellow
    Write-Host "   Run: powershell.exe (not pwsh.exe)" -ForegroundColor Gray
}

Write-Host "`n🚀 NEXT STEPS:" -ForegroundColor Green
Write-Host "1. If tests passed: Try .\VelociraptorGUI-Working.ps1" -ForegroundColor White
Write-Host "2. If tests failed: Use Windows PowerShell 5.1" -ForegroundColor White
Write-Host "3. If still issues: Check Windows Forms installation" -ForegroundColor White

Write-Host "`n✅ Diagnostic completed!" -ForegroundColor Green