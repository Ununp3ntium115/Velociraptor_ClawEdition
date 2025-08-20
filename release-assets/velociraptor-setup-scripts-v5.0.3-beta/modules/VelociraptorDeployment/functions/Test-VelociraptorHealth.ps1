function Test-VelociraptorHealth {
    <#
    .SYNOPSIS
        Performs comprehensive health checks on Velociraptor deployment.
    
    .DESCRIPTION
        Tests various aspects of Velociraptor deployment including service status,
        network connectivity, disk space, memory usage, and configuration validity.
    
    .PARAMETER ConfigPath
        Path to the Velociraptor configuration file.
    
    .PARAMETER IncludePerformance
        Include performance metrics in the health check.
    
    .PARAMETER OutputFormat
        Output format for health check results (Text, JSON, XML).
    
    .PARAMETER AlertThresholds
        Custom alert thresholds for various metrics.
    
    .EXAMPLE
        Test-VelociraptorHealth -ConfigPath "C:\Program Files\Velociraptor\server.config.yaml"
    
    .EXAMPLE
        Test-VelociraptorHealth -ConfigPath "server.yaml" -IncludePerformance -OutputFormat JSON
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$ConfigPath,
        
        [switch]$IncludePerformance,
        
        [ValidateSet('Text', 'JSON', 'XML')]
        [string]$OutputFormat = 'Text',
        
        [hashtable]$AlertThresholds = @{
            DiskSpaceGB = 10
            MemoryUsagePercent = 80
            CPUUsagePercent = 85
            ResponseTimeMs = 5000
        }
    )
    
    Write-VelociraptorLog -Message "Starting Velociraptor health check" -Level Info
    
    $healthResults = @{
        Timestamp = Get-Date
        OverallStatus = 'Unknown'
        Checks = @{}
        Alerts = @()
        Performance = @{}
    }
    
    try {
        # Service Status Check
        Write-VelociraptorLog -Message "Checking service status" -Level Info
        $serviceCheck = Test-VelociraptorServiceStatus
        $healthResults.Checks['ServiceStatus'] = $serviceCheck
        
        # Configuration Validation
        Write-VelociraptorLog -Message "Validating configuration" -Level Info
        $configCheck = Test-VelociraptorConfiguration -ConfigPath $ConfigPath
        $healthResults.Checks['Configuration'] = $configCheck
        
        # Network Connectivity
        Write-VelociraptorLog -Message "Testing network connectivity" -Level Info
        $networkCheck = Test-VelociraptorNetworkConnectivity -ConfigPath $ConfigPath
        $healthResults.Checks['NetworkConnectivity'] = $networkCheck
        
        # Disk Space Check
        Write-VelociraptorLog -Message "Checking disk space" -Level Info
        $diskCheck = Test-VelociraptorDiskSpace -ConfigPath $ConfigPath -ThresholdGB $AlertThresholds.DiskSpaceGB
        $healthResults.Checks['DiskSpace'] = $diskCheck
        
        # Memory Usage Check
        Write-VelociraptorLog -Message "Checking memory usage" -Level Info
        $memoryCheck = Test-VelociraptorMemoryUsage -ThresholdPercent $AlertThresholds.MemoryUsagePercent
        $healthResults.Checks['MemoryUsage'] = $memoryCheck
        
        # Performance Metrics (if requested)
        if ($IncludePerformance) {
            Write-VelociraptorLog -Message "Collecting performance metrics" -Level Info
            $healthResults.Performance = Get-VelociraptorPerformanceMetrics -ConfigPath $ConfigPath
        }
        
        # Determine Overall Status
        $failedChecks = $healthResults.Checks.Values | Where-Object { $_.Status -eq 'Failed' }
        $warningChecks = $healthResults.Checks.Values | Where-Object { $_.Status -eq 'Warning' }
        
        if ($failedChecks.Count -gt 0) {
            $healthResults.OverallStatus = 'Critical'
            $healthResults.Alerts += "Critical: $($failedChecks.Count) health checks failed"
        }
        elseif ($warningChecks.Count -gt 0) {
            $healthResults.OverallStatus = 'Warning'
            $healthResults.Alerts += "Warning: $($warningChecks.Count) health checks have warnings"
        }
        else {
            $healthResults.OverallStatus = 'Healthy'
        }
        
        # Generate Alerts
        foreach ($check in $healthResults.Checks.GetEnumerator()) {
            if ($check.Value.Status -in @('Failed', 'Warning')) {
                $healthResults.Alerts += "$($check.Value.Status): $($check.Key) - $($check.Value.Message)"
            }
        }
        
        Write-VelociraptorLog -Message "Health check completed with status: $($healthResults.OverallStatus)" -Level Info
        
        # Format Output
        switch ($OutputFormat) {
            'JSON' { 
                return $healthResults | ConvertTo-Json -Depth 10
            }
            'XML' { 
                return $healthResults | ConvertTo-Xml -NoTypeInformation
            }
            default { 
                return ConvertTo-VelociraptorHealthReport -HealthResults $healthResults
            }
        }
    }
    catch {
        $errorMsg = "Health check failed: $($_.Exception.Message)"
        Write-VelociraptorLog -Message $errorMsg -Level Error
        
        $healthResults.OverallStatus = 'Error'
        $healthResults.Alerts += $errorMsg
        
        return $healthResults
    }
}

