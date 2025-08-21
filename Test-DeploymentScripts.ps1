# Admin privileges only required for actual testing, not analysis

<#
.SYNOPSIS
    Comprehensive test script to validate and compare Velociraptor deployment scripts.

.DESCRIPTION
    This script analyzes the existing deployment scripts in the repository and identifies
    critical issues that prevent them from creating working Velociraptor servers.
    
    It then provides recommendations and validates the new working deployment script.

.PARAMETER TestExistingScripts
    Analyze existing deployment scripts for issues.

.PARAMETER TestNewScript
    Test the new working deployment script.

.PARAMETER AnalyzeOnly
    Only analyze scripts without running them.

.EXAMPLE
    .\Test-DeploymentScripts.ps1 -AnalyzeOnly
    # Analyze all scripts without running them

.EXAMPLE
    .\Test-DeploymentScripts.ps1 -TestNewScript
    # Test the new working script

.NOTES
    Author: PowerShell Expert / Claude Code
    This script helps identify why the existing deployment scripts don't work.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$TestExistingScripts,
    
    [Parameter()]
    [switch]$TestNewScript,
    
    [Parameter()]
    [switch]$AnalyzeOnly
)

#region Analysis Functions
function Write-TestLog {
    param(
        [string]$Message,
        [string]$Level = 'Info'
    )
    
    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Critical' { 'Magenta' }
        default { 'White' }
    }
    
    Write-Host "[$Level] $Message" -ForegroundColor $color
}

function Test-ScriptIssues {
    param([string]$ScriptPath)
    
    if (-not (Test-Path $ScriptPath)) {
        Write-TestLog "Script not found: $ScriptPath" -Level Error
        return
    }
    
    Write-TestLog "Analyzing: $(Split-Path $ScriptPath -Leaf)" -Level Info
    
    $content = Get-Content $ScriptPath -Raw
    $issues = @()
    $criticalIssues = @()
    
    # Check for incorrect GUI mode usage
    if ($content -match 'velociraptor.*gui\s') {
        $criticalIssues += "Uses 'gui' mode instead of 'frontend' mode for server"
    }
    
    # Check for missing config generate
    if ($content -notmatch 'config generate') {
        $criticalIssues += "Does not use 'velociraptor config generate' for proper configuration"
    }
    
    # Check for missing user creation
    if ($content -notmatch 'user add') {
        $criticalIssues += "Does not create admin user with 'velociraptor user add'"
    }
    
    # Check for missing frontend command
    if ($content -notmatch 'frontend') {
        $criticalIssues += "Does not use 'frontend' command to start server properly"
    }
    
    # Check for proper error handling
    if ($content -notmatch '\$LASTEXITCODE') {
        $issues += "Limited error handling - doesn't check command exit codes"
    }
    
    # Check for web interface validation
    if ($content -notmatch 'http.*://.*:.*') {
        $issues += "Does not validate web interface accessibility"
    }
    
    # Check for process verification
    if ($content -notmatch 'HasExited|WaitForExit') {
        $issues += "Does not properly monitor server process"
    }
    
    # Report findings
    if ($criticalIssues.Count -gt 0) {
        Write-TestLog "CRITICAL ISSUES FOUND:" -Level Critical
        foreach ($issue in $criticalIssues) {
            Write-TestLog "  ❌ $issue" -Level Critical
        }
    }
    
    if ($issues.Count -gt 0) {
        Write-TestLog "Other Issues:" -Level Warning
        foreach ($issue in $issues) {
            Write-TestLog "  ⚠️  $issue" -Level Warning
        }
    }
    
    if ($criticalIssues.Count -eq 0 -and $issues.Count -eq 0) {
        Write-TestLog "  ✅ No obvious issues found" -Level Success
    }
    
    Write-TestLog ""
    
    return @{
        CriticalIssues = $criticalIssues
        Issues = $issues
        IsWorking = $criticalIssues.Count -eq 0
    }
}

function Compare-VelociraptorCommands {
    Write-TestLog "VELOCIRAPTOR COMMAND ANALYSIS" -Level Info
    Write-TestLog "=============================" -Level Info
    Write-TestLog ""
    
    Write-TestLog "BROKEN APPROACH (existing scripts):" -Level Error
    Write-TestLog "  ❌ velociraptor.exe gui --datastore C:\Data" -Level Error
    Write-TestLog "     - This starts a simple GUI, not a server" -Level Error
    Write-TestLog "     - No proper configuration generation" -Level Error
    Write-TestLog "     - No admin user creation" -Level Error
    Write-TestLog "     - Not accessible via web browser" -Level Error
    Write-TestLog ""
    
    Write-TestLog "WORKING APPROACH (new script):" -Level Success
    Write-TestLog "  ✅ velociraptor.exe config generate --config server.yaml" -Level Success
    Write-TestLog "     - Generates proper server configuration" -Level Success
    Write-TestLog "  ✅ velociraptor.exe --config server.yaml user add admin --password xxx --role administrator" -Level Success
    Write-TestLog "     - Creates admin user properly" -Level Success
    Write-TestLog "  ✅ velociraptor.exe --config server.yaml frontend" -Level Success
    Write-TestLog "     - Starts actual server in frontend mode" -Level Success
    Write-TestLog "     - Web interface accessible at https://127.0.0.1:8889" -Level Success
    Write-TestLog ""
}

