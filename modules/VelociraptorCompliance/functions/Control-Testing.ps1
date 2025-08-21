function Test-ConfigurationControl {
    <#
    .SYNOPSIS
        Tests configuration-based compliance controls.
        
    .DESCRIPTION
        Examines Velociraptor configuration files to validate compliance
        with specific control requirements.
        
    .PARAMETER Control
        The compliance control to test.
        
    .PARAMETER ConfigPath
        Path to the Velociraptor configuration file.
        
    .EXAMPLE
        Test-ConfigurationControl -Control $control -ConfigPath "server.config.yaml"
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
        
        # Check if configuration file exists
        if ($ConfigPath -and (Test-Path $ConfigPath)) {
            Write-VelociraptorLog "Testing configuration control $($Control.Id) against $ConfigPath" -Level Debug -Component "Compliance"
            
            # Load configuration based on file type
            $config = $null
            $configExtension = [System.IO.Path]::GetExtension($ConfigPath).ToLower()
            
            switch ($configExtension) {
                '.yaml' { 
                    # For YAML files, we'll need to parse manually or use a YAML parser
                    $configContent = Get-Content $ConfigPath -Raw
                    $testResult.Evidence += "Configuration file content retrieved"
                }
                '.json' { 
                    $config = Get-Content $ConfigPath | ConvertFrom-Json
                    $testResult.Evidence += "JSON configuration parsed successfully"
                }
                '.xml' { 
                    $config = [xml](Get-Content $ConfigPath)
                    $testResult.Evidence += "XML configuration parsed successfully"
                }
                default {
                    $configContent = Get-Content $ConfigPath -Raw
                    $testResult.Evidence += "Raw configuration content retrieved"
                }
            }
            
            # Test specific control requirements
            $testResult = Test-SpecificConfigurationControl -Control $Control -Config $config -ConfigContent $configContent -TestResult $testResult
            
        } else {
            $testResult.Status = 'Fail'
            $testResult.Findings += "Configuration file not found or not specified: $ConfigPath"
        }
        
        return $testResult
        
    } catch {
        return @{
            ControlId = $Control.Id
            ControlTitle = $Control.Title
            Status = 'Error'
            Findings = @("Configuration control test failed: $($_.Exception.Message)")
            TestDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
    }
}

function Test-ProcessControl {
    <#
    .SYNOPSIS
        Tests process-based compliance controls.
        
    .DESCRIPTION
        Evaluates organizational processes and procedures for compliance
        with specific control requirements.
        
    .PARAMETER Control
        The compliance control to test.
        
    .EXAMPLE
        Test-ProcessControl -Control $control
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Control
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
        
        Write-VelociraptorLog "Testing process control $($Control.Id)" -Level Debug -Component "Compliance"
        
        # Test based on control ID and requirements
        switch -Regex ($Control.Id) {
            # Policy and procedure controls
            '.*-1$|Policy|Procedure' {
                $testResult = Test-PolicyProcedureControl -Control $Control -TestResult $testResult
            }
            # Access control related
            'AC-.*|A\.9\..*|CC6\..*' {
                $testResult = Test-AccessControlProcess -Control $Control -TestResult $testResult
            }
            # Incident response related
            'IR-.*|A\.16\..*|CC7\.2' {
                $testResult = Test-IncidentResponseProcess -Control $Control -TestResult $testResult
            }
            # Risk management related
            'CA-.*|RA-.*|A\.6\..*|CC3\..*' {
                $testResult = Test-RiskManagementProcess -Control $Control -TestResult $testResult
            }
            # Training and awareness
            'AT-.*|TR-.*' {
                $testResult = Test-TrainingProcess -Control $Control -TestResult $testResult
            }
            default {
                $testResult = Test-GenericProcess -Control $Control -TestResult $testResult
            }
        }
        
        return $testResult
        
    } catch {
        return @{
            ControlId = $Control.Id
            ControlTitle = $Control.Title
            Status = 'Error'
            Findings = @("Process control test failed: $($_.Exception.Message)")
            TestDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
    }
}

