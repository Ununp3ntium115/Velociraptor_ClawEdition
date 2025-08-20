#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Direct Velociraptor Installation - Simple console-based installation

.DESCRIPTION
    This script downloads the real Velociraptor executable from GitHub and performs
    a complete installation using a simple console interface.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host @"

================================================================
    DIRECT VELOCIRAPTOR INSTALLATION - CONSOLE VERSION
================================================================

This will download and install the ACTUAL Velociraptor executable!
No GUI crashes - direct installation to C:\VelociraptorData

"@ -ForegroundColor Cyan

# Function to write colored log entries
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "Info"
    )
    $timestamp = Get-Date -Format "HH:mm:ss"
    $prefix = "[$timestamp]"
    
    switch ($Level) {
        "Success" { Write-Host "$prefix $Message" -ForegroundColor Green }
        "Warning" { Write-Host "$prefix $Message" -ForegroundColor Yellow }
        "Error" { Write-Host "$prefix $Message" -ForegroundColor Red }
        "Info" { Write-Host "$prefix $Message" -ForegroundColor White }
        "Progress" { Write-Host "$prefix $Message" -ForegroundColor Cyan }
    }
}

try {
    Write-Log "=== STARTING DIRECT VELOCIRAPTOR INSTALLATION ===" "Progress"
    
    # Check admin privileges
    Write-Log "Checking administrator privileges..." "Info"
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Log "WARNING: Not running as administrator. Some features may not work properly." "Warning"
    } else {
        Write-Log "Running with administrator privileges" "Success"
    }
    
    # Create installation directory
    Write-Log "Creating installation directories..." "Progress"
    $installPath = "C:\VelociraptorData"
    $binPath = "$installPath\bin"
    
    Write-Log "Creating installation directory: $installPath" "Info"
    if (-not (Test-Path $installPath)) {
        New-Item -Path $installPath -ItemType Directory -Force | Out-Null
        Write-Log "Created $installPath" "Success"
    } else {
        Write-Log "Directory $installPath already exists" "Info"
    }
    
    if (-not (Test-Path $binPath)) {
        New-Item -Path $binPath -ItemType Directory -Force | Out-Null
        Write-Log "Created $binPath" "Success"
    } else {
        Write-Log "Directory $binPath already exists" "Info"
    }
    
    # Get latest release information
    Write-Log "Fetching latest Velociraptor release info..." "Progress"
    Write-Log "Contacting GitHub API for latest release..." "Info"
    
    try {
        Write-Log "Using direct GitHub API call..." "Info"
        $apiUrl = "https://api.github.com/repos/Velocidex/velociraptor/releases/latest"
        $response = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
        $windowsAsset = $response.assets | Where-Object { 
            $_.name -like "*windows-amd64.exe" -and 
            $_.name -notlike "*debug*" -and 
            $_.name -notlike "*collector*"
        } | Select-Object -First 1
        
        if ($windowsAsset) {
            $release = @{
                Version = $response.tag_name -replace '^v', ''
                Asset = @{
                    Name = $windowsAsset.name
                    Size = $windowsAsset.size
                    DownloadUrl = $windowsAsset.browser_download_url
                }
            }
            Write-Log "SUCCESS - Found Velociraptor v$($release.Version)" "Success"
            Write-Log "  Asset: $($release.Asset.Name)" "Info"
            Write-Log "  Size: $([math]::Round($release.Asset.Size / 1MB, 2)) MB" "Info"
            Write-Log "  URL: $($release.Asset.DownloadUrl)" "Info"
        } else {
            throw "Could not find Windows executable in release assets"
        }
    }
    catch {
        Write-Log "GitHub API failed: $($_.Exception.Message)" "Error"
        throw "Unable to fetch release information"
    }
    
    # Download the executable
    Write-Log "Downloading Velociraptor executable..." "Progress"
    $exePath = "$binPath\velociraptor.exe"
    Write-Log "Downloading to: $exePath" "Info"
    
    try {
        Write-Log "Starting download using Invoke-WebRequest..." "Info"
        Write-Log "This may take a few minutes for a $([math]::Round($release.Asset.Size / 1MB, 2)) MB file..." "Warning"
        
        # Use Invoke-WebRequest with progress
        Invoke-WebRequest -Uri $release.Asset.DownloadUrl -OutFile $exePath -ErrorAction Stop
        
        if (Test-Path $exePath) {
            $fileSize = (Get-Item $exePath).Length
            Write-Log "Download completed successfully" "Success"
            Write-Log "  File size: $([math]::Round($fileSize / 1MB, 2)) MB" "Info"
            Write-Log "  Expected: $([math]::Round($release.Asset.Size / 1MB, 2)) MB" "Info"
            
            if ([math]::Abs($fileSize - $release.Asset.Size) -lt 1024) {
                Write-Log "File size verification: PASSED" "Success"
            } else {
                Write-Log "File size verification: WARNING - Size mismatch" "Warning"
            }
        } else {
            throw "Download failed - file not found"
        }
    }
    catch {
        Write-Log "Download failed: $($_.Exception.Message)" "Error"
        throw
    }
    
    # Verify the executable
    Write-Log "Verifying executable..." "Progress"
    Write-Log "Verifying Velociraptor executable..." "Info"
    
    try {
        # Test if file exists and is executable
        if (Test-Path $exePath) {
            $fileInfo = Get-Item $exePath
            Write-Log "File exists: $($fileInfo.Name) ($([math]::Round($fileInfo.Length / 1MB, 2)) MB)" "Success"
            
            # Try to get version info
            Write-Log "Testing executable..." "Info"
            $versionOutput = & $exePath version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Executable verification successful" "Success"
                Write-Log "  Version: $($versionOutput | Select-Object -First 1)" "Info"
            } else {
                Write-Log "Executable verification completed with exit code $LASTEXITCODE" "Warning"
                Write-Log "  Output: $versionOutput" "Info"
            }
        } else {
            throw "Executable file not found after download"
        }
    }
    catch {
        Write-Log "Could not verify executable: $($_.Exception.Message)" "Warning"
        Write-Log "Continuing with installation anyway..." "Info"
    }
    
    # Create basic server configuration
    Write-Log "Creating server configuration..." "Progress"
    $configPath = "$installPath\server.config.yaml"
    Write-Log "Creating server configuration: $configPath" "Info"
    
    $serverConfig = @"
