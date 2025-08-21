function Start-VelociraptorComplianceMonitor {
    <#
    .SYNOPSIS
        Starts continuous compliance monitoring service.
        
    .DESCRIPTION
        Initiates real-time compliance monitoring that continuously
        validates configuration against compliance requirements.
        
    .PARAMETER Framework
        The compliance framework to monitor.
        
    .PARAMETER MonitoringInterval
        Monitoring check interval in minutes.
        
    .PARAMETER AlertThreshold
        Compliance score threshold below which alerts are generated.
        
    .PARAMETER ConfigPath
        Path to Velociraptor configuration to monitor.
        
    .EXAMPLE
        Start-VelociraptorComplianceMonitor -Framework "FedRAMP" -MonitoringInterval 30 -AlertThreshold 95
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('FedRAMP', 'SOC2', 'ISO27001', 'NIST', 'HIPAA', 'PCI-DSS', 'GDPR')]
        [string]$Framework,
        
        [Parameter()]
        [int]$MonitoringInterval = 60,
        
        [Parameter()]
        [int]$AlertThreshold = 95,
        
        [Parameter()]
        [string]$ConfigPath
    )
    
    try {
        Write-VelociraptorLog "Starting continuous compliance monitoring for $Framework" -Level Info -Component "ComplianceMonitoring"
        
        # Initialize compliance paths
        Initialize-CompliancePaths
        
        # Create monitoring job
        $monitoringJob = Start-Job -ScriptBlock {
            param($Framework, $MonitoringInterval, $AlertThreshold, $ConfigPath, $ComplianceDataPath, $AuditLogPath)
            
            # Import required modules in job context
            Import-Module VelociraptorDeployment -Force
            Import-Module VelociraptorCompliance -Force
            
            # Initialize variables
            $script:ComplianceDataPath = $ComplianceDataPath
            $script:AuditLogPath = $AuditLogPath
            
            while ($true) {
                try {
                    # Run compliance assessment
                    $assessment = Test-VelociraptorCompliance -Framework $Framework -ConfigPath $ConfigPath
                    
                    # Check if score is below threshold
                    if ($assessment.ComplianceScore -lt $AlertThreshold) {
                        # Generate alert
                        $alert = @{
                            AlertId = [System.Guid]::NewGuid().ToString()
                            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                            Framework = $Framework
                            ComplianceScore = $assessment.ComplianceScore
                            Threshold = $AlertThreshold
                            FailedControls = $assessment.FailedControls
                            AlertLevel = if ($assessment.ComplianceScore -lt 70) { "Critical" } 
                                        elseif ($assessment.ComplianceScore -lt 85) { "High" } 
                                        else { "Medium" }
                            Message = "Compliance score ($($assessment.ComplianceScore)%) below threshold ($AlertThreshold%)"
                            Details = $assessment.Findings
                        }
                        
                        # Save alert
                        $alertPath = Join-Path $AuditLogPath "compliance-alerts-$(Get-Date -Format 'yyyyMM').json"
                        $alert | ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath $alertPath -Append -Encoding UTF8
                        
                        # Write to event log if available
                        try {
                            Write-EventLog -LogName Application -Source "VelociraptorCompliance" -EventId 1001 -EntryType Warning -Message $alert.Message
                        } catch {
                            # Ignore if event log source not registered
                        }
                    }
                    
                    # Update monitoring status
                    $monitoringStatus = @{
                        Framework = $Framework
                        LastCheck = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                        ComplianceScore = $assessment.ComplianceScore
                        Status = if ($assessment.ComplianceScore -ge $AlertThreshold) { "Compliant" } else { "Non-Compliant" }
                        NextCheck = (Get-Date).AddMinutes($MonitoringInterval).ToString('yyyy-MM-dd HH:mm:ss')
                    }
                    
                    $statusPath = Join-Path $ComplianceDataPath "$Framework-monitoring-status.json"
                    $monitoringStatus | ConvertTo-Json -Depth 5 | Out-File -FilePath $statusPath -Encoding UTF8
                    
                } catch {
                    # Log monitoring error
                    $errorAlert = @{
                        AlertId = [System.Guid]::NewGuid().ToString()
                        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                        Framework = $Framework
                        AlertLevel = "Error"
                        Message = "Compliance monitoring error: $($_.Exception.Message)"
                        Details = $_.Exception.StackTrace
                    }
                    
                    $alertPath = Join-Path $AuditLogPath "compliance-alerts-$(Get-Date -Format 'yyyyMM').json"
                    $errorAlert | ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath $alertPath -Append -Encoding UTF8
                }
                
                # Wait for next check
                Start-Sleep -Seconds ($MonitoringInterval * 60)
            }
        } -ArgumentList $Framework, $MonitoringInterval, $AlertThreshold, $ConfigPath, $script:ComplianceDataPath, $script:AuditLogPath
        
        # Save job information
        $jobInfo = @{
            JobId = $monitoringJob.Id
            Framework = $Framework
            MonitoringInterval = $MonitoringInterval
            AlertThreshold = $AlertThreshold
            StartTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            Status = "Running"
        }
        
        $jobPath = Join-Path $script:ComplianceDataPath "$Framework-monitoring-job.json"
        $jobInfo | ConvertTo-Json -Depth 5 | Out-File -FilePath $jobPath -Encoding UTF8
        
        Write-VelociraptorLog "Compliance monitoring started successfully (Job ID: $($monitoringJob.Id))" -Level Success -Component "ComplianceMonitoring"
        
        return @{
            JobId = $monitoringJob.Id
            Framework = $Framework
            MonitoringInterval = $MonitoringInterval
            AlertThreshold = $AlertThreshold
            Status = "Started"
        }
        
    } catch {
        Write-VelociraptorLog "Failed to start compliance monitoring: $($_.Exception.Message)" -Level Error -Component "ComplianceMonitoring"
        throw
    }
}