function Test-TechnicalControl {
    <#
    .SYNOPSIS
        Tests technical implementation compliance controls.
        
    .DESCRIPTION
        Examines technical implementations and system configurations
        to validate compliance with specific control requirements.
        
    .PARAMETER Control
        The compliance control to test.
        
    .EXAMPLE
        Test-TechnicalControl -Control $control
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Control
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
        
        Write-VelociraptorLog "Testing technical control $($Control.Id)" -Level Debug -Component "Compliance"
        
        # Test based on control type and requirements
        switch -Regex ($Control.Id) {
            # Authentication and identification
            'IA-.*|A\.9\.2\..*|CC6\.[23]' {
                $testResult = Test-AuthenticationTechnical -Control $Control -TestResult $testResult
            }
            # Audit and accountability
            'AU-.*|A\.12\.4\..*|CC7\.1' {
                $testResult = Test-AuditingTechnical -Control $Control -TestResult $testResult
            }
            # Access control technical
            'AC-[2-9]|A\.9\.4\..*|CC6\.1' {
                $testResult = Test-AccessControlTechnical -Control $Control -TestResult $testResult
            }
            # System and communications protection
            'SC-.*|A\.10\..*|A\.13\..*' {
                $testResult = Test-CommunicationsProtection -Control $Control -TestResult $testResult
            }
            # System integrity
            'SI-.*|A\.12\.6\..*|A\.14\..*' {
                $testResult = Test-SystemIntegrity -Control $Control -TestResult $testResult
            }
            # Configuration management technical
            'CM-[2-9]|A\.12\.1\..*|CC8\.1' {
                $testResult = Test-ConfigurationManagement -Control $Control -TestResult $testResult
            }
            default {
                $testResult = Test-GenericTechnical -Control $Control -TestResult $testResult
            }
        }
        
        return $testResult
        
    } catch {
        return @{
            ControlId = $Control.Id
            ControlTitle = $Control.Title
            Status = 'Error'
            Findings = @("Technical control test failed: $($_.Exception.Message)")
            TestDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
    }
}

function Test-SpecificConfigurationControl {
    <#
    .SYNOPSIS
        Tests specific configuration requirements for controls.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Control,
        
        [Parameter()]
        [object]$Config,
        
        [Parameter()]
        [string]$ConfigContent,
        
        [Parameter(Mandatory)]
        [hashtable]$TestResult
    )
    
    try {
        # Test based on control parameters
        $passedTests = 0
        $totalTests = 0
        
        foreach ($parameter in $Control.Parameters) {
            $totalTests++
            $parameterPassed = $false
            
            switch ($parameter.Name) {
                'LoggingEnabled' {
                    if ($ConfigContent -match '(?i)(logging|audit).*enabled.*true' -or
                        $ConfigContent -match '(?i)log.*level') {
                        $parameterPassed = $true
                        $TestResult.Evidence += "Logging configuration found"
                    }
                }
                'EncryptionEnabled' {
                    if ($ConfigContent -match '(?i)(tls|ssl|encryption).*enabled' -or
                        $ConfigContent -match '(?i)cert|certificate') {
                        $parameterPassed = $true
                        $TestResult.Evidence += "Encryption configuration found"
                    }
                }
                'AuthenticationRequired' {
                    if ($ConfigContent -match '(?i)(auth|authentication)' -or
                        $ConfigContent -match '(?i)(user|login|credential)') {
                        $parameterPassed = $true
                        $TestResult.Evidence += "Authentication configuration found"
                    }
                }
                'AccessControlImplemented' {
                    if ($ConfigContent -match '(?i)(rbac|access.control|permission)' -or
                        $ConfigContent -match '(?i)(role|acl)') {
                        $parameterPassed = $true
                        $TestResult.Evidence += "Access control configuration found"
                    }
                }
                'AuditTrailMaintained' {
                    if ($ConfigContent -match '(?i)(audit|log).*retention' -or
                        $ConfigContent -match '(?i)log.*file') {
                        $parameterPassed = $true
                        $TestResult.Evidence += "Audit trail configuration found"
                    }
                }
                default {
                    # Generic test based on parameter name
                    $pattern = $parameter.Name -replace '([A-Z])', ' $1'
                    if ($ConfigContent -match "(?i)$($pattern.Trim())") {
                        $parameterPassed = $true
                        $TestResult.Evidence += "Configuration for $($parameter.Name) found"
                    }
                }
            }
            
            if ($parameterPassed) {
                $passedTests++
            } else {
                $TestResult.Findings += "Parameter '$($parameter.Name)' not satisfied in configuration"
            }
        }
        
        # Determine overall status
        if ($totalTests -eq 0) {
            $TestResult.Status = 'NotApplicable'
        } elseif ($passedTests -eq $totalTests) {
            $TestResult.Status = 'Pass'
        } elseif ($passedTests -gt 0) {
            $TestResult.Status = 'Partial'
        } else {
            $TestResult.Status = 'Fail'
        }
        
        $TestResult.Evidence += "Configuration test completed: $passedTests/$totalTests parameters satisfied"
        
        return $TestResult
        
    } catch {
        $TestResult.Status = 'Error'
        $TestResult.Findings += "Configuration control test error: $($_.Exception.Message)"
        return $TestResult
    }
}

