<#
.SYNOPSIS
    Deploys Velociraptor on macOS systems.

.DESCRIPTION
    This script automates the deployment of Velociraptor DFIR framework on macOS.
    It handles downloading the appropriate binary (darwin/arm64 or darwin/amd64),
    configuration, launchd service installation, and firewall guidance.

.PARAMETER DeploymentType
    Type of deployment: Server, Standalone, or Client

.PARAMETER InstallPath
    Installation directory for the Velociraptor binary

.PARAMETER DataPath
    Data directory for Velociraptor datastore

.PARAMETER ConfigPath
    Path to configuration file (optional, will generate if not provided)

.PARAMETER GuiPort
    Port for the web GUI (default: 8889)

.PARAMETER FrontendPort
    Port for client connections (default: 8000)

.PARAMETER EnableService
    Whether to install and enable the launchd service

.PARAMETER Force
    Force reinstallation even if already installed

.EXAMPLE
    ./Deploy-VelociraptorMacOS.ps1 -DeploymentType Standalone

.EXAMPLE
    ./Deploy-VelociraptorMacOS.ps1 -DeploymentType Server -GuiPort 9999 -EnableService

.NOTES
    Requires macOS 12.0 or later
    Requires PowerShell 7.0 or later
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('Server', 'Standalone', 'Client')]
    [string]$DeploymentType = 'Standalone',

    [Parameter(Mandatory = $false)]
    [string]$InstallPath = '/usr/local/bin',

    [Parameter(Mandatory = $false)]
    [string]$DataPath = "$HOME/Library/Application Support/Velociraptor",

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath,

    [Parameter(Mandatory = $false)]
    [int]$GuiPort = 8889,

    [Parameter(Mandatory = $false)]
    [int]$FrontendPort = 8000,

    [Parameter(Mandatory = $false)]
    [switch]$EnableService,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Constants
$script:VelociraptorGitHubRepo = 'Velocidex/velociraptor'
$script:VelociraptorBinaryName = 'velociraptor'
$script:LaunchdLabel = 'com.velocidex.velociraptor'
$script:LaunchdPlistPath = "$HOME/Library/LaunchAgents/$script:LaunchdLabel.plist"
$script:LogPath = "$HOME/Library/Logs/Velociraptor"
$script:CachePath = "$HOME/Library/Caches/Velociraptor"
#endregion

#region Logging
function Write-VelociraptorLog {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS', 'DEBUG')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Create log directory if needed
    if (-not (Test-Path $script:LogPath)) {
        New-Item -Path $script:LogPath -ItemType Directory -Force | Out-Null
    }
    
    # Write to log file
    $logFile = Join-Path $script:LogPath "velociraptor_deployment.log"
    Add-Content -Path $logFile -Value $logEntry
    
    # Write to console with color
    switch ($Level) {
        'ERROR'   { Write-Host $logEntry -ForegroundColor Red }
        'WARN'    { Write-Host $logEntry -ForegroundColor Yellow }
        'SUCCESS' { Write-Host $logEntry -ForegroundColor Green }
        'DEBUG'   { Write-Host $logEntry -ForegroundColor Gray }
        default   { Write-Host $logEntry }
    }
}
#endregion

#region macOS Detection
function Test-MacOSPlatform {
    <#
    .SYNOPSIS
        Verifies we're running on macOS
    #>
    if (-not $IsMacOS) {
        Write-VelociraptorLog "This script is designed for macOS only. Detected: $($PSVersionTable.OS)" -Level ERROR
        throw "Platform not supported. This script requires macOS."
    }
    
    # Check macOS version
    $swVers = & sw_vers -productVersion
    $majorVersion = [int]($swVers.Split('.')[0])
    
    if ($majorVersion -lt 12) {
        Write-VelociraptorLog "macOS 12.0 or later required. Detected: $swVers" -Level ERROR
        throw "macOS version not supported."
    }
    
    Write-VelociraptorLog "Running on macOS $swVers" -Level INFO
    return $true
}

function Get-MacOSArchitecture {
    <#
    .SYNOPSIS
        Detects whether running on Apple Silicon or Intel
    #>
    $arch = & uname -m
    
    switch ($arch) {
        'arm64' { return 'darwin-arm64' }
        'x86_64' { return 'darwin-amd64' }
        default {
            Write-VelociraptorLog "Unknown architecture: $arch. Defaulting to amd64." -Level WARN
            return 'darwin-amd64'
        }
    }
}

