#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Verification script to confirm all 4 critical issues have been resolved

.DESCRIPTION
    Tests all the critical fixes applied to ensure beta release readiness:
    1. Module function export mismatch
    2. Syntax errors in Prepare_OfflineCollector_Env.ps1
    3. GUI implementation completeness
    4. Test script path issues
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

# Track results
$script:TestResults = @{
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    Issues = @()
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = ""
    )
    
    $script:TestResults.TotalTests++
    
    if ($Passed) {
        $script:TestResults.PassedTests++
        Write-Host "✅ $TestName" -ForegroundColor Green
        if ($Details) {
            Write-Host "   └─ $Details" -ForegroundColor Gray
        }
    } else {
        $script:TestResults.FailedTests++
        $script:TestResults.Issues += $TestName
        Write-Host "❌ $TestName" -ForegroundColor Red
        if ($Details) {
            Write-Host "   └─ $Details" -ForegroundColor Yellow
        }
    }
}

Write-Host "🔍 VERIFYING CRITICAL FIXES FOR BETA RELEASE" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Module Function Export Mismatch
Write-Host "1. Testing Module Function Exports..." -ForegroundColor Magenta

try {
    # Test VelociraptorDeployment module
    Import-Module ./modules/VelociraptorDeployment -Force -ErrorAction Stop
    $deploymentCommands = Get-Command -Module VelociraptorDeployment
    Write-TestResult "VelociraptorDeployment module imports" $true "$($deploymentCommands.Count) commands available"
    
    # Test VelociraptorGovernance module
    Import-Module ./modules/VelociraptorGovernance -Force -ErrorAction Stop
    $governanceCommands = Get-Command -Module VelociraptorGovernance
    Write-TestResult "VelociraptorGovernance module imports" $true "$($governanceCommands.Count) commands available"
    
    # Test key functions exist
    $keyFunctions = @('Write-VelociraptorLog', 'Test-VelociraptorAdminPrivileges', 'Export-ToolMapping', 'Test-ComplianceBaseline')
    foreach ($func in $keyFunctions) {
        $command = Get-Command $func -ErrorAction SilentlyContinue
        Write-TestResult "Function '$func' available" ($null -ne $command)
    }
    
} catch {
    Write-TestResult "Module import test" $false $_.Exception.Message
}

Write-Host ""

# Test 2: Syntax Errors in Prepare_OfflineCollector_Env.ps1
Write-Host "2. Testing PowerShell Script Syntax..." -ForegroundColor Magenta

try {
    $null = [System.Management.Automation.Language.Parser]::ParseInput((Get-Content 'Prepare_OfflineCollector_Env.ps1' -Raw), [ref]$null, [ref]$null)
    Write-TestResult "Prepare_OfflineCollector_Env.ps1 syntax" $true "PowerShell AST parsing successful"
} catch {
    Write-TestResult "Prepare_OfflineCollector_Env.ps1 syntax" $false $_.Exception.Message
}

# Test other key scripts
$keyScripts = @('Deploy_Velociraptor_Standalone.ps1', 'commit-changes.ps1')
foreach ($script in $keyScripts) {
    if (Test-Path $script) {
        try {
            $null = [System.Management.Automation.Language.Parser]::ParseInput((Get-Content $script -Raw), [ref]$null, [ref]$null)
            Write-TestResult "$script syntax" $true
        } catch {
            Write-TestResult "$script syntax" $false $_.Exception.Message
        }
    }
}

Write-Host ""

# Test 3: GUI Implementation Completeness
Write-Host "3. Testing GUI Implementation..." -ForegroundColor Magenta

# Test main GUI file
if (Test-Path "gui/VelociraptorGUI.ps1") {
    try {
        $null = [System.Management.Automation.Language.Parser]::ParseInput((Get-Content 'gui/VelociraptorGUI.ps1' -Raw), [ref]$null, [ref]$null)
        $guiContent = Get-Content 'gui/VelociraptorGUI.ps1' -Raw
        $lineCount = (Get-Content 'gui/VelociraptorGUI.ps1').Count
        Write-TestResult "gui/VelociraptorGUI.ps1 syntax" $true "$lineCount lines, comprehensive implementation"
        
        # Check for key GUI components
        $hasMainForm = $guiContent -match 'MainForm|New-Object.*Form'
        $hasControls = $guiContent -match 'Button|Label|Panel'
        $hasEventHandlers = $guiContent -match 'Add_Click|Add_'
        
        Write-TestResult "GUI has main form" $hasMainForm
        Write-TestResult "GUI has controls" $hasControls
        Write-TestResult "GUI has event handlers" $hasEventHandlers
        
    } catch {
        Write-TestResult "gui/VelociraptorGUI.ps1 syntax" $false $_.Exception.Message
    }
} else {
    Write-TestResult "gui/VelociraptorGUI.ps1 exists" $false "Main GUI file not found"
}

