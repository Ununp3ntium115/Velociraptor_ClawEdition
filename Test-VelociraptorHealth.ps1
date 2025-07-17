<#
.SYNOPSIS
    Comprehensive health check for Velociraptor deployments.

.DESCRIPTION
    Performs detailed health checks including:
    • Service status and performance
    • Configuration validation
    • Network connectivity
    • Resource utilization
    • Log analysis
    • Security posture

.PARAMETER InstallPath
    Path to Velociraptor installation

.PARAMETER ConfigPath
    Path to configuration file

.PARAMETER Detailed
    Perform detailed analysis including log parsing

.PARAMETER ExportReport
    Export results to JSON/HTML report

.EXAMPLE
    .\Test-VelociraptorHealth.ps1 -InstallPath "C:\tools\velociraptor.exe"

.EXAMPLE
    .\Test-VelociraptorHealth.ps1 -Detailed -ExportReport
#>

[CmdletBinding()]
param(
    [string]$InstallPath = 'C:\tools\velociraptor.exe',
    [string]$ConfigPath,
    [switch]$Detailed,
    [switch]$ExportReport
)

$ErrorActionPreference = 'Continue'  # Continue on errors to collect all health data

function Write-HealthLog {
    param([string]$Message, [string]$Level = 'Info')
    
    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Info' { 'Cyan' }
        default { 'White' }
    }
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $color
}

function Test-VelociraptorService {
    Write-HealthLog "=== Service Health Check ===" -Level 'Info'
    
    $serviceHealth = @{
        ServiceExists = $false
        ServiceStatus = 'Unknown'
        ServiceStartType = 'Unknown'
        ProcessRunning = $false
        ProcessDetails = @()
        MemoryUsage = 0
        CPUUsage = 0
        Uptime = $null
        Issues = @()
    }
    
    try {
        # Check Windows service
        $service = Get-Service -Name "Velociraptor" -ErrorAction SilentlyContinue
        if ($service) {
            $serviceHealth.ServiceExists = $true
            $serviceHealth.ServiceStatus = $service.Status
            $serviceHealth.ServiceStartType = $service.StartType
            
            Write-HealthLog "✓ Service found: $($service.Status)" -Level $(if ($service.Status -eq 'Running') { 'Success' } else { 'Warning' })
        } else {
            $serviceHealth.Issues += "Velociraptor Windows service not found"
            Write-HealthLog "✗ Velociraptor service not found" -Level 'Warning'
        }
        
        # Check processes
        $processes = Get-Process -Name "*velociraptor*" -ErrorAction SilentlyContinue
        if ($processes) {
            $serviceHealth.ProcessRunning = $true
            
            foreach ($proc in $processes) {
                $processInfo = @{
                    Id = $proc.Id
                    Name = $proc.Name
                    Path = $proc.Path
                    StartTime = $proc.StartTime
                    WorkingSet = $proc.WorkingSet64
                    VirtualMemory = $proc.VirtualMemorySize64
                    CPUTime = $proc.TotalProcessorTime
                }
                
                $serviceHealth.ProcessDetails += $processInfo
                $serviceHealth.MemoryUsage += $proc.WorkingSet64
                
                $uptime = (Get-Date) - $proc.StartTime
                if (-not $serviceHealth.Uptime -or $uptime -gt $serviceHealth.Uptime) {
                    $serviceHealth.Uptime = $uptime
                }
                
                Write-HealthLog "✓ Process: $($proc.Name) (PID: $($proc.Id), Memory: $([math]::Round($proc.WorkingSet64/1MB, 2)) MB)" -Level 'Success'
            }
        } else {
            $serviceHealth.Issues += "No Velociraptor processes running"
            Write-HealthLog "✗ No Velociraptor processes found" -Level 'Warning'
        }
        
        # Performance counters (if available)
        try {
            $perfCounters = Get-Counter -Counter "\Process(velociraptor*)\% Processor Time" -ErrorAction SilentlyContinue
            if ($perfCounters) {
                $serviceHealth.CPUUsage = ($perfCounters.CounterSamples | Measure-Object -Property CookedValue -Average).Average
            }
        } catch {
            # Performance counters not available or accessible
        }
        
    } catch {
        $serviceHealth.Issues += "Error checking service: $($_.Exception.Message)"
        Write-HealthLog "✗ Error checking service: $($_.Exception.Message)" -Level 'Error'
    }
    
    return $serviceHealth
}

