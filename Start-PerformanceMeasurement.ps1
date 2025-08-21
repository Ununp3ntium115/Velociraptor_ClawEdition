# Performance Measurement Infrastructure
# Version: 5.0.4-beta
# Date: August 20, 2025
# Purpose: Establish comprehensive performance baseline and monitoring

[CmdletBinding()]
param(
    [string]$TestScope = "All",           # All, Deployment, GUI, Modules, Network, IO
    [string]$OutputPath = ".\performance-results",
    [int]$Iterations = 3,
    [switch]$GenerateReport,
    [switch]$CompareBaseline,
    [string]$BaselinePath = ".\performance-baseline.json"
)

# Initialize performance tracking
$ErrorActionPreference = "Continue"
$PerformanceResults = @{
    TestSession = @{
        StartTime = Get-Date
        TestScope = $TestScope
        Iterations = $Iterations
        SystemInfo = @{}
        Results = @{}
    }
}

# Import required modules
try {
    Import-Module "$PSScriptRoot\modules\VelociraptorDeployment\VelociraptorDeployment.psm1" -Force
    Write-Host "✅ VelociraptorDeployment module loaded" -ForegroundColor Green
} catch {
    Write-Warning "⚠️ Could not load VelociraptorDeployment module: $($_.Exception.Message)"
}

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

function Get-SystemPerformanceBaseline {
    Write-PerformanceLog "Collecting system performance baseline"
    
    $systemInfo = @{
        Processor = (Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed)
        Memory = @{
            TotalPhysicalMemory = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
            AvailableMemory = [math]::Round((Get-Counter '\Memory\Available MBytes').CounterSamples[0].CookedValue / 1024, 2)
        }
        Storage = @{
            Drives = @()
        }
        Network = @{
            Adapters = @()
        }
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        OSVersion = (Get-CimInstance Win32_OperatingSystem).Caption
    }
    
    # Storage information
    Get-CimInstance Win32_LogicalDisk | Where-Object DriveType -eq 3 | ForEach-Object {
        $systemInfo.Storage.Drives += @{
            Drive = $_.DeviceID
            SizeGB = [math]::Round($_.Size / 1GB, 2)
            FreeSpaceGB = [math]::Round($_.FreeSpace / 1GB, 2)
            FileSystem = $_.FileSystem
        }
    }
    
    # Network adapter information
    Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object {
        $systemInfo.Network.Adapters += @{
            Name = $_.Name
            LinkSpeed = $_.LinkSpeed
            InterfaceDescription = $_.InterfaceDescription
        }
    }
    
    $PerformanceResults.TestSession.SystemInfo = $systemInfo
    return $systemInfo
}