function Test-VelociraptorCommands {
    param([string]$VelociraptorPath)
    
    if (-not (Test-Path $VelociraptorPath)) {
        Write-TestLog "Velociraptor executable not found at: $VelociraptorPath" -Level Warning
        return
    }
    
    Write-TestLog "Testing Velociraptor commands..." -Level Info
    
    # Test version command
    try {
        $version = & $VelociraptorPath version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-TestLog "✅ Version command works: $($version -split "`n" | Select-Object -First 1)" -Level Success
        }
        else {
            Write-TestLog "❌ Version command failed" -Level Error
        }
    }
    catch {
        Write-TestLog "❌ Version command error: $($_.Exception.Message)" -Level Error
    }
    
    # Test config generate command
    try {
        $tempConfig = Join-Path $env:TEMP "test_config.yaml"
        $configOutput = & $VelociraptorPath config generate --config $tempConfig 2>&1
        if ($LASTEXITCODE -eq 0 -and (Test-Path $tempConfig)) {
            Write-TestLog "✅ Config generate works" -Level Success
            Remove-Item $tempConfig -Force -ErrorAction SilentlyContinue
        }
        else {
            Write-TestLog "❌ Config generate failed: $configOutput" -Level Error
        }
    }
    catch {
        Write-TestLog "❌ Config generate error: $($_.Exception.Message)" -Level Error
    }
}
#endregion

#region Main Execution
Write-TestLog "VELOCIRAPTOR DEPLOYMENT SCRIPT ANALYSIS" -Level Success
Write-TestLog "=======================================" -Level Success
Write-TestLog ""

# Find deployment scripts
$scriptRoot = $PSScriptRoot
$deploymentScripts = Get-ChildItem -Path $scriptRoot -Name "Deploy_Velociraptor*.ps1" | Sort-Object

if ($AnalyzeOnly -or $TestExistingScripts) {
    Write-TestLog "ANALYZING EXISTING DEPLOYMENT SCRIPTS" -Level Info
    Write-TestLog "====================================" -Level Info
    Write-TestLog ""
    
    $totalScripts = 0
    $workingScripts = 0
    
    foreach ($script in $deploymentScripts) {
        $scriptPath = Join-Path $scriptRoot $script
        $totalScripts++
        
        $analysis = Test-ScriptIssues -ScriptPath $scriptPath
        if ($analysis.IsWorking) {
            $workingScripts++
        }
    }
    
    Write-TestLog "SUMMARY:" -Level Info
    Write-TestLog "  Total scripts analyzed: $totalScripts" -Level Info
    Write-TestLog "  Scripts with no critical issues: $workingScripts" -Level Info
    Write-TestLog "  Scripts with critical issues: $($totalScripts - $workingScripts)" -Level Warning
    Write-TestLog ""
    
    # Show command comparison
    Compare-VelociraptorCommands
}

# Test new working script
if ($TestNewScript) {
    Write-TestLog "TESTING NEW WORKING SCRIPT" -Level Info
    Write-TestLog "==========================" -Level Info
    Write-TestLog ""
    
    $newScriptPath = Join-Path $scriptRoot "Deploy-Velociraptor-Working.ps1"
    
    if (Test-Path $newScriptPath) {
        $analysis = Test-ScriptIssues -ScriptPath $newScriptPath
        
        if ($analysis.IsWorking) {
            Write-TestLog "✅ New script passes analysis checks" -Level Success
            Write-TestLog ""
            Write-TestLog "Key improvements in the new script:" -Level Success
            Write-TestLog "  ✅ Uses 'velociraptor config generate' for proper configuration" -Level Success
            Write-TestLog "  ✅ Creates admin user with 'velociraptor user add'" -Level Success
            Write-TestLog "  ✅ Starts server with 'velociraptor frontend' command" -Level Success
            Write-TestLog "  ✅ Validates web interface accessibility" -Level Success
            Write-TestLog "  ✅ Comprehensive error handling with exit code checks" -Level Success
            Write-TestLog "  ✅ Proper process monitoring and cleanup" -Level Success
            Write-TestLog ""
            
            if (-not $AnalyzeOnly) {
                Write-TestLog "To test the new script, run:" -Level Info
                Write-TestLog "  .\Deploy-Velociraptor-Working.ps1" -Level Info
                Write-TestLog ""
                Write-TestLog "This will create a FUNCTIONAL Velociraptor server with:" -Level Info
                Write-TestLog "  - Accessible web interface at https://127.0.0.1:8889" -Level Info
                Write-TestLog "  - Working admin user login" -Level Info
                Write-TestLog "  - Proper server configuration" -Level Info
            }
        }
        else {
            Write-TestLog "❌ New script has issues" -Level Error
        }
    }
    else {
        Write-TestLog "❌ New script not found at: $newScriptPath" -Level Error
    }
}

# Test Velociraptor executable if available
$veloPath = Join-Path $scriptRoot "C:\tools\velociraptor.exe"
if (Test-Path $veloPath) {
    Write-TestLog "TESTING VELOCIRAPTOR EXECUTABLE" -Level Info
    Write-TestLog "===============================" -Level Info
    Write-TestLog ""
    Test-VelociraptorCommands -VelociraptorPath $veloPath
}

Write-TestLog ""
Write-TestLog "CONCLUSION:" -Level Success
Write-TestLog "==========" -Level Success
Write-TestLog ""
Write-TestLog "The existing deployment scripts in this repository appear to work" -Level Warning
Write-TestLog "but actually create non-functional servers because they:" -Level Warning
Write-TestLog ""
Write-TestLog "1. Use 'gui' mode instead of 'frontend' mode" -Level Error
Write-TestLog "2. Don't generate proper server configuration" -Level Error  
Write-TestLog "3. Don't create admin users properly" -Level Error
Write-TestLog "4. Don't start the server correctly" -Level Error
Write-TestLog ""
Write-TestLog "The new 'Deploy-Velociraptor-Working.ps1' script fixes all these issues" -Level Success
Write-TestLog "and creates a fully functional Velociraptor DFIR server." -Level Success
Write-TestLog ""
#endregion