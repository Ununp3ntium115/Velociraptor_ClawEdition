#Requires -Version 5.1

<#
.SYNOPSIS
    Velociraptor Compliance Framework Module
    
.DESCRIPTION
    Enterprise-grade compliance framework for Velociraptor DFIR infrastructure.
    Supports FedRAMP, SOC2, ISO27001, and other regulatory frameworks with
    automated compliance checking, audit trail generation, and evidence collection.
    
.NOTES
    Module: VelociraptorCompliance
    Author: Velociraptor Community
    Version: 1.0.0
    
    This module maintains forensic integrity while providing comprehensive
    compliance capabilities for enterprise DFIR operations.
#>

# Set strict mode for better error handling
Set-StrictMode -Version Latest

# Module-level error action preference
$ErrorActionPreference = 'Stop'

# Import required modules
try {
    Import-Module VelociraptorDeployment -ErrorAction Stop
} catch {
    Write-Error "VelociraptorDeployment module is required but not found. Please install it first."
}

# Module variables
$script:ComplianceFrameworks = @('FedRAMP', 'SOC2', 'ISO27001', 'NIST', 'HIPAA', 'PCI-DSS', 'GDPR')
$script:ComplianceDataPath = $null
$script:AuditLogPath = $null

# Initialize module paths
function Initialize-CompliancePaths {
    [CmdletBinding()]
    param()
    
    if ($env:OS -eq "Windows_NT" -or [System.Environment]::OSVersion.Platform -eq "Win32NT") {
        $script:ComplianceDataPath = Join-Path $env:ProgramData 'VelociraptorCompliance'
        $script:AuditLogPath = Join-Path $script:ComplianceDataPath 'AuditLogs'
    } elseif ($env:HOME) {
        $script:ComplianceDataPath = Join-Path $env:HOME '.velociraptor-compliance'
        $script:AuditLogPath = Join-Path $script:ComplianceDataPath 'audit-logs'
    } else {
        $script:ComplianceDataPath = '/tmp/velociraptor-compliance'
        $script:AuditLogPath = '/tmp/velociraptor-compliance/audit-logs'
    }
    
    # Create directories if they don't exist
    @($script:ComplianceDataPath, $script:AuditLogPath) | ForEach-Object {
        if (-not (Test-Path $_)) {
            try {
                New-Item -ItemType Directory -Path $_ -Force | Out-Null
                Write-VelociraptorLog "Created compliance directory: $_" -Level Info -Component "Compliance"
            } catch {
                Write-VelociraptorLog "Failed to create compliance directory $_: $($_.Exception.Message)" -Level Error -Component "Compliance"
                throw
            }
        }
    }
}

# Core Compliance Functions

