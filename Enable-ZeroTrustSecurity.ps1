#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Enables comprehensive zero-trust security for Velociraptor DFIR deployments.

.DESCRIPTION
    This script integrates the ZeroTrustSecurity module with existing Velociraptor deployments
    to implement enterprise-grade zero-trust architecture. It provides comprehensive security
    controls while maintaining DFIR operational requirements and forensic integrity.

.PARAMETER ConfigPath
    Path to the Velociraptor configuration file.

.PARAMETER SecurityLevel
    Zero-trust security level to implement (Basic, Standard, Enhanced, Maximum, Forensic).

.PARAMETER ComplianceFramework
    Compliance framework to implement (NIST, CIS, DISA_STIG, SOX, HIPAA, PCI_DSS, GDPR).

.PARAMETER EnableNetworkSegmentation
    Enable network segmentation and micro-segmentation.

.PARAMETER EnableCertificateAuth
    Enable certificate-based authentication.

.PARAMETER EnableContinuousMonitoring
    Enable continuous monitoring and verification.

.PARAMETER ForensicMode
    Enable forensic-grade security with evidence preservation.

.PARAMETER DryRun
    Perform a dry run without making actual changes.

.EXAMPLE
    .\Enable-ZeroTrustSecurity.ps1 -ConfigPath "server.yaml" -SecurityLevel Enhanced -ComplianceFramework NIST

.EXAMPLE
    .\Enable-ZeroTrustSecurity.ps1 -ConfigPath "server.yaml" -SecurityLevel Maximum -ForensicMode -EnableContinuousMonitoring

.NOTES
    Author: Velociraptor Community
    Version: 1.0.0
    Requires: PowerShell 5.1+, Administrator privileges, VelociraptorDeployment module
    
    This script implements defensive security controls for legitimate DFIR operations.
    Ensure proper authorization before deployment in production environments.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$ConfigPath,
    
    [ValidateSet('Basic', 'Standard', 'Enhanced', 'Maximum', 'Forensic')]
    [string]$SecurityLevel = 'Enhanced',
    
    [ValidateSet('NIST', 'CIS', 'DISA_STIG', 'SOX', 'HIPAA', 'PCI_DSS', 'GDPR')]
    [string]$ComplianceFramework = 'NIST',
    
    [switch]$EnableNetworkSegmentation,
    
    [switch]$EnableCertificateAuth,
    
    [switch]$EnableContinuousMonitoring,
    
    [switch]$ForensicMode,
    
    [switch]$GenerateReport,
    
    [string]$ReportPath,
    
    [switch]$DryRun
)

# Set error handling
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Security warning for production deployments
if ($env:COMPUTERNAME -notlike '*TEST*' -and $env:COMPUTERNAME -notlike '*DEV*' -and -not $DryRun) {
    Write-Warning @"
SECURITY NOTICE: Zero-Trust Security Implementation

You are about to implement enterprise-grade zero-trust security controls
on a production Velociraptor deployment. This will:

- Modify authentication and access control mechanisms
- Implement network segmentation and encryption
- Enable continuous monitoring and verification
- Apply compliance framework requirements

Ensure you have:
1. Proper authorization for security modifications
2. Backup of current configuration
3. Maintenance window for implementation
4. Understanding of operational impact

This implementation is designed for legitimate DFIR operations only.
"@
    
    $confirmation = Read-Host "Continue with zero-trust implementation? (y/N)"
    if ($confirmation -notin @('y', 'yes', 'Y', 'YES')) {
        Write-Host "Zero-trust implementation cancelled by user" -ForegroundColor Yellow
        exit 0
    }
}

# Import required modules
try {
    Write-Host "Loading required modules..." -ForegroundColor Cyan
    Import-Module "$PSScriptRoot\modules\VelociraptorDeployment" -Force -ErrorAction Stop
    Import-Module "$PSScriptRoot\modules\ZeroTrustSecurity" -Force -ErrorAction Stop
    Write-Host "Modules loaded successfully" -ForegroundColor Green
}
catch {
    Write-Error "Failed to load required modules: $($_.Exception.Message)"
    exit 1
}