function Get-MacOSSystemSpecs {
    <#
    .SYNOPSIS
        Gets real macOS system specifications using native tools
    #>
    Write-VelociraptorLog "Detecting macOS system specifications..." -Level INFO
    
    $specs = @{
        OS = ''
        OSVersion = ''
        Kernel = ''
        Architecture = ''
        CPUModel = ''
        CPUCores = 0
        MemoryGB = 0
        DiskTotalGB = 0
        DiskFreeGB = 0
        Hostname = ''
        Username = ''
    }
    
    # OS information
    $specs.OS = 'macOS'
    $specs.OSVersion = & sw_vers -productVersion
    $specs.Kernel = & uname -r
    $specs.Architecture = & uname -m
    $specs.Hostname = & hostname
    $specs.Username = $env:USER
    
    # CPU information via sysctl
    try {
        $specs.CPUModel = (& sysctl -n machdep.cpu.brand_string).Trim()
        $specs.CPUCores = [int](& sysctl -n hw.ncpu)
    }
    catch {
        Write-VelociraptorLog "Could not detect CPU info: $_" -Level WARN
        $specs.CPUModel = "Unknown"
        $specs.CPUCores = 1
    }
    
    # Memory via sysctl
    try {
        $memBytes = [long](& sysctl -n hw.memsize)
        $specs.MemoryGB = [math]::Round($memBytes / 1GB, 2)
    }
    catch {
        Write-VelociraptorLog "Could not detect memory: $_" -Level WARN
        $specs.MemoryGB = 0
    }
    
    # Disk space via df
    try {
        $dfOutput = & df -g / | Select-Object -Skip 1
        $dfParts = $dfOutput -split '\s+'
        $specs.DiskTotalGB = [int]$dfParts[1]
        $specs.DiskFreeGB = [int]$dfParts[3]
    }
    catch {
        Write-VelociraptorLog "Could not detect disk space: $_" -Level WARN
    }
    
    Write-VelociraptorLog "System specs: $($specs.CPUModel), $($specs.CPUCores) cores, $($specs.MemoryGB) GB RAM" -Level INFO
    
    return $specs
}
#endregion

#region Admin Privileges
function Test-MacOSAdminPrivileges {
    <#
    .SYNOPSIS
        Checks if current user has admin privileges on macOS
    #>
    
    # Method 1: Check if user is in admin group
    $groups = & id -Gn
    $isAdmin = $groups -match '\badmin\b'
    
    if (-not $isAdmin) {
        # Method 2: Check dseditgroup
        try {
            $result = & dseditgroup -o checkmember -m $env:USER admin 2>&1
            $isAdmin = $result -match 'yes'
        }
        catch {
            $isAdmin = $false
        }
    }
    
    # Method 3: Check if running as root
    $uid = [int](& id -u)
    $isRoot = $uid -eq 0
    
    if ($isAdmin -or $isRoot) {
        Write-VelociraptorLog "Admin privileges confirmed" -Level SUCCESS
        return $true
    }
    else {
        Write-VelociraptorLog "Current user does not have admin privileges" -Level WARN
        return $false
    }
}

function Request-AdminElevation {
    <#
    .SYNOPSIS
        Prompts for admin elevation if needed
    #>
    param([string]$Reason)
    
    Write-VelociraptorLog "Admin privileges required: $Reason" -Level WARN
    Write-Host ""
    Write-Host "This operation requires administrator privileges." -ForegroundColor Yellow
    Write-Host "You may be prompted for your password." -ForegroundColor Yellow
    Write-Host ""
    
    # Test sudo access
    try {
        & sudo -v 2>&1 | Out-Null
        return $true
    }
    catch {
        Write-VelociraptorLog "Failed to obtain admin privileges" -Level ERROR
        return $false
    }
}
#endregion

#region Firewall
function Set-MacOSFirewallRule {
    <#
    .SYNOPSIS
        Configures macOS firewall for Velociraptor
    #>
    param(
        [string]$BinaryPath,
        [int[]]$Ports
    )
    
    Write-VelociraptorLog "Configuring macOS firewall..." -Level INFO
    
    # Check if Application Firewall is enabled
    $firewallState = & /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>&1
    
    if ($firewallState -match 'enabled') {
        Write-VelociraptorLog "Application Firewall is enabled" -Level INFO
        
        # Add Velociraptor to allowed apps
        try {
            & sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add $BinaryPath 2>&1 | Out-Null
            & sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp $BinaryPath 2>&1 | Out-Null
            Write-VelociraptorLog "Added Velociraptor to firewall exceptions" -Level SUCCESS
        }
        catch {
            Write-VelociraptorLog "Could not configure firewall automatically: $_" -Level WARN
            Write-Host ""
            Write-Host "MANUAL STEP REQUIRED:" -ForegroundColor Yellow
            Write-Host "1. Open System Preferences > Security & Privacy > Firewall" -ForegroundColor Cyan
            Write-Host "2. Click 'Firewall Options'" -ForegroundColor Cyan
            Write-Host "3. Add Velociraptor and allow incoming connections" -ForegroundColor Cyan
            Write-Host ""
        }
    }
    else {
        Write-VelociraptorLog "Application Firewall is disabled - no configuration needed" -Level INFO
    }
    
    # Display port information
    Write-Host ""
    Write-Host "Velociraptor will use the following ports:" -ForegroundColor Cyan
    foreach ($port in $Ports) {
        Write-Host "  - Port $port" -ForegroundColor Cyan
    }
    Write-Host ""
}
#endregion

