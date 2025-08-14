#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Cross-platform Velociraptor deployment script for Linux distributions.

.DESCRIPTION
    Deploys Velociraptor on various Linux distributions including Ubuntu, Debian,
    CentOS, RHEL, Fedora, SUSE, and Kali Linux. Handles distribution-specific
    package management, service configuration, and security hardening.

.PARAMETER Distribution
    Target Linux distribution (Ubuntu, Debian, CentOS, RHEL, Fedora, SUSE, Kali, Auto).

.PARAMETER DeploymentType
    Type of deployment (Standalone, Server, Client).

.PARAMETER ConfigPath
    Path to Velociraptor configuration file.

.PARAMETER InstallPath
    Installation directory path.

.PARAMETER ServiceUser
    User account for running Velociraptor service.

.PARAMETER AutoDetect
    Automatically detect Linux distribution.

.PARAMETER SecurityHardening
    Apply security hardening configurations.

.EXAMPLE
    .\Deploy-VelociraptorLinux.ps1 -Distribution Ubuntu -DeploymentType Server

.EXAMPLE
    .\Deploy-VelociraptorLinux.ps1 -AutoDetect -DeploymentType Standalone -SecurityHardening
#>

[CmdletBinding()]
param(
    [ValidateSet('Ubuntu', 'Debian', 'CentOS', 'RHEL', 'Fedora', 'SUSE', 'Kali', 'Auto')]
    [string]$Distribution = 'Auto',

    [ValidateSet('Standalone', 'Server', 'Client')]
    [string]$DeploymentType = 'Standalone',

    [string]$ConfigPath,

    [string]$InstallPath = '/opt/velociraptor',

    [string]$ServiceUser = 'velociraptor',

    [switch]$AutoDetect,

    [switch]$SecurityHardening
)

# Import required modules if available
if (Get-Module -Name VelociraptorDeployment -ListAvailable) {
    Import-Module VelociraptorDeployment -Force
}

# Global variables
$script:DetectedDistribution = $null
$script:PackageManager = $null
$script:ServiceManager = $null
$script:VelociraptorBinary = "$InstallPath/bin/velociraptor"
$script:ConfigFile = "$InstallPath/etc/velociraptor.yaml"
$script:LogFile = "/var/log/velociraptor-deployment.log"

function Deploy-VelociraptorLinux {
    Write-Host "=== VELOCIRAPTOR LINUX DEPLOYMENT ===" -ForegroundColor Cyan
    Write-Host "Target Distribution: $Distribution" -ForegroundColor Green
    Write-Host "Deployment Type: $DeploymentType" -ForegroundColor Green
    Write-Host "Install Path: $InstallPath" -ForegroundColor Green
    Write-Host "Service User: $ServiceUser" -ForegroundColor Green
    Write-Information "" -InformationAction Continue

    try {
        # Check if running as root
        if ((id -u) -ne 0) {
            throw "This script must be run as root (use sudo)"
        }

        # Detect Linux distribution
        if ($Distribution -eq 'Auto' -or $AutoDetect) {
            $script:DetectedDistribution = Get-LinuxDistribution
            Write-Host "Detected distribution: $script:DetectedDistribution" -ForegroundColor Yellow
        }
        else {
            $script:DetectedDistribution = $Distribution
        }

        # Initialize distribution-specific settings
        Initialize-DistributionSettings

        # Pre-deployment checks
        Test-DeploymentPrerequisites

        # Create installation directories
        New-InstallationDirectories

        # Create service user
        New-ServiceUser

        # Download and install Velociraptor
        Install-VelociraptorBinary

        # Generate configuration
        New-VelociraptorConfiguration

        # Install and configure service
        Install-VelociraptorService

        # Apply security hardening
        if ($SecurityHardening) {
            Set-LinuxSecurityHardening
        }

        # Configure firewall
        Set-LinuxFirewallRules

        # Start service
        Start-VelociraptorService

        # Verify deployment
        Test-DeploymentStatus

        Write-Host "Velociraptor deployment completed successfully!" -ForegroundColor Green
        Show-DeploymentSummary

    }
    catch {
        Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-LogEntry "ERROR" "Deployment failed: $($_.Exception.Message)"
        throw
    }
}

