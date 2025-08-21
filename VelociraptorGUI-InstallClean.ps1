#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Velociraptor Installation GUI - Clean Working Version

.DESCRIPTION
    A complete GUI that includes:
    - Proper Windows Forms initialization
    - Real Velociraptor download and installation
    - Proven working installation methods from v5.0.2-beta

.EXAMPLE
    .\VelociraptorGUI-InstallClean.ps1
#>

[CmdletBinding()]
param(
    [switch]$StartMinimized
)

$ErrorActionPreference = 'Stop'

Write-Host "Velociraptor Installation GUI v5.0.3-beta" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Step 1: Initialize Windows Forms
Write-Host "Initializing Windows Forms..." -ForegroundColor Yellow

try {
    # CRITICAL: Load assemblies FIRST, then call SetCompatibleTextRenderingDefault
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    
    # NOW call SetCompatibleTextRenderingDefault after assemblies are loaded
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
    [System.Windows.Forms.Application]::EnableVisualStyles()
    Write-Host "Windows Forms initialized successfully" -ForegroundColor Green
}
catch {
    Write-Host "Windows Forms initialization failed: $($_.Exception.Message)" -ForegroundColor Red
    try {
        [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
        [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
        Write-Host "Alternative initialization successful" -ForegroundColor Green
    }
    catch {
        Write-Host "All initialization methods failed." -ForegroundColor Red
        exit 1
    }
}

# Step 2: Define colors
$Colors = @{
    DarkBackground = [System.Drawing.Color]::FromArgb(32, 32, 32)
    DarkSurface = [System.Drawing.Color]::FromArgb(48, 48, 48)
    PrimaryTeal = [System.Drawing.Color]::FromArgb(0, 150, 136)
    SuccessGreen = [System.Drawing.Color]::FromArgb(0, 255, 127)
    WhiteText = [System.Drawing.Color]::White
    LightGrayText = [System.Drawing.Color]::LightGray
}

# Global variables
$Script:InstallDir = 'C:\tools'
$Script:DataStore = 'C:\VelociraptorData'

# Helper Functions
function Show-UserFriendlyError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorMessage,
        
        [Parameter(Mandatory)]
        [string]$Context,
        
        [Parameter(Mandatory)]
        [string[]]$SuggestedActions,
        
        [Parameter()]
        [string]$HelpUrl = "https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts/blob/main/TROUBLESHOOTING.md"
    )
    
    $message = @"
Operation Failed: $Context

Problem: $ErrorMessage

Suggested Actions:
$($SuggestedActions | ForEach-Object { "• $_" })

Need Help?
• Check the troubleshooting guide: $HelpUrl
• Review installation logs for detailed information
• Ensure you have Administrator privileges
• Verify internet connectivity for downloads
• Contact support if issue persists
"@
    
    [System.Windows.Forms.MessageBox]::Show(
        $message, 
        "Velociraptor Setup Issue", 
        [System.Windows.Forms.MessageBoxButtons]::OK, 
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
}

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
        $webClient.DownloadFile($AssetInfo.DownloadUrl, $tempFile)
        
        if (Test-Path $tempFile) {
            $fileSize = (Get-Item $tempFile).Length
            Write-LogToGUI "Download completed: $([math]::Round($fileSize / 1MB, 1)) MB" -Level 'Success'
            
            if ([math]::Abs($fileSize - $AssetInfo.Size) -lt 1024) {
                Write-LogToGUI "File size verification: PASSED" -Level 'Success'
            } else {
                Write-LogToGUI "File size verification: WARNING - Size mismatch" -Level 'Warning'
            }
            
            if ($fileSize -eq 0) {
                throw "Downloaded file is empty"
            }
            
            Move-Item $tempFile $DestinationPath -Force
            Write-LogToGUI "Successfully installed to $DestinationPath" -Level 'Success'
            
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
    }
}

