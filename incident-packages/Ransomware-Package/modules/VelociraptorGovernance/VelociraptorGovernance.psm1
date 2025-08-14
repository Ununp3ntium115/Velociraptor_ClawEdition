# Velociraptor Governance Module
# Provides compliance, audit, and governance capabilities

# Import required modules
if (Get-Module -Name VelociraptorDeployment -ListAvailable) {
    Import-Module VelociraptorDeployment -Force
}

# Module variables
$script:AuditTrailPath = "$env:ProgramData\Velociraptor\Audit"
$script:ComplianceReportsPath = "$env:ProgramData\Velociraptor\Compliance"
$script:PolicyConfigPath = "$env:ProgramData\Velociraptor\Policies"

# Ensure audit directories exist
if (-not (Test-Path $script:AuditTrailPath)) {
    New-Item -Path $script:AuditTrailPath -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path $script:ComplianceReportsPath)) {
    New-Item -Path $script:ComplianceReportsPath -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path $script:PolicyConfigPath)) {
    New-Item -Path $script:PolicyConfigPath -ItemType Directory -Force | Out-Null
}

function Test-ComplianceBaseline {
    <#
    .SYNOPSIS
        Tests Velociraptor deployment against compliance baselines.
    
    .DESCRIPTION
        Performs comprehensive compliance testing against various regulatory frameworks
        including SOX, HIPAA, PCI-DSS, GDPR, and custom compliance requirements.
    
    .PARAMETER ConfigPath
        Path to Velociraptor configuration file.
    
    .PARAMETER ComplianceFramework
        Compliance framework to test against.
    
    .PARAMETER CustomPolicyPath
        Path to custom compliance policy file.
    
    .PARAMETER GenerateReport
        Generate detailed compliance report.
    
    .PARAMETER OutputPath
        Output path for compliance report.
    
    .EXAMPLE
        Test-ComplianceBaseline -ConfigPath "server.yaml" -ComplianceFramework SOX -GenerateReport
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$ConfigPath,
        
        [ValidateSet('SOX', 'HIPAA', 'PCI_DSS', 'GDPR', 'ISO27001', 'NIST', 'Custom')]
        [string]$ComplianceFramework = 'SOX',
        
        [string]$CustomPolicyPath,
        
        [switch]$GenerateReport,
        
        [string]$OutputPath = $script:ComplianceReportsPath
    )
    
    Write-VelociraptorLog -Message "Starting compliance baseline test: $ComplianceFramework" -Level Info
    
    try {
        # Load compliance policies
        $policies = Get-CompliancePolicies -Framework $ComplianceFramework -CustomPath $CustomPolicyPath
        
        # Load current configuration
        $config = Get-Content $ConfigPath | ConvertFrom-Yaml
        
        # Perform compliance tests
        $complianceResult = @{
            Framework = $ComplianceFramework
            TestDate = Get-Date
            ConfigPath = $ConfigPath
            OverallCompliance = 0
            TotalTests = 0
            PassedTests = 0
            FailedTests = 0
            Categories = @{}
            Findings = @()
            Recommendations = @()
        }
        
        # Test each compliance category
        foreach ($category in $policies.Categories.GetEnumerator()) {
            Write-VelociraptorLog -Message "Testing compliance category: $($category.Key)" -Level Info
            
            $categoryResult = Test-ComplianceCategory -Config $config -Category $category.Value -CategoryName $category.Key
            $complianceResult.Categories[$category.Key] = $categoryResult
            
            $complianceResult.TotalTests += $categoryResult.TotalTests
            $complianceResult.PassedTests += $categoryResult.PassedTests
            $complianceResult.FailedTests += $categoryResult.FailedTests
            $complianceResult.Findings += $categoryResult.Findings
            $complianceResult.Recommendations += $categoryResult.Recommendations
        }
        
        # Calculate overall compliance percentage
        if ($complianceResult.TotalTests -gt 0) {
            $complianceResult.OverallCompliance = [math]::Round(($complianceResult.PassedTests / $complianceResult.TotalTests) * 100, 2)
        }
        
        # Log audit event
        Write-AuditEvent -EventType "ComplianceTest" -Details @{
            Framework = $ComplianceFramework
            OverallCompliance = $complianceResult.OverallCompliance
            TotalTests = $complianceResult.TotalTests
            PassedTests = $complianceResult.PassedTests
            FailedTests = $complianceResult.FailedTests
        }
        
        # Generate report if requested
        if ($GenerateReport) {
            $reportPath = New-ComplianceReport -ComplianceResult $complianceResult -OutputPath $OutputPath
            $complianceResult.ReportPath = $reportPath
        }
        
        Write-VelociraptorLog -Message "Compliance test completed: $($complianceResult.OverallCompliance)% compliant" -Level Info
        
        return $complianceResult
    }
    catch {
        Write-VelociraptorLog -Message "Compliance test failed: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Get-CompliancePolicies {
    param(
        [string]$Framework,
        [string]$CustomPath
    )
    
    if ($CustomPath -and (Test-Path $CustomPath)) {
        return Get-Content $CustomPath | ConvertFrom-Json
    }
    
    # Return framework-specific policies
    switch ($Framework) {
        'SOX' { return Get-SOXCompliancePolicies }
        'HIPAA' { return Get-HIPAACompliancePolicies }
        'PCI_DSS' { return Get-PCIDSSCompliancePolicies }
        'GDPR' { return Get-GDPRCompliancePolicies }
        'ISO27001' { return Get-ISO27001CompliancePolicies }
        'NIST' { return Get-NISTCompliancePolicies }
        default { return Get-DefaultCompliancePolicies }
    }
}

