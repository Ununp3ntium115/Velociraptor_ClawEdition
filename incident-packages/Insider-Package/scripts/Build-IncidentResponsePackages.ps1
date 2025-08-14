#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Build specialized incident response packages with offline collectors

.DESCRIPTION
    Creates customized Velociraptor deployment packages for different incident response scenarios,
    including all necessary tools, artifacts, and dependencies for offline deployment.

.PARAMETER PackageType
    Type of incident response package to build

.PARAMETER OutputDirectory
    Directory to save the built packages

.PARAMETER IncludeAllTools
    Include all available tools in the package

.EXAMPLE
    .\Build-IncidentResponsePackages.ps1 -PackageType "Ransomware" -OutputDirectory ".\packages"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("Ransomware", "APT", "Insider", "Malware", "NetworkIntrusion", "DataBreach", "Complete", "Custom")]
    [string]$PackageType,

    [string]$OutputDirectory = ".\incident-packages",

    [switch]$IncludeAllTools,

    [string[]]$CustomArtifacts = @(),

    [switch]$CreatePortable
)

# Incident Response Package Definitions
$IncidentPackages = @{
    "Ransomware" = @{
        Description = "Ransomware incident response and recovery"
        Priority = "Critical"
        Artifacts = @(
            "Windows.EventLogs.Hayabusa",
            "Windows.Forensics.PersistenceSniper",
            "Windows.Detection.Yara.Yara64",
            "Windows.System.Services",
            "Windows.Registry.NTUser",
            "Windows.Forensics.Jumplists",
            "Windows.Timeline.Prefetch",
            "Windows.System.TaskScheduler",
            "Windows.EventLogs.RDPAuth",
            "Windows.Network.NetstatEnriched",
            "Windows.Sys.StartupItems",
            "Windows.Registry.BackupRestore",
            "Windows.Forensics.VSS",
            "Windows.System.Powershell.PSReadline",
            "Windows.Detection.BinaryRename"
        )
        Tools = @(
            "Hayabusa", "PersistenceSniper", "YARA", "Volatility", "FTKImager"
        )
        ExternalTools = @(
            "Sysinternals", "NirSoft", "EricZimmerman"
        )
        ConfigTemplate = "ransomware-config.yaml"
    }

    "APT" = @{
        Description = "Advanced Persistent Threat investigation"
        Priority = "Critical"
        Artifacts = @(
            "Windows.EventLogs.Hayabusa",
            "Windows.Forensics.PersistenceSniper",
            "Windows.Detection.Yara.Yara64",
            "Windows.System.Services",
            "Windows.Registry.NTUser",
            "Windows.Network.NetstatEnriched",
            "Windows.System.Powershell.PSReadline",
            "Windows.EventLogs.PowershellScriptblock",
            "Windows.Registry.Sysinternals.Eulacheck",
            "Windows.System.Handles",
            "Windows.Memory.ProcessInfo",
            "Windows.Detection.Malfind",
            "Windows.System.CertificateAuthorities",
            "Windows.Registry.RecentDocs",
            "Windows.Forensics.Lnk"
        )
        Tools = @(
            "Hayabusa", "PersistenceSniper", "YARA", "Volatility", "Capa", "DetectRaptor"
        )
        ExternalTools = @(
            "Sysinternals", "NirSoft", "EricZimmerman", "VolatilityWorkbench"
        )
        ConfigTemplate = "apt-config.yaml"
    }

    "Insider" = @{
        Description = "Insider threat investigation"
        Priority = "High"
        Artifacts = @(
            "Windows.EventLogs.Hayabusa",
            "Windows.Forensics.UserAccessLogs",
            "Windows.Registry.RecentDocs",
            "Windows.Forensics.Jumplists",
            "Windows.System.Powershell.PSReadline",
            "Windows.Applications.Chrome.History",
            "Windows.Applications.Edge.History",
            "Windows.System.LoggedInUsers",
            "Windows.EventLogs.Authentication",
            "Windows.Registry.UserAssist",
            "Windows.Forensics.Clipboard",
            "Windows.System.Handles",
            "Windows.Network.NetstatEnriched",
            "Windows.Forensics.NTFS.MFT",
            "Windows.Forensics.USN"
        )
        Tools = @(
            "Hayabusa", "LECmd", "JLECmd", "LastActivityView"
        )
        ExternalTools = @(
            "NirSoft", "EricZimmerman"
        )
        ConfigTemplate = "insider-config.yaml"
    }

    "Malware" = @{
        Description = "Malware analysis and containment"
        Priority = "Critical"
        Artifacts = @(
            "Windows.Analysis.Capa",
            "Windows.Detection.Yara.Yara64",
            "Windows.Memory.ProcessInfo",
            "Windows.Detection.Malfind",
            "Windows.System.Handles",
            "Windows.Network.NetstatEnriched",
            "Windows.Forensics.PersistenceSniper",
            "Windows.System.Services",
            "Windows.Registry.NTUser",
            "Windows.EventLogs.Hayabusa",
            "Windows.Detection.BinaryRename",
            "Windows.System.Powershell.PSReadline",
            "Windows.Forensics.Prefetch",
            "Windows.System.Drivers"
        )
        Tools = @(
            "Capa", "YARA", "Volatility", "PersistenceSniper", "DIE", "Hayabusa"
        )
        ExternalTools = @(
            "Sysinternals", "VolatilityWorkbench"
        )
        ConfigTemplate = "malware-config.yaml"
    }

    "NetworkIntrusion" = @{
        Description = "Network-based attack investigation"
        Priority = "High"
        Artifacts = @(
            "Windows.Network.NetstatEnriched",
            "Windows.EventLogs.Hayabusa",
            "Windows.System.Services",
            "Windows.Registry.NTUser",
            "Windows.EventLogs.Authentication",
            "Windows.EventLogs.RDPAuth",
            "Windows.System.LoggedInUsers",
            "Windows.Network.ArpCache",
            "Windows.Network.DNSCache",
            "Windows.System.Handles",
            "Windows.Forensics.PersistenceSniper",
            "Windows.Detection.Yara.Yara64",
            "Windows.System.Powershell.PSReadline"
        )
        Tools = @(
            "Hayabusa", "PersistenceSniper", "YARA", "Wireshark"
        )
        ExternalTools = @(
            "Sysinternals", "NetworkTools"
        )
        ConfigTemplate = "network-config.yaml"
    }

    "DataBreach" = @{
        Description = "Data breach investigation and forensics"
        Priority = "Critical"
        Artifacts = @(
            "Windows.EventLogs.Hayabusa",
            "Windows.Forensics.UserAccessLogs",
            "Windows.Registry.RecentDocs",
            "Windows.Applications.Chrome.History",
            "Windows.Applications.Edge.History",
            "Windows.System.LoggedInUsers",
            "Windows.EventLogs.Authentication",
            "Windows.Forensics.NTFS.MFT",
            "Windows.Forensics.USN",
            "Windows.Network.NetstatEnriched",
            "Windows.System.Handles",
            "Windows.Forensics.Jumplists",
            "Windows.System.Powershell.PSReadline",
            "Windows.Forensics.FileCopy"
        )
        Tools = @(
            "Hayabusa", "LECmd", "JLECmd", "FTKImager", "LastActivityView"
        )
        ExternalTools = @(
            "NirSoft", "EricZimmerman", "ForensicsTools"
        )
        ConfigTemplate = "databreach-config.yaml"
    }

    "Complete" = @{
        Description = "Complete incident response toolkit"
        Priority = "Maximum"
        Artifacts = @("*")  # All available artifacts
        Tools = @("*")      # All available tools
        ExternalTools = @("*")  # All external tools
        ConfigTemplate = "complete-config.yaml"
    }
}

