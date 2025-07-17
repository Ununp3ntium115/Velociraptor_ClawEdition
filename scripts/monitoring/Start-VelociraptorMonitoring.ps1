#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Starts continuous monitoring of Velociraptor deployment with alerting capabilities.

.DESCRIPTION
    This script provides continuous monitoring of Velociraptor deployment including:
    - Service health monitoring
    - Performance metrics collection
    - Alert generation and notification
    - Automated remediation for common issues
    - Integration with external monitoring systems

.PARAMETER ConfigPath
    Path to the Velociraptor configuration file.

.PARAMETER MonitoringInterval
    Interval in seconds between health checks (default: 300 seconds / 5 minutes).

.PARAMETER AlertingEnabled
    Enable alert notifications (email, webhook, etc.).

.PARAMETER AlertConfig
    Path to alerting configuration file.

.PARAMETER RemediationEnabled
    Enable automated remediation for common issues.

.PARAMETER LogPath
    Path to store monitoring logs.

.PARAMETER DashboardPort
    Port for the monitoring dashboard web interface.

.EXAMPLE
    .\Start-VelociraptorMonitoring.ps1 -ConfigPath "C:\Program Files\Velociraptor\server.config.yaml"

.EXAMPLE
    .\Start-VelociraptorMonitoring.ps1 -ConfigPath "server.yaml" -MonitoringInterval 60 -AlertingEnabled -DashboardPort 8080
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$ConfigPath,
    
    [ValidateRange(30, 3600)]
    [int]$MonitoringInterval = 300,
    
    [switch]$AlertingEnabled,
    
    [string]$AlertConfig = "monitoring-alerts.json",
    
    [switch]$RemediationEnabled,
    
    [string]$LogPath = "monitoring.log",
    
    [ValidateRange(1024, 65535)]
    [int]$DashboardPort = 8090
)

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\VelociraptorDeployment" -Force

# Global monitoring state
$script:MonitoringActive = $true
$script:MonitoringStats = @{
    StartTime = Get-Date
    ChecksPerformed = 0
    AlertsGenerated = 0
    RemediationsPerformed = 0
    LastHealthStatus = 'Unknown'
}

function Start-VelociraptorMonitoring {
    Write-Host "=== VELOCIRAPTOR MONITORING SYSTEM ===" -ForegroundColor Cyan
    Write-Host "Starting monitoring for: $ConfigPath" -ForegroundColor Green
    Write-Host "Monitoring interval: $MonitoringInterval seconds" -ForegroundColor Green
    Write-Host "Alerting enabled: $AlertingEnabled" -ForegroundColor Green
    Write-Host "Remediation enabled: $RemediationEnabled" -ForegroundColor Green
    Write-Host "Dashboard port: $DashboardPort" -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
    Write-Host ""
    
    # Initialize monitoring components
    Initialize-MonitoringSystem
    
    # Start dashboard if requested
    if ($DashboardPort -gt 0) {
        Start-MonitoringDashboard -Port $DashboardPort
    }
    
    # Main monitoring loop
    try {
        while ($script:MonitoringActive) {
            $checkStartTime = Get-Date
            
            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Performing health check..." -ForegroundColor Cyan
            
            # Perform health check
            $healthResult = Test-VelociraptorHealth -ConfigPath $ConfigPath -IncludePerformance -OutputFormat JSON | ConvertFrom-Json
            
            # Update statistics
            $script:MonitoringStats.ChecksPerformed++
            $script:MonitoringStats.LastHealthStatus = $healthResult.OverallStatus
            
            # Log health status
            Write-MonitoringLog -Message "Health check completed: $($healthResult.OverallStatus)" -Level Info
            
            # Process alerts
            if ($healthResult.Alerts.Count -gt 0) {
                foreach ($alert in $healthResult.Alerts) {
                    Write-Host "  ALERT: $alert" -ForegroundColor Red
                    Write-MonitoringLog -Message "ALERT: $alert" -Level Warning
                    
                    if ($AlertingEnabled) {
                        Send-VelociraptorAlert -Alert $alert -HealthResult $healthResult
                        $script:MonitoringStats.AlertsGenerated++
                    }
                }
                
                # Attempt remediation if enabled
                if ($RemediationEnabled) {
                    $remediationResult = Invoke-VelociraptorRemediation -HealthResult $healthResult
                    if ($remediationResult.ActionsPerformed -gt 0) {
                        $script:MonitoringStats.RemediationsPerformed += $remediationResult.ActionsPerformed
                        Write-Host "  Remediation performed: $($remediationResult.ActionsPerformed) actions" -ForegroundColor Yellow
                    }
                }
            }
            else {
                Write-Host "  Status: $($healthResult.OverallStatus) - All checks passed" -ForegroundColor Green
            }
            
            # Display performance summary
            if ($healthResult.Performance) {
                $perf = $healthResult.Performance
                Write-Host "  Performance: CPU $($perf.System.CPUUsagePercent)%, Memory $($perf.Process.WorkingSetMB)MB" -ForegroundColor Blue
            }
            
            # Store metrics for dashboard
            Update-MonitoringMetrics -HealthResult $healthResult
            
            # Calculate sleep time
            $checkDuration = (Get-Date) - $checkStartTime
            $sleepTime = [Math]::Max(0, $MonitoringInterval - $checkDuration.TotalSeconds)
            
            if ($sleepTime -gt 0) {
                Start-Sleep -Seconds $sleepTime
            }
        }
    }
    catch {
        Write-Host "Monitoring error: $($_.Exception.Message)" -ForegroundColor Red
        Write-MonitoringLog -Message "Monitoring error: $($_.Exception.Message)" -Level Error
    }
    finally {
        Write-Host "Monitoring stopped." -ForegroundColor Yellow
        Stop-MonitoringDashboard
    }
}

