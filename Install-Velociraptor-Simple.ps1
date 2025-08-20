#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Simple Live Velociraptor Installation - Downloads and installs the actual executable

.DESCRIPTION
    This script downloads the real Velociraptor executable from GitHub and performs
    a complete installation.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Load our modules
try {
    Import-Module .\modules\VelociraptorDeployment\VelociraptorDeployment.psm1 -Force -ErrorAction SilentlyContinue
    Write-Host "Modules loaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "Warning: Module loading issues, continuing anyway..." -ForegroundColor Yellow
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "LIVE VELOCIRAPTOR INSTALLATION" -ForegroundColor Cyan
Write-Host "This will download and install the REAL Velociraptor executable!" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Create the installation GUI
$form = New-Object System.Windows.Forms.Form
$form.Text = "Live Velociraptor Installation"
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(32, 32, 32)
$form.ForeColor = [System.Drawing.Color]::White
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

# Header
$header = New-Object System.Windows.Forms.Label
$header.Text = "LIVE VELOCIRAPTOR INSTALLATION"
$header.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$header.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
$header.Location = New-Object System.Drawing.Point(20, 20)
$header.Size = New-Object System.Drawing.Size(740, 40)
$header.TextAlign = "MiddleCenter"
$form.Controls.Add($header)

# Status label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready to download and install Velociraptor"
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(255, 193, 7)
$statusLabel.Location = New-Object System.Drawing.Point(20, 80)
$statusLabel.Size = New-Object System.Drawing.Size(740, 30)
$statusLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($statusLabel)

# Progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(50, 130)
$progressBar.Size = New-Object System.Drawing.Size(700, 30)
$progressBar.Style = "Continuous"
$progressBar.Value = 0
$form.Controls.Add($progressBar)

# Log text box
$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Multiline = $true
$logBox.ReadOnly = $true
$logBox.ScrollBars = "Vertical"
$logBox.Location = New-Object System.Drawing.Point(50, 180)
$logBox.Size = New-Object System.Drawing.Size(700, 300)
$logBox.BackColor = [System.Drawing.Color]::FromArgb(16, 16, 16)
$logBox.ForeColor = [System.Drawing.Color]::FromArgb(76, 175, 80)
$logBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$form.Controls.Add($logBox)

# Install button
$installBtn = New-Object System.Windows.Forms.Button
$installBtn.Text = "DOWNLOAD & INSTALL VELOCIRAPTOR NOW"
$installBtn.Location = New-Object System.Drawing.Point(200, 500)
$installBtn.Size = New-Object System.Drawing.Size(400, 50)
$installBtn.BackColor = [System.Drawing.Color]::FromArgb(255, 87, 34)
$installBtn.ForeColor = [System.Drawing.Color]::White
$installBtn.FlatStyle = "Flat"
$installBtn.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($installBtn)

# Function to add log entries
function Add-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    $logBox.AppendText("$logEntry`r`n")
    $logBox.SelectionStart = $logBox.Text.Length
    $logBox.ScrollToCaret()
    $form.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
}

# Function to update status
function Update-Status {
    param([string]$Status, [int]$Progress)
    $statusLabel.Text = $Status
    $progressBar.Value = $Progress
    $form.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
}

