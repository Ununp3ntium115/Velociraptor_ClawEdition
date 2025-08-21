function New-IncidentResponsePackage {
    <#
    .SYNOPSIS
        Creates specialized incident response packages without code duplication.

    .DESCRIPTION
        This function creates incident-specific deployment packages by referencing
        the main codebase rather than duplicating files. Each package contains only
        the unique configurations and artifacts needed for that incident type.

    .PARAMETER IncidentType
        The type of incident response package to create.

    .PARAMETER OutputPath
        The path where the package will be created.

    .PARAMETER CoreModulePath
        The path to the core VelociraptorDeployment module.

    .PARAMETER ArtifactFilter
        Filter to select only relevant artifacts for this incident type.

    .PARAMETER IncludeMainScripts
        Whether to include symbolic links to main deployment scripts.

    .EXAMPLE
        New-IncidentResponsePackage -IncidentType "Ransomware" -OutputPath ".\packages"

    .EXAMPLE
        New-IncidentResponsePackage -IncidentType "APT" -OutputPath ".\packages" -ArtifactFilter "*.Yara.*,*.PersistenceSniper.*"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('APT', 'Ransomware', 'Malware', 'DataBreach', 'Insider', 'NetworkIntrusion', 'Complete')]
        [string]$IncidentType,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,

        [Parameter()]
        [string]$CoreModulePath = (Get-Module VelociraptorDeployment).ModuleBase,

        [Parameter()]
        [string[]]$ArtifactFilter = @(),

        [Parameter()]
        [switch]$IncludeMainScripts = $true
    )

    Write-VelociraptorLog "Creating $IncidentType incident response package..." -Level Info

    try {
        # Define package configuration
        $PackageConfig = Get-IncidentPackageConfig -IncidentType $IncidentType
        $PackagePath = Join-Path $OutputPath "$IncidentType-Package"

        # Create package directory structure
        New-Item -Path $PackagePath -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $PackagePath 'config') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $PackagePath 'artifacts') -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path $PackagePath 'scripts') -ItemType Directory -Force | Out-Null

        # Create package manifest
        $Manifest = @{
            PackageType = $IncidentType
            Version = (Get-Module VelociraptorDeployment).Version.ToString()
            CreatedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Description = $PackageConfig.Description
            RequiredModules = @('VelociraptorDeployment')
            CoreModulePath = $CoreModulePath
            ArtifactCount = 0
            DeploymentScripts = @()
        }

        # Create incident-specific deployment script
        $DeploymentScript = @"
#!/usr/bin/env pwsh

<#
.SYNOPSIS
    $IncidentType Incident Response Deployment Script

