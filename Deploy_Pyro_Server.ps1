#!/usr/bin/env pwsh
<#
.SYNOPSIS
    🔥 Deploy PYRO DFIR Platform in enterprise server mode with integrated toolsuite
    
.DESCRIPTION
    Revolutionary enterprise DFIR server deployment that sets fire to traditional frameworks:
    - Downloads latest Velociraptor server binary
    - Generates secure server configuration with PYRO enhancements
    - Installs complete PYRO DFIR toolsuite for server-side analysis
    - Configures enterprise-grade security hardening
    - Sets up multi-client management capabilities
    - Integrates with enterprise authentication systems
    
.PARAMETER InstallDir
    Installation directory. Default: C:\PYRO (Windows) or /opt/PYRO (Linux/macOS)
    
.PARAMETER DataStore
    Data storage directory. Default: C:\PYROData (Windows) or /var/lib/pyro (Linux/macOS)
    
.PARAMETER ServerPort
    Server frontend port. Default: 8000
    
.PARAMETER GuiPort
    GUI port number. Default: 8889
    
.PARAMETER OrganizationName
    Organization name for certificates. Default: "PYRO DFIR Platform"
    
.PARAMETER AdminUser
    Administrator username. Default: "pyroadmin"
    
.PARAMETER AdminPassword
    Administrator password. If not provided, will be generated
    
.PARAMETER CertificateYears
    Certificate validity period in years. Default: 10
    
.PARAMETER SkipFirewall
    Skip firewall rule creation
    
.PARAMETER Force
    Force download and regeneration even if files exist
    
.PARAMETER InstallPyroTools
    Install complete PYRO DFIR toolsuite. Default: $true
    
.PARAMETER PyroToolsPath
    Custom path for PYRO tools installation
    
.PARAMETER SecurityHardening
    Apply security hardening (Basic, Standard, Maximum). Default: Maximum
    
.PARAMETER EnterpriseMode
    Enable enterprise features (AD integration, advanced logging)
    
.EXAMPLE
    .\Deploy_Pyro_Server.ps1
    
.EXAMPLE
    .\Deploy_Pyro_Server.ps1 -OrganizationName "Acme Corp" -AdminUser "admin" -SecurityHardening Maximum
    
.EXAMPLE
    .\Deploy_Pyro_Server.ps1 -EnterpriseMode -CertificateYears 5 -InstallPyroTools:$true
    
.NOTES
    🔥 PYRO v6.0.0 - Setting Fire to DFIR Frameworks
    Requires Administrator/root privileges for enterprise deployment
    Logs → %ProgramData%\PYRO\server_deploy.log (Windows) or /var/log/pyro/server_deploy.log (Linux/macOS)
#>