function Test-VelociraptorConfiguration {
    param([string]$ConfigPath)
    
    Write-HealthLog "=== Configuration Health Check ===" -Level 'Info'
    
    $configHealth = @{
        ConfigExists = $false
        ConfigValid = $false
        ConfigSize = 0
        LastModified = $null
        Issues = @()
        Warnings = @()
        SecurityIssues = @()
    }
    
    if (-not $ConfigPath) {
        # Try to find config file
        $possiblePaths = @(
            'C:\tools\server.yaml',
            'C:\tools\client.yaml',
            'C:\Program Files\Velociraptor\server.yaml'
        )
        
        foreach ($path in $possiblePaths) {
            if (Test-Path $path) {
                $ConfigPath = $path
                break
            }
        }
    }
    
    if (-not $ConfigPath -or -not (Test-Path $ConfigPath)) {
        $configHealth.Issues += "Configuration file not found"
        Write-HealthLog "✗ Configuration file not found" -Level 'Error'
        return $configHealth
    }
    
    try {
        $configFile = Get-Item $ConfigPath
        $configHealth.ConfigExists = $true
        $configHealth.ConfigSize = $configFile.Length
        $configHealth.LastModified = $configFile.LastWriteTime
        
        Write-HealthLog "✓ Config found: $ConfigPath" -Level 'Success'
        Write-HealthLog "  Size: $([math]::Round($configFile.Length/1KB, 2)) KB, Modified: $($configFile.LastWriteTime)" -Level 'Info'
        
        # Basic validation
        $content = Get-Content $ConfigPath -Raw
        
        # Check for required sections
        $requiredSections = @('version:', 'Client:', 'Frontend:', 'GUI:', 'Datastore:')
        foreach ($section in $requiredSections) {
            if ($content -notmatch $section) {
                $configHealth.Issues += "Missing required section: $section"
            }
        }
        
        # Security checks
        if ($content -match 'bind_address:\s*0\.0\.0\.0') {
            $configHealth.SecurityIssues += "Binding to all interfaces (0.0.0.0) - security risk"
        }
        
        if ($content -match 'autocert_domain:.*localhost') {
            $configHealth.Warnings += "Using localhost for autocert domain"
        }
        
        # Check for default passwords or keys
        if ($content -match 'password.*admin' -or $content -match 'secret.*changeme') {
            $configHealth.SecurityIssues += "Default credentials detected"
        }
        
        # Port conflicts
        $portPattern = 'bind_port:\s*(\d+)'
        $ports = [regex]::Matches($content, $portPattern) | ForEach-Object { [int]$_.Groups[1].Value }
        $duplicatePorts = $ports | Group-Object | Where-Object { $_.Count -gt 1 }
        
        if ($duplicatePorts) {
            $configHealth.Issues += "Duplicate ports: $($duplicatePorts.Name -join ', ')"
        }
        
        $configHealth.ConfigValid = ($configHealth.Issues.Count -eq 0)
        
        # Report results
        if ($configHealth.ConfigValid) {
            Write-HealthLog "✓ Configuration validation passed" -Level 'Success'
        } else {
            Write-HealthLog "✗ Configuration has issues" -Level 'Warning'
            $configHealth.Issues | ForEach-Object { Write-HealthLog "  - $_" -Level 'Warning' }
        }
        
        if ($configHealth.SecurityIssues.Count -gt 0) {
            Write-HealthLog "⚠ Security issues found:" -Level 'Warning'
            $configHealth.SecurityIssues | ForEach-Object { Write-HealthLog "  - $_" -Level 'Warning' }
        }
        
    } catch {
        $configHealth.Issues += "Error reading configuration: $($_.Exception.Message)"
        Write-HealthLog "✗ Error reading configuration: $($_.Exception.Message)" -Level 'Error'
    }
    
    return $configHealth
}

