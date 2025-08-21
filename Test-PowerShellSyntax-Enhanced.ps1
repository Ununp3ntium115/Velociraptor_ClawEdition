#Requires -Version 5.1

<#
.SYNOPSIS
    Enhanced PowerShell Syntax Validator with Detailed Error Reporting

.DESCRIPTION
    Performs comprehensive syntax validation using PowerShell's parser
    and provides detailed error reporting for each file.

.NOTES
    Enhanced version with better error detection
    Author: Claude Code
    Version: 2.0
#>

[CmdletBinding()]
param(
    [string]$LogPath = ".\enhanced-syntax-test-results.log",
    [switch]$DetailedOutput
)

$Results = @{
    TotalFiles = 0
    PassedSyntax = 0
    FailedSyntax = 0
    FilesWithIssues = @()
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
    Add-Content -Path $LogPath -Value $logEntry -Encoding UTF8
}

function Test-PowerShellSyntaxEnhanced {
    param(
        [string]$FilePath
    )
    
    $result = @{
        Valid = $false
        Errors = @()
        Warnings = @()
    }
    
    try {
        $content = Get-Content $FilePath -Raw -Encoding UTF8
        $tokens = $null
        $parseErrors = $null
        
        # Use PowerShell AST parser for comprehensive syntax checking
        $ast = [System.Management.Automation.Language.Parser]::ParseInput(
            $content, 
            [ref]$tokens, 
            [ref]$parseErrors
        )
        
        if ($parseErrors.Count -eq 0) {
            $result.Valid = $true
        } else {
            $result.Valid = $false
            foreach ($error in $parseErrors) {
                $result.Errors += "Line $($error.Extent.StartLineNumber): $($error.Message)"
            }
        }
        
        # Additional checks for common issues
        if ($content -match '(?<!#).*(?:�|[\x80-\xFF])') {
            $result.Warnings += "File may contain encoding issues or special characters"
        }
        
        if ($content -match '\$\w*\s*\+\s*=\s*"[^"]*\$\{[^}]*\}') {
            $result.Warnings += "Potential string interpolation issues detected"
        }
        
    }
    catch {
        $result.Valid = $false
        $result.Errors += "Parser exception: $($_.Exception.Message)"
    }
    
    return $result
}

function Test-SingleFileEnhanced {
    param(
        [string]$FilePath,
        [string]$Category
    )
    
    $Results.TotalFiles++
    
    Write-TestLog "Testing: $FilePath" "INFO"
    
    # Check if file exists
    if (-not (Test-Path $FilePath)) {
        Write-TestLog "File not found: $FilePath" "ERROR"
        return @{
            File = $FilePath
            Category = $Category
            Exists = $false
            SyntaxTest = @{ Valid = $false; Errors = @("File not found") }
            Status = "NOT_FOUND"
        }
    }
    
    # Enhanced syntax test
    $syntaxTest = Test-PowerShellSyntaxEnhanced -FilePath $FilePath
    
    if ($syntaxTest.Valid) {
        $Results.PassedSyntax++
        Write-TestLog "Syntax PASSED: $FilePath" "SUCCESS"
        $status = "READY"
    } else {
        $Results.FailedSyntax++
        Write-TestLog "Syntax FAILED: $FilePath" "ERROR"
        $Results.FilesWithIssues += @{
            File = $FilePath
            Errors = $syntaxTest.Errors
            Warnings = $syntaxTest.Warnings
        }
        
        # Log specific errors
        foreach ($error in $syntaxTest.Errors) {
            Write-TestLog "  ERROR: $error" "ERROR"
        }
        foreach ($warning in $syntaxTest.Warnings) {
            Write-TestLog "  WARNING: $warning" "WARNING"
        }
        
        $status = "SYNTAX_ERROR"
    }
    
    return @{
        File = $FilePath
        Category = $Category
        Exists = $true
        SyntaxTest = $syntaxTest
        Status = $status
    }
}

# Test target files
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

Write-TestLog "=== Enhanced PowerShell Syntax Validation Started ===" "INFO"
Write-TestLog "Log file: $LogPath" "INFO"
Write-TestLog "" "INFO"

# Clear previous log
if (Test-Path $LogPath) {
    Remove-Item $LogPath -Force
}

foreach ($category in $TestFiles.Keys) {
    Write-TestLog "=== Testing Category: $category ===" "INFO"
    
    foreach ($file in $TestFiles[$category]) {
        $result = Test-SingleFileEnhanced -FilePath $file -Category $category
        $Results.Details += $result
    }
    Write-TestLog "" "INFO"
}

# Generate comprehensive report
Write-TestLog "=== COMPREHENSIVE RESULTS ===" "INFO"
Write-TestLog "Total Files Tested: $($Results.TotalFiles)" "INFO"
Write-TestLog "Syntax Valid: $($Results.PassedSyntax)" "SUCCESS"
Write-TestLog "Syntax Invalid: $($Results.FailedSyntax)" "ERROR"
Write-TestLog "" "INFO"

# Files ready to use
$readyFiles = $Results.Details | Where-Object { $_.Status -eq "READY" }
if ($readyFiles.Count -gt 0) {
    Write-TestLog "READY TO RUN ($($readyFiles.Count) files):" "SUCCESS"
    foreach ($file in $readyFiles) {
        Write-TestLog "  - $($file.File)" "SUCCESS"
    }
    Write-TestLog "" "INFO"
}

# Files with issues
if ($Results.FilesWithIssues.Count -gt 0) {
    Write-TestLog "FILES NEEDING FIXES ($($Results.FilesWithIssues.Count) files):" "ERROR"
    foreach ($fileInfo in $Results.FilesWithIssues) {
        Write-TestLog "  FILE: $($fileInfo.File)" "ERROR"
        foreach ($error in $fileInfo.Errors) {
            Write-TestLog "    ERROR: $error" "ERROR"
        }
        foreach ($warning in $fileInfo.Warnings) {
            Write-TestLog "    WARNING: $warning" "WARNING"
        }
        Write-TestLog "" "INFO"
    }
}

Write-TestLog "=== Test Complete ===" "INFO"

return $Results