#region Download and Install
function Get-LatestVelociraptorRelease {
    <#
    .SYNOPSIS
        Gets the latest Velociraptor release from GitHub
    #>
    param([string]$Architecture)
    
    Write-VelociraptorLog "Fetching latest release information..." -Level INFO
    
    $apiUrl = "https://api.github.com/repos/$script:VelociraptorGitHubRepo/releases/latest"
    
    try {
        $release = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers @{
            'Accept' = 'application/vnd.github.v3+json'
            'User-Agent' = 'Velociraptor-Setup-Scripts'
        }
        
        # Find the macOS binary
        $asset = $release.assets | Where-Object { $_.name -match $Architecture -and $_.name -notmatch '\.sig$' } | Select-Object -First 1
        
        if (-not $asset) {
            throw "Could not find macOS binary ($Architecture) in release $($release.tag_name)"
        }
        
        Write-VelociraptorLog "Found release: $($release.tag_name)" -Level SUCCESS
        
        return @{
            Version = $release.tag_name
            DownloadUrl = $asset.browser_download_url
            FileName = $asset.name
            Size = $asset.size
        }
    }
    catch {
        Write-VelociraptorLog "Failed to fetch release: $_" -Level ERROR
        throw
    }
}

function Install-VelociraptorBinary {
    <#
    .SYNOPSIS
        Downloads and installs the Velociraptor binary
    #>
    param(
        [hashtable]$Release,
        [string]$InstallPath
    )
    
    Write-VelociraptorLog "Downloading Velociraptor $($Release.Version)..." -Level INFO
    
    # Create cache directory
    if (-not (Test-Path $script:CachePath)) {
        New-Item -Path $script:CachePath -ItemType Directory -Force | Out-Null
    }
    
    $downloadPath = Join-Path $script:CachePath $Release.FileName
    $binaryPath = Join-Path $InstallPath $script:VelociraptorBinaryName
    
    # Download
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Release.DownloadUrl -OutFile $downloadPath
        $ProgressPreference = 'Continue'
        Write-VelociraptorLog "Download complete: $downloadPath" -Level SUCCESS
    }
    catch {
        Write-VelociraptorLog "Download failed: $_" -Level ERROR
        throw
    }
    
    # Verify download
    $fileInfo = Get-Item $downloadPath
    if ($fileInfo.Length -ne $Release.Size) {
        Write-VelociraptorLog "Download size mismatch. Expected: $($Release.Size), Got: $($fileInfo.Length)" -Level ERROR
        throw "Download verification failed"
    }
    
    # Install (may require sudo)
    Write-VelociraptorLog "Installing to $InstallPath..." -Level INFO
    
    try {
        if (Test-MacOSAdminPrivileges) {
            # Direct copy if admin
            Copy-Item -Path $downloadPath -Destination $binaryPath -Force
            & chmod +x $binaryPath
        }
        else {
            # Use sudo
            & sudo cp $downloadPath $binaryPath
            & sudo chmod +x $binaryPath
        }
        
        Write-VelociraptorLog "Binary installed: $binaryPath" -Level SUCCESS
    }
    catch {
        Write-VelociraptorLog "Installation failed: $_" -Level ERROR
        throw
    }
    
    # Verify installation
    $version = & $binaryPath version 2>&1
    Write-VelociraptorLog "Installed version: $version" -Level INFO
    
    return $binaryPath
}
#endregion

