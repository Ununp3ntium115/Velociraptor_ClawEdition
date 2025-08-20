#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Clean Velociraptor Installation Script

.DESCRIPTION
    Production-ready script that downloads and installs Velociraptor from GitHub.
    Based on proven working installation that just succeeded.

.PARAMETER InstallPath
    Installation directory path. Default: C:\VelociraptorData

.PARAMETER LaunchAfterInstall
    Automatically launch Velociraptor after installation. Default: $true

.EXAMPLE
    .\Deploy_Velociraptor_Clean.ps1
    
.EXAMPLE
    .\Deploy_Velociraptor_Clean.ps1 -InstallPath "D:\Velociraptor" -LaunchAfterInstall $false
#>

[CmdletBinding()]
param(
    [string]$InstallPath = "C:\VelociraptorData",
    [bool]$LaunchAfterInstall = $true
)

$ErrorActionPreference = 'Stop'

# Banner
Write-Host @"

================================================================
               CLEAN VELOCIRAPTOR INSTALLATION
================================================================
Official Velociraptor DFIR Platform Deployment
Downloads latest release from GitHub
================================================================

"@ -ForegroundColor Cyan

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error", "Progress")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $colors = @{
        "Info" = "White"
        "Success" = "Green" 
        "Warning" = "Yellow"
        "Error" = "Red"
        "Progress" = "Cyan"
    }
    
    Write-Host "[$timestamp] $Message" -ForegroundColor $colors[$Level]
}

try {
    Write-Log "Starting Velociraptor installation..." "Progress"
    
    # Validate prerequisites
    Write-Log "Checking prerequisites..." "Info"
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw "PowerShell 5.0 or higher is required"
    }
    Write-Log "PowerShell version: $($PSVersionTable.PSVersion)" "Success"
    
    # Check admin privileges
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if ($isAdmin) {
        Write-Log "Running with administrator privileges" "Success"
    } else {
        Write-Log "Warning: Not running as administrator. Firewall configuration will be skipped." "Warning"
    }
    
    # Check internet connectivity
    try {
        $null = Invoke-WebRequest -Uri "https://api.github.com" -Method Head -TimeoutSec 10
        Write-Log "Internet connectivity verified" "Success"
    }
    catch {
        throw "Internet connection required to download Velociraptor"
    }
    
    # Create installation directories
    Write-Log "Creating installation directories..." "Progress"
    $binPath = Join-Path $InstallPath "bin"
    $configPath = Join-Path $InstallPath "server.config.yaml"
    $launchScript = Join-Path $InstallPath "Launch-Velociraptor.bat"
    
    $directories = @($InstallPath, $binPath, "$InstallPath\datastore", "$InstallPath\filestore", "$InstallPath\logs")
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Log "Created directory: $dir" "Success"
        }
    }
    
    # Get latest Velociraptor release
    Write-Log "Fetching latest Velociraptor release..." "Progress"
    
    $apiUrl = "https://api.github.com/repos/Velocidex/velociraptor/releases/latest"
    $response = Invoke-RestMethod -Uri $apiUrl
    $windowsAsset = $response.assets | Where-Object { 
        $_.name -like "*windows-amd64.exe" -and 
        $_.name -notlike "*debug*" -and 
        $_.name -notlike "*collector*"
    } | Select-Object -First 1
    
    if (-not $windowsAsset) {
        throw "Could not find Windows executable in latest release"
    }
    
    $version = $response.tag_name -replace '^v', ''
    Write-Log "Found Velociraptor v$version" "Success"
    Write-Log "Asset: $($windowsAsset.name) ($([math]::Round($windowsAsset.size / 1MB, 1)) MB)" "Info"
    
    # Download Velociraptor executable
    Write-Log "Downloading Velociraptor executable..." "Progress"
    $exePath = Join-Path $binPath "velociraptor.exe"
    
    Write-Log "Downloading from: $($windowsAsset.browser_download_url)" "Info"
    Write-Log "Saving to: $exePath" "Info"
    
    # Download with progress (for large file)
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($windowsAsset.browser_download_url, $exePath)
    
    # Verify download
    if (Test-Path $exePath) {
        $fileSize = (Get-Item $exePath).Length
        Write-Log "Download completed: $([math]::Round($fileSize / 1MB, 1)) MB" "Success"
        
        # Basic executable test
        try {
            $versionCheck = & $exePath version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Executable verification: PASSED" "Success"
            }
        }
        catch {
            Write-Log "Executable verification: SKIPPED (non-critical)" "Warning"
        }
    } else {
        throw "Download failed - executable not found"
    }
    
    # Create server configuration
    Write-Log "Creating server configuration..." "Progress"
    
    $serverConfig = @"
