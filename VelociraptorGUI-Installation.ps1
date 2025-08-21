#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Velociraptor Installation & Configuration GUI - Complete Working Version

.DESCRIPTION
    A complete GUI that includes:
    - Proper Windows Forms initialization
    - Real Velociraptor download and installation
    - Configuration wizard functionality
    - Proven working installation methods from v5.0.2-beta

.EXAMPLE
    .\VelociraptorGUI-Installation.ps1
#>

[CmdletBinding()]
param(
    [switch]$StartMinimized
)

# CRITICAL: Set execution policy and error handling FIRST
$ErrorActionPreference = 'Stop'

Write-Host "Velociraptor Installation and Configuration GUI v5.0.3" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# Step 1: Initialize Windows Forms with PROPER ORDER
Write-Host "🔧 Initializing Windows Forms..." -ForegroundColor Yellow

try {
    # CRITICAL: Load assemblies FIRST, then call SetCompatibleTextRenderingDefault
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    
    # NOW call SetCompatibleTextRenderingDefault after assemblies are loaded
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
    
    # Then enable visual styles
    [System.Windows.Forms.Application]::EnableVisualStyles()
    
    Write-Host "✅ Windows Forms initialized successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Windows Forms initialization failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "🔧 Trying alternative initialization..." -ForegroundColor Yellow
    
    try {
        [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
        [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
        Write-Host "✅ Alternative initialization successful" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ All initialization methods failed." -ForegroundColor Red
        exit 1
    }
}

# Step 2: Define colors and constants
$Colors = @{
    DarkBackground = [System.Drawing.Color]::FromArgb(32, 32, 32)
    DarkSurface = [System.Drawing.Color]::FromArgb(48, 48, 48)
    PrimaryTeal = [System.Drawing.Color]::FromArgb(0, 150, 136)
    SuccessGreen = [System.Drawing.Color]::FromArgb(0, 255, 127)
    WarningOrange = [System.Drawing.Color]::FromArgb(255, 165, 0)
    WhiteText = [System.Drawing.Color]::White
    LightGrayText = [System.Drawing.Color]::LightGray
}

# Global variables for installation
$Script:InstallDir = 'C:\tools'
$Script:DataStore = 'C:\VelociraptorData'
$Script:CurrentStep = 'welcome'
$Script:DownloadProgress = 0

############  Helper Functions - Proven Working Methods  #####################

function Write-LogToGUI {
    param([string]$Message, [string]$Level = 'Info')
    
    if ($Script:LogTextBox) {
        $timestamp = Get-Date -Format 'HH:mm:ss'
        $logEntry = "[$timestamp] [$Level] $Message"
        
        $Script:LogTextBox.Invoke([Action] {
            $Script:LogTextBox.AppendText("$logEntry`r`n")
            $Script:LogTextBox.ScrollToCaret()
        })
    }
    
    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        default { 'White' }
    }
    
    Write-Host "[$Level] $Message" -ForegroundColor $color
}

function Get-LatestVelociraptorAsset {
    Write-LogToGUI 'Querying GitHub for the latest Velociraptor release...'
    try {
        # Set TLS 1.2 for older systems
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        
        $apiUrl = "https://api.github.com/repos/Velocidex/velociraptor/releases/latest"
        $response = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
        $windowsAsset = $response.assets | Where-Object { 
            $_.name -like "*windows-amd64.exe" -and 
            $_.name -notlike "*debug*" -and 
            $_.name -notlike "*collector*"
        } | Select-Object -First 1
        
        if (-not $windowsAsset) {
            throw "Could not find Windows executable in release assets"
        }
        
        $version = $response.tag_name -replace '^v', ''
        Write-LogToGUI "Found Velociraptor v$version ($([math]::Round($windowsAsset.size / 1MB, 1)) MB)" -Level 'Success'
        
        return @{
            Version = $version
            DownloadUrl = $windowsAsset.browser_download_url
            Size = $windowsAsset.size
            Name = $windowsAsset.name
        }
    }
    catch {
        Write-LogToGUI "Failed to query GitHub API - $($_.Exception.Message)" -Level 'Error'
        throw
    }
}

function Install-VelociraptorExecutable {
    param($AssetInfo, [string]$DestinationPath)
    
    Write-LogToGUI "Downloading $($AssetInfo.Name) ($([math]::Round($AssetInfo.Size / 1MB, 1)) MB)..."
    
    try {
        $tempFile = "$DestinationPath.download"
        
        # Create directory if it doesn't exist
        $directory = Split-Path $DestinationPath -Parent
        if (-not (Test-Path $directory)) {
            New-Item -ItemType Directory $directory -Force | Out-Null
            Write-LogToGUI "Created directory: $directory" -Level 'Success'
        }
        
        # Use proven working download method
        $webClient = New-Object System.Net.WebClient
        
        # Add progress handler for GUI updates
        $webClient.add_DownloadProgressChanged({
            param($sender, $e)
            $Script:DownloadProgress = $e.ProgressPercentage
            if ($Script:ProgressBar) {
                $Script:ProgressBar.Invoke([Action] {
                    $Script:ProgressBar.Value = $Script:DownloadProgress
                })
            }
            if ($Script:StatusLabel) {
                $Script:StatusLabel.Invoke([Action] {
                    $Script:StatusLabel.Text = "Downloading... $($Script:DownloadProgress)%"
                })
            }
        })
        
        $webClient.DownloadFile($AssetInfo.DownloadUrl, $tempFile)
        
        if (Test-Path $tempFile) {
            $fileSize = (Get-Item $tempFile).Length
            Write-LogToGUI "Download completed: $([math]::Round($fileSize / 1MB, 1)) MB" -Level 'Success'
            
            # Verify file size
            if ([math]::Abs($fileSize - $AssetInfo.Size) -lt 1024) {
                Write-LogToGUI "File size verification: PASSED" -Level 'Success'
            } else {
                Write-LogToGUI "File size verification: WARNING - Size mismatch" -Level 'Warning'
            }
            
            # Verify download is not empty
            if ($fileSize -eq 0) {
                throw "Downloaded file is empty"
            }
            
            Move-Item $tempFile $DestinationPath -Force
            Write-LogToGUI "Successfully installed to $DestinationPath" -Level 'Success'
            
            # Test executable
            try {
                $versionOutput = & $DestinationPath version 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-LogToGUI "Executable verification: PASSED" -Level 'Success'
                    return $true
                }
            }
            catch {
                Write-LogToGUI "Executable verification: WARNING (non-critical)" -Level 'Warning'
            }
            
            return $true
        } else {
            throw "Download file not found at $tempFile"
        }
    }
    catch {
        Write-LogToGUI "Download failed - $($_.Exception.Message)" -Level 'Error'
        if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
        throw
    }
    finally {
        if ($webClient) { $webClient.Dispose() }
        if ($Script:ProgressBar) {
            $Script:ProgressBar.Invoke([Action] {
                $Script:ProgressBar.Value = 0
            })
        }
        if ($Script:StatusLabel) {
            $Script:StatusLabel.Invoke([Action] {
                $Script:StatusLabel.Text = "Ready"
            })
        }
    }
}