#region Configuration
function New-VelociraptorConfig {
    <#
    .SYNOPSIS
        Generates Velociraptor configuration
    #>
    param(
        [string]$BinaryPath,
        [string]$DataPath,
        [string]$DeploymentType,
        [int]$GuiPort,
        [int]$FrontendPort
    )
    
    Write-VelociraptorLog "Generating configuration for $DeploymentType deployment..." -Level INFO
    
    # Ensure data directory exists
    if (-not (Test-Path $DataPath)) {
        New-Item -Path $DataPath -ItemType Directory -Force | Out-Null
    }
    
    $configDir = Join-Path $DataPath 'config'
    if (-not (Test-Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }
    
    $configFile = Join-Path $configDir 'server.config.yaml'
    
    # Generate config using velociraptor binary
    try {
        $configArgs = @(
            'config', 'generate'
            '-i'
        )
        
        # For non-interactive, we'll create a minimal config
        $minimalConfig = @"
version:
  name: "VelociraptorOrg"

Client:
  server_urls:
    - https://127.0.0.1:$FrontendPort/
  writeback_darwin: /etc/velociraptor/velociraptor.writeback.yaml

Frontend:
  bind_address: "0.0.0.0"
  bind_port: $FrontendPort

GUI:
  bind_address: "127.0.0.1"
  bind_port: $GuiPort

API:
  bind_address: "127.0.0.1"
  bind_port: 8001

Datastore:
  implementation: FileBaseDataStore
  location: "$DataPath"

Logging:
  output_directory: "$script:LogPath"
  separate_logs_per_component: true
"@
        
        Set-Content -Path $configFile -Value $minimalConfig
        Write-VelociraptorLog "Configuration saved: $configFile" -Level SUCCESS
    }
    catch {
        Write-VelociraptorLog "Config generation failed: $_" -Level ERROR
        throw
    }
    
    return $configFile
}
#endregion

#region Launchd Service
function Install-LaunchdService {
    <#
    .SYNOPSIS
        Installs Velociraptor as a launchd service
    #>
    param(
        [string]$BinaryPath,
        [string]$ConfigPath
    )
    
    Write-VelociraptorLog "Installing launchd service..." -Level INFO
    
    # Ensure LaunchAgents directory exists
    $launchAgentsDir = Split-Path $script:LaunchdPlistPath -Parent
    if (-not (Test-Path $launchAgentsDir)) {
        New-Item -Path $launchAgentsDir -ItemType Directory -Force | Out-Null
    }
    
    # Unload existing service if present
    if (Test-Path $script:LaunchdPlistPath) {
        try {
            & launchctl unload $script:LaunchdPlistPath 2>&1 | Out-Null
        }
        catch {
            Write-VelociraptorLog "Warning: Failed to unload launchd service at $script:LaunchdPlistPath. $($_.Exception.Message)" -Level WARNING
        }
        Remove-Item $script:LaunchdPlistPath -Force
    }
    
    # Create plist
    $plistContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$script:LaunchdLabel</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BinaryPath</string>
        <string>frontend</string>
        <string>--config</string>
        <string>$ConfigPath</string>
    </array>
    <key>RunAtLoad</key>
    <false/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    <key>StandardOutPath</key>
    <string>$script:LogPath/velociraptor.log</string>
    <key>StandardErrorPath</key>
    <string>$script:LogPath/velociraptor.error.log</string>
    <key>WorkingDirectory</key>
    <string>$DataPath</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
</dict>
</plist>
"@
    
    Set-Content -Path $script:LaunchdPlistPath -Value $plistContent
    Write-VelociraptorLog "Launchd plist created: $script:LaunchdPlistPath" -Level SUCCESS
    
    return $script:LaunchdPlistPath
}

function Start-LaunchdService {
    <#
    .SYNOPSIS
        Starts the Velociraptor launchd service
    #>
    
    Write-VelociraptorLog "Starting launchd service..." -Level INFO
    
    try {
        & launchctl load $script:LaunchdPlistPath
        Start-Sleep -Seconds 2
        
        # Verify service is running
        $status = & launchctl list | Select-String $script:LaunchdLabel
        
        if ($status) {
            Write-VelociraptorLog "Service started successfully" -Level SUCCESS
            return $true
        }
        else {
            Write-VelociraptorLog "Service may not have started properly" -Level WARN
            return $false
        }
    }
    catch {
        Write-VelociraptorLog "Failed to start service: $_" -Level ERROR
        return $false
    }
}

function Stop-LaunchdService {
    <#
    .SYNOPSIS
        Stops the Velociraptor launchd service
    #>
    
    Write-VelociraptorLog "Stopping launchd service..." -Level INFO
    
    try {
        & launchctl unload $script:LaunchdPlistPath 2>&1 | Out-Null
        Write-VelociraptorLog "Service stopped" -Level SUCCESS
        return $true
    }
    catch {
        Write-VelociraptorLog "Failed to stop service: $_" -Level WARN
        return $false
    }
}

function Test-ServiceRunning {
    <#
    .SYNOPSIS
        Checks if Velociraptor service is running
    #>
    
    $process = Get-Process -Name 'velociraptor' -ErrorAction SilentlyContinue
    return $null -ne $process
}

function Test-PortListening {
    <#
    .SYNOPSIS
        Checks if a port is listening
    #>
    param([int]$Port)
    
    try {
        $listener = & lsof -iTCP:$Port -sTCP:LISTEN 2>&1
        return $listener -match 'velociraptor'
    }
    catch {
        return $false
    }
}
#endregion

#region Main Deployment
function Invoke-VelociraptorDeployment {
    <#
    .SYNOPSIS
        Main deployment orchestration
    #>
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     VELOCIRAPTOR macOS DEPLOYMENT                            ║" -ForegroundColor Cyan
    Write-Host "║     Free For All First Responders                            ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        # Step 1: Platform verification
        Test-MacOSPlatform | Out-Null
        
        # Step 2: System detection
        $systemSpecs = Get-MacOSSystemSpecs
        $architecture = Get-MacOSArchitecture
        Write-VelociraptorLog "Architecture: $architecture" -Level INFO
        
        # Step 3: Check existing installation
        $existingBinary = Join-Path $InstallPath $script:VelociraptorBinaryName
        if ((Test-Path $existingBinary) -and -not $Force) {
            Write-VelociraptorLog "Velociraptor already installed at $existingBinary" -Level WARN
            Write-Host "Use -Force to reinstall" -ForegroundColor Yellow
            return
        }
        
        # Step 4: Check admin privileges
        $hasAdmin = Test-MacOSAdminPrivileges
        if (-not $hasAdmin) {
            if (-not (Request-AdminElevation -Reason "Installing binary to $InstallPath")) {
                throw "Admin privileges required for installation"
            }
        }
        
        # Step 5: Get latest release
        $release = Get-LatestVelociraptorRelease -Architecture $architecture
        
        # Step 6: Download and install binary
        $binaryPath = Install-VelociraptorBinary -Release $release -InstallPath $InstallPath
        
        # Step 7: Generate configuration
        $configFile = if ($ConfigPath) {
            $ConfigPath
        }
        else {
            New-VelociraptorConfig -BinaryPath $binaryPath -DataPath $DataPath `
                -DeploymentType $DeploymentType -GuiPort $GuiPort -FrontendPort $FrontendPort
        }
        
        # Step 8: Configure firewall
        Set-MacOSFirewallRule -BinaryPath $binaryPath -Ports @($GuiPort, $FrontendPort)
        
        # Step 9: Install service
        $plistPath = Install-LaunchdService -BinaryPath $binaryPath -ConfigPath $configFile
        
        # Step 10: Start service if requested
        if ($EnableService) {
            $started = Start-LaunchdService
            
            if ($started) {
                # Wait for port to be ready
                $maxWait = 30
                $waited = 0
                while (-not (Test-PortListening -Port $GuiPort) -and $waited -lt $maxWait) {
                    Start-Sleep -Seconds 1
                    $waited++
                }
                
                if (Test-PortListening -Port $GuiPort) {
                    Write-VelociraptorLog "GUI is ready on port $GuiPort" -Level SUCCESS
                }
            }
        }
        
        # Summary
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
        Write-Host " DEPLOYMENT COMPLETE" -ForegroundColor Green
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
        Write-Host ""
        Write-Host " Binary:        $binaryPath" -ForegroundColor Cyan
        Write-Host " Configuration: $configFile" -ForegroundColor Cyan
        Write-Host " Data:          $DataPath" -ForegroundColor Cyan
        Write-Host " Logs:          $script:LogPath" -ForegroundColor Cyan
        Write-Host " Service:       $plistPath" -ForegroundColor Cyan
        Write-Host ""
        Write-Host " Web GUI:       https://127.0.0.1:$GuiPort" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " To start:      launchctl load $plistPath" -ForegroundColor Gray
        Write-Host " To stop:       launchctl unload $plistPath" -ForegroundColor Gray
        Write-Host ""
        
        return @{
            Success = $true
            BinaryPath = $binaryPath
            ConfigPath = $configFile
            DataPath = $DataPath
            PlistPath = $plistPath
            GuiUrl = "https://127.0.0.1:$GuiPort"
        }
    }
    catch {
        Write-VelociraptorLog "Deployment failed: $_" -Level ERROR
        Write-Host ""
        Write-Host "Deployment failed. Check logs at: $script:LogPath" -ForegroundColor Red
        Write-Host ""
        
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Execute deployment
Invoke-VelociraptorDeployment