function Test-PolicyProcedureControl {
    <#
    .SYNOPSIS
        Tests policy and procedure compliance controls.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Control,
        
        [Parameter(Mandatory)]
        [hashtable]$TestResult
    )
    
    try {
        # Check for common policy/procedure evidence
        $policyPaths = @(
            ".\policies\",
            ".\documentation\",
            ".\compliance\",
            "$env:ProgramData\VelociraptorCompliance\policies\"
        )
        
        $foundPolicies = @()
        foreach ($path in $policyPaths) {
            if (Test-Path $path) {
                $policyFiles = Get-ChildItem $path -Filter "*.pdf", "*.docx", "*.md", "*.txt" -ErrorAction SilentlyContinue
                $foundPolicies += $policyFiles
            }
        }
        
        if ($foundPolicies.Count -gt 0) {
            $TestResult.Status = 'Pass'
            $TestResult.Evidence += "Found $($foundPolicies.Count) policy/procedure documents"
            $TestResult.Evidence += ($foundPolicies.Name -join ', ')
        } else {
            $TestResult.Status = 'Fail'
            $TestResult.Findings += "No policy or procedure documents found in standard locations"
        }
        
        return $TestResult
        
    } catch {
        $TestResult.Status = 'Error'
        $TestResult.Findings += "Policy procedure test error: $($_.Exception.Message)"
        return $TestResult
    }
}

function Test-AccessControlProcess {
    <#
    .SYNOPSIS
        Tests access control process compliance.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Control,
        
        [Parameter(Mandatory)]
        [hashtable]$TestResult
    )
    
    try {
        # Check for access control evidence
        $accessControlChecks = @()
        
        # Check for user management processes
        if (Get-Command "Get-LocalUser" -ErrorAction SilentlyContinue) {
            $localUsers = Get-LocalUser | Where-Object { $_.Enabled -eq $true }
            $accessControlChecks += "Found $($localUsers.Count) enabled local users"
        }
        
        # Check for group policy or similar
        if (Test-Path "HKLM:\SOFTWARE\Policies") {
            $accessControlChecks += "Group policy registry keys found"
        }
        
        # Check for Windows security settings
        if (Get-Command "Get-LocalSecurityPolicy" -ErrorAction SilentlyContinue) {
            $accessControlChecks += "Local security policy accessible"
        }
        
        if ($accessControlChecks.Count -gt 0) {
            $TestResult.Status = 'Pass'
            $TestResult.Evidence += $accessControlChecks
        } else {
            $TestResult.Status = 'Partial'
            $TestResult.Findings += "Limited access control evidence found"
        }
        
        return $TestResult
        
    } catch {
        $TestResult.Status = 'Error'
        $TestResult.Findings += "Access control process test error: $($_.Exception.Message)"
        return $TestResult
    }
}