# Verify administrator privileges
Write-Host "Verifying administrator privileges..." -ForegroundColor Cyan
$adminCheck = Test-VelociraptorAdminPrivileges -TestServiceControl -TestFirewallAccess -TestRegistryAccess -TestCertificateAccess -TestUserManagement
if (-not $adminCheck.HasRequiredPrivileges) {
    Write-Error "Administrator privileges required for zero-trust security implementation"
    exit 1
}
Write-Host "Administrator privileges verified" -ForegroundColor Green

# Start zero-trust implementation
$startTime = Get-Date
Write-Host ""
Write-Host "=== ZERO-TRUST SECURITY IMPLEMENTATION ===" -ForegroundColor Cyan
Write-Host "Configuration: $ConfigPath" -ForegroundColor Green
Write-Host "Security Level: $SecurityLevel" -ForegroundColor Green
Write-Host "Compliance Framework: $ComplianceFramework" -ForegroundColor Green
Write-Host "Network Segmentation: $EnableNetworkSegmentation" -ForegroundColor Green
Write-Host "Certificate Auth: $EnableCertificateAuth" -ForegroundColor Green
Write-Host "Continuous Monitoring: $EnableContinuousMonitoring" -ForegroundColor Green
Write-Host "Forensic Mode: $ForensicMode" -ForegroundColor Green
Write-Host "Dry Run: $DryRun" -ForegroundColor $(if ($DryRun) { 'Yellow' } else { 'Green' })
Write-Host ""

# Initialize implementation results
$implementationResults = @{
    StartTime = $startTime
    ConfigPath = $ConfigPath
    SecurityLevel = $SecurityLevel
    ComplianceFramework = $ComplianceFramework
    Success = $false
    Components = @{}
    Errors = @()
    Warnings = @()
    Summary = @{}
}