function Stop-VelociraptorComplianceMonitor {
    <#
    .SYNOPSIS
        Stops continuous compliance monitoring service.
        
    .DESCRIPTION
        Stops the continuous compliance monitoring job for the specified framework.
        
    .PARAMETER Framework
        The compliance framework to stop monitoring.
        
    .PARAMETER JobId
        Specific job ID to stop (optional).
        
    .EXAMPLE
        Stop-VelociraptorComplianceMonitor -Framework "FedRAMP"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('FedRAMP', 'SOC2', 'ISO27001', 'NIST', 'HIPAA', 'PCI-DSS', 'GDPR')]
        [string]$Framework,
        
        [Parameter()]
        [int]$JobId
    )
    
    try {
        Write-VelociraptorLog "Stopping compliance monitoring for $Framework" -Level Info -Component "ComplianceMonitoring"
        
        Initialize-CompliancePaths
        
        # Get job information
        $jobPath = Join-Path $script:ComplianceDataPath "$Framework-monitoring-job.json"
        
        if ($JobId) {
            # Stop specific job
            $job = Get-Job -Id $JobId -ErrorAction SilentlyContinue
            if ($job) {
                Stop-Job -Id $JobId -ErrorAction SilentlyContinue
                Remove-Job -Id $JobId -Force -ErrorAction SilentlyContinue
                Write-VelociraptorLog "Stopped compliance monitoring job ID: $JobId" -Level Success -Component "ComplianceMonitoring"
            } else {
                Write-Warning "Job ID $JobId not found or already stopped"
            }
        } elseif (Test-Path $jobPath) {
            # Stop job based on framework
            $jobInfo = Get-Content $jobPath | ConvertFrom-Json
            $job = Get-Job -Id $jobInfo.JobId -ErrorAction SilentlyContinue
            
            if ($job) {
                Stop-Job -Id $jobInfo.JobId -ErrorAction SilentlyContinue
                Remove-Job -Id $jobInfo.JobId -Force -ErrorAction SilentlyContinue
                Write-VelociraptorLog "Stopped compliance monitoring for $Framework (Job ID: $($jobInfo.JobId))" -Level Success -Component "ComplianceMonitoring"
            }
            
            # Update job status
            $jobInfo.Status = "Stopped"
            $jobInfo.StopTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            $jobInfo | ConvertTo-Json -Depth 5 | Out-File -FilePath $jobPath -Encoding UTF8
        } else {
            Write-Warning "No active monitoring job found for $Framework"
        }
        
        # Update monitoring configuration
        $configPath = Join-Path $script:ComplianceDataPath "$Framework-monitoring.json"
        if (Test-Path $configPath) {
            $config = Get-Content $configPath | ConvertFrom-Json
            $config.Enabled = $false
            $config.StoppedDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            $config | ConvertTo-Json -Depth 5 | Out-File -FilePath $configPath -Encoding UTF8
        }
        
        return @{
            Framework = $Framework
            Status = "Stopped"
            StoppedTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
        
    } catch {
        Write-VelociraptorLog "Failed to stop compliance monitoring: $($_.Exception.Message)" -Level Error -Component "ComplianceMonitoring"
        throw
    }
}

