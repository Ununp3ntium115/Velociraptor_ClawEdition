# Performance Measurement Infrastructure (Simplified)
# Version: 5.0.4-beta
# Date: August 20, 2025

[CmdletBinding()]
param(
    [string]$TestScope = "All",
    [string]$OutputPath = ".\performance-results",
    [int]$Iterations = 3
)

$ErrorActionPreference = "Continue"

function Write-PerformanceLog {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    
    $logPath = Join-Path $OutputPath "performance.log"
    if (-not (Test-Path (Split-Path $logPath -Parent))) {
        New-Item -ItemType Directory -Path (Split-Path $logPath -Parent) -Force | Out-Null
    }
    Add-Content -Path $logPath -Value $logEntry
}

function Test-BasicPerformance {
    Write-PerformanceLog "Starting basic performance tests"
    
    $results = @{
        SystemInfo = @{
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            OSVersion = [System.Environment]::OSVersion.VersionString
            ProcessorCount = [System.Environment]::ProcessorCount
            TotalMemoryGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        }
        Tests = @{}
    }
    
    # Test 1: PowerShell execution performance
    Write-PerformanceLog "Testing PowerShell execution performance"
    $psTimes = @()
    for ($i = 1; $i -le $Iterations; $i++) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $null = Get-Process | Where-Object ProcessName -like "powershell*" | Select-Object -First 5
            $stopwatch.Stop()
            $psTimes += $stopwatch.ElapsedMilliseconds
        } catch {
            $stopwatch.Stop()
            $psTimes += -1
        }
    }
    
    $results.Tests.PowerShellExecution = @{
        AverageMs = if ($psTimes.Where({$_ -gt 0}).Count -gt 0) { 
            [math]::Round(($psTimes.Where({$_ -gt 0}) | Measure-Object -Average).Average, 2) 
        } else { -1 }
        MinMs = if ($psTimes.Where({$_ -gt 0}).Count -gt 0) { 
            ($psTimes.Where({$_ -gt 0}) | Measure-Object -Minimum).Minimum 
        } else { -1 }
        MaxMs = ($psTimes | Measure-Object -Maximum).Maximum
        SuccessRate = [math]::Round(($psTimes.Where({$_ -gt 0}).Count / $Iterations) * 100, 1)
    }
    
    # Test 2: File I/O performance
    Write-PerformanceLog "Testing file I/O performance"
    $ioTimes = @()
    $testData = "Performance test data " * 100
    
    for ($i = 1; $i -le $Iterations; $i++) {
        $testFile = Join-Path $OutputPath "test-$i.txt"
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $testData | Out-File -FilePath $testFile -Encoding UTF8
            $content = Get-Content -Path $testFile
            Remove-Item -Path $testFile -Force
            $stopwatch.Stop()
            $ioTimes += $stopwatch.ElapsedMilliseconds
        } catch {
            $stopwatch.Stop()
            $ioTimes += -1
        }
    }
    
    $results.Tests.FileIO = @{
        AverageMs = if ($ioTimes.Where({$_ -gt 0}).Count -gt 0) { 
            [math]::Round(($ioTimes.Where({$_ -gt 0}) | Measure-Object -Average).Average, 2) 
        } else { -1 }
        MinMs = if ($ioTimes.Where({$_ -gt 0}).Count -gt 0) { 
            ($ioTimes.Where({$_ -gt 0}) | Measure-Object -Minimum).Minimum 
        } else { -1 }
        MaxMs = ($ioTimes | Measure-Object -Maximum).Maximum
        SuccessRate = [math]::Round(($ioTimes.Where({$_ -gt 0}).Count / $Iterations) * 100, 1)
    }
    
    # Test 3: Network connectivity
    Write-PerformanceLog "Testing network connectivity"
    $networkTimes = @()
    for ($i = 1; $i -le $Iterations; $i++) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $result = Test-NetConnection -ComputerName "github.com" -Port 443 -InformationLevel Quiet
            $stopwatch.Stop()
            if ($result) {
                $networkTimes += $stopwatch.ElapsedMilliseconds
            } else {
                $networkTimes += -1
            }
        } catch {
            $stopwatch.Stop()
            $networkTimes += -1
        }
    }
    
    $results.Tests.NetworkConnectivity = @{
        AverageMs = if ($networkTimes.Where({$_ -gt 0}).Count -gt 0) { 
            [math]::Round(($networkTimes.Where({$_ -gt 0}) | Measure-Object -Average).Average, 2) 
        } else { -1 }
        MinMs = if ($networkTimes.Where({$_ -gt 0}).Count -gt 0) { 
            ($networkTimes.Where({$_ -gt 0}) | Measure-Object -Minimum).Minimum 
        } else { -1 }
        MaxMs = ($networkTimes | Measure-Object -Maximum).Maximum
        SuccessRate = [math]::Round(($networkTimes.Where({$_ -gt 0}).Count / $Iterations) * 100, 1)
    }
    
    return $results
}