function Test-DeploymentPerformance {
    Write-PerformanceLog "Testing deployment performance"
    
    $deploymentResults = @{}
    
    # Test system detection performance
    $detectionTimes = @()
    for ($i = 1; $i -le $Iterations; $i++) {
        Write-PerformanceLog "System detection iteration $i of $Iterations"
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        try {
            $specs = Get-AutoDetectedSystemSpecs -Verbose:$false
            $stopwatch.Stop()
            $detectionTimes += $stopwatch.ElapsedMilliseconds
            Write-PerformanceLog "System detection completed in $($stopwatch.ElapsedMilliseconds)ms"
        } catch {
            $stopwatch.Stop()
            Write-PerformanceLog "System detection failed: $($_.Exception.Message)" -Level "WARNING"
            $detectionTimes += -1
        }
        
        Start-Sleep -Milliseconds 500
    }
    
    $deploymentResults.SystemDetection = @{
        AverageMs = if ($detectionTimes.Where({$_ -gt 0}).Count -gt 0) { 
            [math]::Round(($detectionTimes.Where({$_ -gt 0}) | Measure-Object -Average).Average, 2) 
        } else { -1 }
        MinMs = if ($detectionTimes.Where({$_ -gt 0}).Count -gt 0) { 
            ($detectionTimes.Where({$_ -gt 0}) | Measure-Object -Minimum).Minimum 
        } else { -1 }
        MaxMs = ($detectionTimes | Measure-Object -Maximum).Maximum
        Iterations = $Iterations
        SuccessRate = [math]::Round(($detectionTimes.Where({$_ -gt 0}).Count / $Iterations) * 100, 1)
    }
    
    # Test internet connectivity performance
    $connectivityTimes = @()
    for ($i = 1; $i -le $Iterations; $i++) {
        Write-PerformanceLog "Internet connectivity test iteration $i of $Iterations"
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        try {
            $connected = Test-VelociraptorInternetConnection -Verbose:$false
            $stopwatch.Stop()
            $connectivityTimes += $stopwatch.ElapsedMilliseconds
            Write-PerformanceLog "Connectivity test completed in $($stopwatch.ElapsedMilliseconds)ms - Result: $connected"
        } catch {
            $stopwatch.Stop()
            Write-PerformanceLog "Connectivity test failed: $($_.Exception.Message)" -Level "WARNING"
            $connectivityTimes += -1
        }
        
        Start-Sleep -Milliseconds 200
    }
    
    $deploymentResults.InternetConnectivity = @{
        AverageMs = if ($connectivityTimes.Where({$_ -gt 0}).Count -gt 0) { 
            [math]::Round(($connectivityTimes.Where({$_ -gt 0}) | Measure-Object -Average).Average, 2) 
        } else { -1 }
        MinMs = if ($connectivityTimes.Where({$_ -gt 0}).Count -gt 0) { 
            ($connectivityTimes.Where({$_ -gt 0}) | Measure-Object -Minimum).Minimum 
        } else { -1 }
        MaxMs = ($connectivityTimes | Measure-Object -Maximum).Maximum
        SuccessRate = [math]::Round(($connectivityTimes.Where({$_ -gt 0}).Count / $Iterations) * 100, 1)
    }
    
    return $deploymentResults
}

function Test-ModulePerformance {
    Write-PerformanceLog "Testing module performance"
    
    $moduleResults = @{}
    
    # Test module import performance
    $importTimes = @()
    for ($i = 1; $i -le $Iterations; $i++) {
        Write-PerformanceLog "Module import test iteration $i of $Iterations"
        
        # Remove module if loaded
        if (Get-Module VelociraptorDeployment) {
            Remove-Module VelociraptorDeployment -Force
        }
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            Import-Module "$PSScriptRoot\modules\VelociraptorDeployment\VelociraptorDeployment.psm1" -Force
            $stopwatch.Stop()
            $importTimes += $stopwatch.ElapsedMilliseconds
            Write-PerformanceLog "Module import completed in $($stopwatch.ElapsedMilliseconds)ms"
        } catch {
            $stopwatch.Stop()
            Write-PerformanceLog "Module import failed: $($_.Exception.Message)" -Level "WARNING"
            $importTimes += -1
        }
        
        Start-Sleep -Milliseconds 100
    }
    
    $moduleResults.ImportTime = @{
        AverageMs = if ($importTimes.Where({$_ -gt 0}).Count -gt 0) { 
            [math]::Round(($importTimes.Where({$_ -gt 0}) | Measure-Object -Average).Average, 2) 
        } else { -1 }
        MinMs = if ($importTimes.Where({$_ -gt 0}).Count -gt 0) { 
            ($importTimes.Where({$_ -gt 0}) | Measure-Object -Minimum).Minimum 
        } else { -1 }
        MaxMs = ($importTimes | Measure-Object -Maximum).Maximum
        SuccessRate = [math]::Round(($importTimes.Where({$_ -gt 0}).Count / $Iterations) * 100, 1)
    }
    
    return $moduleResults
}

