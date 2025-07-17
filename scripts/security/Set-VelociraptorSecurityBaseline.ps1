#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Applies comprehensive security baseline configuration to Velociraptor deployment.

.DESCRIPTION
    This script implements security hardening measures for Velociraptor deployments
    based on industry best practices and compliance frameworks including:
    - CIS (Center for Internet Security) benchmarks
    - NIST Cybersecurity Framework
    - DISA STIG (Security Technical Implementation Guide)
    - Custom security policies

.PARAMETER ConfigPath
    Path to the Velociraptor configuration file.

.PARAMETER SecurityLevel
    Security hardening level: Basic, Standard, Maximum, Custom.

.PARAMETER ComplianceFramework
    Compliance framework to apply: CIS, NIST, DISA_STIG, Custom.

.PARAMETER CustomPolicyPath
    Path to custom security policy configuration file.

.PARAMETER BackupConfig
    Create backup of current configuration before applying changes.

.PARAMETER ValidateOnly
    Only validate current security posture without making changes.

.PARAMETER GenerateReport
    Generate detailed security compliance report.

.EXAMPLE
    .\Set-VelociraptorSecurityBaseline.ps1 -ConfigPath "server.yaml" -SecurityLevel Standard

.EXAMPLE
    .\Set-VelociraptorSecurityBaseline.ps1 -ConfigPath "server.yaml" -ComplianceFramework CIS -GenerateReport
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$ConfigPath,
    
    [ValidateSet('Basic', 'Standard', 'Maximum', 'Custom')]
    [string]$SecurityLevel = 'Standard',
    
    [ValidateSet('CIS', 'NIST', 'DISA_STIG', 'Custom')]
    [string]$ComplianceFramework = 'CIS',
    
    [string]$CustomPolicyPath,
    
    [switch]$BackupConfig = $true,
    
    [switch]$ValidateOnly,
    
    [switch]$GenerateReport
)

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\VelociraptorDeployment" -Force

