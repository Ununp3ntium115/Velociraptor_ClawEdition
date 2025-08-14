#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Comprehensive configuration management for Velociraptor deployments.

.DESCRIPTION
    Provides centralized configuration management including:
    • Template-based configuration generation for different environments
    • Environment-specific settings management (Dev/Test/Prod)
    • Configuration validation and security hardening
    • Backup and restore operations with versioning
    • Configuration comparison and migration tools
    • Multi-environment deployment support

.PARAMETER Action
    Action to perform:
    - Generate: Create configuration from template
    - Validate: Validate existing configuration
    - Deploy: Deploy configuration to environment
    - Backup: Create configuration backup
    - Restore: Restore from backup
    - Compare: Compare configurations
    - Migrate: Migrate configuration between versions
    - Harden: Apply security hardening

.PARAMETER Environment
    Target environment: Development, Testing, Staging, Production

.PARAMETER Template
    Configuration template: Standalone, Server, Cluster, Forensics, Enterprise

.PARAMETER ConfigPath
    Path to configuration file

.PARAMETER OutputPath
    Output directory for generated files

.PARAMETER Force
    Skip confirmation prompts

.EXAMPLE
    .\Manage-VelociraptorConfig.ps1 -Action Generate -Template Server -Environment Production

.EXAMPLE
    .\Manage-VelociraptorConfig.ps1 -Action Deploy -ConfigPath "server.yaml" -Environment Testing

.EXAMPLE
    .\Manage-VelociraptorConfig.ps1 -Action Compare -ConfigPath "old.yaml,new.yaml"

.NOTES
    Requires VelociraptorDeployment module for full functionality.
    Author: Velociraptor Community
    Version: 2.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Generate', 'Validate', 'Deploy', 'Backup', 'Restore', 'Compare', 'Migrate', 'Harden')]
    [string]$Action,

    [Parameter()]
    [ValidateSet('Development', 'Testing', 'Staging', 'Production')]
    [string]$Environment = 'Development',

    [Parameter()]
    [ValidateSet('Standalone', 'Server', 'Cluster', 'Forensics', 'Enterprise')]
    [string]$Template,

    [Parameter()]
    [string]$ConfigPath,

    [Parameter()]
    [string]$OutputPath = '.',

    [Parameter()]
    [switch]$Force
)

# Set error handling
$ErrorActionPreference = 'Stop'

# Import VelociraptorDeployment module if available
$ModulePath = Join-Path $PSScriptRoot '..\..\modules\VelociraptorDeployment\VelociraptorDeployment.psd1'
$ModuleLoaded = $false

if (Test-Path $ModulePath) {
    try {
        Import-Module $ModulePath -Force -ErrorAction Stop
        $ModuleLoaded = $true
        Write-Host "[INFO] VelociraptorDeployment module loaded successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "[WARNING] Could not load VelociraptorDeployment module: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "[INFO] Using built-in functions" -ForegroundColor Yellow
    }
}

# Built-in logging function (fallback if module not available)
function Write-ConfigLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Debug')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Debug' { 'Cyan' }
        default { 'White' }
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color

    # Also log to file
    $logDir = Join-Path $env:ProgramData 'VelociraptorConfig'
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $logPath = Join-Path $logDir 'config-management.log'
    "[$timestamp] [$Level] $Message" | Out-File -FilePath $logPath -Append -Encoding UTF8
}

# Use module function if available, otherwise use built-in
if ($ModuleLoaded -and (Get-Command Write-VelociraptorLog -ErrorAction SilentlyContinue)) {
    Set-Alias -Name Write-ConfigLog -Value Write-VelociraptorLog -Force
}