function Initialize-VelociraptorCompliance {
    <#
    .SYNOPSIS
        Initializes the Velociraptor compliance framework.
        
    .DESCRIPTION
        Sets up the compliance infrastructure, creates necessary directories,
        initializes audit logging, and validates prerequisites for compliance operations.
        
    .PARAMETER Framework
        The compliance framework to initialize (FedRAMP, SOC2, ISO27001, etc.).
        
    .PARAMETER ComplianceLevel
        The compliance level or tier (e.g., 'Low', 'Moderate', 'High' for FedRAMP).
        
    .PARAMETER OrganizationInfo
        Hashtable containing organization information for compliance documentation.
        
    .EXAMPLE
        Initialize-VelociraptorCompliance -Framework "FedRAMP" -ComplianceLevel "Moderate"
        
    .EXAMPLE
        $orgInfo = @{
            Name = "Example Corp"
            Industry = "Financial Services"
            ComplianceOfficer = "John Doe"
            Contact = "compliance@example.com"
        }
        Initialize-VelociraptorCompliance -Framework "SOC2" -OrganizationInfo $orgInfo
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('FedRAMP', 'SOC2', 'ISO27001', 'NIST', 'HIPAA', 'PCI-DSS', 'GDPR')]
        [string]$Framework,
        
        [Parameter()]
        [string]$ComplianceLevel,
        
        [Parameter()]
        [hashtable]$OrganizationInfo = @{}
    )
    
    begin {
        Write-VelociraptorLog "Initializing Velociraptor Compliance Framework for $Framework" -Level Info -Component "Compliance"
        
        # Validate admin privileges
        if (-not (Test-VelociraptorAdminPrivileges)) {
            throw "Administrator privileges are required for compliance framework initialization."
        }
    }
    
    process {
        try {
            # Initialize paths
            Initialize-CompliancePaths
            
            # Create compliance audit entry
            $auditEntry = @{
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                Action = 'ComplianceInitialization'
                Framework = $Framework
                ComplianceLevel = $ComplianceLevel
                User = $env:USERNAME
                Computer = $env:COMPUTERNAME
                OrganizationInfo = $OrganizationInfo
                Status = 'Started'
            }
            
            Write-VelociraptorComplianceAudit -AuditEntry $auditEntry
            
            # Create framework-specific configuration
            $configPath = Join-Path $script:ComplianceDataPath "$Framework-config.json"
            $config = @{
                Framework = $Framework
                ComplianceLevel = $ComplianceLevel
                Initialized = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                Version = '1.0.0'
                OrganizationInfo = $OrganizationInfo
                ControlsConfiguration = Get-ComplianceControlsTemplate -Framework $Framework
                MonitoringEnabled = $false
                LastAssessment = $null
            }
            
            $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
            Write-VelociraptorLog "Created compliance configuration: $configPath" -Level Success -Component "Compliance"
            
            # Initialize compliance monitoring if applicable
            if ($Framework -in @('FedRAMP', 'SOC2', 'ISO27001')) {
                Enable-VelociraptorComplianceMonitoring -Framework $Framework
            }
            
            # Update audit entry
            $auditEntry.Status = 'Completed'
            Write-VelociraptorComplianceAudit -AuditEntry $auditEntry
            
            Write-VelociraptorLog "Compliance framework $Framework successfully initialized" -Level Success -Component "Compliance"
            
            return @{
                Framework = $Framework
                ComplianceLevel = $ComplianceLevel
                ConfigurationPath = $configPath
                AuditLogPath = $script:AuditLogPath
                Status = 'Initialized'
            }
            
        } catch {
            $auditEntry.Status = 'Failed'
            $auditEntry.Error = $_.Exception.Message
            Write-VelociraptorComplianceAudit -AuditEntry $auditEntry
            
            Write-VelociraptorLog "Failed to initialize compliance framework: $($_.Exception.Message)" -Level Error -Component "Compliance"
            throw
        }
    }
}

