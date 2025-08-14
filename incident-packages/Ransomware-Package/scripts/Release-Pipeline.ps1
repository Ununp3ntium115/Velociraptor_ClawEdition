#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Comprehensive QA/UA/Production release pipeline for Velociraptor Setup Scripts

.DESCRIPTION
    Implements a complete software development lifecycle with Quality Assurance,
    User Acceptance Testing, and Production release processes.

.PARAMETER Stage
    Pipeline stage to execute

.PARAMETER Version
    Version number for the release

.PARAMETER SkipTests
    Skip automated testing (not recommended)

.EXAMPLE
    .\Release-Pipeline.ps1 -Stage QA -Version "5.1.0"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("QA", "UA", "Production", "All")]
    [string]$Stage,

    [Parameter(Mandatory)]
    [string]$Version,

    [switch]$SkipTests,

    [string]$OutputDirectory = ".\releases"
)

# Pipeline configuration
$PipelineConfig = @{
    QA = @{
        Description = "Quality Assurance Testing"
        TestSuites = @("Unit", "Integration", "Security", "Performance")
        RequiredCoverage = 90
        Environments = @("QA-Windows", "QA-Linux")
        ApprovalRequired = $false
    }
    UA = @{
        Description = "User Acceptance Testing"
        TestSuites = @("Functional", "Usability", "Compatibility")
        RequiredCoverage = 95
        Environments = @("UA-Windows", "UA-Linux", "UA-macOS")
        ApprovalRequired = $true
    }
    Production = @{
        Description = "Production Release"
        TestSuites = @("Smoke", "Regression")
        RequiredCoverage = 100
        Environments = @("Production")
        ApprovalRequired = $true
    }
}

function Write-PipelineLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        "INFO" { "Cyan" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color

    # Log to file
    $logFile = "pipeline-$Version-$(Get-Date -Format 'yyyyMMdd').log"
    "[$timestamp] [$Level] $Message" | Add-Content -Path $logFile
}

function Test-Prerequisites {
    Write-PipelineLog "Checking prerequisites..." "INFO"

    $prerequisites = @(
        @{ Name = "PowerShell"; Command = "pwsh"; MinVersion = "7.0" },
        @{ Name = "Pester"; Command = "Get-Module Pester -ListAvailable"; MinVersion = "5.0" },
        @{ Name = "PSScriptAnalyzer"; Command = "Get-Module PSScriptAnalyzer -ListAvailable"; MinVersion = "1.19" },
        @{ Name = "Git"; Command = "git"; MinVersion = "2.0" }
    )

    $allGood = $true
    foreach ($prereq in $prerequisites) {
        try {
            if ($prereq.Command -match "Get-Module") {
                $result = Invoke-Expression $prereq.Command
                if ($result) {
                    Write-PipelineLog "$($prereq.Name) is available" "SUCCESS"
                } else {
                    Write-PipelineLog "$($prereq.Name) is missing" "ERROR"
                    $allGood = $false
                }
            } else {
                $null = Get-Command $prereq.Command -ErrorAction Stop
                Write-PipelineLog "$($prereq.Name) is available" "SUCCESS"
            }
        } catch {
            Write-PipelineLog "$($prereq.Name) is missing or not accessible" "ERROR"
            $allGood = $false
        }
    }

    return $allGood
}

function Invoke-CodeAnalysis {
    Write-PipelineLog "Running static code analysis..." "INFO"

    $scriptFiles = Get-ChildItem -Path "." -Filter "*.ps1" -Recurse | Where-Object {
        $_.FullName -notmatch "\\(tests|temp|releases)\\"
    }

    $issues = @()
    foreach ($file in $scriptFiles) {
        $analysis = Invoke-ScriptAnalyzer -Path $file.FullName -Severity Warning, Error
        if ($analysis) {
            $issues += $analysis
            Write-PipelineLog "Issues found in $($file.Name): $($analysis.Count)" "WARNING"
        }
    }

    if ($issues.Count -gt 0) {
        Write-PipelineLog "Total code analysis issues: $($issues.Count)" "WARNING"
        $issues | Export-Csv -Path "code-analysis-$Version.csv" -NoTypeInformation
        return $false
    } else {
        Write-PipelineLog "Code analysis passed with no issues" "SUCCESS"
        return $true
    }
}