function Initialize-MonitoringSystem {
    # Create monitoring directories
    $monitoringDir = Split-Path $LogPath -Parent
    if ($monitoringDir -and -not (Test-Path $monitoringDir)) {
        New-Item -Path $monitoringDir -ItemType Directory -Force | Out-Null
    }
    
    # Initialize log file
    Write-MonitoringLog -Message "Monitoring system initialized" -Level Info
    
    # Load alert configuration
    if ($AlertingEnabled -and (Test-Path $AlertConfig)) {
        try {
            $script:AlertConfiguration = Get-Content $AlertConfig | ConvertFrom-Json
            Write-MonitoringLog -Message "Alert configuration loaded from $AlertConfig" -Level Info
        }
        catch {
            Write-Warning "Failed to load alert configuration: $($_.Exception.Message)"
            $script:AlertConfiguration = Get-DefaultAlertConfiguration
        }
    }
    else {
        $script:AlertConfiguration = Get-DefaultAlertConfiguration
    }
    
    # Initialize metrics storage
    $script:MetricsHistory = @()
    $script:MaxMetricsHistory = 1440  # 24 hours at 1-minute intervals
}

function Write-MonitoringLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to file
    Add-Content -Path $LogPath -Value $logEntry
    
    # Also write to Velociraptor log
    Write-VelociraptorLog -Message $Message -Level $Level
}

function Send-VelociraptorAlert {
    param(
        [string]$Alert,
        [object]$HealthResult
    )
    
    try {
        # Email alerts
        if ($script:AlertConfiguration.Email.Enabled) {
            Send-EmailAlert -Alert $Alert -HealthResult $HealthResult
        }
        
        # Webhook alerts
        if ($script:AlertConfiguration.Webhook.Enabled) {
            Send-WebhookAlert -Alert $Alert -HealthResult $HealthResult
        }
        
        # Slack alerts
        if ($script:AlertConfiguration.Slack.Enabled) {
            Send-SlackAlert -Alert $Alert -HealthResult $HealthResult
        }
        
        # Windows Event Log
        if ($script:AlertConfiguration.EventLog.Enabled) {
            Write-EventLog -LogName Application -Source "VelociraptorMonitoring" -EventId 1001 -EntryType Warning -Message $Alert
        }
        
        Write-MonitoringLog -Message "Alert sent: $Alert" -Level Info
    }
    catch {
        Write-MonitoringLog -Message "Failed to send alert: $($_.Exception.Message)" -Level Error
    }
}