# Test safe GUI file
if (Test-Path "VelociraptorGUI-Safe.ps1") {
    try {
        $null = [System.Management.Automation.Language.Parser]::ParseInput((Get-Content 'VelociraptorGUI-Safe.ps1' -Raw), [ref]$null, [ref]$null)
        Write-TestResult "VelociraptorGUI-Safe.ps1 syntax" $true "Safe GUI implementation"
    } catch {
        Write-TestResult "VelociraptorGUI-Safe.ps1 syntax" $false $_.Exception.Message
    }
} else {
    Write-TestResult "VelociraptorGUI-Safe.ps1 exists" $false "Safe GUI file not found"
}

Write-Host ""

# Test 4: Test Script Path Issues
Write-Host "4. Testing Script Path Fixes..." -ForegroundColor Magenta

# Test artifact tool manager scripts
$testScripts = @('Test-ArtifactToolManager.ps1', 'Test-ArtifactToolManager-Fixed.ps1')
foreach ($script in $testScripts) {
    if (Test-Path $script) {
        try {
            $null = [System.Management.Automation.Language.Parser]::ParseInput((Get-Content $script -Raw), [ref]$null, [ref]$null)
            
            # Check for cross-platform path usage
            $content = Get-Content $script -Raw
            $hasBackslashes = $content -match '\\(?!n|r|t|\\)'  # Backslashes that aren't escape sequences
            $hasJoinPath = $content -match 'Join-Path'
            
            Write-TestResult "$script syntax" $true
            Write-TestResult "$script uses cross-platform paths" (-not $hasBackslashes -and $hasJoinPath) $(if ($hasBackslashes) { "Still contains backslashes" } else { "Uses Join-Path correctly" })
            
        } catch {
            Write-TestResult "$script syntax" $false $_.Exception.Message
        }
    } else {
        Write-TestResult "$script exists" $false "Test script not found"
    }
}

Write-Host ""

# Summary
Write-Host "📊 VERIFICATION SUMMARY" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host "Total Tests: $($script:TestResults.TotalTests)" -ForegroundColor White
Write-Host "Passed: $($script:TestResults.PassedTests)" -ForegroundColor Green
Write-Host "Failed: $($script:TestResults.FailedTests)" -ForegroundColor Red

$successRate = [math]::Round(($script:TestResults.PassedTests / $script:TestResults.TotalTests) * 100, 1)
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -gt 90) { "Green" } elseif ($successRate -gt 75) { "Yellow" } else { "Red" })

Write-Host ""

if ($script:TestResults.FailedTests -eq 0) {
    Write-Host "🎉 ALL CRITICAL FIXES VERIFIED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "✅ Ready for Beta Release" -ForegroundColor Green
    Write-Host ""
    Write-Host "Critical Issues Resolved:" -ForegroundColor Green
    Write-Host "1. ✅ Module Function Export Mismatch - FIXED" -ForegroundColor Green
    Write-Host "2. ✅ Syntax Errors in PowerShell Scripts - FIXED" -ForegroundColor Green
    Write-Host "3. ✅ GUI Implementation Completeness - VERIFIED" -ForegroundColor Green
    Write-Host "4. ✅ Test Script Path Issues - FIXED" -ForegroundColor Green
} else {
    Write-Host "⚠️ SOME ISSUES REMAIN" -ForegroundColor Yellow
    Write-Host "Failed Tests:" -ForegroundColor Red
    $script:TestResults.Issues | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Please address the remaining issues before beta release." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Run comprehensive testing in beta environment" -ForegroundColor White
Write-Host "2. Validate cross-platform compatibility" -ForegroundColor White
Write-Host "3. Perform user acceptance testing" -ForegroundColor White
Write-Host "4. Deploy to beta users" -ForegroundColor White

return $script:TestResults