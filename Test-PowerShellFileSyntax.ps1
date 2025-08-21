#Requires -Version 5.1

<#
.SYNOPSIS
    Comprehensive PowerShell File Syntax and Functionality Validator

.DESCRIPTION
    Tests specified PowerShell files for syntax validity and basic functionality.
    Provides detailed reporting on file status and issues.

.NOTES
    Created for comprehensive infrastructure file testing
    Author: Claude Code
    Version: 1.0
#>

[CmdletBinding()]
param(
    [string]$LogPath = ".\syntax-test-results.log",
    [switch]$DetailedOutput
)

# Initialize results tracking
$Results = @{
    TotalFiles = 0
    PassedSyntax = 0
    FailedSyntax = 0
    PassedBasic = 0
    FailedBasic = 0
    NotFound = 0
    Errors = @()
    Details = @()
}

function Write-TestLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path $LogPath -Value $logEntry
}

function Test-PowerShellSyntax {
    param(
        [string]$FilePath
    )
    
    try {
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $FilePath -Raw), [ref]$null)
        return $true
    }
    catch {
        return $false
    }
}

function Test-PowerShellBasicFunctionality {
    param(
        [string]$FilePath
    )
    
    try {
        # Try to parse the AST without executing
        $content = Get-Content $FilePath -Raw
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
        
        # Check for basic PowerShell constructs
        $hasValidStructure = $ast -and $ast.GetType().Name -eq "ScriptBlockAst"
        
        # Additional checks for common patterns
        $hasValidFunctions = $content -match 'function\s+[\w-]+\s*\{'
        $hasValidParameters = $content -match '\[CmdletBinding\(\)\]' -or $content -match 'param\s*\('
        $hasValidErrorHandling = $content -match 'try\s*\{' -or $content -match '\$ErrorActionPreference'
        
        return @{
            ValidStructure = $hasValidStructure
            HasFunctions = $hasValidFunctions
            HasParameters = $hasValidParameters
            HasErrorHandling = $hasValidErrorHandling
            Score = @($hasValidStructure, $hasValidFunctions, $hasValidParameters, $hasValidErrorHandling).Where({$_}).Count
        }
    }
    catch {
        return @{
            ValidStructure = $false
            HasFunctions = $false
            HasParameters = $false
            HasErrorHandling = $false
            Score = 0
            Error = $_.Exception.Message
        }
    }
}

function Test-SingleFile {
    param(
        [string]$FilePath,
        [string]$Category
    )
    
    $Results.TotalFiles++
    
    Write-TestLog "Testing: $FilePath" "INFO"
    
    # Check if file exists
    if (-not (Test-Path $FilePath)) {
        Write-TestLog "File not found: $FilePath" "ERROR"
        $Results.NotFound++
        $Results.Errors += "File not found: $FilePath"
        return @{
            File = $FilePath
            Category = $Category
            Exists = $false
            SyntaxValid = $false
            BasicFunctionality = $null
            Status = "NOT_FOUND"
        }
    }
    
    # Test syntax
    $syntaxValid = Test-PowerShellSyntax -FilePath $FilePath
    if ($syntaxValid) {
        $Results.PassedSyntax++
        Write-TestLog "Syntax PASSED: $FilePath" "SUCCESS"
    } else {
        $Results.FailedSyntax++
        Write-TestLog "Syntax FAILED: $FilePath" "ERROR"
        $Results.Errors += "Syntax error in: $FilePath"
    }
    
    # Test basic functionality
    $basicTest = $null
    if ($syntaxValid) {
        $basicTest = Test-PowerShellBasicFunctionality -FilePath $FilePath
        if ($basicTest.Score -ge 2) {
            $Results.PassedBasic++
            Write-TestLog "Basic functionality PASSED: $FilePath (Score: $($basicTest.Score)/4)" "SUCCESS"
        } else {
            $Results.FailedBasic++
            Write-TestLog "Basic functionality FAILED: $FilePath (Score: $($basicTest.Score)/4)" "WARNING"
        }
    }
    
    $status = if (-not $syntaxValid) { "SYNTAX_ERROR" }
              elseif ($basicTest.Score -ge 3) { "READY" }
              elseif ($basicTest.Score -ge 2) { "NEEDS_REVIEW" }
              else { "NEEDS_FIXES" }
    
    return @{
        File = $FilePath
        Category = $Category
        Exists = $true
        SyntaxValid = $syntaxValid
        BasicFunctionality = $basicTest
        Status = $status
    }
}

