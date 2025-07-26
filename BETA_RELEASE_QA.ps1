#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Comprehensive Beta Release Quality Assurance Testing Suite

.DESCRIPTION
    This script performs exhaustive testing of all PowerShell scripts, modules, 
    shell scripts, and configurations to ensure beta release readiness.

.EXAMPLE
    .\BETA_RELEASE_QA.ps1 -Verbose
#>

[CmdletBinding()]
param(
    [switch]$SkipSlowTests,
    [switch]$GenerateReport,
    [string]$OutputPath = "BETA_QA_REPORT.md"
)

# Initialize results tracking
$script:TestResults = @{
    PowerShellScripts = @()
    ShellScripts = @()
    Modules = @()
    Configurations = @()
    GUI = @()
    Integration = @()
    Security = @()
    Performance = @()
    Summary = @{
        TotalTests = 0
        PassedTests = 0
        FailedTests = 0
        WarningTests = 0
        CriticalIssues = @()
        Recommendations = @()
    }
}

# Color coding for output
function Write-TestResult {
    param(
        [string]$Message,
        [ValidateSet("PASS", "FAIL", "WARN", "INFO")]
        [string]$Status,
        [string]$Details = ""
    )
    
    $color = switch ($Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARN" { "Yellow" }
        "INFO" { "Cyan" }
    }
    
    Write-Host "[$Status] $Message" -ForegroundColor $color
    if ($Details) {
        Write-Host "    $Details" -ForegroundColor Gray
    }
    
    $script:TestResults.Summary.TotalTests++
    switch ($Status) {
        "PASS" { $script:TestResults.Summary.PassedTests++ }
        "FAIL" { 
            $script:TestResults.Summary.FailedTests++
            $script:TestResults.Summary.CriticalIssues += $Message
        }
        "WARN" { $script:TestResults.Summary.WarningTests++ }
    }
}

# Test PowerShell script syntax and basic functionality
function Test-PowerShellScript {
    param([string]$ScriptPath)
    
    $result = @{
        Path = $ScriptPath
        SyntaxValid = $false
        HasHelpContent = $false
        HasErrorHandling = $false
        UsesApprovedVerbs = $true
        Issues = @()
    }
    
    try {
        # Test syntax
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $ScriptPath -Raw), [ref]$null)
        $result.SyntaxValid = $true
        Write-TestResult "Syntax validation for $ScriptPath" "PASS"
    }
    catch {
        $result.Issues += "Syntax Error: $($_.Exception.Message)"
        Write-TestResult "Syntax validation for $ScriptPath" "FAIL" $_.Exception.Message
    }
    
    # Check for help content
    $content = Get-Content $ScriptPath -Raw
    if ($content -match '\.SYNOPSIS|\.DESCRIPTION|\.EXAMPLE') {
        $result.HasHelpContent = $true
        Write-TestResult "Help content in $ScriptPath" "PASS"
    }
    else {
        $result.Issues += "Missing help documentation"
        Write-TestResult "Help content in $ScriptPath" "WARN" "Missing .SYNOPSIS, .DESCRIPTION, or .EXAMPLE"
    }
    
    # Check for error handling
    if ($content -match 'try\s*\{|catch\s*\{|trap\s*\{') {
        $result.HasErrorHandling = $true
        Write-TestResult "Error handling in $ScriptPath" "PASS"
    }
    else {
        $result.Issues += "Limited error handling"
        Write-TestResult "Error handling in $ScriptPath" "WARN" "No try-catch blocks found"
    }
    
    # Check for unapproved verbs in function names
    $functions = [regex]::Matches($content, 'function\s+([A-Za-z]+-[A-Za-z]+)')
    foreach ($match in $functions) {
        $functionName = $match.Groups[1].Value
        $verb = $functionName.Split('-')[0]
        if ($verb -notin (Get-Verb).Verb) {
            $result.UsesApprovedVerbs = $false
            $result.Issues += "Unapproved verb: $verb in $functionName"
            Write-TestResult "PowerShell verb compliance in $ScriptPath" "WARN" "Unapproved verb: $verb"
        }
    }
    
    $script:TestResults.PowerShellScripts += $result
    return $result
}

