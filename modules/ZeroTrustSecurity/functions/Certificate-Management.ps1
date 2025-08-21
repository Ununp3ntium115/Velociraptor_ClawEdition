<#
.SYNOPSIS
    Certificate-Based Authentication Framework for Zero-Trust Architecture

.DESCRIPTION
    This module implements comprehensive certificate-based authentication and PKI
    management for zero-trust architecture in Velociraptor DFIR deployments.
    It provides functions for certificate lifecycle management, mutual TLS authentication,
    and certificate-based access controls while maintaining forensic integrity.

.NOTES
    Author: Velociraptor Community
    Version: 1.0.0
    Requires: PowerShell 5.1+, VelociraptorDeployment module
#>

function New-ZeroTrustCertificate {
    <#
    .SYNOPSIS
        Creates a new certificate for zero-trust authentication.

    .DESCRIPTION
        Generates certificates for zero-trust authentication including client certificates,
        server certificates, and service certificates. Implements PKI best practices
        and forensic-grade certificate management for DFIR operations.

    .PARAMETER CertificateType
        Type of certificate to create (Client, Server, Service, CA, Intermediate).

    .PARAMETER Subject
        Certificate subject distinguished name.

    .PARAMETER KeyUsage
        Key usage purposes for the certificate.

    .PARAMETER ValidityPeriod
        Validity period in days.

    .PARAMETER ForensicGrade
        Create forensic-grade certificate with enhanced security.

    .EXAMPLE
        New-ZeroTrustCertificate -CertificateType Client -Subject "CN=analyst01" -KeyUsage DigitalSignature,KeyEncipherment

    .EXAMPLE
        New-ZeroTrustCertificate -CertificateType Server -Subject "CN=velociraptor.local" -ForensicGrade -ValidityPeriod 365
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Client', 'Server', 'Service', 'CA', 'Intermediate', 'CodeSigning')]
        [string]$CertificateType,
        
        [Parameter(Mandatory)]
        [string]$Subject,
        
        [ValidateSet('DigitalSignature', 'KeyEncipherment', 'DataEncipherment', 'KeyAgreement', 'KeyCertSign', 'CRLSign', 'NonRepudiation')]
        [string[]]$KeyUsage = @('DigitalSignature', 'KeyEncipherment'),
        
        [ValidateRange(1, 3650)]  # 1 day to 10 years
        [int]$ValidityPeriod = 730,  # 2 years default
        
        [ValidateSet(2048, 3072, 4096)]
        [int]$KeySize = 2048,
        
        [ValidateSet('SHA256', 'SHA384', 'SHA512')]
        [string]$HashAlgorithm = 'SHA256',
        
        [string[]]$SubjectAlternativeNames = @(),
        
        [switch]$ForensicGrade,
        
        [string]$CAPath,
        
        [string]$OutputPath,
        
        [switch]$ExportPFX,
        
        [securestring]$PFXPassword,
        
        [switch]$DryRun
    )
    
    begin {
        Write-VelociraptorLog -Message "Creating zero-trust certificate: $CertificateType for $Subject" -Level INFO
        $startTime = Get-Date
        
        # Verify admin privileges for certificate operations
        $adminCheck = Test-VelociraptorAdminPrivileges -TestCertificateAccess
        if (-not $adminCheck.HasRequiredPrivileges) {
            throw "Administrator privileges required for certificate management operations"
        }
    }
    
    process {
        try {
            Write-Host "=== CREATING ZERO-TRUST CERTIFICATE ===" -ForegroundColor Cyan
            Write-Host "Certificate Type: $CertificateType" -ForegroundColor Green
            Write-Host "Subject: $Subject" -ForegroundColor Green
            Write-Host "Key Usage: $($KeyUsage -join ', ')" -ForegroundColor Green
            Write-Host "Validity Period: $ValidityPeriod days" -ForegroundColor Green
            Write-Host "Key Size: $KeySize bits" -ForegroundColor Green
            Write-Host "Hash Algorithm: $HashAlgorithm" -ForegroundColor Green
            Write-Host "Forensic Grade: $ForensicGrade" -ForegroundColor Green
            Write-Host "Dry Run: $DryRun" -ForegroundColor $(if ($DryRun) { 'Yellow' } else { 'Green' })
            Write-Host ""
            
            # Validate certificate configuration
            Write-Host "Validating certificate configuration..." -ForegroundColor Cyan
            $configValidation = Test-CertificateConfiguration -Type $CertificateType -Subject $Subject -KeyUsage $KeyUsage
            if (-not $configValidation.Valid) {
                throw "Certificate configuration validation failed: $($configValidation.Errors -join ', ')"
            }
            
            # Apply forensic-grade settings if requested
            if ($ForensicGrade) {
                Write-Host "Applying forensic-grade security settings..." -ForegroundColor Cyan
                $KeySize = [Math]::Max($KeySize, 3072)  # Minimum 3072-bit keys for forensic grade
                $HashAlgorithm = if ($HashAlgorithm -eq 'SHA256') { 'SHA384' } else { $HashAlgorithm }
                $ValidityPeriod = [Math]::Min($ValidityPeriod, 365)  # Maximum 1 year for forensic grade
            }
            
            # Create certificate configuration
            $certConfig = @{
                Type = $CertificateType
                Subject = $Subject
                KeyUsage = $KeyUsage
                ValidityPeriod = $ValidityPeriod
                KeySize = $KeySize
                HashAlgorithm = $HashAlgorithm
                SubjectAlternativeNames = $SubjectAlternativeNames
                ForensicGrade = $ForensicGrade.IsPresent
                CreatedTime = Get-Date
                SerialNumber = New-CertificateSerialNumber
                Extensions = @()
                AuditTrail = @()
            }
            
            # Configure certificate extensions
            Write-Host "Configuring certificate extensions..." -ForegroundColor Cyan
            $extensions = Get-CertificateExtensions -Type $CertificateType -Config $certConfig
            $certConfig.Extensions = $extensions
            
            # Generate key pair
            Write-Host "Generating cryptographic key pair..." -ForegroundColor Cyan
            $keyPair = New-CryptographicKeyPair -KeySize $KeySize -Algorithm 'RSA'
            
            # Create certificate signing request
            Write-Host "Creating certificate signing request..." -ForegroundColor Cyan
            $csr = New-CertificateSigningRequest -Config $certConfig -KeyPair $keyPair
            
            # Sign certificate
            Write-Host "Signing certificate..." -ForegroundColor Cyan
            if ($CAPath -and (Test-Path $CAPath)) {
                # Sign with external CA
                $certificate = Invoke-CertificateSigning -CSR $csr -CAPath $CAPath
            }
            else {
                # Self-sign or use internal CA
                $certificate = Invoke-SelfSignedCertificate -CSR $csr -Config $certConfig -KeyPair $keyPair
            }
            
            # Apply certificate to configuration
            $certConfig.Certificate = $certificate
            $certConfig.Thumbprint = $certificate.Thumbprint
            $certConfig.PublicKey = $certificate.PublicKey.Key
            $certConfig.NotBefore = $certificate.NotBefore
            $certConfig.NotAfter = $certificate.NotAfter
            
            # Install certificate if not dry run
            if (-not $DryRun) {
                Write-Host "Installing certificate..." -ForegroundColor Cyan
                $installResults = Install-ZeroTrustCertificate -Certificate $certificate -Type $CertificateType
                
                # Export certificate files
                if ($OutputPath) {
                    $exportResults = Export-CertificateFiles -Certificate $certificate -Config $certConfig -OutputPath $OutputPath -ExportPFX:$ExportPFX -PFXPassword $PFXPassword
                }
                
                # Register with certificate store
                $registrationResults = Register-CertificateWithZeroTrust -Config $certConfig
                
                Write-Host "Certificate created and installed successfully!" -ForegroundColor Green
            }
            else {
                Write-Host "Dry run completed - no certificate created" -ForegroundColor Yellow
            }
            
            # Create audit trail entry
            $auditEntry = @{
                Timestamp = Get-Date
                Action = 'CertificateCreated'
                Actor = $env:USERNAME
                Details = @{
                    Type = $CertificateType
                    Subject = $Subject
                    Thumbprint = $certConfig.Thumbprint
                    ValidityPeriod = $ValidityPeriod
                    ForensicGrade = $ForensicGrade.IsPresent
                }
                Source = 'ZeroTrustSecurity'
            }
            $certConfig.AuditTrail += $auditEntry
            
            # Generate certificate summary
            $summary = @{
                CertificateType = $CertificateType
                Subject = $Subject
                Thumbprint = $certConfig.Thumbprint
                ValidFrom = $certConfig.NotBefore
                ValidTo = $certConfig.NotAfter
                KeySize = $KeySize
                HashAlgorithm = $HashAlgorithm
                ForensicGrade = $ForensicGrade.IsPresent
                Configuration = $certConfig
            }
            
            Write-Host ""
            Write-Host "Certificate Summary:" -ForegroundColor Cyan
            Write-Host "  Thumbprint: $($summary.Thumbprint)" -ForegroundColor Green
            Write-Host "  Valid From: $($summary.ValidFrom)" -ForegroundColor Green
            Write-Host "  Valid To: $($summary.ValidTo)" -ForegroundColor Green
            Write-Host "  Key Size: $($summary.KeySize) bits" -ForegroundColor Green
            
            return $summary
        }
        catch {
            Write-Host "Failed to create certificate: $($_.Exception.Message)" -ForegroundColor Red
            Write-VelociraptorLog -Message "Certificate creation error: $($_.Exception.Message)" -Level ERROR
            throw
        }
    }
    
    end {
        $duration = (Get-Date) - $startTime
        Write-VelociraptorLog -Message "Certificate creation completed in $($duration.TotalSeconds) seconds" -Level INFO
    }
}