function Get-LinuxDistribution {
    # Try multiple methods to detect distribution

    # Method 1: /etc/os-release
    if (Test-Path "/etc/os-release") {
        $osRelease = Get-Content "/etc/os-release" | ConvertFrom-StringData
        $distroId = $osRelease.ID.ToLower()

        switch -Regex ($distroId) {
            "ubuntu" { return "Ubuntu" }
            "debian" { return "Debian" }
            "centos" { return "CentOS" }
            "rhel|redhat" { return "RHEL" }
            "fedora" { return "Fedora" }
            "suse|opensuse" { return "SUSE" }
            "kali" { return "Kali" }
        }
    }

    # Method 2: /etc/lsb-release
    if (Test-Path "/etc/lsb-release") {
        $lsbRelease = Get-Content "/etc/lsb-release" | ConvertFrom-StringData
        if ($lsbRelease.DISTRIB_ID) {
            switch -Regex ($lsbRelease.DISTRIB_ID.ToLower()) {
                "ubuntu" { return "Ubuntu" }
                "debian" { return "Debian" }
                "kali" { return "Kali" }
            }
        }
    }

    # Method 3: Check specific distribution files
    if (Test-Path "/etc/debian_version") { return "Debian" }
    if (Test-Path "/etc/redhat-release") { return "RHEL" }
    if (Test-Path "/etc/centos-release") { return "CentOS" }
    if (Test-Path "/etc/fedora-release") { return "Fedora" }
    if (Test-Path "/etc/SuSE-release") { return "SUSE" }

    # Default fallback
    Write-Warning "Could not detect Linux distribution, defaulting to Ubuntu"
    return "Ubuntu"
}

function Initialize-DistributionSettings {
    switch ($script:DetectedDistribution) {
        "Ubuntu" {
            $script:PackageManager = "apt"
            $script:ServiceManager = "systemd"
        }
        "Debian" {
            $script:PackageManager = "apt"
            $script:ServiceManager = "systemd"
        }
        "Kali" {
            $script:PackageManager = "apt"
            $script:ServiceManager = "systemd"
        }
        "CentOS" {
            $script:PackageManager = "yum"
            $script:ServiceManager = "systemd"
        }
        "RHEL" {
            $script:PackageManager = "yum"
            $script:ServiceManager = "systemd"
        }
        "Fedora" {
            $script:PackageManager = "dnf"
            $script:ServiceManager = "systemd"
        }
        "SUSE" {
            $script:PackageManager = "zypper"
            $script:ServiceManager = "systemd"
        }
        default {
            $script:PackageManager = "apt"
            $script:ServiceManager = "systemd"
        }
    }

    Write-LogEntry "INFO" "Initialized settings for $script:DetectedDistribution (Package: $script:PackageManager, Service: $script:ServiceManager)"
}

function Test-DeploymentPrerequisites {
    Write-Host "Checking deployment prerequisites..." -ForegroundColor Cyan

    # Check required commands
    $requiredCommands = @('curl', 'wget', 'unzip', 'systemctl')
    foreach ($cmd in $requiredCommands) {
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
            Write-Host "Installing required package for: $cmd" -ForegroundColor Yellow
            Install-RequiredPackage -Command $cmd
        }
    }

    # Check disk space
    $availableSpace = (Get-ChildItem / | Measure-Object -Property Length -Sum).Sum
    if ($availableSpace -lt 1GB) {
        Write-Warning "Low disk space detected. Deployment may fail."
    }

    # Check network connectivity
    if (-not (Test-Connection -ComputerName "github.com" -Count 1 -Quiet)) {
        Write-Warning "Network connectivity issues detected"
    }

    Write-LogEntry "INFO" "Prerequisites check completed"
}