# Test shell script syntax and functionality
function Test-ShellScript {
    param([string]$ScriptPath)
    
    $result = @{
        Path = $ScriptPath
        SyntaxValid = $false
        HasShebang = $false
        HasErrorHandling = $false
        Issues = @()
    }
    
    try {
        # Check for shebang
        $firstLine = (Get-Content $ScriptPath -TotalCount 1)
        if ($firstLine -match '^#!/') {
            $result.HasShebang = $true
            Write-TestResult "Shebang in $ScriptPath" "PASS"
        }
        else {
            $result.Issues += "Missing shebang line"
            Write-TestResult "Shebang in $ScriptPath" "WARN" "Missing #!/bin/bash or similar"
        }
        
        # Basic syntax check (if bash is available)
        if (Get-Command bash -ErrorAction SilentlyContinue) {
            $syntaxCheck = bash -n $ScriptPath 2>&1
            if ($LASTEXITCODE -eq 0) {
                $result.SyntaxValid = $true
                Write-TestResult "Shell syntax for $ScriptPath" "PASS"
            }
            else {
                $result.Issues += "Syntax errors: $syntaxCheck"
                Write-TestResult "Shell syntax for $ScriptPath" "FAIL" $syntaxCheck
            }
        }
        else {
            Write-TestResult "Shell syntax for $ScriptPath" "INFO" "Bash not available for syntax checking"
        }
        
        # Check for error handling
        $content = Get-Content $ScriptPath -Raw
        if ($content -match 'set -e|trap |if.*\$\?') {
            $result.HasErrorHandling = $true
            Write-TestResult "Error handling in $ScriptPath" "PASS"
        }
        else {
            $result.Issues += "Limited error handling"
            Write-TestResult "Error handling in $ScriptPath" "WARN" "No error handling patterns found"
        }
    }
    catch {
        $result.Issues += "Test error: $($_.Exception.Message)"
        Write-TestResult "Shell script test for $ScriptPath" "FAIL" $_.Exception.Message
    }
    
    $script:TestResults.ShellScripts += $result
    return $result
}

# Test PowerShell module structure and functionality
function Test-PowerShellModule {
    param([string]$ModulePath)
    
    $result = @{
        Path = $ModulePath
        ManifestValid = $false
        FunctionsExported = $false
        ModuleLoads = $false
        Issues = @()
    }
    
    try {
        # Test module manifest
        $manifestPath = Get-ChildItem $ModulePath -Filter "*.psd1" | Select-Object -First 1
        if ($manifestPath) {
            $manifest = Test-ModuleManifest $manifestPath.FullName -ErrorAction Stop
            $result.ManifestValid = $true
            Write-TestResult "Module manifest for $ModulePath" "PASS"
            
            # Check if functions are properly exported
            if ($manifest.ExportedFunctions.Count -gt 0) {
                $result.FunctionsExported = $true
                Write-TestResult "Function exports for $ModulePath" "PASS" "$($manifest.ExportedFunctions.Count) functions exported"
            }
            else {
                $result.Issues += "No functions exported"
                Write-TestResult "Function exports for $ModulePath" "WARN" "No functions exported in manifest"
            }
        }
        else {
            $result.Issues += "No module manifest found"
            Write-TestResult "Module manifest for $ModulePath" "FAIL" "No .psd1 file found"
        }
        
        # Test module loading
        try {
            Import-Module $ModulePath -Force -ErrorAction Stop
            $result.ModuleLoads = $true
            Write-TestResult "Module loading for $ModulePath" "PASS"
            Remove-Module (Split-Path $ModulePath -Leaf) -Force -ErrorAction SilentlyContinue
        }
        catch {
            $result.Issues += "Module loading error: $($_.Exception.Message)"
            Write-TestResult "Module loading for $ModulePath" "FAIL" $_.Exception.Message
        }
    }
    catch {
        $result.Issues += "Module test error: $($_.Exception.Message)"
        Write-TestResult "Module test for $ModulePath" "FAIL" $_.Exception.Message
    }
    
    $script:TestResults.Modules += $result
    return $result
}