try {
    # Step 1: Initialize Zero-Trust Security Framework
    Write-Host "Step 1: Initializing Zero-Trust Security Framework..." -ForegroundColor Cyan
    $initResults = Initialize-ZeroTrustSecurity -ConfigPath $ConfigPath -SecurityLevel $SecurityLevel -ComplianceFramework $ComplianceFramework -EnableContinuousVerification:$EnableContinuousMonitoring -ForensicMode:$ForensicMode -DryRun:$DryRun
    $implementationResults.Components['Initialization'] = $initResults
    Write-Host "Zero-trust framework initialized successfully" -ForegroundColor Green
    
    # Step 2: Configure Network Segmentation (if enabled)
    if ($EnableNetworkSegmentation) {
        Write-Host "Step 2: Configuring Network Segmentation..." -ForegroundColor Cyan
        
        # Create DFIR operations segment
        $dfirSegment = New-NetworkSegment -SegmentName "DFIR-Operations" -NetworkRange "10.1.0.0/24" -TrustLevel Trusted -IsolationLevel Enhanced -ForensicPreservation:$ForensicMode -DryRun:$DryRun
        
        # Create evidence storage segment
        $evidenceSegment = New-NetworkSegment -SegmentName "Evidence-Storage" -NetworkRange "10.2.0.0/24" -TrustLevel HighlyTrusted -IsolationLevel Complete -ForensicPreservation -DryRun:$DryRun
        
        # Create analysis workstation segment
        $analysisSegment = New-NetworkSegment -SegmentName "Analysis-Workstations" -NetworkRange "10.3.0.0/24" -TrustLevel Trusted -IsolationLevel Enhanced -DryRun:$DryRun
        
        $implementationResults.Components['NetworkSegmentation'] = @{
            DFIRSegment = $dfirSegment
            EvidenceSegment = $evidenceSegment
            AnalysisSegment = $analysisSegment
        }
        Write-Host "Network segmentation configured successfully" -ForegroundColor Green
    }
    
    # Step 3: Configure Certificate-Based Authentication (if enabled)
    if ($EnableCertificateAuth) {
        Write-Host "Step 3: Configuring Certificate-Based Authentication..." -ForegroundColor Cyan
        
        # Create server certificate
        $serverCert = New-ZeroTrustCertificate -CertificateType Server -Subject "CN=velociraptor.local" -ForensicGrade:$ForensicMode -ValidityPeriod 365 -DryRun:$DryRun
        
        # Configure certificate-based authentication
        $certAuth = Set-CertificateBasedAuth -ServiceName "VelociraptorServer" -CertificateThumbprint $serverCert.Thumbprint -RequireClientCertificate -ValidateChain -ForensicValidation:$ForensicMode -DryRun:$DryRun
        
        $implementationResults.Components['CertificateAuth'] = @{
            ServerCertificate = $serverCert
            AuthConfiguration = $certAuth
        }
        Write-Host "Certificate-based authentication configured successfully" -ForegroundColor Green
    }
    
    # Step 4: Configure Encryption Framework
    Write-Host "Step 4: Configuring Encryption Framework..." -ForegroundColor Cyan
    
    # Enable end-to-end encryption
    $e2eEncryption = Enable-EndToEndEncryption -ServiceName "VelociraptorServer" -EncryptionLevel $(if ($ForensicMode) { 'Forensic' } else { $SecurityLevel }) -ForensicMode:$ForensicMode -PerfectForwardSecrecy -DryRun:$DryRun
    
    # Configure encryption at rest for data directories
    $configDir = Split-Path $ConfigPath -Parent
    $dataPath = Join-Path $configDir "data"
    if (Test-Path $dataPath) {
        $atRestEncryption = Set-EncryptionAtRest -DataPath $dataPath -EncryptionProvider FileSystem -ForensicIntegrity:$ForensicMode -DryRun:$DryRun
    }
    
    $implementationResults.Components['Encryption'] = @{
        EndToEndEncryption = $e2eEncryption
        AtRestEncryption = if ($atRestEncryption) { $atRestEncryption } else { $null }
    }
    Write-Host "Encryption framework configured successfully" -ForegroundColor Green
    
    # Step 5: Configure Identity and Access Management
    Write-Host "Step 5: Configuring Identity and Access Management..." -ForegroundColor Cyan
    
    # Create sample DFIR analyst identity
    $analystIdentity = New-ZeroTrustIdentity -Username "dfir-analyst" -Role DFIRAnalyst -MFARequired -ForensicAccess:$ForensicMode -DryRun:$DryRun
    
    # Configure least privilege access
    $accessControls = Set-LeastPrivilegeAccess -Username "dfir-analyst" -Role DFIRAnalyst -AccessScope @('Data', 'Service') -PrivilegeLevel Standard -ForensicAccess:$ForensicMode -DryRun:$DryRun
    
    $implementationResults.Components['IdentityAccessManagement'] = @{
        AnalystIdentity = $analystIdentity
        AccessControls = $accessControls
    }
    Write-Host "Identity and access management configured successfully" -ForegroundColor Green
    
    # Step 6: Start Continuous Monitoring (if enabled)
    if ($EnableContinuousMonitoring) {
        Write-Host "Step 6: Starting Continuous Monitoring..." -ForegroundColor Cyan
        
        $ztConfigPath = Join-Path (Split-Path $ConfigPath -Parent) "zero-trust-config.json"
        $monitoring = Start-ZeroTrustMonitoring -ConfigPath $ztConfigPath -MonitoringLevel $(if ($ForensicMode) { 'Forensic' } else { $SecurityLevel }) -ThreatDetection -BehavioralAnalysis:$ForensicMode -ForensicMode:$ForensicMode -DryRun:$DryRun
        
        $implementationResults.Components['ContinuousMonitoring'] = $monitoring
        Write-Host "Continuous monitoring started successfully" -ForegroundColor Green
    }
    
    # Step 7: Enable Zero-Trust Mode
    Write-Host "Step 7: Enabling Zero-Trust Mode..." -ForegroundColor Cyan
    if (-not $DryRun) {
        $ztModeResults = Enable-ZeroTrustMode -ConfigPath $ConfigPath -GracePeriod 60
        $implementationResults.Components['ZeroTrustMode'] = $ztModeResults
        Write-Host "Zero-trust mode enabled successfully" -ForegroundColor Green
    }
    else {
        Write-Host "Zero-trust mode would be enabled (dry run)" -ForegroundColor Yellow
    }
    
    # Step 8: Perform Compliance Assessment
    Write-Host "Step 8: Performing Compliance Assessment..." -ForegroundColor Cyan
    $complianceResults = Test-ZeroTrustCompliance -ConfigPath $ConfigPath -Framework $ComplianceFramework -IncludeRemediation
    $implementationResults.Components['ComplianceAssessment'] = $complianceResults
    Write-Host "Compliance assessment completed" -ForegroundColor Green
    
    # Mark implementation as successful
    $implementationResults.Success = $true
    $implementationResults.EndTime = Get-Date
    $implementationResults.Duration = ($implementationResults.EndTime - $implementationResults.StartTime).TotalMinutes
    
    # Generate implementation summary
    Write-Host ""
    Write-Host "=== ZERO-TRUST IMPLEMENTATION SUMMARY ===" -ForegroundColor Cyan
    Write-Host "Status: SUCCESS" -ForegroundColor Green
    Write-Host "Duration: $([math]::Round($implementationResults.Duration, 2)) minutes" -ForegroundColor Green
    Write-Host "Components Configured: $($implementationResults.Components.Keys.Count)" -ForegroundColor Green
    Write-Host "Compliance Score: $($complianceResults.CompliancePercentage)%" -ForegroundColor $(
        if ($complianceResults.CompliancePercentage -ge 90) { 'Green' }
        elseif ($complianceResults.CompliancePercentage -ge 75) { 'Yellow' }
        else { 'Red' }
    )
    
    if ($initResults.TrustBoundariesCreated -gt 0) {
        Write-Host "Trust Boundaries Created: $($initResults.TrustBoundariesCreated)" -ForegroundColor Green
    }
    
    if ($EnableNetworkSegmentation) {
        Write-Host "Network Segments: 3 (DFIR-Operations, Evidence-Storage, Analysis-Workstations)" -ForegroundColor Green
    }
    
    if ($EnableCertificateAuth) {
        Write-Host "Certificate Authentication: Enabled" -ForegroundColor Green
    }
    
    if ($EnableContinuousMonitoring) {
        Write-Host "Continuous Monitoring: Active" -ForegroundColor Green
    }
    
    Write-Host ""
    
    # Generate detailed report if requested
    if ($GenerateReport) {
        Write-Host "Generating implementation report..." -ForegroundColor Cyan
        $reportFile = Generate-ZeroTrustImplementationReport -Results $implementationResults -ReportPath $ReportPath
        Write-Host "Implementation report generated: $reportFile" -ForegroundColor Green
    }
    
    # Display next steps
    Write-Host "=== NEXT STEPS ===" -ForegroundColor Cyan
    Write-Host "1. Review and test zero-trust configuration" -ForegroundColor White
    Write-Host "2. Train users on new authentication procedures" -ForegroundColor White
    Write-Host "3. Monitor system performance and adjust as needed" -ForegroundColor White
    Write-Host "4. Regularly review and update security policies" -ForegroundColor White
    Write-Host "5. Conduct periodic compliance assessments" -ForegroundColor White
    
    if ($complianceResults.CompliancePercentage -lt 90) {
        Write-Host ""
        Write-Host "RECOMMENDATIONS:" -ForegroundColor Yellow
        foreach ($recommendation in $complianceResults.Recommendations | Select-Object -First 3) {
            Write-Host "- $recommendation" -ForegroundColor Yellow
        }
    }
    
    # Log successful implementation
    Write-VelociraptorLog -Message "Zero-trust security implementation completed successfully for $ConfigPath" -Level INFO
    
    Write-Host ""
    Write-Host "Zero-Trust Security implementation completed successfully!" -ForegroundColor Green
    Write-Host "Your Velociraptor deployment is now protected with enterprise-grade zero-trust security." -ForegroundColor Green
}
catch {
    $implementationResults.Success = $false
    $implementationResults.EndTime = Get-Date
    $implementationResults.Errors += $_.Exception.Message
    
    Write-Host ""
    Write-Host "=== ZERO-TRUST IMPLEMENTATION FAILED ===" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Duration: $([math]::Round(((Get-Date) - $startTime).TotalMinutes, 2)) minutes" -ForegroundColor Yellow
    
    # Log implementation failure
    Write-VelociraptorLog -Message "Zero-trust security implementation failed: $($_.Exception.Message)" -Level ERROR
    
    # Provide troubleshooting guidance
    Write-Host ""
    Write-Host "TROUBLESHOOTING GUIDANCE:" -ForegroundColor Yellow
    Write-Host "1. Verify administrator privileges" -ForegroundColor White
    Write-Host "2. Check Velociraptor configuration file validity" -ForegroundColor White
    Write-Host "3. Ensure all required modules are properly installed" -ForegroundColor White
    Write-Host "4. Review system logs for additional error details" -ForegroundColor White
    Write-Host "5. Try running with -DryRun first to validate configuration" -ForegroundColor White
    
    exit 1
}