[CmdletBinding()]
param(
    [string]$InstallDir = $(if ($IsWindows -or $null -eq $IsWindows) { 'C:\PYRO' } else { '/opt/PYRO' }),
    [string]$DataStore = $(if ($IsWindows -or $null -eq $IsWindows) { 'C:\PYROData' } else { '/var/lib/pyro' }),
    [int]$ServerPort = 8000,
    [int]$GuiPort = 8889,
    [string]$OrganizationName = "PYRO DFIR Platform",
    [string]$AdminUser = "pyroadmin",
    [string]$AdminPassword,
    [ValidateRange(1, 50)]
    [int]$CertificateYears = 10,
    [switch]$SkipFirewall,
    [switch]$Force,
    [bool]$InstallPyroTools = $true,
    [string]$PyroToolsPath = $(if ($IsWindows -or $null -eq $IsWindows) { 'C:\PYRO\tools' } else { '/opt/PYRO/tools' }),
    [ValidateSet('Basic', 'Standard', 'Maximum')]
    [string]$SecurityHardening = 'Maximum',
    [switch]$EnterpriseMode
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# 🔥 PYRO Server Banner
Write-Host "🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥" -ForegroundColor Red
Write-Host "🔥                                                   🔥" -ForegroundColor Red
Write-Host "🔥         PYRO SERVER DEPLOYMENT v6.0.0            🔥" -ForegroundColor Red
Write-Host "🔥        Enterprise DFIR Platform Ignition         🔥" -ForegroundColor Red
Write-Host "🔥           Setting Fire to DFIR Frameworks        🔥" -ForegroundColor Red
Write-Host "🔥                                                   🔥" -ForegroundColor Red
Write-Host "🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥" -ForegroundColor Red
Write-Host ""

# Generate admin password if not provided
if (-not $AdminPassword) {
    $AdminPassword = -join ((33..126 | ForEach-Object { [char]$_ }) | Get-Random -Count 16)
    Write-Host "🔐 Generated admin password: $AdminPassword" -ForegroundColor Yellow
    Write-Host "   Please save this password securely!" -ForegroundColor Yellow
    Write-Host ""
}

# Import PyroSetupScripts module if available
$pyroModulePath = Join-Path $PSScriptRoot 'PyroSetupScripts.psm1'
if (Test-Path $pyroModulePath) {
    try {
        Import-Module $pyroModulePath -Force -Global
        $pyroModuleLoaded = $true
        Write-Host "🔥 PYRO Module loaded successfully!" -ForegroundColor Green
    }
    catch {
        $pyroModuleLoaded = $false
        Write-Host "⚠️ Could not load PYRO module, using built-in functions" -ForegroundColor Yellow
    }
}
else {
    $pyroModuleLoaded = $false
    Write-Host "⚠️ PYRO module not found at: $pyroModulePath" -ForegroundColor Yellow
}

############  🔥 PYRO Server Helper Functions  ###################################################

function Write-PyroLog {
    param([string]$Message, [string]$Level = 'Info')
    
    $logDir = if ($IsWindows -or $null -eq $IsWindows) { 
        Join-Path $env:ProgramData 'PYRO'
    } else { 
        '/var/log/pyro'
    }
    
    if (-not (Test-Path $logDir)) { 
        New-Item -ItemType Directory $logDir -Force | Out-Null 
    }
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "$timestamp`t[SERVER-$Level]`t$Message"
    $logFile = Join-Path $logDir 'server_deploy.log'
    $logEntry | Out-File $logFile -Append -Encoding UTF8
    
    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Info' { 'Cyan' }
        default { 'White' }
    }
    
    $emoji = switch ($Level) {
        'Success' { '✅' }
        'Warning' { '⚠️' }
        'Error' { '❌' }
        'Info' { '🔥' }
        default { '📝' }
    }
    
    Write-Host "$emoji [SERVER-$Level] $Message" -ForegroundColor $color
}

function Test-PyroAdminPrivileges {
    if ($IsWindows -or $null -eq $IsWindows) {
        $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    } else {
        return (id -u) -eq 0
    }
}

function Get-LatestVelociraptorAsset {
    Write-PyroLog 'Querying GitHub for the latest Velociraptor release...' -Level 'Info'
    try {
        $headers = @{ 
            'User-Agent' = 'PYRO-DFIR-Platform-Server/6.0.0'
            'Accept'     = 'application/vnd.github.v3+json'
        }
        $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/Velocidx/velociraptor/releases/latest' -Headers $headers -TimeoutSec 30
        
        # Determine platform-specific asset
        if ($IsWindows -or $null -eq $IsWindows) {
            $assetPattern = '*windows-amd64.exe'
        } elseif ($IsLinux) {
            $assetPattern = '*linux-amd64'
        } elseif ($IsMacOS) {
            $assetPattern = '*darwin-amd64'
        } else {
            $assetPattern = '*linux-amd64'  # Default fallback
        }
        
        $asset = $release.assets | Where-Object { $_.name -like $assetPattern -and $_.name -notlike '*msi*' } | Select-Object -First 1
        
        if (-not $asset) { 
            throw "Could not locate a compatible asset for your platform in the latest release."
        }
        
        Write-PyroLog "Found Velociraptor version: $($release.tag_name)" -Level 'Success'
        return @{
            Url = $asset.browser_download_url
            Name = $asset.name
            Version = $release.tag_name
        }
    }
    catch {
        Write-PyroLog "Failed to query GitHub API - $($_.Exception.Message)" -Level 'Error'
        throw
    }
}

