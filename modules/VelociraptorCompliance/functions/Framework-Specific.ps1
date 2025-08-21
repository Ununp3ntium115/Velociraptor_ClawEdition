function Get-FedRAMPControls {
    <#
    .SYNOPSIS
        Gets FedRAMP-specific controls for compliance assessment.
        
    .DESCRIPTION
        Retrieves and filters FedRAMP controls based on authorization level
        and specific control scope if provided.
        
    .PARAMETER ControlScope
        Specific FedRAMP controls to include (e.g., "AC-1", "AU-2").
        
    .PARAMETER AuthorizationLevel
        FedRAMP authorization level (Low, Moderate, High).
        
    .EXAMPLE
        Get-FedRAMPControls -AuthorizationLevel "Moderate"
        
    .EXAMPLE
        Get-FedRAMPControls -ControlScope @("AC-1", "AC-2") -AuthorizationLevel "High"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$ControlScope,
        
        [Parameter()]
        [ValidateSet('Low', 'Moderate', 'High')]
        [string]$AuthorizationLevel = 'Moderate'
    )
    
    try {
        # Load FedRAMP controls template
        $templatePath = Join-Path $PSScriptRoot "..\templates\FedRAMP-controls.json"
        $fedRAMPTemplate = Get-Content $templatePath | ConvertFrom-Json
        
        $controls = @()
        
        foreach ($family in $fedRAMPTemplate.ControlFamilies) {
            foreach ($control in $family.Controls) {
                # Filter by authorization level
                if ($control.AuthorizationLevel -contains $AuthorizationLevel) {
                    # Filter by control scope if specified
                    if (-not $ControlScope -or $control.Id -in $ControlScope) {
                        $controls += @{
                            Id = $control.Id
                            Title = $control.Title
                            Description = $control.Description
                            TestType = $control.TestType
                            AuthorizationLevel = $AuthorizationLevel
                            Parameters = $control.Parameters
                            TestCriteria = $control.TestCriteria
                            Family = $family.FamilyName
                            Framework = 'FedRAMP'
                        }
                    }
                }
            }
        }
        
        Write-VelociraptorLog "Retrieved $($controls.Count) FedRAMP controls for $AuthorizationLevel level" -Level Info -Component "Compliance"
        return $controls
        
    } catch {
        Write-VelociraptorLog "Failed to get FedRAMP controls: $($_.Exception.Message)" -Level Error -Component "Compliance"
        throw
    }
}

function Get-SOC2Controls {
    <#
    .SYNOPSIS
        Gets SOC2-specific controls for compliance assessment.
        
    .DESCRIPTION
        Retrieves and filters SOC2 controls based on Trust Service Categories
        and specific control scope if provided.
        
    .PARAMETER ControlScope
        Specific SOC2 controls to include (e.g., "CC6.1", "CC6.2").
        
    .PARAMETER TrustServiceCategories
        SOC2 Trust Service Categories to include (Security, Availability, etc.).
        
    .EXAMPLE
        Get-SOC2Controls -TrustServiceCategories @("Security", "Availability")
        
    .EXAMPLE
        Get-SOC2Controls -ControlScope @("CC6.1", "CC6.2")
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$ControlScope,
        
        [Parameter()]
        [ValidateSet('Security', 'Availability', 'Processing Integrity', 'Confidentiality', 'Privacy')]
        [string[]]$TrustServiceCategories = @('Security', 'Availability', 'Processing Integrity', 'Confidentiality', 'Privacy')
    )
    
    try {
        # Load SOC2 controls template
        $templatePath = Join-Path $PSScriptRoot "..\templates\SOC2-controls.json"
        $soc2Template = Get-Content $templatePath | ConvertFrom-Json
        
        $controls = @()
        
        foreach ($category in $soc2Template.ControlCategories) {
            foreach ($control in $category.Controls) {
                # Check if control applies to selected Trust Service Categories
                $categoryMatch = $false
                foreach ($tsc in $TrustServiceCategories) {
                    if ($control.TrustServiceCategory -contains $tsc) {
                        $categoryMatch = $true
                        break
                    }
                }
                
                if ($categoryMatch) {
                    # Filter by control scope if specified
                    if (-not $ControlScope -or $control.Id -in $ControlScope) {
                        $controls += @{
                            Id = $control.Id
                            Title = $control.Title
                            Description = $control.Description
                            TestType = $control.TestType
                            TrustServiceCategory = $control.TrustServiceCategory
                            Parameters = $control.Parameters
                            TestCriteria = $control.TestCriteria
                            Category = $category.CategoryName
                            Framework = 'SOC2'
                        }
                    }
                }
            }
        }
        
        Write-VelociraptorLog "Retrieved $($controls.Count) SOC2 controls for Trust Service Categories: $($TrustServiceCategories -join ', ')" -Level Info -Component "Compliance"
        return $controls
        
    } catch {
        Write-VelociraptorLog "Failed to get SOC2 controls: $($_.Exception.Message)" -Level Error -Component "Compliance"
        throw
    }
}

