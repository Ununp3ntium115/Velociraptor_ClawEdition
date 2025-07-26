@{
    # Module manifest for VelociraptorDeployment
    RootModule        = 'VelociraptorDeployment.psm1'
    ModuleVersion     = '2.0.0'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = 'Velociraptor Community'
    CompanyName       = 'Open Source'
    Copyright         = '(c) 2024 Velociraptor Community. All rights reserved.'
    Description       = 'PowerShell module for deploying and managing Velociraptor digital forensics platform'
    
    # Minimum version of the PowerShell engine required
    PowerShellVersion = '5.1'
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Install-VelociraptorStandalone',
        'Install-VelociraptorServer', 
        'Remove-VelociraptorInstallation',
        'Get-VelociraptorStatus',
        'New-VelociraptorOfflineEnvironment',
        'Test-VelociraptorPrerequisites'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport   = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport   = @()
    
    # Private data to pass to the module
    PrivateData       = @{
        PSData = @{
            Tags         = @('Velociraptor', 'DFIR', 'Forensics', 'Security', 'Deployment')
            LicenseUri   = 'https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts'
            ReleaseNotes = 'Initial release of Velociraptor deployment module'
        }
    }
}