function Set-CertificateBasedAuth {
    <#
    .SYNOPSIS
        Configures certificate-based authentication for zero-trust access.

    .DESCRIPTION
        Sets up certificate-based authentication including mutual TLS (mTLS),
        client certificate authentication, and certificate validation policies.
        Implements enterprise PKI integration for DFIR operations.

    .PARAMETER ServiceName
        Name of the service to configure certificate authentication for.

    .PARAMETER CertificateThumbprint
        Thumbprint of the certificate to use for authentication.

    .PARAMETER RequireClientCertificate
        Require client certificates for all connections.

    .PARAMETER ValidateChain
        Validate complete certificate chain.

    .PARAMETER ForensicValidation
        Enable forensic-grade certificate validation.

    .EXAMPLE
        Set-CertificateBasedAuth -ServiceName "VelociraptorServer" -CertificateThumbprint $thumbprint -RequireClientCertificate

    .EXAMPLE
        Set-CertificateBasedAuth -ServiceName "VelociraptorGUI" -ForensicValidation -ValidateChain
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,
        
        [string]$CertificateThumbprint,
        
        [switch]$RequireClientCertificate,
        
        [switch]$ValidateChain,
        
        [switch]$ForensicValidation,
        
        [string[]]$TrustedIssuers = @(),
        
        [ValidateSet('None', 'Optional', 'Required')]
        [string]$ClientCertificateMode = 'Required',
        
        [string]$CRLLocation,
        
        [switch]$EnableOCSP,
        
        [switch]$DryRun
    )
    
    begin {
        Write-VelociraptorLog -Message "Configuring certificate-based authentication for: $ServiceName" -Level INFO
    }
    
    process {
        try {
            Write-Host "=== CONFIGURING CERTIFICATE-BASED AUTHENTICATION ===" -ForegroundColor Cyan
            Write-Host "Service: $ServiceName" -ForegroundColor Green
            Write-Host "Certificate: $CertificateThumbprint" -ForegroundColor Green
            Write-Host "Client Certificate Mode: $ClientCertificateMode" -ForegroundColor Green
            Write-Host "Validate Chain: $ValidateChain" -ForegroundColor Green
            Write-Host "Forensic Validation: $ForensicValidation" -ForegroundColor Green
            Write-Host ""
            
            # Validate certificate if provided
            if ($CertificateThumbprint) {
                Write-Host "Validating server certificate..." -ForegroundColor Cyan
                $certValidation = Test-CertificateValidity -Thumbprint $CertificateThumbprint
                if (-not $certValidation.Valid) {
                    throw "Certificate validation failed: $($certValidation.Issues -join ', ')"
                }
            }
            
            # Create certificate authentication configuration
            $authConfig = @{
                ServiceName = $ServiceName
                CertificateThumbprint = $CertificateThumbprint
                ClientCertificateMode = $ClientCertificateMode
                RequireClientCertificate = $RequireClientCertificate.IsPresent
                ValidateChain = $ValidateChain.IsPresent
                ForensicValidation = $ForensicValidation.IsPresent
                TrustedIssuers = $TrustedIssuers
                CRLLocation = $CRLLocation
                EnableOCSP = $EnableOCSP.IsPresent
                CreatedTime = Get-Date
                ValidationPolicies = @()
                AuditTrail = @()
            }
            
            # Configure validation policies
            Write-Host "Configuring certificate validation policies..." -ForegroundColor Cyan
            $validationPolicies = Get-CertificateValidationPolicies -Config $authConfig -ForensicGrade:$ForensicValidation
            $authConfig.ValidationPolicies = $validationPolicies
            
            # Configure mutual TLS if client certificates required
            if ($RequireClientCertificate) {
                Write-Host "Configuring mutual TLS (mTLS)..." -ForegroundColor Cyan
                $mtlsConfig = Configure-MutualTLS -Service $ServiceName -Config $authConfig
                $authConfig.MutualTLSConfig = $mtlsConfig
            }
            
            # Set up certificate revocation checking
            Write-Host "Configuring certificate revocation checking..." -ForegroundColor Cyan
            $revocationConfig = Configure-CertificateRevocationChecking -Config $authConfig
            $authConfig.RevocationConfig = $revocationConfig
            
            # Configure forensic validation if enabled
            if ($ForensicValidation) {
                Write-Host "Configuring forensic-grade validation..." -ForegroundColor Cyan
                $forensicConfig = Configure-ForensicCertificateValidation -Config $authConfig
                $authConfig.ForensicConfig = $forensicConfig
            }
            
            # Apply configuration to service
            if (-not $DryRun) {
                Write-Host "Applying certificate authentication configuration..." -ForegroundColor Cyan
                
                # Update service configuration
                $serviceResults = Update-ServiceCertificateConfig -Service $ServiceName -Config $authConfig
                
                # Configure TLS settings
                $tlsResults = Configure-ServiceTLSSettings -Service $ServiceName -Config $authConfig
                
                # Set up certificate monitoring
                $monitoringResults = Start-CertificateMonitoring -Config $authConfig
                
                Write-Host "Certificate-based authentication configured successfully!" -ForegroundColor Green
            }
            else {
                Write-Host "Dry run completed - no changes applied" -ForegroundColor Yellow
            }
            
            # Create audit trail entry
            $auditEntry = @{
                Timestamp = Get-Date
                Action = 'CertificateAuthConfigured'
                Actor = $env:USERNAME
                Details = @{
                    ServiceName = $ServiceName
                    CertificateThumbprint = $CertificateThumbprint
                    ClientCertificateMode = $ClientCertificateMode
                    ForensicValidation = $ForensicValidation.IsPresent
                }
                Source = 'ZeroTrustSecurity'
            }
            $authConfig.AuditTrail += $auditEntry
            
            return @{
                ServiceName = $ServiceName
                CertificateThumbprint = $CertificateThumbprint
                ClientCertificateMode = $ClientCertificateMode
                ValidationPoliciesCount = $validationPolicies.Count
                ForensicValidation = $ForensicValidation.IsPresent
                Configuration = $authConfig
            }
        }
        catch {
            Write-Host "Failed to configure certificate-based authentication: $($_.Exception.Message)" -ForegroundColor Red
            Write-VelociraptorLog -Message "Certificate authentication configuration error: $($_.Exception.Message)" -Level ERROR
            throw
        }
    }
}