version:
  name: velociraptor
  version: $($release.Version)

datastore:
  implementation: FileBaseDataStore
  location: $installPath\datastore
  filestore_directory: $installPath\filestore

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
  output_directory: $installPath\logs
  separate_logs_per_component: true
  level: INFO
"@
    
    Set-Content -Path $configPath -Value $serverConfig -Encoding UTF8
    Write-Log "Server configuration created successfully" "Success"
    
    # Configure Windows Firewall
    Write-Log "Configuring Windows Firewall..." "Progress"
    Write-Log "Configuring Windows Firewall rules..." "Info"
    
    try {
        if ($isAdmin) {
            # Add firewall rules for Velociraptor
            $null = netsh advfirewall firewall add rule name="Velociraptor GUI" dir=in action=allow protocol=TCP localport=8889 2>&1
            $null = netsh advfirewall firewall add rule name="Velociraptor Frontend" dir=in action=allow protocol=TCP localport=8000 2>&1
            Write-Log "Firewall rules added for ports 8000 and 8889" "Success"
        } else {
            Write-Log "Skipping firewall configuration (requires admin privileges)" "Warning"
        }
    }
    catch {
        Write-Log "Firewall configuration failed: $($_.Exception.Message)" "Warning"
    }
    
    # Create launch script
    Write-Log "Creating launch scripts..." "Progress"
    $launchScript = "$installPath\Launch-Velociraptor.bat"
    $launchContent = @"
@echo off
echo Starting Velociraptor Server...
cd /d "$installPath"
"$exePath" --config "$configPath" gui
pause
"@
    Set-Content -Path $launchScript -Value $launchContent -Encoding ASCII
    Write-Log "Launch script created: $launchScript" "Success"
    
    # Create supporting directories
    $directories = @("datastore", "filestore", "logs")
    foreach ($dir in $directories) {
        $dirPath = "$installPath\$dir"
        if (-not (Test-Path $dirPath)) {
            New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
            Write-Log "Created $dir directory" "Success"
        }
    }
    
    # Installation complete
    Write-Log "=== INSTALLATION COMPLETED SUCCESSFULLY ===" "Success"
    Write-Host ""
    Write-Log "Velociraptor v$($release.Version) has been installed to:" "Success"
    Write-Log "  Installation: $installPath" "Info"
    Write-Log "  Executable: $exePath" "Info"
    Write-Log "  Configuration: $configPath" "Info"
    Write-Log "  Launch Script: $launchScript" "Info"
    Write-Host ""
    Write-Log "To start Velociraptor:" "Info"
    Write-Log "1. Option 1: Double-click $launchScript" "Info"
    Write-Log "2. Option 2: Run the command below manually" "Info"
    Write-Log "3. Then open browser to: http://127.0.0.1:8889" "Info"
    Write-Host ""
    
    # Ask user if they want to launch now
    Write-Host "Would you like to launch Velociraptor now? (Y/N): " -ForegroundColor Yellow -NoNewline
    $response = Read-Host
    
    if ($response -match '^[Yy]') {
        Write-Log "Launching Velociraptor server..." "Progress"
        
        try {
            Write-Log "Starting Velociraptor with config: $configPath" "Info"
            $process = Start-Process -FilePath $exePath -ArgumentList "--config", $configPath, "gui" -WorkingDirectory $installPath -PassThru
            Write-Log "Velociraptor process started with PID: $($process.Id)" "Success"
            Write-Log "Waiting 8 seconds for server to start..." "Info"
            
            # Wait for server to start
            Start-Sleep -Seconds 8
            
            Write-Log "Opening browser to http://127.0.0.1:8889" "Info"
            Start-Process "http://127.0.0.1:8889"
            
            Write-Host ""
            Write-Log "=== VELOCIRAPTOR IS NOW RUNNING! ===" "Success"
            Write-Log "Access the web interface at: http://127.0.0.1:8889" "Success"
            Write-Log "The server is running in the background." "Info"
            Write-Host ""
        }
        catch {
            Write-Log "Failed to launch Velociraptor: $($_.Exception.Message)" "Error"
            Write-Log "You can manually launch it using: $launchScript" "Info"
        }
    } else {
        Write-Log "Installation complete. Launch Velociraptor when ready using:" "Info"
        Write-Log "$launchScript" "Info"
    }
    
}
catch {
    Write-Log "INSTALLATION FAILED: $($_.Exception.Message)" "Error"
    Write-Host ""
    Write-Host "Installation failed. Please check the error above and try again." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")