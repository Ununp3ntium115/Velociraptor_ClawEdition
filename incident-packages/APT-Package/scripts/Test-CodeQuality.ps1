#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick PowerShell code quality check before GitHub push

.DESCRIPTION
    Performs rapid validation of PowerShell scripts to catch common errors,
    syntax issues, and best practice violations before committing to GitHub.

.PARAMETER Path
    Path to scan for PowerShell files (defaults to current directory)

.PARAMETER Fix
    Attempt to automatically fix simple issues

.EXAMPLE
    .\Test-CodeQuality.ps1
    .\Test-CodeQuality.ps1 -Path "scripts" -Fix
#>

[CmdletBinding()]
param(
    [string]$Path = ".",
    [switch]$Fix
)

# Initialize results tracking
$script:Results = @{
    TotalFiles = 0
    PassedFiles = 0
    FailedFiles = 0
    TotalIssues = 0
    CriticalIssues = 0
    WarningIssues = 0
    InfoIssues = 0
    Issues = @()
}

function Write-TestResult {
    param([string]$Message, [string]$Level = "INFO")
    $color = switch ($Level) {
        "CRITICAL" { "Red" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        "INFO" { "Cyan" }
        default { "White" }
    }
    Write-Host $Message -ForegroundColor $color
}

function Test-PowerShellSyntax {
    param([string]$FilePath)

    Write-TestResult "  🔍 Testing syntax..." "INFO"

    try {
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $FilePath -Raw), [ref]$null)
        return @{ Passed = $true; Issues = @() }
    } catch {
        $issue = @{
            File = $FilePath
            Type = "SyntaxError"
            Severity = "CRITICAL"
            Message = "PowerShell syntax error: $($_.Exception.Message)"
            Line = 0
        }
        return @{ Passed = $false; Issues = @($issue) }
    }
}

function Test-ScriptAnalyzer {
    param([string]$FilePath)

    Write-TestResult "  📊 Running PSScriptAnalyzer..." "INFO"

    try {
        # Check if PSScriptAnalyzer is available
        if (-not (Get-Module PSScriptAnalyzer -ListAvailable)) {
            Write-TestResult "  ⚠️ PSScriptAnalyzer not installed, skipping..." "WARNING"
            return @{ Passed = $true; Issues = @() }
        }

        $analysis = Invoke-ScriptAnalyzer -Path $FilePath -Severity Error, Warning
        $issues = @()

        foreach ($result in $analysis) {
            $severity = switch ($result.Severity) {
                "Error" { "CRITICAL" }
                "Warning" { "WARNING" }
                default { "INFO" }
            }

            $issues += @{
                File = $FilePath
                Type = "ScriptAnalyzer"
                Severity = $severity
                Message = "$($result.RuleName): $($result.Message)"
                Line = $result.Line
            }
        }

        return @{
            Passed = $analysis.Count -eq 0
            Issues = $issues
        }
    } catch {
        Write-TestResult "  ⚠️ PSScriptAnalyzer failed: $($_.Exception.Message)" "WARNING"
        return @{ Passed = $true; Issues = @() }
    }
}