function Test-CertificateChain {
    <#
    .SYNOPSIS
        Tests certificate chain validity and trust relationships.

    .DESCRIPTION
        Performs comprehensive certificate chain validation including trust path
        verification, revocation checking, and forensic-grade validation.
        Ensures certificate integrity for zero-trust operations.

    .PARAMETER CertificateThumbprint
        Thumbprint of the certificate to test.

    .PARAMETER ValidationType
        Type of validation to perform (Basic, Extended, Forensic).

    .PARAMETER CheckRevocation
        Check certificate revocation status.

    .PARAMETER GenerateReport
        Generate detailed validation report.

    .EXAMPLE
        Test-CertificateChain -CertificateThumbprint $thumbprint -ValidationType Forensic -CheckRevocation

    .EXAMPLE
        Test-CertificateChain -CertificateThumbprint $thumbprint -GenerateReport
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CertificateThumbprint,
        
        [ValidateSet('Basic', 'Extended', 'Forensic')]
        [string]$ValidationType = 'Extended',
        
        [switch]$CheckRevocation,
        
        [switch]$ValidatePurpose,
        
        [string]$ExpectedPurpose,
        
        [switch]$GenerateReport,
        
        [string]$ReportPath
    )
    
    begin {
        Write-VelociraptorLog -Message "Testing certificate chain for: $CertificateThumbprint" -Level INFO
        $startTime = Get-Date
    }
    
    process {
        try {
            Write-Host "=== CERTIFICATE CHAIN VALIDATION ===" -ForegroundColor Cyan
            Write-Host "Certificate: $CertificateThumbprint" -ForegroundColor Green
            Write-Host "Validation Type: $ValidationType" -ForegroundColor Green
            Write-Host "Check Revocation: $CheckRevocation" -ForegroundColor Green
            Write-Host ""
            
            # Find the certificate
            $certificate = Get-ChildItem -Path Cert:\ -Recurse | Where-Object { $_.Thumbprint -eq $CertificateThumbprint }
            if (-not $certificate) {
                throw "Certificate with thumbprint '$CertificateThumbprint' not found"
            }
            
            # Initialize validation results
            $validationResults = @{
                CertificateThumbprint = $CertificateThumbprint
                Subject = $certificate.Subject
                Issuer = $certificate.Issuer
                ValidationType = $ValidationType
                Timestamp = Get-Date
                OverallStatus = 'Unknown'
                ChainStatus = 'Unknown'
                ValidationTests = @{}
                Issues = @()
                Warnings = @()
                ChainDetails = @()
                ForensicIntegrity = $true
            }
            
            # Build certificate chain
            Write-Host "Building certificate chain..." -ForegroundColor Cyan
            $chainResults = Build-CertificateChain -Certificate $certificate
            $validationResults.ChainDetails = $chainResults.Chain
            $validationResults.ChainStatus = $chainResults.Status
            
            # Perform basic validation
            Write-Host "Performing basic certificate validation..." -ForegroundColor Cyan
            $basicValidation = Test-BasicCertificateValidation -Certificate $certificate
            $validationResults.ValidationTests['Basic'] = $basicValidation
            
            # Perform extended validation
            if ($ValidationType -in @('Extended', 'Forensic')) {
                Write-Host "Performing extended certificate validation..." -ForegroundColor Cyan
                $extendedValidation = Test-ExtendedCertificateValidation -Certificate $certificate -Chain $chainResults.Chain
                $validationResults.ValidationTests['Extended'] = $extendedValidation
            }
            
            # Perform forensic validation
            if ($ValidationType -eq 'Forensic') {
                Write-Host "Performing forensic certificate validation..." -ForegroundColor Cyan
                $forensicValidation = Test-ForensicCertificateValidation -Certificate $certificate -Chain $chainResults.Chain
                $validationResults.ValidationTests['Forensic'] = $forensicValidation
                $validationResults.ForensicIntegrity = $forensicValidation.IntegrityMaintained
            }
            
            # Check certificate revocation
            if ($CheckRevocation) {
                Write-Host "Checking certificate revocation status..." -ForegroundColor Cyan
                $revocationResults = Test-CertificateRevocation -Certificate $certificate -Chain $chainResults.Chain
                $validationResults.ValidationTests['Revocation'] = $revocationResults
            }
            
            # Validate certificate purpose
            if ($ValidatePurpose -and $ExpectedPurpose) {
                Write-Host "Validating certificate purpose..." -ForegroundColor Cyan
                $purposeValidation = Test-CertificatePurpose -Certificate $certificate -ExpectedPurpose $ExpectedPurpose
                $validationResults.ValidationTests['Purpose'] = $purposeValidation
            }
            
            # Calculate overall status
            $overallStatus = Calculate-OverallCertificateStatus -ValidationResults $validationResults
            $validationResults.OverallStatus = $overallStatus
            
            # Collect issues and warnings
            foreach ($test in $validationResults.ValidationTests.Values) {
                $validationResults.Issues += $test.Issues
                $validationResults.Warnings += $test.Warnings
            }
            
            # Display validation summary
            Show-CertificateValidationSummary -Results $validationResults
            
            # Generate report if requested
            if ($GenerateReport) {
                $reportFile = Generate-CertificateValidationReport -Results $validationResults -ReportPath $ReportPath
                Write-Host "Validation report generated: $reportFile" -ForegroundColor Green
            }
            
            return $validationResults
        }
        catch {
            Write-Host "Certificate chain validation failed: $($_.Exception.Message)" -ForegroundColor Red
            Write-VelociraptorLog -Message "Certificate chain validation error: $($_.Exception.Message)" -Level ERROR
            throw
        }
    }
    
    end {
        $duration = (Get-Date) - $startTime
        Write-VelociraptorLog -Message "Certificate chain validation completed in $($duration.TotalSeconds) seconds" -Level INFO
    }
}