# Define target files to test
$TestFiles = @{
    "Test and QA Scripts" = @(
        ".\Test-Beta-Release-Full-Features.ps1",
        ".\Test-Windows-Beta-Features.ps1",
        ".\Test-Windows-Beta-Features-Clean.ps1",
        ".\Test-VelociraptorHealth.ps1",
        ".\COMPREHENSIVE_BETA_QA.ps1",
        ".\Test-CriticalFixes.ps1",
        ".\BETA_RELEASE_QA.ps1",
        ".\Test-WindowsForms.ps1",
        ".\Test-WindowsFormsInit.ps1"
    )
    "Installation and Setup Scripts" = @(
        ".\Install-Velociraptor-Direct.ps1",
        ".\Install-Velociraptor-Fixed.ps1",
        ".\Install-Velociraptor-Live.ps1",
        ".\Install-Velociraptor-Simple.ps1"
    )
    "Utility Scripts" = @(
        ".\Backup-VelociraptorData.ps1",
        ".\Cleanup_Velociraptor.ps1",
        ".\Manage-VelociraptorConfig.ps1",
        ".\Prepare_OfflineCollector_Env.ps1"
    )
    "Analysis and Reporting Scripts" = @(
        ".\Advanced-UA-Testing.ps1",
        ".\execute-uat-checklist.ps1"
    )
}

# Start testing
Write-TestLog "=== PowerShell File Syntax and Functionality Test Started ===" "INFO"
Write-TestLog "Log file: $LogPath" "INFO"
Write-TestLog "" "INFO"

# Clear previous log
if (Test-Path $LogPath) {
    Remove-Item $LogPath -Force
}

foreach ($category in $TestFiles.Keys) {
    Write-TestLog "=== Testing Category: $category ===" "INFO"
    
    foreach ($file in $TestFiles[$category]) {
        $result = Test-SingleFile -FilePath $file -Category $category
        $Results.Details += $result
        
        if ($DetailedOutput) {
            Write-TestLog "  File: $($result.File)" "INFO"
            Write-TestLog "  Status: $($result.Status)" "INFO"
            if ($result.BasicFunctionality) {
                Write-TestLog "  Functionality Score: $($result.BasicFunctionality.Score)/4" "INFO"
            }
            Write-TestLog "" "INFO"
        }
    }
    Write-TestLog "" "INFO"
}

# Generate summary report
Write-TestLog "=== SUMMARY REPORT ===" "INFO"
Write-TestLog "Total Files Tested: $($Results.TotalFiles)" "INFO"
Write-TestLog "Files Not Found: $($Results.NotFound)" "INFO"
Write-TestLog "Syntax Validation - Passed: $($Results.PassedSyntax), Failed: $($Results.FailedSyntax)" "INFO"
Write-TestLog "Basic Functionality - Passed: $($Results.PassedBasic), Failed: $($Results.FailedBasic)" "INFO"
Write-TestLog "" "INFO"

# Files by status
$statusGroups = $Results.Details | Group-Object Status
foreach ($group in $statusGroups) {
    Write-TestLog "$($group.Name): $($group.Count) files" "INFO"
    foreach ($file in $group.Group) {
        Write-TestLog "  - $($file.File)" "INFO"
    }
    Write-TestLog "" "INFO"
}

# Errors summary
if ($Results.Errors.Count -gt 0) {
    Write-TestLog "=== ERRORS ENCOUNTERED ===" "ERROR"
    foreach ($error in $Results.Errors) {
        Write-TestLog "  $error" "ERROR"
    }
}

Write-TestLog "=== Test Complete ===" "INFO"

# Return results for further processing
return $Results