function Start-VelociraptorInstallation {
    try {
        Write-LogToGUI "=== STARTING VELOCIRAPTOR INSTALLATION ===" -Level 'Success'
        
        # Update UI to show installation in progress
        if ($Script:InstallButton) {
            $Script:InstallButton.Invoke([Action] {
                $Script:InstallButton.Enabled = $false
                $Script:InstallButton.Text = "Installing..."
            })
        }
        
        # Create directories
        foreach ($directory in @($Script:InstallDir, $Script:DataStore)) {
            if (-not (Test-Path $directory)) {
                New-Item -ItemType Directory $directory -Force | Out-Null
                Write-LogToGUI "Created directory: $directory" -Level 'Success'
            }
            else {
                Write-LogToGUI "Directory exists: $directory"
            }
        }
        
        # Download and install Velociraptor
        $executablePath = Join-Path $Script:InstallDir 'velociraptor.exe'
        $assetInfo = Get-LatestVelociraptorAsset
        $success = Install-VelociraptorExecutable -AssetInfo $assetInfo -DestinationPath $executablePath
        
        if ($success) {
            Write-LogToGUI "=== INSTALLATION COMPLETED SUCCESSFULLY ===" -Level 'Success'
            Write-LogToGUI "Velociraptor installed to: $executablePath" -Level 'Success'
            Write-LogToGUI "Data directory: $Script:DataStore" -Level 'Success'
            
            # Update UI to show success
            if ($Script:InstallButton) {
                $Script:InstallButton.Invoke([Action] {
                    $Script:InstallButton.Text = "✅ Installation Complete"
                    $Script:InstallButton.BackColor = $Colors.SuccessGreen
                    $Script:InstallButton.ForeColor = [System.Drawing.Color]::Black
                })
            }
            
            if ($Script:LaunchButton) {
                $Script:LaunchButton.Invoke([Action] {
                    $Script:LaunchButton.Enabled = $true
                })
            }
            
            [System.Windows.Forms.MessageBox]::Show(
                "Velociraptor installation completed successfully!`n`nInstalled to: $executablePath`nData directory: $Script:DataStore`n`nYou can now launch Velociraptor using the 'Launch Velociraptor' button.",
                "Installation Complete",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
    }
    catch {
        Write-LogToGUI "Installation failed - $($_.Exception.Message)" -Level 'Error'
        
        # Update UI to show error
        if ($Script:InstallButton) {
            $Script:InstallButton.Invoke([Action] {
                $Script:InstallButton.Enabled = $true
                $Script:InstallButton.Text = "❌ Install Failed - Retry"
                $Script:InstallButton.BackColor = [System.Drawing.Color]::Red
            })
        }
        
        [System.Windows.Forms.MessageBox]::Show(
            "Installation failed: $($_.Exception.Message)",
            "Installation Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Start-VelociraptorLaunch {
    try {
        $executablePath = Join-Path $Script:InstallDir 'velociraptor.exe'
        
        if (-not (Test-Path $executablePath)) {
            throw "Velociraptor executable not found. Please install first."
        }
        
        Write-LogToGUI "Launching Velociraptor GUI service..." -Level 'Success'
        
        $arguments = "gui --datastore `"$Script:DataStore`""
        $process = Start-Process $executablePath -ArgumentList $arguments -WorkingDirectory $Script:InstallDir -PassThru
        
        if ($process) {
            Write-LogToGUI "Velociraptor process started (PID: $($process.Id))" -Level 'Success'
            
            # Wait a moment for startup
            Start-Sleep -Seconds 5
            
            Write-LogToGUI "Opening web interface..." -Level 'Success'
            Start-Process "https://127.0.0.1:8889"
            
            Write-LogToGUI "Velociraptor GUI is ready at: https://127.0.0.1:8889" -Level 'Success'
            Write-LogToGUI "Default credentials: admin / password" -Level 'Warning'
            
            [System.Windows.Forms.MessageBox]::Show(
                "Velociraptor launched successfully!`n`nWeb Interface: https://127.0.0.1:8889`nProcess ID: $($process.Id)`n`nDefault credentials: admin / password",
                "Launch Successful",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
        else {
            throw "Failed to start Velociraptor process"
        }
    }
    catch {
        Write-LogToGUI "Launch failed - $($_.Exception.Message)" -Level 'Error'
        
        [System.Windows.Forms.MessageBox]::Show(
            "Launch failed: $($_.Exception.Message)",
            "Launch Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

############  GUI Creation  ###################################################

# Step 3: Create the main form
Write-Host "🏗️ Creating main form..." -ForegroundColor Yellow

try {
    $MainForm = New-Object System.Windows.Forms.Form
    $MainForm.Text = "Velociraptor Installation and Configuration Wizard v5.0.3"
    $MainForm.Size = New-Object System.Drawing.Size(1000, 700)
    $MainForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $MainForm.BackColor = $Colors.DarkBackground
    $MainForm.ForeColor = $Colors.WhiteText
    $MainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $MainForm.MaximizeBox = $false
    $MainForm.MinimizeBox = $true
    
    Write-Host "✅ Main form created successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to create main form: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 4: Create header
Write-Host "📋 Creating header..." -ForegroundColor Yellow

try {
    $HeaderPanel = New-Object System.Windows.Forms.Panel
    $HeaderPanel.Size = New-Object System.Drawing.Size(980, 80)
    $HeaderPanel.Location = New-Object System.Drawing.Point(10, 10)
    $HeaderPanel.BackColor = $Colors.DarkSurface
    
    $TitleLabel = New-Object System.Windows.Forms.Label
    $TitleLabel.Text = "Velociraptor DFIR Framework - Installation and Configuration"
    $TitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $TitleLabel.ForeColor = $Colors.PrimaryTeal
    $TitleLabel.Location = New-Object System.Drawing.Point(20, 15)
    $TitleLabel.Size = New-Object System.Drawing.Size(800, 25)
    
    $SubtitleLabel = New-Object System.Windows.Forms.Label
    $SubtitleLabel.Text = "Complete Installation Wizard - Free For All First Responders"
    $SubtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $SubtitleLabel.ForeColor = $Colors.LightGrayText
    $SubtitleLabel.Location = New-Object System.Drawing.Point(20, 45)
    $SubtitleLabel.Size = New-Object System.Drawing.Size(500, 20)
    
    $HeaderPanel.Controls.Add($TitleLabel)
    $HeaderPanel.Controls.Add($SubtitleLabel)
    $MainForm.Controls.Add($HeaderPanel)
    
    Write-Host "✅ Header created successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to create header: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 5: Create content area with installation controls
Write-Host "📝 Creating installation interface..." -ForegroundColor Yellow

try {
    $ContentPanel = New-Object System.Windows.Forms.Panel
    $ContentPanel.Size = New-Object System.Drawing.Size(980, 480)
    $ContentPanel.Location = New-Object System.Drawing.Point(10, 100)
    $ContentPanel.BackColor = $Colors.DarkSurface
    
    # Configuration section
    $ConfigLabel = New-Object System.Windows.Forms.Label
    $ConfigLabel.Text = "Installation Configuration:"
    $ConfigLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $ConfigLabel.ForeColor = $Colors.WarningOrange
    $ConfigLabel.Location = New-Object System.Drawing.Point(20, 20)
    $ConfigLabel.Size = New-Object System.Drawing.Size(300, 25)
    
    # Install directory
    $InstallDirLabel = New-Object System.Windows.Forms.Label
    $InstallDirLabel.Text = "Installation Directory:"
    $InstallDirLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $InstallDirLabel.ForeColor = $Colors.WhiteText
    $InstallDirLabel.Location = New-Object System.Drawing.Point(40, 55)
    $InstallDirLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $InstallDirTextBox = New-Object System.Windows.Forms.TextBox
    $InstallDirTextBox.Text = $Script:InstallDir
    $InstallDirTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $InstallDirTextBox.BackColor = $Colors.DarkBackground
    $InstallDirTextBox.ForeColor = $Colors.WhiteText
    $InstallDirTextBox.Location = New-Object System.Drawing.Point(200, 53)
    $InstallDirTextBox.Size = New-Object System.Drawing.Size(300, 25)
    $InstallDirTextBox.Add_TextChanged({
        $Script:InstallDir = $InstallDirTextBox.Text
    })
    
    # Data directory
    $DataDirLabel = New-Object System.Windows.Forms.Label
    $DataDirLabel.Text = "Data Directory:"
    $DataDirLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $DataDirLabel.ForeColor = $Colors.WhiteText
    $DataDirLabel.Location = New-Object System.Drawing.Point(40, 85)
    $DataDirLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $DataDirTextBox = New-Object System.Windows.Forms.TextBox
    $DataDirTextBox.Text = $Script:DataStore
    $DataDirTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $DataDirTextBox.BackColor = $Colors.DarkBackground
    $DataDirTextBox.ForeColor = $Colors.WhiteText
    $DataDirTextBox.Location = New-Object System.Drawing.Point(200, 83)
    $DataDirTextBox.Size = New-Object System.Drawing.Size(300, 25)
    $DataDirTextBox.Add_TextChanged({
        $Script:DataStore = $DataDirTextBox.Text
    })
    
    # Progress bar
    $Script:ProgressBar = New-Object System.Windows.Forms.ProgressBar
    $Script:ProgressBar.Location = New-Object System.Drawing.Point(40, 120)
    $Script:ProgressBar.Size = New-Object System.Drawing.Size(460, 20)
    $Script:ProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
    
    # Status label
    $Script:StatusLabel = New-Object System.Windows.Forms.Label
    $Script:StatusLabel.Text = "Ready"
    $Script:StatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $Script:StatusLabel.ForeColor = $Colors.LightGrayText
    $Script:StatusLabel.Location = New-Object System.Drawing.Point(40, 150)
    $Script:StatusLabel.Size = New-Object System.Drawing.Size(460, 20)
    
    # Log area
    $LogLabel = New-Object System.Windows.Forms.Label
    $LogLabel.Text = "Installation Log:"
    $LogLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $LogLabel.ForeColor = $Colors.WarningOrange
    $LogLabel.Location = New-Object System.Drawing.Point(20, 185)
    $LogLabel.Size = New-Object System.Drawing.Size(200, 25)
    
    $Script:LogTextBox = New-Object System.Windows.Forms.TextBox
    $Script:LogTextBox.Multiline = $true
    $Script:LogTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $Script:LogTextBox.BackColor = $Colors.DarkBackground
    $Script:LogTextBox.ForeColor = $Colors.WhiteText
    $Script:LogTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $Script:LogTextBox.Location = New-Object System.Drawing.Point(20, 215)
    $Script:LogTextBox.Size = New-Object System.Drawing.Size(940, 240)
    $Script:LogTextBox.ReadOnly = $true
    
    # Add all controls to content panel
    $ContentPanel.Controls.AddRange(@(
        $ConfigLabel, $InstallDirLabel, $InstallDirTextBox,
        $DataDirLabel, $DataDirTextBox, $Script:ProgressBar,
        $Script:StatusLabel, $LogLabel, $Script:LogTextBox
    ))
    
    $MainForm.Controls.Add($ContentPanel)
    
    Write-Host "✅ Installation interface created successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to create installation interface: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 6: Create buttons
Write-Host "🔘 Creating action buttons..." -ForegroundColor Yellow

try {
    $ButtonPanel = New-Object System.Windows.Forms.Panel
    $ButtonPanel.Size = New-Object System.Drawing.Size(980, 60)
    $ButtonPanel.Location = New-Object System.Drawing.Point(10, 590)
    $ButtonPanel.BackColor = $Colors.DarkSurface
    
    # Install button
    $Script:InstallButton = New-Object System.Windows.Forms.Button
    $Script:InstallButton.Text = "🚀 Install Velociraptor"
    $Script:InstallButton.Size = New-Object System.Drawing.Size(180, 35)
    $Script:InstallButton.Location = New-Object System.Drawing.Point(500, 15)
    $Script:InstallButton.BackColor = $Colors.PrimaryTeal
    $Script:InstallButton.ForeColor = $Colors.WhiteText
    $Script:InstallButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $Script:InstallButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $Script:InstallButton.Add_Click({
        # Run installation in background thread to prevent GUI freeze
        $runspace = [powershell]::Create()
        $runspace.AddScript({
            param($installFunction)
            & $installFunction
        }).AddArgument(${function:Start-VelociraptorInstallation}) | Out-Null
        $runspace.BeginInvoke() | Out-Null
    })
    
    # Launch button
    $Script:LaunchButton = New-Object System.Windows.Forms.Button
    $Script:LaunchButton.Text = "🌐 Launch Velociraptor"
    $Script:LaunchButton.Size = New-Object System.Drawing.Size(150, 35)
    $Script:LaunchButton.Location = New-Object System.Drawing.Point(690, 15)
    $Script:LaunchButton.BackColor = $Colors.SuccessGreen
    $Script:LaunchButton.ForeColor = [System.Drawing.Color]::Black
    $Script:LaunchButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $Script:LaunchButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $Script:LaunchButton.Enabled = $false
    $Script:LaunchButton.Add_Click({
        Start-VelociraptorLaunch
    })
    
    # Exit button
    $ExitButton = New-Object System.Windows.Forms.Button
    $ExitButton.Text = "Exit"
    $ExitButton.Size = New-Object System.Drawing.Size(80, 35)
    $ExitButton.Location = New-Object System.Drawing.Point(860, 15)
    $ExitButton.BackColor = $Colors.DarkBackground
    $ExitButton.ForeColor = $Colors.WhiteText
    $ExitButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ExitButton.Add_Click({ $MainForm.Close() })
    
    $ButtonPanel.Controls.AddRange(@($Script:InstallButton, $Script:LaunchButton, $ExitButton))
    $MainForm.Controls.Add($ButtonPanel)
    
    Write-Host "✅ Action buttons created successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to create action buttons: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 7: Show initial log message
Write-LogToGUI "=== Velociraptor Installation GUI Ready ===" -Level 'Success'
Write-LogToGUI "Configure your installation paths and click 'Install Velociraptor' to begin."

# Step 8: Show the form
Write-Host "🚀 Launching Installation GUI..." -ForegroundColor Green

try {
    if ($StartMinimized) {
        $MainForm.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
    }
    
    Write-Host "Installation GUI launched successfully!" -ForegroundColor Green
    Write-Host "Configure paths and click 'Install Velociraptor' to begin!" -ForegroundColor Cyan
    
    # Show the form and wait for it to close
    $result = $MainForm.ShowDialog()
    
    Write-Host "✅ Installation GUI completed successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to show GUI: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
    exit 1
}
finally {
    # Cleanup
    try {
        if ($MainForm) {
            $MainForm.Dispose()
        }
    }
    catch {
        # Ignore cleanup errors
    }
}

Write-Host "Velociraptor Installation GUI session completed!" -ForegroundColor Green

