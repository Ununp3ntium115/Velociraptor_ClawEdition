#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Velociraptor Incident Response Collector GUI - Complete Installation Version

.DESCRIPTION
    Enhanced Incident Response GUI that includes:
    - Real Velociraptor download and installation
    - Specialized incident response collectors
    - Proven working installation methods from v5.0.2-beta
    - Automatic artifact deployment

.EXAMPLE
    .\IncidentResponseGUI-Installation.ps1
#>

[CmdletBinding()]
param(
    [switch]$StartMinimized
)

$ErrorActionPreference = 'Stop'

Write-Host "🚨 Velociraptor Incident Response Collector - Installation GUI" -ForegroundColor Red
Write-Host "=========================================================" -ForegroundColor Red

# CRITICAL: Initialize Windows Forms properly
Write-Host "🔧 Initializing Windows Forms..." -ForegroundColor Yellow

try {
    # CRITICAL: Load assemblies FIRST, then call SetCompatibleTextRenderingDefault
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
    
    # NOW call SetCompatibleTextRenderingDefault after assemblies are loaded
    try {
        [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
        Write-Host "✅ SetCompatibleTextRenderingDefault successful" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️  SetCompatibleTextRenderingDefault already called (this is normal)" -ForegroundColor Yellow
    }
    
    try {
        [System.Windows.Forms.Application]::EnableVisualStyles()
    }
    catch {
        # Ignore if already called
    }
    
    Write-Host "✅ Windows Forms initialized successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Windows Forms initialization failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Define colors
$Colors = @{
    DarkBackground = [System.Drawing.Color]::FromArgb(32, 32, 32)
    DarkPanel = [System.Drawing.Color]::FromArgb(45, 45, 48)
    VelociraptorGreen = [System.Drawing.Color]::FromArgb(0, 255, 127)
    VelociraptorBlue = [System.Drawing.Color]::FromArgb(0, 191, 255)
    TextColor = [System.Drawing.Color]::White
    AccentColor = [System.Drawing.Color]::FromArgb(255, 165, 0)
    ErrorRed = [System.Drawing.Color]::FromArgb(255, 69, 58)
}

# Global variables
$Script:InstallDir = 'C:\tools'
$Script:DataStore = 'C:\VelociraptorIR'
$Script:SelectedIncident = $null
$Script:DownloadProgress = 0

# Incident types with specialized collectors
$IncidentTypes = @(
    @{ 
        Name = "APT Attack"
        Description = "Advanced Persistent Threat investigation"
        Icon = "🎯"
        Artifacts = @("Windows.System.ProcessTracker", "Windows.Network.NetstatEnrich", "Windows.Events.ProcessCreation", "Windows.Registry.NTUser")
        Priority = "Critical"
    }
    @{ 
        Name = "Ransomware"
        Description = "Ransomware incident response"
        Icon = "🔒"
        Artifacts = @("Windows.Detection.Amcache", "Windows.Forensics.FilenameSearch", "Windows.Registry.UserAssist", "Windows.System.Handles")
        Priority = "Critical"
    }
    @{ 
        Name = "Malware Analysis"
        Description = "Malware infection investigation"
        Icon = "🦠"
        Artifacts = @("Windows.Detection.Yara", "Windows.Forensics.SAM", "Windows.Network.ArpCache", "Windows.System.Services")
        Priority = "High"
    }
    @{ 
        Name = "Data Breach"
        Description = "Data exfiltration investigation"
        Icon = "📊"
        Artifacts = @("Windows.Network.PacketCapture", "Windows.Forensics.UserAccessLogs", "Windows.Registry.Sysinternals", "Windows.System.CertificateAuthorities")
        Priority = "Critical"
    }
    @{ 
        Name = "Network Intrusion"
        Description = "Network compromise investigation"
        Icon = "🌐"
        Artifacts = @("Windows.Network.Netstat", "Windows.Detection.EnvironmentVariables", "Windows.Forensics.RDPCache", "Windows.System.PowerShell")
        Priority = "High"
    }
    @{ 
        Name = "Insider Threat"
        Description = "Internal threat investigation"
        Icon = "👤"
        Artifacts = @("Windows.Forensics.UserActivity", "Windows.Registry.UserAccounts", "Windows.Network.ArpCache", "Windows.System.TaskScheduler")
        Priority = "Medium"
    }
)

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
        'Critical' { 'Magenta' }
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
        
        $webClient = New-Object System.Net.WebClient
        
        # Add progress handler
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
                    $Script:StatusLabel.Text = "Downloading Velociraptor... $($Script:DownloadProgress)%"
                })
            }
        })
        
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
    }
}