function Test-VelociraptorCompliance {
    <#
    .SYNOPSIS
        Performs comprehensive compliance assessment and validation.
        
    .DESCRIPTION
        Executes automated compliance testing against specified framework requirements.
        Generates detailed assessment reports with findings and recommendations.
        
    .PARAMETER Framework
        The compliance framework to test against.
        
    .PARAMETER ConfigPath
        Path to the Velociraptor configuration file to assess.
        
    .PARAMETER ControlScope
        Specific controls to test (default: all controls).
        
    .PARAMETER OutputFormat
        Output format for the assessment report (JSON, XML, HTML, CSV).
        
    .PARAMETER GenerateEvidence
        Generate compliance evidence packages for audit purposes.
        
    .EXAMPLE
        Test-VelociraptorCompliance -Framework "FedRAMP" -ConfigPath "server.config.yaml"
        
    .EXAMPLE
        Test-VelociraptorCompliance -Framework "SOC2" -ControlScope @("CC6.1", "CC6.2") -GenerateEvidence
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('FedRAMP', 'SOC2', 'ISO27001', 'NIST', 'HIPAA', 'PCI-DSS', 'GDPR')]
        [string]$Framework,
        
        [Parameter()]
        [string]$ConfigPath,
        
        [Parameter()]
        [string[]]$ControlScope,
        
        [Parameter()]
        [ValidateSet('JSON', 'XML', 'HTML', 'CSV')]
        [string]$OutputFormat = 'JSON',
        
        [Parameter()]
        [switch]$GenerateEvidence
    )
    
    begin {
        Write-VelociraptorLog "Starting compliance assessment for $Framework" -Level Info -Component "Compliance"
        Initialize-CompliancePaths
    }
    
    process {
        try {
            # Load compliance controls for the framework
            $controls = Get-ComplianceControls -Framework $Framework -ControlScope $ControlScope
            
            # Initialize assessment results
            $assessmentResults = @{
                Framework = $Framework
                AssessmentDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                ConfigurationPath = $ConfigPath
                TotalControls = $controls.Count
                PassedControls = 0
                FailedControls = 0
                NotApplicableControls = 0
                ComplianceScore = 0
                Findings = @()
                Evidence = @()
                Recommendations = @()
            }
            
            # Create audit entry
            $auditEntry = @{
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                Action = 'ComplianceAssessment'
                Framework = $Framework
                ConfigPath = $ConfigPath
                User = $env:USERNAME
                Computer = $env:COMPUTERNAME
                Status = 'InProgress'
            }
            Write-VelociraptorComplianceAudit -AuditEntry $auditEntry
            
            # Execute compliance tests
            foreach ($control in $controls) {
                Write-VelociraptorLog "Testing control: $($control.Id) - $($control.Title)" -Level Info -Component "Compliance"
                
                $testResult = Invoke-ComplianceControlTest -Control $control -ConfigPath $ConfigPath
                
                # Update assessment results
                switch ($testResult.Status) {
                    'Pass' { $assessmentResults.PassedControls++ }
                    'Fail' { 
                        $assessmentResults.FailedControls++
                        $assessmentResults.Findings += $testResult
                    }
                    'NotApplicable' { $assessmentResults.NotApplicableControls++ }
                }
                
                # Generate evidence if requested
                if ($GenerateEvidence -and $testResult.Status -eq 'Pass') {
                    $evidence = New-ComplianceEvidence -Control $control -TestResult $testResult
                    $assessmentResults.Evidence += $evidence
                }
            }
            
            # Calculate compliance score
            $applicableControls = $assessmentResults.TotalControls - $assessmentResults.NotApplicableControls
            if ($applicableControls -gt 0) {
                $assessmentResults.ComplianceScore = [math]::Round(($assessmentResults.PassedControls / $applicableControls) * 100, 2)
            }
            
            # Generate recommendations
            $assessmentResults.Recommendations = Get-ComplianceRecommendations -Framework $Framework -Findings $assessmentResults.Findings
            
            # Save assessment report
            $reportPath = Join-Path $script:ComplianceDataPath "compliance-assessment-$Framework-$(Get-Date -Format 'yyyyMMdd-HHmmss').$($OutputFormat.ToLower())"
            Export-ComplianceReport -AssessmentResults $assessmentResults -OutputPath $reportPath -Format $OutputFormat
            
            # Update audit entry
            $auditEntry.Status = 'Completed'
            $auditEntry.ComplianceScore = $assessmentResults.ComplianceScore
            $auditEntry.ReportPath = $reportPath
            Write-VelociraptorComplianceAudit -AuditEntry $auditEntry
            
            Write-VelociraptorLog "Compliance assessment completed. Score: $($assessmentResults.ComplianceScore)%" -Level Success -Component "Compliance"
            Write-VelociraptorLog "Assessment report saved: $reportPath" -Level Info -Component "Compliance"
            
            return $assessmentResults
            
        } catch {
            $auditEntry.Status = 'Failed'
            $auditEntry.Error = $_.Exception.Message
            Write-VelociraptorComplianceAudit -AuditEntry $auditEntry
            
            Write-VelociraptorLog "Compliance assessment failed: $($_.Exception.Message)" -Level Error -Component "Compliance"
            throw
        }
    }
}

function Enable-VelociraptorComplianceMonitoring {
    <#
    .SYNOPSIS
        Enables continuous compliance monitoring for Velociraptor infrastructure.
        
    .DESCRIPTION
        Sets up automated compliance monitoring that continuously validates
        configuration against compliance requirements and generates alerts
        for potential violations.
        
    .PARAMETER Framework
        The compliance framework to monitor.
        
    .PARAMETER MonitoringInterval
        Monitoring interval in minutes (default: 60).
        
    .PARAMETER AlertThreshold
        Compliance score threshold below which alerts are generated.
        
    .EXAMPLE
        Enable-VelociraptorComplianceMonitoring -Framework "FedRAMP" -MonitoringInterval 30
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('FedRAMP', 'SOC2', 'ISO27001', 'NIST', 'HIPAA', 'PCI-DSS', 'GDPR')]
        [string]$Framework,
        
        [Parameter()]
        [int]$MonitoringInterval = 60,
        
        [Parameter()]
        [int]$AlertThreshold = 95
    )
    
    begin {
        Write-VelociraptorLog "Enabling compliance monitoring for $Framework" -Level Info -Component "Compliance"
        Initialize-CompliancePaths
    }
    
    process {
        try {
            # Create monitoring configuration
            $monitoringConfig = @{
                Framework = $Framework
                Enabled = $true
                MonitoringInterval = $MonitoringInterval
                AlertThreshold = $AlertThreshold
                LastCheck = $null
                EnabledDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                Alerts = @()
            }
            
            # Save monitoring configuration
            $configPath = Join-Path $script:ComplianceDataPath "$Framework-monitoring.json"
            $monitoringConfig | ConvertTo-Json -Depth 5 | Out-File -FilePath $configPath -Encoding UTF8
            
            # Create audit entry
            $auditEntry = @{
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                Action = 'EnableComplianceMonitoring'
                Framework = $Framework
                MonitoringInterval = $MonitoringInterval
                AlertThreshold = $AlertThreshold
                User = $env:USERNAME
                Computer = $env:COMPUTERNAME
                Status = 'Enabled'
            }
            Write-VelociraptorComplianceAudit -AuditEntry $auditEntry
            
            Write-VelociraptorLog "Compliance monitoring enabled for $Framework (Interval: $MonitoringInterval min, Threshold: $AlertThreshold%)" -Level Success -Component "Compliance"
            
            return @{
                Framework = $Framework
                MonitoringEnabled = $true
                ConfigurationPath = $configPath
                MonitoringInterval = $MonitoringInterval
                AlertThreshold = $AlertThreshold
            }
            
        } catch {
            Write-VelociraptorLog "Failed to enable compliance monitoring: $($_.Exception.Message)" -Level Error -Component "Compliance"
            throw
        }
    }
}

