#!/usr/bin/env pwsh
<#
.SYNOPSIS
    🔥 Test PYRO Tool Integration System
    
.DESCRIPTION
    Comprehensive testing script for PYRO DFIR tool integration.
    Tests installation, functionality, and integration of critical tools:
    - Hayabusa (Windows Event Timeline)
    - UAC (Unix Artifacts Collector) 
    - Chainsaw (Event Log Hunter)
    - YARA (Pattern Matching)
    - Sigma (SIEM Rules)
    
.PARAMETER TestToolsuite
    Test complete toolsuite installation
    
.PARAMETER TestIndividual
    Test individual tool installations
    
.PARAMETER TestFunctionality
    Test tool functionality with sample data
    
.PARAMETER ToolsPath
    Custom tools installation path
    
.EXAMPLE
    .\Test-PyroToolIntegration.ps1 -TestToolsuite
    
.EXAMPLE
    .\Test-PyroToolIntegration.ps1 -TestIndividual -TestFunctionality
#>

[CmdletBinding()]
param(
    [switch]$TestToolsuite,
    [switch]$TestIndividual,
    [switch]$TestFunctionality,
    [string]$ToolsPath = "C:\PYRO\tools"
)

# Set error handling
$ErrorActionPreference = "Stop"

Write-Host "🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥" -ForegroundColor Red
Write-Host "🔥                                                   🔥" -ForegroundColor Red
Write-Host "🔥        PYRO TOOL INTEGRATION TESTING             🔥" -ForegroundColor Red
Write-Host "🔥           Setting Fire to DFIR Tools             🔥" -ForegroundColor Red
Write-Host "🔥                                                   🔥" -ForegroundColor Red
Write-Host "🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥" -ForegroundColor Red
Write-Host ""

# Test environment setup
function Test-Environment {
    Write-Host "🧪 Testing Environment Setup..." -ForegroundColor Yellow
    
    $checks = @{
        "PowerShell Version" = $PSVersionTable.PSVersion.Major -ge 5
        "Windows OS" = $IsWindows -or ($null -eq $IsWindows)  # PowerShell 5.1 doesn't have $IsWindows
        "Internet Connection" = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet
        "Git Available" = $null -ne (Get-Command git -ErrorAction SilentlyContinue)
        "Tools Directory Writable" = $true
    }
    
    # Test tools directory access
    try {
        $testPath = Join-Path $ToolsPath "test"
        New-Item -ItemType Directory -Path $testPath -Force | Out-Null
        Remove-Item $testPath -Force -ErrorAction SilentlyContinue
    }
    catch {
        $checks["Tools Directory Writable"] = $false
    }
    
    foreach ($check in $checks.GetEnumerator()) {
        $status = if ($check.Value) { "✅ PASS" } else { "❌ FAIL" }
        $color = if ($check.Value) { "Green" } else { "Red" }
        Write-Host "   $($check.Key): $status" -ForegroundColor $color
    }
    
    $failedChecks = ($checks.Values | Where-Object { $_ -eq $false }).Count
    if ($failedChecks -gt 0) {
        Write-Warning "$failedChecks environment checks failed. Some tests may not work properly."
    }
    
    Write-Host ""
    return $checks
}

# Test PyroSetupScripts module loading
function Test-ModuleLoading {
    Write-Host "🧪 Testing PYRO Module Loading..." -ForegroundColor Yellow
    
    try {
        # Import the PYRO module
        $modulePath = Join-Path $PSScriptRoot "PyroSetupScripts.psm1"
        if (-not (Test-Path $modulePath)) {
            throw "PyroSetupScripts.psm1 not found at: $modulePath"
        }
        
        Import-Module $modulePath -Force -Global
        Write-Host "   ✅ PyroSetupScripts module loaded successfully" -ForegroundColor Green
        
        # Test if tool integration functions are available
        $toolFunctions = @(
            "Install-PyroHayabusa",
            "Install-PyroUAC",
            "Install-PyroChainsaw", 
            "Install-PyroYARA",
            "Install-PyroSigma",
            "Install-PyroToolsuite",
            "Get-PyroToolStatus",
            "Test-PyroToolIntegration"
        )
        
        foreach ($func in $toolFunctions) {
            $command = Get-Command $func -ErrorAction SilentlyContinue
            $status = if ($command) { "✅ AVAILABLE" } else { "❌ MISSING" }
            $color = if ($command) { "Green" } else { "Red" }
            Write-Host "   $func`: $status" -ForegroundColor $color
        }
        
        Write-Host ""
        return $true
    }
    catch {
        Write-Error "❌ Failed to load PYRO module: $($_.Exception.Message)"
        return $false
    }
}