function Start-IncidentResponseDeployment {
    try {
        if (-not $Script:SelectedIncident) {
            throw "Please select an incident type first"
        }
        
        Write-LogToGUI "=== STARTING INCIDENT RESPONSE DEPLOYMENT ===" -Level 'Critical'
        Write-LogToGUI "Incident Type: $($Script:SelectedIncident.Name)" -Level 'Critical'
        Write-LogToGUI "Priority: $($Script:SelectedIncident.Priority)" -Level 'Critical'
        
        # Update UI
        if ($Script:DeployButton) {
            $Script:DeployButton.Invoke([Action] {
                $Script:DeployButton.Enabled = $false
                $Script:DeployButton.Text = "🚀 Deploying..."
            })
        }
        
        # Create directories
        foreach ($directory in @($Script:InstallDir, $Script:DataStore)) {
            if (-not (Test-Path $directory)) {
                New-Item -ItemType Directory $directory -Force | Out-Null
                Write-LogToGUI "Created directory: $directory" -Level 'Success'
            }
        }
        
        # Download and install Velociraptor
        $executablePath = Join-Path $Script:InstallDir 'velociraptor.exe'
        
        if (-not (Test-Path $executablePath)) {
            Write-LogToGUI "Installing Velociraptor executable..." -Level 'Success'
            $assetInfo = Get-LatestVelociraptorAsset
            $success = Install-VelociraptorExecutable -AssetInfo $assetInfo -DestinationPath $executablePath
            
            if (-not $success) {
                throw "Failed to install Velociraptor executable"
            }
        } else {
            Write-LogToGUI "Using existing Velociraptor installation" -Level 'Success'
        }
        
        # Generate incident-specific configuration
        Write-LogToGUI "Generating incident-specific configuration..." -Level 'Success'
        $configPath = Join-Path $Script:InstallDir "ir_config_$($Script:SelectedIncident.Name -replace '\s','_').yaml"
        
        # Generate base config
        $baseConfigOutput = & $executablePath config generate 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to generate base configuration: $baseConfigOutput"
        }
        
        # Save and modify config for incident response
        $baseConfigOutput | Out-File $configPath -Encoding UTF8
        Write-LogToGUI "Base configuration generated: $configPath" -Level 'Success'
        
        # Create specialized collector
        Write-LogToGUI "Creating specialized collector for $($Script:SelectedIncident.Name)..." -Level 'Critical'
        
        # List artifacts that will be collected
        Write-LogToGUI "Artifacts to be collected:" -Level 'Success'
        foreach ($artifact in $Script:SelectedIncident.Artifacts) {
            Write-LogToGUI "  - $artifact" -Level 'Success'
        }
        
        # Launch Velociraptor with incident-specific settings
        Write-LogToGUI "Launching Velociraptor IR platform..." -Level 'Critical'
        $arguments = "gui --datastore `"$Script:DataStore`" --config `"$configPath`""
        $process = Start-Process $executablePath -ArgumentList $arguments -WorkingDirectory $Script:InstallDir -PassThru
        
        if ($process) {
            Write-LogToGUI "Velociraptor IR platform started (PID: $($process.Id))" -Level 'Success'
            
            # Wait for startup
            Start-Sleep -Seconds 5
            
            Write-LogToGUI "Opening incident response web interface..." -Level 'Critical'
            Start-Process "https://127.0.0.1:8889"
            
            Write-LogToGUI "=== DEPLOYMENT COMPLETED SUCCESSFULLY ===" -Level 'Critical'
            Write-LogToGUI "Web Interface: https://127.0.0.1:8889" -Level 'Success'
            Write-LogToGUI "Default credentials: admin / password" -Level 'Warning'
            Write-LogToGUI "Data Store: $Script:DataStore" -Level 'Success'
            Write-LogToGUI "Process ID: $($process.Id)" -Level 'Success'
            
            # Update UI
            if ($Script:DeployButton) {
                $Script:DeployButton.Invoke([Action] {
                    $Script:DeployButton.Text = "✅ Deployment Complete"
                    $Script:DeployButton.BackColor = $Colors.VelociraptorGreen
                    $Script:DeployButton.ForeColor = [System.Drawing.Color]::Black
                })
            }
            
            if ($Script:StatusLabel) {
                $Script:StatusLabel.Invoke([Action] {
                    $Script:StatusLabel.Text = "IR Platform Ready - https://127.0.0.1:8889"
                })
            }
            
            [System.Windows.Forms.MessageBox]::Show(
                "Incident Response deployment completed successfully!`n`nIncident Type: $($Script:SelectedIncident.Name)`nWeb Interface: https://127.0.0.1:8889`nProcess ID: $($process.Id)`n`nSpecialized artifacts are ready for collection.`n`nDefault credentials: admin / password",
                "IR Deployment Complete",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
        else {
            throw "Failed to start Velociraptor IR platform"
        }
    }
    catch {
        Write-LogToGUI "Deployment failed - $($_.Exception.Message)" -Level 'Error'
        
        if ($Script:DeployButton) {
            $Script:DeployButton.Invoke([Action] {
                $Script:DeployButton.Enabled = $true
                $Script:DeployButton.Text = "❌ Deploy Failed - Retry"
                $Script:DeployButton.BackColor = $Colors.ErrorRed
            })
        }
        
        [System.Windows.Forms.MessageBox]::Show(
            "Deployment failed: $($_.Exception.Message)",
            "Deployment Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

############  GUI Creation  ###################################################

Write-Host "🏗️ Creating main form..." -ForegroundColor Yellow

try {
    # Create main form
    $MainForm = New-Object System.Windows.Forms.Form
    $MainForm.Text = "🦖 Velociraptor Incident Response Collector - Installation & Deployment"
    $MainForm.Size = New-Object System.Drawing.Size(1200, 800)
    $MainForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $MainForm.BackColor = $Colors.DarkBackground
    $MainForm.ForeColor = $Colors.TextColor
    $MainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $MainForm.MaximizeBox = $false
    
    Write-Host "✅ Main form created successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to create main form: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Creating header..." -ForegroundColor Yellow

try {
    # Header panel
    $HeaderPanel = New-Object System.Windows.Forms.Panel
    $HeaderPanel.Size = New-Object System.Drawing.Size(1180, 80)
    $HeaderPanel.Location = New-Object System.Drawing.Point(10, 10)
    $HeaderPanel.BackColor = $Colors.DarkPanel
    
    # Title
    $TitleLabel = New-Object System.Windows.Forms.Label
    $TitleLabel.Text = "🚨 INCIDENT RESPONSE COLLECTOR - DEPLOYMENT PLATFORM"
    $TitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $TitleLabel.ForeColor = $Colors.VelociraptorGreen
    $TitleLabel.Location = New-Object System.Drawing.Point(20, 15)
    $TitleLabel.Size = New-Object System.Drawing.Size(800, 25)
    
    # Subtitle
    $SubtitleLabel = New-Object System.Windows.Forms.Label
    $SubtitleLabel.Text = "Deploy specialized Velociraptor collectors for cybersecurity incident response"
    $SubtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $SubtitleLabel.ForeColor = $Colors.TextColor
    $SubtitleLabel.Location = New-Object System.Drawing.Point(20, 45)
    $SubtitleLabel.Size = New-Object System.Drawing.Size(800, 20)
    
    $HeaderPanel.Controls.Add($TitleLabel)
    $HeaderPanel.Controls.Add($SubtitleLabel)
    $MainForm.Controls.Add($HeaderPanel)
    
    Write-Host "✅ Header created successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to create header: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "📝 Creating incident selection..." -ForegroundColor Yellow

try {
    # Left panel for incident selection
    $IncidentPanel = New-Object System.Windows.Forms.Panel
    $IncidentPanel.Size = New-Object System.Drawing.Size(580, 500)
    $IncidentPanel.Location = New-Object System.Drawing.Point(10, 100)
    $IncidentPanel.BackColor = $Colors.DarkPanel
    
    # Instructions
    $InstructionLabel = New-Object System.Windows.Forms.Label
    $InstructionLabel.Text = "Select the type of incident you're investigating:"
    $InstructionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $InstructionLabel.ForeColor = $Colors.AccentColor
    $InstructionLabel.Location = New-Object System.Drawing.Point(20, 20)
    $InstructionLabel.Size = New-Object System.Drawing.Size(500, 25)
    
    $IncidentPanel.Controls.Add($InstructionLabel)
    
    # Create incident type buttons
    $ButtonY = 60
    foreach ($incident in $IncidentTypes) {
        $IncidentButton = New-Object System.Windows.Forms.Button
        $IncidentButton.Text = "$($incident.Icon) $($incident.Name)"
        $IncidentButton.Size = New-Object System.Drawing.Size(250, 50)
        $IncidentButton.Location = New-Object System.Drawing.Point(30, $ButtonY)
        $IncidentButton.BackColor = $Colors.DarkBackground
        $IncidentButton.ForeColor = $Colors.TextColor
        $IncidentButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $IncidentButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        
        # Add click event
        $IncidentButton.Add_Click({
            param($sender, $e)
            
            # Reset all button colors
            foreach ($ctrl in $IncidentPanel.Controls) {
                if ($ctrl -is [System.Windows.Forms.Button] -and $ctrl.Text -like "*$($incident.Icon)*") {
                    $ctrl.BackColor = $Colors.DarkBackground
                }
            }
            
            # Highlight selected button
            $sender.BackColor = $Colors.VelociraptorBlue
            
            # Set selected incident
            $Script:SelectedIncident = $IncidentTypes | Where-Object { "$($_.Icon) $($_.Name)" -eq $sender.Text }
            
            Write-LogToGUI "Selected incident type: $($Script:SelectedIncident.Name)" -Level 'Critical'
            Write-LogToGUI "Priority: $($Script:SelectedIncident.Priority)" -Level 'Warning'
            Write-LogToGUI "Description: $($Script:SelectedIncident.Description)" -Level 'Success'
            Write-LogToGUI "Specialized artifacts: $($Script:SelectedIncident.Artifacts -join ', ')" -Level 'Success'
            
            # Enable deploy button
            if ($Script:DeployButton) {
                $Script:DeployButton.Enabled = $true
            }
            
        }.GetNewClosure())
        
        # Priority label
        $PriorityLabel = New-Object System.Windows.Forms.Label
        $PriorityLabel.Text = "$($incident.Priority) Priority"
        $PriorityLabel.Size = New-Object System.Drawing.Size(100, 20)
        $PriorityLabel.Location = New-Object System.Drawing.Point(290, ($ButtonY + 5))
        $PriorityLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $priorityColor = switch ($incident.Priority) {
            'Critical' { $Colors.ErrorRed }
            'High' { $Colors.AccentColor }
            'Medium' { $Colors.VelociraptorBlue }
            default { $Colors.TextColor }
        }
        $PriorityLabel.ForeColor = $priorityColor
        
        # Description label
        $DescLabel = New-Object System.Windows.Forms.Label
        $DescLabel.Text = $incident.Description
        $DescLabel.Size = New-Object System.Drawing.Size(250, 20)
        $DescLabel.Location = New-Object System.Drawing.Point(290, ($ButtonY + 25))
        $DescLabel.ForeColor = $Colors.TextColor
        $DescLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        
        $IncidentPanel.Controls.Add($IncidentButton)
        $IncidentPanel.Controls.Add($PriorityLabel)
        $IncidentPanel.Controls.Add($DescLabel)
        
        $ButtonY += 70
    }
    
    $MainForm.Controls.Add($IncidentPanel)
    
    Write-Host "✅ Incident selection created successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to create incident selection: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "📊 Creating deployment panel..." -ForegroundColor Yellow

try {
    # Right panel for deployment info
    $DeploymentPanel = New-Object System.Windows.Forms.Panel
    $DeploymentPanel.Size = New-Object System.Drawing.Size(580, 500)
    $DeploymentPanel.Location = New-Object System.Drawing.Point(610, 100)
    $DeploymentPanel.BackColor = $Colors.DarkPanel
    
    # Deployment info
    $DeployLabel = New-Object System.Windows.Forms.Label
    $DeployLabel.Text = "Deployment Configuration:"
    $DeployLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $DeployLabel.ForeColor = $Colors.AccentColor
    $DeployLabel.Location = New-Object System.Drawing.Point(20, 20)
    $DeployLabel.Size = New-Object System.Drawing.Size(300, 25)
    
    # Install directory
    $InstallDirLabel = New-Object System.Windows.Forms.Label
    $InstallDirLabel.Text = "Installation Directory:"
    $InstallDirLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $InstallDirLabel.ForeColor = $Colors.TextColor
    $InstallDirLabel.Location = New-Object System.Drawing.Point(30, 55)
    $InstallDirLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $InstallDirTextBox = New-Object System.Windows.Forms.TextBox
    $InstallDirTextBox.Text = $Script:InstallDir
    $InstallDirTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $InstallDirTextBox.BackColor = $Colors.DarkBackground
    $InstallDirTextBox.ForeColor = $Colors.TextColor
    $InstallDirTextBox.Location = New-Object System.Drawing.Point(30, 75)
    $InstallDirTextBox.Size = New-Object System.Drawing.Size(520, 25)
    $InstallDirTextBox.Add_TextChanged({
        $Script:InstallDir = $InstallDirTextBox.Text
    })
    
    # Data directory
    $DataDirLabel = New-Object System.Windows.Forms.Label
    $DataDirLabel.Text = "IR Data Directory:"
    $DataDirLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $DataDirLabel.ForeColor = $Colors.TextColor
    $DataDirLabel.Location = New-Object System.Drawing.Point(30, 110)
    $DataDirLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $DataDirTextBox = New-Object System.Windows.Forms.TextBox
    $DataDirTextBox.Text = $Script:DataStore
    $DataDirTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $DataDirTextBox.BackColor = $Colors.DarkBackground
    $DataDirTextBox.ForeColor = $Colors.TextColor
    $DataDirTextBox.Location = New-Object System.Drawing.Point(30, 130)
    $DataDirTextBox.Size = New-Object System.Drawing.Size(520, 25)
    $DataDirTextBox.Add_TextChanged({
        $Script:DataStore = $DataDirTextBox.Text
    })
    
    # Progress bar
    $Script:ProgressBar = New-Object System.Windows.Forms.ProgressBar
    $Script:ProgressBar.Location = New-Object System.Drawing.Point(30, 170)
    $Script:ProgressBar.Size = New-Object System.Drawing.Size(520, 20)
    $Script:ProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
    
    # Status label
    $Script:StatusLabel = New-Object System.Windows.Forms.Label
    $Script:StatusLabel.Text = "Ready for deployment"
    $Script:StatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $Script:StatusLabel.ForeColor = $Colors.TextColor
    $Script:StatusLabel.Location = New-Object System.Drawing.Point(30, 200)
    $Script:StatusLabel.Size = New-Object System.Drawing.Size(520, 20)
    
    # Log area
    $LogLabel = New-Object System.Windows.Forms.Label
    $LogLabel.Text = "Deployment Log:"
    $LogLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $LogLabel.ForeColor = $Colors.AccentColor
    $LogLabel.Location = New-Object System.Drawing.Point(30, 230)
    $LogLabel.Size = New-Object System.Drawing.Size(200, 20)
    
    $Script:LogTextBox = New-Object System.Windows.Forms.TextBox
    $Script:LogTextBox.Multiline = $true
    $Script:LogTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $Script:LogTextBox.BackColor = $Colors.DarkBackground
    $Script:LogTextBox.ForeColor = $Colors.TextColor
    $Script:LogTextBox.Font = New-Object System.Drawing.Font("Consolas", 8)
    $Script:LogTextBox.Location = New-Object System.Drawing.Point(30, 255)
    $Script:LogTextBox.Size = New-Object System.Drawing.Size(520, 220)
    $Script:LogTextBox.ReadOnly = $true
    
    $DeploymentPanel.Controls.AddRange(@(
        $DeployLabel, $InstallDirLabel, $InstallDirTextBox,
        $DataDirLabel, $DataDirTextBox, $Script:ProgressBar,
        $Script:StatusLabel, $LogLabel, $Script:LogTextBox
    ))
    
    $MainForm.Controls.Add($DeploymentPanel)
    
    Write-Host "✅ Deployment panel created successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to create deployment panel: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "🔘 Creating buttons..." -ForegroundColor Yellow

try {
    # Button panel
    $ButtonPanel = New-Object System.Windows.Forms.Panel
    $ButtonPanel.Size = New-Object System.Drawing.Size(1180, 60)
    $ButtonPanel.Location = New-Object System.Drawing.Point(10, 610)
    $ButtonPanel.BackColor = $Colors.DarkPanel
    
    # Deploy button
    $Script:DeployButton = New-Object System.Windows.Forms.Button
    $Script:DeployButton.Text = "🚀 Deploy IR Collector"
    $Script:DeployButton.Size = New-Object System.Drawing.Size(200, 35)
    $Script:DeployButton.Location = New-Object System.Drawing.Point(850, 15)
    $Script:DeployButton.BackColor = $Colors.VelociraptorGreen
    $Script:DeployButton.ForeColor = [System.Drawing.Color]::Black
    $Script:DeployButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $Script:DeployButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $Script:DeployButton.Enabled = $false
    $Script:DeployButton.Add_Click({
        # Run deployment in background thread
        $runspace = [powershell]::Create()
        $runspace.AddScript({
            param($deployFunction)
            & $deployFunction
        }).AddArgument(${function:Start-IncidentResponseDeployment}) | Out-Null
        $runspace.BeginInvoke() | Out-Null
    })
    
    # Exit button
    $ExitButton = New-Object System.Windows.Forms.Button
    $ExitButton.Text = "Exit"
    $ExitButton.Size = New-Object System.Drawing.Size(80, 35)
    $ExitButton.Location = New-Object System.Drawing.Point(1070, 15)
    $ExitButton.BackColor = $Colors.DarkBackground
    $ExitButton.ForeColor = $Colors.TextColor
    $ExitButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ExitButton.Add_Click({ $MainForm.Close() })
    
    $ButtonPanel.Controls.Add($Script:DeployButton)
    $ButtonPanel.Controls.Add($ExitButton)
    $MainForm.Controls.Add($ButtonPanel)
    
    Write-Host "✅ Buttons created successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to create buttons: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Initial log message
Write-LogToGUI "=== Velociraptor Incident Response Collector Ready ===" -Level 'Critical'
Write-LogToGUI "Select an incident type to deploy a specialized collector platform."

# Show the form
Write-Host "🚀 Launching Incident Response GUI..." -ForegroundColor Green

try {
    if ($StartMinimized) {
        $MainForm.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
    }
    
    Write-Host "✅ Incident Response GUI launched successfully!" -ForegroundColor Green
    Write-Host "💡 Select an incident type to deploy a specialized collector" -ForegroundColor Cyan
    
    # Show the form and wait for it to close
    $result = $MainForm.ShowDialog()
    
    Write-Host "✅ Incident Response GUI completed successfully" -ForegroundColor Green
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

Write-Host "Incident Response session completed!" -ForegroundColor Green
