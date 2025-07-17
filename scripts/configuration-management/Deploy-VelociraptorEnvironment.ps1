#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Deploy Velociraptor configurations to specific environments with validation and monitoring.

.DESCRIPTION
    Comprehensive deployment script that:
    • Validates environment-specific configurations
    • Applies security hardening based on environment
    • Manages service deployment and startup
    • Configures monitoring and alerting
    • Handles rollback scenarios
    • Provides deployment status reporting

.PARAMETER Environment
    Target environment: Development, Testing, Staging, Production

.PARAMETER ConfigPath
    Path to the configuration file to deploy

.PARAMETER ServiceAction
    Service action: Install, Start, Stop, Restart, Remove

.PARAMETER ValidateOnly
    Only validate the configuration without deploying

.PARAMETER Force
    Skip confirmation prompts and force deployment

.PARAMETER Rollback
    Rollback to previous configuration

.EXAMPLE
    .\Deploy-VelociraptorEnvironment.ps1 -Environment Production -ConfigPath "server-prod.yaml"

.EXAMPLE
    .\Deploy-VelociraptorEnvironment.ps1 -Environment Testing -ValidateOnly

.EXAMPLE
    .\Deploy-VelociraptorEnvironment.ps1 -Environment Production -Rollback

.NOTES
    Requires Administrator privileges for service operations.
    Author: Velociraptor Community
    Version: 2.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Development', 'Testing', 'Staging', 'Production')]
    [string]$Environment,
    
    [Parameter()]
    [string]$ConfigPath,
    
    [Parameter()]
    [ValidateSet('Install', 'Start', 'Stop', 'Restart', 'Remove')]
    [string]$ServiceAction = 'Start',
    
    [Parameter()]
    [switch]$ValidateOnly,
    
    [Parameter()]
    [switch]$Force,
    
    [Parameter()]
    [switch]$Rollback
)

# Set error handling
$ErrorActionPreference = 'Stop'

# Import required modules
$ModulePath = Join-Path $PSScriptRoot '..\..\modules\VelociraptorDeployment\VelociraptorDeployment.psd1'
if (Test-Path $ModulePath) {
    Import-Module $ModulePath -Force
    $ModuleLoaded = $true
} else {
    Write-Warning "VelociraptorDeployment module not found. Some features may be limited."
    $ModuleLoaded = $false
}

# Load environment configuration
$EnvConfigPath = Join-Path $PSScriptRoot 'environments.json'
if (-not (Test-Path $EnvConfigPath)) {
    throw "Environment configuration file not found: $EnvConfigPath"
}

$EnvConfig = Get-Content $EnvConfigPath -Raw | ConvertFrom-Json
$CurrentEnvConfig = $EnvConfig.environments.$Environment

if (-not $CurrentEnvConfig) {
    throw "Environment configuration not found for: $Environment"
}

#region Logging
function Write-DeployLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Debug')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Environment] [$Level] $Message"
    
    # Console output with colors
    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Debug' { 'Cyan' }
        default { 'White' }
    }
    
    Write-Host $logEntry -ForegroundColor $color
    
    # File logging
    $logDir = Join-Path $env:ProgramData "VelociraptorDeploy\$Environment"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    $logPath = Join-Path $logDir "deployment-$(Get-Date -Format 'yyyyMMdd').log"
    $logEntry | Out-File -FilePath $logPath -Append -Encoding UTF8
}
#endregion