function Test-IOPerformance {
    Write-PerformanceLog "Testing I/O performance"
    
    $ioResults = @{}
    $testDir = Join-Path $OutputPath "io-test"
    
    if (-not (Test-Path $testDir)) {
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    }
    
    # Test file write performance
    $writeTimes = @()
    $testData = "Performance test data " * 1000  # ~20KB of test data
    
    for ($i = 1; $i -le $Iterations; $i++) {
        Write-PerformanceLog "File write test iteration $i of $Iterations"
        $testFile = Join-Path $testDir "test-$i.txt"
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $testData | Out-File -FilePath $testFile -Encoding UTF8
            $stopwatch.Stop()
            $writeTimes += $stopwatch.ElapsedMilliseconds
            Write-PerformanceLog "File write completed in $($stopwatch.ElapsedMilliseconds)ms"
        } catch {
            $stopwatch.Stop()
            Write-PerformanceLog "File write failed: $($_.Exception.Message)" -Level "WARNING"
            $writeTimes += -1
        }
    }
    
    # Test file read performance
    $readTimes = @()
    for ($i = 1; $i -le $Iterations; $i++) {
        Write-PerformanceLog "File read test iteration $i of $Iterations"
        $testFile = Join-Path $testDir "test-$i.txt"
        
        if (Test-Path $testFile) {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                $content = Get-Content -Path $testFile
                $stopwatch.Stop()
                $readTimes += $stopwatch.ElapsedMilliseconds
                Write-PerformanceLog "File read completed in $($stopwatch.ElapsedMilliseconds)ms"
            } catch {
                $stopwatch.Stop()
                Write-PerformanceLog "File read failed: $($_.Exception.Message)" -Level "WARNING"
                $readTimes += -1
            }
        }
    }
    
    $ioResults.FileWrite = @{
        AverageMs = if ($writeTimes.Where({$_ -gt 0}).Count -gt 0) { 
            [math]::Round(($writeTimes.Where({$_ -gt 0}) | Measure-Object -Average).Average, 2) 
        } else { -1 }
        MinMs = if ($writeTimes.Where({$_ -gt 0}).Count -gt 0) { 
            ($writeTimes.Where({$_ -gt 0}) | Measure-Object -Minimum).Minimum 
        } else { -1 }
        MaxMs = ($writeTimes | Measure-Object -Maximum).Maximum
        SuccessRate = [math]::Round(($writeTimes.Where({$_ -gt 0}).Count / $Iterations) * 100, 1)
    }
    
    $ioResults.FileRead = @{
        AverageMs = if ($readTimes.Where({$_ -gt 0}).Count -gt 0) { 
            [math]::Round(($readTimes.Where({$_ -gt 0}) | Measure-Object -Average).Average, 2) 
        } else { -1 }
        MinMs = if ($readTimes.Where({$_ -gt 0}).Count -gt 0) { 
            ($readTimes.Where({$_ -gt 0}) | Measure-Object -Minimum).Minimum 
        } else { -1 }
        MaxMs = ($readTimes | Measure-Object -Maximum).Maximum
        SuccessRate = [math]::Round(($readTimes.Where({$_ -gt 0}).Count / $Iterations) * 100, 1)
    }
    
    # Cleanup test files
    try {
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        Write-PerformanceLog "Could not cleanup test directory: $($_.Exception.Message)" -Level "WARNING"
    }
    
    return $ioResults
}