function Install-RequiredPackage {
    param([string]$Command)

    $packageMap = @{
        'curl' = 'curl'
        'wget' = 'wget'
        'unzip' = 'unzip'
        'systemctl' = 'systemd'
    }

    $packageName = $packageMap[$Command]
    if (-not $packageName) { $packageName = $Command }

    switch ($script:PackageManager) {
        "apt" {
            Invoke-Expression "apt update && apt install -y $packageName"
        }
        "yum" {
            Invoke-Expression "yum install -y $packageName"
        }
        "dnf" {
            Invoke-Expression "dnf install -y $packageName"
        }
        "zypper" {
            Invoke-Expression "zypper install -y $packageName"
        }
    }
}

function New-InstallationDirectories {
    Write-Host "Creating installation directories..." -ForegroundColor Cyan

    $directories = @(
        $InstallPath,
        "$InstallPath/bin",
        "$InstallPath/etc",
        "$InstallPath/var",
        "$InstallPath/log",
        "/var/log/velociraptor",
        "/etc/velociraptor"
    )

    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-LogEntry "INFO" "Created directory: $dir"
        }
    }

    # Set proper permissions
    chmod 755 $InstallPath
    chmod 750 "$InstallPath/etc"
    chmod 750 "/etc/velociraptor"
}

function New-ServiceUser {
    Write-Host "Creating service user: $ServiceUser" -ForegroundColor Cyan

    # Check if user already exists
    if (id $ServiceUser 2>/dev/null) {
        Write-Host "User $ServiceUser already exists" -ForegroundColor Yellow
        return
    }

    # Create system user
    useradd --system --home-dir $InstallPath --shell /bin/false --comment "Velociraptor Service User" $ServiceUser

    # Set ownership
    chown -R "${ServiceUser}:${ServiceUser}" $InstallPath
    chown -R "${ServiceUser}:${ServiceUser}" "/var/log/velociraptor"

    Write-LogEntry "INFO" "Created service user: $ServiceUser"
}

function Install-VelociraptorBinary {
    Write-Host "Downloading and installing Velociraptor binary..." -ForegroundColor Cyan

    try {
        # Get latest release information
        $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/Velocidex/velociraptor/releases/latest"

        # Find Linux binary
        $linuxAsset = $releaseInfo.assets | Where-Object { $_.name -match "linux-amd64" }
        if (-not $linuxAsset) {
            throw "Linux binary not found in latest release"
        }

        $downloadUrl = $linuxAsset.browser_download_url
        $tempFile = "/tmp/velociraptor-linux.zip"

        Write-Host "Downloading from: $downloadUrl" -ForegroundColor Yellow

        # Download binary
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile

        # Extract binary
        unzip -j $tempFile -d "$InstallPath/bin/"

        # Make executable
        chmod +x $script:VelociraptorBinary

        # Verify installation
        $version = & $script:VelociraptorBinary version
        Write-Host "Installed Velociraptor version: $version" -ForegroundColor Green

        # Cleanup
        Remove-Item $tempFile -Force

        Write-LogEntry "INFO" "Velociraptor binary installed successfully"
    }
    catch {
        Write-LogEntry "ERROR" "Failed to install Velociraptor binary: $($_.Exception.Message)"
        throw
    }
}