function Get-SOXCompliancePolicies {
    return @{
        Categories = @{
            'Access Controls' = @{
                Tests = @(
                    @{ Name = 'Authentication Required'; Check = 'config.GUI.authenticator' }
                    @{ Name = 'Role-Based Access'; Check = 'config.GUI.authenticator.type' }
                    @{ Name = 'Session Management'; Check = 'config.GUI.session_timeout' }
                )
            }
            'Audit Logging' = @{
                Tests = @(
                    @{ Name = 'Audit Logging Enabled'; Check = 'config.Logging.output_directory' }
                    @{ Name = 'Log Retention Policy'; Check = 'config.Logging.max_age' }
                    @{ Name = 'Log Integrity Protection'; Check = 'config.Logging.separate_logs_per_component' }
                )
            }
            'Data Protection' = @{
                Tests = @(
                    @{ Name = 'Encryption in Transit'; Check = 'config.GUI.use_plain_http' }
                    @{ Name = 'Certificate Management'; Check = 'config.GUI.tls_certificate_file' }
                    @{ Name = 'Data Storage Security'; Check = 'config.Datastore.location' }
                )
            }
            'Change Management' = @{
                Tests = @(
                    @{ Name = 'Configuration Backup'; Check = 'backup_policy' }
                    @{ Name = 'Change Approval Process'; Check = 'change_management' }
                    @{ Name = 'Version Control'; Check = 'version_tracking' }
                )
            }
        }
    }
}

function Get-HIPAACompliancePolicies {
    return @{
        Categories = @{
            'Administrative Safeguards' = @{
                Tests = @(
                    @{ Name = 'Access Management'; Check = 'config.GUI.authenticator' }
                    @{ Name = 'Workforce Training'; Check = 'training_records' }
                    @{ Name = 'Incident Response'; Check = 'incident_response_plan' }
                )
            }
            'Physical Safeguards' = @{
                Tests = @(
                    @{ Name = 'Facility Access Controls'; Check = 'physical_security' }
                    @{ Name = 'Workstation Security'; Check = 'workstation_controls' }
                    @{ Name = 'Media Controls'; Check = 'media_handling' }
                )
            }
            'Technical Safeguards' = @{
                Tests = @(
                    @{ Name = 'Access Control'; Check = 'config.GUI.authenticator' }
                    @{ Name = 'Audit Controls'; Check = 'config.Logging' }
                    @{ Name = 'Integrity'; Check = 'data_integrity_controls' }
                    @{ Name = 'Transmission Security'; Check = 'config.GUI.use_plain_http' }
                )
            }
        }
    }
}

