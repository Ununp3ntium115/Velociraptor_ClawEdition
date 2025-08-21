function Test-VelociraptorConfiguration {
    <#
    .SYNOPSIS
        Validates Velociraptor configuration files for syntax and security issues.

    .DESCRIPTION
        Performs comprehensive validation of Velociraptor YAML configuration files,
        checking for syntax errors, security issues, and best practice compliance.

    .PARAMETER ConfigPath
        Path to the Velociraptor configuration file to validate.

    .PARAMETER ValidationLevel
        Validation level: Basic, Standard, or Comprehensive. Default is Standard.

    .PARAMETER IgnoreWarnings
        Skip warning-level issues and only report errors.

    .PARAMETER OutputFormat
        Output format: Object, JSON, or Summary. Default is Object.

    .EXAMPLE
        Test-VelociraptorConfiguration -ConfigPath "C:\tools\server.yaml"

    .EXAMPLE
        Test-VelociraptorConfiguration -ConfigPath "server.yaml" -ValidationLevel Comprehensive

    .OUTPUTS
        PSCustomObject with validation results including issues, warnings, and recommendations.

    .NOTES
        Requires the configuration file to be accessible and readable.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$ConfigPath,
        
        [Parameter()]
        [ValidateSet('Basic', 'Standard', 'Comprehensive')]
        [string]$ValidationLevel = 'Standard',
        
        [Parameter()]
        [switch]$IgnoreWarnings,
        
        [Parameter()]
        [ValidateSet('Object', 'JSON', 'Summary')]
        [string]$OutputFormat = 'Object'
    )
    
    try {
        Write-VelociraptorLog "Validating configuration: $ConfigPath (Level: $ValidationLevel)" -Level Info
        
        # Initialize result object
        $result = [PSCustomObject]@{
            ConfigPath = $ConfigPath
            ValidationLevel = $ValidationLevel
            IsValid = $false
            Issues = @()
            Warnings = @()
            SecurityIssues = @()
            Recommendations = @()
            ConfigInfo = @{}
            ValidationDate = Get-Date
        }
        
        # Check if file exists and is readable
        if (-not (Test-Path $ConfigPath)) {
            throw "Configuration file not found: $ConfigPath"
        }
        
        # Read configuration content
        $configContent = Get-Content $ConfigPath -Raw -ErrorAction Stop
        
        if ([string]::IsNullOrWhiteSpace($configContent)) {
            $result.Issues += "Configuration file is empty"
            return $result
        }
        
        # Basic YAML structure validation
        if (-not ($configContent -match 'version:')) {
            $result.Issues += "Missing version specification"
        }
        
        # Extract basic configuration information
        if ($configContent -match 'version:\s*\n\s*name:\s*(.+)\n\s*version:\s*"?([^"\n]+)') {
            $result.ConfigInfo.Name = $Matches[1].Trim()
            $result.ConfigInfo.Version = $Matches[2].Trim()
        }
        
        # Check required sections
        $requiredSections = @('Frontend:', 'GUI:', 'Client:', 'Datastore:')
        foreach ($section in $requiredSections) {
            if (-not ($configContent -match $section)) {
                $result.Issues += "Missing required section: $section"
            }
        }
        
        # Port validation
        $portPattern = 'bind_port:\s*(\d+)'
        $ports = [regex]::Matches($configContent, $portPattern) | ForEach-Object { [int]$_.Groups[1].Value }
        
        if ($ports) {
            $result.ConfigInfo.Ports = $ports
            
            # Check for duplicate ports
            $duplicatePorts = $ports | Group-Object | Where-Object { $_.Count -gt 1 }
            if ($duplicatePorts) {
                $result.Issues += "Duplicate ports found: $($duplicatePorts.Name -join ', ')"
            }
            
            # Check for privileged ports
            $privilegedPorts = $ports | Where-Object { $_ -lt 1024 }
            if ($privilegedPorts) {
                $result.Warnings += "Using privileged ports (below 1024): $($privilegedPorts -join ', ')"
            }
        }
        
        # Security validation
        Test-SecuritySettings $configContent $result $ValidationLevel
        
        # Standard validation checks
        if ($ValidationLevel -in 'Standard', 'Comprehensive') {
            Test-StandardSettings $configContent $result
        }
        
        # Comprehensive validation checks
        if ($ValidationLevel -eq 'Comprehensive') {
            Test-ComprehensiveSettings $configContent $result
        }
        
        # Determine overall validity
        $result.IsValid = $result.Issues.Count -eq 0
        
        # Log results
        if ($result.IsValid) {
            $message = "Configuration validation passed"
            if ($result.SecurityIssues.Count -gt 0) {
                $message += " (with security concerns)"
                Write-VelociraptorLog $message -Level Warning
            } else {
                Write-VelociraptorLog $message -Level Success
            }
        } else {
            Write-VelociraptorLog "Configuration validation failed with $($result.Issues.Count) issues" -Level Error
        }
        
        # Output warnings if not ignored
        if (-not $IgnoreWarnings -and $result.Warnings.Count -gt 0) {
            Write-VelociraptorLog "Warnings found: $($result.Warnings.Count)" -Level Warning
        }
        
        # Format output
        switch ($OutputFormat) {
            'JSON' {
                return $result | ConvertTo-Json -Depth 5
            }
            'Summary' {
                return [PSCustomObject]@{
                    IsValid = $result.IsValid
                    IssueCount = $result.Issues.Count
                    WarningCount = $result.Warnings.Count
                    SecurityIssueCount = $result.SecurityIssues.Count
                }
            }
            default {
                return $result
            }
        }
    }
    catch {
        $errorMessage = "Configuration validation failed: $($_.Exception.Message)"
        Write-VelociraptorLog $errorMessage -Level Error
        
        return [PSCustomObject]@{
            ConfigPath = $ConfigPath
            IsValid = $false
            Issues = @($_.Exception.Message)
            ValidationDate = Get-Date
            Error = $_.Exception.Message
        }
    }
}

