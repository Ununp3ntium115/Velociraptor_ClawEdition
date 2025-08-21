#Requires -Version 5.1

<#
.SYNOPSIS
    Zero-Trust Security Framework for Velociraptor DFIR Infrastructure

.DESCRIPTION
    This module provides comprehensive zero-trust security implementation for Velociraptor deployments.
    It implements enterprise-grade security controls while maintaining DFIR operational requirements
    and forensic integrity standards.

    Key Features:
    - Network segmentation and micro-segmentation with trust boundaries
    - Identity and access management with multi-factor authentication
    - Certificate-based authentication framework with PKI integration
    - End-to-end encryption with automated key rotation
    - Continuous monitoring and real-time threat detection
    - Least privilege access controls with just-in-time access
    - Policy-driven compliance framework (NIST, CIS, DISA STIG)
    - Multi-cloud zero-trust configurations
    - Container and Kubernetes security policies

.NOTES
    Author: Velociraptor Community
    Version: 1.0.0
    Requires: PowerShell 5.1 or higher, VelociraptorDeployment module
    
    Security Notice: This module implements defensive security controls for legitimate
    DFIR operations. Ensure proper authorization before deployment in production environments.
#>

# Set strict mode for enhanced security
Set-StrictMode -Version Latest

# Module variables
$script:ModuleRoot = $PSScriptRoot
$script:ZeroTrustConfig = $null
$script:TrustBoundaries = @()
$script:SecurityTelemetry = @{}
$script:ComplianceFrameworks = @{}

# Constants
$script:ZERO_TRUST_VERSION = '1.0.0'
$script:DEFAULT_TRUST_SCORE_THRESHOLD = 80
$script:CONTINUOUS_VERIFICATION_INTERVAL = 300  # 5 minutes
$script:CERTIFICATE_RENEWAL_THRESHOLD = 30      # 30 days before expiry

# Import VelociraptorDeployment module
try {
    Import-Module VelociraptorDeployment -Force -ErrorAction Stop
    Write-Verbose "Successfully imported VelociraptorDeployment module"
}
catch {
    throw "Failed to import required VelociraptorDeployment module: $($_.Exception.Message)"
}

# Import all function files
$functionPath = Join-Path $script:ModuleRoot 'functions'
if (Test-Path $functionPath) {
    $functionFiles = Get-ChildItem -Path $functionPath -Filter '*.ps1' -Recurse
    foreach ($file in $functionFiles) {
        try {
            . $file.FullName
            Write-Verbose "Imported zero-trust function file: $($file.Name)"
        }
        catch {
            Write-Error "Failed to import zero-trust function file $($file.Name): $($_.Exception.Message)"
        }
    }
}
else {
    Write-Warning "Zero-trust functions directory not found: $functionPath"
}

# Load zero-trust policy templates
$templatesPath = Join-Path $script:ModuleRoot 'templates'
if (Test-Path $templatesPath) {
    try {
        # Load policy templates
        $policyTemplatesFile = Join-Path $templatesPath 'zero-trust-policies.json'
        if (Test-Path $policyTemplatesFile) {
            $script:PolicyTemplates = Get-Content $policyTemplatesFile | ConvertFrom-Json
            Write-Verbose "Loaded zero-trust policy templates"
        }
        
        # Load compliance frameworks
        $complianceFile = Join-Path $templatesPath 'compliance-frameworks.json'
        if (Test-Path $complianceFile) {
            $script:ComplianceFrameworks = Get-Content $complianceFile | ConvertFrom-Json
            Write-Verbose "Loaded compliance framework definitions"
        }
    }
    catch {
        Write-Warning "Failed to load zero-trust templates: $($_.Exception.Message)"
    }
}

# Create backward compatibility aliases for zero-trust operations
$ztAliases = @{
    'zt-init' = 'Initialize-ZeroTrustSecurity'
    'zt-test' = 'Test-ZeroTrustCompliance'
    'zt-enable' = 'Enable-ZeroTrustMode'
    'zt-monitor' = 'Start-ZeroTrustMonitoring'
    'zt-verify' = 'Test-ContinuousVerification'
    'zt-segment' = 'New-NetworkSegment'
    'zt-auth' = 'Set-MultiFactorAuthentication'
    'zt-cert' = 'New-ZeroTrustCertificate'
    'zt-encrypt' = 'Enable-EndToEndEncryption'
    'zt-access' = 'Set-LeastPrivilegeAccess'
}