#region Pre-deployment Checks
function Test-DeploymentPrerequisites {
    Write-DeployLog "Checking deployment prerequisites..." -Level Info
    
    $issues = @()
    
    # Check administrator privileges
    if ($ModuleLoaded) {
        if (-not (Test-VelociraptorAdminPrivileges -Quiet)) {
            $issues += "Administrator privileges required"
        }
    } else {
        $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
            $issues += "Administrator privileges required"
        }
    }
    
    # Check internet connectivity for downloads
    if ($ModuleLoaded -and (Get-Command Test-VelociraptorInternetConnection -ErrorAction SilentlyContinue)) {
        $connectivity = Test-VelociraptorInternetConnection -Quiet
        if (-not $connectivity) {
            $issues += "Internet connectivity required for downloads"
        }
    }
    
    # Check disk space
    $dataStorePath = $CurrentEnvConfig.paths.datastore
    $drive = Split-Path $dataStorePath -Qualifier
    if ($drive) {
        $diskSpace = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$drive'"
        $freeSpaceGB = [math]::Round($diskSpace.FreeSpace / 1GB, 2)
        
        $requiredSpace = switch ($CurrentEnvConfig.settings.datastore_size) {
            'Small' { 5 }
            'Medium' { 20 }
            'Large' { 100 }
            default { 10 }
        }
        
        if ($freeSpaceGB -lt $requiredSpace) {
            $issues += "Insufficient disk space. Required: ${requiredSpace}GB, Available: ${freeSpaceGB}GB"
        }
    }
    
    # Check required directories
    $requiredDirs = @(
        $CurrentEnvConfig.paths.datastore,
        $CurrentEnvConfig.paths.logs,
        $CurrentEnvConfig.paths.certificates,
        $CurrentEnvConfig.paths.backups
    )
    
    foreach ($dir in $requiredDirs) {
        $parentDir = Split-Path $dir -Parent
        if ($parentDir -and -not (Test-Path $parentDir)) {
            try {
                New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
                Write-DeployLog "Created directory: $parentDir" -Level Debug
            }
            catch {
                $issues += "Cannot create required directory: $parentDir"
            }
        }
    }
    
    if ($issues.Count -gt 0) {
        Write-DeployLog "Prerequisites check failed:" -Level Error
        $issues | ForEach-Object { Write-DeployLog "  - $_" -Level Error }
        return $false
    }
    
    Write-DeployLog "Prerequisites check passed" -Level Success
    return $true
}
#endregion

#region Configuration Management
function Deploy-Configuration {
    param([string]$ConfigPath)
    
    Write-DeployLog "Deploying configuration for $Environment environment" -Level Info
    
    # Validate configuration
    if ($ModuleLoaded -and (Get-Command Test-VelociraptorConfiguration -ErrorAction SilentlyContinue)) {
        Write-DeployLog "Validating configuration..." -Level Info
        $validation = Test-VelociraptorConfiguration -ConfigPath $ConfigPath -ValidationLevel Comprehensive
        
        if (-not $validation.IsValid) {
            Write-DeployLog "Configuration validation failed" -Level Error
            $validation.Issues | ForEach-Object { Write-DeployLog "  - $_" -Level Error }
            throw "Configuration validation failed"
        }
        
        Write-DeployLog "Configuration validation passed" -Level Success
        
        if ($validation.SecurityIssues.Count -gt 0) {
            Write-DeployLog "Security issues found: $($validation.SecurityIssues.Count)" -Level Warning
            if ($Environment -eq 'Production' -and -not $Force) {
                throw "Security issues found in Production configuration. Use -Force to override."
            }
        }
    }
    
    # Create backup of current configuration if it exists
    $targetConfigPath = Join-Path $CurrentEnvConfig.paths.datastore "server.yaml"
    if (Test-Path $targetConfigPath) {
        Write-DeployLog "Creating backup of current configuration..." -Level Info
        
        if ($ModuleLoaded -and (Get-Command Backup-VelociraptorConfiguration -ErrorAction SilentlyContinue)) {
            $backupResult = Backup-VelociraptorConfiguration -ConfigPath $targetConfigPath -BackupType ConfigOnly
            Write-DeployLog "Backup created: $($backupResult.BackupPath)" -Level Success
        } else {
            $backupPath = "$targetConfigPath.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
            Copy-Item $targetConfigPath $backupPath -Force
            Write-DeployLog "Backup created: $backupPath" -Level Success
        }
    }
    
    # Apply environment-specific hardening
    if ($ModuleLoaded -and (Get-Command Set-VelociraptorSecurityHardening -ErrorAction SilentlyContinue)) {
        Write-DeployLog "Applying $($CurrentEnvConfig.settings.security_level) security hardening..." -Level Info
        $hardeningResult = Set-VelociraptorSecurityHardening -ConfigPath $ConfigPath -HardeningLevel $CurrentEnvConfig.settings.security_level -Force:$Force
        
        if ($hardeningResult.Success) {
            Write-DeployLog "Security hardening applied: $($hardeningResult.ChangeCount) changes" -Level Success
        }
    }
    
    # Copy configuration to target location
    $targetDir = Split-Path $targetConfigPath -Parent
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    
    Copy-Item $ConfigPath $targetConfigPath -Force
    Write-DeployLog "Configuration deployed to: $targetConfigPath" -Level Success
    
    return $targetConfigPath
}