function Test-VelociraptorConnectivity {
    Write-HealthLog "=== Network Connectivity Check ===" -Level 'Info'
    
    $connectivityHealth = @{
        LocalPorts = @()
        ExternalConnectivity = $false
        DNSResolution = $false
        CertificateValid = $false
        Issues = @()
    }
    
    try {
        # Check listening ports
        $commonPorts = @(8000, 8001, 8889)
        foreach ($port in $commonPorts) {
            $connection = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
            if ($connection) {
                $connectivityHealth.LocalPorts += @{
                    Port = $port
                    ProcessId = $connection.OwningProcess
                    State = $connection.State
                }
                Write-HealthLog "✓ Port $port is listening (PID: $($connection.OwningProcess))" -Level 'Success'
            } else {
                Write-HealthLog "○ Port $port not listening" -Level 'Info'
            }
        }
        
        # Test external connectivity (if GUI port is available)
        $guiPort = $connectivityHealth.LocalPorts | Where-Object { $_.Port -eq 8889 } | Select-Object -First 1
        if ($guiPort) {
            try {
                $testUrl = "https://localhost:8889"
                $response = Invoke-WebRequest -Uri $testUrl -Method Head -TimeoutSec 5 -SkipCertificateCheck -ErrorAction Stop
                $connectivityHealth.ExternalConnectivity = $true
                Write-HealthLog "✓ GUI interface accessible" -Level 'Success'
            } catch {
                $connectivityHealth.Issues += "GUI interface not accessible: $($_.Exception.Message)"
                Write-HealthLog "✗ GUI interface not accessible" -Level 'Warning'
            }
        }
        
        # DNS resolution test
        try {
            $dnsTest = Resolve-DnsName "api.github.com" -ErrorAction Stop
            $connectivityHealth.DNSResolution = $true
            Write-HealthLog "✓ DNS resolution working" -Level 'Success'
        } catch {
            $connectivityHealth.Issues += "DNS resolution failed"
            Write-HealthLog "✗ DNS resolution failed" -Level 'Warning'
        }
        
    } catch {
        $connectivityHealth.Issues += "Error checking connectivity: $($_.Exception.Message)"
        Write-HealthLog "✗ Error checking connectivity: $($_.Exception.Message)" -Level 'Error'
    }
    
    return $connectivityHealth
}

function Test-VelociraptorResources {
    Write-HealthLog "=== Resource Utilization Check ===" -Level 'Info'
    
    $resourceHealth = @{
        DiskSpace = @()
        MemoryUsage = @{}
        CPUUsage = 0
        Issues = @()
        Warnings = @()
    }
    
    try {
        # Disk space check
        $drives = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        foreach ($drive in $drives) {
            $freeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
            $totalSpaceGB = [math]::Round($drive.Size / 1GB, 2)
            $usedPercent = [math]::Round((($drive.Size - $drive.FreeSpace) / $drive.Size) * 100, 1)
            
            $driveInfo = @{
                Drive = $drive.DeviceID
                TotalGB = $totalSpaceGB
                FreeGB = $freeSpaceGB
                UsedPercent = $usedPercent
            }
            
            $resourceHealth.DiskSpace += $driveInfo
            
            if ($usedPercent -gt 90) {
                $resourceHealth.Issues += "Drive $($drive.DeviceID) is $usedPercent% full"
                Write-HealthLog "✗ Drive $($drive.DeviceID): $usedPercent% full ($freeSpaceGB GB free)" -Level 'Error'
            } elseif ($usedPercent -gt 80) {
                $resourceHealth.Warnings += "Drive $($drive.DeviceID) is $usedPercent% full"
                Write-HealthLog "⚠ Drive $($drive.DeviceID): $usedPercent% full ($freeSpaceGB GB free)" -Level 'Warning'
            } else {
                Write-HealthLog "✓ Drive $($drive.DeviceID): $usedPercent% full ($freeSpaceGB GB free)" -Level 'Success'
            }
        }
        
        # Memory usage
        $memory = Get-WmiObject -Class Win32_OperatingSystem
        $totalMemoryGB = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
        $freeMemoryGB = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
        $usedMemoryPercent = [math]::Round((($totalMemoryGB - $freeMemoryGB) / $totalMemoryGB) * 100, 1)
        
        $resourceHealth.MemoryUsage = @{
            TotalGB = $totalMemoryGB
            FreeGB = $freeMemoryGB
            UsedPercent = $usedMemoryPercent
        }
        
        if ($usedMemoryPercent -gt 90) {
            $resourceHealth.Issues += "Memory usage is $usedMemoryPercent%"
            Write-HealthLog "✗ Memory: $usedMemoryPercent% used ($freeMemoryGB GB free)" -Level 'Error'
        } elseif ($usedMemoryPercent -gt 80) {
            $resourceHealth.Warnings += "Memory usage is $usedMemoryPercent%"
            Write-HealthLog "⚠ Memory: $usedMemoryPercent% used ($freeMemoryGB GB free)" -Level 'Warning'
        } else {
            Write-HealthLog "✓ Memory: $usedMemoryPercent% used ($freeMemoryGB GB free)" -Level 'Success'
        }
        
        # CPU usage (average over 5 seconds)
        try {
            $cpuSamples = @()
            for ($i = 0; $i -lt 3; $i++) {
                $cpu = Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average
                $cpuSamples += $cpu.Average
                Start-Sleep -Seconds 2
            }
            $resourceHealth.CPUUsage = [math]::Round(($cpuSamples | Measure-Object -Average).Average, 1)
            
            if ($resourceHealth.CPUUsage -gt 80) {
                $resourceHealth.Issues += "High CPU usage: $($resourceHealth.CPUUsage)%"
                Write-HealthLog "✗ CPU: $($resourceHealth.CPUUsage)% average" -Level 'Error'
            } elseif ($resourceHealth.CPUUsage -gt 60) {
                $resourceHealth.Warnings += "Elevated CPU usage: $($resourceHealth.CPUUsage)%"
                Write-HealthLog "⚠ CPU: $($resourceHealth.CPUUsage)% average" -Level 'Warning'
            } else {
                Write-HealthLog "✓ CPU: $($resourceHealth.CPUUsage)% average" -Level 'Success'
            }
        } catch {
            Write-HealthLog "○ Could not measure CPU usage" -Level 'Info'
        }
        
    } catch {
        $resourceHealth.Issues += "Error checking resources: $($_.Exception.Message)"
        Write-HealthLog "✗ Error checking resources: $($_.Exception.Message)" -Level 'Error'
    }
    
    return $resourceHealth
}