# Test GUI functionality
function Test-GUIFunctionality {
    Write-Host "`n=== GUI Testing ===" -ForegroundColor Magenta
    
    $guiPath = "gui/VelociraptorGUI.ps1"
    $result = @{
        Path = $guiPath
        SyntaxValid = $false
        WindowsFormsLoads = $false
        Issues = @()
    }
    
    if (Test-Path $guiPath) {
        # Test GUI syntax
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $guiPath -Raw), [ref]$null)
            $result.SyntaxValid = $true
            Write-TestResult "GUI syntax validation" "PASS"
        }
        catch {
            $result.Issues += "GUI syntax error: $($_.Exception.Message)"
            Write-TestResult "GUI syntax validation" "FAIL" $_.Exception.Message
        }
        
        # Test Windows Forms loading
        try {
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
            Add-Type -AssemblyName System.Drawing -ErrorAction Stop
            $result.WindowsFormsLoads = $true
            Write-TestResult "Windows Forms availability" "PASS"
        }
        catch {
            $result.Issues += "Windows Forms error: $($_.Exception.Message)"
            Write-TestResult "Windows Forms availability" "FAIL" $_.Exception.Message
        }
    }
    else {
        $result.Issues += "GUI file not found"
        Write-TestResult "GUI file existence" "FAIL" "gui/VelociraptorGUI.ps1 not found"
    }
    
    $script:TestResults.GUI += $result
    return $result
}

# Test configuration files
function Test-ConfigurationFiles {
    Write-Host "`n=== Configuration Testing ===" -ForegroundColor Magenta
    
    $configPaths = @(
        "templates/configurations/*.yaml",
        "scripts/configuration-management/*.json",
        "*.psd1",
        "*.psm1"
    )
    
    foreach ($pattern in $configPaths) {
        $files = Get-ChildItem $pattern -Recurse -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            $result = @{
                Path = $file.FullName
                Valid = $false
                Issues = @()
            }
            
            try {
                switch ($file.Extension) {
                    ".yaml" {
                        # Basic YAML validation (simplified)
                        $content = Get-Content $file.FullName -Raw
                        if ($content -match '^[^:]+:' -and $content -notmatch '\t') {
                            $result.Valid = $true
                            Write-TestResult "YAML validation for $($file.Name)" "PASS"
                        }
                        else {
                            $result.Issues += "Invalid YAML format"
                            Write-TestResult "YAML validation for $($file.Name)" "WARN" "Potential YAML formatting issues"
                        }
                    }
                    ".json" {
                        $content = Get-Content $file.FullName -Raw | ConvertFrom-Json -ErrorAction Stop
                        $result.Valid = $true
                        Write-TestResult "JSON validation for $($file.Name)" "PASS"
                    }
                    ".psd1" {
                        $null = Import-PowerShellDataFile $file.FullName -ErrorAction Stop
                        $result.Valid = $true
                        Write-TestResult "PowerShell data file validation for $($file.Name)" "PASS"
                    }
                }
            }
            catch {
                $result.Issues += "Validation error: $($_.Exception.Message)"
                Write-TestResult "Configuration validation for $($file.Name)" "FAIL" $_.Exception.Message
            }
            
            $script:TestResults.Configurations += $result
        }
    }
}

# Test security baseline
function Test-SecurityBaseline {
    Write-Host "`n=== Security Testing ===" -ForegroundColor Magenta
    
    $securityIssues = @()
    
    # Check for hardcoded credentials
    $scriptFiles = Get-ChildItem "*.ps1" -Recurse
    foreach ($file in $scriptFiles) {
        $content = Get-Content $file.FullName -Raw
        if ($content -match 'password\s*=\s*["\'][^"\']+["\']|secret\s*=\s*["\'][^"\']+["\']') {
            $securityIssues += "Potential hardcoded credentials in $($file.FullName)"
            Write-TestResult "Credential check for $($file.Name)" "WARN" "Potential hardcoded credentials found"
        }
        else {
            Write-TestResult "Credential check for $($file.Name)" "PASS"
        }
    }
    
    # Check for secure communication
    $deploymentScripts = Get-ChildItem "*Deploy*.ps1"
    foreach ($script in $deploymentScripts) {
        $content = Get-Content $script.FullName -Raw
        if ($content -match 'https://|TLS|SSL') {
            Write-TestResult "Secure communication in $($script.Name)" "PASS"
        }
        else {
            Write-TestResult "Secure communication in $($script.Name)" "WARN" "No HTTPS/TLS references found"
        }
    }
    
    $script:TestResults.Security = $securityIssues
}