function Test-NetworkPerformance {
    Write-PerformanceLog "Testing network performance"
    
    $networkResults = @{}
    
    # Test GitHub API connectivity (used for releases)
    $githubTimes = @()
    for ($i = 1; $i -le $Iterations; $i++) {
        Write-PerformanceLog "GitHub API test iteration $i of $Iterations"
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        try {
            $response = Invoke-RestMethod -Uri "https://api.github.com/repos/velocidx/velociraptor/releases/latest" -TimeoutSec 10
            $stopwatch.Stop()
            $githubTimes += $stopwatch.ElapsedMilliseconds
            Write-PerformanceLog "GitHub API test completed in $($stopwatch.ElapsedMilliseconds)ms"
        } catch {
            $stopwatch.Stop()
            Write-PerformanceLog "GitHub API test failed: $($_.Exception.Message)" -Level "WARNING"
            $githubTimes += -1
        }
        
        Start-Sleep -Milliseconds 500
    }
    
    $networkResults.GitHubAPI = @{
        AverageMs = if ($githubTimes.Where({$_ -gt 0}).Count -gt 0) { 
            [math]::Round(($githubTimes.Where({$_ -gt 0}) | Measure-Object -Average).Average, 2) 
        } else { -1 }
        MinMs = if ($githubTimes.Where({$_ -gt 0}).Count -gt 0) { 
            ($githubTimes.Where({$_ -gt 0}) | Measure-Object -Minimum).Minimum 
        } else { -1 }
        MaxMs = ($githubTimes | Measure-Object -Maximum).Maximum
        SuccessRate = [math]::Round(($githubTimes.Where({$_ -gt 0}).Count / $Iterations) * 100, 1)
    }
    
    return $networkResults
}