function Get-ISO27001Controls {
    <#
    .SYNOPSIS
        Gets ISO27001-specific controls for compliance assessment.
        
    .DESCRIPTION
        Retrieves and filters ISO27001 Annex A controls based on
        control objectives and specific control scope if provided.
        
    .PARAMETER ControlScope
        Specific ISO27001 controls to include (e.g., "A.5.1.1", "A.9.1.1").
        
    .PARAMETER ControlObjectives
        ISO27001 control objectives to include (e.g., "A.5", "A.9").
        
    .EXAMPLE
        Get-ISO27001Controls -ControlObjectives @("A.5", "A.9")
        
    .EXAMPLE
        Get-ISO27001Controls -ControlScope @("A.5.1.1", "A.9.1.1")
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$ControlScope,
        
        [Parameter()]
        [string[]]$ControlObjectives
    )
    
    try {
        # Load ISO27001 controls template
        $templatePath = Join-Path $PSScriptRoot "..\templates\ISO27001-controls.json"
        $iso27001Template = Get-Content $templatePath | ConvertFrom-Json
        
        $controls = @()
        
        foreach ($objective in $iso27001Template.AnnexAControlObjectives) {
            # Filter by control objectives if specified
            if (-not $ControlObjectives -or $objective.ObjectiveId -in $ControlObjectives) {
                foreach ($control in $objective.Controls) {
                    # Filter by control scope if specified
                    if (-not $ControlScope -or $control.Id -in $ControlScope) {
                        $controls += @{
                            Id = $control.Id
                            Title = $control.Title
                            Description = $control.Description
                            TestType = $control.TestType
                            Parameters = $control.Parameters
                            TestCriteria = $control.TestCriteria
                            Objective = $objective.ObjectiveName
                            ObjectiveId = $objective.ObjectiveId
                            Framework = 'ISO27001'
                        }
                    }
                }
            }
        }
        
        Write-VelociraptorLog "Retrieved $($controls.Count) ISO27001 controls" -Level Info -Component "Compliance"
        return $controls
        
    } catch {
        Write-VelociraptorLog "Failed to get ISO27001 controls: $($_.Exception.Message)" -Level Error -Component "Compliance"
        throw
    }
}

function Get-GenericComplianceControls {
    <#
    .SYNOPSIS
        Gets generic compliance controls for other frameworks.
        
    .DESCRIPTION
        Provides a basic set of compliance controls for frameworks
        that don't have specific implementations yet.
        
    .PARAMETER Framework
        The compliance framework name.
        
    .PARAMETER ControlScope
        Specific controls to include.
        
    .EXAMPLE
        Get-GenericComplianceControls -Framework "NIST" -ControlScope @("ID.AM", "PR.AC")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Framework,
        
        [Parameter()]
        [string[]]$ControlScope
    )
    
    try {
        # Basic control set for generic frameworks
        $genericControls = @(
            @{
                Id = "GEN-001"
                Title = "Access Control Policy"
                Description = "Organization has documented access control policies and procedures"
                TestType = "Process"
                Parameters = @(@{Name = "PolicyExists"; Type = "Boolean"; Required = $true})
                TestCriteria = @("Verify access control policy exists", "Verify policy is current")
                Framework = $Framework
            },
            @{
                Id = "GEN-002"
                Title = "Audit Logging"
                Description = "System maintains comprehensive audit logs"
                TestType = "Technical"
                Parameters = @(@{Name = "LoggingEnabled"; Type = "Boolean"; Required = $true})
                TestCriteria = @("Verify logging is enabled", "Verify logs are comprehensive")
                Framework = $Framework
            },
            @{
                Id = "GEN-003"
                Title = "Incident Response"
                Description = "Organization has incident response procedures"
                TestType = "Process"
                Parameters = @(@{Name = "IncidentProcedures"; Type = "Boolean"; Required = $true})
                TestCriteria = @("Verify incident response procedures exist", "Verify procedures are tested")
                Framework = $Framework
            }
        )
        
        # Filter by control scope if specified
        if ($ControlScope) {
            $genericControls = $genericControls | Where-Object { $_.Id -in $ControlScope }
        }
        
        Write-VelociraptorLog "Retrieved $($genericControls.Count) generic compliance controls for $Framework" -Level Info -Component "Compliance"
        return $genericControls
        
    } catch {
        Write-VelociraptorLog "Failed to get generic compliance controls: $($_.Exception.Message)" -Level Error -Component "Compliance"
        throw
    }
}