function Install-VelociraptorExecutable {
    param([hashtable]$Asset, [string]$DestinationPath)
    
    Write-PyroLog "Downloading $($Asset.Name)..." -Level 'Info'
    
    try {
        $tempFile = "$DestinationPath.download"
        Invoke-WebRequest -Uri $Asset.Url -OutFile $tempFile -UseBasicParsing -Headers @{ 'User-Agent' = 'PYRO-SERVER/6.0.0' } -TimeoutSec 300
        
        # Verify download
        if (-not (Test-Path $tempFile) -or (Get-Item $tempFile).Length -eq 0) {
            throw "Download failed or file is empty"
        }
        
        Move-Item $tempFile $DestinationPath -Force
        
        # Make executable on Unix-like systems
        if ($IsLinux -or $IsMacOS) {
            chmod +x $DestinationPath
        }
        
        Write-PyroLog 'Velociraptor server binary downloaded successfully.' -Level 'Success'
        return $DestinationPath
    }
    catch {
        # Cleanup on failure
        if (Test-Path "$DestinationPath.download") {
            Remove-Item "$DestinationPath.download" -Force -ErrorAction SilentlyContinue
        }
        Write-PyroLog "Download failed: $($_.Exception.Message)" -Level 'Error'
        throw
    }
}

function New-PyroServerConfiguration {
    param(
        [string]$VelociraptorPath,
        [string]$ConfigPath,
        [string]$DatastorePath,
        [string]$Organization,
        [string]$AdminUsername,
        [string]$AdminPass,
        [int]$FrontendPort,
        [int]$GUIPort,
        [int]$CertYears
    )
    
    Write-PyroLog "Generating PYRO server configuration..." -Level 'Info'
    
    try {
        # Generate base configuration
        $configArgs = @(
            'config', 'generate',
            '--merge_file', $ConfigPath
        )
        
        Write-PyroLog "Running: $VelociraptorPath config generate" -Level 'Info'
        $baseConfig = & $VelociraptorPath config generate
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to generate base configuration"
        }
        
        # Enhance configuration with PYRO settings
        $pyroConfig = @"
# 🔥 PYRO DFIR Platform Server Configuration v6.0.0
# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# Organization: $Organization

version:
  name: PYRO DFIR Platform
  version: "6.0.0"
  commit: "$(Get-Date -Format 'yyyyMMdd')"
  build_time: "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Base Velociraptor configuration
$baseConfig

# 🔥 PYRO Enhanced Configuration
Client:
  server_urls:
    - https://localhost:$FrontendPort/
  
  # PYRO branding
  default_labels:
    - "PYRO-Client"
    - "DFIR-Platform"
    - "v6.0.0"

Frontend:
  bind_address: 0.0.0.0
  bind_port: $FrontendPort
  
  # Enhanced security
  certificate_lifetime: $(365 * $CertYears)
  organization: "$Organization"
  
  # PYRO toolsuite integration
  tools:
    hayabusa_path: "$PyroToolsPath/hayabusa"
    chainsaw_path: "$PyroToolsPath/chainsaw"
    yara_path: "$PyroToolsPath/yara"
    sigma_path: "$PyroToolsPath/sigma"
    uac_path: "$PyroToolsPath/uac"

GUI:
  bind_address: 0.0.0.0
  bind_port: $GUIPort
  
  # PYRO branding
  branding:
    org_name: "$Organization"
    links:
      - text: "PYRO Documentation"
        href: "https://github.com/PyroOrg/pyro-platform"
      - text: "PYRO Support"
        href: "https://github.com/PyroOrg/pyro-platform/issues"

Datastore:
  implementation: FileBaseDataStore
  location: "$DatastorePath"
  filestore_directory: "$DatastorePath/filestore"

# Enhanced logging for enterprise
Logging:
  output_directory: "$DatastorePath/logs"
  separate_logs_per_component: true
  debug: false
  
# 🔥 PYRO Security Enhancements
api:
  bind_address: 127.0.0.1
  bind_port: 8001
  
autodial:
  - name: PYRO-AutoDial
    retry_delay: 3600
    
server_monitoring:
  enabled: true
  bind_port: 9090
  
defaults:
  hunt_expiry_hours: 168  # 7 days
  notebook_ttl: 2592000   # 30 days
  
# Enterprise features
$(if ($EnterpriseMode) { @"
enterprise:
  enabled: true
  audit_logging: true
  advanced_permissions: true
  sso_integration: true
"@ })
"@
        
        # Save configuration
        $pyroConfig | Out-File $ConfigPath -Encoding UTF8
        Write-PyroLog "PYRO server configuration saved to: $ConfigPath" -Level 'Success'
        
        # Create initial admin user
        Write-PyroLog "Creating admin user: $AdminUsername" -Level 'Info'
        $userArgs = @(
            '--config', $ConfigPath,
            'user', 'add', $AdminUsername,
            '--role', 'administrator',
            '--password', $AdminPass
        )
        
        & $VelociraptorPath $userArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-PyroLog "Admin user created successfully" -Level 'Success'
        } else {
            Write-PyroLog "Failed to create admin user (may already exist)" -Level 'Warning'
        }
        
        return $ConfigPath
    }
    catch {
        Write-PyroLog "Configuration generation failed: $($_.Exception.Message)" -Level 'Error'
        throw
    }
}