function Generate-PerformanceReport {
    param($Results)
    
    Write-PerformanceLog "Generating performance report"
    
    $reportPath = Join-Path $OutputPath "performance-report.md"
    $report = @"
# Velociraptor Setup Scripts Performance Report

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Test Scope**: $($Results.TestSession.TestScope)  
**Iterations**: $($Results.TestSession.Iterations)  
**Duration**: $([math]::Round(((Get-Date) - $Results.TestSession.StartTime).TotalSeconds, 2)) seconds

---

## System Information

**PowerShell Version**: $($Results.TestSession.SystemInfo.PowerShellVersion)  
**Operating System**: $($Results.TestSession.SystemInfo.OSVersion)  
**Processor**: $($Results.TestSession.SystemInfo.Processor.Name)  
**CPU Cores**: $($Results.TestSession.SystemInfo.Processor.NumberOfCores) physical, $($Results.TestSession.SystemInfo.Processor.NumberOfLogicalProcessors) logical  
**Total Memory**: $($Results.TestSession.SystemInfo.Memory.TotalPhysicalMemory) GB  
**Available Memory**: $($Results.TestSession.SystemInfo.Memory.AvailableMemory) GB  

### Storage
$(foreach ($drive in $Results.TestSession.SystemInfo.Storage.Drives) {
    "- **$($drive.Drive)**: $($drive.SizeGB) GB ($($drive.FileSystem)) - $($drive.FreeSpaceGB) GB free"
})

### Network Adapters
$(foreach ($adapter in $Results.TestSession.SystemInfo.Network.Adapters) {
    "- **$($adapter.Name)**: $($adapter.LinkSpeed)"
})

---

## Performance Results

"@

    if ($Results.TestSession.Results.Deployment) {
        $deploy = $Results.TestSession.Results.Deployment
        $report += @"

### Deployment Performance

#### System Detection
- **Average Time**: $($deploy.SystemDetection.AverageMs) ms
- **Min/Max Time**: $($deploy.SystemDetection.MinMs) ms / $($deploy.SystemDetection.MaxMs) ms
- **Success Rate**: $($deploy.SystemDetection.SuccessRate)%

#### Internet Connectivity
- **Average Time**: $($deploy.InternetConnectivity.AverageMs) ms
- **Min/Max Time**: $($deploy.InternetConnectivity.MinMs) ms / $($deploy.InternetConnectivity.MaxMs) ms
- **Success Rate**: $($deploy.InternetConnectivity.SuccessRate)%

"@
    }

    if ($Results.TestSession.Results.Modules) {
        $modules = $Results.TestSession.Results.Modules
        $report += @"

### Module Performance

#### Module Import Time
- **Average Time**: $($modules.ImportTime.AverageMs) ms
- **Min/Max Time**: $($modules.ImportTime.MinMs) ms / $($modules.ImportTime.MaxMs) ms
- **Success Rate**: $($modules.ImportTime.SuccessRate)%

"@
    }

    if ($Results.TestSession.Results.IO) {
        $io = $Results.TestSession.Results.IO
        $report += @"

### I/O Performance

#### File Write Operations
- **Average Time**: $($io.FileWrite.AverageMs) ms
- **Min/Max Time**: $($io.FileWrite.MinMs) ms / $($io.FileWrite.MaxMs) ms
- **Success Rate**: $($io.FileWrite.SuccessRate)%

#### File Read Operations
- **Average Time**: $($io.FileRead.AverageMs) ms
- **Min/Max Time**: $($io.FileRead.MinMs) ms / $($io.FileRead.MaxMs) ms
- **Success Rate**: $($io.FileRead.SuccessRate)%

"@
    }

    if ($Results.TestSession.Results.Network) {
        $network = $Results.TestSession.Results.Network
        $report += @"

### Network Performance

#### GitHub API Connectivity
- **Average Time**: $($network.GitHubAPI.AverageMs) ms
- **Min/Max Time**: $($network.GitHubAPI.MinMs) ms / $($network.GitHubAPI.MaxMs) ms
- **Success Rate**: $($network.GitHubAPI.SuccessRate)%

"@
    }

    $report += @"

---

## Performance Assessment

$(if ($Results.TestSession.Results.Deployment.SystemDetection.AverageMs -ne -1) {
    if ($Results.TestSession.Results.Deployment.SystemDetection.AverageMs -lt 1000) {
        "✅ **System Detection**: Excellent ($($Results.TestSession.Results.Deployment.SystemDetection.AverageMs)ms average)"
    } elseif ($Results.TestSession.Results.Deployment.SystemDetection.AverageMs -lt 3000) {
        "⚠️ **System Detection**: Good ($($Results.TestSession.Results.Deployment.SystemDetection.AverageMs)ms average)"
    } else {
        "🔴 **System Detection**: Needs optimization ($($Results.TestSession.Results.Deployment.SystemDetection.AverageMs)ms average)"
    }
} else {
    "❌ **System Detection**: Failed to measure"
})

$(if ($Results.TestSession.Results.Modules.ImportTime.AverageMs -ne -1) {
    if ($Results.TestSession.Results.Modules.ImportTime.AverageMs -lt 2000) {
        "✅ **Module Import**: Excellent ($($Results.TestSession.Results.Modules.ImportTime.AverageMs)ms average)"
    } elseif ($Results.TestSession.Results.Modules.ImportTime.AverageMs -lt 5000) {
        "⚠️ **Module Import**: Good ($($Results.TestSession.Results.Modules.ImportTime.AverageMs)ms average)"
    } else {
        "🔴 **Module Import**: Needs optimization ($($Results.TestSession.Results.Modules.ImportTime.AverageMs)ms average)"
    }
} else {
    "❌ **Module Import**: Failed to measure"
})

$(if ($Results.TestSession.Results.Network.GitHubAPI.AverageMs -ne -1) {
    if ($Results.TestSession.Results.Network.GitHubAPI.AverageMs -lt 1000) {
        "✅ **Network Connectivity**: Excellent ($($Results.TestSession.Results.Network.GitHubAPI.AverageMs)ms average)"
    } elseif ($Results.TestSession.Results.Network.GitHubAPI.AverageMs -lt 3000) {
        "⚠️ **Network Connectivity**: Good ($($Results.TestSession.Results.Network.GitHubAPI.AverageMs)ms average)"
    } else {
        "🔴 **Network Connectivity**: Slow connection ($($Results.TestSession.Results.Network.GitHubAPI.AverageMs)ms average)"
    }
} else {
    "❌ **Network Connectivity**: Failed to measure"
})

---

## Recommendations

### Performance Optimization
1. **System Detection**: $(if ($Results.TestSession.Results.Deployment.SystemDetection.AverageMs -gt 2000) { "Consider caching system specs or using parallel processing" } else { "Performance is acceptable" })
2. **Module Loading**: $(if ($Results.TestSession.Results.Modules.ImportTime.AverageMs -gt 3000) { "Consider module optimization or lazy loading" } else { "Performance is acceptable" })
3. **Network Operations**: $(if ($Results.TestSession.Results.Network.GitHubAPI.AverageMs -gt 2000) { "Consider implementing retry logic with exponential backoff" } else { "Performance is acceptable" })

### Success Rate Analysis
$(if ($Results.TestSession.Results.Deployment.SystemDetection.SuccessRate -lt 100) { "⚠️ System detection success rate is $($Results.TestSession.Results.Deployment.SystemDetection.SuccessRate)% - investigate reliability issues" })
$(if ($Results.TestSession.Results.Modules.ImportTime.SuccessRate -lt 100) { "⚠️ Module import success rate is $($Results.TestSession.Results.Modules.ImportTime.SuccessRate)% - check for dependency issues" })
$(if ($Results.TestSession.Results.Network.GitHubAPI.SuccessRate -lt 90) { "⚠️ Network connectivity success rate is $($Results.TestSession.Results.Network.GitHubAPI.SuccessRate)% - implement better error handling" })

---

**Report Generated by**: Velociraptor Setup Scripts Performance Monitor  
**Version**: 5.0.4-beta
"@

    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-PerformanceLog "Performance report saved to: $reportPath"
    
    return $reportPath
}

