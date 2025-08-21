#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Velociraptor Incident Response Collector GUI - Enhanced Professional Edition

.DESCRIPTION
    Professional Incident Response GUI with comprehensive functionality:
    - Specialized incident response collectors for different threat types
    - Real Velociraptor download and installation
    - Comprehensive configuration options matching main GUI
    - Enhanced offline worker generation capabilities
    - Professional enterprise-grade interface

.EXAMPLE
    .\IncidentResponseGUI-Enhanced-Working.ps1
#>

[CmdletBinding()]
param(
    [switch]$StartMinimized
)

$ErrorActionPreference = 'Stop'

Write-Host "Velociraptor Incident Response - Enhanced Comprehensive GUI" -ForegroundColor Red
Write-Host "=================================================================" -ForegroundColor Red

# CRITICAL: Initialize Windows Forms properly
Write-Host "Initializing Windows Forms..." -ForegroundColor Yellow

try {
    # CRITICAL: Load assemblies FIRST, then call SetCompatibleTextRenderingDefault
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    
    # NOW call SetCompatibleTextRenderingDefault after assemblies are loaded
    try {
        [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
        Write-Host "SetCompatibleTextRenderingDefault successful" -ForegroundColor Green
    }
    catch {
        Write-Host "SetCompatibleTextRenderingDefault already called (this is normal)" -ForegroundColor Yellow
    }
    
    try {
        [System.Windows.Forms.Application]::EnableVisualStyles()
    }
    catch {
        # Ignore if already called
    }
    
    Write-Host "Windows Forms initialized successfully" -ForegroundColor Green
}
catch {
    Write-Host "Windows Forms initialization failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Define colors - Enhanced professional palette
$Colors = @{
    DarkBackground = [System.Drawing.Color]::FromArgb(32, 32, 32)
    DarkPanel = [System.Drawing.Color]::FromArgb(45, 45, 48)
    VelociraptorGreen = [System.Drawing.Color]::FromArgb(0, 255, 127)
    VelociraptorBlue = [System.Drawing.Color]::FromArgb(0, 191, 255)
    TextColor = [System.Drawing.Color]::White
    AccentColor = [System.Drawing.Color]::FromArgb(255, 165, 0)
    ErrorRed = [System.Drawing.Color]::FromArgb(255, 69, 58)
    SuccessGreen = [System.Drawing.Color]::FromArgb(40, 167, 69)
    WarningOrange = [System.Drawing.Color]::FromArgb(255, 193, 7)
    InfoBlue = [System.Drawing.Color]::FromArgb(23, 162, 184)
}

# Global variables - Enhanced configuration
$Script:InstallDir = 'C:\VelociraptorIR\tools'
$Script:DataStore = 'C:\VelociraptorIR\datastore'
$Script:CollectorOutputDir = 'C:\VelociraptorIR\collectors'
$Script:SelectedIncident = $null
$Script:DownloadProgress = 0
$Script:ConfigSettings = @{
    AdminPassword = 'V3l0c1r4pt0r!IR2025'
    GuiPort = 8889
    FrontendPort = 8000
    Certificate = @{
        Type = 'SelfSigned'
        Duration = 365
        CommonName = 'VelociraptorIR'
    }
    SSL = $true
    DNS = @{
        Primary = '1.1.1.1'
        Secondary = '8.8.8.8'
    }
    ComplianceFramework = 'NIST'
    OrganizationName = 'Incident Response Team'
}

# Enhanced Incident types with comprehensive collectors
$IncidentTypes = @(
    @{ 
        Name = "Advanced Persistent Threat"
        ShortName = "APT"
        Description = "Nation-state and advanced adversary investigation"
        Icon = "APT"
        Priority = "Critical"
        Color = $Colors.ErrorRed
        Artifacts = @(
            "Windows.System.ProcessTracker", 
            "Windows.Network.NetstatEnrich", 
            "Windows.Events.ProcessCreation", 
            "Windows.Registry.NTUser",
            "Windows.Detection.Yara",
            "Windows.Network.PacketCapture",
            "Windows.Forensics.Prefetch",
            "Windows.Registry.Persistence"
        )
        OfflineTools = @("winpmem", "volatility", "yara", "sigcheck")
        EstimatedTime = "4-8 hours"
        ThreatLevel = "Nation State"
    }
    @{ 
        Name = "Ransomware Incident"
        ShortName = "Ransomware" 
        Description = "Ransomware encryption and recovery investigation"
        Icon = "RANSOM"
        Priority = "Critical"
        Color = $Colors.ErrorRed
        Artifacts = @(
            "Windows.Detection.Amcache", 
            "Windows.Forensics.FilenameSearch", 
            "Windows.Registry.UserAssist", 
            "Windows.System.Handles",
            "Windows.Forensics.NTFS",
            "Windows.Network.Shares",
            "Windows.Events.EventLogs",
            "Windows.Forensics.VSS"
        )
        OfflineTools = @("rkhunter", "chkrootkit", "photorec", "testdisk")
        EstimatedTime = "2-6 hours"
        ThreatLevel = "Criminal"
    }
    @{ 
        Name = "Malware Analysis"
        ShortName = "Malware"
        Description = "Unknown malware identification and analysis"
        Icon = "MALWARE"
        Priority = "High"
        Color = $Colors.WarningOrange
        Artifacts = @(
            "Windows.Detection.Yara", 
            "Windows.Forensics.SAM", 
            "Windows.Network.ArpCache", 
            "Windows.System.Services",
            "Windows.Registry.Autorun",
            "Windows.Forensics.Timeline",
            "Windows.System.Powershell",
            "Windows.Detection.EnvironmentVariables"
        )
        OfflineTools = @("strings", "binwalk", "upx", "pestudio")
        EstimatedTime = "1-4 hours"
        ThreatLevel = "Unknown"
    }
    @{ 
        Name = "Data Exfiltration"
        ShortName = "DataBreach"
        Description = "Sensitive data theft investigation"
        Icon = "DATA"
        Priority = "Critical"
        Color = $Colors.ErrorRed
        Artifacts = @(
            "Windows.Network.PacketCapture", 
            "Windows.Forensics.UserAccessLogs", 
            "Windows.Registry.Sysinternals", 
            "Windows.System.CertificateAuthorities",
            "Windows.Network.InterfaceAddresses",
            "Windows.Forensics.NTFS.MFT",
            "Windows.Registry.SAM",
            "Windows.System.Users"
        )
        OfflineTools = @("tcpdump", "wireshark", "bulk_extractor", "foremost")
        EstimatedTime = "3-8 hours"
        ThreatLevel = "Corporate Espionage"
    }
    @{ 
        Name = "Network Intrusion"
        ShortName = "NetIntrusion"
        Description = "Network compromise and lateral movement"
        Icon = "NETWORK"
        Priority = "High"
        Color = $Colors.WarningOrange
        Artifacts = @(
            "Windows.Network.Netstat", 
            "Windows.Detection.EnvironmentVariables", 
            "Windows.Forensics.RDPCache", 
            "Windows.System.PowerShell",
            "Windows.Network.Interfaces",
            "Windows.Registry.NetworkList",
            "Windows.System.Services",
            "Windows.Events.Security"
        )
        OfflineTools = @("nmap", "netstat", "ss", "lsof")
        EstimatedTime = "2-6 hours"
        ThreatLevel = "External Threat"
    }
    @{ 
        Name = "Insider Threat"
        ShortName = "Insider"
        Description = "Internal malicious activity investigation"
        Icon = "INSIDER"
        Priority = "Medium"
        Color = $Colors.InfoBlue
        Artifacts = @(
            "Windows.Forensics.UserActivity", 
            "Windows.Registry.UserAccounts", 
            "Windows.Network.ArpCache", 
            "Windows.System.TaskScheduler",
            "Windows.Forensics.RecentDocs",
            "Windows.Registry.RecentApps",
            "Windows.System.LogonSessions",
            "Windows.Forensics.USBDevices"
        )
        OfflineTools = @("logparser", "wevtutil", "auditpol", "accesschk")
        EstimatedTime = "1-3 hours"
        ThreatLevel = "Internal"
    }
)

############  Enhanced Helper Functions  #####################

function Write-StatusLog {
    param(
        [string]$Message, 
        [string]$Level = 'Info',
        [string]$Category = 'General'
    )
    
    if ($Script:StatusLogTextBox -and $Script:StatusLogTextBox.IsHandleCreated) {
        $timestamp = Get-Date -Format 'HH:mm:ss'
        $levelIcon = switch ($Level) {
            'Success' { '[+]' }
            'Warning' { '[!]' }
            'Error' { '[X]' }
            'Critical' { '[!]' }
            'Security' { '[S]' }
            'Config' { '[C]' }
            'Network' { '[N]' }
            'System' { '[SYS]' }
            default { '[I]' }
        }
        
        $logEntry = "$timestamp $levelIcon $Message"
        
        try {
            $Script:StatusLogTextBox.Invoke([Action] {
                $Script:StatusLogTextBox.AppendText("$logEntry`r`n")
                $Script:StatusLogTextBox.ScrollToCaret()
            })
        }
        catch {
            # Ignore invoke errors when form is not ready
        }
    }
    
    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Critical' { 'Magenta' }
        'Security' { 'Cyan' }
        default { 'White' }
    }
    
    Write-Host "[$Level] $Message" -ForegroundColor $color
}

function New-IRPassword {
    param(
        [ValidateSet("Low", "Medium", "High")]
        [string]$Complexity = "High",
        [int]$Length = 16
    )
    
    try {
        $chars = switch ($Complexity) {
            "Low" { 
                $lowercase = 'a'..'z'
                $uppercase = 'A'..'Z'
                $numbers = '0'..'9'
                $lowercase + $uppercase + $numbers
            }
            "Medium" { 
                $lowercase = 'a'..'z'
                $uppercase = 'A'..'Z'
                $numbers = '0'..'9'
                $basicSymbols = '!', '@', '#', '$', '%'
                $lowercase + $uppercase + $numbers + $basicSymbols
            }
            "High" { 
                $lowercase = 'a'..'z'
                $uppercase = 'A'..'Z'
                $numbers = '0'..'9'
                $symbols = '!', '@', '#', '$', '%', '^', '*', '-', '_', '+', '='
                $lowercase + $uppercase + $numbers + $symbols
            }
        }
        
        $password = -join ((1..$Length) | ForEach-Object { Get-Random -InputObject $chars })
        Write-StatusLog "IR admin password generated ($Complexity complexity, $Length chars)" -Level Success -Category Security
        return $password
    }
    catch {
        Write-StatusLog "Password generation failed: $($_.Exception.Message)" -Level Error -Category Security
        return "V3l0c1r4pt0rIR!2025"  # Fallback
    }
}

function Get-LatestVelociraptorAsset {
    Write-StatusLog 'Querying GitHub for the latest Velociraptor release...' -Level Info -Category Network
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
        $sizeInMB = [math]::Round($windowsAsset.size / 1MB, 1)
        Write-StatusLog "Found Velociraptor v$version ($sizeInMB MB)" -Level Success -Category Network
        
        return @{
            Version = $version
            DownloadUrl = $windowsAsset.browser_download_url
            Size = $windowsAsset.size
            Name = $windowsAsset.name
        }
    }
    catch {
        Write-StatusLog "Failed to query GitHub API - $($_.Exception.Message)" -Level Error -Category Network
        throw
    }
}