function Revoke-ZeroTrustCertificate {
    <#
    .SYNOPSIS
        Revokes a zero-trust certificate and updates revocation lists.

    .DESCRIPTION
        Revokes a certificate for security or operational reasons and updates
        all relevant revocation lists and OCSP responders. Maintains forensic
        audit trail for certificate lifecycle management.

    .PARAMETER CertificateThumbprint
        Thumbprint of the certificate to revoke.

    .PARAMETER RevocationReason
        Reason for certificate revocation.

    .PARAMETER EffectiveDate
        Effective date of revocation (defaults to current time).

    .PARAMETER UpdateCRL
        Update Certificate Revocation List.

    .PARAMETER NotifyServices
        Notify dependent services of revocation.

    .EXAMPLE
        Revoke-ZeroTrustCertificate -CertificateThumbprint $thumbprint -RevocationReason KeyCompromise -UpdateCRL

    .EXAMPLE
        Revoke-ZeroTrustCertificate -CertificateThumbprint $thumbprint -RevocationReason Superseded -NotifyServices
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$CertificateThumbprint,
        
        [Parameter(Mandatory)]
        [ValidateSet('Unspecified', 'KeyCompromise', 'CaCompromise', 'AffiliationChanged', 'Superseded', 'CessationOfOperation', 'CertificateHold', 'RemoveFromCRL')]
        [string]$RevocationReason,
        
        [DateTime]$EffectiveDate = (Get-Date),
        
        [switch]$UpdateCRL,
        
        [switch]$NotifyServices,
        
        [string]$Justification,
        
        [switch]$Force
    )
    
    begin {
        Write-VelociraptorLog -Message "Revoking certificate: $CertificateThumbprint" -Level WARNING
    }
    
    process {
        try {
            # Find the certificate
            $certificate = Get-ChildItem -Path Cert:\ -Recurse | Where-Object { $_.Thumbprint -eq $CertificateThumbprint }
            if (-not $certificate) {
                throw "Certificate with thumbprint '$CertificateThumbprint' not found"
            }
            
            Write-Host "=== CERTIFICATE REVOCATION ===" -ForegroundColor Yellow
            Write-Host "Certificate: $CertificateThumbprint" -ForegroundColor Green
            Write-Host "Subject: $($certificate.Subject)" -ForegroundColor Green
            Write-Host "Revocation Reason: $RevocationReason" -ForegroundColor Yellow
            Write-Host "Effective Date: $EffectiveDate" -ForegroundColor Yellow
            Write-Host ""
            
            # Confirmation prompt
            if (-not $Force -and $PSCmdlet.ShouldProcess($certificate.Subject, "Revoke Certificate")) {
                $confirmation = Read-Host "Are you sure you want to revoke this certificate? This action cannot be undone. (y/N)"
                if ($confirmation -notin @('y', 'yes', 'Y', 'YES')) {
                    Write-Host "Certificate revocation cancelled by user" -ForegroundColor Yellow
                    return
                }
            }
            
            # Create revocation record
            $revocationRecord = @{
                CertificateThumbprint = $CertificateThumbprint
                Subject = $certificate.Subject
                Issuer = $certificate.Issuer
                SerialNumber = $certificate.SerialNumber
                RevocationReason = $RevocationReason
                EffectiveDate = $EffectiveDate
                RevokedBy = $env:USERNAME
                Justification = $Justification
                Timestamp = Get-Date
                Source = 'ZeroTrustSecurity'
            }
            
            # Add to certificate revocation list
            Write-Host "Adding certificate to revocation list..." -ForegroundColor Cyan
            $crlResults = Add-CertificateToRevocationList -RevocationRecord $revocationRecord
            
            # Update CRL if requested
            if ($UpdateCRL) {
                Write-Host "Updating Certificate Revocation List..." -ForegroundColor Cyan
                $crlUpdateResults = Update-CertificateRevocationList -RevocationRecord $revocationRecord
            }
            
            # Update OCSP responder
            Write-Host "Updating OCSP responder..." -ForegroundColor Cyan
            $ocspResults = Update-OCSPResponder -RevocationRecord $revocationRecord
            
            # Notify dependent services
            if ($NotifyServices) {
                Write-Host "Notifying dependent services..." -ForegroundColor Cyan
                $notificationResults = Send-CertificateRevocationNotifications -RevocationRecord $revocationRecord
            }
            
            # Remove certificate from trusted stores
            Write-Host "Removing certificate from trusted stores..." -ForegroundColor Cyan
            $removalResults = Remove-CertificateFromTrustedStores -CertificateThumbprint $CertificateThumbprint
            
            # Create forensic audit entry
            $auditEntry = @{
                Timestamp = Get-Date
                Action = 'CertificateRevoked'
                Actor = $env:USERNAME
                Details = $revocationRecord
                Source = 'ZeroTrustSecurity'
                Severity = 'HIGH'
            }
            
            # Log to forensic audit trail
            Write-VelociraptorLog -Message "Certificate revoked: $CertificateThumbprint - Reason: $RevocationReason" -Level WARNING
            Add-ForensicAuditEntry -Entry $auditEntry
            
            Write-Host ""
            Write-Host "Certificate revoked successfully!" -ForegroundColor Green
            Write-Host "Revocation effective: $EffectiveDate" -ForegroundColor Green
            Write-Host "Reason: $RevocationReason" -ForegroundColor Yellow
            
            return @{
                CertificateThumbprint = $CertificateThumbprint
                RevocationReason = $RevocationReason
                EffectiveDate = $EffectiveDate
                CRLUpdated = $UpdateCRL.IsPresent
                ServicesNotified = $NotifyServices.IsPresent
                RevocationRecord = $revocationRecord
            }
        }
        catch {
            Write-Host "Failed to revoke certificate: $($_.Exception.Message)" -ForegroundColor Red
            Write-VelociraptorLog -Message "Certificate revocation error: $($_.Exception.Message)" -Level ERROR
            throw
        }
    }
}