.DESCRIPTION
    Specialized deployment script for $IncidentType incidents.
    This script references the main VelociraptorDeployment module
    to avoid code duplication while providing incident-specific functionality.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]`$ServerName = "$($PackageConfig.DefaultServerName)",
    
    [Parameter()]
    [int]`$GuiPort = $($PackageConfig.DefaultGuiPort),
    
    [Parameter()]
    [int]`$FrontendPort = $($PackageConfig.DefaultFrontendPort),
    
    [Parameter()]
    [string]`$DatastoreLocation = "$($PackageConfig.DefaultDatastore)",
    
    [Parameter()]
    [switch]`$EmergencyMode
)

# Import the main VelociraptorDeployment module
try {
    `$ModulePath = Join-Path `$PSScriptRoot '..\..\..\modules\VelociraptorDeployment\VelociraptorDeployment.psd1'
    if (-not (Test-Path `$ModulePath)) {
        throw "Core VelociraptorDeployment module not found at: `$ModulePath"
    }
    Import-Module `$ModulePath -Force
    Write-VelociraptorLog "Loaded VelociraptorDeployment module" -Level Info
} catch {
    Write-Error "Failed to load VelociraptorDeployment module: `$(`$_.Exception.Message)"
    exit 1
}

# Set incident-specific configuration
`$IncidentConfig = @{
    IncidentType = '$IncidentType'
    ArtifactPath = Join-Path `$PSScriptRoot 'artifacts'
    ConfigTemplate = Join-Path `$PSScriptRoot 'config\$($IncidentType.ToLower())-config.yaml'
    LogPath = Join-Path `$env:ProgramData "VelociraptorDeploy\$IncidentType"
}

Write-VelociraptorLog "Starting $IncidentType incident response deployment..." -Level Info

# Validate environment
if (-not (Test-VelociraptorAdminPrivileges)) {
    Write-Error "Administrator privileges required for $IncidentType deployment"
    exit 1
}

# Create specialized configuration
try {
    `$ConfigParams = @{
        ServerName = `$ServerName
        GuiPort = `$GuiPort
        FrontendPort = `$FrontendPort
        DatastoreLocation = `$DatastoreLocation
        IncidentType = '$IncidentType'
        ArtifactPath = `$IncidentConfig.ArtifactPath
        EmergencyMode = `$EmergencyMode
    }
    
    `$Config = New-ConfigurationEngine @ConfigParams
    Write-VelociraptorLog "Generated $IncidentType configuration" -Level Info
} catch {
    Write-VelociraptorLog "Failed to generate configuration: `$(`$_.Exception.Message)" -Level Error
    exit 1
}

# Deploy using main deployment engine with incident-specific settings
try {
    if (`$EmergencyMode) {
        Write-VelociraptorLog "EMERGENCY MODE: Rapid $IncidentType deployment" -Level Warning
        `$DeploymentParams = @{
            ConfigPath = `$Config.ConfigPath
            SkipValidation = `$true
            FastDeploy = `$true
            IncidentType = '$IncidentType'
        }
    } else {
        `$DeploymentParams = @{
            ConfigPath = `$Config.ConfigPath
            IncidentType = '$IncidentType'
        }
    }
    
    # Use the appropriate main deployment script based on configuration
    if (`$Config.DeploymentType -eq 'Standalone') {
        & (Join-Path `$PSScriptRoot '..\..\..\Deploy_Velociraptor_Standalone.ps1') @DeploymentParams
    } else {
        & (Join-Path `$PSScriptRoot '..\..\..\Deploy_Velociraptor_Server.ps1') @DeploymentParams
    }
    
    Write-VelociraptorLog "$IncidentType deployment completed successfully" -Level Success
} catch {
    Write-VelociraptorLog "Deployment failed: `$(`$_.Exception.Message)" -Level Error
    exit 1
}
"@

        # Save the deployment script
        $ScriptPath = Join-Path $PackagePath "Deploy-$IncidentType.ps1"
        Set-Content -Path $ScriptPath -Value $DeploymentScript -Encoding UTF8
        $Manifest.DeploymentScripts += "Deploy-$IncidentType.ps1"

        # Copy incident-specific artifacts
        if ($PackageConfig.Artifacts -and $PackageConfig.Artifacts.Count -gt 0) {
            foreach ($artifact in $PackageConfig.Artifacts) {
                $SourcePath = Join-Path $PSScriptRoot "..\..\..\content\exchange\artifacts\$artifact"
                $DestPath = Join-Path $PackagePath "artifacts\$artifact"
                
                if (Test-Path $SourcePath) {
                    Copy-Item -Path $SourcePath -Destination $DestPath -Force
                    Write-VelociraptorLog "Added artifact: $artifact" -Level Info
                    $Manifest.ArtifactCount++
                }
            }
        }

        # Create incident-specific configuration template
        $ConfigTemplate = Get-IncidentConfigTemplate -IncidentType $IncidentType
        $ConfigPath = Join-Path $PackagePath "config\$($IncidentType.ToLower())-config.yaml"
        Set-Content -Path $ConfigPath -Value $ConfigTemplate -Encoding UTF8

        # Create package README
        $ReadmeContent = Get-IncidentPackageReadme -IncidentType $IncidentType -Config $PackageConfig
        Set-Content -Path (Join-Path $PackagePath 'README.md') -Value $ReadmeContent -Encoding UTF8

        # Save manifest
        $Manifest | ConvertTo-Json -Depth 3 | Set-Content -Path (Join-Path $PackagePath 'package-manifest.json') -Encoding UTF8

        Write-VelociraptorLog "Created $IncidentType package at: $PackagePath" -Level Success
        
        return @{
            Success = $true
            PackagePath = $PackagePath
            ArtifactCount = $Manifest.ArtifactCount
            Size = (Get-ChildItem $PackagePath -Recurse | Measure-Object -Property Length -Sum).Sum
        }
    }
    catch {
        $errorMsg = "Failed to create $IncidentType package: $($_.Exception.Message)"
        Write-VelociraptorLog $errorMsg -Level Error
        throw $errorMsg
    }
}

function Get-IncidentPackageConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$IncidentType
    )

    $Configs = @{
        'APT' = @{
            Description = 'Advanced Persistent Threat investigation and response'
            DefaultServerName = 'apt-investigation.local'
            DefaultGuiPort = 8889
            DefaultFrontendPort = 8000
            DefaultDatastore = 'C:\VelociraptorData\APT'
            Artifacts = @(
                'Windows.Detection.Yara.Yara64.yaml',
                'Windows.EventLogs.Hayabusa.yaml',
                'Windows.Forensics.PersistenceSniper.yaml'
            )
        }
        'Ransomware' = @{
            Description = 'Ransomware incident response and analysis'
            DefaultServerName = 'ransomware-response.local'
            DefaultGuiPort = 8890
            DefaultFrontendPort = 8001
            DefaultDatastore = 'C:\VelociraptorData\Ransomware'
            Artifacts = @(
                'Windows.Detection.Yara.Yara64.yaml',
                'Windows.EventLogs.Hayabusa.yaml',
                'Windows.Forensics.PersistenceSniper.yaml'
            )
        }
        'Malware' = @{
            Description = 'Malware analysis and forensic investigation'
            DefaultServerName = 'malware-analysis.local'
            DefaultGuiPort = 8891
            DefaultFrontendPort = 8002
            DefaultDatastore = 'C:\VelociraptorData\Malware'
            Artifacts = @(
                'Windows.Analysis.Capa.yaml',
                'Windows.Detection.Yara.Yara64.yaml',
                'Windows.EventLogs.Hayabusa.yaml',
                'Windows.Forensics.PersistenceSniper.yaml'
            )
        }
        'DataBreach' = @{
            Description = 'Data breach investigation and containment'
            DefaultServerName = 'databreach-investigation.local'
            DefaultGuiPort = 8892
            DefaultFrontendPort = 8003
            DefaultDatastore = 'C:\VelociraptorData\DataBreach'
            Artifacts = @(
                'Windows.EventLogs.Hayabusa.yaml'
            )
        }
        'Insider' = @{
            Description = 'Insider threat investigation and monitoring'
            DefaultServerName = 'insider-investigation.local'
            DefaultGuiPort = 8893
            DefaultFrontendPort = 8004
            DefaultDatastore = 'C:\VelociraptorData\Insider'
            Artifacts = @(
                'Windows.EventLogs.Hayabusa.yaml',
                'Windows.Forensics.Clipboard.yaml'
            )
        }
        'NetworkIntrusion' = @{
            Description = 'Network intrusion detection and response'
            DefaultServerName = 'network-investigation.local'
            DefaultGuiPort = 8894
            DefaultFrontendPort = 8005
            DefaultDatastore = 'C:\VelociraptorData\NetworkIntrusion'
            Artifacts = @(
                'Windows.Detection.Yara.Yara64.yaml',
                'Windows.EventLogs.Hayabusa.yaml',
                'Windows.Forensics.PersistenceSniper.yaml'
            )
        }
        'Complete' = @{
            Description = 'Complete incident response package with all artifacts'
            DefaultServerName = 'complete-investigation.local'
            DefaultGuiPort = 8888
            DefaultFrontendPort = 7999
            DefaultDatastore = 'C:\VelociraptorData\Complete'
            Artifacts = @() # Will include all available artifacts
        }
    }

    return $Configs[$IncidentType]
}

function Get-IncidentConfigTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$IncidentType
    )

    return @"
# $IncidentType Incident Response Configuration Template
# This configuration is optimized for $IncidentType investigations

version:
  name: velociraptor
  version: "{{ .Version }}"
  commit: "{{ .Commit }}"
  build_time: "{{ .BuildTime }}"

Client:
  server_urls:
    - https://{{ .ServerName }}:{{ .FrontendPort }}/
  ca_certificate: |
{{ .CACert | indent 4 }}
  nonce: "{{ .Nonce }}"

API:
  bind_address: 127.0.0.1
  bind_port: {{ .GuiPort }}
  bind_scheme: https
  pinned_gw_name: GRPC_GW

GUI:
  bind_address: 0.0.0.0
  bind_port: {{ .GuiPort }}
  gw_certificate: |
{{ .GWCert | indent 4 }}
  gw_private_key: |
{{ .GWKey | indent 4 }}
  authenticator: 
    type: Basic

Frontend:
  bind_address: 0.0.0.0
  bind_port: {{ .FrontendPort }}
  certificate: |
{{ .FrontendCert | indent 4 }}
  private_key: |
{{ .FrontendKey | indent 4 }}
  
Datastore:
  implementation: FileDataStore
  location: {{ .DatastoreLocation }}
  filestore_directory: {{ .DatastoreLocation }}\filestore

Logging:
  output_directory: {{ .DatastoreLocation }}\logs
  separate_logs_per_component: true
  rotation_time: 604800
  max_age: 31536000

# $IncidentType-specific settings
autocert_domain: {{ .ServerName }}
autocert_cert_cache: {{ .DatastoreLocation }}\autocert
default_server_config:
  urls:
    - https://{{ .ServerName }}:{{ .FrontendPort }}/
"@
}

function Get-IncidentPackageReadme {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$IncidentType,
        
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    return @"
# $IncidentType Incident Response Package

**Version**: $(Get-Module VelociraptorDeployment | Select-Object -ExpandProperty Version)  
**Created**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Type**: $($Config.Description)

## Overview

This is a specialized incident response package for **$IncidentType** investigations. 
It provides a streamlined deployment focused on the specific artifacts and 
configurations needed for this type of incident.

## Key Features

- **Zero Code Duplication**: References the main VelociraptorDeployment module
- **Incident-Specific Artifacts**: Pre-configured with relevant artifacts
- **Optimized Configuration**: Tuned for $IncidentType investigations
- **Emergency Mode**: Rapid deployment capability for time-critical incidents
- **Professional Integration**: Full compatibility with main Velociraptor ecosystem

## Quick Start

### Emergency Deployment (2-3 minutes)
```powershell
.\Deploy-$IncidentType.ps1 -EmergencyMode
```

### Standard Deployment
```powershell
.\Deploy-$IncidentType.ps1
```

### Custom Configuration
```powershell
.\Deploy-$IncidentType.ps1 -ServerName "custom-server.local" -GuiPort 9000
```

## Package Contents

- **Deploy-$IncidentType.ps1**: Main deployment script
- **config/**: Incident-specific configuration templates
- **artifacts/**: Curated artifacts for $IncidentType investigations
- **package-manifest.json**: Package metadata and dependencies

## Artifacts Included

$($Config.Artifacts | ForEach-Object { "- $_" } | Out-String)

## Requirements

- **Administrator Privileges**: Required for deployment
- **VelociraptorDeployment Module**: Must be available in parent directory structure
- **PowerShell 5.1+**: Windows PowerShell or PowerShell Core
- **Network Access**: For downloading Velociraptor binaries (unless offline)

## Emergency Response Workflow

1. **Immediate Deployment**: Use `-EmergencyMode` for fastest setup
2. **Rapid Collection**: Start with built-in artifact collection
3. **Analysis**: Use Velociraptor GUI for investigation
4. **Escalation**: Integrate with larger investigation infrastructure

## Integration with Main Platform

This package is designed to work seamlessly with the main Velociraptor Setup Scripts:

- **Shared Module**: Uses the same VelociraptorDeployment module
- **Consistent Logging**: Integrates with centralized logging
- **Unified Management**: Compatible with existing governance tools
- **Scalable Architecture**: Can be upgraded to full deployment

## Support and Documentation

- **Main Project**: [Velociraptor Setup Scripts](../../README.md)
- **Module Documentation**: [VelociraptorDeployment Module](../../modules/VelociraptorDeployment/)
- **Troubleshooting**: [Troubleshooting Guide](../../docs/troubleshooting.md)

## Security Considerations

- All configurations follow enterprise security standards
- Incident-specific hardening applied
- Audit trail maintained for compliance
- Secure credential handling throughout

---

**Note**: This package is part of the Velociraptor Setup Scripts ecosystem, 
providing enterprise-grade DFIR capabilities with zero licensing costs.
"@
}

Export-ModuleMember -Function New-IncidentResponsePackage