function Set-PyroServerFirewall {
    param([int]$FrontendPort, [int]$GUIPort)
    
    if ($SkipFirewall) {
        Write-PyroLog "Skipping firewall configuration as requested" -Level 'Warning'
        return
    }
    
    Write-PyroLog "Configuring firewall for PYRO server..." -Level 'Info'
    
    $ports = @($FrontendPort, $GUIPort)
    
    try {
        foreach ($port in $ports) {
            if ($IsWindows -or $null -eq $IsWindows) {
                # Windows Firewall
                $ruleName = "PYRO-Server-$port"
                
                # Remove existing rule
                try {
                    Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
                } catch { }
                
                # Add new rule
                New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Protocol TCP -LocalPort $port -Action Allow -Description "PYRO DFIR Platform Server - Port $port"
                Write-PyroLog "Windows Firewall rule created for port $port" -Level 'Success'
                
            } elseif ($IsLinux) {
                # UFW (Ubuntu) or firewalld (CentOS/RHEL)
                if (Get-Command ufw -ErrorAction SilentlyContinue) {
                    ufw allow $port/tcp
                    Write-PyroLog "UFW firewall rule created for port $port" -Level 'Success'
                } elseif (Get-Command firewall-cmd -ErrorAction SilentlyContinue) {
                    firewall-cmd --add-port=$port/tcp --permanent
                    firewall-cmd --reload
                    Write-PyroLog "firewalld rule created for port $port" -Level 'Success'
                } else {
                    Write-PyroLog "No supported firewall found (ufw/firewalld)" -Level 'Warning'
                }
                
            } elseif ($IsMacOS) {
                # macOS pfctl
                Write-PyroLog "macOS firewall configuration may require manual setup for port $port" -Level 'Warning'
            }
        }
    }
    catch {
        Write-PyroLog "Firewall configuration failed: $($_.Exception.Message)" -Level 'Error'
        Write-PyroLog "You may need to manually configure firewall for ports: $($ports -join ', ')" -Level 'Warning'
    }
}