# Helper functions for certificate management

function New-CertificateSerialNumber {
    # Generate cryptographically secure serial number
    $bytes = New-Object byte[] 16
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    $rng.GetBytes($bytes)
    return [System.BitConverter]::ToString($bytes) -replace '-', ''
}

function Get-CertificateExtensions {
    param($Type, $Config)
    
    $extensions = @()
    
    switch ($Type) {
        'Client' {
            $extensions += @{
                OID = '2.5.29.37'  # Extended Key Usage
                Value = 'ClientAuthentication'
                Critical = $true
            }
            $extensions += @{
                OID = '2.5.29.15'  # Key Usage
                Value = 'DigitalSignature,KeyEncipherment'
                Critical = $true
            }
        }
        'Server' {
            $extensions += @{
                OID = '2.5.29.37'  # Extended Key Usage
                Value = 'ServerAuthentication'
                Critical = $true
            }
            $extensions += @{
                OID = '2.5.29.15'  # Key Usage
                Value = 'DigitalSignature,KeyEncipherment'
                Critical = $true
            }
        }
        'CA' {
            $extensions += @{
                OID = '2.5.29.19'  # Basic Constraints
                Value = 'CA:TRUE'
                Critical = $true
            }
            $extensions += @{
                OID = '2.5.29.15'  # Key Usage
                Value = 'KeyCertSign,CRLSign'
                Critical = $true
            }
        }
    }
    
    # Add forensic extension if forensic grade
    if ($Config.ForensicGrade) {
        $extensions += @{
            OID = '1.3.6.1.4.1.311.21.7'  # Certificate Template (Microsoft specific)
            Value = 'ForensicGrade'
            Critical = $false
        }
    }
    
    return $extensions
}