function Invoke-ServiceManagement {
    param(
        [string]$ConfigPath,
        [string]$Action
    )
    
    Write-DeployLog "Managing Velociraptor service: $Action" -Level Info
    
    $serviceName = "Velociraptor"
    $existingService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    
    switch ($Action) {
        'Install' {
            if ($existingService) {
                Write-DeployLog "Service already exists, stopping first..." -Level Info
                Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            }
            
            # Install service using Velociraptor executable
            $veloExe = Join-Path (Split-Path $ConfigPath -Parent) "velociraptor.exe"
            if (-not (Test-Path $veloExe)) {
                throw "Velociraptor executable not found: $veloExe"
            }
            
            $installResult = & $veloExe service install --config $ConfigPath 2>&1
            if ($LASTEXITCODE -ne 0) {
                throw "Service installation failed: $installResult"
            }
            
            Write-DeployLog "Service installed successfully" -Level Success
        }
        
        'Start' {
            if (-not $existingService) {
                throw "Service not found. Install the service first."
            }
            
            Start-Service -Name $serviceName
            Write-DeployLog "Service started successfully" -Level Success
        }
        
        'Stop' {
            if ($existingService -and $existingService.Status -eq 'Running') {
                Stop-Service -Name $serviceName -Force
                Write-DeployLog "Service stopped successfully" -Level Success
            } else {
                Write-DeployLog "Service is not running" -Level Info
            }
        }
        
        'Restart' {
            if ($existingService) {
                Restart-Service -Name $serviceName -Force
                Write-DeployLog "Service restarted successfully" -Level Success
            } else {
                throw "Service not found. Install the service first."
            }
        }
        
        'Remove' {
            if ($existingService) {
                Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
                
                $veloExe = Join-Path (Split-Path $ConfigPath -Parent) "velociraptor.exe"
                if (Test-Path $veloExe) {
                    & $veloExe service remove 2>&1 | Out-Null
                }
                
                Write-DeployLog "Service removed successfully" -Level Success
            } else {
                Write-DeployLog "Service not found" -Level Info
            }
        }
    }
}
#endregion