function Test-VelociraptorServiceStatus {
    $result = @{
        Status = 'Unknown'
        Message = ''
        Details = @{}
    }
    
    try {
        $service = Get-Service -Name "Velociraptor" -ErrorAction SilentlyContinue
        
        if ($null -eq $service) {
            $result.Status = 'Failed'
            $result.Message = 'Velociraptor service not found'
        }
        else {
            $result.Details['ServiceName'] = $service.Name
            $result.Details['Status'] = $service.Status
            $result.Details['StartType'] = $service.StartType
            
            if ($service.Status -eq 'Running') {
                $result.Status = 'Passed'
                $result.Message = 'Service is running normally'
            }
            else {
                $result.Status = 'Failed'
                $result.Message = "Service is $($service.Status)"
            }
        }
    }
    catch {
        $result.Status = 'Failed'
        $result.Message = "Error checking service status: $($_.Exception.Message)"
    }
    
    return $result
}

function Test-VelociraptorNetworkConnectivity {
    param([string]$ConfigPath)
    
    $result = @{
        Status = 'Unknown'
        Message = ''
        Details = @{}
    }
    
    try {
        # Parse configuration to get bind addresses and ports
        $config = Get-Content $ConfigPath | ConvertFrom-Yaml
        
        $bindAddress = $config.GUI.bind_address -replace '0.0.0.0', 'localhost'
        $bindPort = $config.GUI.bind_port
        
        # Test GUI connectivity
        $guiTest = Wait-VelociraptorTcpPort -ComputerName $bindAddress -Port $bindPort -TimeoutSeconds 5
        $result.Details['GUI'] = @{
            Address = $bindAddress
            Port = $bindPort
            Accessible = $guiTest
        }
        
        # Test API connectivity if different
        if ($config.API) {
            $apiAddress = $config.API.bind_address -replace '0.0.0.0', 'localhost'
            $apiPort = $config.API.bind_port
            
            $apiTest = Wait-VelociraptorTcpPort -ComputerName $apiAddress -Port $apiPort -TimeoutSeconds 5
            $result.Details['API'] = @{
                Address = $apiAddress
                Port = $apiPort
                Accessible = $apiTest
            }
        }
        
        # Determine overall connectivity status
        $allTests = $result.Details.Values | ForEach-Object { $_.Accessible }
        if ($allTests -contains $false) {
            $result.Status = 'Failed'
            $result.Message = 'One or more network endpoints are not accessible'
        }
        else {
            $result.Status = 'Passed'
            $result.Message = 'All network endpoints are accessible'
        }
    }
    catch {
        $result.Status = 'Failed'
        $result.Message = "Error testing network connectivity: $($_.Exception.Message)"
    }
    
    return $result
}

function Test-VelociraptorDiskSpace {
    param(
        [string]$ConfigPath,
        [int]$ThresholdGB = 10
    )
    
    $result = @{
        Status = 'Unknown'
        Message = ''
        Details = @{}
    }
    
    try {
        # Get datastore path from configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Yaml
        $datastorePath = $config.Datastore.location
        
        if (-not $datastorePath) {
            $datastorePath = Split-Path $ConfigPath -Parent
        }
        
        # Get disk space information
        $drive = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $datastorePath.StartsWith($_.DeviceID) }
        
        if ($drive) {
            $freeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
            $totalSpaceGB = [math]::Round($drive.Size / 1GB, 2)
            $usedSpaceGB = $totalSpaceGB - $freeSpaceGB
            $usedPercent = [math]::Round(($usedSpaceGB / $totalSpaceGB) * 100, 2)
            
            $result.Details = @{
                Drive = $drive.DeviceID
                TotalSpaceGB = $totalSpaceGB
                UsedSpaceGB = $usedSpaceGB
                FreeSpaceGB = $freeSpaceGB
                UsedPercent = $usedPercent
                ThresholdGB = $ThresholdGB
            }
            
            if ($freeSpaceGB -lt $ThresholdGB) {
                $result.Status = 'Warning'
                $result.Message = "Low disk space: $freeSpaceGB GB free (threshold: $ThresholdGB GB)"
            }
            else {
                $result.Status = 'Passed'
                $result.Message = "Sufficient disk space: $freeSpaceGB GB free"
            }
        }
        else {
            $result.Status = 'Failed'
            $result.Message = "Could not determine disk space for datastore path: $datastorePath"
        }
    }
    catch {
        $result.Status = 'Failed'
        $result.Message = "Error checking disk space: $($_.Exception.Message)"
    }
    
    return $result
}