function Test-VelociraptorLogs {
    param([bool]$Detailed)
    
    Write-HealthLog "=== Log Analysis ===" -Level 'Info'
    
    $logHealth = @{
        LogsFound = @()
        RecentErrors = @()
        RecentWarnings = @()
        LogSize = 0
        Issues = @()
    }
    
    try {
        # Common log locations
        $logPaths = @(
            'C:\tools\logs',
            'C:\Program Files\Velociraptor\logs',
            'C:\ProgramData\Velociraptor\logs',
            'C:\VelociraptorData\logs'
        )
        
        foreach ($logPath in $logPaths) {
            if (Test-Path $logPath) {
                $logFiles = Get-ChildItem -Path $logPath -Filter "*.log" -Recurse -ErrorAction SilentlyContinue
                foreach ($logFile in $logFiles) {
                    $logHealth.LogsFound += @{
                        Path = $logFile.FullName
                        Size = $logFile.Length
                        LastModified = $logFile.LastWriteTime
                    }
                    $logHealth.LogSize += $logFile.Length
                }
            }
        }
        
        if ($logHealth.LogsFound.Count -eq 0) {
            $logHealth.Issues += "No log files found"
            Write-HealthLog "✗ No log files found" -Level 'Warning'
        } else {
            Write-HealthLog "✓ Found $($logHealth.LogsFound.Count) log files (Total: $([math]::Round($logHealth.LogSize/1MB, 2)) MB)" -Level 'Success'
            
            if ($Detailed) {
                # Analyze recent log entries
                $recentLogs = $logHealth.LogsFound | Where-Object { $_.LastModified -gt (Get-Date).AddHours(-24) }
                
                foreach ($logFile in $recentLogs) {
                    try {
                        $content = Get-Content $logFile.Path -Tail 100 -ErrorAction SilentlyContinue
                        
                        # Look for errors and warnings
                        $errors = $content | Where-Object { $_ -match '\[ERROR\]|\bERROR\b|\bFAILED\b' }
                        $warnings = $content | Where-Object { $_ -match '\[WARN\]|\bWARN\b|\bWARNING\b' }
                        
                        $logHealth.RecentErrors += $errors | Select-Object -First 5
                        $logHealth.RecentWarnings += $warnings | Select-Object -First 5
                    } catch {
                        # Skip files that can't be read
                    }
                }
                
                if ($logHealth.RecentErrors.Count -gt 0) {
                    Write-HealthLog "⚠ Found $($logHealth.RecentErrors.Count) recent errors in logs" -Level 'Warning'
                }
                
                if ($logHealth.RecentWarnings.Count -gt 0) {
                    Write-HealthLog "○ Found $($logHealth.RecentWarnings.Count) recent warnings in logs" -Level 'Info'
                }
            }
        }
        
        # Check Windows Event Log
        try {
            $veloEvents = Get-WinEvent -LogName Application -FilterXPath "*[System[Provider[@Name='Velociraptor']]]" -MaxEvents 10 -ErrorAction SilentlyContinue
            if ($veloEvents) {
                Write-HealthLog "✓ Found Velociraptor events in Windows Event Log" -Level 'Success'
                
                $recentErrors = $veloEvents | Where-Object { $_.LevelDisplayName -eq 'Error' -and $_.TimeCreated -gt (Get-Date).AddHours(-24) }
                if ($recentErrors) {
                    $logHealth.Issues += "Recent errors in Windows Event Log: $($recentErrors.Count)"
                }
            }
        } catch {
            # Event log not accessible or no events
        }
        
    } catch {
        $logHealth.Issues += "Error analyzing logs: $($_.Exception.Message)"
        Write-HealthLog "✗ Error analyzing logs: $($_.Exception.Message)" -Level 'Error'
    }
    
    return $logHealth
}