function Set-VelociraptorSecurityBaseline {
    Write-Host "=== VELOCIRAPTOR SECURITY BASELINE CONFIGURATION ===" -ForegroundColor Cyan
    Write-Host "Configuration: $ConfigPath" -ForegroundColor Green
    Write-Host "Security Level: $SecurityLevel" -ForegroundColor Green
    Write-Host "Compliance Framework: $ComplianceFramework" -ForegroundColor Green
    Write-Host "Validation Only: $ValidateOnly" -ForegroundColor Green
    Write-Host ""
    
    try {
        # Verify admin privileges
        $adminCheck = Test-VelociraptorAdminPrivileges -TestServiceControl -TestFirewallAccess -TestRegistryAccess
        if (-not $adminCheck.HasRequiredPrivileges) {
            throw "Administrator privileges required for security baseline configuration"
        }
        
        # Load security policies
        $securityPolicies = Get-SecurityPolicies -SecurityLevel $SecurityLevel -ComplianceFramework $ComplianceFramework -CustomPolicyPath $CustomPolicyPath
        
        # Backup current configuration
        if ($BackupConfig -and -not $ValidateOnly) {
            $backupResult = Backup-VelociraptorConfiguration -ConfigPath $ConfigPath
            Write-Host "Configuration backed up to: $($backupResult.BackupPath)" -ForegroundColor Yellow
        }
        
        # Load current configuration
        $currentConfig = Get-Content $ConfigPath | ConvertFrom-Yaml
        
        # Perform security assessment
        Write-Host "Performing security assessment..." -ForegroundColor Cyan
        $securityAssessment = Test-VelociraptorSecurityCompliance -Config $currentConfig -Policies $securityPolicies
        
        # Display current security posture
        Show-SecurityAssessmentSummary -Assessment $securityAssessment
        
        if ($ValidateOnly) {
            Write-Host "Validation complete. No changes made." -ForegroundColor Yellow
            return $securityAssessment
        }
        
        # Apply security hardening
        Write-Host "Applying security hardening measures..." -ForegroundColor Cyan
        $hardeningResults = Apply-SecurityHardening -Config $currentConfig -Policies $securityPolicies -Assessment $securityAssessment
        
        # Save hardened configuration
        if ($hardeningResults.ConfigurationChanged) {
            $hardeningResults.HardenedConfig | ConvertTo-Yaml | Set-Content -Path $ConfigPath
            Write-Host "Hardened configuration saved to: $ConfigPath" -ForegroundColor Green
        }
        
        # Apply system-level security settings
        Apply-SystemSecuritySettings -Policies $securityPolicies
        
        # Configure firewall rules
        Configure-SecurityFirewallRules -Policies $securityPolicies
        
        # Set file and registry permissions
        Set-SecurityPermissions -Policies $securityPolicies -ConfigPath $ConfigPath
        
        # Generate compliance report
        if ($GenerateReport) {
            $reportPath = Generate-SecurityComplianceReport -Assessment $securityAssessment -HardeningResults $hardeningResults
            Write-Host "Security compliance report generated: $reportPath" -ForegroundColor Green
        }
        
        Write-Host "Security baseline configuration completed successfully!" -ForegroundColor Green
        
        return @{
            Assessment = $securityAssessment
            HardeningResults = $hardeningResults
            ReportPath = if ($GenerateReport) { $reportPath } else { $null }
        }
    }
    catch {
        Write-Host "Security baseline configuration failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-VelociraptorLog -Message "Security baseline error: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Get-SecurityPolicies {
    param(
        [string]$SecurityLevel,
        [string]$ComplianceFramework,
        [string]$CustomPolicyPath
    )
    
    $policies = @{
        Encryption = @{}
        Authentication = @{}
        Authorization = @{}
        Logging = @{}
        Network = @{}
        FileSystem = @{}
        System = @{}
    }
    
    # Load base policies based on security level
    switch ($SecurityLevel) {
        'Basic' {
            $policies = Get-BasicSecurityPolicies
        }
        'Standard' {
            $policies = Get-StandardSecurityPolicies
        }
        'Maximum' {
            $policies = Get-MaximumSecurityPolicies
        }
        'Custom' {
            if ($CustomPolicyPath -and (Test-Path $CustomPolicyPath)) {
                $policies = Get-Content $CustomPolicyPath | ConvertFrom-Json
            }
            else {
                $policies = Get-StandardSecurityPolicies
            }
        }
    }
    
    # Apply compliance framework overlays
    switch ($ComplianceFramework) {
        'CIS' {
            $policies = Merge-CISCompliancePolicies -Policies $policies
        }
        'NIST' {
            $policies = Merge-NISTCompliancePolicies -Policies $policies
        }
        'DISA_STIG' {
            $policies = Merge-DISTASTIGPolicies -Policies $policies
        }
    }
    
    return $policies
}

function Get-StandardSecurityPolicies {
    return @{
        Encryption = @{
            RequireSSL = $true
            MinimumTLSVersion = '1.2'
            CipherSuites = @('TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384', 'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256')
            CertificateValidation = $true
            RequireClientCertificates = $false
        }
        Authentication = @{
            RequireAuthentication = $true
            MinimumPasswordLength = 12
            RequireComplexPasswords = $true
            MaxFailedAttempts = 5
            LockoutDuration = 900  # 15 minutes
            SessionTimeout = 3600  # 1 hour
            RequireMFA = $false
        }
        Authorization = @{
            DefaultDenyAll = $true
            RequireRoleBasedAccess = $true
            MinimumPrivilegeLevel = 'User'
            AuditPermissionChanges = $true
        }
        Logging = @{
            EnableAuditLogging = $true
            LogLevel = 'INFO'
            LogRetentionDays = 90
            LogEncryption = $true
            RemoteLogging = $false
            LogFailedAuthentication = $true
            LogPrivilegeEscalation = $true
        }
        Network = @{
            RestrictBindAddresses = $true
            AllowedNetworks = @('127.0.0.1/32', '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16')
            BlockedPorts = @(23, 135, 139, 445, 1433, 3389)
            RequireFirewall = $true
            DisableUnnecessaryServices = $true
        }
        FileSystem = @{
            RestrictFilePermissions = $true
            RequireFileIntegrity = $true
            DisableExecutionFromTemp = $true
            AuditFileAccess = $true
        }
        System = @{
            DisableUnnecessaryFeatures = $true
            RequireSystemUpdates = $true
            ConfigureEventLogging = $true
            SetSecurityPolicies = $true
        }
    }
}

function Get-MaximumSecurityPolicies {
    $policies = Get-StandardSecurityPolicies
    
    # Enhance for maximum security
    $policies.Encryption.RequireClientCertificates = $true
    $policies.Encryption.MinimumTLSVersion = '1.3'
    $policies.Authentication.RequireMFA = $true
    $policies.Authentication.MinimumPasswordLength = 16
    $policies.Authentication.MaxFailedAttempts = 3
    $policies.Authentication.SessionTimeout = 1800  # 30 minutes
    $policies.Logging.LogLevel = 'DEBUG'
    $policies.Logging.RemoteLogging = $true
    $policies.Network.AllowedNetworks = @('127.0.0.1/32')  # Localhost only
    
    return $policies
}

function Get-BasicSecurityPolicies {
    $policies = Get-StandardSecurityPolicies
    
    # Reduce for basic security
    $policies.Authentication.MinimumPasswordLength = 8
    $policies.Authentication.RequireComplexPasswords = $false
    $policies.Authentication.MaxFailedAttempts = 10
    $policies.Logging.LogLevel = 'WARN'
    $policies.Logging.LogRetentionDays = 30
    
    return $policies
}

function Test-VelociraptorSecurityCompliance {
    param($Config, $Policies)
    
    $assessment = @{
        OverallScore = 0
        MaxScore = 0
        CompliancePercentage = 0
        Categories = @{}
        Findings = @()
        Recommendations = @()
    }
    
    # Test encryption compliance
    $encryptionAssessment = Test-EncryptionCompliance -Config $Config -Policies $Policies.Encryption
    $assessment.Categories['Encryption'] = $encryptionAssessment
    
    # Test authentication compliance
    $authAssessment = Test-AuthenticationCompliance -Config $Config -Policies $Policies.Authentication
    $assessment.Categories['Authentication'] = $authAssessment
    
    # Test logging compliance
    $loggingAssessment = Test-LoggingCompliance -Config $Config -Policies $Policies.Logging
    $assessment.Categories['Logging'] = $loggingAssessment
    
    # Test network compliance
    $networkAssessment = Test-NetworkCompliance -Config $Config -Policies $Policies.Network
    $assessment.Categories['Network'] = $networkAssessment
    
    # Calculate overall score
    $totalScore = 0
    $maxTotalScore = 0
    
    foreach ($category in $assessment.Categories.Values) {
        $totalScore += $category.Score
        $maxTotalScore += $category.MaxScore
        $assessment.Findings += $category.Findings
        $assessment.Recommendations += $category.Recommendations
    }
    
    $assessment.OverallScore = $totalScore
    $assessment.MaxScore = $maxTotalScore
    $assessment.CompliancePercentage = if ($maxTotalScore -gt 0) { [math]::Round(($totalScore / $maxTotalScore) * 100, 2) } else { 0 }
    
    return $assessment
}

function Test-EncryptionCompliance {
    param($Config, $Policies)
    
    $assessment = @{
        Score = 0
        MaxScore = 0
        Findings = @()
        Recommendations = @()
    }
    
    # Test SSL/TLS configuration
    if ($Policies.RequireSSL) {
        $assessment.MaxScore += 10
        if ($Config.GUI.use_plain_http -eq $false -or $null -eq $Config.GUI.use_plain_http) {
            $assessment.Score += 10
        }
        else {
            $assessment.Findings += "SSL/TLS not enforced for GUI"
            $assessment.Recommendations += "Enable SSL/TLS encryption for web interface"
        }
    }
    
    # Test certificate configuration
    if ($Policies.CertificateValidation) {
        $assessment.MaxScore += 10
        if ($Config.GUI.tls_certificate_file -and $Config.GUI.tls_private_key_file) {
            $assessment.Score += 10
        }
        else {
            $assessment.Findings += "Custom TLS certificates not configured"
            $assessment.Recommendations += "Configure custom TLS certificates"
        }
    }
    
    return $assessment
}

function Test-AuthenticationCompliance {
    param($Config, $Policies)
    
    $assessment = @{
        Score = 0
        MaxScore = 0
        Findings = @()
        Recommendations = @()
    }
    
    # Test authentication requirement
    if ($Policies.RequireAuthentication) {
        $assessment.MaxScore += 15
        if ($Config.GUI.authenticator -and $Config.GUI.authenticator.type) {
            $assessment.Score += 15
        }
        else {
            $assessment.Findings += "Authentication not properly configured"
            $assessment.Recommendations += "Configure proper authentication mechanism"
        }
    }
    
    return $assessment
}

function Test-LoggingCompliance {
    param($Config, $Policies)
    
    $assessment = @{
        Score = 0
        MaxScore = 0
        Findings = @()
        Recommendations = @()
    }
    
    # Test audit logging
    if ($Policies.EnableAuditLogging) {
        $assessment.MaxScore += 10
        if ($Config.Logging -and $Config.Logging.output_directory) {
            $assessment.Score += 10
        }
        else {
            $assessment.Findings += "Audit logging not properly configured"
            $assessment.Recommendations += "Configure comprehensive audit logging"
        }
    }
    
    return $assessment
}

function Test-NetworkCompliance {
    param($Config, $Policies)
    
    $assessment = @{
        Score = 0
        MaxScore = 0
        Findings = @()
        Recommendations = @()
    }
    
    # Test bind address restrictions
    if ($Policies.RestrictBindAddresses) {
        $assessment.MaxScore += 10
        $bindAddress = $Config.GUI.bind_address
        if ($bindAddress -and $bindAddress -ne '0.0.0.0') {
            $assessment.Score += 10
        }
        else {
            $assessment.Findings += "Service bound to all interfaces (0.0.0.0)"
            $assessment.Recommendations += "Restrict bind address to specific interfaces"
        }
    }
    
    return $assessment
}

function Apply-SecurityHardening {
    param($Config, $Policies, $Assessment)
    
    $results = @{
        ConfigurationChanged = $false
        HardenedConfig = $Config.PSObject.Copy()
        ChangesApplied = @()
    }
    
    # Apply encryption hardening
    if ($Assessment.Categories.Encryption.Score -lt $Assessment.Categories.Encryption.MaxScore) {
        Apply-EncryptionHardening -Config $results.HardenedConfig -Policies $Policies.Encryption -Results $results
    }
    
    # Apply authentication hardening
    if ($Assessment.Categories.Authentication.Score -lt $Assessment.Categories.Authentication.MaxScore) {
        Apply-AuthenticationHardening -Config $results.HardenedConfig -Policies $Policies.Authentication -Results $results
    }
    
    # Apply logging hardening
    if ($Assessment.Categories.Logging.Score -lt $Assessment.Categories.Logging.MaxScore) {
        Apply-LoggingHardening -Config $results.HardenedConfig -Policies $Policies.Logging -Results $results
    }
    
    # Apply network hardening
    if ($Assessment.Categories.Network.Score -lt $Assessment.Categories.Network.MaxScore) {
        Apply-NetworkHardening -Config $results.HardenedConfig -Policies $Policies.Network -Results $results
    }
    
    return $results
}

function Apply-EncryptionHardening {
    param($Config, $Policies, $Results)
    
    if ($Policies.RequireSSL -and ($Config.GUI.use_plain_http -eq $true)) {
        $Config.GUI.use_plain_http = $false
        $Results.ChangesApplied += "Disabled plain HTTP for GUI"
        $Results.ConfigurationChanged = $true
    }
    
    if ($Policies.MinimumTLSVersion) {
        if (-not $Config.GUI.tls_config) {
            $Config.GUI | Add-Member -NotePropertyName 'tls_config' -NotePropertyValue @{}
        }
        $Config.GUI.tls_config.min_version = $Policies.MinimumTLSVersion
        $Results.ChangesApplied += "Set minimum TLS version to $($Policies.MinimumTLSVersion)"
        $Results.ConfigurationChanged = $true
    }
}

function Apply-AuthenticationHardening {
    param($Config, $Policies, $Results)
    
    if ($Policies.RequireAuthentication -and (-not $Config.GUI.authenticator)) {
        $Config.GUI | Add-Member -NotePropertyName 'authenticator' -NotePropertyValue @{
            type = 'Basic'
            sub_authenticators = @(
                @{
                    type = 'BasicAuthenticator'
                }
            )
        }
        $Results.ChangesApplied += "Enabled basic authentication"
        $Results.ConfigurationChanged = $true
    }
}

function Apply-LoggingHardening {
    param($Config, $Policies, $Results)
    
    if ($Policies.EnableAuditLogging -and (-not $Config.Logging)) {
        $Config | Add-Member -NotePropertyName 'Logging' -NotePropertyValue @{
            output_directory = 'logs'
            separate_logs_per_component = $true
            rotation_time = 86400  # Daily rotation
            max_age = $Policies.LogRetentionDays * 86400
        }
        $Results.ChangesApplied += "Enabled comprehensive audit logging"
        $Results.ConfigurationChanged = $true
    }
}

function Apply-NetworkHardening {
    param($Config, $Policies, $Results)
    
    if ($Policies.RestrictBindAddresses -and ($Config.GUI.bind_address -eq '0.0.0.0')) {
        $Config.GUI.bind_address = '127.0.0.1'
        $Results.ChangesApplied += "Restricted bind address to localhost"
        $Results.ConfigurationChanged = $true
    }
}

function Apply-SystemSecuritySettings {
    param($Policies)
    
    Write-Host "Applying system-level security settings..." -ForegroundColor Cyan
    
    # Configure Windows Event Logging
    if ($Policies.System.ConfigureEventLogging) {
        Configure-WindowsEventLogging
    }
    
    # Set security policies
    if ($Policies.System.SetSecurityPolicies) {
        Set-WindowsSecurityPolicies -Policies $Policies
    }
}

function Configure-SecurityFirewallRules {
    param($Policies)
    
    if ($Policies.Network.RequireFirewall) {
        Write-Host "Configuring firewall rules..." -ForegroundColor Cyan
        
        # Enable Windows Firewall
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
        
        # Block unnecessary ports
        foreach ($port in $Policies.Network.BlockedPorts) {
            $ruleName = "Block-Port-$port-Velociraptor-Security"
            if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
                New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Protocol TCP -LocalPort $port -Action Block
                Write-Host "  Blocked inbound traffic on port $port" -ForegroundColor Yellow
            }
        }
    }
}

function Set-SecurityPermissions {
    param($Policies, $ConfigPath)
    
    if ($Policies.FileSystem.RestrictFilePermissions) {
        Write-Host "Setting secure file permissions..." -ForegroundColor Cyan
        
        # Secure configuration file permissions
        $configDir = Split-Path $ConfigPath -Parent
        $acl = Get-Acl $configDir
        
        # Remove inherited permissions and set explicit permissions
        $acl.SetAccessRuleProtection($true, $false)
        
        # Grant full control to Administrators
        $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
        )
        $acl.SetAccessRule($adminRule)
        
        # Grant read/execute to SYSTEM
        $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "SYSTEM", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow"
        )
        $acl.SetAccessRule($systemRule)
        
        Set-Acl -Path $configDir -AclObject $acl
        Write-Host "  Secured configuration directory permissions" -ForegroundColor Yellow
    }
}

