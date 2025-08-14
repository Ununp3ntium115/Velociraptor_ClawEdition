function Set-VelociraptorSecurityHardening {
    <#
    .SYNOPSIS
        Applies security hardening to Velociraptor configuration files.

    .DESCRIPTION
        Implements security best practices and hardening measures for Velociraptor
        configurations including secure defaults, access controls, and compliance settings.

    .PARAMETER ConfigPath
        Path to the Velociraptor configuration file to harden.

    .PARAMETER HardeningLevel
        Security hardening level: Basic, Standard, or Maximum. Default is Standard.

    .PARAMETER BackupOriginal
        Create backup of original configuration before applying changes.

    .PARAMETER CustomRules
        Array of custom hardening rules to apply.

    .PARAMETER Force
        Apply hardening without confirmation prompts.

    .EXAMPLE
        Set-VelociraptorSecurityHardening -ConfigPath "C:\tools\server.yaml"

    .EXAMPLE
        Set-VelociraptorSecurityHardening -ConfigPath "server.yaml" -HardeningLevel Maximum -BackupOriginal

    .OUTPUTS
        PSCustomObject with hardening results including applied changes and recommendations.

    .NOTES
        Review hardening changes carefully before deploying to production environments.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$ConfigPath,

        [Parameter()]
        [ValidateSet('Basic', 'Standard', 'Maximum')]
        [string]$HardeningLevel = 'Standard',

        [Parameter()]
        [switch]$BackupOriginal = $true,

        [Parameter()]
        [string[]]$CustomRules = @(),

        [Parameter()]
        [switch]$Force
    )

    try {
        Write-VelociraptorLog "Applying $HardeningLevel security hardening to: $ConfigPath" -Level Info

        # Create backup if requested
        $backupPath = $null
        if ($BackupOriginal) {
            $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
            $backupPath = "$ConfigPath.pre-hardening.$timestamp"
            Copy-Item $ConfigPath $backupPath -Force -ErrorAction SilentlyContinue
            Write-VelociraptorLog "Original configuration backed up to: $backupPath" -Level Info
        }

        # Read current configuration
        $configContent = Get-Content $ConfigPath -Raw
        $originalContent = $configContent

        # Initialize result tracking
        $appliedChanges = @()
        $recommendations = @()
        $warnings = @()

        # Apply basic hardening rules (always applied)
        $basicRules = @{
            # Enable detailed logging
            'separate_logs_per_component:\s*false' = 'separate_logs_per_component: true  # Hardened: Enable detailed logging'

            # Set reasonable timeouts
            'notebook_cell_timeout:\s*0' = 'notebook_cell_timeout: 300  # Hardened: 5 minute timeout'

            # Enable log rotation
            'max_log_size:\s*0' = 'max_log_size: 104857600  # Hardened: 100MB log rotation'
        }

        foreach ($pattern in $basicRules.Keys) {
            if ($configContent -match $pattern) {
                $configContent = $configContent -replace $pattern, $basicRules[$pattern]
                $appliedChanges += "Applied basic rule: $pattern"
            }
        }

        # Apply standard hardening rules
        if ($HardeningLevel -in 'Standard', 'Maximum') {
            $standardRules = @{
                # Restrict bind addresses where appropriate
                'bind_address:\s*0\.0\.0\.0' = 'bind_address: 127.0.0.1  # Hardened: Localhost only (review for multi-host deployments)'

                # Set upload limits
                'max_upload_size:\s*0' = 'max_upload_size: 104857600  # Hardened: 100MB upload limit'

                # Set memory limits
                'max_memory:\s*0' = 'max_memory: 1073741824  # Hardened: 1GB memory limit'

                # Enable audit logging
                'audit_log:\s*false' = 'audit_log: true  # Hardened: Enable audit logging'
            }

            foreach ($pattern in $standardRules.Keys) {
                if ($configContent -match $pattern) {
                    $configContent = $configContent -replace $pattern, $standardRules[$pattern]
                    $appliedChanges += "Applied standard rule: $pattern"
                }
            }

            # Add security headers if GUI section exists
            if ($configContent -match 'GUI:' -and -not ($configContent -match 'security_headers:')) {
                $securityHeaders = @"

  # Security hardening headers
  security_headers:
    X-Frame-Options: DENY
    X-Content-Type-Options: nosniff
    X-XSS-Protection: "1; mode=block"
    Strict-Transport-Security: "max-age=31536000; includeSubDomains"
    Content-Security-Policy: "default-src 'self'"
    Referrer-Policy: "strict-origin-when-cross-origin"
"@
                $configContent = $configContent -replace '(GUI:.*?)((?=\n[A-Z])|$)', "`$1$securityHeaders`$2"
                $appliedChanges += "Added security headers to GUI configuration"
            }
        }

        # Apply maximum hardening rules
        if ($HardeningLevel -eq 'Maximum') {
            $maximumRules = @{
                # Enforce minimum TLS version
                'min_tls_version:\s*"?TLS1[.0-1]"?' = 'min_tls_version: "TLS1.2"  # Hardened: TLS 1.2+ only'

                # Strict CORS policy
                'cors_allowed_origins:\s*\[.*\]' = 'cors_allowed_origins: []  # Hardened: Strict CORS policy'

                # Disable unnecessary features
                'enable_debug:\s*true' = 'enable_debug: false  # Hardened: Disable debug mode'

                # Set session timeouts
                'session_timeout:\s*0' = 'session_timeout: 3600  # Hardened: 1 hour session timeout'
            }

            foreach ($pattern in $maximumRules.Keys) {
                if ($configContent -match $pattern) {
                    $configContent = $configContent -replace $pattern, $maximumRules[$pattern]
                    $appliedChanges += "Applied maximum rule: $pattern"
                }
            }

            # Add rate limiting if not present
            if (-not ($configContent -match 'rate_limiting:')) {
                $rateLimiting = @"

# Rate limiting configuration (Security Hardening)
rate_limiting:
  enabled: true
  login_attempts: 5
  login_lockout_time: 300
  api_request_limit: 100
  api_request_period: 60
"@
                $configContent += $rateLimiting
                $appliedChanges += "Added rate limiting configuration"
            }

            # Add additional security settings
            if (-not ($configContent -match 'security_settings:')) {
                $securitySettings = @"

# Additional security settings (Maximum Hardening)
security_settings:
  disable_server_info: true
  hide_version_info: true
  require_strong_passwords: true
  password_complexity:
    min_length: 12
    require_uppercase: true
    require_lowercase: true
    require_numbers: true
    require_symbols: true
"@
                $configContent += $securitySettings
                $appliedChanges += "Added additional security settings"
            }
        }

        # Apply custom rules if provided
        foreach ($customRule in $CustomRules) {
            try {
                # Custom rules should be in format "pattern|replacement"
                $parts = $customRule -split '\|', 2
                if ($parts.Length -eq 2) {
                    $pattern = $parts[0]
                    $replacement = $parts[1]

                    if ($configContent -match $pattern) {
                        $configContent = $configContent -replace $pattern, $replacement
                        $appliedChanges += "Applied custom rule: $pattern"
                    }
                }
            }
            catch {
                $warnings += "Failed to apply custom rule: $customRule"
            }
        }

        # Generate security recommendations
        if ($configContent -match 'password.*admin|password.*password') {
            $recommendations += "Change default passwords immediately"
        }

        if ($configContent -match 'certificate:\s*""') {
            $recommendations += "Configure proper SSL/TLS certificates"
        }

        if ($configContent -match 'bind_address:\s*0\.0\.0\.0') {
            $recommendations += "Review network binding - consider restricting to specific interfaces"
        }

        # Confirm changes if not forced
        if (-not $Force -and $appliedChanges.Count -gt 0) {
            Write-VelociraptorLog "The following changes will be applied:" -Level Info
            $appliedChanges | ForEach-Object { Write-VelociraptorLog "  - $_" -Level Info }

            $confirm = Read-VelociraptorUserInput -Prompt "Apply these changes?" -DefaultValue "Y" -ValidValues @("Y", "N")
            if ($confirm -eq "N") {
                throw "Hardening cancelled by user"
            }
        }

        # Write hardened configuration
        if ($appliedChanges.Count -gt 0) {
            $configContent | Out-File $ConfigPath -Encoding UTF8
            Write-VelociraptorLog "Security hardening applied successfully" -Level Success
        } else {
            Write-VelociraptorLog "No hardening changes were needed" -Level Info
        }

        # Validate hardened configuration
        $validation = Test-VelociraptorConfiguration -ConfigPath $ConfigPath -ValidationLevel Standard -OutputFormat Object

        # Create result object
        $result = [PSCustomObject]@{
            Success = $true
            ConfigPath = $ConfigPath
            HardeningLevel = $HardeningLevel
            BackupPath = $backupPath
            AppliedChanges = $appliedChanges
            ChangeCount = $appliedChanges.Count
            Recommendations = $recommendations
            Warnings = $warnings
            ValidationResult = $validation
            HardeningDate = Get-Date
        }

        # Display summary
        Write-VelociraptorLog "Hardening Summary:" -Level Info
        Write-VelociraptorLog "  Changes applied: $($result.ChangeCount)" -Level Info
        Write-VelociraptorLog "  Recommendations: $($recommendations.Count)" -Level Info
        Write-VelociraptorLog "  Configuration valid: $($validation.IsValid)" -Level Info

        if ($recommendations.Count -gt 0) {
            Write-VelociraptorLog "Security Recommendations:" -Level Warning
            $recommendations | ForEach-Object { Write-VelociraptorLog "  - $_" -Level Warning }
        }

        return $result
    }
    catch {
        $errorMessage = "Security hardening failed: $($_.Exception.Message)"
        Write-VelociraptorLog $errorMessage -Level Error

        # Restore original if backup exists and changes were made
        if ($backupPath -and (Test-Path $backupPath) -and $appliedChanges.Count -gt 0) {
            try {
                Copy-Item $backupPath $ConfigPath -Force -ErrorAction SilentlyContinue
                Write-VelociraptorLog "Original configuration restored from backup" -Level Info
            }
            catch {
                Write-VelociraptorLog "Warning: Could not restore original configuration" -Level Warning
            }
        }

        return [PSCustomObject]@{
            Success = $false
            ConfigPath = $ConfigPath
            HardeningLevel = $HardeningLevel
            Error = $_.Exception.Message
            HardeningDate = Get-Date
        }
    }
}