function New-VelociraptorConfiguration {
    Write-Host "Generating Velociraptor configuration..." -ForegroundColor Cyan

    if ($ConfigPath -and (Test-Path $ConfigPath)) {
        # Use provided configuration
        Copy-Item $ConfigPath $script:ConfigFile
        Write-LogEntry "INFO" "Used provided configuration: $ConfigPath"
    }
    else {
        # Generate new configuration
        switch ($DeploymentType) {
            "Server" {
                & $script:VelociraptorBinary config generate --config $script:ConfigFile
            }
            "Standalone" {
                & $script:VelociraptorBinary config generate --config $script:ConfigFile
                # Modify for standalone mode
                # Implementation would modify the config for standalone
            }
            "Client" {
                if (-not $ConfigPath) {
                    throw "Client deployment requires a configuration file"
                }
            }
        }

        Write-LogEntry "INFO" "Generated $DeploymentType configuration"
    }

    # Set proper permissions
    chown "${ServiceUser}:${ServiceUser}" $script:ConfigFile
    chmod 640 $script:ConfigFile

    # Create symlink in /etc
    if (-not (Test-Path "/etc/velociraptor/velociraptor.yaml")) {
        ln -sf $script:ConfigFile "/etc/velociraptor/velociraptor.yaml"
    }
}

function Install-VelociraptorService {
    Write-Host "Installing Velociraptor service..." -ForegroundColor Cyan

    $serviceContent = @"
[Unit]
Description=Velociraptor DFIR Platform
Documentation=https://docs.velociraptor.app/
After=network.target
Wants=network.target

[Service]
Type=simple
User=$ServiceUser
Group=$ServiceUser
ExecStart=$script:VelociraptorBinary --config $script:ConfigFile frontend
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=velociraptor
KillMode=mixed
TimeoutStopSec=5

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$InstallPath /var/log/velociraptor
CapabilityBoundingSet=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
"@

    $serviceContent | Set-Content "/etc/systemd/system/velociraptor.service"

    # Reload systemd and enable service
    systemctl daemon-reload
    systemctl enable velociraptor.service

    Write-LogEntry "INFO" "Velociraptor service installed and enabled"
}