# Helper method for security validation
function Test-SecuritySettings {
    param($configContent, $result, $validationLevel)
    
    # Check for insecure bind addresses
    if ($configContent -match 'bind_address:\s*0\.0\.0\.0') {
        $result.SecurityIssues += "Binding to all interfaces (0.0.0.0) - consider restricting to specific interfaces"
    }
    
    # Check for default credentials
    if ($configContent -match '(password|secret):\s*["`'']?(admin|password|changeme|secret)["`'']?') {
        $result.SecurityIssues += "Default or weak credentials detected"
    }
    
    # Check for missing TLS configuration
    if (-not ($configContent -match 'tls_')) {
        $result.SecurityIssues += "No explicit TLS configuration found"
    }
    
    # Check for localhost autocert
    if ($configContent -match 'autocert_domain:.*localhost') {
        $result.Warnings += "Using localhost for autocert domain - this will only work for local connections"
    }
}

# Helper method for standard validation
function Test-StandardSettings {
    param($configContent, $result)
    
    # Check for proper logging configuration
    if (-not ($configContent -match 'Logging:')) {
        $result.Warnings += "No explicit logging configuration found"
    }
    
    # Check for datastore path
    if ($configContent -match 'location:\s*["`'']?(.+?)["`'']?\s*$') {
        $datastorePath = $Matches[1].Trim()
        $result.ConfigInfo.DatastorePath = $datastorePath
        
        if (-not (Test-Path $datastorePath -IsValid)) {
            $result.Warnings += "Datastore path may not be valid: $datastorePath"
        }
    }
}

# Helper method for comprehensive validation
function Test-ComprehensiveSettings {
    param($configContent, $result)
    
    # Check for proper certificate configuration
    if (-not ($configContent -match 'certificate:')) {
        $result.SecurityIssues += "No explicit certificate configuration found"
    }
    
    # Check for proper authentication configuration
    if (-not ($configContent -match 'auth:')) {
        $result.Warnings += "No explicit authentication configuration found"
    }
    
    # Check for proper rate limiting
    if (-not ($configContent -match 'rate_limit')) {
        $result.Recommendations += "Consider adding rate limiting configuration"
    }
    
    # Check for proper monitoring configuration
    if (-not ($configContent -match 'monitoring:')) {
        $result.Recommendations += "Consider adding monitoring configuration"
    }
}