function Test-VelociraptorFedRAMP {
    <#
    .SYNOPSIS
        Performs FedRAMP-specific compliance testing.
        
    .DESCRIPTION
        Executes comprehensive FedRAMP compliance testing against
        specified authorization level requirements.
        
    .PARAMETER AuthorizationLevel
        FedRAMP authorization level to test against.
        
    .PARAMETER ConfigPath
        Path to Velociraptor configuration file.
        
    .PARAMETER GenerateEvidence
        Generate FedRAMP compliance evidence packages.
        
    .EXAMPLE
        Test-VelociraptorFedRAMP -AuthorizationLevel "Moderate" -ConfigPath "server.config.yaml"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('Low', 'Moderate', 'High')]
        [string]$AuthorizationLevel = 'Moderate',
        
        [Parameter()]
        [string]$ConfigPath,
        
        [Parameter()]
        [switch]$GenerateEvidence
    )
    
    return Test-VelociraptorCompliance -Framework "FedRAMP" -ConfigPath $ConfigPath -GenerateEvidence:$GenerateEvidence
}

function Test-VelociraptorSOC2 {
    <#
    .SYNOPSIS
        Performs SOC2-specific compliance testing.
        
    .DESCRIPTION
        Executes comprehensive SOC2 compliance testing for specified
        Trust Service Categories.
        
    .PARAMETER TrustServiceCategories
        SOC2 Trust Service Categories to test.
        
    .PARAMETER ConfigPath
        Path to Velociraptor configuration file.
        
    .PARAMETER GenerateEvidence
        Generate SOC2 compliance evidence packages.
        
    .EXAMPLE
        Test-VelociraptorSOC2 -TrustServiceCategories @("Security", "Availability") -ConfigPath "server.config.yaml"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('Security', 'Availability', 'Processing Integrity', 'Confidentiality', 'Privacy')]
        [string[]]$TrustServiceCategories = @('Security', 'Availability'),
        
        [Parameter()]
        [string]$ConfigPath,
        
        [Parameter()]
        [switch]$GenerateEvidence
    )
    
    return Test-VelociraptorCompliance -Framework "SOC2" -ConfigPath $ConfigPath -GenerateEvidence:$GenerateEvidence
}

function Test-VelociraptorISO27001 {
    <#
    .SYNOPSIS
        Performs ISO27001-specific compliance testing.
        
    .DESCRIPTION
        Executes comprehensive ISO27001 compliance testing against
        Annex A control objectives.
        
    .PARAMETER ControlObjectives
        ISO27001 control objectives to test.
        
    .PARAMETER ConfigPath
        Path to Velociraptor configuration file.
        
    .PARAMETER GenerateEvidence
        Generate ISO27001 compliance evidence packages.
        
    .EXAMPLE
        Test-VelociraptorISO27001 -ControlObjectives @("A.5", "A.9") -ConfigPath "server.config.yaml"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$ControlObjectives,
        
        [Parameter()]
        [string]$ConfigPath,
        
        [Parameter()]
        [switch]$GenerateEvidence
    )
    
    return Test-VelociraptorCompliance -Framework "ISO27001" -ConfigPath $ConfigPath -GenerateEvidence:$GenerateEvidence
}