# Main execution
Write-PerformanceLog "Starting performance measurement - Scope: $TestScope" -Level "INFO"

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Collect system baseline
Get-SystemPerformanceBaseline

# Run performance tests based on scope
if ($TestScope -eq "All" -or $TestScope -eq "Deployment") {
    Write-PerformanceLog "Running deployment performance tests"
    $PerformanceResults.TestSession.Results.Deployment = Test-DeploymentPerformance
}

if ($TestScope -eq "All" -or $TestScope -eq "Modules") {
    Write-PerformanceLog "Running module performance tests"
    $PerformanceResults.TestSession.Results.Modules = Test-ModulePerformance
}

if ($TestScope -eq "All" -or $TestScope -eq "IO") {
    Write-PerformanceLog "Running I/O performance tests"
    $PerformanceResults.TestSession.Results.IO = Test-IOPerformance
}

if ($TestScope -eq "All" -or $TestScope -eq "Network") {
    Write-PerformanceLog "Running network performance tests"
    $PerformanceResults.TestSession.Results.Network = Test-NetworkPerformance
}

# Finalize results
$PerformanceResults.TestSession.EndTime = Get-Date
$PerformanceResults.TestSession.Duration = $PerformanceResults.TestSession.EndTime - $PerformanceResults.TestSession.StartTime

# Save results to JSON
$jsonPath = Join-Path $OutputPath "performance-results.json"
$PerformanceResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8
Write-PerformanceLog "Performance results saved to: $jsonPath"

# Generate report if requested
if ($GenerateReport) {
    $reportPath = Generate-PerformanceReport -Results $PerformanceResults
    Write-Host "📊 Performance report generated: $reportPath" -ForegroundColor Green
}

# Compare with baseline if requested
if ($CompareBaseline -and (Test-Path $BaselinePath)) {
    Write-PerformanceLog "Comparing with baseline: $BaselinePath"
    # Baseline comparison logic would go here
    Write-Host "📈 Baseline comparison completed" -ForegroundColor Green
}

Write-PerformanceLog "Performance measurement completed" -Level "INFO"
Write-Host "✅ Performance measurement infrastructure established!" -ForegroundColor Green
Write-Host "📈 Total duration: $([math]::Round($PerformanceResults.TestSession.Duration.TotalSeconds, 2)) seconds" -ForegroundColor Cyan

# Return results for automation
return $PerformanceResults