function Set-LinuxSecurityHardening {
    Write-Host "Applying Linux security hardening..." -ForegroundColor Cyan

    # File permissions
    chmod 750 $InstallPath
    chmod 640 $script:ConfigFile
    chmod 755 $script:VelociraptorBinary

    # SELinux context (if available)
    if (Get-Command "semanage" -ErrorAction SilentlyContinue) {
        semanage fcontext -a -t bin_t "$script:VelociraptorBinary" 2>/dev/null || true
        restorecon -R $InstallPath 2>/dev/null || true
    }

    # AppArmor profile (if available)
    if (Get-Command "aa-status" -ErrorAction SilentlyContinue) {
        # Create basic AppArmor profile
        $apparmorProfile = @"
#include <tunables/global>

$script:VelociraptorBinary {
  #include <abstractions/base>
  #include <abstractions/nameservice>

  capability net_bind_service,

  $script:VelociraptorBinary mr,
  $script:ConfigFile r,
  $InstallPath/** rw,
  /var/log/velociraptor/** rw,

  /proc/sys/kernel/random/uuid r,
  /sys/kernel/mm/transparent_hugepage/hpage_pmd_size r,
}
"@

        $apparmorProfile | Set-Content "/etc/apparmor.d/velociraptor"
        apparmor_parser -r /etc/apparmor.d/velociraptor 2>/dev/null || true
    }

    Write-LogEntry "INFO" "Security hardening applied"
}

function Set-LinuxFirewallRules {
    Write-Host "Configuring firewall rules..." -ForegroundColor Cyan

    # Try different firewall managers
    if (Get-Command "ufw" -ErrorAction SilentlyContinue) {
        # Ubuntu/Debian UFW
        ufw allow 8889/tcp comment "Velociraptor GUI"
        ufw allow 8000/tcp comment "Velociraptor API"
        ufw allow 8080/tcp comment "Velociraptor Frontend"
    }
    elseif (Get-Command "firewall-cmd" -ErrorAction SilentlyContinue) {
        # RHEL/CentOS/Fedora firewalld
        firewall-cmd --permanent --add-port=8889/tcp
        firewall-cmd --permanent --add-port=8000/tcp
        firewall-cmd --permanent --add-port=8080/tcp
        firewall-cmd --reload
    }
    elseif (Get-Command "iptables" -ErrorAction SilentlyContinue) {
        # Generic iptables
        iptables -A INPUT -p tcp --dport 8889 -j ACCEPT
        iptables -A INPUT -p tcp --dport 8000 -j ACCEPT
        iptables -A INPUT -p tcp --dport 8080 -j ACCEPT

        # Save rules (distribution-specific)
        if (Test-Path "/etc/iptables/rules.v4") {
            iptables-save > /etc/iptables/rules.v4
        }
        elseif (Test-Path "/etc/sysconfig/iptables") {
            iptables-save > /etc/sysconfig/iptables
        }
    }

    Write-LogEntry "INFO" "Firewall rules configured"
}

function Start-VelociraptorService {
    Write-Host "Starting Velociraptor service..." -ForegroundColor Cyan

    systemctl start velociraptor.service

    # Wait for service to start
    Start-Sleep 5

    $status = systemctl is-active velociraptor.service
    if ($status -eq "active") {
        Write-Host "Velociraptor service started successfully" -ForegroundColor Green
        Write-LogEntry "INFO" "Velociraptor service started"
    }
    else {
        throw "Failed to start Velociraptor service"
    }
}

function Test-DeploymentStatus {
    Write-Host "Verifying deployment status..." -ForegroundColor Cyan

    # Check service status
    $serviceStatus = systemctl is-active velociraptor.service
    Write-Host "Service Status: $serviceStatus" -ForegroundColor $(if ($serviceStatus -eq "active") { "Green" } else { "Red" })

    # Check process
    $process = Get-Process -Name "velociraptor" -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "Process Running: Yes (PID: $($process.Id))" -ForegroundColor Green
    }
    else {
        Write-Host "Process Running: No" -ForegroundColor Red
    }

    # Check ports
    $ports = @(8889, 8000, 8080)
    foreach ($port in $ports) {
        $listening = netstat -tlnp | grep ":$port "
        if ($listening) {
            Write-Host "Port $port: Listening" -ForegroundColor Green
        }
        else {
            Write-Host "Port $port: Not listening" -ForegroundColor Yellow
        }
    }

    Write-LogEntry "INFO" "Deployment verification completed"
}

function Show-DeploymentSummary {
    Write-Information "" -InformationAction Continue
    Write-Host "=== DEPLOYMENT SUMMARY ===" -ForegroundColor Cyan
    Write-Host "Distribution: $script:DetectedDistribution" -ForegroundColor Green
    Write-Host "Deployment Type: $DeploymentType" -ForegroundColor Green
    Write-Host "Install Path: $InstallPath" -ForegroundColor Green
    Write-Host "Config File: $script:ConfigFile" -ForegroundColor Green
    Write-Host "Service User: $ServiceUser" -ForegroundColor Green
    Write-Host "Binary Path: $script:VelociraptorBinary" -ForegroundColor Green
    Write-Information "" -InformationAction Continue
    Write-Host "Service Commands:" -ForegroundColor Yellow
    Write-Host "  Start:   systemctl start velociraptor" -ForegroundColor White
    Write-Host "  Stop:    systemctl stop velociraptor" -ForegroundColor White
    Write-Host "  Status:  systemctl status velociraptor" -ForegroundColor White
    Write-Host "  Logs:    journalctl -u velociraptor -f" -ForegroundColor White
    Write-Information "" -InformationAction Continue
    Write-Host "Web Interface: https://localhost:8889" -ForegroundColor Yellow
    Write-Host "API Endpoint:  https://localhost:8000" -ForegroundColor Yellow
    Write-Information "" -InformationAction Continue
}

function Write-LogEntry {
    param(
        [string]$Level,
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Write to log file
    $logEntry | Add-Content $script:LogFile

    # Also write to console for debugging
    Write-Verbose $logEntry
}

# Execute deployment
Deploy-VelociraptorLinux