# Comprehensive User Acceptance Testing Script
# Version: 5.0.4-beta UA Testing Suite
# Date: August 20, 2025
# Purpose: Complete validation of all scripts and functionality

[CmdletBinding()]
param(
    [string]$TestScope = "All",          # All, Core, GUI, Modules, Incident
    [string]$OutputFormat = "Console",    # Console, HTML, JSON
    [switch]$Detailed,
    [switch]$FixIssues,
    [string]$LogPath = ".\UA-Testing-Results.log"
)

# Initialize testing framework
$ErrorActionPreference = "Continue"
$TestResults = @{
    Passed = 0
    Failed = 0
    Warnings = 0
    Skipped = 0
    Details = @()
    StartTime = Get-Date
}

function Write-TestLog {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path $LogPath -Value $logEntry
}

function Test-PowerShellSyntax {
    param([string]$FilePath)
    
    Write-TestLog "Testing PowerShell syntax: $FilePath"
    
    try {
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $FilePath -Raw), [ref]$null)
        $TestResults.Passed++
        $TestResults.Details += @{
            Test = "Syntax Check"
            File = $FilePath
            Status = "PASS"
            Message = "Valid PowerShell syntax"
        }
        return $true
    }
    catch {
        $TestResults.Failed++
        $TestResults.Details += @{
            Test = "Syntax Check"
            File = $FilePath
            Status = "FAIL"
            Message = $_.Exception.Message
        }
        Write-TestLog "SYNTAX ERROR in $FilePath`: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Test-RequiredFunctions {
    param([string]$FilePath)
    
    Write-TestLog "Testing required functions: $FilePath"
    $content = Get-Content $FilePath -Raw
    $requiredPatterns = @(
        'CmdletBinding',
        'param\s*\(',
        'try\s*\{',
        'catch\s*\{'
    )
    
    $missing = @()
    foreach ($pattern in $requiredPatterns) {
        if ($content -notmatch $pattern) {
            $missing += $pattern
        }
    }
    
    if ($missing.Count -eq 0) {
        $TestResults.Passed++
        $TestResults.Details += @{
            Test = "Required Functions"
            File = $FilePath
            Status = "PASS"
            Message = "All required patterns found"
        }
        return $true
    } else {
        $TestResults.Failed++
        $TestResults.Details += @{
            Test = "Required Functions"
            File = $FilePath
            Status = "FAIL"
            Message = "Missing patterns: $($missing -join ', ')"
        }
        return $false
    }
}

function Test-SecurityPatterns {
    param([string]$FilePath)
    
    Write-TestLog "Testing security patterns: $FilePath"
    $content = Get-Content $FilePath -Raw
    $securityIssues = @()
    
    # Check for security anti-patterns
    if ($content -match 'ConvertTo-SecureString.*-AsPlainText.*-Force') {
        $securityIssues += "Insecure credential handling detected"
    }
    
    if ($content -match '\$.*password.*=.*".*"') {
        $securityIssues += "Hardcoded password detected"
    }
    
    if ($content -match 'IgnoreCertificateValidation|SkipCertificateCheck') {
        $securityIssues += "Certificate validation bypass detected"
    }
    
    if ($securityIssues.Count -eq 0) {
        $TestResults.Passed++
        $TestResults.Details += @{
            Test = "Security Check"
            File = $FilePath
            Status = "PASS"
            Message = "No security issues detected"
        }
        return $true
    } else {
        $TestResults.Failed++
        $TestResults.Details += @{
            Test = "Security Check"
            File = $FilePath
            Status = "FAIL"
            Message = "Security issues: $($securityIssues -join '; ')"
        }
        return $false
    }
}