function New-PackageDirectory {
    param([string]$Path)

    if (Test-Path $Path) {
        Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
}

function Copy-VelociraptorCore {
    param([string]$PackagePath)

    Write-Host "📦 Adding Velociraptor core components..." -ForegroundColor Cyan

    # Copy main deployment scripts
    $coreFiles = @(
        "Deploy_Velociraptor_Standalone.ps1",
        "Deploy_Velociraptor_Server.ps1",
        "VelociraptorSetupScripts.psd1",
        "VelociraptorSetupScripts.psm1"
    )

    foreach ($file in $coreFiles) {
        if (Test-Path $file) {
            Copy-Item $file -Destination $PackagePath -Force -ErrorAction SilentlyContinue
        }
    }

    # Copy modules directory
    if (Test-Path "modules") {
        Copy-Item "modules" -Destination $PackagePath -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Copy scripts directory
    if (Test-Path "scripts") {
        Copy-Item "scripts" -Destination $PackagePath -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Copy GUI
    if (Test-Path "gui") {
        Copy-Item "gui" -Destination $PackagePath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Copy-Artifacts {
    param([string]$PackagePath, [string[]]$ArtifactList)

    Write-Host "📋 Adding artifacts..." -ForegroundColor Cyan

    $artifactPath = Join-Path $PackagePath "artifacts"
    New-Item -ItemType Directory -Path $artifactPath -Force -ErrorAction SilentlyContinue | Out-Null

    if ($ArtifactList -contains "*") {
        # Copy all artifacts
        if (Test-Path "content/exchange/artifacts") {
            Copy-Item "content/exchange/artifacts/*" -Destination $artifactPath -Force -ErrorAction SilentlyContinue
        }
    } else {
        # Copy specific artifacts
        foreach ($artifact in $ArtifactList) {
            $artifactFile = "$artifact.yaml"
            $sourcePath = "content/exchange/artifacts/$artifactFile"

            if (Test-Path $sourcePath) {
                Copy-Item $sourcePath -Destination $artifactPath -Force -ErrorAction SilentlyContinue
            } else {
                Write-Warning "Artifact not found: $artifactFile"
            }
        }
    }
}

function Copy-Tools {
    param([string]$PackagePath, [string[]]$ToolList, [string[]]$ExternalToolList)

    Write-Host "🔧 Adding tools..." -ForegroundColor Cyan

    $toolsPath = Join-Path $PackagePath "tools"
    New-Item -ItemType Directory -Path $toolsPath -Force -ErrorAction SilentlyContinue | Out-Null

    # Copy internal tools
    if (Test-Path "tools") {
        if ($ToolList -contains "*") {
            Copy-Item "tools/*" -Destination $toolsPath -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            foreach ($tool in $ToolList) {
                $toolPath = "tools/$tool"
                if (Test-Path $toolPath) {
                    Copy-Item $toolPath -Destination $toolsPath -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    # Copy external tools
    if (Test-Path "tools-mirror") {
        $externalPath = Join-Path $toolsPath "external"
        New-Item -ItemType Directory -Path $externalPath -Force -ErrorAction SilentlyContinue | Out-Null

        if ($ExternalToolList -contains "*") {
            Copy-Item "tools-mirror/*" -Destination $externalPath -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            foreach ($toolCategory in $ExternalToolList) {
                $categoryPath = "tools-mirror/$toolCategory"
                if (Test-Path $categoryPath) {
                    Copy-Item $categoryPath -Destination $externalPath -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}

function New-ConfigurationTemplate {
    param([string]$PackagePath, [string]$TemplateName, [hashtable]$PackageInfo)

    Write-Host "⚙️ Creating configuration template..." -ForegroundColor Cyan

    $configPath = Join-Path $PackagePath "config"
    New-Item -ItemType Directory -Path $configPath -Force -ErrorAction SilentlyContinue | Out-Null

    $configContent = @"
# Velociraptor Configuration Template
# Package: $($PackageInfo.Description)
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

version:
  name: velociraptor
  version: "0.8.0"
  commit: "custom-build"
  build_time: "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"

Client:
  server_urls:
    - https://localhost:8000/
  ca_certificate: |
    # CA Certificate will be inserted here
  nonce: "$(New-Guid)"
  writeback_darwin: /opt/velociraptor/velociraptor.writeback.yaml
  writeback_linux: /opt/velociraptor/velociraptor.writeback.yaml
  writeback_windows: C:\Program Files\Velociraptor\velociraptor.writeback.yaml
  max_poll: 60
  max_poll_std: 5

API:
  bind_address: 0.0.0.0
  bind_port: 8001
  bind_scheme: tcp
  pinned_gw_name: GRPC_GW

GUI:
  bind_address: 0.0.0.0
  bind_port: 8889
  gw_certificate: |
    # GUI Certificate will be inserted here
  gw_private_key: |
    # GUI Private Key will be inserted here
  internal_cidr:
    - 127.0.0.1/12
    - 192.168.0.0/16
    - 10.0.0.0/8
    - 172.16.0.0/12

CA:
  private_key: |
    # CA Private Key will be inserted here

Frontend:
  bind_address: 0.0.0.0
  bind_port: 8000
  certificate: |
    # Frontend Certificate will be inserted here
  private_key: |
    # Frontend Private Key will be inserted here
  dyn_dns: {}

Datastore:
  implementation: FileBaseDataStore
  location: ./datastore
  filestore_directory: ./datastore

Logging:
  output_directory: ./logs
  separate_logs_per_component: true
  rotation_time: 604800
  max_age: 2678400

Monitoring:
  bind_address: 127.0.0.1
  bind_port: 8003

# Package-specific artifact definitions
artifacts:
  definitions:
"@

    # Add artifact definitions for this package
    if ($PackageInfo.Artifacts -notcontains "*") {
        foreach ($artifact in $PackageInfo.Artifacts) {
            $configContent += "`n    - name: $artifact"
        }
    }

    Set-Content -Path (Join-Path $configPath $TemplateName) -Value $configContent
}

function New-DeploymentScript {
    param([string]$PackagePath, [hashtable]$PackageInfo)

    Write-Host "🚀 Creating deployment script..." -ForegroundColor Cyan

    $deployScript = @"
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploy $($PackageInfo.Description) Package

.DESCRIPTION
    Automated deployment script for the $($PackageInfo.Description) incident response package.
    This script deploys Velociraptor with pre-configured artifacts and tools for this specific
    incident response scenario.

.PARAMETER InstallDir
    Installation directory for Velociraptor

.PARAMETER ConfigFile
    Configuration file to use

.PARAMETER Offline
    Run in offline mode using bundled tools

.EXAMPLE
    .\Deploy-$PackageType.ps1 -InstallDir "C:\Velociraptor" -Offline
#>

[CmdletBinding()]
param(
    [string]`$InstallDir = "C:\Program Files\Velociraptor",
    [string]`$ConfigFile = "config\$($PackageInfo.ConfigTemplate)",
    [switch]`$Offline
)

Write-Host "🚀 Deploying $($PackageInfo.Description) Package" -ForegroundColor Green
Write-Host "📁 Installation Directory: `$InstallDir" -ForegroundColor Cyan
Write-Host "⚙️ Configuration: `$ConfigFile" -ForegroundColor Cyan
Write-Host "🌐 Offline Mode: `$Offline" -ForegroundColor Cyan

# Set tool paths for offline mode
if (`$Offline) {
    `$env:VELOCIRAPTOR_TOOLS_PATH = Join-Path `$PSScriptRoot "tools"
    Write-Host "🔧 Using offline tools from: `$(`$env:VELOCIRAPTOR_TOOLS_PATH)" -ForegroundColor Yellow
}

# Import the main deployment module
Import-Module .\VelociraptorSetupScripts.psd1 -Force -ErrorAction SilentlyContinue

# Deploy based on configuration
if (Test-Path `$ConfigFile) {
    Deploy-VelociraptorServer -InstallDir `$InstallDir -ConfigPath `$ConfigFile -Force -ErrorAction SilentlyContinue
} else {
    Write-Warning "Configuration file not found: `$ConfigFile"
    Write-Information "Using default deployment..." -InformationAction Continue
    Deploy-VelociraptorServer -InstallDir `$InstallDir -Force -ErrorAction SilentlyContinue
}

Write-Host "✅ $($PackageInfo.Description) package deployment completed!" -ForegroundColor Green
"@

    Set-Content -Path (Join-Path $PackagePath "Deploy-$PackageType.ps1") -Value $deployScript
}

function New-PackageManifest {
    param([string]$PackagePath, [hashtable]$PackageInfo)

    Write-Host "📄 Creating package manifest..." -ForegroundColor Cyan

    $manifest = @{
        PackageType = $PackageType
        Description = $PackageInfo.Description
        Priority = $PackageInfo.Priority
        CreatedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Version = "1.0.0"
        Artifacts = $PackageInfo.Artifacts
        Tools = $PackageInfo.Tools
        ExternalTools = $PackageInfo.ExternalTools
        ConfigTemplate = $PackageInfo.ConfigTemplate
        DeploymentScript = "Deploy-$PackageType.ps1"
        Requirements = @{
            PowerShell = "5.1+"
            OS = "Windows 10+"
            Memory = "4GB"
            Disk = "10GB"
        }
    }

    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $PackagePath "package-manifest.json")
}

function New-ReadmeFile {
    param([string]$PackagePath, [hashtable]$PackageInfo)

    $readmeContent = @"
# $($PackageInfo.Description) Package

## Overview
This package contains a specialized Velociraptor deployment for $($PackageInfo.Description.ToLower()) scenarios.

## Contents
- **Velociraptor Core**: Main DFIR platform
- **Specialized Artifacts**: $($PackageInfo.Artifacts.Count) artifacts optimized for this scenario
- **Required Tools**: $($PackageInfo.Tools.Count) integrated tools
- **Configuration**: Pre-configured for optimal performance

## Quick Start
``````powershell
# Deploy the package
.\Deploy-$PackageType.ps1 -InstallDir "C:\Velociraptor" -Offline

# Or use the GUI
.\gui\VelociraptorGUI.ps1
``````

## Included Artifacts
$($PackageInfo.Artifacts | ForEach-Object { "- $_" } | Out-String)

## Included Tools
$($PackageInfo.Tools | ForEach-Object { "- $_" } | Out-String)

## Requirements
- PowerShell 5.1 or later
- Windows 10 or later
- 4GB RAM minimum
- 10GB disk space

## Support
For support and documentation, visit the main repository.
"@

    Set-Content -Path (Join-Path $PackagePath "README.md") -Value $readmeContent
}

# Main execution
Write-Host "🏗️ Building $PackageType Incident Response Package" -ForegroundColor Green

if (-not $IncidentPackages.ContainsKey($PackageType)) {
    Write-Error "Unknown package type: $PackageType"
    exit 1
}

$packageInfo = $IncidentPackages[$PackageType]
$packagePath = Join-Path $OutputDirectory "$PackageType-Package"

# Create package directory
New-PackageDirectory -Path $packagePath

# Build package components
Copy-VelociraptorCore -PackagePath $packagePath
Copy-Artifacts -PackagePath $packagePath -ArtifactList $packageInfo.Artifacts
Copy-Tools -PackagePath $packagePath -ToolList $packageInfo.Tools -ExternalToolList $packageInfo.ExternalTools
New-ConfigurationTemplate -PackagePath $packagePath -TemplateName $packageInfo.ConfigTemplate -PackageInfo $packageInfo
New-DeploymentScript -PackagePath $packagePath -PackageInfo $packageInfo
New-PackageManifest -PackagePath $packagePath -PackageInfo $packageInfo
New-ReadmeFile -PackagePath $packagePath -PackageInfo $packageInfo

# Create portable package if requested
if ($CreatePortable) {
    Write-Host "📦 Creating portable package..." -ForegroundColor Cyan
    $zipPath = "$packagePath.zip"
    Compress-Archive -Path $packagePath -DestinationPath $zipPath -Force -ErrorAction SilentlyContinue
    Write-Host "✅ Portable package created: $zipPath" -ForegroundColor Green
}

Write-Host "✅ $PackageType package built successfully!" -ForegroundColor Green
Write-Host "📁 Package location: $packagePath" -ForegroundColor Cyan
Write-Host "🚀 Deploy with: .\$PackageType-Package\Deploy-$PackageType.ps1" -ForegroundColor Yellow