function Test-IncidentResponseProcess {
    <#
    .SYNOPSIS
        Tests incident response process compliance.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Control,
        
        [Parameter(Mandatory)]
        [hashtable]$TestResult
    )
    
    try {
        # Check for incident response evidence
        $irChecks = @()
        
        # Check for Windows Event Log configuration
        if (Get-Command "Get-WinEvent" -ErrorAction SilentlyContinue) {
            $securityLog = Get-WinEvent -ListLog Security -ErrorAction SilentlyContinue
            if ($securityLog) {
                $irChecks += "Security event log configured"
            }
        }
        
        # Check for incident response documentation
        $irPaths = @(
            ".\incident-response\",
            ".\ir\",
            "$env:ProgramData\VelociraptorCompliance\incident-response\"
        )
        
        foreach ($path in $irPaths) {
            if (Test-Path $path) {
                $irChecks += "Incident response directory found: $path"
            }
        }
        
        if ($irChecks.Count -gt 0) {
            $TestResult.Status = 'Pass'
            $TestResult.Evidence += $irChecks
        } else {
            $TestResult.Status = 'Fail'
            $TestResult.Findings += "No incident response evidence found"
        }
        
        return $TestResult
        
    } catch {
        $TestResult.Status = 'Error'
        $TestResult.Findings += "Incident response process test error: $($_.Exception.Message)"
        return $TestResult
    }
}

function Test-RiskManagementProcess {
    <#
    .SYNOPSIS
        Tests risk management process compliance.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Control,
        
        [Parameter(Mandatory)]
        [hashtable]$TestResult
    )
    
    try {
        # Check for risk management evidence
        $riskChecks = @()
        
        # Check for risk management documentation
        $riskPaths = @(
            ".\risk-management\",
            ".\risks\",
            "$env:ProgramData\VelociraptorCompliance\risk-management\"
        )
        
        foreach ($path in $riskPaths) {
            if (Test-Path $path) {
                $riskFiles = Get-ChildItem $path -Filter "*risk*" -ErrorAction SilentlyContinue
                if ($riskFiles) {
                    $riskChecks += "Risk management files found: $($riskFiles.Count)"
                }
            }
        }
        
        # Check for assessment capabilities
        if (Get-Command "Test-VelociraptorHealth" -ErrorAction SilentlyContinue) {
            $riskChecks += "Health assessment capability available"
        }
        
        if ($riskChecks.Count -gt 0) {
            $TestResult.Status = 'Pass'
            $TestResult.Evidence += $riskChecks
        } else {
            $TestResult.Status = 'Partial'
            $TestResult.Findings += "Limited risk management evidence found"
        }
        
        return $TestResult
        
    } catch {
        $TestResult.Status = 'Error'
        $TestResult.Findings += "Risk management process test error: $($_.Exception.Message)"
        return $TestResult
    }
}

function Test-TrainingProcess {
    <#
    .SYNOPSIS
        Tests training and awareness process compliance.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Control,
        
        [Parameter(Mandatory)]
        [hashtable]$TestResult
    )
    
    try {
        # Check for training evidence
        $trainingChecks = @()
        
        # Check for training documentation
        $trainingPaths = @(
            ".\training\",
            ".\documentation\training\",
            "$env:ProgramData\VelociraptorCompliance\training\"
        )
        
        foreach ($path in $trainingPaths) {
            if (Test-Path $path) {
                $trainingFiles = Get-ChildItem $path -ErrorAction SilentlyContinue
                if ($trainingFiles) {
                    $trainingChecks += "Training materials found: $($trainingFiles.Count) files"
                }
            }
        }
        
        if ($trainingChecks.Count -gt 0) {
            $TestResult.Status = 'Pass'
            $TestResult.Evidence += $trainingChecks
        } else {
            $TestResult.Status = 'NotApplicable'
            $TestResult.Findings += "No training materials found - may not be applicable for technical deployment"
        }
        
        return $TestResult
        
    } catch {
        $TestResult.Status = 'Error'
        $TestResult.Findings += "Training process test error: $($_.Exception.Message)"
        return $TestResult
    }
}

function Test-GenericProcess {
    <#
    .SYNOPSIS
        Tests generic process compliance controls.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Control,
        
        [Parameter(Mandatory)]
        [hashtable]$TestResult
    )
    
    try {
        # Generic process test
        $TestResult.Status = 'Partial'
        $TestResult.Findings += "Generic process control - manual verification required"
        $TestResult.Evidence += "Control requires manual verification of organizational processes"
        
        return $TestResult
        
    } catch {
        $TestResult.Status = 'Error'
        $TestResult.Findings += "Generic process test error: $($_.Exception.Message)"
        return $TestResult
    }
}