function Get-VelociraptorComplianceAlerts {
    <#
    .SYNOPSIS
        Retrieves compliance monitoring alerts.
        
    .DESCRIPTION
        Gets compliance alerts generated by the continuous monitoring system.
        
    .PARAMETER Framework
        Filter alerts by compliance framework.
        
    .PARAMETER AlertLevel
        Filter alerts by severity level.
        
    .PARAMETER DateRange
        Number of days to look back for alerts.
        
    .PARAMETER MaxResults
        Maximum number of alerts to return.
        
    .EXAMPLE
        Get-VelociraptorComplianceAlerts -Framework "FedRAMP" -AlertLevel "Critical" -DateRange 7
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('FedRAMP', 'SOC2', 'ISO27001', 'NIST', 'HIPAA', 'PCI-DSS', 'GDPR')]
        [string]$Framework,
        
        [Parameter()]
        [ValidateSet('Critical', 'High', 'Medium', 'Low', 'Error')]
        [string]$AlertLevel,
        
        [Parameter()]
        [int]$DateRange = 30,
        
        [Parameter()]
        [int]$MaxResults = 100
    )
    
    try {
        Initialize-CompliancePaths
        
        $alerts = @()
        $cutoffDate = (Get-Date).AddDays(-$DateRange)
        
        # Get alert files from the date range
        $alertFiles = Get-ChildItem -Path $script:AuditLogPath -Filter "compliance-alerts-*.json" -ErrorAction SilentlyContinue
        
        foreach ($alertFile in $alertFiles) {
            # Check if file is within date range
            if ($alertFile.CreationTime -gt $cutoffDate) {
                $fileAlerts = Get-Content $alertFile.FullName | Where-Object { $_.Trim() -ne "" } | ForEach-Object {
                    try {
                        $_ | ConvertFrom-Json
                    } catch {
                        # Skip malformed JSON lines
                        $null
                    }
                } | Where-Object { $_ -ne $null }
                
                $alerts += $fileAlerts
            }
        }
        
        # Filter by framework if specified
        if ($Framework) {
            $alerts = $alerts | Where-Object { $_.Framework -eq $Framework }
        }
        
        # Filter by alert level if specified
        if ($AlertLevel) {
            $alerts = $alerts | Where-Object { $_.AlertLevel -eq $AlertLevel }
        }
        
        # Filter by date range
        $alerts = $alerts | Where-Object { 
            try {
                [DateTime]::ParseExact($_.Timestamp, 'yyyy-MM-dd HH:mm:ss', $null) -gt $cutoffDate
            } catch {
                $false
            }
        }
        
        # Sort by timestamp (newest first) and limit results
        $alerts = $alerts | Sort-Object { 
            try {
                [DateTime]::ParseExact($_.Timestamp, 'yyyy-MM-dd HH:mm:ss', $null)
            } catch {
                [DateTime]::MinValue
            }
        } -Descending | Select-Object -First $MaxResults
        
        Write-VelociraptorLog "Retrieved $($alerts.Count) compliance alerts" -Level Info -Component "ComplianceMonitoring"
        
        return $alerts
        
    } catch {
        Write-VelociraptorLog "Failed to retrieve compliance alerts: $($_.Exception.Message)" -Level Error -Component "ComplianceMonitoring"
        throw
    }
}