# Performance testing
function Test-Performance {
    if ($SkipSlowTests) {
        Write-Host "`n=== Performance Testing (Skipped) ===" -ForegroundColor Magenta
        return
    }
    
    Write-Host "`n=== Performance Testing ===" -ForegroundColor Magenta
    
    # Test module import performance
    $modules = Get-ChildItem "modules" -Directory
    foreach ($module in $modules) {
        $startTime = Get-Date
        try {
            Import-Module $module.FullName -Force -ErrorAction Stop
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            
            if ($duration -lt 2) {
                Write-TestResult "Module import performance for $($module.Name)" "PASS" "$([math]::Round($duration, 2))s"
            }
            else {
                Write-TestResult "Module import performance for $($module.Name)" "WARN" "Slow import: $([math]::Round($duration, 2))s"
            }
            
            Remove-Module $module.Name -Force -ErrorAction SilentlyContinue
        }
        catch {
            Write-TestResult "Module import performance for $($module.Name)" "FAIL" $_.Exception.Message
        }
    }
    
    $script:TestResults.Performance = @{
        ModuleImportTimes = "Measured"
        OverallPerformance = "Acceptable"
    }
}

# Generate comprehensive report
function New-QAReport {
    $report = @"
# Beta Release Quality Assurance Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Executive Summary
- **Total Tests**: $($script:TestResults.Summary.TotalTests)
- **Passed**: $($script:TestResults.Summary.PassedTests) ✅
- **Failed**: $($script:TestResults.Summary.FailedTests) ❌
- **Warnings**: $($script:TestResults.Summary.WarningTests) ⚠️
- **Success Rate**: $([math]::Round(($script:TestResults.Summary.PassedTests / $script:TestResults.Summary.TotalTests) * 100, 1))%

## Beta Release Readiness
$(if ($script:TestResults.Summary.FailedTests -eq 0) {
    "✅ **READY FOR BETA RELEASE** - All critical tests passed"
} elseif ($script:TestResults.Summary.FailedTests -lt 5) {
    "⚠️ **CONDITIONAL BETA RELEASE** - Minor issues need attention"
} else {
    "❌ **NOT READY FOR BETA RELEASE** - Critical issues must be resolved"
})

## Critical Issues
$(if ($script:TestResults.Summary.CriticalIssues.Count -gt 0) {
    $script:TestResults.Summary.CriticalIssues | ForEach-Object { "- $_" }
} else {
    "None identified ✅"
})

## PowerShell Scripts Analysis
- **Total Scripts Tested**: $($script:TestResults.PowerShellScripts.Count)
- **Syntax Valid**: $(($script:TestResults.PowerShellScripts | Where-Object SyntaxValid).Count)
- **With Help Content**: $(($script:TestResults.PowerShellScripts | Where-Object HasHelpContent).Count)
- **With Error Handling**: $(($script:TestResults.PowerShellScripts | Where-Object HasErrorHandling).Count)

## Module Analysis
- **Total Modules Tested**: $($script:TestResults.Modules.Count)
- **Valid Manifests**: $(($script:TestResults.Modules | Where-Object ManifestValid).Count)
- **Loadable Modules**: $(($script:TestResults.Modules | Where-Object ModuleLoads).Count)

## Shell Scripts Analysis
- **Total Scripts Tested**: $($script:TestResults.ShellScripts.Count)
- **With Shebang**: $(($script:TestResults.ShellScripts | Where-Object HasShebang).Count)
- **Syntax Valid**: $(($script:TestResults.ShellScripts | Where-Object SyntaxValid).Count)

## GUI Analysis
$(if ($script:TestResults.GUI.Count -gt 0) {
    "- **Syntax Valid**: $(($script:TestResults.GUI | Where-Object SyntaxValid).Count)"
    "- **Windows Forms Compatible**: $(($script:TestResults.GUI | Where-Object WindowsFormsLoads).Count)"
} else {
    "No GUI tests performed"
})

## Recommendations for Beta Release
$(if ($script:TestResults.Summary.WarningTests -gt 0) {
    "1. Address warning-level issues for improved quality"
    "2. Add missing help documentation to scripts"
    "3. Enhance error handling in scripts without try-catch blocks"
    "4. Consider performance optimizations for slow-loading modules"
} else {
    "All quality checks passed - ready for beta release!"
})

## Next Steps
1. **Address Critical Issues**: Fix any failed tests before beta release
2. **Documentation Review**: Ensure all scripts have proper help content
3. **Security Review**: Verify no hardcoded credentials or security issues
4. **Performance Testing**: Validate performance under load
5. **Integration Testing**: Test full deployment scenarios

---
*Report generated by Beta Release QA Suite v1.0*
"@

    if ($GenerateReport) {
        $report | Out-File $OutputPath -Encoding UTF8
        Write-Host "`nReport saved to: $OutputPath" -ForegroundColor Green
    }
    
    return $report
}