# Test individual tool installation
function Test-IndividualToolInstallation {
    Write-Host "🧪 Testing Individual Tool Installation..." -ForegroundColor Yellow
    
    $tools = @("Hayabusa", "UAC", "Chainsaw", "YARA", "Sigma")
    $results = @{}
    
    foreach ($tool in $tools) {
        Write-Host "   Installing $tool..." -ForegroundColor Cyan
        
        try {
            switch ($tool) {
                "Hayabusa" { Install-PyroHayabusa -InstallPath (Join-Path $ToolsPath "hayabusa") }
                "UAC" { Install-PyroUAC -InstallPath (Join-Path $ToolsPath "uac") }
                "Chainsaw" { Install-PyroChainsaw -InstallPath (Join-Path $ToolsPath "chainsaw") }
                "YARA" { Install-PyroYARA -InstallPath (Join-Path $ToolsPath "yara") }
                "Sigma" { Install-PyroSigma -InstallPath (Join-Path $ToolsPath "sigma") }
            }
            
            $results[$tool] = "✅ SUCCESS"
            Write-Host "     ✅ $tool installed successfully" -ForegroundColor Green
        }
        catch {
            $results[$tool] = "❌ FAILED: $($_.Exception.Message)"
            Write-Host "     ❌ $tool installation failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Start-Sleep -Seconds 1
    }
    
    Write-Host ""
    return $results
}

# Test toolsuite installation
function Test-ToolsuiteInstallation {
    Write-Host "🧪 Testing Complete Toolsuite Installation..." -ForegroundColor Yellow
    
    try {
        $results = Install-PyroToolsuite -ToolsPath $ToolsPath
        
        Write-Host ""
        Write-Host "📊 Toolsuite Installation Results:" -ForegroundColor Cyan
        foreach ($tool in $results.GetEnumerator()) {
            $color = if ($tool.Value -like "*SUCCESS*") { "Green" } else { "Red" }
            Write-Host "   $($tool.Key): $($tool.Value)" -ForegroundColor $color
        }
        
        Write-Host ""
        return $results
    }
    catch {
        Write-Error "❌ Toolsuite installation failed: $($_.Exception.Message)"
        return @{}
    }
}

# Test tool functionality
function Test-ToolFunctionality {
    Write-Host "🧪 Testing Tool Functionality..." -ForegroundColor Yellow
    
    # Run the built-in integration test
    try {
        $testResults = Test-PyroToolIntegration
        
        Write-Host ""
        Write-Host "📊 Functionality Test Results:" -ForegroundColor Cyan
        foreach ($tool in $testResults.GetEnumerator()) {
            $status = if ($tool.Value) { "✅ PASS" } else { "❌ FAIL" }
            $color = if ($tool.Value) { "Green" } else { "Red" }
            Write-Host "   $($tool.Key): $status" -ForegroundColor $color
        }
        
        Write-Host ""
        return $testResults
    }
    catch {
        Write-Error "❌ Functionality testing failed: $($_.Exception.Message)"
        return @{}
    }
}

# Test tool status reporting
function Test-ToolStatus {
    Write-Host "🧪 Testing Tool Status Reporting..." -ForegroundColor Yellow
    
    try {
        $status = Get-PyroToolStatus
        Write-Host "   ✅ Tool status retrieved successfully" -ForegroundColor Green
        return $status
    }
    catch {
        Write-Error "❌ Tool status reporting failed: $($_.Exception.Message)"
        return $null
    }
}

# Main execution
function Main {
    $startTime = Get-Date
    
    # Environment checks
    $envChecks = Test-Environment
    
    # Module loading test
    $moduleLoaded = Test-ModuleLoading
    if (-not $moduleLoaded) {
        Write-Error "Cannot continue without PYRO module. Exiting."
        return
    }
    
    $allResults = @{
        Environment = $envChecks
        ModuleLoading = $moduleLoaded
    }
    
    # Test individual tool installation
    if ($TestIndividual) {
        $allResults.IndividualInstallation = Test-IndividualToolInstallation
    }
    
    # Test complete toolsuite installation
    if ($TestToolsuite) {
        $allResults.ToolsuiteInstallation = Test-ToolsuiteInstallation
    }
    
    # Test functionality
    if ($TestFunctionality) {
        $allResults.FunctionalityTest = Test-ToolFunctionality
    }
    
    # Always test status reporting
    $allResults.ToolStatus = Test-ToolStatus
    
    # Final summary
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host "🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥" -ForegroundColor Red
    Write-Host "🔥              TESTING COMPLETE                   🔥" -ForegroundColor Red
    Write-Host "🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥" -ForegroundColor Red
    Write-Host ""
    Write-Host "⏱️ Total Duration: $($duration.TotalMinutes.ToString('F1')) minutes" -ForegroundColor Cyan
    Write-Host "📁 Tools Path: $ToolsPath" -ForegroundColor Cyan
    
    if ($allResults.ToolsuiteInstallation) {
        $successCount = ($allResults.ToolsuiteInstallation.Values | Where-Object { $_ -like "*SUCCESS*" }).Count
        $totalCount = $allResults.ToolsuiteInstallation.Count
        Write-Host "📊 Tools Installed: $successCount/$totalCount" -ForegroundColor Cyan
    }
    
    if ($allResults.FunctionalityTest) {
        $passedTests = ($allResults.FunctionalityTest.Values | Where-Object { $_ -eq $true }).Count
        $totalTests = $allResults.FunctionalityTest.Count
        Write-Host "🧪 Functionality Tests: $passedTests/$totalTests passed" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host "🔥 PYRO Tool Integration Testing Complete!" -ForegroundColor Red
    Write-Host "   Ready to set fire to DFIR operations!" -ForegroundColor Yellow
    
    return $allResults
}

# Execute based on parameters
if (-not $TestToolsuite -and -not $TestIndividual -and -not $TestFunctionality) {
    # Default: test everything
    Write-Host "🎯 No specific tests specified - running comprehensive test suite..." -ForegroundColor Cyan
    $TestToolsuite = $true
    $TestFunctionality = $true
}

# Run main function
$results = Main

# Return results for programmatic use
return $results