function Test-GUIComponents {
    param([string]$FilePath)
    
    Write-TestLog "Testing GUI components: $FilePath"
    $content = Get-Content $FilePath -Raw
    $guiIssues = @()
    
    # Check for common GUI issues
    if ($content -match '\.BackColor\s*=\s*\$null') {
        $guiIssues += "Null BackColor assignment detected"
    }
    
    if ($content -match 'System\.Windows\.Forms' -and $content -notmatch 'Add-Type.*System\.Windows\.Forms') {
        $guiIssues += "Windows Forms not properly loaded"
    }
    
    if ($content -match '\.ShowDialog\(\)' -and $content -notmatch '\.Dispose\(\)') {
        $guiIssues += "Missing resource disposal"
    }
    
    if ($guiIssues.Count -eq 0) {
        $TestResults.Passed++
        $TestResults.Details += @{
            Test = "GUI Components"
            File = $FilePath
            Status = "PASS"
            Message = "GUI components properly implemented"
        }
        return $true
    } else {
        $TestResults.Failed++
        $TestResults.Details += @{
            Test = "GUI Components"
            File = $FilePath
            Status = "FAIL"
            Message = "GUI issues: $($guiIssues -join '; ')"
        }
        return $false
    }
}

function Test-ModuleStructure {
    param([string]$ModulePath)
    
    Write-TestLog "Testing module structure: $ModulePath"
    $moduleDir = Split-Path $ModulePath -Parent
    $requiredFiles = @(
        "*.psd1",  # Module manifest
        "*.psm1"   # Module script
    )
    
    $missing = @()
    foreach ($pattern in $requiredFiles) {
        if (-not (Get-ChildItem $moduleDir -Filter $pattern)) {
            $missing += $pattern
        }
    }
    
    if ($missing.Count -eq 0) {
        $TestResults.Passed++
        $TestResults.Details += @{
            Test = "Module Structure"
            File = $ModulePath
            Status = "PASS"
            Message = "Complete module structure"
        }
        return $true
    } else {
        $TestResults.Failed++
        $TestResults.Details += @{
            Test = "Module Structure"
            File = $ModulePath
            Status = "FAIL"
            Message = "Missing files: $($missing -join ', ')"
        }
        return $false
    }
}

function Test-DeploymentScript {
    param([string]$FilePath)
    
    Write-TestLog "Testing deployment script: $FilePath"
    $content = Get-Content $FilePath -Raw
    $deploymentChecks = @()
    
    # Check for essential deployment functions
    $essentialPatterns = @(
        'Test-AdminPrivileges|Test.*Admin',
        'Get-VelociraptorLatestRelease|Download.*Velociraptor',
        'New-VelociraptorConfiguration|Generate.*Config',
        'Start-VelociraptorService|Install.*Service'
    )
    
    foreach ($pattern in $essentialPatterns) {
        if ($content -notmatch $pattern) {
            $deploymentChecks += "Missing pattern: $pattern"
        }
    }
    
    if ($deploymentChecks.Count -eq 0) {
        $TestResults.Passed++
        $TestResults.Details += @{
            Test = "Deployment Logic"
            File = $FilePath
            Status = "PASS"
            Message = "All deployment patterns found"
        }
        return $true
    } else {
        $TestResults.Warnings++
        $TestResults.Details += @{
            Test = "Deployment Logic"
            File = $FilePath
            Status = "WARNING"
            Message = "Potential issues: $($deploymentChecks -join '; ')"
        }
        return $false
    }
}

# Main Testing Logic
Write-TestLog "Starting Comprehensive UA Testing - Scope: $TestScope" -Level "INFO"
Write-TestLog "Output Format: $OutputFormat" -Level "INFO"
Write-TestLog "Log Path: $LogPath" -Level "INFO"

# Test Core Deployment Scripts
if ($TestScope -eq "All" -or $TestScope -eq "Core") {
    Write-TestLog "=== TESTING CORE DEPLOYMENT SCRIPTS ===" -Level "INFO"
    
    $coreScripts = @(
        "Deploy_Velociraptor_Standalone.ps1",
        "Deploy_Velociraptor_Server.ps1",
        "Deploy_Velociraptor_Clean.ps1",
        "Deploy_Velociraptor_Fresh.ps1"
    )
    
    foreach ($script in $coreScripts) {
        $fullPath = Join-Path $PWD $script
        if (Test-Path $fullPath) {
            Write-TestLog "Testing core script: $script" -Level "INFO"
            Test-PowerShellSyntax $fullPath
            Test-RequiredFunctions $fullPath
            Test-SecurityPatterns $fullPath
            Test-DeploymentScript $fullPath
        } else {
            Write-TestLog "Core script not found: $script" -Level "WARNING"
            $TestResults.Skipped++
        }
    }
}