# Main execution
function Start-BetaQA {
    Write-Host "🚀 Starting Comprehensive Beta Release Quality Assurance" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    
    # Test PowerShell scripts
    Write-Host "`n=== PowerShell Script Testing ===" -ForegroundColor Magenta
    $psScripts = Get-ChildItem "*.ps1" -Recurse | Where-Object { $_.Name -notlike "*Test*" -and $_.Directory.Name -ne ".git" }
    foreach ($script in $psScripts) {
        Test-PowerShellScript $script.FullName
    }
    
    # Test shell scripts
    Write-Host "`n=== Shell Script Testing ===" -ForegroundColor Magenta
    $shellScripts = Get-ChildItem "*.sh" -Recurse
    foreach ($script in $shellScripts) {
        Test-ShellScript $script.FullName
    }
    
    # Test modules
    Write-Host "`n=== Module Testing ===" -ForegroundColor Magenta
    $modules = Get-ChildItem "modules" -Directory -ErrorAction SilentlyContinue
    foreach ($module in $modules) {
        Test-PowerShellModule $module.FullName
    }
    
    # Test GUI
    Test-GUIFunctionality
    
    # Test configurations
    Test-ConfigurationFiles
    
    # Test security
    Test-SecurityBaseline
    
    # Test performance
    Test-Performance
    
    # Generate report
    Write-Host "`n=== Generating Report ===" -ForegroundColor Magenta
    $report = New-QAReport
    
    # Display summary
    Write-Host "`n================================================================" -ForegroundColor Green
    Write-Host "🎯 BETA RELEASE QA SUMMARY" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "Total Tests: $($script:TestResults.Summary.TotalTests)" -ForegroundColor White
    Write-Host "Passed: $($script:TestResults.Summary.PassedTests)" -ForegroundColor Green
    Write-Host "Failed: $($script:TestResults.Summary.FailedTests)" -ForegroundColor Red
    Write-Host "Warnings: $($script:TestResults.Summary.WarningTests)" -ForegroundColor Yellow
    
    $successRate = [math]::Round(($script:TestResults.Summary.PassedTests / $script:TestResults.Summary.TotalTests) * 100, 1)
    Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -gt 90) { "Green" } elseif ($successRate -gt 75) { "Yellow" } else { "Red" })
    
    # Beta readiness assessment
    if ($script:TestResults.Summary.FailedTests -eq 0) {
        Write-Host "`n✅ READY FOR BETA RELEASE" -ForegroundColor Green
        Write-Host "All critical tests passed. Proceed with beta deployment." -ForegroundColor Green
    }
    elseif ($script:TestResults.Summary.FailedTests -lt 5) {
        Write-Host "`n⚠️ CONDITIONAL BETA RELEASE" -ForegroundColor Yellow
        Write-Host "Minor issues detected. Review and fix before beta release." -ForegroundColor Yellow
    }
    else {
        Write-Host "`n❌ NOT READY FOR BETA RELEASE" -ForegroundColor Red
        Write-Host "Critical issues must be resolved before beta deployment." -ForegroundColor Red
    }
    
    if ($script:TestResults.Summary.CriticalIssues.Count -gt 0) {
        Write-Host "`nCritical Issues:" -ForegroundColor Red
        $script:TestResults.Summary.CriticalIssues | ForEach-Object {
            Write-Host "  - $_" -ForegroundColor Red
        }
    }
    
    Write-Host "`n================================================================" -ForegroundColor Green
    
    return $report
}

# Execute the QA suite
Start-BetaQA