function Test-CommonIssues {
    param([string]$FilePath)

    Write-TestResult "  🔎 Checking common issues..." "INFO"

    $content = Get-Content $FilePath -Raw
    $lines = Get-Content $FilePath
    $issues = @()

    # Check for common PowerShell issues
    $checks = @(
        @{
            Name = "Hardcoded Credentials"
            Pattern = '(password|secret|key|token)\s*=\s*["\x27][^\x22\x27]+["\x27]'
            Severity = "CRITICAL"
            Message = "Potential hardcoded credential found"
        },
        @{
            Name = "Unsafe Invoke-Expression"
            Pattern = '(Invoke-Expression|iex)\s+'
            Severity = "WARNING"
            Message = "Unsafe use of Invoke-Expression detected"
        },
        @{
            Name = "Missing Error Handling"
            Pattern = '(Remove-Item|New-Item|Copy-Item).*-Force'
            Severity = "WARNING"
            Message = "Potentially unsafe file operation without error handling"
        },
        @{
            Name = "Unapproved Verbs"
            Pattern = 'function\s+(?!Get-|Set-|New-|Remove-|Test-|Start-|Stop-|Add-|Clear-|Copy-|Move-|Write-|Read-|Import-|Export-|Install-|Enable-|Disable-|Invoke-|Update-|Deploy-|Build-|Find-|Show-|Request-)[A-Za-z]+-[A-Za-z]+'
            Severity = "WARNING"
            Message = "Function may not use approved PowerShell verb"
        },
        @{
            Name = "Missing Parameter Validation"
            Pattern = 'param\s*\([^)]*\[Parameter\([^)]*Mandatory[^)]*\)[^)]*\$\w+(?!\s*,\s*\[ValidateNotNullOrEmpty\]|\s*,\s*\[ValidateScript\]|\s*,\s*\[ValidateSet\])'
            Severity = "INFO"
            Message = "Mandatory parameter without validation"
        },
        @{
            Name = "Write-Host Usage"
            Pattern = 'Write-Host(?!\s+-ForegroundColor)'
            Severity = "INFO"
            Message = "Consider using Write-Output or Write-Information instead of Write-Host"
        }
    )

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $lineNumber = $i + 1

        foreach ($check in $checks) {
            if ($line -match $check.Pattern) {
                $issues += @{
                    File = $FilePath
                    Type = $check.Name
                    Severity = $check.Severity
                    Message = $check.Message
                    Line = $lineNumber
                    Content = $line.Trim()
                }
            }
        }
    }

    # Check for missing comment-based help
    if ($content -notmatch '\.SYNOPSIS' -and $content -match 'function\s+\w+-\w+') {
        $issues += @{
            File = $FilePath
            Type = "Missing Help"
            Severity = "INFO"
            Message = "Functions should have comment-based help"
            Line = 1
        }
    }

    # Check for proper error handling
    $functionMatches = [regex]::Matches($content, 'function\s+[\w-]+\s*{[^}]*}', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    foreach ($match in $functionMatches) {
        if ($match.Value -notmatch 'try\s*{|catch\s*{|\$ErrorActionPreference') {
            $issues += @{
                File = $FilePath
                Type = "Missing Error Handling"
                Severity = "WARNING"
                Message = "Function lacks proper error handling"
                Line = ($content.Substring(0, $match.Index) -split "`n").Count
            }
        }
    }

    return @{
        Passed = $issues.Count -eq 0
        Issues = $issues
    }
}

function Test-FileEncoding {
    param([string]$FilePath)

    Write-TestResult "  📝 Checking file encoding..." "INFO"

    try {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        $issues = @()

        # Check for BOM
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            $issues += @{
                File = $FilePath
                Type = "Encoding"
                Severity = "WARNING"
                Message = "File contains UTF-8 BOM which may cause issues"
                Line = 1
            }
        }

        # Check for mixed line endings
        $content = Get-Content $FilePath -Raw
        $crlfCount = ($content -split "`r`n").Count - 1
        $lfCount = ($content -split "`n").Count - 1 - $crlfCount

        if ($crlfCount -gt 0 -and $lfCount -gt 0) {
            $issues += @{
                File = $FilePath
                Type = "Line Endings"
                Severity = "WARNING"
                Message = "File contains mixed line endings (CRLF and LF)"
                Line = 1
            }
        }

        return @{
            Passed = $issues.Count -eq 0
            Issues = $issues
        }
    } catch {
        return @{
            Passed = $false
            Issues = @(@{
                File = $FilePath
                Type = "Encoding"
                Severity = "ERROR"
                Message = "Unable to read file encoding: $($_.Exception.Message)"
                Line = 1
            })
        }
    }
}

function Test-PowerShellFile {
    param([string]$FilePath)

    Write-TestResult "📄 Testing: $FilePath" "INFO"
    $script:Results.TotalFiles++

    $allTests = @(
        (Test-PowerShellSyntax -FilePath $FilePath),
        (Test-ScriptAnalyzer -FilePath $FilePath),
        (Test-CommonIssues -FilePath $FilePath),
        (Test-FileEncoding -FilePath $FilePath)
    )

    $fileIssues = @()
    $filePassed = $true

    foreach ($test in $allTests) {
        if (-not $test.Passed) {
            $filePassed = $false
        }
        $fileIssues += $test.Issues
    }

    # Update global results
    $script:Results.Issues += $fileIssues
    $script:Results.TotalIssues += $fileIssues.Count

    foreach ($issue in $fileIssues) {
        switch ($issue.Severity) {
            "CRITICAL" { $script:Results.CriticalIssues++ }
            "ERROR" { $script:Results.CriticalIssues++ }
            "WARNING" { $script:Results.WarningIssues++ }
            "INFO" { $script:Results.InfoIssues++ }
        }
    }

    if ($filePassed) {
        $script:Results.PassedFiles++
        Write-TestResult "  ✅ PASSED" "SUCCESS"
    } else {
        $script:Results.FailedFiles++
        Write-TestResult "  ❌ FAILED ($($fileIssues.Count) issues)" "ERROR"

        # Display issues for this file
        foreach ($issue in $fileIssues) {
            $severity = $issue.Severity
            $line = if ($issue.Line -gt 0) { " (Line $($issue.Line))" } else { "" }
            Write-TestResult "    [$severity]$line $($issue.Message)" $severity
            if ($issue.Content) {
                Write-TestResult "      Code: $($issue.Content)" "INFO"
            }
        }
    }

    return $filePassed
}