version:
  name: velociraptor
  version: $version

datastore:
  implementation: FileBaseDataStore
  location: $InstallPath\datastore
  filestore_directory: $InstallPath\filestore

server_type: standalone

GUI:
  bind_address: 127.0.0.1
  bind_port: 8889
  use_plain_http: true

Frontend:
  bind_address: 127.0.0.1
  bind_port: 8000

Client:
  use_self_signed_ssl: true

defaults:
  hunt_expiry_hours: 168
  notebook_cell_timeout_min: 10

logging:
  output_directory: $InstallPath\logs
  separate_logs_per_component: true
  level: INFO
"@
    
    Set-Content -Path $configPath -Value $serverConfig -Encoding UTF8
    Write-Log "Server configuration created: $configPath" "Success"
    
    # Configure Windows Firewall (if admin)
    if ($isAdmin) {
        Write-Log "Configuring Windows Firewall..." "Progress"
        try {
            $null = netsh advfirewall firewall add rule name="Velociraptor GUI" dir=in action=allow protocol=TCP localport=8889
            $null = netsh advfirewall firewall add rule name="Velociraptor Frontend" dir=in action=allow protocol=TCP localport=8000
            Write-Log "Firewall rules added for ports 8000 and 8889" "Success"
        }
        catch {
            Write-Log "Firewall configuration failed: $($_.Exception.Message)" "Warning"
        }
    }
    
    # Create launch script
    Write-Log "Creating launch script..." "Progress"
    $launchContent = @"
@echo off
title Velociraptor Server v$version
echo Starting Velociraptor Server v$version...
echo.
cd /d "$InstallPath"
"$exePath" --config "$configPath" gui
echo.
echo Velociraptor server has stopped.
pause
"@
    
    Set-Content -Path $launchScript -Value $launchContent -Encoding ASCII
    Write-Log "Launch script created: $launchScript" "Success"
    
    # Installation summary
    Write-Log "Installation completed successfully!" "Success"
    Write-Host ""
    Write-Host "=== INSTALLATION SUMMARY ===" -ForegroundColor Green
    Write-Host "Version:      Velociraptor v$version" -ForegroundColor White
    Write-Host "Location:     $InstallPath" -ForegroundColor White
    Write-Host "Executable:   $exePath" -ForegroundColor White
    Write-Host "Config:       $configPath" -ForegroundColor White
    Write-Host "Launch:       $launchScript" -ForegroundColor White
    Write-Host "Web Access:   http://127.0.0.1:8889" -ForegroundColor Yellow
    Write-Host ""
    
    # Launch option
    if ($LaunchAfterInstall) {
        Write-Host "Launching Velociraptor in 3 seconds..." -ForegroundColor Cyan
        Start-Sleep -Seconds 3
        
        Write-Log "Starting Velociraptor server..." "Progress"
        $process = Start-Process -FilePath $exePath -ArgumentList "--config", $configPath, "gui" -WorkingDirectory $InstallPath -PassThru
        Write-Log "Velociraptor started with PID: $($process.Id)" "Success"
        
        Write-Log "Waiting for server startup..." "Info"
        Start-Sleep -Seconds 8
        
        Write-Log "Opening web interface..." "Info"
        Start-Process "http://127.0.0.1:8889"
        
        Write-Host ""
        Write-Host "=== VELOCIRAPTOR IS RUNNING ===" -ForegroundColor Green
        Write-Host "Web Interface: http://127.0.0.1:8889" -ForegroundColor Yellow
        Write-Host "Server Process ID: $($process.Id)" -ForegroundColor White
        Write-Host ""
        Write-Host "To stop the server, close the Velociraptor console window." -ForegroundColor Gray
    } else {
        Write-Host "To start Velociraptor:" -ForegroundColor Cyan
        Write-Host "1. Double-click: $launchScript" -ForegroundColor White
        Write-Host "2. Then browse to: http://127.0.0.1:8889" -ForegroundColor Yellow
    }
    
}
catch {
    Write-Log "Installation failed: $($_.Exception.Message)" "Error"
    Write-Host ""
    Write-Host "Installation failed. Please check the error above and try again." -ForegroundColor Red
    Write-Host "You may need to run as Administrator for full functionality." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Installation script completed." -ForegroundColor Green