function Test-ComplianceCategory {
    param($Config, $Category, $CategoryName)
    
    $result = @{
        CategoryName = $CategoryName
        TotalTests = $Category.Tests.Count
        PassedTests = 0
        FailedTests = 0
        Tests = @()
        Findings = @()
        Recommendations = @()
    }
    
    foreach ($test in $Category.Tests) {
        $testResult = @{
            Name = $test.Name
            Check = $test.Check
            Passed = $false
            Details = ""
        }
        
        try {
            # Evaluate compliance check
            $checkResult = Invoke-ComplianceCheck -Config $Config -Check $test.Check
            $testResult.Passed = $checkResult.Passed
            $testResult.Details = $checkResult.Details
            
            if ($checkResult.Passed) {
                $result.PassedTests++
            }
            else {
                $result.FailedTests++
                $result.Findings += "$($test.Name): $($checkResult.Details)"
                
                if ($checkResult.Recommendation) {
                    $result.Recommendations += $checkResult.Recommendation
                }
            }
        }
        catch {
            $testResult.Details = "Test execution failed: $($_.Exception.Message)"
            $result.FailedTests++
            $result.Findings += "$($test.Name): Test execution failed"
        }
        
        $result.Tests += $testResult
    }
    
    return $result
}

function Invoke-ComplianceCheck {
    param($Config, $Check)
    
    $result = @{
        Passed = $false
        Details = ""
        Recommendation = ""
    }
    
    try {
        switch ($Check) {
            'config.GUI.authenticator' {
                if ($Config.GUI.authenticator) {
                    $result.Passed = $true
                    $result.Details = "Authentication is configured"
                }
                else {
                    $result.Details = "Authentication is not configured"
                    $result.Recommendation = "Configure authentication for GUI access"
                }
            }
            'config.GUI.use_plain_http' {
                if ($Config.GUI.use_plain_http -eq $false -or $null -eq $Config.GUI.use_plain_http) {
                    $result.Passed = $true
                    $result.Details = "HTTPS is enforced"
                }
                else {
                    $result.Details = "Plain HTTP is allowed"
                    $result.Recommendation = "Disable plain HTTP and enforce HTTPS"
                }
            }
            'config.Logging.output_directory' {
                if ($Config.Logging -and $Config.Logging.output_directory) {
                    $result.Passed = $true
                    $result.Details = "Audit logging is configured"
                }
                else {
                    $result.Details = "Audit logging is not configured"
                    $result.Recommendation = "Configure comprehensive audit logging"
                }
            }
            default {
                $result.Details = "Check not implemented: $Check"
                $result.Recommendation = "Implement compliance check for $Check"
            }
        }
    }
    catch {
        $result.Details = "Check evaluation failed: $($_.Exception.Message)"
    }
    
    return $result
}

