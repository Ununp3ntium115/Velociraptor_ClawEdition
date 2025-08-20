@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'VelociraptorDeployment.psm1'

    # Version number of this module.
    ModuleVersion = '5.0.4'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'

    # Author of this module
    Author = 'Velociraptor Community'

    # Company or vendor of this module
    CompanyName = 'Velociraptor Community'

    # Copyright statement for this module
    Copyright = '(c) 2024 Velociraptor Community. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'PowerShell module for Velociraptor deployment, configuration, and management operations'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Name of the PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # ClrVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    # NOTE: Only functions that are fully implemented are exported for beta release
    FunctionsToExport = @(
        'Write-VelociraptorLog',
        'Test-VelociraptorAdminPrivileges',
        'Test-VelociraptorHealth',
        'Get-VelociraptorLatestRelease',
        'Invoke-VelociraptorDownload',
        'Add-VelociraptorFirewallRule',
        'Wait-VelociraptorTcpPort',
        'Test-VelociraptorInternetConnection',
        'Read-VelociraptorUserInput',
        'Read-VelociraptorSecureInput',
        'Test-VelociraptorConfiguration',
        'Backup-VelociraptorConfiguration',
        'Restore-VelociraptorConfiguration',
        'New-VelociraptorConfigurationTemplate',
        'Set-VelociraptorSecurityHardening',
        'New-ArtifactToolManager',
        'Export-ToolMapping',
        'Deploy-VelociraptorEdge'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    # NOTE: Only aliases for implemented functions are exported for beta release
    AliasesToExport = @(
        'Log',
        'Write-Log',
        'Require-Admin',
        'Test-Admin',
        'Latest-WindowsAsset',
        'Download-EXE',
        'Ask',
        'AskSecret',
        'Wait-Port'
    )

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Velociraptor', 'DFIR', 'Security', 'Deployment', 'Automation', 'PowerShell')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = @'
# Release Notes - Version 1.0.0

## New Features
- Comprehensive PowerShell module for Velociraptor deployment operations
- Standardized logging with multiple output options
- Enhanced security validation and hardening functions
- Configuration management with backup and restore capabilities
- Network connectivity and firewall management functions
- Cross-platform compatibility (Windows PowerShell 5.1+ and PowerShell Core)

## Functions Included
- Write-VelociraptorLog: Enhanced logging with multiple levels and outputs
- Test-VelociraptorAdminPrivileges: Administrator privilege validation
- Get-VelociraptorLatestRelease: GitHub release information retrieval
- Invoke-VelociraptorDownload: Secure file download with progress tracking
- Add-VelociraptorFirewallRule: Firewall rule management
- Wait-VelociraptorTcpPort: Network port availability checking
- Test-VelociraptorInternetConnection: Internet connectivity validation
- Read-VelociraptorUserInput: Interactive user input with validation
- Read-VelociraptorSecureInput: Secure password input handling
- Test-VelociraptorConfiguration: Configuration validation and security checking
- Backup-VelociraptorConfiguration: Configuration backup with metadata
- Restore-VelociraptorConfiguration: Configuration restoration
- New-VelociraptorConfigurationTemplate: Template generation
- Set-VelociraptorSecurityHardening: Security hardening automation

## Backward Compatibility
- All legacy function names maintained through aliases
- Existing scripts continue to work without modification
- Gradual migration path to new standardized functions
'@

            # Prerelease string of this module
            # Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false

            # External dependent modules of this module
            # ExternalModuleDependencies = @()

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}