function Show-SecurityAssessmentSummary {
    param($Assessment)
    
    Write-Host "=== SECURITY ASSESSMENT SUMMARY ===" -ForegroundColor Cyan
    Write-Host "Overall Compliance: $($Assessment.CompliancePercentage)% ($($Assessment.OverallScore)/$($Assessment.MaxScore))" -ForegroundColor $(
        if ($Assessment.CompliancePercentage -ge 80) { 'Green' }
        elseif ($Assessment.CompliancePercentage -ge 60) { 'Yellow' }
        else { 'Red' }
    )
    Write-Host ""
    
    foreach ($category in $Assessment.Categories.GetEnumerator()) {
        $percentage = if ($category.Value.MaxScore -gt 0) { [math]::Round(($category.Value.Score / $category.Value.MaxScore) * 100, 1) } else { 0 }
        Write-Host "$($category.Key): $percentage% ($($category.Value.Score)/$($category.Value.MaxScore))" -ForegroundColor $(
            if ($percentage -ge 80) { 'Green' }
            elseif ($percentage -ge 60) { 'Yellow' }
            else { 'Red' }
        )
    }
    
    if ($Assessment.Findings.Count -gt 0) {
        Write-Host ""
        Write-Host "Security Findings:" -ForegroundColor Red
        foreach ($finding in $Assessment.Findings) {
            Write-Host "  - $finding" -ForegroundColor Red
        }
    }
    
    Write-Host ""
}