function Write-VelociraptorComplianceAudit {
    <#
    .SYNOPSIS
        Writes compliance audit entries with forensic integrity.
        
    .DESCRIPTION
        Creates tamper-evident audit log entries for compliance activities.
        Maintains chain of custody and provides non-repudiation for audit trails.
        
    .PARAMETER AuditEntry
        Hashtable containing audit entry information.
        
    .PARAMETER AuditLogPath
        Custom path for audit log (optional).
        
    .EXAMPLE
        $auditEntry = @{
            Timestamp = Get-Date
            Action = "ConfigurationChange"
            User = $env:USERNAME
            Details = "Updated server configuration"
        }
        Write-VelociraptorComplianceAudit -AuditEntry $auditEntry
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$AuditEntry,
        
        [Parameter()]
        [string]$AuditLogPath
    )
    
    begin {
        if (-not $AuditLogPath) {
            Initialize-CompliancePaths
            $AuditLogPath = $script:AuditLogPath
        }
    }
    
    process {
        try {
            # Add system information for forensic integrity
            $enrichedEntry = $AuditEntry.Clone()
            $enrichedEntry.AuditId = [System.Guid]::NewGuid().ToString()
            $enrichedEntry.SystemTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
            $enrichedEntry.TimeZone = [System.TimeZoneInfo]::Local.DisplayName
            $enrichedEntry.ProcessId = $PID
            $enrichedEntry.SessionId = [System.Diagnostics.Process]::GetCurrentProcess().SessionId
            $enrichedEntry.MachineInfo = @{
                Computer = $env:COMPUTERNAME
                Domain = $env:USERDOMAIN
                OSVersion = [System.Environment]::OSVersion.VersionString
                PSVersion = $PSVersionTable.PSVersion.ToString()
            }
            
            # Create hash for integrity verification
            $entryJson = $enrichedEntry | ConvertTo-Json -Depth 10 -Compress
            $hash = Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($entryJson))) -Algorithm SHA256
            $enrichedEntry.IntegrityHash = $hash.Hash
            
            # Write to audit log with timestamp
            $logFile = Join-Path $AuditLogPath "compliance-audit-$(Get-Date -Format 'yyyyMM').json"
            $logEntry = @{
                AuditEntry = $enrichedEntry
                LogTimestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
            }
            
            # Append to monthly audit log file
            $logEntry | ConvertTo-Json -Depth 15 -Compress | Out-File -FilePath $logFile -Append -Encoding UTF8
            
            # Also write to main Velociraptor log
            Write-VelociraptorLog "Audit: $($AuditEntry.Action) - $($AuditEntry.Status)" -Level Info -Component "ComplianceAudit"
            
        } catch {
            Write-VelociraptorLog "Failed to write compliance audit entry: $($_.Exception.Message)" -Level Error -Component "ComplianceAudit"
            throw
        }
    }
}

# Helper Functions

function Get-ComplianceControlsTemplate {
    <#
    .SYNOPSIS
        Gets the compliance controls template for a specific framework.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Framework
    )
    
    # This will load from template files in the templates directory
    $templatePath = Join-Path $PSScriptRoot "templates\$Framework-controls.json"
    
    if (Test-Path $templatePath) {
        return Get-Content $templatePath | ConvertFrom-Json
    } else {
        # Return basic template structure
        return @{
            Framework = $Framework
            Version = '1.0.0'
            Controls = @()
            ControlCategories = @()
        }
    }
}