#region Main Execution
try {
    Write-DeployLog "Starting Velociraptor deployment for $Environment environment" -Level Info
    Write-DeployLog "Environment Description: $($CurrentEnvConfig.description)" -Level Info
    
    # Check prerequisites
    if (-not (Test-DeploymentPrerequisites)) {
        throw "Prerequisites check failed"
    }
    
    # Handle rollback scenario
    if ($Rollback) {
        Write-DeployLog "Initiating rollback procedure..." -Level Warning
        
        $backupDir = $CurrentEnvConfig.paths.backups
        if (Test-Path $backupDir) {
            $latestBackup = Get-ChildItem $backupDir -Filter "*.backup.*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            
            if ($latestBackup) {
                Write-DeployLog "Rolling back to: $($latestBackup.Name)" -Level Info
                
                if ($ModuleLoaded -and (Get-Command Restore-VelociraptorConfiguration -ErrorAction SilentlyContinue)) {
                    $restoreResult = Restore-VelociraptorConfiguration -BackupPath $latestBackup.FullName -Force:$Force
                    if ($restoreResult.Success) {
                        Write-DeployLog "Rollback completed successfully" -Level Success
                        Invoke-ServiceManagement -ConfigPath $restoreResult.RestorePath -Action 'Restart'
                    }
                } else {
                    $targetPath = Join-Path $CurrentEnvConfig.paths.datastore "server.yaml"
                    Copy-Item $latestBackup.FullName $targetPath -Force
                    Write-DeployLog "Rollback completed successfully" -Level Success
                    Invoke-ServiceManagement -ConfigPath $targetPath -Action 'Restart'
                }
            } else {
                throw "No backup found for rollback"
            }
        } else {
            throw "Backup directory not found: $backupDir"
        }
        
        return
    }
    
    # Validate configuration path
    if (-not $ConfigPath) {
        # Try to find configuration in standard locations
        $possiblePaths = @(
            "server-$($Environment.ToLower()).yaml",
            "standalone-$($Environment.ToLower()).yaml",
            Join-Path $CurrentEnvConfig.paths.datastore "server.yaml"
        )
        
        foreach ($path in $possiblePaths) {
            if (Test-Path $path) {
                $ConfigPath = $path
                break
            }
        }
        
        if (-not $ConfigPath) {
            throw "Configuration file not specified and none found in standard locations"
        }
    }
    
    if (-not (Test-Path $ConfigPath)) {
        throw "Configuration file not found: $ConfigPath"
    }
    
    Write-DeployLog "Using configuration: $ConfigPath" -Level Info
    
    # Validation-only mode
    if ($ValidateOnly) {
        Write-DeployLog "Validation-only mode enabled" -Level Info
        
        if ($ModuleLoaded -and (Get-Command Test-VelociraptorConfiguration -ErrorAction SilentlyContinue)) {
            $validation = Test-VelociraptorConfiguration -ConfigPath $ConfigPath -ValidationLevel Comprehensive
            
            if ($validation.IsValid) {
                Write-DeployLog "Configuration validation passed" -Level Success
                Write-DeployLog "Issues: $($validation.Issues.Count)" -Level Info
                Write-DeployLog "Warnings: $($validation.Warnings.Count)" -Level Info
                Write-DeployLog "Security Issues: $($validation.SecurityIssues.Count)" -Level Info
            } else {
                Write-DeployLog "Configuration validation failed" -Level Error
                $validation.Issues | ForEach-Object { Write-DeployLog "  - $_" -Level Error }
            }
        } else {
            Write-DeployLog "Basic validation only (module not available)" -Level Warning
            if (Test-Path $ConfigPath) {
                Write-DeployLog "Configuration file exists and is readable" -Level Success
            }
        }
        
        return
    }
    
    # Deploy configuration
    $deployedConfigPath = Deploy-Configuration -ConfigPath $ConfigPath
    
    # Manage service
    Invoke-ServiceManagement -ConfigPath $deployedConfigPath -Action $ServiceAction
    
    # Configure firewall rules
    if ($ModuleLoaded -and (Get-Command Add-VelociraptorFirewallRule -ErrorAction SilentlyContinue)) {
        Write-DeployLog "Configuring firewall rules..." -Level Info
        
        $frontendPort = $CurrentEnvConfig.ports.frontend
        $guiPort = $CurrentEnvConfig.ports.gui
        
        Add-VelociraptorFirewallRule -Port $frontendPort -RuleName "Velociraptor Frontend ($Environment)" -Force
        Add-VelociraptorFirewallRule -Port $guiPort -RuleName "Velociraptor GUI ($Environment)" -Force
        
        Write-DeployLog "Firewall rules configured" -Level Success
    }
    
    # Wait for service to start and verify
    if ($ServiceAction -in 'Install', 'Start', 'Restart') {
        Write-DeployLog "Waiting for service to start..." -Level Info
        
        if ($ModuleLoaded -and (Get-Command Wait-VelociraptorTcpPort -ErrorAction SilentlyContinue)) {
            $guiPort = $CurrentEnvConfig.ports.gui
            $portReady = Wait-VelociraptorTcpPort -Port $guiPort -TimeoutSeconds 60 -ShowProgress
            
            if ($portReady) {
                Write-DeployLog "Service is ready and listening on port $guiPort" -Level Success
                Write-DeployLog "GUI URL: https://localhost:$guiPort" -Level Info
            } else {
                Write-DeployLog "Service may not have started properly (port $guiPort not responding)" -Level Warning
            }
        } else {
            Start-Sleep -Seconds 10
            $service = Get-Service -Name "Velociraptor" -ErrorAction SilentlyContinue
            if ($service -and $service.Status -eq 'Running') {
                Write-DeployLog "Service is running" -Level Success
            } else {
                Write-DeployLog "Service status unknown" -Level Warning
            }
        }
    }
    
    Write-DeployLog "Deployment completed successfully for $Environment environment" -Level Success
    
    # Display deployment summary
    Write-DeployLog "Deployment Summary:" -Level Info
    Write-DeployLog "  Environment: $Environment" -Level Info
    Write-DeployLog "  Configuration: $deployedConfigPath" -Level Info
    Write-DeployLog "  Security Level: $($CurrentEnvConfig.settings.security_level)" -Level Info
    Write-DeployLog "  Service Action: $ServiceAction" -Level Info
    Write-DeployLog "  Frontend Port: $($CurrentEnvConfig.ports.frontend)" -Level Info
    Write-DeployLog "  GUI Port: $($CurrentEnvConfig.ports.gui)" -Level Info
}
catch {
    Write-DeployLog "Deployment failed: $($_.Exception.Message)" -Level Error
    
    # Attempt rollback on production failures
    if ($Environment -eq 'Production' -and -not $Rollback) {
        Write-DeployLog "Attempting automatic rollback for Production environment..." -Level Warning
        try {
            & $MyInvocation.MyCommand.Path -Environment $Environment -Rollback -Force
        }
        catch {
            Write-DeployLog "Automatic rollback failed: $($_.Exception.Message)" -Level Error
        }
    }
    
    exit 1
}
#endregion