function Test-VelociraptorNIST {
    <#
    .SYNOPSIS
        Performs NIST Cybersecurity Framework compliance testing.
        
    .DESCRIPTION
        Executes NIST CSF compliance testing against the five framework functions.
        
    .PARAMETER Functions
        NIST CSF functions to test (Identify, Protect, Detect, Respond, Recover).
        
    .PARAMETER ConfigPath
        Path to Velociraptor configuration file.
        
    .PARAMETER GenerateEvidence
        Generate NIST compliance evidence packages.
        
    .EXAMPLE
        Test-VelociraptorNIST -Functions @("Identify", "Protect") -ConfigPath "server.config.yaml"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('Identify', 'Protect', 'Detect', 'Respond', 'Recover')]
        [string[]]$Functions = @('Identify', 'Protect', 'Detect', 'Respond', 'Recover'),
        
        [Parameter()]
        [string]$ConfigPath,
        
        [Parameter()]
        [switch]$GenerateEvidence
    )
    
    return Test-VelociraptorCompliance -Framework "NIST" -ConfigPath $ConfigPath -GenerateEvidence:$GenerateEvidence
}

function Test-VelociraptorHIPAA {
    <#
    .SYNOPSIS
        Performs HIPAA compliance testing.
        
    .DESCRIPTION
        Executes HIPAA Security Rule compliance testing for covered entities
        and business associates.
        
    .PARAMETER EntityType
        HIPAA entity type (CoveredEntity, BusinessAssociate).
        
    .PARAMETER ConfigPath
        Path to Velociraptor configuration file.
        
    .PARAMETER GenerateEvidence
        Generate HIPAA compliance evidence packages.
        
    .EXAMPLE
        Test-VelociraptorHIPAA -EntityType "BusinessAssociate" -ConfigPath "server.config.yaml"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('CoveredEntity', 'BusinessAssociate')]
        [string]$EntityType = 'BusinessAssociate',
        
        [Parameter()]
        [string]$ConfigPath,
        
        [Parameter()]
        [switch]$GenerateEvidence
    )
    
    return Test-VelociraptorCompliance -Framework "HIPAA" -ConfigPath $ConfigPath -GenerateEvidence:$GenerateEvidence
}

function Test-VelociraptorPCIDSS {
    <#
    .SYNOPSIS
        Performs PCI-DSS compliance testing.
        
    .DESCRIPTION
        Executes PCI-DSS compliance testing for payment card industry requirements.
        
    .PARAMETER MerchantLevel
        PCI-DSS merchant level (Level1, Level2, Level3, Level4).
        
    .PARAMETER ConfigPath
        Path to Velociraptor configuration file.
        
    .PARAMETER GenerateEvidence
        Generate PCI-DSS compliance evidence packages.
        
    .EXAMPLE
        Test-VelociraptorPCIDSS -MerchantLevel "Level1" -ConfigPath "server.config.yaml"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('Level1', 'Level2', 'Level3', 'Level4')]
        [string]$MerchantLevel = 'Level1',
        
        [Parameter()]
        [string]$ConfigPath,
        
        [Parameter()]
        [switch]$GenerateEvidence
    )
    
    return Test-VelociraptorCompliance -Framework "PCI-DSS" -ConfigPath $ConfigPath -GenerateEvidence:$GenerateEvidence
}

function Test-VelociraptorGDPR {
    <#
    .SYNOPSIS
        Performs GDPR compliance testing.
        
    .DESCRIPTION
        Executes GDPR compliance testing for data protection requirements.
        
    .PARAMETER DataControllerRole
        Whether organization acts as data controller or processor.
        
    .PARAMETER ConfigPath
        Path to Velociraptor configuration file.
        
    .PARAMETER GenerateEvidence
        Generate GDPR compliance evidence packages.
        
    .EXAMPLE
        Test-VelociraptorGDPR -DataControllerRole $true -ConfigPath "server.config.yaml"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [bool]$DataControllerRole = $true,
        
        [Parameter()]
        [string]$ConfigPath,
        
        [Parameter()]
        [switch]$GenerateEvidence
    )
    
    return Test-VelociraptorCompliance -Framework "GDPR" -ConfigPath $ConfigPath -GenerateEvidence:$GenerateEvidence
}