function Repair-CommonIssues {
    param([string]$FilePath)

    if (-not $Fix) { return }

    Write-TestResult "🔧 Attempting to fix issues in: $FilePath" "INFO"

    $content = Get-Content $FilePath -Raw
    $originalContent = $content
    $fixCount = 0

    # Fix common issues
    $fixes = @(
        @{
            Name = "Remove UTF-8 BOM"
            Pattern = "^\xEF\xBB\xBF"
            Replacement = ""
        },
        @{
            Name = "Normalize line endings to CRLF"
            Pattern = "(?<!\r)\n"
            Replacement = "`r`n"
        },
        @{
            Name = "Remove trailing whitespace"
            Pattern = "[ \t]+$"
            Replacement = ""
        }
    )

    foreach ($fix in $fixes) {
        if ($content -match $fix.Pattern) {
            $content = $content -replace $fix.Pattern, $fix.Replacement
            $fixCount++
            Write-TestResult "  ✅ Fixed: $($fix.Name)" "SUCCESS"
        }
    }

    if ($fixCount -gt 0) {
        Set-Content -Path $FilePath -Value $content -NoNewline
        Write-TestResult "  🔧 Applied $fixCount fixes to $FilePath" "SUCCESS"
    }
}

function Show-Summary {
    Write-TestResult "`n📊 CODE QUALITY SUMMARY" "INFO"
    Write-TestResult "========================" "INFO"
    Write-TestResult "Total Files Tested: $($script:Results.TotalFiles)" "INFO"
    Write-TestResult "Passed: $($script:Results.PassedFiles)" "SUCCESS"
    Write-TestResult "Failed: $($script:Results.FailedFiles)" $(if ($script:Results.FailedFiles -eq 0) { "SUCCESS" } else { "ERROR" })
    Write-TestResult "`nIssue Breakdown:" "INFO"
    Write-TestResult "Critical/Error: $($script:Results.CriticalIssues)" $(if ($script:Results.CriticalIssues -eq 0) { "SUCCESS" } else { "CRITICAL" })
    Write-TestResult "Warnings: $($script:Results.WarningIssues)" $(if ($script:Results.WarningIssues -eq 0) { "SUCCESS" } else { "WARNING" })
    Write-TestResult "Info: $($script:Results.InfoIssues)" "INFO"
    Write-TestResult "Total Issues: $($script:Results.TotalIssues)" $(if ($script:Results.TotalIssues -eq 0) { "SUCCESS" } else { "WARNING" })

    # Show top issues by type
    if ($script:Results.Issues.Count -gt 0) {
        Write-TestResult "`n🔍 TOP ISSUES BY TYPE:" "INFO"
        $issueGroups = $script:Results.Issues | Group-Object Type | Sort-Object Count -Descending | Select-Object -First 5
        foreach ($group in $issueGroups) {
            Write-TestResult "  $($group.Name): $($group.Count) occurrences" "WARNING"
        }
    }

    # Recommendation
    if ($script:Results.CriticalIssues -eq 0) {
        Write-TestResult "`n✅ READY FOR GITHUB PUSH" "SUCCESS"
        Write-TestResult "No critical issues found. Code quality check passed!" "SUCCESS"
        return $true
    } else {
        Write-TestResult "`n❌ NOT READY FOR GITHUB PUSH" "CRITICAL"
        Write-TestResult "Critical issues must be fixed before pushing to GitHub!" "CRITICAL"
        return $false
    }
}

# Main execution
Write-TestResult "🚀 PowerShell Code Quality Check" "INFO"
Write-TestResult "Scanning path: $Path" "INFO"
if ($Fix) {
    Write-TestResult "Auto-fix mode: ENABLED" "WARNING"
}

# Find all PowerShell files
$psFiles = Get-ChildItem -Path $Path -Filter "*.ps1" -Recurse | Where-Object {
    $_.FullName -notmatch '\\(temp|releases|\.git)\\' -and
    $_.Name -notmatch '^(Test-|.*\.Tests\.ps1)$'
}

if ($psFiles.Count -eq 0) {
    Write-TestResult "No PowerShell files found in: $Path" "WARNING"
    exit 0
}

Write-TestResult "Found $($psFiles.Count) PowerShell files to test" "INFO"

# Test each file
foreach ($file in $psFiles) {
    Test-PowerShellFile -FilePath $file.FullName
    if ($Fix) {
        Fix-CommonIssues -FilePath $file.FullName
    }
}

# Show summary and determine exit code
$readyForPush = Show-Summary

if ($readyForPush) {
    exit 0
} else {
    exit 1
}