function Test-CertificateConfiguration {
    param($Type, $Subject, $KeyUsage)
    
    $validation = @{
        Valid = $true
        Errors = @()
        Warnings = @()
    }
    
    # Validate subject format
    if (-not $Subject.StartsWith('CN=')) {
        $validation.Valid = $false
        $validation.Errors += "Subject must start with 'CN='"
    }
    
    # Validate key usage for certificate type
    switch ($Type) {
        'Client' {
            if ('DigitalSignature' -notin $KeyUsage) {
                $validation.Valid = $false
                $validation.Errors += "Client certificates must include DigitalSignature key usage"
            }
        }
        'Server' {
            if ('KeyEncipherment' -notin $KeyUsage) {
                $validation.Valid = $false
                $validation.Errors += "Server certificates must include KeyEncipherment key usage"
            }
        }
        'CA' {
            if ('KeyCertSign' -notin $KeyUsage) {
                $validation.Valid = $false
                $validation.Errors += "CA certificates must include KeyCertSign key usage"
            }
        }
    }
    
    return $validation
}

function Show-CertificateValidationSummary {
    param($Results)
    
    Write-Host "=== CERTIFICATE VALIDATION SUMMARY ===" -ForegroundColor Cyan
    Write-Host "Certificate: $($Results.CertificateThumbprint)" -ForegroundColor Green
    Write-Host "Subject: $($Results.Subject)" -ForegroundColor Green
    Write-Host "Overall Status: $($Results.OverallStatus)" -ForegroundColor $(
        switch ($Results.OverallStatus) {
            'Valid' { 'Green' }
            'Warning' { 'Yellow' }
            'Invalid' { 'Red' }
            default { 'White' }
        }
    )
    Write-Host "Chain Status: $($Results.ChainStatus)" -ForegroundColor $(
        switch ($Results.ChainStatus) {
            'Valid' { 'Green' }
            'Warning' { 'Yellow' }
            'Invalid' { 'Red' }
            default { 'White' }
        }
    )
    Write-Host ""
    
    foreach ($test in $Results.ValidationTests.GetEnumerator()) {
        $status = $test.Value.Status
        $statusColor = switch ($status) {
            'Pass' { 'Green' }
            'Warning' { 'Yellow' }
            'Fail' { 'Red' }
            default { 'White' }
        }
        Write-Host "$($test.Key): $status" -ForegroundColor $statusColor
    }
    
    if ($Results.Issues.Count -gt 0) {
        Write-Host ""
        Write-Host "Issues Found: $($Results.Issues.Count)" -ForegroundColor Red
        foreach ($issue in $Results.Issues | Select-Object -First 5) {
            Write-Host "  - $issue" -ForegroundColor Red
        }
    }
    
    if ($Results.Warnings.Count -gt 0) {
        Write-Host ""
        Write-Host "Warnings: $($Results.Warnings.Count)" -ForegroundColor Yellow
    }
    
    Write-Host ""
}