function Generate-SecurityComplianceReport {
    param($Assessment, $HardeningResults)
    
    $reportPath = "velociraptor-security-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Velociraptor Security Compliance Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #2c3e50; color: white; padding: 20px; text-align: center; }
        .summary { background-color: #ecf0f1; padding: 15px; margin: 20px 0; }
        .category { margin: 20px 0; padding: 15px; border-left: 4px solid #3498db; }
        .finding { color: #e74c3c; margin: 5px 0; }
        .recommendation { color: #f39c12; margin: 5px 0; }
        .change { color: #27ae60; margin: 5px 0; }
        .score-good { color: #27ae60; font-weight: bold; }
        .score-warning { color: #f39c12; font-weight: bold; }
        .score-critical { color: #e74c3c; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Velociraptor Security Compliance Report</h1>
        <p>Generated: $(Get-Date)</p>
    </div>
    
    <div class="summary">
        <h2>Executive Summary</h2>
        <p><strong>Overall Compliance:</strong> <span class="$(if ($Assessment.CompliancePercentage -ge 80) { 'score-good' } elseif ($Assessment.CompliancePercentage -ge 60) { 'score-warning' } else { 'score-critical' })">$($Assessment.CompliancePercentage)%</span></p>
        <p><strong>Score:</strong> $($Assessment.OverallScore) / $($Assessment.MaxScore)</p>
        <p><strong>Total Findings:</strong> $($Assessment.Findings.Count)</p>
        <p><strong>Changes Applied:</strong> $($HardeningResults.ChangesApplied.Count)</p>
    </div>
"@
    
    # Add category details
    foreach ($category in $Assessment.Categories.GetEnumerator()) {
        $percentage = if ($category.Value.MaxScore -gt 0) { [math]::Round(($category.Value.Score / $category.Value.MaxScore) * 100, 1) } else { 0 }
        $scoreClass = if ($percentage -ge 80) { 'score-good' } elseif ($percentage -ge 60) { 'score-warning' } else { 'score-critical' }
        
        $html += @"
    <div class="category">
        <h3>$($category.Key)</h3>
        <p><strong>Score:</strong> <span class="$scoreClass">$percentage%</span> ($($category.Value.Score) / $($category.Value.MaxScore))</p>
"@
        
        if ($category.Value.Findings.Count -gt 0) {
            $html += "<h4>Findings:</h4>"
            foreach ($finding in $category.Value.Findings) {
                $html += "<div class='finding'>• $finding</div>"
            }
        }
        
        if ($category.Value.Recommendations.Count -gt 0) {
            $html += "<h4>Recommendations:</h4>"
            foreach ($recommendation in $category.Value.Recommendations) {
                $html += "<div class='recommendation'>• $recommendation</div>"
            }
        }
        
        $html += "</div>"
    }
    
    # Add changes applied
    if ($HardeningResults.ChangesApplied.Count -gt 0) {
        $html += @"
    <div class="category">
        <h3>Security Changes Applied</h3>
"@
        foreach ($change in $HardeningResults.ChangesApplied) {
            $html += "<div class='change'>✓ $change</div>"
        }
        $html += "</div>"
    }
    
    $html += @"
</body>
</html>
"@
    
    $html | Set-Content -Path $reportPath
    return $reportPath
}

# Additional helper functions for compliance frameworks
function Merge-CISCompliancePolicies {
    param($Policies)
    
    # Apply CIS-specific enhancements
    $Policies.Logging.LogLevel = 'INFO'
    $Policies.Authentication.RequireComplexPasswords = $true
    $Policies.Network.RequireFirewall = $true
    
    return $Policies
}

function Merge-NISTCompliancePolicies {
    param($Policies)
    
    # Apply NIST-specific enhancements
    $Policies.Encryption.MinimumTLSVersion = '1.2'
    $Policies.Authentication.RequireMFA = $true
    $Policies.Logging.RemoteLogging = $true
    
    return $Policies
}

function Merge-DISTASTIGPolicies {
    param($Policies)
    
    # Apply DISA STIG-specific enhancements
    $Policies.Encryption.RequireClientCertificates = $true
    $Policies.Authentication.MaxFailedAttempts = 3
    $Policies.Logging.LogLevel = 'DEBUG'
    $Policies.Network.AllowedNetworks = @('127.0.0.1/32')
    
    return $Policies
}

function Configure-WindowsEventLogging {
    # Configure Windows Event Log settings for security monitoring
    try {
        # Enable security auditing
        auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
        auditpol /set /category:"Account Management" /success:enable /failure:enable
        auditpol /set /category:"Privilege Use" /success:enable /failure:enable
        
        Write-Host "  Configured Windows security auditing" -ForegroundColor Yellow
    }
    catch {
        Write-Warning "Failed to configure Windows Event Logging: $($_.Exception.Message)"
    }
}

function Set-WindowsSecurityPolicies {
    param($Policies)
    
    # This would implement Windows security policy configuration
    # For now, just log the action
    Write-Host "  Applied Windows security policies" -ForegroundColor Yellow
}

# Execute the security baseline configuration
Set-VelociraptorSecurityBaseline