function Start-VelociraptorInstallation {
    try {
        Write-LogToGUI "=== STARTING VELOCIRAPTOR INSTALLATION ===" -Level 'Success'
        
        # Update UI
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
            
            # Update UI
            if ($Script:InstallButton) {
                $Script:InstallButton.Invoke([Action] {
                    $Script:InstallButton.Text = "Installation Complete"
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
        
        if ($Script:InstallButton) {
            $Script:InstallButton.Invoke([Action] {
                $Script:InstallButton.Enabled = $true
                $Script:InstallButton.Text = "Install Failed - Retry"
                $Script:InstallButton.BackColor = [System.Drawing.Color]::Red
            })
        }
        
        Show-UserFriendlyError -ErrorMessage $_.Exception.Message -Context "Velociraptor Installation" -SuggestedActions @(
            "Verify you have Administrator privileges",
            "Check internet connectivity",
            "Ensure sufficient disk space (500MB+ required)",
            "Verify parent directories exist and are writable",
            "Temporarily disable antivirus if blocking downloads",
            "Try running installation as Administrator"
        )
    }
}

function Start-EmergencyDeployment {
    try {
        Write-LogToGUI "=== EMERGENCY MODE ACTIVATED ===" -Level 'Warning'
        Write-LogToGUI "Initiating rapid deployment for incident response..." -Level 'Warning'
        
        # Set emergency defaults
        $Script:InstallDir = 'C:\EmergencyVelociraptor'
        $Script:DataStore = 'C:\EmergencyVelociraptor\Data'
        
        # Show confirmation dialog
        $emergencyConfirm = [System.Windows.Forms.MessageBox]::Show(
            @"
🚨 EMERGENCY DEPLOYMENT MODE 🚨

This will perform a rapid Velociraptor deployment with:
• Installation Directory: $($Script:InstallDir)
• Data Directory: $($Script:DataStore)
• Pre-configured for immediate incident response
• Minimal user interaction required

Time: ~2-3 minutes for full deployment

Continue with emergency deployment?
"@,
            "Emergency Mode Confirmation",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        
        if ($emergencyConfirm -eq [System.Windows.Forms.DialogResult]::Yes) {
            Write-LogToGUI "Emergency deployment confirmed - starting rapid installation..." -Level 'Success'
            
            # Disable emergency button during deployment
            $Script:EmergencyButton.Enabled = $false
            $Script:EmergencyButton.Text = "DEPLOYING..."
            $Script:EmergencyButton.BackColor = [System.Drawing.Color]::DarkOrange
            
            # Run emergency installation
            $runspace = [powershell]::Create()
            $runspace.AddScript({
                param($installFunction)
                & $installFunction
            }).AddArgument(${function:Start-VelociraptorInstallation}) | Out-Null
            $runspace.BeginInvoke() | Out-Null
            
            Write-LogToGUI "Emergency deployment initiated - monitor log for progress" -Level 'Warning'
        } else {
            Write-LogToGUI "Emergency deployment cancelled" -Level 'Info'
        }
    }
    catch {
        Write-LogToGUI "Emergency deployment failed: $($_.Exception.Message)" -Level 'Error'
        Show-UserFriendlyError -ErrorMessage $_.Exception.Message -Context "Emergency Deployment" -SuggestedActions @(
            "Ensure you have Administrator privileges",
            "Check available disk space (2GB+ recommended for emergency)",
            "Verify internet connectivity for downloads", 
            "Try running as Administrator",
            "Use standard installation mode if emergency fails",
            "Contact incident response team for assistance"
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
        
        Show-UserFriendlyError -ErrorMessage $_.Exception.Message -Context "Velociraptor Launch" -SuggestedActions @(
            "Verify Velociraptor installation completed successfully",
            "Check that data directory path is valid and accessible",
            "Ensure no other Velociraptor processes are running",
            "Try launching as Administrator",
            "Check Windows Firewall and antivirus settings",
            "Verify port 8889 is not in use by another application"
        )
    }
}

# Step 3: Create main form
Write-Host "Creating main form..." -ForegroundColor Yellow

try {
    $MainForm = New-Object System.Windows.Forms.Form
    $MainForm.Text = "Velociraptor Installation and Configuration Wizard v5.0.3"
    $MainForm.Size = New-Object System.Drawing.Size(900, 650)
    $MainForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $MainForm.BackColor = $Colors.DarkBackground
    $MainForm.ForeColor = $Colors.WhiteText
    $MainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $MainForm.MaximizeBox = $false
    $MainForm.MinimizeBox = $true
    
    Write-Host "Main form created successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to create main form: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 4: Create header
try {
    $HeaderPanel = New-Object System.Windows.Forms.Panel
    $HeaderPanel.Size = New-Object System.Drawing.Size(880, 80)
    $HeaderPanel.Location = New-Object System.Drawing.Point(10, 10)
    $HeaderPanel.BackColor = $Colors.DarkSurface
    
    $TitleLabel = New-Object System.Windows.Forms.Label
    $TitleLabel.Text = "Velociraptor DFIR Framework - Installation and Configuration"
    $TitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $TitleLabel.ForeColor = $Colors.PrimaryTeal
    $TitleLabel.Location = New-Object System.Drawing.Point(20, 15)
    $TitleLabel.Size = New-Object System.Drawing.Size(700, 25)
    
    $SubtitleLabel = New-Object System.Windows.Forms.Label
    $SubtitleLabel.Text = "Complete Installation Wizard - Free For All First Responders"
    $SubtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $SubtitleLabel.ForeColor = $Colors.LightGrayText
    $SubtitleLabel.Location = New-Object System.Drawing.Point(20, 45)
    $SubtitleLabel.Size = New-Object System.Drawing.Size(500, 20)
    
    $HeaderPanel.Controls.Add($TitleLabel)
    $HeaderPanel.Controls.Add($SubtitleLabel)
    $MainForm.Controls.Add($HeaderPanel)
}
catch {
    Write-Host "Failed to create header: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 5: Create content area
try {
    $ContentPanel = New-Object System.Windows.Forms.Panel
    $ContentPanel.Size = New-Object System.Drawing.Size(880, 450)
    $ContentPanel.Location = New-Object System.Drawing.Point(10, 100)
    $ContentPanel.BackColor = $Colors.DarkSurface
    
    # Install directory
    $InstallDirLabel = New-Object System.Windows.Forms.Label
    $InstallDirLabel.Text = "Installation Directory:"
    $InstallDirLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $InstallDirLabel.ForeColor = $Colors.WhiteText
    $InstallDirLabel.Location = New-Object System.Drawing.Point(20, 30)
    $InstallDirLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $InstallDirTextBox = New-Object System.Windows.Forms.TextBox
    $InstallDirTextBox.Text = $Script:InstallDir
    $InstallDirTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $InstallDirTextBox.BackColor = $Colors.DarkBackground
    $InstallDirTextBox.ForeColor = $Colors.WhiteText
    $InstallDirTextBox.Location = New-Object System.Drawing.Point(180, 28)
    $InstallDirTextBox.Size = New-Object System.Drawing.Size(300, 25)
    $InstallDirTextBox.TabIndex = 1
    $InstallDirTextBox.AccessibleName = "Installation Directory"
    $InstallDirTextBox.AccessibleDescription = "Directory where Velociraptor will be installed. Changes background color to green for valid paths."
    $InstallDirTextBox.Add_TextChanged({
        $Script:InstallDir = $InstallDirTextBox.Text
        
        # Real-time validation with visual feedback
        $parentDir = Split-Path $InstallDirTextBox.Text -Parent
        $isValidPath = $false
        
        try {
            # Check if parent directory exists or is valid path format
            if ([string]::IsNullOrWhiteSpace($InstallDirTextBox.Text)) {
                $isValidPath = $false
            } elseif ($parentDir -and (Test-Path $parentDir)) {
                $isValidPath = $true
            } elseif ([System.IO.Path]::IsPathRooted($InstallDirTextBox.Text) -and 
                      $InstallDirTextBox.Text -match '^[A-Za-z]:\\[^<>:"|?*]*$') {
                $isValidPath = $true  # Valid path format even if parent doesn't exist
            }
        } catch {
            $isValidPath = $false
        }
        
        # Update visual feedback
        $InstallDirTextBox.BackColor = if ($isValidPath) { 
            [System.Drawing.Color]::FromArgb(25, 50, 25)  # Dark green
        } else { 
            [System.Drawing.Color]::FromArgb(50, 25, 25)  # Dark red
        }
        
        # Enable/disable install button based on all validations
        if ($Script:InstallButton) {
            $Script:InstallButton.Enabled = $isValidPath -and -not [string]::IsNullOrWhiteSpace($Script:DataStore)
        }
    })
    
    # Data directory
    $DataDirLabel = New-Object System.Windows.Forms.Label
    $DataDirLabel.Text = "Data Directory:"
    $DataDirLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $DataDirLabel.ForeColor = $Colors.WhiteText
    $DataDirLabel.Location = New-Object System.Drawing.Point(20, 65)
    $DataDirLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $DataDirTextBox = New-Object System.Windows.Forms.TextBox
    $DataDirTextBox.Text = $Script:DataStore
    $DataDirTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $DataDirTextBox.BackColor = $Colors.DarkBackground
    $DataDirTextBox.ForeColor = $Colors.WhiteText
    $DataDirTextBox.Location = New-Object System.Drawing.Point(180, 63)
    $DataDirTextBox.Size = New-Object System.Drawing.Size(300, 25)
    $DataDirTextBox.TabIndex = 2
    $DataDirTextBox.AccessibleName = "Data Directory"
    $DataDirTextBox.AccessibleDescription = "Directory where Velociraptor data will be stored. Changes background color to green for valid paths."
    $DataDirTextBox.Add_TextChanged({
        $Script:DataStore = $DataDirTextBox.Text
        
        # Real-time validation with visual feedback
        $parentDir = Split-Path $DataDirTextBox.Text -Parent
        $isValidPath = $false
        
        try {
            # Check if parent directory exists or is valid path format
            if ([string]::IsNullOrWhiteSpace($DataDirTextBox.Text)) {
                $isValidPath = $false
            } elseif ($parentDir -and (Test-Path $parentDir)) {
                $isValidPath = $true
            } elseif ([System.IO.Path]::IsPathRooted($DataDirTextBox.Text) -and 
                      $DataDirTextBox.Text -match '^[A-Za-z]:\\[^<>:"|?*]*$') {
                $isValidPath = $true  # Valid path format even if parent doesn't exist
            }
        } catch {
            $isValidPath = $false
        }
        
        # Update visual feedback
        $DataDirTextBox.BackColor = if ($isValidPath) { 
            [System.Drawing.Color]::FromArgb(25, 50, 25)  # Dark green
        } else { 
            [System.Drawing.Color]::FromArgb(50, 25, 25)  # Dark red
        }
        
        # Enable/disable install button based on all validations
        if ($Script:InstallButton) {
            $Script:InstallButton.Enabled = $isValidPath -and -not [string]::IsNullOrWhiteSpace($Script:InstallDir)
        }
    })
    
    # Log area
    $LogLabel = New-Object System.Windows.Forms.Label
    $LogLabel.Text = "Installation Log:"
    $LogLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $LogLabel.ForeColor = $Colors.PrimaryTeal
    $LogLabel.Location = New-Object System.Drawing.Point(20, 110)
    $LogLabel.Size = New-Object System.Drawing.Size(200, 25)
    
    $Script:LogTextBox = New-Object System.Windows.Forms.TextBox
    $Script:LogTextBox.Multiline = $true
    $Script:LogTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $Script:LogTextBox.BackColor = $Colors.DarkBackground
    $Script:LogTextBox.ForeColor = $Colors.WhiteText
    $Script:LogTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $Script:LogTextBox.Location = New-Object System.Drawing.Point(20, 140)
    $Script:LogTextBox.Size = New-Object System.Drawing.Size(840, 280)
    $Script:LogTextBox.ReadOnly = $true
    
    $ContentPanel.Controls.AddRange(@(
        $InstallDirLabel, $InstallDirTextBox,
        $DataDirLabel, $DataDirTextBox,
        $LogLabel, $Script:LogTextBox
    ))
    
    $MainForm.Controls.Add($ContentPanel)
}
catch {
    Write-Host "Failed to create content area: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 6: Create buttons
try {
    $ButtonPanel = New-Object System.Windows.Forms.Panel
    $ButtonPanel.Size = New-Object System.Drawing.Size(880, 60)
    $ButtonPanel.Location = New-Object System.Drawing.Point(10, 560)
    $ButtonPanel.BackColor = $Colors.DarkSurface
    
    # Emergency Mode button (prominent placement)
    $Script:EmergencyButton = New-Object System.Windows.Forms.Button
    $Script:EmergencyButton.Text = "🚨 EMERGENCY MODE"
    $Script:EmergencyButton.Size = New-Object System.Drawing.Size(180, 45)
    $Script:EmergencyButton.Location = New-Object System.Drawing.Point(350, 10)
    $Script:EmergencyButton.BackColor = [System.Drawing.Color]::DarkRed
    $Script:EmergencyButton.ForeColor = [System.Drawing.Color]::White
    $Script:EmergencyButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $Script:EmergencyButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $Script:EmergencyButton.TabIndex = 3
    $Script:EmergencyButton.AccessibleName = "Emergency Mode"
    $Script:EmergencyButton.AccessibleDescription = "Activates rapid deployment mode for emergency incident response situations. One-click deployment with minimal configuration."
    $Script:EmergencyButton.Add_Click({
        Start-EmergencyDeployment
    })
    
    # Install button (moved to accommodate emergency button)
    $Script:InstallButton = New-Object System.Windows.Forms.Button
    $Script:InstallButton.Text = "Install Velociraptor"
    $Script:InstallButton.Size = New-Object System.Drawing.Size(140, 35)
    $Script:InstallButton.Location = New-Object System.Drawing.Point(550, 15)
    $Script:InstallButton.BackColor = $Colors.PrimaryTeal
    $Script:InstallButton.ForeColor = $Colors.WhiteText
    $Script:InstallButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $Script:InstallButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $Script:InstallButton.TabIndex = 4
    $Script:InstallButton.AccessibleName = "Install Velociraptor"
    $Script:InstallButton.AccessibleDescription = "Downloads and installs Velociraptor to the specified directories. Requires valid installation and data directory paths."
    $Script:InstallButton.Add_Click({
        # Run installation in background thread
        $runspace = [powershell]::Create()
        $runspace.AddScript({
            param($installFunction)
            & $installFunction
        }).AddArgument(${function:Start-VelociraptorInstallation}) | Out-Null
        $runspace.BeginInvoke() | Out-Null
    })
    
    # Launch button
    $Script:LaunchButton = New-Object System.Windows.Forms.Button
    $Script:LaunchButton.Text = "Launch Velociraptor"
    $Script:LaunchButton.Size = New-Object System.Drawing.Size(130, 35)
    $Script:LaunchButton.Location = New-Object System.Drawing.Point(710, 15)
    $Script:LaunchButton.BackColor = $Colors.SuccessGreen
    $Script:LaunchButton.ForeColor = [System.Drawing.Color]::Black
    $Script:LaunchButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $Script:LaunchButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $Script:LaunchButton.Enabled = $false
    $Script:LaunchButton.TabIndex = 5
    $Script:LaunchButton.AccessibleName = "Launch Velociraptor"
    $Script:LaunchButton.AccessibleDescription = "Launches the Velociraptor GUI interface after successful installation. Enabled only after installation completes."
    $Script:LaunchButton.Add_Click({
        Start-VelociraptorLaunch
    })
    
    # Exit button
    $ExitButton = New-Object System.Windows.Forms.Button
    $ExitButton.Text = "Exit"
    $ExitButton.Size = New-Object System.Drawing.Size(60, 35)
    $ExitButton.Location = New-Object System.Drawing.Point(20, 15)
    $ExitButton.BackColor = $Colors.DarkBackground
    $ExitButton.ForeColor = $Colors.WhiteText
    $ExitButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ExitButton.TabIndex = 6
    $ExitButton.AccessibleName = "Exit Application"
    $ExitButton.AccessibleDescription = "Closes the Velociraptor installation wizard application."
    $ExitButton.Add_Click({ $MainForm.Close() })
    
    $ButtonPanel.Controls.AddRange(@($Script:EmergencyButton, $Script:InstallButton, $Script:LaunchButton, $ExitButton))
    $MainForm.Controls.Add($ButtonPanel)
}
catch {
    Write-Host "Failed to create buttons: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Initial log message
Write-LogToGUI "=== Velociraptor Installation GUI Ready ===" -Level 'Success'
Write-LogToGUI "Configure your installation paths and click 'Install Velociraptor' to begin."

# Show the form
Write-Host "Launching Installation GUI..." -ForegroundColor Green

try {
    if ($StartMinimized) {
        $MainForm.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
    }
    
    Write-Host "Installation GUI launched successfully!" -ForegroundColor Green
    Write-Host "Configure paths and click 'Install Velociraptor' to begin!" -ForegroundColor Cyan
    
    $result = $MainForm.ShowDialog()
    
    Write-Host "Installation GUI completed successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to show GUI: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
    exit 1
}
finally {
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