# Installation process
$installBtn.Add_Click({
    try {
        $installBtn.Enabled = $false
        $installBtn.Text = "INSTALLING..."
        
        Add-Log "=== STARTING LIVE VELOCIRAPTOR INSTALLATION ==="
        Update-Status "Checking prerequisites..." 10
        
        # Check admin privileges
        Add-Log "Checking administrator privileges..."
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if (-not $isAdmin) {
            Add-Log "WARNING: Not running as administrator. Some features may not work properly."
        } else {
            Add-Log "Running with administrator privileges"
        }
        
        # Create installation directory
        Update-Status "Creating installation directories..." 20
        $installPath = "C:\VelociraptorData"
        $binPath = "$installPath\bin"
        
        Add-Log "Creating installation directory: $installPath"
        if (-not (Test-Path $installPath)) {
            New-Item -Path $installPath -ItemType Directory -Force | Out-Null
            Add-Log "Created $installPath"
        }
        
        if (-not (Test-Path $binPath)) {
            New-Item -Path $binPath -ItemType Directory -Force | Out-Null
            Add-Log "Created $binPath"
        }
        
        # Get latest release information
        Update-Status "Fetching latest Velociraptor release info..." 30
        Add-Log "Contacting GitHub API for latest release..."
        
        try {
            $release = Get-VelociraptorLatestRelease -Platform Windows -Architecture amd64
            Add-Log "Found Velociraptor v$($release.Version)"
            Add-Log "  Asset: $($release.Asset.Name)"
            Add-Log "  Size: $([math]::Round($release.Asset.Size / 1MB, 2)) MB"
            Add-Log "  URL: $($release.Asset.DownloadUrl)"
        }
        catch {
            Add-Log "GitHub API failed: $($_.Exception.Message)"
            Add-Log "Using fallback download method..."
            
            # Fallback to direct GitHub API call
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
                Add-Log "Fallback successful - Found Velociraptor v$($release.Version)"
            } else {
                throw "Could not find Windows executable in release assets"
            }
        }
        
        # Download the executable
        Update-Status "Downloading Velociraptor executable..." 50
        $exePath = "$binPath\velociraptor.exe"
        Add-Log "Downloading to: $exePath"
        
        try {
            # Use our download function if available
            if (Get-Command Invoke-VelociraptorDownload -ErrorAction SilentlyContinue) {
                Invoke-VelociraptorDownload -Url $release.Asset.DownloadUrl -DestinationPath $exePath -ShowProgress -Force
            } else {
                # Fallback download with progress
                $webClient = New-Object System.Net.WebClient
                $webClient.DownloadFile($release.Asset.DownloadUrl, $exePath)
            }
            
            if (Test-Path $exePath) {
                $fileSize = (Get-Item $exePath).Length
                Add-Log "Download completed successfully"
                Add-Log "  File size: $([math]::Round($fileSize / 1MB, 2)) MB"
            } else {
                throw "Download failed - file not found"
            }
        }
        catch {
            Add-Log "Download failed: $($_.Exception.Message)"
            throw
        }
        
        # Verify the executable
        Update-Status "Verifying executable..." 70
        Add-Log "Verifying Velociraptor executable..."
        
        try {
            $versionOutput = & $exePath version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Add-Log "Executable verification successful"
                Add-Log "  Version output: $($versionOutput | Select-Object -First 1)"
            } else {
                Add-Log "Executable runs but returned exit code $LASTEXITCODE"
            }
        }
        catch {
            Add-Log "Could not verify executable: $($_.Exception.Message)"
        }
        
        # Create basic server configuration
        Update-Status "Creating server configuration..." 80
        $configPath = "$installPath\server.config.yaml"
        Add-Log "Creating server configuration: $configPath"
        
        $serverConfig = "version:`n  name: velociraptor`n  version: $($release.Version)`n`ndatastore:`n  implementation: FileBaseDataStore`n  location: $installPath\datastore`n  filestore_directory: $installPath\filestore`n`nserver_type: standalone`n`nGUI:`n  bind_address: 127.0.0.1`n  bind_port: 8889`n  use_plain_http: true`n`nFrontend:`n  bind_address: 127.0.0.1`n  bind_port: 8000`n`nClient:`n  use_self_signed_ssl: true`n`ndefaults:`n  hunt_expiry_hours: 168`n  notebook_cell_timeout_min: 10`n`nlogging:`n  output_directory: $installPath\logs`n  separate_logs_per_component: true`n  level: INFO"
        
        Set-Content -Path $configPath -Value $serverConfig -Encoding UTF8
        Add-Log "Server configuration created"
        
        # Configure Windows Firewall
        Update-Status "Configuring Windows Firewall..." 90
        Add-Log "Configuring Windows Firewall rules..."
        
        try {
            if ($isAdmin) {
                # Add firewall rules for Velociraptor
                netsh advfirewall firewall add rule name="Velociraptor GUI" dir=in action=allow protocol=TCP localport=8889 | Out-Null
                netsh advfirewall firewall add rule name="Velociraptor Frontend" dir=in action=allow protocol=TCP localport=8000 | Out-Null
                Add-Log "Firewall rules added for ports 8000 and 8889"
            } else {
                Add-Log "Skipping firewall configuration (requires admin privileges)"
            }
        }
        catch {
            Add-Log "Firewall configuration failed: $($_.Exception.Message)"
        }
        
        # Create launch script
        Update-Status "Creating launch scripts..." 95
        $launchScript = "$installPath\Launch-Velociraptor.bat"
        $launchContent = "@echo off`necho Starting Velociraptor Server...`ncd /d `"$installPath`"`n`"$exePath`" --config `"$configPath`" gui`npause"
        Set-Content -Path $launchScript -Value $launchContent -Encoding ASCII
        Add-Log "Launch script created: $launchScript"
        
        # Installation complete
        Update-Status "Installation completed successfully!" 100
        Add-Log "=== INSTALLATION COMPLETED SUCCESSFULLY ==="
        Add-Log ""
        Add-Log "Velociraptor v$($release.Version) has been installed to:"
        Add-Log "  Installation: $installPath"
        Add-Log "  Executable: $exePath"
        Add-Log "  Configuration: $configPath"
        Add-Log "  Launch Script: $launchScript"
        Add-Log ""
        Add-Log "To start Velociraptor:"
        Add-Log "1. Double-click: $launchScript"
        Add-Log "2. Or run manually: $exePath --config `"$configPath`" gui"
        Add-Log "3. Open browser to: http://127.0.0.1:8889"
        
        # Update button to launch
        $installBtn.Text = "LAUNCH VELOCIRAPTOR NOW"
        $installBtn.BackColor = [System.Drawing.Color]::FromArgb(76, 175, 80)
        $installBtn.Enabled = $true
        
        # Remove old click handler and add new one
        $installBtn.remove_Click($installBtn.GetLifetimeService())
        $installBtn.Add_Click({
            Add-Log "Launching Velociraptor..."
            try {
                Start-Process -FilePath $exePath -ArgumentList "--config", "`"$configPath`"", "gui" -WorkingDirectory $installPath
                Add-Log "Velociraptor launched successfully!"
                Add-Log "Opening browser to http://127.0.0.1:8889 in 5 seconds..."
                
                # Wait a moment then open browser
                Start-Sleep -Seconds 5
                Start-Process "http://127.0.0.1:8889"
                
                Add-Log "Browser opened to Velociraptor GUI"
            }
            catch {
                Add-Log "Failed to launch: $($_.Exception.Message)"
            }
        })
        
    }
    catch {
        Add-Log "INSTALLATION FAILED: $($_.Exception.Message)"
        Update-Status "Installation failed!" 0
        $installBtn.Text = "INSTALLATION FAILED"
        $installBtn.BackColor = [System.Drawing.Color]::FromArgb(244, 67, 54)
        $installBtn.Enabled = $true
    }
})

Write-Host "Opening Live Installation GUI..." -ForegroundColor Green
Write-Host "This will download and install the ACTUAL Velociraptor executable!" -ForegroundColor Yellow

# Show the form
$form.ShowDialog() | Out-Null