function Get-ComplianceControls {
    <#
    .SYNOPSIS
        Gets compliance controls for assessment.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Framework,
        
        [Parameter()]
        [string[]]$ControlScope
    )
    
    $controls = @()
    
    switch ($Framework) {
        'FedRAMP' {
            $controls = Get-FedRAMPControls -ControlScope $ControlScope
        }
        'SOC2' {
            $controls = Get-SOC2Controls -ControlScope $ControlScope
        }
        'ISO27001' {
            $controls = Get-ISO27001Controls -ControlScope $ControlScope
        }
        default {
            $controls = Get-GenericComplianceControls -Framework $Framework -ControlScope $ControlScope
        }
    }
    
    return $controls
}

function Invoke-ComplianceControlTest {
    <#
    .SYNOPSIS
        Executes a compliance control test.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Control,
        
        [Parameter()]
        [string]$ConfigPath
    )
    
    try {
        $testResult = @{
            ControlId = $Control.Id
            ControlTitle = $Control.Title
            Status = 'NotTested'
            Findings = @()
            Evidence = @()
            TestDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
        
        # Execute control-specific tests
        switch ($Control.TestType) {
            'Configuration' {
                $testResult = Test-ConfigurationControl -Control $Control -ConfigPath $ConfigPath
            }
            'Process' {
                $testResult = Test-ProcessControl -Control $Control
            }
            'Technical' {
                $testResult = Test-TechnicalControl -Control $Control
            }
            default {
                $testResult.Status = 'NotApplicable'
                $testResult.Findings += "Test type '$($Control.TestType)' not implemented"
            }
        }
        
        return $testResult
        
    } catch {
        return @{
            ControlId = $Control.Id
            ControlTitle = $Control.Title
            Status = 'Error'
            Findings = @("Test execution failed: $($_.Exception.Message)")
            TestDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
    }
}

# Initialize compliance paths when module loads
Initialize-CompliancePaths

# Import function files
$functionFiles = @(
    'Framework-Specific.ps1',
    'Control-Testing.ps1',
    'Technical-Testing.ps1',
    'Reporting-Evidence.ps1',
    'Continuous-Monitoring.ps1'
)

foreach ($file in $functionFiles) {
    $functionPath = Join-Path $PSScriptRoot "functions\$file"
    if (Test-Path $functionPath) {
        try {
            . $functionPath
            Write-VelociraptorLog "Loaded compliance function file: $file" -Level Debug -Component "Compliance"
        } catch {
            Write-VelociraptorLog "Failed to load compliance function file $file`: $($_.Exception.Message)" -Level Error -Component "Compliance"
        }
    }
}

# Export module functions
Export-ModuleMember -Function @(
    # Core Compliance Functions
    'Initialize-VelociraptorCompliance',
    'Test-VelociraptorCompliance', 
    'Enable-VelociraptorComplianceMonitoring',
    'Disable-VelociraptorComplianceMonitoring',
    'Write-VelociraptorComplianceAudit',
    
    # Framework-Specific Functions
    'Test-VelociraptorFedRAMP',
    'Test-VelociraptorSOC2',
    'Test-VelociraptorISO27001',
    'Test-VelociraptorNIST',
    'Test-VelociraptorHIPAA',
    'Test-VelociraptorPCIDSS',
    'Test-VelociraptorGDPR',
    'Get-FedRAMPControls',
    'Get-SOC2Controls',
    'Get-ISO27001Controls',
    
    # Testing Functions
    'Test-ConfigurationControl',
    'Test-ProcessControl',
    'Test-TechnicalControl',
    'Test-AuthenticationTechnical',
    'Test-AuditingTechnical',
    'Test-AccessControlTechnical',
    'Test-CommunicationsProtection',
    'Test-SystemIntegrity',
    'Test-ConfigurationManagement',
    
    # Reporting and Evidence Functions
    'Export-ComplianceReport',
    'New-ComplianceEvidence',
    'Export-VelociraptorComplianceEvidence',
    'Import-VelociraptorComplianceEvidence',
    'Get-ComplianceRecommendations',
    
    # Continuous Monitoring Functions
    'Start-VelociraptorComplianceMonitor',
    'Stop-VelociraptorComplianceMonitor',
    'Get-VelociraptorComplianceAlerts',
    'Get-VelociraptorComplianceStatus',
    'Set-VelociraptorComplianceThresholds'
)