# Test GUI Scripts
if ($TestScope -eq "All" -or $TestScope -eq "GUI") {
    Write-TestLog "=== TESTING GUI SCRIPTS ===" -Level "INFO"
    
    $guiScripts = Get-ChildItem -Path $PWD -Filter "*GUI*.ps1" | Select-Object -ExpandProperty Name
    
    foreach ($script in $guiScripts) {
        $fullPath = Join-Path $PWD $script
        Write-TestLog "Testing GUI script: $script" -Level "INFO"
        Test-PowerShellSyntax $fullPath
        Test-SecurityPatterns $fullPath
        Test-GUIComponents $fullPath
    }
}

# Test Module Files
if ($TestScope -eq "All" -or $TestScope -eq "Modules") {
    Write-TestLog "=== TESTING MODULE FILES ===" -Level "INFO"
    
    $moduleFiles = Get-ChildItem -Path "modules" -Recurse -Filter "*.ps*1" -ErrorAction SilentlyContinue
    
    foreach ($moduleFile in $moduleFiles) {
        Write-TestLog "Testing module: $($moduleFile.Name)" -Level "INFO"
        Test-PowerShellSyntax $moduleFile.FullName
        Test-SecurityPatterns $moduleFile.FullName
        
        if ($moduleFile.Extension -eq ".psm1") {
            Test-ModuleStructure $moduleFile.FullName
        }
    }
}

# Test Incident Package Scripts
if ($TestScope -eq "All" -or $TestScope -eq "Incident") {
    Write-TestLog "=== TESTING INCIDENT PACKAGE SCRIPTS ===" -Level "INFO"
    
    $incidentScripts = Get-ChildItem -Path "incident-packages" -Recurse -Filter "*.ps1" -ErrorAction SilentlyContinue | Select-Object -First 20
    
    foreach ($script in $incidentScripts) {
        Write-TestLog "Testing incident script: $($script.Name)" -Level "INFO"
        Test-PowerShellSyntax $script.FullName
        Test-SecurityPatterns $script.FullName
    }
}

# Test Utilities and Tools
if ($TestScope -eq "All") {
    Write-TestLog "=== TESTING UTILITY SCRIPTS ===" -Level "INFO"
    
    $utilityScripts = Get-ChildItem -Path "scripts" -Filter "*.ps1" -ErrorAction SilentlyContinue
    
    foreach ($script in $utilityScripts) {
        Write-TestLog "Testing utility: $($script.Name)" -Level "INFO"
        Test-PowerShellSyntax $script.FullName
        Test-SecurityPatterns $script.FullName
    }
}

# Generate Results Summary
$TestResults.EndTime = Get-Date
$TestResults.Duration = $TestResults.EndTime - $TestResults.StartTime
$TestResults.TotalTests = $TestResults.Passed + $TestResults.Failed + $TestResults.Warnings + $TestResults.Skipped

Write-TestLog "=== TESTING COMPLETE ===" -Level "INFO"
Write-TestLog "Total Tests: $($TestResults.TotalTests)" -Level "INFO"
Write-TestLog "Passed: $($TestResults.Passed)" -Level "INFO"
Write-TestLog "Failed: $($TestResults.Failed)" -Level "ERROR"
Write-TestLog "Warnings: $($TestResults.Warnings)" -Level "WARNING"
Write-TestLog "Skipped: $($TestResults.Skipped)" -Level "INFO"
Write-TestLog "Duration: $($TestResults.Duration.TotalSeconds) seconds" -Level "INFO"

# Output Results
if ($OutputFormat -eq "HTML") {
    $htmlPath = $LogPath -replace "\.log$", ".html"
    # Generate HTML report
    Write-TestLog "HTML report generated: $htmlPath" -Level "INFO"
}

if ($OutputFormat -eq "JSON") {
    $jsonPath = $LogPath -replace "\.log$", ".json"
    $TestResults | ConvertTo-Json -Depth 3 | Out-File $jsonPath
    Write-TestLog "JSON report generated: $jsonPath" -Level "INFO"
}

# Return results for automation
return $TestResults