function Test-VelociraptorMemoryUsage {
    param([int]$ThresholdPercent = 80)
    
    $result = @{
        Status = 'Unknown'
        Message = ''
        Details = @{}
    }
    
    try {
        # Get system memory information
        $totalMemory = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory
        $availableMemory = (Get-WmiObject -Class Win32_OperatingSystem).FreePhysicalMemory * 1KB
        
        $usedMemory = $totalMemory - $availableMemory
        $usedPercent = [math]::Round(($usedMemory / $totalMemory) * 100, 2)
        
        # Get Velociraptor process memory usage
        $veloProcess = Get-Process -Name "velociraptor*" -ErrorAction SilentlyContinue
        $veloMemoryMB = 0
        
        if ($veloProcess) {
            $veloMemoryMB = [math]::Round(($veloProcess | Measure-Object WorkingSet -Sum).Sum / 1MB, 2)
        }
        
        $result.Details = @{
            TotalMemoryGB = [math]::Round($totalMemory / 1GB, 2)
            UsedMemoryGB = [math]::Round($usedMemory / 1GB, 2)
            AvailableMemoryGB = [math]::Round($availableMemory / 1GB, 2)
            UsedPercent = $usedPercent
            VelociraptorMemoryMB = $veloMemoryMB
            ThresholdPercent = $ThresholdPercent
        }
        
        if ($usedPercent -gt $ThresholdPercent) {
            $result.Status = 'Warning'
            $result.Message = "High memory usage: $usedPercent% (threshold: $ThresholdPercent%)"
        }
        else {
            $result.Status = 'Passed'
            $result.Message = "Normal memory usage: $usedPercent%"
        }
    }
    catch {
        $result.Status = 'Failed'
        $result.Message = "Error checking memory usage: $($_.Exception.Message)"
    }
    
    return $result
}

function Get-VelociraptorPerformanceMetrics {
    param([string]$ConfigPath)
    
    $metrics = @{
        Timestamp = Get-Date
        System = @{}
        Process = @{}
        Network = @{}
    }
    
    try {
        # System metrics
        $cpu = Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average
        $metrics.System['CPUUsagePercent'] = [math]::Round($cpu.Average, 2)
        
        # Process metrics
        $veloProcess = Get-Process -Name "velociraptor*" -ErrorAction SilentlyContinue
        if ($veloProcess) {
            $metrics.Process = @{
                ProcessCount = $veloProcess.Count
                TotalCPUTime = ($veloProcess | Measure-Object CPU -Sum).Sum
                WorkingSetMB = [math]::Round(($veloProcess | Measure-Object WorkingSet -Sum).Sum / 1MB, 2)
                VirtualMemoryMB = [math]::Round(($veloProcess | Measure-Object VirtualMemorySize -Sum).Sum / 1MB, 2)
                HandleCount = ($veloProcess | Measure-Object HandleCount -Sum).Sum
                ThreadCount = ($veloProcess | Measure-Object Threads -Sum).Sum
            }
        }
        
        # Network metrics (basic)
        $networkAdapters = Get-WmiObject -Class Win32_NetworkAdapter | Where-Object { $_.NetEnabled -eq $true }
        $metrics.Network['ActiveAdapters'] = $networkAdapters.Count
        
    }
    catch {
        Write-VelociraptorLog -Message "Error collecting performance metrics: $($_.Exception.Message)" -Level Warning
    }
    
    return $metrics
}

function ConvertTo-VelociraptorHealthReport {
    param($HealthResults)
    
    $report = @"
=== VELOCIRAPTOR HEALTH CHECK REPORT ===
Timestamp: $($HealthResults.Timestamp)
Overall Status: $($HealthResults.OverallStatus)

"@
    
    # Add check results
    foreach ($check in $HealthResults.Checks.GetEnumerator()) {
        $report += @"
--- $($check.Key) ---
Status: $($check.Value.Status)
Message: $($check.Value.Message)

"@
        
        if ($check.Value.Details.Count -gt 0) {
            $report += "Details:`n"
            foreach ($detail in $check.Value.Details.GetEnumerator()) {
                $report += "  $($detail.Key): $($detail.Value)`n"
            }
            $report += "`n"
        }
    }
    
    # Add alerts
    if ($HealthResults.Alerts.Count -gt 0) {
        $report += "=== ALERTS ===`n"
        foreach ($alert in $HealthResults.Alerts) {
            $report += "- $alert`n"
        }
        $report += "`n"
    }
    
    # Add performance metrics if available
    if ($HealthResults.Performance.Count -gt 0) {
        $report += "=== PERFORMANCE METRICS ===`n"
        $report += "System:`n"
        foreach ($metric in $HealthResults.Performance.System.GetEnumerator()) {
            $report += "  $($metric.Key): $($metric.Value)`n"
        }
        
        if ($HealthResults.Performance.Process.Count -gt 0) {
            $report += "Process:`n"
            foreach ($metric in $HealthResults.Performance.Process.GetEnumerator()) {
                $report += "  $($metric.Key): $($metric.Value)`n"
            }
        }
    }
    
    return $report
}