function Get-VelociraptorComplianceStatus {
    <#
    .SYNOPSIS
        Gets current compliance monitoring status.
        
    .DESCRIPTION
        Retrieves the current status of compliance monitoring including
        recent assessments, alerts, and monitoring configuration.
        
    .PARAMETER Framework
        Get status for specific compliance framework.
        
    .EXAMPLE
        Get-VelociraptorComplianceStatus -Framework "FedRAMP"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('FedRAMP', 'SOC2', 'ISO27001', 'NIST', 'HIPAA', 'PCI-DSS', 'GDPR')]
        [string]$Framework
    )
    
    try {
        Initialize-CompliancePaths
        
        $frameworks = if ($Framework) { @($Framework) } else { $script:ComplianceFrameworks }
        $status = @()
        
        foreach ($fw in $frameworks) {
            $frameworkStatus = @{
                Framework = $fw
                MonitoringEnabled = $false
                LastAssessment = $null
                ComplianceScore = $null
                Status = "Unknown"
                RecentAlerts = 0
                JobStatus = "Not Running"
                Configuration = $null
            }
            
            # Check monitoring configuration
            $configPath = Join-Path $script:ComplianceDataPath "$fw-monitoring.json"
            if (Test-Path $configPath) {
                $config = Get-Content $configPath | ConvertFrom-Json
                $frameworkStatus.MonitoringEnabled = $config.Enabled
                $frameworkStatus.Configuration = $config
            }
            
            # Check job status
            $jobPath = Join-Path $script:ComplianceDataPath "$fw-monitoring-job.json"
            if (Test-Path $jobPath) {
                $jobInfo = Get-Content $jobPath | ConvertFrom-Json
                $job = Get-Job -Id $jobInfo.JobId -ErrorAction SilentlyContinue
                if ($job) {
                    $frameworkStatus.JobStatus = $job.State
                } else {
                    $frameworkStatus.JobStatus = "Stopped"
                }
            }
            
            # Check monitoring status
            $statusPath = Join-Path $script:ComplianceDataPath "$fw-monitoring-status.json"
            if (Test-Path $statusPath) {
                $monitoringStatus = Get-Content $statusPath | ConvertFrom-Json
                $frameworkStatus.LastAssessment = $monitoringStatus.LastCheck
                $frameworkStatus.ComplianceScore = $monitoringStatus.ComplianceScore
                $frameworkStatus.Status = $monitoringStatus.Status
            }
            
            # Count recent alerts (last 24 hours)
            $recentAlerts = Get-VelociraptorComplianceAlerts -Framework $fw -DateRange 1
            $frameworkStatus.RecentAlerts = $recentAlerts.Count
            
            $status += $frameworkStatus
        }
        
        Write-VelociraptorLog "Retrieved compliance status for $($status.Count) framework(s)" -Level Info -Component "ComplianceMonitoring"
        
        return $status
        
    } catch {
        Write-VelociraptorLog "Failed to get compliance status: $($_.Exception.Message)" -Level Error -Component "ComplianceMonitoring"
        throw
    }
}