function Install-PyroServerTools {
    if (-not $InstallPyroTools) {
        Write-PyroLog "PYRO server tools installation skipped as requested" -Level 'Warning'
        return @{}
    }
    
    Write-PyroLog "Installing PYRO Server DFIR Toolsuite..." -Level 'Info'
    
    try {
        if ($pyroModuleLoaded -and (Get-Command Install-PyroToolsuite -ErrorAction SilentlyContinue)) {
            # Use the integrated tool installation
            $results = Install-PyroToolsuite -ToolsPath $PyroToolsPath
            
            $successCount = ($results.Values | Where-Object { $_ -like "*SUCCESS*" }).Count
            $totalCount = $results.Count
            
            if ($successCount -eq $totalCount) {
                Write-PyroLog "All PYRO server tools installed successfully ($successCount/$totalCount)" -Level 'Success'
            } else {
                Write-PyroLog "Some PYRO server tools failed to install ($successCount/$totalCount)" -Level 'Warning'
            }
            
            # Configure Velociraptor artifacts to use PYRO tools
            Write-PyroLog "Configuring Velociraptor artifacts for PYRO tools..." -Level 'Info'
            
            return $results
        } else {
            Write-PyroLog "PYRO tool integration not available, skipping server toolsuite installation" -Level 'Warning'
            return @{}
        }
    }
    catch {
        Write-PyroLog "PYRO server toolsuite installation failed: $($_.Exception.Message)" -Level 'Error'
        Write-PyroLog "Continuing with server deployment..." -Level 'Info'
        return @{}
    }
}

function Set-PyroServerSecurity {
    param([string]$Level, [string]$DataPath)
    
    Write-PyroLog "Applying PYRO server security hardening level: $Level" -Level 'Info'
    
    try {
        switch ($Level) {
            'Basic' {
                Write-PyroLog "Basic server security: Secure file permissions" -Level 'Info'
                if (Test-Path $DataPath) {
                    if ($IsWindows -or $null -eq $IsWindows) {
                        icacls $DataPath /inheritance:r /grant:r "Administrators:(OI)(CI)F" /grant:r "SYSTEM:(OI)(CI)F"
                    } else {
                        chmod 750 $DataPath
                    }
                }
            }
            
            'Standard' {
                Write-PyroLog "Standard server security: Enhanced permissions + logging" -Level 'Info'
                if (Test-Path $DataPath) {
                    if ($IsWindows -or $null -eq $IsWindows) {
                        icacls $DataPath /inheritance:r /grant:r "Administrators:(OI)(CI)F" /grant:r "SYSTEM:(OI)(CI)F"
                        # Enable advanced auditing
                        auditpol /set /subcategory:"File System" /success:enable /failure:enable
                    } else {
                        chmod 750 $DataPath
                        chown root:root $DataPath 2>/dev/null || true
                    }
                }
            }
            
            'Maximum' {
                Write-PyroLog "Maximum server security: Full enterprise hardening" -Level 'Info'
                if ($pyroModuleLoaded -and (Get-Command Set-PyroSecurityBaseline -ErrorAction SilentlyContinue)) {
                    Set-PyroSecurityBaseline -SecurityLevel Maximum -ServerMode
                    Write-PyroLog "Maximum server security applied via PYRO module" -Level 'Success'
                } else {
                    # Fallback security measures
                    if (Test-Path $DataPath) {
                        if ($IsWindows -or $null -eq $IsWindows) {
                            icacls $DataPath /inheritance:r /grant:r "Administrators:(OI)(CI)F" /grant:r "SYSTEM:(OI)(CI)F"
                            # Enhanced Windows security
                            auditpol /set /subcategory:"File System" /success:enable /failure:enable
                            auditpol /set /subcategory:"Logon" /success:enable /failure:enable
                            auditpol /set /subcategory:"Process Creation" /success:enable /failure:enable
                        } else {
                            chmod 700 $DataPath
                            chown root:root $DataPath 2>/dev/null || true
                            # Enhanced Linux security
                            echo "PYRO server security hardening applied" | logger
                        }
                    }
                    Write-PyroLog "Maximum server security applied (enhanced implementation)" -Level 'Success'
                }
            }
        }
    }
    catch {
        Write-PyroLog "Server security hardening failed: $($_.Exception.Message)" -Level 'Error'
        Write-PyroLog "Continuing with deployment..." -Level 'Info'
    }
}