foreach ($alias in $ztAliases.GetEnumerator()) {
    try {
        Set-Alias -Name $alias.Key -Value $alias.Value -Scope Global -Force
        Write-Verbose "Created zero-trust alias: $($alias.Key) -> $($alias.Value)"
    }
    catch {
        Write-Warning "Failed to create zero-trust alias $($alias.Key): $($_.Exception.Message)"
    }
}

# Initialize zero-trust security context
function Initialize-ZeroTrustContext {
    [CmdletBinding()]
    param()
    
    try {
        # Initialize security telemetry
        $script:SecurityTelemetry = @{
            StartTime = Get-Date
            TrustVerifications = 0
            SecurityEvents = @()
            ThreatDetections = @()
            PolicyViolations = @()
            LastVerification = $null
        }
        
        # Initialize trust boundaries
        $script:TrustBoundaries = @()
        
        # Set default zero-trust configuration
        $script:ZeroTrustConfig = @{
            Version = $script:ZERO_TRUST_VERSION
            Mode = 'Disabled'
            TrustScoreThreshold = $script:DEFAULT_TRUST_SCORE_THRESHOLD
            ContinuousVerificationEnabled = $false
            VerificationInterval = $script:CONTINUOUS_VERIFICATION_INTERVAL
            DefaultDenyAll = $true
            RequireExplicitTrust = $true
            EnforceNetworkSegmentation = $true
            RequireMFA = $true
            RequireCertificateAuth = $false
            EncryptionLevel = 'Standard'
            ComplianceFramework = 'NIST'
            LoggingLevel = 'INFO'
            MonitoringEnabled = $false
        }
        
        Write-Verbose "Zero-trust security context initialized successfully"
        return $true
    }
    catch {
        Write-Error "Failed to initialize zero-trust context: $($_.Exception.Message)"
        return $false
    }
}

# Module initialization
Write-Verbose "Initializing Zero-Trust Security Framework..."

# Initialize zero-trust context
if (-not (Initialize-ZeroTrustContext)) {
    Write-Warning "Zero-trust context initialization failed. Some features may not work correctly."
}

# Register module cleanup
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    # Cleanup zero-trust resources
    if ($script:SecurityTelemetry -and $script:SecurityTelemetry.MonitoringJobs) {
        foreach ($job in $script:SecurityTelemetry.MonitoringJobs) {
            try {
                Stop-Job -Job $job -ErrorAction SilentlyContinue
                Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
            }
            catch {
                # Ignore cleanup errors
            }
        }
    }
    
    Write-Verbose "Zero-Trust Security Framework unloaded"
}

Write-Verbose "Zero-Trust Security Framework loaded successfully"
Write-Host "Zero-Trust Security Framework v$($script:ZERO_TRUST_VERSION) ready for DFIR operations" -ForegroundColor Green

# Export module members
Export-ModuleMember -Function * -Alias * -Variable ZeroTrustConfig

# Security warning for production deployments
if ($env:COMPUTERNAME -notlike '*TEST*' -and $env:COMPUTERNAME -notlike '*DEV*') {
    Write-Warning @"
SECURITY NOTICE: Zero-Trust Security Framework for DFIR Operations

This module implements enterprise-grade security controls for Velociraptor deployments.
Ensure you have proper authorization before deploying in production environments.

Key Security Features:
- Network micro-segmentation with trust boundaries
- Multi-factor authentication and continuous verification  
- Certificate-based authentication with PKI integration
- End-to-end encryption with automated key rotation
- Real-time threat detection and security monitoring
- Least privilege access controls with just-in-time access
- Compliance framework enforcement (NIST, CIS, DISA STIG)

For DFIR use only. Maintain forensic integrity and chain of custody.
"@
}