function Set-VelociraptorComplianceThresholds {
    <#
    .SYNOPSIS
        Sets compliance monitoring alert thresholds.
        
    .DESCRIPTION
        Configures the thresholds and settings for compliance monitoring alerts.
        
    .PARAMETER Framework
        The compliance framework to configure.
        
    .PARAMETER AlertThreshold
        Compliance score threshold below which alerts are generated.
        
    .PARAMETER CriticalThreshold
        Compliance score threshold for critical alerts.
        
    .PARAMETER MonitoringInterval
        Monitoring check interval in minutes.
        
    .PARAMETER EnableEmailAlerts
        Enable email notifications for alerts.
        
    .PARAMETER EmailRecipients
        Email addresses to receive alert notifications.
        
    .EXAMPLE
        Set-VelociraptorComplianceThresholds -Framework "FedRAMP" -AlertThreshold 95 -CriticalThreshold 70
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('FedRAMP', 'SOC2', 'ISO27001', 'NIST', 'HIPAA', 'PCI-DSS', 'GDPR')]
        [string]$Framework,
        
        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$AlertThreshold = 95,
        
        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$CriticalThreshold = 70,
        
        [Parameter()]
        [ValidateRange(1, 1440)]
        [int]$MonitoringInterval = 60,
        
        [Parameter()]
        [switch]$EnableEmailAlerts,
        
        [Parameter()]
        [string[]]$EmailRecipients = @()
    )
    
    try {
        Initialize-CompliancePaths
        
        # Validate thresholds
        if ($CriticalThreshold -gt $AlertThreshold) {
            throw "Critical threshold ($CriticalThreshold) cannot be higher than alert threshold ($AlertThreshold)"
        }
        
        # Load existing configuration or create new
        $configPath = Join-Path $script:ComplianceDataPath "$Framework-monitoring.json"
        $config = if (Test-Path $configPath) {
            Get-Content $configPath | ConvertFrom-Json
        } else {
            @{
                Framework = $Framework
                Enabled = $false
                EnabledDate = $null
            }
        }
        
        # Update configuration
        $config.AlertThreshold = $AlertThreshold
        $config.CriticalThreshold = $CriticalThreshold
        $config.MonitoringInterval = $MonitoringInterval
        $config.EnableEmailAlerts = $EnableEmailAlerts.IsPresent
        $config.EmailRecipients = $EmailRecipients
        $config.LastUpdated = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $config.UpdatedBy = $env:USERNAME
        
        # Save configuration
        $config | ConvertTo-Json -Depth 5 | Out-File -FilePath $configPath -Encoding UTF8
        
        # Create audit entry
        $auditEntry = @{
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            Action = 'ComplianceThresholdsUpdated'
            Framework = $Framework
            AlertThreshold = $AlertThreshold
            CriticalThreshold = $CriticalThreshold
            MonitoringInterval = $MonitoringInterval
            User = $env:USERNAME
            Computer = $env:COMPUTERNAME
            Status = 'Updated'
        }
        Write-VelociraptorComplianceAudit -AuditEntry $auditEntry
        
        Write-VelociraptorLog "Updated compliance thresholds for $Framework" -Level Success -Component "ComplianceMonitoring"
        
        return @{
            Framework = $Framework
            AlertThreshold = $AlertThreshold
            CriticalThreshold = $CriticalThreshold
            MonitoringInterval = $MonitoringInterval
            EnableEmailAlerts = $EnableEmailAlerts.IsPresent
            EmailRecipients = $EmailRecipients
            Updated = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
        
    } catch {
        Write-VelociraptorLog "Failed to set compliance thresholds: $($_.Exception.Message)" -Level Error -Component "ComplianceMonitoring"
        throw
    }
}

function Disable-VelociraptorComplianceMonitoring {
    <#
    .SYNOPSIS
        Disables compliance monitoring for a framework.
        
    .DESCRIPTION
        Stops and disables continuous compliance monitoring for the specified framework.
        
    .PARAMETER Framework
        The compliance framework to disable monitoring for.
        
    .EXAMPLE
        Disable-VelociraptorComplianceMonitoring -Framework "FedRAMP"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('FedRAMP', 'SOC2', 'ISO27001', 'NIST', 'HIPAA', 'PCI-DSS', 'GDPR')]
        [string]$Framework
    )
    
    try {
        # Stop monitoring job
        Stop-VelociraptorComplianceMonitor -Framework $Framework
        
        # Update configuration to disabled
        Initialize-CompliancePaths
        $configPath = Join-Path $script:ComplianceDataPath "$Framework-monitoring.json"
        
        if (Test-Path $configPath) {
            $config = Get-Content $configPath | ConvertFrom-Json
            $config.Enabled = $false
            $config.DisabledDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            $config.DisabledBy = $env:USERNAME
            $config | ConvertTo-Json -Depth 5 | Out-File -FilePath $configPath -Encoding UTF8
        }
        
        # Create audit entry
        $auditEntry = @{
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            Action = 'ComplianceMonitoringDisabled'
            Framework = $Framework
            User = $env:USERNAME
            Computer = $env:COMPUTERNAME
            Status = 'Disabled'
        }
        Write-VelociraptorComplianceAudit -AuditEntry $auditEntry
        
        Write-VelociraptorLog "Compliance monitoring disabled for $Framework" -Level Info -Component "ComplianceMonitoring"
        
        return @{
            Framework = $Framework
            MonitoringEnabled = $false
            DisabledTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
        
    } catch {
        Write-VelociraptorLog "Failed to disable compliance monitoring: $($_.Exception.Message)" -Level Error -Component "ComplianceMonitoring"
        throw
    }
}