function Export-AuditReport {
    <#
    .SYNOPSIS
        Exports comprehensive audit report for Velociraptor deployment.
    
    .DESCRIPTION
        Generates detailed audit reports including configuration changes,
        access logs, compliance status, and security events.
    
    .PARAMETER StartDate
        Start date for audit report period.
    
    .PARAMETER EndDate
        End date for audit report period.
    
    .PARAMETER ReportType
        Type of audit report to generate.
    
    .PARAMETER OutputPath
        Output path for audit report.
    
    .PARAMETER Format
        Report format (HTML, PDF, JSON, CSV).
    
    .EXAMPLE
        Export-AuditReport -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date) -ReportType Full
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [DateTime]$StartDate,
        
        [Parameter(Mandatory)]
        [DateTime]$EndDate,
        
        [ValidateSet('Full', 'Security', 'Compliance', 'Changes', 'Access')]
        [string]$ReportType = 'Full',
        
        [string]$OutputPath = $script:ComplianceReportsPath,
        
        [ValidateSet('HTML', 'PDF', 'JSON', 'CSV')]
        [string]$Format = 'HTML'
    )
    
    Write-VelociraptorLog -Message "Generating audit report: $ReportType ($StartDate to $EndDate)" -Level Info
    
    try {
        # Collect audit data
        $auditData = @{
            ReportType = $ReportType
            StartDate = $StartDate
            EndDate = $EndDate
            GeneratedDate = Get-Date
            Events = @()
            Summary = @{}
        }
        
        # Get audit events for the specified period
        $auditEvents = Get-AuditEvents -StartDate $StartDate -EndDate $EndDate -EventType $ReportType
        $auditData.Events = $auditEvents
        
        # Generate summary statistics
        $auditData.Summary = @{
            TotalEvents = $auditEvents.Count
            EventTypes = $auditEvents | Group-Object EventType | ForEach-Object { @{ Type = $_.Name; Count = $_.Count } }
            SecurityEvents = ($auditEvents | Where-Object { $_.EventType -eq 'Security' }).Count
            ComplianceEvents = ($auditEvents | Where-Object { $_.EventType -eq 'Compliance' }).Count
            ChangeEvents = ($auditEvents | Where-Object { $_.EventType -eq 'Change' }).Count
            AccessEvents = ($auditEvents | Where-Object { $_.EventType -eq 'Access' }).Count
        }
        
        # Generate report based on format
        $reportPath = switch ($Format) {
            'HTML' { Generate-HTMLAuditReport -AuditData $auditData -OutputPath $OutputPath }
            'PDF' { Generate-PDFAuditReport -AuditData $auditData -OutputPath $OutputPath }
            'JSON' { Generate-JSONAuditReport -AuditData $auditData -OutputPath $OutputPath }
            'CSV' { Generate-CSVAuditReport -AuditData $auditData -OutputPath $OutputPath }
        }
        
        # Log audit report generation
        Write-AuditEvent -EventType "AuditReport" -Details @{
            ReportType = $ReportType
            Format = $Format
            StartDate = $StartDate
            EndDate = $EndDate
            EventCount = $auditEvents.Count
            ReportPath = $reportPath
        }
        
        Write-VelociraptorLog -Message "Audit report generated: $reportPath" -Level Info
        
        return @{
            ReportPath = $reportPath
            EventCount = $auditEvents.Count
            Summary = $auditData.Summary
        }
    }
    catch {
        Write-VelociraptorLog -Message "Audit report generation failed: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Write-AuditEvent {
    <#
    .SYNOPSIS
        Writes an event to the audit trail.
    
    .PARAMETER EventType
        Type of audit event.
    
    .PARAMETER Details
        Event details and metadata.
    
    .PARAMETER Severity
        Event severity level.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EventType,
        
        [Parameter(Mandatory)]
        [hashtable]$Details,
        
        [ValidateSet('Low', 'Medium', 'High', 'Critical')]
        [string]$Severity = 'Medium'
    )
    
    $auditEvent = @{
        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
        EventType = $EventType
        Severity = $Severity
        User = $env:USERNAME
        Computer = $env:COMPUTERNAME
        ProcessId = $PID
        Details = $Details
    }
    
    # Write to audit log file
    $auditLogPath = Join-Path $script:AuditTrailPath "audit-$(Get-Date -Format 'yyyy-MM').json"
    $auditEvent | ConvertTo-Json -Depth 10 | Add-Content -Path $auditLogPath
    
    # Also write to Velociraptor log if available
    if (Get-Command Write-VelociraptorLog -ErrorAction SilentlyContinue) {
        Write-VelociraptorLog -Message "AUDIT: $EventType - $($Details | ConvertTo-Json -Compress)" -Level Info
    }
}

