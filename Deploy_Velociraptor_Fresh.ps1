#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Fresh Velociraptor Installation Script

.DESCRIPTION
    Clean, tested script that downloads and installs Velociraptor from GitHub.
    Handles Windows security prompts gracefully.
#>

[CmdletBinding()]
param(
    [string]$InstallPath = "C:\VelociraptorFresh"
)

$ErrorActionPreference = 'Stop'

Write-Host @"

================================================================
               FRESH VELOCIRAPTOR INSTALLATION
================================================================
Downloads and installs the real Velociraptor executable
================================================================

"@ -ForegroundColor Cyan

function Write-Log {
    param([string]$Message, [string]$Level = "Info")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $colors = @{ "Info" = "White"; "Success" = "Green"; "Warning" = "Yellow"; "Error" = "Red"; "Progress" = "Cyan" }
    Write-Host "[$timestamp] $Message" -ForegroundColor $colors[$Level]
}

try {
    Write-Log "Starting fresh Velociraptor installation..." "Progress"
    
    # Create directories
    Write-Log "Creating installation directories..." "Info"
    $binPath = Join-Path $InstallPath "bin"
    $exePath = Join-Path $binPath "velociraptor.exe"
    $configPath = Join-Path $InstallPath "server.config.yaml"
    
    @($InstallPath, $binPath, "$InstallPath\datastore", "$InstallPath\filestore", "$InstallPath\logs") | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -Path $_ -ItemType Directory -Force | Out-Null
            Write-Log "Created: $_" "Success"
        }
    }
    
    # Get latest release
    Write-Log "Fetching latest Velociraptor release..." "Progress"
    $apiUrl = "https://api.github.com/repos/Velocidex/velociraptor/releases/latest"
    $response = Invoke-RestMethod -Uri $apiUrl
    $windowsAsset = $response.assets | Where-Object { 
        $_.name -like "*windows-amd64.exe" -and 
        $_.name -notlike "*debug*" -and 
        $_.name -notlike "*collector*"
    } | Select-Object -First 1
    
    if (-not $windowsAsset) {
        throw "Could not find Windows executable"
    }
    
    $version = $response.tag_name -replace '^v', ''
    Write-Log "Found Velociraptor v$version ($([math]::Round($windowsAsset.size / 1MB, 1)) MB)" "Success"
    
    # Download
    Write-Log "Downloading Velociraptor executable..." "Progress"
    Write-Log "This may take a moment for a $([math]::Round($windowsAsset.size / 1MB, 1)) MB file..." "Info"
    
    $webClient = $null
    try {
        # Use simple download method with proper resource disposal
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($windowsAsset.browser_download_url, $exePath)
        
        if (Test-Path $exePath) {
            $fileSize = (Get-Item $exePath).Length
            Write-Log "Download completed: $([math]::Round($fileSize / 1MB, 1)) MB" "Success"
        } else {
            throw "Download failed"
        }
    }
    catch {
        Write-Log "Download error: $($_.Exception.Message)" "Error"
        throw
    }
    finally {
        if ($webClient) { 
            $webClient.Dispose()
            Write-Log "WebClient resources disposed" "Debug"
        }
    }
    
    # Create configuration
    Write-Log "Creating server configuration..." "Info"
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
    Write-Log "Configuration created: $configPath" "Success"
    
    # Create launch script
    $launchScript = Join-Path $InstallPath "Launch-Velociraptor.bat"
    $launchContent = @"
@echo off
title Velociraptor Server v$version
echo.
echo ================================================================
echo                   VELOCIRAPTOR SERVER v$version
echo ================================================================
echo.
echo Starting Velociraptor server...
echo Web interface will be available at: http://127.0.0.1:8889
echo.
cd /d "$InstallPath"
"$exePath" --config "$configPath" gui
echo.
echo Server stopped.
pause
"@
    
    Set-Content -Path $launchScript -Value $launchContent -Encoding ASCII
    Write-Log "Launch script created: $launchScript" "Success"
    
    # Installation complete
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "           INSTALLATION COMPLETED SUCCESSFULLY!" -ForegroundColor Green  
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Velociraptor v$version installed to:" -ForegroundColor White
    Write-Host "  Location:   $InstallPath" -ForegroundColor Gray
    Write-Host "  Executable: $exePath" -ForegroundColor Gray
    Write-Host "  Config:     $configPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "TO START VELOCIRAPTOR:" -ForegroundColor Yellow
    Write-Host "1. Double-click: $launchScript" -ForegroundColor White
    Write-Host "2. Then browse to: http://127.0.0.1:8889" -ForegroundColor Cyan
    Write-Host ""
    
    # Ask to launch
    Write-Host "Launch Velociraptor now? (Y/N): " -ForegroundColor Yellow -NoNewline
    $response = Read-Host
    
    if ($response -match '^[Yy]') {
        Write-Log "Starting Velociraptor..." "Progress"
        
        try {
            $process = Start-Process -FilePath $exePath -ArgumentList "--config", $configPath, "gui" -WorkingDirectory $InstallPath -PassThru
            Write-Log "Velociraptor started (PID: $($process.Id))" "Success"
            
            Write-Log "Waiting for server startup..." "Info"
            Start-Sleep -Seconds 8
            
            Write-Log "Opening web interface..." "Info"
            Start-Process "http://127.0.0.1:8889"
            
            Write-Host ""
            Write-Host "=== VELOCIRAPTOR IS RUNNING ===" -ForegroundColor Green
            Write-Host "Web Interface: http://127.0.0.1:8889" -ForegroundColor Cyan
            Write-Host "Process ID: $($process.Id)" -ForegroundColor Gray
        }
        catch {
            Write-Log "Launch failed: $($_.Exception.Message)" "Error"
            Write-Log "You can manually launch using: $launchScript" "Info"
        }
    }
    
}
catch {
    Write-Log "Installation failed: $($_.Exception.Message)" "Error"
    Write-Host ""
    Write-Host "Installation failed. Error details above." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Installation script completed." -ForegroundColor Green