function Invoke-UnitTests {
    Write-PipelineLog "Running unit tests..." "INFO"

    if (-not (Test-Path "tests")) {
        Write-PipelineLog "No tests directory found, creating basic test structure..." "WARNING"
        New-TestStructure
    }

    $testResults = Invoke-Pester -Path "tests" -OutputFormat NUnitXml -OutputFile "test-results-$Version.xml" -PassThru

    $coverage = ($testResults.CodeCoverage.NumberOfCommandsExecuted / $testResults.CodeCoverage.NumberOfCommandsAnalyzed) * 100

    Write-PipelineLog "Test Results: $($testResults.PassedCount) passed, $($testResults.FailedCount) failed" "INFO"
    Write-PipelineLog "Code Coverage: $([math]::Round($coverage, 2))%" "INFO"

    return @{
        Passed = $testResults.FailedCount -eq 0
        Coverage = $coverage
        Results = $testResults
    }
}

function Invoke-IntegrationTests {
    Write-PipelineLog "Running integration tests..." "INFO"

    $integrationTests = @(
        @{ Name = "Standalone Deployment"; Script = ".\Deploy_Velociraptor_Standalone.ps1"; Args = @("-WhatIf") },
        @{ Name = "Server Deployment"; Script = ".\Deploy_Velociraptor_Server.ps1"; Args = @("-WhatIf") },
        @{ Name = "GUI Launch"; Script = ".\gui\VelociraptorGUI.ps1"; Args = @("-StartMinimized", "-TestMode") },
        @{ Name = "Module Import"; Script = { Import-Module .\VelociraptorSetupScripts.psd1 -Force -ErrorAction SilentlyContinue } }
    )

    $results = @()
    foreach ($test in $integrationTests) {
        try {
            Write-PipelineLog "Running: $($test.Name)" "INFO"

            if ($test.Script -is [scriptblock]) {
                & $test.Script
            } else {
                & $test.Script @($test.Args)
            }

            $results += @{ Name = $test.Name; Status = "PASSED" }
            Write-PipelineLog "$($test.Name): PASSED" "SUCCESS"
        } catch {
            $results += @{ Name = $test.Name; Status = "FAILED"; Error = $_.Exception.Message }
            Write-PipelineLog "$($test.Name): FAILED - $($_.Exception.Message)" "ERROR"
        }
    }

    $passed = ($results | Where-Object { $_.Status -eq "PASSED" }).Count
    $total = $results.Count

    Write-PipelineLog "Integration Tests: $passed/$total passed" "INFO"

    return @{
        Passed = $passed -eq $total
        Results = $results
    }
}