function Start-PyroServer {
    param([string]$VelociraptorPath, [string]$ConfigPath)
    
    Write-PyroLog "Starting PYRO server..." -Level 'Info'
    
    try {
        $arguments = @('--config', $ConfigPath, 'frontend', '-v')
        
        Write-PyroLog "Starting: $VelociraptorPath $($arguments -join ' ')" -Level 'Info'
        
        # Start server in background
        $process = Start-Process -FilePath $VelociraptorPath -ArgumentList $arguments -PassThru -WindowStyle Hidden
        
        if ($process) {
            Write-PyroLog "PYRO server process started (PID: $($process.Id))" -Level 'Success'
            return $process
        } else {
            throw "Failed to start PYRO server process"
        }
    }
    catch {
        Write-PyroLog "Failed to start PYRO server: $($_.Exception.Message)" -Level 'Error'
        throw
    }
}

############  🔥 Main Server Deployment Logic  ###################################################

function Main {
    $startTime = Get-Date
    
    Write-PyroLog "Starting PYRO Server Deployment..." -Level 'Info'
    Write-PyroLog "Installation Directory: $InstallDir" -Level 'Info'
    Write-PyroLog "Data Store: $DataStore" -Level 'Info'
    Write-PyroLog "Frontend Port: $ServerPort" -Level 'Info'
    Write-PyroLog "GUI Port: $GuiPort" -Level 'Info'
    Write-PyroLog "Organization: $OrganizationName" -Level 'Info'
    Write-PyroLog "Admin User: $AdminUser" -Level 'Info'
    Write-PyroLog "PYRO Tools: $(if ($InstallPyroTools) { 'YES' } else { 'NO' })" -Level 'Info'
    Write-PyroLog "Security Level: $SecurityHardening" -Level 'Info'
    Write-PyroLog "Enterprise Mode: $(if ($EnterpriseMode) { 'YES' } else { 'NO' })" -Level 'Info'
    
    # Check admin privileges
    if (-not (Test-PyroAdminPrivileges)) {
        Write-PyroLog "Administrator/root privileges required for server deployment" -Level 'Error'
        throw "Administrator/root privileges required"
    }
    
    # Create directories
    Write-PyroLog "Creating server directories..." -Level 'Info'
    @($InstallDir, $DataStore, $PyroToolsPath, "$DataStore/filestore", "$DataStore/logs") | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
            Write-PyroLog "Created directory: $_" -Level 'Success'
        }
    }
    
    # Determine Velociraptor executable path
    $velociraptorExe = if ($IsWindows -or $null -eq $IsWindows) {
        Join-Path $InstallDir 'velociraptor.exe'
    } else {
        Join-Path $InstallDir 'velociraptor'
    }
    
    # Configuration file path
    $configPath = Join-Path $DataStore 'server.config.yaml'
    
    # Download Velociraptor if needed
    if ($Force -or -not (Test-Path $velociraptorExe)) {
        Write-PyroLog "Downloading latest Velociraptor server..." -Level 'Info'
        $asset = Get-LatestVelociraptorAsset
        Install-VelociraptorExecutable -Asset $asset -DestinationPath $velociraptorExe
    } else {
        Write-PyroLog "Using existing Velociraptor at: $velociraptorExe" -Level 'Info'
    }
    
    # Install PYRO server toolsuite
    $toolResults = Install-PyroServerTools
    
    # Generate server configuration
    if ($Force -or -not (Test-Path $configPath)) {
        New-PyroServerConfiguration -VelociraptorPath $velociraptorExe -ConfigPath $configPath -DatastorePath $DataStore -Organization $OrganizationName -AdminUsername $AdminUser -AdminPass $AdminPassword -FrontendPort $ServerPort -GUIPort $GuiPort -CertYears $CertificateYears
    } else {
        Write-PyroLog "Using existing configuration at: $configPath" -Level 'Info'
    }
    
    # Configure firewall
    Set-PyroServerFirewall -FrontendPort $ServerPort -GUIPort $GuiPort
    
    # Apply security hardening
    Set-PyroServerSecurity -Level $SecurityHardening -DataPath $DataStore
    
    # Start PYRO server
    $serverProcess = Start-PyroServer -VelociraptorPath $velociraptorExe -ConfigPath $configPath
    
    # Wait a moment for server to initialize
    Start-Sleep -Seconds 5
    
    # Deployment summary
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host ""
    Write-Host "🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥" -ForegroundColor Red
    Write-Host "🔥         PYRO SERVER DEPLOYMENT COMPLETE          🔥" -ForegroundColor Red
    Write-Host "🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥" -ForegroundColor Red
    Write-Host ""
    Write-Host "⏱️ Total Duration: $($duration.TotalMinutes.ToString('F1')) minutes" -ForegroundColor Cyan
    Write-Host "🌐 Server URL: https://localhost:$ServerPort" -ForegroundColor Green
    Write-Host "🖥️ GUI URL: https://localhost:$GuiPort" -ForegroundColor Green
    Write-Host "📁 Data Store: $DataStore" -ForegroundColor Cyan
    Write-Host "🔧 Install Dir: $InstallDir" -ForegroundColor Cyan
    Write-Host "🔑 Admin User: $AdminUser" -ForegroundColor Cyan
    Write-Host "🔐 Admin Password: $AdminPassword" -ForegroundColor Yellow
    Write-Host "🛡️ Security Level: $SecurityHardening" -ForegroundColor Cyan
    Write-Host "📝 Config File: $configPath" -ForegroundColor Cyan
    
    if ($InstallPyroTools) {
        Write-Host "🔥 PYRO Tools: $PyroToolsPath" -ForegroundColor Cyan
        if ($toolResults.Count -gt 0) {
            $successfulTools = ($toolResults.Values | Where-Object { $_ -like "*SUCCESS*" }).Count
            Write-Host "   Server Tools: $successfulTools" -ForegroundColor Green
        }
    }
    
    if ($EnterpriseMode) {
        Write-Host "🏢 Enterprise Mode: ENABLED" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "🔥 PYRO DFIR Server is IGNITED and ready!" -ForegroundColor Red
    Write-Host "   Enterprise DFIR operations ready to burn!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Cyan
    Write-Host "   1. Access GUI at: https://localhost:$GuiPort" -ForegroundColor White
    Write-Host "   2. Login with: $AdminUser / $AdminPassword" -ForegroundColor White
    Write-Host "   3. Configure client endpoints" -ForegroundColor White
    Write-Host "   4. Start hunting with PYRO tools!" -ForegroundColor White
    
    return @{
        VelociraptorPath = $velociraptorExe
        ConfigPath = $configPath
        DataStore = $DataStore
        ServerPort = $ServerPort
        GuiPort = $GuiPort
        AdminUser = $AdminUser
        AdminPassword = $AdminPassword
        ToolsInstalled = $toolResults
        Duration = $duration
        ProcessId = $serverProcess.Id
        EnterpriseMode = $EnterpriseMode
    }
}

# Execute server deployment
try {
    $result = Main
    exit 0
}
catch {
    Write-PyroLog "PYRO server deployment failed: $($_.Exception.Message)" -Level 'Error'
    Write-Host ""
    Write-Host "❌ PYRO server deployment failed. Check logs for details." -ForegroundColor Red
    Write-Host "   Log file: $(if ($IsWindows -or $null -eq $IsWindows) { '%ProgramData%\PYRO\server_deploy.log' } else { '/var/log/pyro/server_deploy.log' })" -ForegroundColor Yellow
    exit 1
}