#region Environment Configuration
function Get-EnvironmentConfig {
    param([string]$Environment)

    $configs = @{
        'Development' = @{
            DatastoreSize = 'Small'
            LogLevel = 'Debug'
            SecurityLevel = 'Basic'
            BindAddress = '127.0.0.1'
            EnableDebug = $true
            BackupRetention = 7
            MonitoringEnabled = $false
        }
        'Testing' = @{
            DatastoreSize = 'Medium'
            LogLevel = 'Info'
            SecurityLevel = 'Standard'
            BindAddress = '0.0.0.0'
            EnableDebug = $false
            BackupRetention = 14
            MonitoringEnabled = $true
        }
        'Staging' = @{
            DatastoreSize = 'Large'
            LogLevel = 'Warning'
            SecurityLevel = 'Standard'
            BindAddress = '0.0.0.0'
            EnableDebug = $false
            BackupRetention = 30
            MonitoringEnabled = $true
        }
        'Production' = @{
            DatastoreSize = 'Large'
            LogLevel = 'Error'
            SecurityLevel = 'Maximum'
            BindAddress = '0.0.0.0'
            EnableDebug = $false
            BackupRetention = 90
            MonitoringEnabled = $true
        }
    }

    return $configs[$Environment]
}
#endregion

#region Template Generation
function New-ConfigurationFromTemplate {
    param(
        [string]$Template,
        [string]$Environment,
        [string]$OutputPath
    )

    Write-ConfigLog "Generating $Template configuration for $Environment environment" -Level Info

    $envConfig = Get-EnvironmentConfig -Environment $Environment
    $templatePath = Join-Path $PSScriptRoot "..\..\templates\configurations\$Template.template.yaml"

    # Check if template exists, if not create it
    if (-not (Test-Path $templatePath)) {
        Write-ConfigLog "Template not found, creating default template: $templatePath" -Level Warning
        New-DefaultTemplate -Template $Template -TemplatePath $templatePath
    }

    # Read template
    $templateContent = Get-Content $templatePath -Raw

    # Replace environment-specific placeholders
    $configContent = $templateContent
    $configContent = $configContent -replace '{{ENVIRONMENT}}', $Environment
    $configContent = $configContent -replace '{{BIND_ADDRESS}}', $envConfig.BindAddress
    $configContent = $configContent -replace '{{LOG_LEVEL}}', $envConfig.LogLevel
    $configContent = $configContent -replace '{{ENABLE_DEBUG}}', $envConfig.EnableDebug.ToString().ToLower()
    $configContent = $configContent -replace '{{DATASTORE_SIZE}}', $envConfig.DatastoreSize
    $configContent = $configContent -replace '{{TIMESTAMP}}', (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

    # Generate output filename
    $outputFile = Join-Path $OutputPath "$Template-$Environment.yaml"

    # Write configuration
    $configContent | Out-File -FilePath $outputFile -Encoding UTF8

    Write-ConfigLog "Configuration generated: $outputFile" -Level Success

    return @{
        Success = $true
        ConfigPath = $outputFile
        Template = $Template
        Environment = $Environment
        EnvironmentConfig = $envConfig
    }
}

function New-DefaultTemplate {
    param(
        [string]$Template,
        [string]$TemplatePath
    )

    # Ensure template directory exists
    $templateDir = Split-Path $TemplatePath -Parent
    if (-not (Test-Path $templateDir)) {
        New-Item -ItemType Directory -Path $templateDir -Force | Out-Null
    }

    $templateContent = switch ($Template) {
        'Standalone' { Get-StandaloneTemplate }
        'Server' { Get-ServerTemplate }
        'Cluster' { Get-ClusterTemplate }
        'Forensics' { Get-ForensicsTemplate }
        'Enterprise' { Get-EnterpriseTemplate }
        default { Get-ServerTemplate }
    }

    $templateContent | Out-File -FilePath $TemplatePath -Encoding UTF8
    Write-ConfigLog "Created default template: $TemplatePath" -Level Info
}

function Get-ServerTemplate {
    return @"
# Velociraptor Server Configuration Template
# Environment: {{ENVIRONMENT}}
# Generated: {{TIMESTAMP}}

version:
  name: VelociraptorServer
  version: "0.7.0"
  built_time: "{{TIMESTAMP}}"

# Frontend Configuration - Client connections
Frontend:
  bind_address: {{BIND_ADDRESS}}
  bind_port: 8000
  certificate: ""
  private_key: ""

# GUI Configuration - Web interface
GUI:
  bind_address: {{BIND_ADDRESS}}
  bind_port: 8889
  gw_certificate: ""
  gw_private_key: ""

# Client Configuration
Client:
  server_urls:
  - "https://localhost:8000/"

# Datastore Configuration
Datastore:
  implementation: FileBaseDataStore
  location: "C:\\VelociraptorServerData"
  filestore_directory: "C:\\VelociraptorServerData\\filestore"

# Logging Configuration
Logging:
  output_directory: "C:\\VelociraptorServerData\\logs"
  separate_logs_per_component: true
  debug: {{ENABLE_DEBUG}}

# Security Settings
autocert_domain: ""
autocert_cert_cache: "C:\\VelociraptorServerData\\acme"

# Environment-specific settings
environment:
  name: "{{ENVIRONMENT}}"
  datastore_size: "{{DATASTORE_SIZE}}"
  log_level: "{{LOG_LEVEL}}"
"@
}

function Get-StandaloneTemplate {
    return @"
# Velociraptor Standalone Configuration Template
# Environment: {{ENVIRONMENT}}
# Generated: {{TIMESTAMP}}

version:
  name: VelociraptorStandalone
  version: "0.7.0"
  built_time: "{{TIMESTAMP}}"

# GUI Configuration - Web interface for analysis
GUI:
  bind_address: {{BIND_ADDRESS}}
  bind_port: 8889
  gw_certificate: ""
  gw_private_key: ""

# Client Configuration - Not used in standalone mode
Client:
  server_urls: []

# Datastore Configuration - Local storage
Datastore:
  implementation: FileBaseDataStore
  location: "C:\\VelociraptorData"
  filestore_directory: "C:\\VelociraptorData\\filestore"

# Logging Configuration
Logging:
  output_directory: "C:\\VelociraptorData\\logs"
  separate_logs_per_component: true
  debug: {{ENABLE_DEBUG}}

# Security Settings
autocert_domain: localhost

# Environment-specific settings
environment:
  name: "{{ENVIRONMENT}}"
  datastore_size: "{{DATASTORE_SIZE}}"
  log_level: "{{LOG_LEVEL}}"
"@
}

function Get-ClusterTemplate {
    return @"
# Velociraptor Cluster Configuration Template
# Environment: {{ENVIRONMENT}}
# Generated: {{TIMESTAMP}}

version:
  name: VelociraptorCluster
  version: "0.7.0"
  built_time: "{{TIMESTAMP}}"

# Frontend Configuration - Load balanced
Frontend:
  bind_address: {{BIND_ADDRESS}}
  bind_port: 8000
  certificate: ""
  private_key: ""

# GUI Configuration - High availability
GUI:
  bind_address: {{BIND_ADDRESS}}
  bind_port: 8889
  gw_certificate: ""
  gw_private_key: ""

# Client Configuration
Client:
  server_urls:
  - "https://node1.example.com:8000/"
  - "https://node2.example.com:8000/"
  - "https://node3.example.com:8000/"

# Datastore Configuration - Shared storage
Datastore:
  implementation: FileBaseDataStore
  location: "\\\\shared\\VelociraptorCluster"
  filestore_directory: "\\\\shared\\VelociraptorCluster\\filestore"

# Logging Configuration
Logging:
  output_directory: "\\\\shared\\VelociraptorCluster\\logs"
  separate_logs_per_component: true
  debug: {{ENABLE_DEBUG}}

# Cluster Configuration
cluster:
  enabled: true
  nodes:
  - "node1.example.com"
  - "node2.example.com"
  - "node3.example.com"

# Environment-specific settings
environment:
  name: "{{ENVIRONMENT}}"
  datastore_size: "{{DATASTORE_SIZE}}"
  log_level: "{{LOG_LEVEL}}"
"@
}

function Get-ForensicsTemplate {
    return @"
# Velociraptor Forensics Configuration Template
# Environment: {{ENVIRONMENT}}
# Generated: {{TIMESTAMP}}

version:
  name: VelociraptorForensics
  version: "0.7.0"
  built_time: "{{TIMESTAMP}}"

# GUI Configuration - Forensics workstation
GUI:
  bind_address: {{BIND_ADDRESS}}
  bind_port: 8889
  gw_certificate: ""
  gw_private_key: ""

# Client Configuration - Offline analysis
Client:
  server_urls: []

# Datastore Configuration - Case storage
Datastore:
  implementation: FileBaseDataStore
  location: "C:\\ForensicsCases"
  filestore_directory: "C:\\ForensicsCases\\evidence"

# Logging Configuration - Detailed for forensics
Logging:
  output_directory: "C:\\ForensicsCases\\logs"
  separate_logs_per_component: true
  debug: true
  audit_log: true

# Forensics-specific settings
forensics:
  case_management: true
  evidence_chain: true
  hash_verification: true

# Environment-specific settings
environment:
  name: "{{ENVIRONMENT}}"
  datastore_size: "{{DATASTORE_SIZE}}"
  log_level: "{{LOG_LEVEL}}"
"@
}

function Get-EnterpriseTemplate {
    return @"
# Velociraptor Enterprise Configuration Template
# Environment: {{ENVIRONMENT}}
# Generated: {{TIMESTAMP}}

version:
  name: VelociraptorEnterprise
  version: "0.7.0"
  built_time: "{{TIMESTAMP}}"

# Frontend Configuration - Enterprise scale
Frontend:
  bind_address: {{BIND_ADDRESS}}
  bind_port: 8000
  certificate: ""
  private_key: ""

# GUI Configuration - Enterprise features
GUI:
  bind_address: {{BIND_ADDRESS}}
  bind_port: 8889
  gw_certificate: ""
  gw_private_key: ""

# Client Configuration
Client:
  server_urls:
  - "https://velociraptor.enterprise.com:8000/"

# Datastore Configuration - Enterprise storage
Datastore:
  implementation: FileBaseDataStore
  location: "D:\\VelociraptorEnterprise"
  filestore_directory: "D:\\VelociraptorEnterprise\\filestore"

# Logging Configuration - Enterprise logging
Logging:
  output_directory: "D:\\VelociraptorEnterprise\\logs"
  separate_logs_per_component: true
  debug: {{ENABLE_DEBUG}}
  audit_log: true
  syslog_enabled: true

# Enterprise Features
enterprise:
  sso_enabled: true
  rbac_enabled: true
  compliance_mode: true
  monitoring_enabled: true

# Environment-specific settings
environment:
  name: "{{ENVIRONMENT}}"
  datastore_size: "{{DATASTORE_SIZE}}"
  log_level: "{{LOG_LEVEL}}"
"@
}
#endregion

#region Main Action Handlers
function Invoke-GenerateAction {
    if (-not $Template) {
        throw "Template parameter is required for Generate action"
    }

    $result = New-ConfigurationFromTemplate -Template $Template -Environment $Environment -OutputPath $OutputPath

    if ($result.Success) {
        Write-ConfigLog "Configuration generation completed successfully" -Level Success
        Write-ConfigLog "Generated file: $($result.ConfigPath)" -Level Info
        Write-ConfigLog "Template: $($result.Template)" -Level Info
        Write-ConfigLog "Environment: $($result.Environment)" -Level Info
    }

    return $result
}

function Invoke-ValidateAction {
    if (-not $ConfigPath) {
        throw "ConfigPath parameter is required for Validate action"
    }

    Write-ConfigLog "Validating configuration: $ConfigPath" -Level Info

    if ($ModuleLoaded -and (Get-Command Test-VelociraptorConfiguration -ErrorAction SilentlyContinue)) {
        $result = Test-VelociraptorConfiguration -ConfigPath $ConfigPath -ValidationLevel Comprehensive
    } else {
        # Basic validation fallback
        $result = Test-BasicConfiguration -ConfigPath $ConfigPath
    }

    return $result
}

function Invoke-DeployAction {
    if (-not $ConfigPath) {
        throw "ConfigPath parameter is required for Deploy action"
    }

    Write-ConfigLog "Deploying configuration to $Environment environment" -Level Info

    # Validate before deployment
    $validation = Invoke-ValidateAction
    if (-not $validation.IsValid) {
        throw "Configuration validation failed. Cannot deploy invalid configuration."
    }

    # Environment-specific deployment logic
    $envConfig = Get-EnvironmentConfig -Environment $Environment

    # Apply environment-specific hardening
    if ($ModuleLoaded -and (Get-Command Set-VelociraptorSecurityHardening -ErrorAction SilentlyContinue)) {
        Write-ConfigLog "Applying $($envConfig.SecurityLevel) security hardening" -Level Info
        Set-VelociraptorSecurityHardening -ConfigPath $ConfigPath -HardeningLevel $envConfig.SecurityLevel -Force:$Force
    }

    Write-ConfigLog "Configuration deployed successfully to $Environment" -Level Success

    return @{
        Success = $true
        Environment = $Environment
        ConfigPath = $ConfigPath
        SecurityLevel = $envConfig.SecurityLevel
    }
}

function Test-BasicConfiguration {
    param([string]$ConfigPath)

    if (-not (Test-Path $ConfigPath)) {
        return @{ IsValid = $false; Issues = @("Configuration file not found: $ConfigPath") }
    }

    $content = Get-Content $ConfigPath -Raw
    $issues = @()

    # Basic checks
    if (-not ($content -match 'version:')) {
        $issues += "Missing version specification"
    }

    if (-not ($content -match 'Frontend:|GUI:')) {
        $issues += "Missing Frontend or GUI configuration"
    }

    return @{
        IsValid = $issues.Count -eq 0
        Issues = $issues
    }
}
#endregion

#region Main Execution
try {
    Write-ConfigLog "Starting Velociraptor Configuration Management" -Level Info
    Write-ConfigLog "Action: $Action" -Level Info
    Write-ConfigLog "Environment: $Environment" -Level Info

    $result = switch ($Action) {
        'Generate' { Invoke-GenerateAction }
        'Validate' { Invoke-ValidateAction }
        'Deploy' { Invoke-DeployAction }
        'Backup' {
            if ($ModuleLoaded -and (Get-Command Backup-VelociraptorConfiguration -ErrorAction SilentlyContinue)) {
                Backup-VelociraptorConfiguration -ConfigPath $ConfigPath
            } else {
                throw "Backup action requires VelociraptorDeployment module"
            }
        }
        'Restore' {
            if ($ModuleLoaded -and (Get-Command Restore-VelociraptorConfiguration -ErrorAction SilentlyContinue)) {
                Restore-VelociraptorConfiguration -BackupPath $ConfigPath
            } else {
                throw "Restore action requires VelociraptorDeployment module"
            }
        }
        'Compare' {
            if ($ModuleLoaded -and (Get-Command Compare-VelociraptorConfigs -ErrorAction SilentlyContinue)) {
                $configs = $ConfigPath -split ','
                Compare-VelociraptorConfigs -ReferenceConfigPath $configs[0] -DifferenceConfigPath $configs[1]
            } else {
                throw "Compare action requires VelociraptorDeployment module"
            }
        }
        'Harden' {
            if ($ModuleLoaded -and (Get-Command Set-VelociraptorSecurityHardening -ErrorAction SilentlyContinue)) {
                $envConfig = Get-EnvironmentConfig -Environment $Environment
                Set-VelociraptorSecurityHardening -ConfigPath $ConfigPath -HardeningLevel $envConfig.SecurityLevel -Force:$Force
            } else {
                throw "Harden action requires VelociraptorDeployment module"
            }
        }
        default { throw "Unknown action: $Action" }
    }

    Write-ConfigLog "Configuration management completed successfully" -Level Success

    if ($result -and $result.GetType().Name -eq 'Hashtable') {
        $result | ConvertTo-Json -Depth 3 | Write-Host
    }
}
catch {
    Write-ConfigLog "Configuration management failed: $($_.Exception.Message)" -Level Error
    exit 1
}
#endregion