# Main execution
try {
    Write-HealthLog "Starting Velociraptor Health Check..." -Level 'Success'
    Write-HealthLog "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level 'Info'
    Write-HealthLog ""
    
    # Collect health data
    $healthReport = @{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        Service = Test-VelociraptorService
        Configuration = Test-VelociraptorConfiguration -ConfigPath $ConfigPath
        Connectivity = Test-VelociraptorConnectivity
        Resources = Test-VelociraptorResources
        Logs = Test-VelociraptorLogs -Detailed $Detailed
        OverallHealth = 'Unknown'
        Summary = @{
            TotalIssues = 0
            TotalWarnings = 0
            CriticalIssues = @()
        }
    }
    
    # Calculate overall health
    $allIssues = @()
    $allWarnings = @()
    
    $allIssues += $healthReport.Service.Issues
    $allIssues += $healthReport.Configuration.Issues
    $allIssues += $healthReport.Connectivity.Issues
    $allIssues += $healthReport.Resources.Issues
    $allIssues += $healthReport.Logs.Issues
    
    $allWarnings += $healthReport.Configuration.Warnings
    $allWarnings += $healthReport.Configuration.SecurityIssues
    $allWarnings += $healthReport.Resources.Warnings
    
    $healthReport.Summary.TotalIssues = $allIssues.Count
    $healthReport.Summary.TotalWarnings = $allWarnings.Count
    
    # Determine overall health status
    if ($allIssues.Count -eq 0 -and $allWarnings.Count -eq 0) {
        $healthReport.OverallHealth = 'Healthy'
    } elseif ($allIssues.Count -eq 0) {
        $healthReport.OverallHealth = 'Warning'
    } else {
        $healthReport.OverallHealth = 'Critical'
    }
    
    # Critical issues
    if (-not $healthReport.Service.ProcessRunning) {
        $healthReport.Summary.CriticalIssues += "Velociraptor is not running"
    }
    if (-not $healthReport.Configuration.ConfigValid) {
        $healthReport.Summary.CriticalIssues += "Configuration is invalid"
    }
    
    # Summary
    Write-HealthLog ""
    Write-HealthLog "=== Health Check Summary ===" -Level 'Info'
    Write-HealthLog "Overall Status: $($healthReport.OverallHealth)" -Level $(
        switch ($healthReport.OverallHealth) {
            'Healthy' { 'Success' }
            'Warning' { 'Warning' }
            'Critical' { 'Error' }
            default { 'Info' }
        }
    )
    Write-HealthLog "Issues: $($healthReport.Summary.TotalIssues), Warnings: $($healthReport.Summary.TotalWarnings)" -Level 'Info'
    
    if ($healthReport.Summary.CriticalIssues.Count -gt 0) {
        Write-HealthLog "Critical Issues:" -Level 'Error'
        $healthReport.Summary.CriticalIssues | ForEach-Object { Write-HealthLog "  - $_" -Level 'Error' }
    }
    
    # Export report if requested
    if ($ExportReport) {
        $reportPath = "VelociraptorHealthReport_$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $healthReport | ConvertTo-Json -Depth 10 | Out-File $reportPath -Encoding UTF8
        Write-HealthLog ""
        Write-HealthLog "Health report exported to: $reportPath" -Level 'Success'
    }
    
    # Exit with appropriate code
    switch ($healthReport.OverallHealth) {
        'Healthy' { exit 0 }
        'Warning' { exit 1 }
        'Critical' { exit 2 }
        default { exit 3 }
    }
}
catch {
    Write-HealthLog "Health check failed: $($_.Exception.Message)" -Level 'Error'
    exit 99
}