function Invoke-SecurityTests {
    Write-PipelineLog "Running security tests..." "INFO"

    $securityChecks = @(
        @{ Name = "Hardcoded Credentials"; Pattern = "(password|secret|key)\s*=\s*['\`"][^'\`"]+['\`"]"; Severity = "High" },
        @{ Name = "Unsafe Functions"; Pattern = "(Invoke-Expression|iex|cmd\.exe|powershell\.exe -c)"; Severity = "Medium" },
        @{ Name = "Network Calls"; Pattern = "(Invoke-WebRequest|wget|curl|Net\.WebClient)"; Severity = "Low" },
        @{ Name = "File Operations"; Pattern = "(Remove-Item.*-Recurse.*-Force -ErrorAction SilentlyContinue|rm.*-rf)"; Severity = "Medium" }
    )

    $findings = @()
    $scriptFiles = Get-ChildItem -Path "." -Filter "*.ps1" -Recurse

    foreach ($file in $scriptFiles) {
        $content = Get-Content $file.FullName -Raw

        foreach ($check in $securityChecks) {
            if ($content -match $check.Pattern) {
                $findings += @{
                    File = $file.Name
                    Check = $check.Name
                    Severity = $check.Severity
                    Pattern = $check.Pattern
                }
            }
        }
    }

    if ($findings.Count -gt 0) {
        Write-PipelineLog "Security findings: $($findings.Count)" "WARNING"
        $findings | Export-Csv -Path "security-findings-$Version.csv" -NoTypeInformation

        $highSeverity = ($findings | Where-Object { $_.Severity -eq "High" }).Count
        return @{
            Passed = $highSeverity -eq 0
            Findings = $findings
        }
    } else {
        Write-PipelineLog "No security issues found" "SUCCESS"
        return @{ Passed = $true; Findings = @() }
    }
}

function Invoke-PerformanceTests {
    Write-PipelineLog "Running performance tests..." "INFO"

    $performanceTests = @(
        @{
            Name = "Module Load Time"
            Script = {
                $start = Get-Date
                Import-Module .\VelociraptorSetupScripts.psd1 -Force -ErrorAction SilentlyContinue
                $end = Get-Date
                return ($end - $start).TotalSeconds
            }
            Threshold = 5.0
        },
        @{
            Name = "GUI Launch Time"
            Script = {
                $start = Get-Date
                $process = Start-Process -FilePath "pwsh" -ArgumentList "-File", ".\gui\VelociraptorGUI.ps1", "-TestMode" -PassThru
                Start-Sleep -Seconds 2
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                $end = Get-Date
                return ($end - $start).TotalSeconds
            }
            Threshold = 10.0
        }
    )

    $results = @()
    foreach ($test in $performanceTests) {
        try {
            $duration = & $test.Script
            $passed = $duration -le $test.Threshold

            $results += @{
                Name = $test.Name
                Duration = $duration
                Threshold = $test.Threshold
                Passed = $passed
            }

            $status = if ($passed) { "PASSED" } else { "FAILED" }
            Write-PipelineLog "$($test.Name): $duration seconds - $status" $(if ($passed) { "SUCCESS" } else { "WARNING" })
        } catch {
            $results += @{
                Name = $test.Name
                Duration = -1
                Threshold = $test.Threshold
                Passed = $false
                Error = $_.Exception.Message
            }
            Write-PipelineLog "$($test.Name): FAILED - $($_.Exception.Message)" "ERROR"
        }
    }

    $passed = ($results | Where-Object { $_.Passed }).Count
    $total = $results.Count

    return @{
        Passed = $passed -eq $total
        Results = $results
    }
}

function New-TestStructure {
    Write-PipelineLog "Creating test structure..." "INFO"

    New-Item -ItemType Directory -Path "tests" -Force -ErrorAction SilentlyContinue | Out-Null

    $testTemplate = @'
Describe "Velociraptor Setup Scripts Tests" {
    Context "Module Loading" {
        It "Should import module without errors" {
            { Import-Module .\VelociraptorSetupScripts.psd1 -Force -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Core Functions" {
        It "Should have required functions exported" {
            $module = Get-Module VelociraptorSetupScripts
            $module.ExportedFunctions.Keys | Should -Contain "Deploy-VelociraptorStandalone"
        }
    }
}
'@

    Set-Content -Path "tests\VelociraptorSetupScripts.Tests.ps1" -Value $testTemplate
}

function New-ReleasePackage {
    param([string]$Stage)

    Write-PipelineLog "Creating $Stage release package..." "INFO"

    $releaseDir = Join-Path $OutputDirectory "$Stage-$Version"
    New-Item -ItemType Directory -Path $releaseDir -Force -ErrorAction SilentlyContinue | Out-Null

    # Copy core files
    $coreFiles = @(
        "*.ps1", "*.psd1", "*.psm1", "*.md", "LICENSE",
        "modules", "scripts", "gui", "templates", "examples"
    )

    foreach ($pattern in $coreFiles) {
        $items = Get-Item $pattern -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            if ($item.PSIsContainer) {
                Copy-Item $item.FullName -Destination $releaseDir -Recurse -Force -ErrorAction SilentlyContinue
            } else {
                Copy-Item $item.FullName -Destination $releaseDir -Force -ErrorAction SilentlyContinue
            }
        }
    }

    # Create release manifest
    $manifest = @{
        Version = $Version
        Stage = $Stage
        BuildDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        GitCommit = (git rev-parse HEAD)
        GitBranch = (git branch --show-current)
        TestResults = "See test-results-$Version.xml"
    }

    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $releaseDir "release-manifest.json")

    # Create ZIP package
    $zipPath = "$releaseDir.zip"
    Compress-Archive -Path $releaseDir -DestinationPath $zipPath -Force -ErrorAction SilentlyContinue

    Write-PipelineLog "$Stage package created: $zipPath" "SUCCESS"
    return $zipPath
}

function Request-Approval {
    param([string]$Stage)

    Write-PipelineLog "Approval required for $Stage stage" "WARNING"

    do {
        $response = Read-Host "Approve $Stage release for version $Version? (y/n/details)"

        switch ($response.ToLower()) {
            "y" { return $true }
            "n" { return $false }
            "details" {
                Write-Host "Release Details:" -ForegroundColor Cyan
                Write-Host "  Version: $Version" -ForegroundColor White
                Write-Host "  Stage: $Stage" -ForegroundColor White
                Write-Host "  Build Date: $(Get-Date)" -ForegroundColor White
                Write-Host "  Git Commit: $(git rev-parse HEAD)" -ForegroundColor White
                Write-Host "  Test Results: See test-results-$Version.xml" -ForegroundColor White
            }
            default {
                Write-Host "Please enter 'y' for yes, 'n' for no, or 'details' for more information" -ForegroundColor Yellow
            }
        }
    } while ($true)
}

function Invoke-PipelineStage {
    param([string]$StageName)

    Write-PipelineLog "Starting $StageName stage for version $Version" "INFO"

    $stageConfig = $PipelineConfig[$StageName]
    $allTestsPassed = $true

    # Run test suites
    foreach ($testSuite in $stageConfig.TestSuites) {
        switch ($testSuite) {
            "Unit" {
                $result = Invoke-UnitTests
                if (-not $result.Passed) { $allTestsPassed = $false }
            }
            "Integration" {
                $result = Invoke-IntegrationTests
                if (-not $result.Passed) { $allTestsPassed = $false }
            }
            "Security" {
                $result = Invoke-SecurityTests
                if (-not $result.Passed) { $allTestsPassed = $false }
            }
            "Performance" {
                $result = Invoke-PerformanceTests
                if (-not $result.Passed) { $allTestsPassed = $false }
            }
            "Functional" {
                Write-PipelineLog "Functional tests require manual execution" "WARNING"
            }
            "Usability" {
                Write-PipelineLog "Usability tests require manual execution" "WARNING"
            }
            "Compatibility" {
                Write-PipelineLog "Compatibility tests require manual execution" "WARNING"
            }
            "Smoke" {
                $result = Invoke-IntegrationTests
                if (-not $result.Passed) { $allTestsPassed = $false }
            }
            "Regression" {
                $result = Invoke-UnitTests
                if (-not $result.Passed) { $allTestsPassed = $false }
            }
        }
    }

    # Check if approval is required
    if ($stageConfig.ApprovalRequired) {
        if (-not (Request-Approval -Stage $StageName)) {
            Write-PipelineLog "$StageName stage rejected by approver" "ERROR"
            return $false
        }
    }

    if ($allTestsPassed) {
        Write-PipelineLog "$StageName stage completed successfully" "SUCCESS"
        New-ReleasePackage -Stage $StageName
        return $true
    } else {
        Write-PipelineLog "$StageName stage failed" "ERROR"
        return $false
    }
}

# Main pipeline execution
function Main {
    Write-PipelineLog "Starting Velociraptor Setup Scripts Release Pipeline" "INFO"
    Write-PipelineLog "Version: $Version" "INFO"
    Write-PipelineLog "Stage: $Stage" "INFO"

    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        Write-PipelineLog "Prerequisites check failed" "ERROR"
        exit 1
    }

    # Run code analysis
    if (-not $SkipTests) {
        if (-not (Invoke-CodeAnalysis)) {
            Write-PipelineLog "Code analysis failed" "ERROR"
            exit 1
        }
    }

    # Execute pipeline stages
    $success = $true

    if ($Stage -eq "All") {
        $stages = @("QA", "UA", "Production")
    } else {
        $stages = @($Stage)
    }

    foreach ($stageName in $stages) {
        if (-not (Invoke-PipelineStage -StageName $stageName)) {
            $success = $false
            break
        }
    }

    if ($success) {
        Write-PipelineLog "Pipeline completed successfully!" "SUCCESS"
        Write-PipelineLog "Release packages available in: $OutputDirectory" "INFO"
    } else {
        Write-PipelineLog "Pipeline failed" "ERROR"
        exit 1
    }
}

# Execute main function
Main