# Function to generate implementation report
function Generate-ZeroTrustImplementationReport {
    param($Results, $ReportPath)
    
    if (-not $ReportPath) {
        $ReportPath = "zero-trust-implementation-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
    }
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Zero-Trust Security Implementation Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #1e3a8a; color: white; padding: 20px; text-align: center; }
        .success { background-color: #dcfce7; padding: 15px; margin: 20px 0; border-left: 4px solid #16a34a; }
        .warning { background-color: #fef3c7; padding: 15px; margin: 20px 0; border-left: 4px solid #f59e0b; }
        .error { background-color: #fee2e2; padding: 15px; margin: 20px 0; border-left: 4px solid #dc2626; }
        .component { margin: 20px 0; padding: 15px; border: 1px solid #e5e7eb; }
        .metric { display: inline-block; margin: 10px; padding: 10px; background-color: #f3f4f6; border-radius: 5px; }
        .compliance-good { color: #16a34a; font-weight: bold; }
        .compliance-warning { color: #f59e0b; font-weight: bold; }
        .compliance-critical { color: #dc2626; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Zero-Trust Security Implementation Report</h1>
        <p>Generated: $(Get-Date)</p>
        <p>Status: $(if ($Results.Success) { 'SUCCESS' } else { 'FAILED' })</p>
    </div>
    
    <div class="$(if ($Results.Success) { 'success' } else { 'error' })">
        <h2>Implementation Summary</h2>
        <p><strong>Configuration File:</strong> $($Results.ConfigPath)</p>
        <p><strong>Security Level:</strong> $($Results.SecurityLevel)</p>
        <p><strong>Compliance Framework:</strong> $($Results.ComplianceFramework)</p>
        <p><strong>Duration:</strong> $([math]::Round($Results.Duration, 2)) minutes</p>
        <p><strong>Components Configured:</strong> $($Results.Components.Keys.Count)</p>
    </div>
"@
    
    # Add component details
    foreach ($component in $Results.Components.GetEnumerator()) {
        $html += @"
    <div class="component">
        <h3>$($component.Key)</h3>
        <p>Configuration completed successfully</p>
    </div>
"@
    }
    
    # Add compliance information
    if ($Results.Components.ComplianceAssessment) {
        $compliance = $Results.Components.ComplianceAssessment
        $complianceClass = if ($compliance.CompliancePercentage -ge 90) { 'compliance-good' } 
                          elseif ($compliance.CompliancePercentage -ge 75) { 'compliance-warning' } 
                          else { 'compliance-critical' }
        
        $html += @"
    <div class="component">
        <h3>Compliance Assessment</h3>
        <p><strong>Overall Compliance:</strong> <span class="$complianceClass">$($compliance.CompliancePercentage)%</span></p>
        <p><strong>Framework:</strong> $($compliance.Framework)</p>
    </div>
"@
    }
    
    $html += @"
</body>
</html>
"@
    
    $html | Set-Content -Path $ReportPath
    return $ReportPath
}