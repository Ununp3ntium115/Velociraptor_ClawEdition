@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'VelociraptorGovernance.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID = 'b2c3d4e5-f6a7-4901-bcde-f23456789012'

    # Author of this module
    Author = 'Velociraptor Community'

    # Company or vendor of this module
    CompanyName = 'Velociraptor Community'

    # Copyright statement for this module
    Copyright = '(c) 2024 Velociraptor Community. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'PowerShell module for Velociraptor governance, compliance, and audit trail management'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    # NOTE: Only implemented functions are exported for beta release
    FunctionsToExport = @(
        'Test-ComplianceBaseline',
        'Export-AuditReport',
        'Write-AuditEvent',
        'Get-AuditEvents'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # Private data to pass to the module
    PrivateData = @{
        PSData = @{
            Tags = @('Velociraptor', 'Governance', 'Compliance', 'Audit', 'Security', 'PowerShell')
            LicenseUri = 'https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts/blob/main/LICENSE'
            ProjectUri = 'https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts'
            ReleaseNotes = @'
# Release Notes - Version 1.0.0

## New Features
- Comprehensive compliance baseline testing
- Automated audit report generation
- Policy enforcement mechanisms
- Risk assessment capabilities
- Change tracking and audit trails
- Access control management
- Multi-framework compliance support (SOX, HIPAA, PCI-DSS, GDPR)

## Functions Included
- Test-ComplianceBaseline: Comprehensive compliance testing
- Export-AuditReport: Detailed audit report generation
- Set-PolicyEnforcement: Policy configuration and enforcement
- New-ComplianceReport: Compliance status reporting
- Start-AuditTrail: Audit trail initialization and management
- Get-ChangeHistory: Configuration change tracking
- Set-AccessControl: Access control configuration
- Test-RiskAssessment: Security risk evaluation
'@
        }
    }
}