function Send-EmailAlert {
    param($Alert, $HealthResult)
    
    $emailConfig = $script:AlertConfiguration.Email
    
    $subject = "Velociraptor Alert: $($HealthResult.OverallStatus)"
    $body = @"
Velociraptor Monitoring Alert

Time: $($HealthResult.Timestamp)
Status: $($HealthResult.OverallStatus)
Alert: $Alert

Health Check Summary:
$(Format-VelociraptorHealthReport -HealthResults $HealthResult)

This is an automated alert from Velociraptor Monitoring System.
"@
    
    $mailParams = @{
        To = $emailConfig.Recipients
        From = $emailConfig.From
        Subject = $subject
        Body = $body
        SmtpServer = $emailConfig.SmtpServer
        Port = $emailConfig.Port
    }
    
    if ($emailConfig.UseSSL) {
        $mailParams.UseSsl = $true
    }
    
    if ($emailConfig.Credential) {
        $mailParams.Credential = $emailConfig.Credential
    }
    
    Send-MailMessage @mailParams
}

function Send-WebhookAlert {
    param($Alert, $HealthResult)
    
    $webhookConfig = $script:AlertConfiguration.Webhook
    
    $payload = @{
        timestamp = $HealthResult.Timestamp
        status = $HealthResult.OverallStatus
        alert = $Alert
        checks = $HealthResult.Checks
        alerts = $HealthResult.Alerts
    } | ConvertTo-Json -Depth 10
    
    $headers = @{
        'Content-Type' = 'application/json'
    }
    
    if ($webhookConfig.AuthHeader) {
        $headers[$webhookConfig.AuthHeader.Name] = $webhookConfig.AuthHeader.Value
    }
    
    Invoke-RestMethod -Uri $webhookConfig.Url -Method Post -Body $payload -Headers $headers
}

function Send-SlackAlert {
    param($Alert, $HealthResult)
    
    $slackConfig = $script:AlertConfiguration.Slack
    
    $color = switch ($HealthResult.OverallStatus) {
        'Critical' { 'danger' }
        'Warning' { 'warning' }
        default { 'good' }
    }
    
    $payload = @{
        channel = $slackConfig.Channel
        username = 'Velociraptor Monitor'
        icon_emoji = ':warning:'
        attachments = @(
            @{
                color = $color
                title = "Velociraptor Alert: $($HealthResult.OverallStatus)"
                text = $Alert
                fields = @(
                    @{
                        title = 'Timestamp'
                        value = $HealthResult.Timestamp
                        short = $true
                    }
                    @{
                        title = 'Status'
                        value = $HealthResult.OverallStatus
                        short = $true
                    }
                )
                footer = 'Velociraptor Monitoring'
                ts = [int][double]::Parse((Get-Date -UFormat %s))
            }
        )
    } | ConvertTo-Json -Depth 10
    
    Invoke-RestMethod -Uri $slackConfig.WebhookUrl -Method Post -Body $payload -ContentType 'application/json'
}