function Generate-SimpleReport {
    param($Results)
    
    $reportContent = @()
    $reportContent += "# Velociraptor Setup Scripts Performance Baseline"
    $reportContent += ""
    $reportContent += "**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $reportContent += "**Iterations**: $Iterations"
    $reportContent += ""
    $reportContent += "## System Information"
    $reportContent += "- PowerShell Version: $($Results.SystemInfo.PowerShellVersion)"
    $reportContent += "- OS Version: $($Results.SystemInfo.OSVersion)"
    $reportContent += "- Processor Count: $($Results.SystemInfo.ProcessorCount)"
    $reportContent += "- Total Memory: $($Results.SystemInfo.TotalMemoryGB) GB"
    $reportContent += ""
    $reportContent += "## Performance Results"
    $reportContent += ""
    
    foreach ($testName in $Results.Tests.Keys) {
        $test = $Results.Tests[$testName]
        $reportContent += "### $testName"
        $reportContent += "- Average Time: $($test.AverageMs) ms"
        $reportContent += "- Min/Max Time: $($test.MinMs) / $($test.MaxMs) ms"
        $reportContent += "- Success Rate: $($test.SuccessRate)%"
        $reportContent += ""
    }
    
    $reportContent += "## Assessment"
    $reportContent += ""
    
    # PowerShell execution assessment
    $psTest = $Results.Tests.PowerShellExecution
    if ($psTest.AverageMs -ne -1) {
        if ($psTest.AverageMs -lt 100) {
            $reportContent += "- **PowerShell Execution**: Excellent ($($psTest.AverageMs)ms average)"
        } elseif ($psTest.AverageMs -lt 500) {
            $reportContent += "- **PowerShell Execution**: Good ($($psTest.AverageMs)ms average)"
        } else {
            $reportContent += "- **PowerShell Execution**: Needs optimization ($($psTest.AverageMs)ms average)"
        }
    } else {
        $reportContent += "- **PowerShell Execution**: Failed to measure"
    }
    
    # File I/O assessment
    $ioTest = $Results.Tests.FileIO
    if ($ioTest.AverageMs -ne -1) {
        if ($ioTest.AverageMs -lt 50) {
            $reportContent += "- **File I/O**: Excellent ($($ioTest.AverageMs)ms average)"
        } elseif ($ioTest.AverageMs -lt 200) {
            $reportContent += "- **File I/O**: Good ($($ioTest.AverageMs)ms average)"
        } else {
            $reportContent += "- **File I/O**: Slow storage ($($ioTest.AverageMs)ms average)"
        }
    } else {
        $reportContent += "- **File I/O**: Failed to measure"
    }
    
    # Network assessment
    $netTest = $Results.Tests.NetworkConnectivity
    if ($netTest.AverageMs -ne -1) {
        if ($netTest.AverageMs -lt 100) {
            $reportContent += "- **Network Connectivity**: Excellent ($($netTest.AverageMs)ms average)"
        } elseif ($netTest.AverageMs -lt 500) {
            $reportContent += "- **Network Connectivity**: Good ($($netTest.AverageMs)ms average)"
        } else {
            $reportContent += "- **Network Connectivity**: Slow connection ($($netTest.AverageMs)ms average)"
        }
    } else {
        $reportContent += "- **Network Connectivity**: Failed to measure"
    }
    
    $reportContent += ""
    $reportContent += "---"
    $reportContent += "**Report Generated by**: Velociraptor Setup Scripts Performance Monitor v5.0.4-beta"
    
    return $reportContent -join "`n"
}

# Main execution
Write-PerformanceLog "Starting performance measurement baseline"

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Run performance tests
$startTime = Get-Date
$results = Test-BasicPerformance
$endTime = Get-Date

# Save JSON results
$results.TestDuration = [math]::Round(($endTime - $startTime).TotalSeconds, 2)
$jsonPath = Join-Path $OutputPath "performance-baseline.json"
$results | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8

# Generate report
$report = Generate-SimpleReport -Results $results
$reportPath = Join-Path $OutputPath "performance-baseline.md"
$report | Out-File -FilePath $reportPath -Encoding UTF8

Write-PerformanceLog "Performance measurement completed"
Write-Host "Performance baseline established!" -ForegroundColor Green
Write-Host "Results saved to: $jsonPath" -ForegroundColor Cyan
Write-Host "Report saved to: $reportPath" -ForegroundColor Cyan
Write-Host "Test duration: $($results.TestDuration) seconds" -ForegroundColor Cyan

return $results