function Get-AuditEvents {
    param(
        [DateTime]$StartDate,
        [DateTime]$EndDate,
        [string]$EventType
    )
    
    $events = @()
    
    # Get all audit log files in the date range
    $logFiles = Get-ChildItem -Path $script:AuditTrailPath -Filter "audit-*.json" | Where-Object {
        $fileDate = [DateTime]::ParseExact($_.BaseName.Substring(6), "yyyy-MM", $null)
        $fileDate -ge $StartDate.Date -and $fileDate -le $EndDate.Date
    }
    
    foreach ($logFile in $logFiles) {
        try {
            $logContent = Get-Content $logFile.FullName | Where-Object { $_.Trim() -ne "" }
            foreach ($line in $logContent) {
                $event = $line | ConvertFrom-Json
                $eventDate = [DateTime]::Parse($event.Timestamp)
                
                if ($eventDate -ge $StartDate -and $eventDate -le $EndDate) {
                    if (-not $EventType -or $event.EventType -eq $EventType -or $EventType -eq 'Full') {
                        $events += $event
                    }
                }
            }
        }
        catch {
            Write-Warning "Failed to parse audit log file: $($logFile.FullName)"
        }
    }
    
    return $events | Sort-Object Timestamp
}

function Generate-HTMLAuditReport {
    param($AuditData, $OutputPath)
    
    $reportPath = Join-Path $OutputPath "audit-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Velociraptor Audit Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #2c3e50; color: white; padding: 20px; text-align: center; }
        .summary { background-color: #ecf0f1; padding: 15px; margin: 20px 0; }
        .event { margin: 10px 0; padding: 10px; border-left: 4px solid #3498db; }
        .event-high { border-left-color: #e74c3c; }
        .event-critical { border-left-color: #c0392b; background-color: #fadbd8; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Velociraptor Audit Report</h1>
        <p>Report Type: $($AuditData.ReportType)</p>
        <p>Period: $($AuditData.StartDate.ToString('yyyy-MM-dd')) to $($AuditData.EndDate.ToString('yyyy-MM-dd'))</p>
        <p>Generated: $($AuditData.GeneratedDate.ToString('yyyy-MM-dd HH:mm:ss'))</p>
    </div>
    
    <div class="summary">
        <h2>Summary</h2>
        <p><strong>Total Events:</strong> $($AuditData.Summary.TotalEvents)</p>
        <p><strong>Security Events:</strong> $($AuditData.Summary.SecurityEvents)</p>
        <p><strong>Compliance Events:</strong> $($AuditData.Summary.ComplianceEvents)</p>
        <p><strong>Change Events:</strong> $($AuditData.Summary.ChangeEvents)</p>
        <p><strong>Access Events:</strong> $($AuditData.Summary.AccessEvents)</p>
    </div>
    
    <h2>Event Details</h2>
    <table>
        <tr>
            <th>Timestamp</th>
            <th>Event Type</th>
            <th>Severity</th>
            <th>User</th>
            <th>Details</th>
        </tr>
"@
    
    foreach ($event in $AuditData.Events) {
        $severityClass = if ($event.Severity -eq 'High') { 'event-high' } elseif ($event.Severity -eq 'Critical') { 'event-critical' } else { '' }
        $html += @"
        <tr class="$severityClass">
            <td>$($event.Timestamp)</td>
            <td>$($event.EventType)</td>
            <td>$($event.Severity)</td>
            <td>$($event.User)</td>
            <td>$($event.Details | ConvertTo-Json -Compress)</td>
        </tr>
"@
    }
    
    $html += @"
    </table>
</body>
</html>
"@
    
    $html | Set-Content -Path $reportPath
    return $reportPath
}

function Generate-JSONAuditReport {
    param($AuditData, $OutputPath)
    
    $reportPath = Join-Path $OutputPath "audit-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $AuditData | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath
    return $reportPath
}

function New-ComplianceReport {
    param($ComplianceResult, $OutputPath)
    
    $reportPath = Join-Path $OutputPath "compliance-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
    
    # Generate HTML compliance report (similar to audit report structure)
    # Implementation would be similar to Generate-HTMLAuditReport but focused on compliance data
    
    return $reportPath
}

# Export module functions
Export-ModuleMember -Function @(
    'Test-ComplianceBaseline',
    'Export-AuditReport',
    'Write-AuditEvent',
    'Get-AuditEvents'
)