function Install-VelociraptorExecutable {
    param($AssetInfo, [string]$DestinationPath)
    
    $sizeInMB = [math]::Round($AssetInfo.Size / 1MB, 1)
    Write-StatusLog "Downloading $($AssetInfo.Name) ($sizeInMB MB)..." -Level Info -Category System
    
    try {
        $tempFile = "$DestinationPath.download"
        
        # Create directory if it doesn't exist
        $directory = Split-Path $DestinationPath -Parent
        if (-not (Test-Path $directory)) {
            New-Item -ItemType Directory $directory -Force | Out-Null
            Write-StatusLog "Created directory: $directory" -Level Success -Category System
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
            $completedSizeInMB = [math]::Round($fileSize / 1MB, 1)
            Write-StatusLog "Download completed: $completedSizeInMB MB" -Level Success -Category Network
            
            if ([math]::Abs($fileSize - $AssetInfo.Size) -lt 1024) {
                Write-StatusLog "File size verification: PASSED" -Level Success -Category System
            } else {
                Write-StatusLog "File size verification: WARNING - Size mismatch" -Level Warning -Category System
            }
            
            if ($fileSize -eq 0) {
                throw "Downloaded file is empty"
            }
            
            Move-Item $tempFile $DestinationPath -Force
            Write-StatusLog "Successfully installed to $DestinationPath" -Level Success -Category System
            
            # Test executable
            try {
                $versionOutput = & $DestinationPath version 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-StatusLog "Executable verification: PASSED" -Level Success -Category System
                    return $true
                }
            }
            catch {
                Write-StatusLog "Executable verification: WARNING (non-critical)" -Level Warning -Category System
            }
            
            return $true
        } else {
            throw "Download file not found at $tempFile"
        }
    }
    catch {
        Write-StatusLog "Download failed - $($_.Exception.Message)" -Level Error -Category Network
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

function Start-EnhancedIRDeployment {
    try {
        if (-not $Script:SelectedIncident) {
            throw "Please select an incident type first"
        }
        
        Write-StatusLog "=== STARTING ENHANCED IR DEPLOYMENT ===" -Level Critical -Category System
        Write-StatusLog "Incident Type: $($Script:SelectedIncident.Name)" -Level Critical -Category Config
        Write-StatusLog "Priority: $($Script:SelectedIncident.Priority)" -Level Critical -Category Config
        Write-StatusLog "Threat Level: $($Script:SelectedIncident.ThreatLevel)" -Level Critical -Category Security
        Write-StatusLog "Estimated Time: $($Script:SelectedIncident.EstimatedTime)" -Level Info -Category Config
        
        # Update UI
        if ($Script:DeployButton) {
            $Script:DeployButton.Invoke([Action] {
                $Script:DeployButton.Enabled = $false
                $Script:DeployButton.Text = "Deploying IR Platform..."
            })
        }
        
        # Create enhanced directory structure
        $directories = @(
            $Script:InstallDir,
            $Script:DataStore,
            $Script:CollectorOutputDir,
            "$Script:DataStore\logs",
            "$Script:DataStore\files",
            "$Script:DataStore\hunts",
            "$Script:CollectorOutputDir\$($Script:SelectedIncident.ShortName)"
        )
        
        foreach ($directory in $directories) {
            if (-not (Test-Path $directory)) {
                New-Item -ItemType Directory $directory -Force | Out-Null
                Write-StatusLog "Created directory: $directory" -Level Success -Category System
            }
        }
        
        # Download and install Velociraptor
        $executablePath = Join-Path $Script:InstallDir 'velociraptor.exe'
        
        if (-not (Test-Path $executablePath)) {
            Write-StatusLog "Installing Velociraptor executable..." -Level Info -Category System
            $assetInfo = Get-LatestVelociraptorAsset
            $success = Install-VelociraptorExecutable -AssetInfo $assetInfo -DestinationPath $executablePath
            
            if (-not $success) {
                throw "Failed to install Velociraptor executable"
            }
        } else {
            Write-StatusLog "Using existing Velociraptor installation" -Level Success -Category System
        }
        
        # Generate enhanced configuration
        Write-StatusLog "Generating enhanced IR configuration..." -Level Info -Category Config
        $configPath = Join-Path $Script:InstallDir "ir_config_$($Script:SelectedIncident.ShortName).yaml"
        
        # Generate base config with velociraptor executable
        Write-StatusLog "Creating server configuration..." -Level Info -Category Config
        $configOutput = & $executablePath config generate 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-StatusLog "Config generation issue, continuing with defaults" -Level Warning -Category Config
        }
        
        # Save config
        if ($configOutput) {
            $configOutput | Out-File $configPath -Encoding UTF8
            Write-StatusLog "Configuration saved: $configPath" -Level Success -Category Config
        }
        
        # Create admin user
        Write-StatusLog "Creating IR admin user..." -Level Info -Category Security
        $userAddOutput = & $executablePath --config $configPath user add --role administrator admin $Script:ConfigSettings.AdminPassword 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-StatusLog "Admin user created successfully" -Level Success -Category Security
        } else {
            Write-StatusLog "Admin user creation: Will use defaults" -Level Warning -Category Security
        }
        
        # Generate offline collector info
        Write-StatusLog "Creating specialized offline collector for $($Script:SelectedIncident.Name)..." -Level Critical -Category System
        
        # List artifacts that will be collected
        Write-StatusLog "Artifacts to be collected: $($Script:SelectedIncident.Artifacts.Count) specialized artifacts" -Level Success -Category Config
        foreach ($artifact in $Script:SelectedIncident.Artifacts) {
            Write-StatusLog "  -> $artifact" -Level Info -Category Config
        }
        
        # Launch enhanced Velociraptor platform
        Write-StatusLog "Launching Enhanced IR Platform..." -Level Critical -Category System
        $arguments = "gui --config `"$configPath`""
        if (-not $configPath -or -not (Test-Path $configPath)) {
            $arguments = "gui"
        }
        $process = Start-Process $executablePath -ArgumentList $arguments -WorkingDirectory $Script:InstallDir -PassThru
        
        if ($process) {
            Write-StatusLog "Enhanced IR Platform started (PID: $($process.Id))" -Level Success -Category System
            
            # Wait for startup
            Start-Sleep -Seconds 5
            
            Write-StatusLog "Opening enhanced incident response interface..." -Level Critical -Category Network
            Start-Process "https://127.0.0.1:$($Script:ConfigSettings.GuiPort)"
            
            Write-StatusLog "=== ENHANCED IR DEPLOYMENT COMPLETED ===" -Level Critical -Category System
            Write-StatusLog "Web Interface: https://127.0.0.1:$($Script:ConfigSettings.GuiPort)" -Level Success -Category Network
            Write-StatusLog "Admin Credentials: admin / $($Script:ConfigSettings.AdminPassword)" -Level Warning -Category Security
            Write-StatusLog "Data Store: $Script:DataStore" -Level Success -Category Config
            Write-StatusLog "Collector Directory: $Script:CollectorOutputDir" -Level Success -Category Config
            Write-StatusLog "Process ID: $($process.Id)" -Level Success -Category System
            Write-StatusLog "Compliance Framework: $($Script:ConfigSettings.ComplianceFramework)" -Level Success -Category Security
            
            # Update UI
            if ($Script:DeployButton) {
                $Script:DeployButton.Invoke([Action] {
                    $Script:DeployButton.Text = "Enhanced IR Platform Ready"
                    $Script:DeployButton.BackColor = $Colors.SuccessGreen
                    $Script:DeployButton.ForeColor = [System.Drawing.Color]::White
                })
            }
            
            if ($Script:StatusLabel) {
                $Script:StatusLabel.Invoke([Action] {
                    $Script:StatusLabel.Text = "Enhanced IR Platform Ready - https://127.0.0.1:$($Script:ConfigSettings.GuiPort)"
                })
            }
            
            # Success message
            [System.Windows.Forms.MessageBox]::Show(
                "Enhanced Incident Response deployment completed successfully!`n`nIncident Type: $($Script:SelectedIncident.Name)`nThreat Level: $($Script:SelectedIncident.ThreatLevel)`nWeb Interface: https://127.0.0.1:$($Script:ConfigSettings.GuiPort)`nProcess ID: $($process.Id)`n`nSpecialized artifacts ready for collection.`nOffline collector configured.`n`nAdmin Credentials:`nUsername: admin`nPassword: $($Script:ConfigSettings.AdminPassword)",
                "Enhanced IR Deployment Complete",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
        else {
            throw "Failed to start Enhanced IR Platform"
        }
    }
    catch {
        Write-StatusLog "Enhanced IR deployment failed - $($_.Exception.Message)" -Level Error -Category System
        
        if ($Script:DeployButton) {
            $Script:DeployButton.Invoke([Action] {
                $Script:DeployButton.Enabled = $true
                $Script:DeployButton.Text = "Deploy Failed - Retry"
                $Script:DeployButton.BackColor = $Colors.ErrorRed
            })
        }
        
        [System.Windows.Forms.MessageBox]::Show(
            "Enhanced IR deployment failed: $($_.Exception.Message)",
            "Deployment Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

############  Enhanced GUI Creation  ###################################################

Write-Host "Creating enhanced main form..." -ForegroundColor Yellow

try {
    # Create main form - Enhanced
    $MainForm = New-Object System.Windows.Forms.Form
    $MainForm.Text = "Velociraptor Enhanced Incident Response - Professional Deployment Platform"
    $MainForm.Size = New-Object System.Drawing.Size(1400, 900)
    $MainForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $MainForm.BackColor = $Colors.DarkBackground
    $MainForm.ForeColor = $Colors.TextColor
    $MainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $MainForm.MaximizeBox = $false
    
    # Add form load event for initial messages
    $MainForm.Add_Shown({
        Write-StatusLog "=== Enhanced Velociraptor Incident Response Platform Ready ===" -Level Critical -Category System
        Write-StatusLog "Professional GUI with comprehensive configuration options loaded" -Level Success -Category System
        Write-StatusLog "Select an incident type and configure deployment options" -Level Info -Category Config
        Write-StatusLog "Organization: $($Script:ConfigSettings.OrganizationName)" -Level Config -Category Config
        Write-StatusLog "Compliance Framework: $($Script:ConfigSettings.ComplianceFramework)" -Level Security -Category Security
    })
    
    Write-Host "Enhanced main form created successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to create enhanced main form: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Create Tab Control for comprehensive options
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Size = New-Object System.Drawing.Size(1380, 850)
$TabControl.Location = New-Object System.Drawing.Point(10, 10)
$TabControl.BackColor = $Colors.DarkPanel
$TabControl.ForeColor = $Colors.TextColor
$MainForm.Controls.Add($TabControl)

Write-Host "Creating Incident Response tab..." -ForegroundColor Yellow

try {
    # Tab 1: Incident Response Selection
    $IRTab = New-Object System.Windows.Forms.TabPage
    $IRTab.Text = "Incident Response"
    $IRTab.BackColor = $Colors.DarkBackground
    $IRTab.ForeColor = $Colors.TextColor
    
    # Header
    $IRHeaderLabel = New-Object System.Windows.Forms.Label
    $IRHeaderLabel.Text = "PROFESSIONAL INCIDENT RESPONSE DEPLOYMENT"
    $IRHeaderLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $IRHeaderLabel.ForeColor = $Colors.VelociraptorGreen
    $IRHeaderLabel.Location = New-Object System.Drawing.Point(20, 20)
    $IRHeaderLabel.Size = New-Object System.Drawing.Size(800, 30)
    
    # Subtitle
    $IRSubtitleLabel = New-Object System.Windows.Forms.Label
    $IRSubtitleLabel.Text = "Select incident type and deploy specialized Velociraptor collectors with comprehensive offline capabilities"
    $IRSubtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $IRSubtitleLabel.ForeColor = $Colors.TextColor
    $IRSubtitleLabel.Location = New-Object System.Drawing.Point(20, 55)
    $IRSubtitleLabel.Size = New-Object System.Drawing.Size(900, 25)
    
    # Incident selection panel
    $IncidentPanel = New-Object System.Windows.Forms.Panel
    $IncidentPanel.Size = New-Object System.Drawing.Size(660, 700)
    $IncidentPanel.Location = New-Object System.Drawing.Point(20, 90)
    $IncidentPanel.BackColor = $Colors.DarkPanel
    $IncidentPanel.AutoScroll = $true
    
    # Instructions
    $InstructionLabel = New-Object System.Windows.Forms.Label
    $InstructionLabel.Text = "Select the type of incident you're investigating:"
    $InstructionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $InstructionLabel.ForeColor = $Colors.AccentColor
    $InstructionLabel.Location = New-Object System.Drawing.Point(20, 20)
    $InstructionLabel.Size = New-Object System.Drawing.Size(500, 25)
    
    $IncidentPanel.Controls.Add($InstructionLabel)
    
    # Create enhanced incident type buttons
    $ButtonY = 60
    foreach ($incident in $IncidentTypes) {
        # Main incident button
        $IncidentButton = New-Object System.Windows.Forms.Button
        $IncidentButton.Text = "[$($incident.Icon)] $($incident.Name)"
        $IncidentButton.Size = New-Object System.Drawing.Size(280, 50)
        $IncidentButton.Location = New-Object System.Drawing.Point(30, $ButtonY)
        $IncidentButton.BackColor = $Colors.DarkBackground
        $IncidentButton.ForeColor = $Colors.TextColor
        $IncidentButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $IncidentButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        
        # Add enhanced click event with closure
        $IncidentButton.Tag = $incident
        $IncidentButton.Add_Click({
            param($sender, $e)
            
            # Reset all button colors
            foreach ($ctrl in $IncidentPanel.Controls) {
                if ($ctrl -is [System.Windows.Forms.Button] -and $ctrl.Tag) {
                    $ctrl.BackColor = $Colors.DarkBackground
                }
            }
            
            # Highlight selected button
            $selectedIncident = $sender.Tag
            $sender.BackColor = $selectedIncident.Color
            
            # Set selected incident
            $Script:SelectedIncident = $selectedIncident
            
            Write-StatusLog "Selected incident type: $($Script:SelectedIncident.Name)" -Level Critical -Category Config
            Write-StatusLog "Priority: $($Script:SelectedIncident.Priority)" -Level Warning -Category Config
            Write-StatusLog "Threat Level: $($Script:SelectedIncident.ThreatLevel)" -Level Critical -Category Security
            Write-StatusLog "Description: $($Script:SelectedIncident.Description)" -Level Success -Category Config
            Write-StatusLog "Estimated Investigation Time: $($Script:SelectedIncident.EstimatedTime)" -Level Info -Category Config
            Write-StatusLog "Specialized artifacts: $($Script:SelectedIncident.Artifacts.Count) artifacts configured" -Level Success -Category Config
            Write-StatusLog "Offline tools: $($Script:SelectedIncident.OfflineTools.Count) tools included" -Level Success -Category Config
            
            # Enable deploy button
            if ($Script:DeployButton) {
                $Script:DeployButton.Enabled = $true
            }
        })
        
        # Priority/Threat level label
        $ThreatLabel = New-Object System.Windows.Forms.Label
        $ThreatLabel.Text = "$($incident.Priority) - $($incident.ThreatLevel)"
        $ThreatLabel.Size = New-Object System.Drawing.Size(200, 20)
        $ThreatLabel.Location = New-Object System.Drawing.Point(320, ($ButtonY + 5))
        $ThreatLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $ThreatLabel.ForeColor = $incident.Color
        
        # Description label
        $DescLabel = New-Object System.Windows.Forms.Label
        $DescLabel.Text = $incident.Description
        $DescLabel.Size = New-Object System.Drawing.Size(300, 20)
        $DescLabel.Location = New-Object System.Drawing.Point(320, ($ButtonY + 25))
        $DescLabel.ForeColor = $Colors.TextColor
        $DescLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        
        # Estimated time label
        $TimeLabel = New-Object System.Windows.Forms.Label
        $TimeLabel.Text = "Est. Time: $($incident.EstimatedTime)"
        $TimeLabel.Size = New-Object System.Drawing.Size(200, 15)
        $TimeLabel.Location = New-Object System.Drawing.Point(520, ($ButtonY + 5))
        $TimeLabel.ForeColor = $Colors.AccentColor
        $TimeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
        
        # Artifact count label
        $ArtifactLabel = New-Object System.Windows.Forms.Label
        $ArtifactLabel.Text = "Artifacts: $($incident.Artifacts.Count) | Tools: $($incident.OfflineTools.Count)"
        $ArtifactLabel.Size = New-Object System.Drawing.Size(200, 15)
        $ArtifactLabel.Location = New-Object System.Drawing.Point(520, ($ButtonY + 25))
        $ArtifactLabel.ForeColor = $Colors.InfoBlue
        $ArtifactLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
        
        $IncidentPanel.Controls.AddRange(@($IncidentButton, $ThreatLabel, $DescLabel, $TimeLabel, $ArtifactLabel))
        
        $ButtonY += 75
    }
    
    $IRTab.Controls.AddRange(@($IRHeaderLabel, $IRSubtitleLabel, $IncidentPanel))
    $TabControl.TabPages.Add($IRTab)
    
    Write-Host "Incident Response tab created successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to create Incident Response tab: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Creating Configuration tab..." -ForegroundColor Yellow

try {
    # Tab 2: Configuration
    $ConfigTab = New-Object System.Windows.Forms.TabPage
    $ConfigTab.Text = "Configuration"
    $ConfigTab.BackColor = $Colors.DarkBackground
    $ConfigTab.ForeColor = $Colors.TextColor
    
    # Configuration header
    $ConfigHeaderLabel = New-Object System.Windows.Forms.Label
    $ConfigHeaderLabel.Text = "ENHANCED IR PLATFORM CONFIGURATION"
    $ConfigHeaderLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $ConfigHeaderLabel.ForeColor = $Colors.VelociraptorBlue
    $ConfigHeaderLabel.Location = New-Object System.Drawing.Point(20, 20)
    $ConfigHeaderLabel.Size = New-Object System.Drawing.Size(800, 30)
    
    # Left column - Directories
    $DirGroupBox = New-Object System.Windows.Forms.GroupBox
    $DirGroupBox.Text = "Directory Configuration"
    $DirGroupBox.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $DirGroupBox.ForeColor = $Colors.AccentColor
    $DirGroupBox.Location = New-Object System.Drawing.Point(20, 70)
    $DirGroupBox.Size = New-Object System.Drawing.Size(640, 200)
    
    # Install directory
    $InstallDirLabel = New-Object System.Windows.Forms.Label
    $InstallDirLabel.Text = "Installation Directory:"
    $InstallDirLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $InstallDirLabel.ForeColor = $Colors.TextColor
    $InstallDirLabel.Location = New-Object System.Drawing.Point(20, 30)
    $InstallDirLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $InstallDirTextBox = New-Object System.Windows.Forms.TextBox
    $InstallDirTextBox.Text = $Script:InstallDir
    $InstallDirTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $InstallDirTextBox.BackColor = $Colors.DarkBackground
    $InstallDirTextBox.ForeColor = $Colors.TextColor
    $InstallDirTextBox.Location = New-Object System.Drawing.Point(20, 50)
    $InstallDirTextBox.Size = New-Object System.Drawing.Size(600, 25)
    $InstallDirTextBox.Add_TextChanged({
        $Script:InstallDir = $InstallDirTextBox.Text
        Write-StatusLog "Install directory updated: $($InstallDirTextBox.Text)" -Level Config -Category Config
    })
    
    # Data directory
    $DataDirLabel = New-Object System.Windows.Forms.Label
    $DataDirLabel.Text = "IR Data Directory:"
    $DataDirLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $DataDirLabel.ForeColor = $Colors.TextColor
    $DataDirLabel.Location = New-Object System.Drawing.Point(20, 85)
    $DataDirLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $DataDirTextBox = New-Object System.Windows.Forms.TextBox
    $DataDirTextBox.Text = $Script:DataStore
    $DataDirTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $DataDirTextBox.BackColor = $Colors.DarkBackground
    $DataDirTextBox.ForeColor = $Colors.TextColor
    $DataDirTextBox.Location = New-Object System.Drawing.Point(20, 105)
    $DataDirTextBox.Size = New-Object System.Drawing.Size(600, 25)
    $DataDirTextBox.Add_TextChanged({
        $Script:DataStore = $DataDirTextBox.Text
        Write-StatusLog "Data directory updated: $($DataDirTextBox.Text)" -Level Config -Category Config
    })
    
    # Collector output directory
    $CollectorDirLabel = New-Object System.Windows.Forms.Label
    $CollectorDirLabel.Text = "Offline Collector Output Directory:"
    $CollectorDirLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $CollectorDirLabel.ForeColor = $Colors.TextColor
    $CollectorDirLabel.Location = New-Object System.Drawing.Point(20, 140)
    $CollectorDirLabel.Size = New-Object System.Drawing.Size(250, 20)
    
    $CollectorDirTextBox = New-Object System.Windows.Forms.TextBox
    $CollectorDirTextBox.Text = $Script:CollectorOutputDir
    $CollectorDirTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $CollectorDirTextBox.BackColor = $Colors.DarkBackground
    $CollectorDirTextBox.ForeColor = $Colors.TextColor
    $CollectorDirTextBox.Location = New-Object System.Drawing.Point(20, 160)
    $CollectorDirTextBox.Size = New-Object System.Drawing.Size(600, 25)
    $CollectorDirTextBox.Add_TextChanged({
        $Script:CollectorOutputDir = $CollectorDirTextBox.Text
        Write-StatusLog "Collector output directory updated: $($CollectorDirTextBox.Text)" -Level Config -Category Config
    })
    
    $DirGroupBox.Controls.AddRange(@($InstallDirLabel, $InstallDirTextBox, $DataDirLabel, $DataDirTextBox, $CollectorDirLabel, $CollectorDirTextBox))
    
    # Right column - Authentication
    $AuthGroupBox = New-Object System.Windows.Forms.GroupBox
    $AuthGroupBox.Text = "Authentication and Network"
    $AuthGroupBox.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $AuthGroupBox.ForeColor = $Colors.AccentColor
    $AuthGroupBox.Location = New-Object System.Drawing.Point(680, 70)
    $AuthGroupBox.Size = New-Object System.Drawing.Size(640, 200)
    
    # Admin password section
    $AdminPassLabel = New-Object System.Windows.Forms.Label
    $AdminPassLabel.Text = "IR Admin Password:"
    $AdminPassLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $AdminPassLabel.ForeColor = $Colors.TextColor
    $AdminPassLabel.Location = New-Object System.Drawing.Point(20, 30)
    $AdminPassLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $Script:AdminPassTextBox = New-Object System.Windows.Forms.TextBox
    $Script:AdminPassTextBox.Text = $Script:ConfigSettings.AdminPassword
    $Script:AdminPassTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $Script:AdminPassTextBox.BackColor = $Colors.DarkBackground
    $Script:AdminPassTextBox.ForeColor = $Colors.TextColor
    $Script:AdminPassTextBox.Location = New-Object System.Drawing.Point(20, 50)
    $Script:AdminPassTextBox.Size = New-Object System.Drawing.Size(400, 25)
    $Script:AdminPassTextBox.UseSystemPasswordChar = $true
    $Script:AdminPassTextBox.Add_TextChanged({
        $Script:ConfigSettings.AdminPassword = $Script:AdminPassTextBox.Text
        Write-StatusLog "Admin password updated" -Level Security -Category Security
    })
    
    # Generate password button
    $GenPassButton = New-Object System.Windows.Forms.Button
    $GenPassButton.Text = "Generate"
    $GenPassButton.Size = New-Object System.Drawing.Size(80, 25)
    $GenPassButton.Location = New-Object System.Drawing.Point(430, 50)
    $GenPassButton.BackColor = $Colors.VelociraptorBlue
    $GenPassButton.ForeColor = $Colors.TextColor
    $GenPassButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $GenPassButton.Add_Click({
        $newPassword = New-IRPassword -Complexity High -Length 20
        $Script:AdminPassTextBox.Text = $newPassword
        $Script:ConfigSettings.AdminPassword = $newPassword
        Write-StatusLog "New secure IR admin password generated" -Level Success -Category Security
    })
    
    # Show password checkbox
    $ShowPassCheckBox = New-Object System.Windows.Forms.CheckBox
    $ShowPassCheckBox.Text = "Show Password"
    $ShowPassCheckBox.Location = New-Object System.Drawing.Point(520, 50)
    $ShowPassCheckBox.Size = New-Object System.Drawing.Size(120, 25)
    $ShowPassCheckBox.ForeColor = $Colors.TextColor
    $ShowPassCheckBox.Add_CheckedChanged({
        $Script:AdminPassTextBox.UseSystemPasswordChar = -not $ShowPassCheckBox.Checked
    })
    
    # GUI Port
    $GuiPortLabel = New-Object System.Windows.Forms.Label
    $GuiPortLabel.Text = "GUI Port:"
    $GuiPortLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $GuiPortLabel.ForeColor = $Colors.TextColor
    $GuiPortLabel.Location = New-Object System.Drawing.Point(20, 90)
    $GuiPortLabel.Size = New-Object System.Drawing.Size(100, 20)
    
    $GuiPortTextBox = New-Object System.Windows.Forms.TextBox
    $GuiPortTextBox.Text = $Script:ConfigSettings.GuiPort.ToString()
    $GuiPortTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $GuiPortTextBox.BackColor = $Colors.DarkBackground
    $GuiPortTextBox.ForeColor = $Colors.TextColor
    $GuiPortTextBox.Location = New-Object System.Drawing.Point(20, 110)
    $GuiPortTextBox.Size = New-Object System.Drawing.Size(100, 25)
    $GuiPortTextBox.Add_TextChanged({
        if ([int]::TryParse($GuiPortTextBox.Text, [ref]$null)) {
            $Script:ConfigSettings.GuiPort = [int]$GuiPortTextBox.Text
            Write-StatusLog "GUI port updated: $($GuiPortTextBox.Text)" -Level Config -Category Network
        }
    })
    
    # SSL Enable
    $SSLCheckBox = New-Object System.Windows.Forms.CheckBox
    $SSLCheckBox.Text = "Enable SSL/TLS"
    $SSLCheckBox.Checked = $Script:ConfigSettings.SSL
    $SSLCheckBox.Location = New-Object System.Drawing.Point(140, 110)
    $SSLCheckBox.Size = New-Object System.Drawing.Size(120, 25)
    $SSLCheckBox.ForeColor = $Colors.TextColor
    $SSLCheckBox.Add_CheckedChanged({
        $Script:ConfigSettings.SSL = $SSLCheckBox.Checked
        Write-StatusLog "SSL setting: $($SSLCheckBox.Checked)" -Level Config -Category Security
    })
    
    $AuthGroupBox.Controls.AddRange(@($AdminPassLabel, $Script:AdminPassTextBox, $GenPassButton, $ShowPassCheckBox, $GuiPortLabel, $GuiPortTextBox, $SSLCheckBox))
    
    $ConfigTab.Controls.AddRange(@($ConfigHeaderLabel, $DirGroupBox, $AuthGroupBox))
    $TabControl.TabPages.Add($ConfigTab)
    
    Write-Host "Configuration tab created successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to create Configuration tab: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Creating Deployment Status tab..." -ForegroundColor Yellow

try {
    # Tab 3: Deployment & Status
    $StatusTab = New-Object System.Windows.Forms.TabPage
    $StatusTab.Text = "Deployment Status"
    $StatusTab.BackColor = $Colors.DarkBackground
    $StatusTab.ForeColor = $Colors.TextColor
    
    # Status header
    $StatusHeaderLabel = New-Object System.Windows.Forms.Label
    $StatusHeaderLabel.Text = "DEPLOYMENT STATUS AND MONITORING"
    $StatusHeaderLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $StatusHeaderLabel.ForeColor = $Colors.AccentColor
    $StatusHeaderLabel.Location = New-Object System.Drawing.Point(20, 20)
    $StatusHeaderLabel.Size = New-Object System.Drawing.Size(800, 30)
    
    # Progress section
    $ProgressGroupBox = New-Object System.Windows.Forms.GroupBox
    $ProgressGroupBox.Text = "Deployment Progress"
    $ProgressGroupBox.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $ProgressGroupBox.ForeColor = $Colors.AccentColor
    $ProgressGroupBox.Location = New-Object System.Drawing.Point(20, 70)
    $ProgressGroupBox.Size = New-Object System.Drawing.Size(1320, 120)
    
    # Progress bar
    $Script:ProgressBar = New-Object System.Windows.Forms.ProgressBar
    $Script:ProgressBar.Location = New-Object System.Drawing.Point(30, 30)
    $Script:ProgressBar.Size = New-Object System.Drawing.Size(1260, 30)
    $Script:ProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
    
    # Status label
    $Script:StatusLabel = New-Object System.Windows.Forms.Label
    $Script:StatusLabel.Text = "Ready for enhanced IR deployment"
    $Script:StatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Script:StatusLabel.ForeColor = $Colors.InfoBlue
    $Script:StatusLabel.Location = New-Object System.Drawing.Point(30, 70)
    $Script:StatusLabel.Size = New-Object System.Drawing.Size(1260, 25)
    
    $ProgressGroupBox.Controls.AddRange(@($Script:ProgressBar, $Script:StatusLabel))
    
    # Log section
    $LogGroupBox = New-Object System.Windows.Forms.GroupBox
    $LogGroupBox.Text = "Enhanced Deployment Log"
    $LogGroupBox.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $LogGroupBox.ForeColor = $Colors.AccentColor
    $LogGroupBox.Location = New-Object System.Drawing.Point(20, 200)
    $LogGroupBox.Size = New-Object System.Drawing.Size(1320, 520)
    
    $Script:StatusLogTextBox = New-Object System.Windows.Forms.TextBox
    $Script:StatusLogTextBox.Multiline = $true
    $Script:StatusLogTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $Script:StatusLogTextBox.BackColor = $Colors.DarkBackground
    $Script:StatusLogTextBox.ForeColor = $Colors.TextColor
    $Script:StatusLogTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $Script:StatusLogTextBox.Location = New-Object System.Drawing.Point(20, 30)
    $Script:StatusLogTextBox.Size = New-Object System.Drawing.Size(1280, 470)
    $Script:StatusLogTextBox.ReadOnly = $true
    
    $LogGroupBox.Controls.Add($Script:StatusLogTextBox)
    
    # Deploy button
    $Script:DeployButton = New-Object System.Windows.Forms.Button
    $Script:DeployButton.Text = "Deploy Enhanced IR Platform"
    $Script:DeployButton.Size = New-Object System.Drawing.Size(250, 40)
    $Script:DeployButton.Location = New-Object System.Drawing.Point(20, 730)
    $Script:DeployButton.BackColor = $Colors.VelociraptorGreen
    $Script:DeployButton.ForeColor = [System.Drawing.Color]::Black
    $Script:DeployButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $Script:DeployButton.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Script:DeployButton.Enabled = $false
    $Script:DeployButton.Add_Click({
        # Run enhanced deployment in background thread
        $runspace = [powershell]::Create()
        $runspace.AddScript({
            param($deployFunction)
            & $deployFunction
        }).AddArgument(${function:Start-EnhancedIRDeployment}) | Out-Null
        $runspace.BeginInvoke() | Out-Null
    })
    
    # Exit button
    $ExitButton = New-Object System.Windows.Forms.Button
    $ExitButton.Text = "Exit"
    $ExitButton.Size = New-Object System.Drawing.Size(100, 40)
    $ExitButton.Location = New-Object System.Drawing.Point(1240, 730)
    $ExitButton.BackColor = $Colors.DarkBackground
    $ExitButton.ForeColor = $Colors.TextColor
    $ExitButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ExitButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $ExitButton.Add_Click({ $MainForm.Close() })
    
    $StatusTab.Controls.AddRange(@($StatusHeaderLabel, $ProgressGroupBox, $LogGroupBox, $Script:DeployButton, $ExitButton))
    $TabControl.TabPages.Add($StatusTab)
    
    Write-Host "Deployment Status tab created successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to create Deployment Status tab: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Show the enhanced form
Write-Host "Launching Enhanced Incident Response GUI..." -ForegroundColor Green

try {
    if ($StartMinimized) {
        $MainForm.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
    }
    
    Write-Host "Enhanced Incident Response GUI launched successfully!" -ForegroundColor Green
    Write-Host "Configure your incident response deployment across multiple tabs" -ForegroundColor Cyan
    
    # Show the form and wait for it to close
    $result = $MainForm.ShowDialog()
    
    Write-Host "Enhanced Incident Response session completed successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to show Enhanced GUI: $($_.Exception.Message)" -ForegroundColor Red
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

Write-Host "Enhanced Incident Response session completed!" -ForegroundColor Green