function Invoke-VelociraptorRemediation {
    param([object]$HealthResult)
    
    $remediationResult = @{
        ActionsPerformed = 0
        Actions = @()
    }
    
    try {
        # Service restart remediation
        if ($HealthResult.Checks.ServiceStatus.Status -eq 'Failed') {
            Write-MonitoringLog -Message "Attempting service restart remediation" -Level Info
            
            try {
                Restart-Service -Name "Velociraptor" -Force
                Start-Sleep -Seconds 10
                
                # Verify service is running
                $service = Get-Service -Name "Velociraptor"
                if ($service.Status -eq 'Running') {
                    $remediationResult.ActionsPerformed++
                    $remediationResult.Actions += "Service restarted successfully"
                    Write-MonitoringLog -Message "Service restart remediation successful" -Level Info
                }
            }
            catch {
                Write-MonitoringLog -Message "Service restart remediation failed: $($_.Exception.Message)" -Level Error
            }
        }
        
        # Disk space cleanup remediation
        if ($HealthResult.Checks.DiskSpace.Status -eq 'Warning') {
            Write-MonitoringLog -Message "Attempting disk space cleanup remediation" -Level Info
            
            try {
                # Clean temporary files
                $tempCleaned = Clear-VelociraptorTempFiles
                if ($tempCleaned -gt 0) {
                    $remediationResult.ActionsPerformed++
                    $remediationResult.Actions += "Cleaned $tempCleaned MB of temporary files"
                }
                
                # Rotate old logs
                $logsCleaned = Rotate-VelociraptorLogs
                if ($logsCleaned -gt 0) {
                    $remediationResult.ActionsPerformed++
                    $remediationResult.Actions += "Rotated $logsCleaned old log files"
                }
            }
            catch {
                Write-MonitoringLog -Message "Disk cleanup remediation failed: $($_.Exception.Message)" -Level Error
            }
        }
        
        # Memory pressure remediation
        if ($HealthResult.Checks.MemoryUsage.Status -eq 'Warning') {
            Write-MonitoringLog -Message "Memory pressure detected - logging for analysis" -Level Warning
            # Note: Memory remediation typically requires service restart or system-level intervention
            # This is logged for manual review rather than automated action
        }
    }
    catch {
        Write-MonitoringLog -Message "Remediation error: $($_.Exception.Message)" -Level Error
    }
    
    return $remediationResult
}

function Clear-VelociraptorTempFiles {
    $tempPath = "$env:TEMP\Velociraptor"
    $cleanedMB = 0
    
    if (Test-Path $tempPath) {
        $sizeBefore = (Get-ChildItem $tempPath -Recurse | Measure-Object -Property Length -Sum).Sum
        Remove-Item "$tempPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        $sizeAfter = (Get-ChildItem $tempPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        
        if ($null -eq $sizeAfter) { $sizeAfter = 0 }
        $cleanedMB = [math]::Round(($sizeBefore - $sizeAfter) / 1MB, 2)
    }
    
    return $cleanedMB
}

function Rotate-VelociraptorLogs {
    # This would implement log rotation logic
    # For now, return 0 as placeholder
    return 0
}

function Start-MonitoringDashboard {
    param([int]$Port)
    
    Write-MonitoringLog -Message "Starting monitoring dashboard on port $Port" -Level Info
    # Dashboard implementation would go here
    # This could be a simple HTTP server showing real-time metrics
}

function Stop-MonitoringDashboard {
    Write-MonitoringLog -Message "Stopping monitoring dashboard" -Level Info
    # Dashboard cleanup would go here
}

function Update-MonitoringMetrics {
    param([object]$HealthResult)
    
    $metric = @{
        Timestamp = $HealthResult.Timestamp
        OverallStatus = $HealthResult.OverallStatus
        AlertCount = $HealthResult.Alerts.Count
        Performance = $HealthResult.Performance
    }
    
    $script:MetricsHistory += $metric
    
    # Keep only recent metrics
    if ($script:MetricsHistory.Count -gt $script:MaxMetricsHistory) {
        $script:MetricsHistory = $script:MetricsHistory[-$script:MaxMetricsHistory..-1]
    }
}

function Get-DefaultAlertConfiguration {
    return @{
        Email = @{
            Enabled = $false
            Recipients = @()
            From = ""
            SmtpServer = ""
            Port = 587
            UseSSL = $true
            Credential = $null
        }
        Webhook = @{
            Enabled = $false
            Url = ""
            AuthHeader = $null
        }
        Slack = @{
            Enabled = $false
            WebhookUrl = ""
            Channel = "#alerts"
        }
        EventLog = @{
            Enabled = $true
        }
    }
}

# Handle Ctrl+C gracefully
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    $script:MonitoringActive = $false
}

# Start monitoring
Start-VelociraptorMonitoring