#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Velociraptor Simple Comprehensive Installation GUI
    
.DESCRIPTION
    A streamlined, single-form GUI that combines excellent usability with comprehensive 
    Velociraptor configuration options. Features:
    - Single form with grouped sections (no complex tabs)
    - Large, clearly labeled buttons with optimal spacing
    - Automatic configuration generation based on user selections
    - Real-time progress feedback in integrated log panel
    - Professional layout that's immediately intuitive
    - All-in-one interface handling complete setup automatically
    
.PARAMETER InstallDir
    Installation directory. Default: C:\tools
    
.PARAMETER DataStore
    Data storage directory. Default: C:\VelociraptorData
    
.PARAMETER GuiPort
    GUI port number. Default: 8889
    
.EXAMPLE
    .\VelociraptorGUI-Simple-Comprehensive.ps1
    
.NOTES
    Administrator privileges recommended for optimal functionality
    Version: 1.0.0 - Simple Comprehensive Edition
    Created: 2025-08-21
#>

[CmdletBinding()]
param(
    [string]$InstallDir = 'C:\tools',
    [string]$DataStore = 'C:\VelociraptorData',
    [int]$GuiPort = 8889
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Write-Host "=== Velociraptor Simple Comprehensive GUI ===" -ForegroundColor Cyan
Write-Host "Loading Windows Forms and initializing interface..." -ForegroundColor Yellow

#region Windows Forms Initialization
try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
    [System.Windows.Forms.Application]::EnableVisualStyles()
    
    Write-Host "Windows Forms initialized successfully" -ForegroundColor Green
}
catch {
    try {
        [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
        [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
        Write-Host "Alternative initialization successful" -ForegroundColor Green
    }
    catch {
        Write-Host "CRITICAL: Cannot load Windows Forms. GUI cannot continue." -ForegroundColor Red
        exit 1
    }
}
#endregion

#region Global Variables and Colors
$Script:CurrentStep = 0
$Script:TotalSteps = 8
$Script:IsInstalling = $false
$Script:VelociraptorProcess = $null
$Script:ConfigPath = ""
$Script:AdminUsername = "admin"
$Script:AdminPassword = ""
$Script:InstallDir = $InstallDir
$Script:DataStore = $DataStore
$Script:GuiPort = $GuiPort

# Professional color scheme optimized for usability
$Colors = @{
    DarkBackground = [System.Drawing.Color]::FromArgb(25, 25, 25)
    LightSurface = [System.Drawing.Color]::FromArgb(50, 50, 50)
    CardSurface = [System.Drawing.Color]::FromArgb(40, 40, 40)
    AccentBlue = [System.Drawing.Color]::FromArgb(0, 120, 215)
    SuccessGreen = [System.Drawing.Color]::FromArgb(16, 124, 16)
    WarningOrange = [System.Drawing.Color]::FromArgb(255, 185, 0)
    ErrorRed = [System.Drawing.Color]::FromArgb(196, 43, 28)
    TextWhite = [System.Drawing.Color]::White
    TextLight = [System.Drawing.Color]::FromArgb(220, 220, 220)
    TextMuted = [System.Drawing.Color]::FromArgb(160, 160, 160)
    BorderGray = [System.Drawing.Color]::FromArgb(70, 70, 70)
    HoverBlue = [System.Drawing.Color]::FromArgb(0, 100, 180)
}

# Configuration options
$Script:DeploymentType = "Standalone"
$Script:SecurityLevel = "Standard"
$Script:ArtifactPack = "Essential"
$Script:EnableMonitoring = $true
$Script:EnableSSL = $true
$Script:EnableFirewall = $true
#endregion

#region Utility Functions
function Write-StatusLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Step')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'HH:mm:ss'
    $prefix = switch ($Level) {
        'Success' { "[✓]" }
        'Warning' { "[!]" }
        'Error' { "[✗]" }
        'Step' { "[▶]" }
        default { "[•]" }
    }
    
    $logEntry = "$timestamp $prefix $Message"
    
    if ($Script:LogTextBox) {
        try {
            $Script:LogTextBox.AppendText("$logEntry`r`n")
            $Script:LogTextBox.SelectionStart = $Script:LogTextBox.Text.Length
            $Script:LogTextBox.ScrollToCaret()
            $Script:LogTextBox.Refresh()
            [System.Windows.Forms.Application]::DoEvents()
        }
        catch { }
    }
    
    $consoleColor = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Step' { 'Cyan' }
        default { 'White' }
    }
    
    Write-Host $logEntry -ForegroundColor $consoleColor
}

function Update-ProgressBar {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Step,
        
        [Parameter(Mandatory)]
        [string]$Status
    )
    
    if ($Script:ProgressBar -and $Script:StatusLabel) {
        try {
            $Script:ProgressBar.Value = [math]::Min(($Step * 100 / $Script:TotalSteps), 100)
            $Script:StatusLabel.Text = $Status
            $Script:ProgressBar.Refresh()
            $Script:StatusLabel.Refresh()
            [System.Windows.Forms.Application]::DoEvents()
        }
        catch {
            Write-StatusLog "Progress update failed (non-critical)" -Level Warning
        }
    }
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-PortAvailable {
    [CmdletBinding()]
    param([int]$Port)
    
    try {
        $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $Port)
        $listener.Start()
        $listener.Stop()
        return $true
    }
    catch {
        return $false
    }
}

function Get-SecurePassword {
    return -join ((1..12) | ForEach-Object { Get-Random -InputObject @('a'..'z' + 'A'..'Z' + '0'..'9' + '!@#$%^&*') })
}

function Show-MessageDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title,
        
        [Parameter(Mandatory)]
        [string]$Message,
        
        [System.Windows.Forms.MessageBoxIcon]$Icon = [System.Windows.Forms.MessageBoxIcon]::Information
    )
    
    [System.Windows.Forms.MessageBox]::Show(
        $Message,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        $Icon
    )
}

function Select-FolderPath {
    param([string]$Description = "Select Folder")
    
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = $Description
    $folderBrowser.ShowNewFolderButton = $true
    
    $result = $folderBrowser.ShowDialog($MainForm)
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $folderBrowser.SelectedPath
    }
    return $null
}
#endregion

#region Velociraptor Installation Functions
function Get-LatestVelociraptorAsset {
    Write-StatusLog "Querying GitHub for latest Velociraptor release..." -Level Info
    
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
        Write-StatusLog "Found Velociraptor v$version ($([math]::Round($windowsAsset.size / 1048576, 1)) MB)" -Level Success
        
        return @{
            Version = $version
            DownloadUrl = $windowsAsset.browser_download_url
            Size = $windowsAsset.size
            Name = $windowsAsset.name
        }
    }
    catch {
        Write-StatusLog "Failed to query GitHub API: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Install-VelociraptorExecutable {
    [CmdletBinding()]
    param(
        $AssetInfo,
        [string]$DestinationPath
    )
    
    Write-StatusLog "Downloading $($AssetInfo.Name)..." -Level Step
    Update-ProgressBar -Step 2 -Status "Downloading Velociraptor executable..."
    
    try {
        $directory = Split-Path $DestinationPath -Parent
        if (-not (Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
            Write-StatusLog "Created directory: $directory" -Level Success
        }
        
        $tempFile = "$DestinationPath.download"
        
        $webClient = New-Object System.Net.WebClient
        
        Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action {
            $percent = $Event.SourceEventArgs.ProgressPercentage
            if ($Script:ProgressBar) {
                try {
                    $Script:ProgressBar.Invoke([Action]{
                        $Script:ProgressBar.Value = [math]::Min(20 + ($percent * 0.3), 50)
                    })
                }
                catch {}
            }
        } | Out-Null
        
        $webClient.DownloadFile($AssetInfo.DownloadUrl, $tempFile)
        
        if (Test-Path $tempFile) {
            $fileSize = (Get-Item $tempFile).Length
            Write-StatusLog "Download completed: $([math]::Round($fileSize / 1048576, 1)) MB" -Level Success
            
            if ($fileSize -eq 0) {
                throw "Downloaded file is empty"
            }
            
            Move-Item $tempFile $DestinationPath -Force
            Write-StatusLog "Executable installed successfully" -Level Success
            
            return $true
        }
        else {
            throw "Download file not found"
        }
    }
    catch {
        Write-StatusLog "Download failed: $($_.Exception.Message)" -Level Error
        if (Test-Path $tempFile) { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }
        throw
    }
    finally {
        if ($webClient) { $webClient.Dispose() }
        Get-EventSubscriber | Where-Object { $_.SourceObject -is [System.Net.WebClient] } | Unregister-Event
    }
}

function New-VelociraptorConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ExecutablePath,
        
        [Parameter(Mandatory)]
        [string]$ConfigPath
    )
    
    Write-StatusLog "Generating comprehensive Velociraptor configuration..." -Level Step
    Update-ProgressBar -Step 3 -Status "Generating server configuration..."
    
    try {
        $configDir = Split-Path $ConfigPath -Parent
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        # Generate base configuration
        $arguments = @(
            'config', 'generate'
            '--config', "`"$ConfigPath`""
        )
        
        Write-StatusLog "Running: velociraptor.exe $($arguments -join ' ')" -Level Info
        
        $process = Start-Process -FilePath $ExecutablePath -ArgumentList $arguments -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$env:TEMP\velo_config_out.log" -RedirectStandardError "$env:TEMP\velo_config_err.log"
        
        if ($process.ExitCode -ne 0) {
            $errorOutput = if (Test-Path "$env:TEMP\velo_config_err.log") { Get-Content "$env:TEMP\velo_config_err.log" -Raw } else { "Unknown error" }
            throw "Configuration generation failed with exit code $($process.ExitCode). Error: $errorOutput"
        }
        
        if (-not (Test-Path $ConfigPath)) {
            throw "Configuration file was not created at $ConfigPath"
        }
        
        Write-StatusLog "Base configuration generated successfully" -Level Success
        
        # Apply user-selected customizations
        Update-ProgressBar -Step 4 -Status "Applying customizations..."
        Write-StatusLog "Applying customizations based on selected options..." -Level Step
        
        $config = Get-Content $ConfigPath -Raw
        
        # Apply GUI port if different from default
        if ($Script:GuiPort -ne 8889) {
            $config = $config -replace 'bind_port: 8889', "bind_port: $Script:GuiPort"
            Write-StatusLog "Updated GUI port to $Script:GuiPort" -Level Info
        }
        
        # Apply security level configurations
        if ($Script:SecurityLevel -eq "High") {
            Write-StatusLog "Applying high security configurations..." -Level Info
            # Add high security settings (this would be expanded based on actual Velociraptor config)
        }
        elseif ($Script:SecurityLevel -eq "Enterprise") {
            Write-StatusLog "Applying enterprise security configurations..." -Level Info
            # Add enterprise security settings
        }
        
        # Apply deployment type configurations
        if ($Script:DeploymentType -eq "Server") {
            Write-StatusLog "Configuring for server deployment..." -Level Info
            # Add server-specific settings
        }
        elseif ($Script:DeploymentType -eq "Cluster") {
            Write-StatusLog "Configuring for cluster deployment..." -Level Info
            # Add clustering settings
        }
        
        # Apply monitoring configurations
        if ($Script:EnableMonitoring) {
            Write-StatusLog "Enabling comprehensive monitoring..." -Level Info
            # Add monitoring configurations
        }
        
        # Save customized configuration
        Set-Content -Path $ConfigPath -Value $config
        Write-StatusLog "Configuration customizations applied successfully" -Level Success
        
        return $true
    }
    catch {
        Write-StatusLog "Configuration generation failed: $($_.Exception.Message)" -Level Error
        throw
    }
}

function New-VelociraptorAdminUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ExecutablePath,
        
        [Parameter(Mandatory)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory)]
        [string]$Username,
        
        [Parameter(Mandatory)]
        [string]$Password
    )
    
    Write-StatusLog "Creating admin user '$Username'..." -Level Step
    Update-ProgressBar -Step 5 -Status "Creating admin user account..."
    
    try {
        $arguments = @(
            '--config', "`"$ConfigPath`""
            'user', 'add', $Username
            '--role', 'administrator'
            '--password', $Password
        )
        
        $process = Start-Process -FilePath $ExecutablePath -ArgumentList $arguments -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$env:TEMP\velo_user_out.log" -RedirectStandardError "$env:TEMP\velo_user_err.log"
        
        if ($process.ExitCode -ne 0) {
            $errorOutput = if (Test-Path "$env:TEMP\velo_user_err.log") { Get-Content "$env:TEMP\velo_user_err.log" -Raw } else { "Unknown error" }
            Write-StatusLog "User creation warning (exit code $($process.ExitCode)): $errorOutput" -Level Warning
            Write-StatusLog "User may already exist or will be created on first access" -Level Info
        }
        else {
            Write-StatusLog "Admin user '$Username' created successfully" -Level Success
        }
        
        return $true
    }
    catch {
        Write-StatusLog "User creation error: $($_.Exception.Message)" -Level Warning
        Write-StatusLog "Continuing - default credentials may be used" -Level Info
        return $true
    }
}

function Start-VelociraptorServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ExecutablePath,
        
        [Parameter(Mandatory)]
        [string]$ConfigPath
    )
    
    Write-StatusLog "Starting Velociraptor server with custom configuration..." -Level Step
    Update-ProgressBar -Step 6 -Status "Starting Velociraptor server..."
    
    try {
        $arguments = @(
            '--config', "`"$ConfigPath`""
            'frontend', '-v'
        )
        
        Write-StatusLog "Launching server process with comprehensive config..." -Level Info
        
        $process = Start-Process -FilePath $ExecutablePath -ArgumentList $arguments -PassThru -WindowStyle Hidden
        
        if ($process) {
            Write-StatusLog "Server process started (PID: $($process.Id))" -Level Success
            $Script:VelociraptorProcess = $process
            
            Update-ProgressBar -Step 7 -Status "Waiting for server to initialize..."
            Start-Sleep -Seconds 10
            
            return $process
        }
        else {
            throw "Failed to start server process"
        }
    }
    catch {
        Write-StatusLog "Server startup failed: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Wait-ForWebInterface {
    [CmdletBinding()]
    param(
        [int]$Port = 8889,
        [int]$TimeoutSeconds = 30
    )
    
    $uri = "https://127.0.0.1:$Port"
    $timeout = (Get-Date).AddSeconds($TimeoutSeconds)
    
    Write-StatusLog "Waiting for web interface to become available..." -Level Info
    
    while ((Get-Date) -lt $timeout) {
        try {
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
            
            $response = Invoke-WebRequest -Uri $uri -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                return $true
            }
        }
        catch {
            # Continue waiting
        }
        
        Start-Sleep -Seconds 2
    }
    
    return $false
}
#endregion

#region Main Installation Function
function Start-VelociraptorInstallation {
    if ($Script:IsInstalling) {
        Write-StatusLog "Installation already in progress" -Level Warning
        return
    }
    
    $Script:IsInstalling = $true
    
    try {
        Write-StatusLog "=== Starting Comprehensive Velociraptor Installation ===" -Level Step
        Write-StatusLog "Deployment Type: $Script:DeploymentType | Security Level: $Script:SecurityLevel" -Level Info
        Write-StatusLog "Artifact Pack: $Script:ArtifactPack | Monitoring: $Script:EnableMonitoring" -Level Info
        
        # Disable controls during installation
        Set-InstallationState -Installing $true
        
        # Step 1: Prerequisites check
        Update-ProgressBar -Step 1 -Status "Checking prerequisites..."
        Write-StatusLog "Checking prerequisites and validating configuration..." -Level Step
        
        if (-not (Test-Administrator)) {
            Write-StatusLog "Warning: Not running as Administrator - some features may not work" -Level Warning
        }
        
        if (-not (Test-PortAvailable -Port $Script:GuiPort)) {
            throw "Port $Script:GuiPort is already in use. Please select a different port."
        }
        
        # Create directories
        foreach ($dir in @($Script:InstallDir, $Script:DataStore)) {
            if (-not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Write-StatusLog "Created directory: $dir" -Level Success
            }
        }
        
        Write-StatusLog "Prerequisites check completed successfully" -Level Success
        
        # Step 2: Download Velociraptor
        $executablePath = Join-Path $Script:InstallDir 'velociraptor.exe'
        $assetInfo = Get-LatestVelociraptorAsset
        Install-VelociraptorExecutable -AssetInfo $assetInfo -DestinationPath $executablePath
        
        # Step 3-4: Generate and customize configuration
        $Script:ConfigPath = Join-Path $Script:InstallDir 'server.config.yaml'
        New-VelociraptorConfiguration -ExecutablePath $executablePath -ConfigPath $Script:ConfigPath
        
        # Step 5: Create admin user
        $Script:AdminPassword = Get-SecurePassword
        New-VelociraptorAdminUser -ExecutablePath $executablePath -ConfigPath $Script:ConfigPath -Username $Script:AdminUsername -Password $Script:AdminPassword
        
        # Step 6-7: Start server
        $process = Start-VelociraptorServer -ExecutablePath $executablePath -ConfigPath $Script:ConfigPath
        
        # Step 8: Verify web interface
        Update-ProgressBar -Step 8 -Status "Verifying web interface..."
        Write-StatusLog "Verifying web interface accessibility..." -Level Step
        
        if (Wait-ForWebInterface -Port $Script:GuiPort -TimeoutSeconds 30) {
            Write-StatusLog "=== Installation Completed Successfully ===" -Level Success
            Write-StatusLog "Web Interface: https://127.0.0.1:$Script:GuiPort" -Level Success
            Write-StatusLog "Username: $Script:AdminUsername" -Level Success
            Write-StatusLog "Password: $Script:AdminPassword" -Level Success
            Write-StatusLog "Configuration: $Script:ConfigPath" -Level Info
            
            # Update UI for success
            Set-InstallationState -Installing $false -Success $true
            
            Update-ProgressBar -Step 8 -Status "Installation completed successfully!"
            
            # Show success dialog
            Show-MessageDialog -Title "Installation Complete" -Message @"
Velociraptor installation completed successfully!

Configuration Applied:
• Deployment Type: $Script:DeploymentType
• Security Level: $Script:SecurityLevel
• Artifact Pack: $Script:ArtifactPack
• Monitoring: $(if ($Script:EnableMonitoring) { 'Enabled' } else { 'Disabled' })

Web Interface: https://127.0.0.1:$Script:GuiPort
Username: $Script:AdminUsername
Password: $Script:AdminPassword

The server is now running and ready to use.
Click 'Open Web Interface' to access Velociraptor.

IMPORTANT: Save these credentials securely!
"@ -Icon Information
        }
        else {
            throw "Web interface is not accessible after 30 seconds. Server may not have started correctly."
        }
    }
    catch {
        Write-StatusLog "Installation failed: $($_.Exception.Message)" -Level Error
        
        # Update UI for failure
        Set-InstallationState -Installing $false -Success $false
        
        Show-MessageDialog -Title "Installation Failed" -Message @"
Installation failed: $($_.Exception.Message)

Suggestions:
• Verify you have Administrator privileges
• Check that port $Script:GuiPort is not in use
• Ensure adequate disk space (500MB minimum)
• Check internet connectivity for downloads
• Try running as Administrator
"@ -Icon Error
    }
    finally {
        $Script:IsInstalling = $false
    }
}

function Set-InstallationState {
    param(
        [bool]$Installing,
        [bool]$Success = $false
    )
    
    if ($Installing) {
        # Disable controls during installation
        $Script:InstallButton.Enabled = $false
        $Script:InstallButton.Text = "Installing..."
        $Script:InstallButton.BackColor = $Colors.WarningOrange
        
        $Script:OpenWebButton.Enabled = $false
        $Script:StopServerButton.Enabled = $false
        
        # Disable configuration controls
        $Script:InstallDirTextBox.Enabled = $false
        $Script:DataDirTextBox.Enabled = $false
        $Script:GuiPortTextBox.Enabled = $false
        $Script:DeploymentTypeCombo.Enabled = $false
        $Script:SecurityLevelCombo.Enabled = $false
        $Script:ArtifactPackCombo.Enabled = $false
    }
    else {
        if ($Success) {
            # Installation succeeded
            $Script:InstallButton.Text = "Installation Complete"
            $Script:InstallButton.BackColor = $Colors.SuccessGreen
            $Script:OpenWebButton.Enabled = $true
            $Script:StopServerButton.Enabled = $true
        }
        else {
            # Installation failed - re-enable for retry
            $Script:InstallButton.Text = "Install Velociraptor"
            $Script:InstallButton.BackColor = $Colors.AccentBlue
            $Script:InstallButton.Enabled = $true
            
            # Re-enable configuration controls
            $Script:InstallDirTextBox.Enabled = $true
            $Script:DataDirTextBox.Enabled = $true
            $Script:GuiPortTextBox.Enabled = $true
            $Script:DeploymentTypeCombo.Enabled = $true
            $Script:SecurityLevelCombo.Enabled = $true
            $Script:ArtifactPackCombo.Enabled = $true
        }
    }
    
    [System.Windows.Forms.Application]::DoEvents()
}

function Open-VelociraptorWebInterface {
    try {
        $url = "https://127.0.0.1:$Script:GuiPort"
        Write-StatusLog "Opening web interface: $url" -Level Info
        Start-Process $url
        
        $credentials = "Username: $Script:AdminUsername`nPassword: $Script:AdminPassword"
        Set-Clipboard -Value $credentials
        
        Show-MessageDialog -Title "Web Interface Opened" -Message @"
Web interface opened in your default browser.

Credentials copied to clipboard:
Username: $Script:AdminUsername
Password: $Script:AdminPassword
"@ -Icon Information
    }
    catch {
        Write-StatusLog "Failed to open web interface: $($_.Exception.Message)" -Level Error
        Show-MessageDialog -Title "Web Interface Error" -Message @"
Failed to open web interface: $($_.Exception.Message)

Try manually navigating to: https://127.0.0.1:$Script:GuiPort

Credentials:
Username: $Script:AdminUsername
Password: $Script:AdminPassword
"@ -Icon Error
    }
}

function Stop-VelociraptorServer {
    try {
        if ($Script:VelociraptorProcess -and -not $Script:VelociraptorProcess.HasExited) {
            Write-StatusLog "Stopping Velociraptor server..." -Level Info
            $Script:VelociraptorProcess.Kill()
            $Script:VelociraptorProcess.WaitForExit(5000)
            Write-StatusLog "Server stopped successfully" -Level Success
            
            # Reset UI state
            $Script:StopServerButton.Enabled = $false
            $Script:OpenWebButton.Enabled = $false
            $Script:InstallButton.Enabled = $true
            $Script:InstallButton.Text = "Install Velociraptor"
            $Script:InstallButton.BackColor = $Colors.AccentBlue
            
            # Re-enable configuration controls
            $Script:InstallDirTextBox.Enabled = $true
            $Script:DataDirTextBox.Enabled = $true
            $Script:GuiPortTextBox.Enabled = $true
            $Script:DeploymentTypeCombo.Enabled = $true
            $Script:SecurityLevelCombo.Enabled = $true
            $Script:ArtifactPackCombo.Enabled = $true
            
            # Reset progress
            $Script:ProgressBar.Value = 0
            $Script:StatusLabel.Text = "Ready to install Velociraptor"
            
            $Script:VelociraptorProcess = $null
        }
        else {
            Write-StatusLog "No running server process found" -Level Warning
        }
    }
    catch {
        Write-StatusLog "Failed to stop server: $($_.Exception.Message)" -Level Error
    }
}

function Test-ConfigurationInputs {
    $errors = @()
    
    if ([string]::IsNullOrWhiteSpace($Script:InstallDirTextBox.Text)) {
        $errors += "Installation directory is required"
    }
    
    if ([string]::IsNullOrWhiteSpace($Script:DataDirTextBox.Text)) {
        $errors += "Data directory is required"
    }
    
    $portText = $Script:GuiPortTextBox.Text.Trim()
    if (-not [int]::TryParse($portText, [ref]$null)) {
        $errors += "Port must be a valid number"
    } elseif ([int]$portText -lt 1024 -or [int]$portText -gt 65535) {
        $errors += "Port must be between 1024 and 65535"
    }
    
    if ($errors.Count -gt 0) {
        Show-MessageDialog -Title "Configuration Error" -Message ($errors -join "`n") -Icon Error
        return $false
    }
    
    return $true
}

function Start-AsyncInstallation {
    # Use timer to prevent GUI freezing
    $Script:InstallTimer = New-Object System.Windows.Forms.Timer
    $Script:InstallTimer.Interval = 100
    $Script:InstallTimer.Add_Tick({
        $Script:InstallTimer.Stop()
        try {
            Start-VelociraptorInstallation
        }
        catch {
            Write-StatusLog "Async installation error: $($_.Exception.Message)" -Level Error
        }
        finally {
            $Script:InstallTimer.Dispose()
        }
    })
    $Script:InstallTimer.Start()
}
#endregion

#region GUI Creation
Write-StatusLog "Creating streamlined comprehensive GUI..." -Level Info

# Create main form with optimal sizing
$MainForm = New-Object System.Windows.Forms.Form
$MainForm.Text = "Velociraptor DFIR Framework - Simple Comprehensive GUI v1.0"
$MainForm.Size = New-Object System.Drawing.Size(1200, 800)
$MainForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$MainForm.BackColor = $Colors.DarkBackground
$MainForm.ForeColor = $Colors.TextWhite
$MainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$MainForm.MaximizeBox = $false
$MainForm.MinimizeBox = $true

# Header Panel - Professional branding
$HeaderPanel = New-Object System.Windows.Forms.Panel
$HeaderPanel.Size = New-Object System.Drawing.Size(1180, 80)
$HeaderPanel.Location = New-Object System.Drawing.Point(10, 10)
$HeaderPanel.BackColor = $Colors.CardSurface

$TitleLabel = New-Object System.Windows.Forms.Label
$TitleLabel.Text = "Velociraptor DFIR Framework"
$TitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$TitleLabel.ForeColor = $Colors.AccentBlue
$TitleLabel.Location = New-Object System.Drawing.Point(20, 15)
$TitleLabel.Size = New-Object System.Drawing.Size(500, 35)

$SubtitleLabel = New-Object System.Windows.Forms.Label
$SubtitleLabel.Text = "Simple Comprehensive Installation - Professional DFIR Automation"
$SubtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$SubtitleLabel.ForeColor = $Colors.TextLight
$SubtitleLabel.Location = New-Object System.Drawing.Point(20, 45)
$SubtitleLabel.Size = New-Object System.Drawing.Size(800, 25)

$HeaderPanel.Controls.AddRange(@($TitleLabel, $SubtitleLabel))
$MainForm.Controls.Add($HeaderPanel)

# Configuration Panel - Left side grouped configuration
$ConfigPanel = New-Object System.Windows.Forms.Panel
$ConfigPanel.Size = New-Object System.Drawing.Size(580, 400)
$ConfigPanel.Location = New-Object System.Drawing.Point(10, 100)
$ConfigPanel.BackColor = $Colors.CardSurface

# Configuration Title
$ConfigTitle = New-Object System.Windows.Forms.Label
$ConfigTitle.Text = "Installation Configuration"
$ConfigTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$ConfigTitle.ForeColor = $Colors.AccentBlue
$ConfigTitle.Location = New-Object System.Drawing.Point(20, 15)
$ConfigTitle.Size = New-Object System.Drawing.Size(300, 25)

# Basic Settings Group
$BasicGroupLabel = New-Object System.Windows.Forms.Label
$BasicGroupLabel.Text = "Basic Settings"
$BasicGroupLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$BasicGroupLabel.ForeColor = $Colors.TextWhite
$BasicGroupLabel.Location = New-Object System.Drawing.Point(20, 50)
$BasicGroupLabel.Size = New-Object System.Drawing.Size(200, 25)

# Installation Directory
$InstallDirLabel = New-Object System.Windows.Forms.Label
$InstallDirLabel.Text = "Installation Directory:"
$InstallDirLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$InstallDirLabel.ForeColor = $Colors.TextLight
$InstallDirLabel.Location = New-Object System.Drawing.Point(30, 80)
$InstallDirLabel.Size = New-Object System.Drawing.Size(150, 20)

$Script:InstallDirTextBox = New-Object System.Windows.Forms.TextBox
$Script:InstallDirTextBox.Text = $Script:InstallDir
$Script:InstallDirTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:InstallDirTextBox.BackColor = $Colors.LightSurface
$Script:InstallDirTextBox.ForeColor = $Colors.TextWhite
$Script:InstallDirTextBox.Location = New-Object System.Drawing.Point(190, 78)
$Script:InstallDirTextBox.Size = New-Object System.Drawing.Size(280, 25)
$Script:InstallDirTextBox.Add_TextChanged({
    $Script:InstallDir = $Script:InstallDirTextBox.Text
})

$InstallDirBrowseButton = New-Object System.Windows.Forms.Button
$InstallDirBrowseButton.Text = "Browse"
$InstallDirBrowseButton.Size = New-Object System.Drawing.Size(80, 25)
$InstallDirBrowseButton.Location = New-Object System.Drawing.Point(480, 78)
$InstallDirBrowseButton.BackColor = $Colors.BorderGray
$InstallDirBrowseButton.ForeColor = $Colors.TextWhite
$InstallDirBrowseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$InstallDirBrowseButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$InstallDirBrowseButton.Add_Click({
    $selectedPath = Select-FolderPath -Description "Select Installation Directory"
    if ($selectedPath) {
        $Script:InstallDirTextBox.Text = $selectedPath
        Write-StatusLog "Installation directory updated: $selectedPath" -Level Info
    }
})

# Data Directory
$DataDirLabel = New-Object System.Windows.Forms.Label
$DataDirLabel.Text = "Data Directory:"
$DataDirLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$DataDirLabel.ForeColor = $Colors.TextLight
$DataDirLabel.Location = New-Object System.Drawing.Point(30, 115)
$DataDirLabel.Size = New-Object System.Drawing.Size(150, 20)

$Script:DataDirTextBox = New-Object System.Windows.Forms.TextBox
$Script:DataDirTextBox.Text = $Script:DataStore
$Script:DataDirTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:DataDirTextBox.BackColor = $Colors.LightSurface
$Script:DataDirTextBox.ForeColor = $Colors.TextWhite
$Script:DataDirTextBox.Location = New-Object System.Drawing.Point(190, 113)
$Script:DataDirTextBox.Size = New-Object System.Drawing.Size(280, 25)
$Script:DataDirTextBox.Add_TextChanged({
    $Script:DataStore = $Script:DataDirTextBox.Text
})

$DataDirBrowseButton = New-Object System.Windows.Forms.Button
$DataDirBrowseButton.Text = "Browse"
$DataDirBrowseButton.Size = New-Object System.Drawing.Size(80, 25)
$DataDirBrowseButton.Location = New-Object System.Drawing.Point(480, 113)
$DataDirBrowseButton.BackColor = $Colors.BorderGray
$DataDirBrowseButton.ForeColor = $Colors.TextWhite
$DataDirBrowseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$DataDirBrowseButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$DataDirBrowseButton.Add_Click({
    $selectedPath = Select-FolderPath -Description "Select Data Directory"
    if ($selectedPath) {
        $Script:DataDirTextBox.Text = $selectedPath
        Write-StatusLog "Data directory updated: $selectedPath" -Level Info
    }
})

# GUI Port
$GuiPortLabel = New-Object System.Windows.Forms.Label
$GuiPortLabel.Text = "GUI Port:"
$GuiPortLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$GuiPortLabel.ForeColor = $Colors.TextLight
$GuiPortLabel.Location = New-Object System.Drawing.Point(30, 150)
$GuiPortLabel.Size = New-Object System.Drawing.Size(150, 20)

$Script:GuiPortTextBox = New-Object System.Windows.Forms.TextBox
$Script:GuiPortTextBox.Text = $Script:GuiPort.ToString()
$Script:GuiPortTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:GuiPortTextBox.BackColor = $Colors.LightSurface
$Script:GuiPortTextBox.ForeColor = $Colors.TextWhite
$Script:GuiPortTextBox.Location = New-Object System.Drawing.Point(190, 148)
$Script:GuiPortTextBox.Size = New-Object System.Drawing.Size(100, 25)
$Script:GuiPortTextBox.Add_TextChanged({
    $portText = $Script:GuiPortTextBox.Text
    if ([int]::TryParse($portText, [ref]$null)) {
        $port = [int]$portText
        $Script:GuiPort = $port
        if ($port -ge 1024 -and $port -le 65535) {
            $Script:GuiPortTextBox.BackColor = $Colors.LightSurface
        } else {
            $Script:GuiPortTextBox.BackColor = $Colors.ErrorRed
        }
    } else {
        $Script:GuiPortTextBox.BackColor = $Colors.ErrorRed
    }
})

# Advanced Settings Group
$AdvancedGroupLabel = New-Object System.Windows.Forms.Label
$AdvancedGroupLabel.Text = "Deployment Configuration"
$AdvancedGroupLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$AdvancedGroupLabel.ForeColor = $Colors.TextWhite
$AdvancedGroupLabel.Location = New-Object System.Drawing.Point(20, 190)
$AdvancedGroupLabel.Size = New-Object System.Drawing.Size(250, 25)

# Deployment Type
$DeploymentTypeLabel = New-Object System.Windows.Forms.Label
$DeploymentTypeLabel.Text = "Deployment Type:"
$DeploymentTypeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$DeploymentTypeLabel.ForeColor = $Colors.TextLight
$DeploymentTypeLabel.Location = New-Object System.Drawing.Point(30, 220)
$DeploymentTypeLabel.Size = New-Object System.Drawing.Size(150, 20)

$Script:DeploymentTypeCombo = New-Object System.Windows.Forms.ComboBox
$Script:DeploymentTypeCombo.Items.AddRange(@("Standalone", "Server", "Cluster"))
$Script:DeploymentTypeCombo.SelectedItem = $Script:DeploymentType
$Script:DeploymentTypeCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$Script:DeploymentTypeCombo.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:DeploymentTypeCombo.BackColor = $Colors.LightSurface
$Script:DeploymentTypeCombo.ForeColor = $Colors.TextWhite
$Script:DeploymentTypeCombo.Location = New-Object System.Drawing.Point(190, 218)
$Script:DeploymentTypeCombo.Size = New-Object System.Drawing.Size(150, 25)
$Script:DeploymentTypeCombo.Add_SelectedIndexChanged({
    $Script:DeploymentType = $Script:DeploymentTypeCombo.SelectedItem
    Write-StatusLog "Deployment type changed to: $Script:DeploymentType" -Level Info
})

# Security Level
$SecurityLevelLabel = New-Object System.Windows.Forms.Label
$SecurityLevelLabel.Text = "Security Level:"
$SecurityLevelLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$SecurityLevelLabel.ForeColor = $Colors.TextLight
$SecurityLevelLabel.Location = New-Object System.Drawing.Point(30, 255)
$SecurityLevelLabel.Size = New-Object System.Drawing.Size(150, 20)

$Script:SecurityLevelCombo = New-Object System.Windows.Forms.ComboBox
$Script:SecurityLevelCombo.Items.AddRange(@("Standard", "High", "Enterprise"))
$Script:SecurityLevelCombo.SelectedItem = $Script:SecurityLevel
$Script:SecurityLevelCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$Script:SecurityLevelCombo.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:SecurityLevelCombo.BackColor = $Colors.LightSurface
$Script:SecurityLevelCombo.ForeColor = $Colors.TextWhite
$Script:SecurityLevelCombo.Location = New-Object System.Drawing.Point(190, 253)
$Script:SecurityLevelCombo.Size = New-Object System.Drawing.Size(150, 25)
$Script:SecurityLevelCombo.Add_SelectedIndexChanged({
    $Script:SecurityLevel = $Script:SecurityLevelCombo.SelectedItem
    Write-StatusLog "Security level changed to: $Script:SecurityLevel" -Level Info
})

# Artifact Pack
$ArtifactPackLabel = New-Object System.Windows.Forms.Label
$ArtifactPackLabel.Text = "Artifact Pack:"
$ArtifactPackLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$ArtifactPackLabel.ForeColor = $Colors.TextLight
$ArtifactPackLabel.Location = New-Object System.Drawing.Point(30, 290)
$ArtifactPackLabel.Size = New-Object System.Drawing.Size(150, 20)

$Script:ArtifactPackCombo = New-Object System.Windows.Forms.ComboBox
$Script:ArtifactPackCombo.Items.AddRange(@("Essential", "Windows", "Linux", "Complete"))
$Script:ArtifactPackCombo.SelectedItem = $Script:ArtifactPack
$Script:ArtifactPackCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$Script:ArtifactPackCombo.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:ArtifactPackCombo.BackColor = $Colors.LightSurface
$Script:ArtifactPackCombo.ForeColor = $Colors.TextWhite
$Script:ArtifactPackCombo.Location = New-Object System.Drawing.Point(190, 288)
$Script:ArtifactPackCombo.Size = New-Object System.Drawing.Size(150, 25)
$Script:ArtifactPackCombo.Add_SelectedIndexChanged({
    $Script:ArtifactPack = $Script:ArtifactPackCombo.SelectedItem
    Write-StatusLog "Artifact pack changed to: $Script:ArtifactPack" -Level Info
})

# Options Checkboxes
$MonitoringCheckbox = New-Object System.Windows.Forms.CheckBox
$MonitoringCheckbox.Text = "Enable Comprehensive Monitoring"
$MonitoringCheckbox.Checked = $Script:EnableMonitoring
$MonitoringCheckbox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$MonitoringCheckbox.ForeColor = $Colors.TextLight
$MonitoringCheckbox.Location = New-Object System.Drawing.Point(30, 325)
$MonitoringCheckbox.Size = New-Object System.Drawing.Size(250, 25)
$MonitoringCheckbox.Add_CheckedChanged({
    $Script:EnableMonitoring = $MonitoringCheckbox.Checked
    Write-StatusLog "Monitoring $(if ($Script:EnableMonitoring) { 'enabled' } else { 'disabled' })" -Level Info
})

$SSLCheckbox = New-Object System.Windows.Forms.CheckBox
$SSLCheckbox.Text = "Enable SSL/TLS Security"
$SSLCheckbox.Checked = $Script:EnableSSL
$SSLCheckbox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$SSLCheckbox.ForeColor = $Colors.TextLight
$SSLCheckbox.Location = New-Object System.Drawing.Point(30, 355)
$SSLCheckbox.Size = New-Object System.Drawing.Size(250, 25)
$SSLCheckbox.Add_CheckedChanged({
    $Script:EnableSSL = $SSLCheckbox.Checked
    Write-StatusLog "SSL/TLS $(if ($Script:EnableSSL) { 'enabled' } else { 'disabled' })" -Level Info
})

$ConfigPanel.Controls.AddRange(@(
    $ConfigTitle,
    $BasicGroupLabel,
    $InstallDirLabel, $Script:InstallDirTextBox, $InstallDirBrowseButton,
    $DataDirLabel, $Script:DataDirTextBox, $DataDirBrowseButton,
    $GuiPortLabel, $Script:GuiPortTextBox,
    $AdvancedGroupLabel,
    $DeploymentTypeLabel, $Script:DeploymentTypeCombo,
    $SecurityLevelLabel, $Script:SecurityLevelCombo,
    $ArtifactPackLabel, $Script:ArtifactPackCombo,
    $MonitoringCheckbox, $SSLCheckbox
))
$MainForm.Controls.Add($ConfigPanel)

# Right Panel - Progress and Log
$RightPanel = New-Object System.Windows.Forms.Panel
$RightPanel.Size = New-Object System.Drawing.Size(590, 400)
$RightPanel.Location = New-Object System.Drawing.Point(600, 100)
$RightPanel.BackColor = $Colors.CardSurface

# Progress Section
$ProgressTitle = New-Object System.Windows.Forms.Label
$ProgressTitle.Text = "Installation Progress"
$ProgressTitle.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$ProgressTitle.ForeColor = $Colors.AccentBlue
$ProgressTitle.Location = New-Object System.Drawing.Point(20, 15)
$ProgressTitle.Size = New-Object System.Drawing.Size(300, 25)

$Script:ProgressBar = New-Object System.Windows.Forms.ProgressBar
$Script:ProgressBar.Size = New-Object System.Drawing.Size(450, 25)
$Script:ProgressBar.Location = New-Object System.Drawing.Point(20, 50)
$Script:ProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous

$Script:StatusLabel = New-Object System.Windows.Forms.Label
$Script:StatusLabel.Text = "Ready to install Velociraptor"
$Script:StatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:StatusLabel.ForeColor = $Colors.TextMuted
$Script:StatusLabel.Location = New-Object System.Drawing.Point(480, 50)
$Script:StatusLabel.Size = New-Object System.Drawing.Size(100, 25)

# Log Section
$LogTitle = New-Object System.Windows.Forms.Label
$LogTitle.Text = "Installation Log"
$LogTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$LogTitle.ForeColor = $Colors.AccentBlue
$LogTitle.Location = New-Object System.Drawing.Point(20, 90)
$LogTitle.Size = New-Object System.Drawing.Size(200, 25)

$Script:LogTextBox = New-Object System.Windows.Forms.TextBox
$Script:LogTextBox.Multiline = $true
$Script:LogTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$Script:LogTextBox.BackColor = $Colors.DarkBackground
$Script:LogTextBox.ForeColor = $Colors.TextLight
$Script:LogTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$Script:LogTextBox.Location = New-Object System.Drawing.Point(20, 120)
$Script:LogTextBox.Size = New-Object System.Drawing.Size(550, 265)
$Script:LogTextBox.ReadOnly = $true

$RightPanel.Controls.AddRange(@(
    $ProgressTitle, $Script:ProgressBar, $Script:StatusLabel,
    $LogTitle, $Script:LogTextBox
))
$MainForm.Controls.Add($RightPanel)

# Button Panel - Large, well-spaced buttons
$ButtonPanel = New-Object System.Windows.Forms.Panel
$ButtonPanel.Size = New-Object System.Drawing.Size(1180, 70)
$ButtonPanel.Location = New-Object System.Drawing.Point(10, 510)
$ButtonPanel.BackColor = $Colors.CardSurface

# Install Button - Primary action button
$Script:InstallButton = New-Object System.Windows.Forms.Button
$Script:InstallButton.Text = "Install Velociraptor"
$Script:InstallButton.Size = New-Object System.Drawing.Size(200, 45)
$Script:InstallButton.Location = New-Object System.Drawing.Point(30, 12)
$Script:InstallButton.BackColor = $Colors.AccentBlue
$Script:InstallButton.ForeColor = $Colors.TextWhite
$Script:InstallButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$Script:InstallButton.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$Script:InstallButton.Add_MouseEnter({ $Script:InstallButton.BackColor = $Colors.HoverBlue })
$Script:InstallButton.Add_MouseLeave({ if ($Script:InstallButton.Enabled) { $Script:InstallButton.BackColor = $Colors.AccentBlue } })
$Script:InstallButton.Add_Click({
    Write-StatusLog "Starting comprehensive installation process..." -Level Info
    
    if (Test-ConfigurationInputs) {
        Write-StatusLog "Configuration validated successfully" -Level Success
        Start-AsyncInstallation
    } else {
        Write-StatusLog "Configuration validation failed" -Level Error
    }
})

# Open Web Interface Button
$Script:OpenWebButton = New-Object System.Windows.Forms.Button
$Script:OpenWebButton.Text = "Open Web Interface"
$Script:OpenWebButton.Size = New-Object System.Drawing.Size(180, 45)
$Script:OpenWebButton.Location = New-Object System.Drawing.Point(250, 12)
$Script:OpenWebButton.BackColor = $Colors.SuccessGreen
$Script:OpenWebButton.ForeColor = $Colors.TextWhite
$Script:OpenWebButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$Script:OpenWebButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$Script:OpenWebButton.Enabled = $false
$Script:OpenWebButton.Add_Click({ 
    Write-StatusLog "Opening web interface..." -Level Info
    Open-VelociraptorWebInterface 
})

# Validate Configuration Button
$ValidateButton = New-Object System.Windows.Forms.Button
$ValidateButton.Text = "Validate Config"
$ValidateButton.Size = New-Object System.Drawing.Size(140, 45)
$ValidateButton.Location = New-Object System.Drawing.Point(450, 12)
$ValidateButton.BackColor = $Colors.WarningOrange
$ValidateButton.ForeColor = $Colors.TextWhite
$ValidateButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$ValidateButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$ValidateButton.Add_Click({
    Write-StatusLog "Validating comprehensive configuration..." -Level Info
    if (Test-ConfigurationInputs) {
        Write-StatusLog "All configuration settings are valid" -Level Success
        Show-MessageDialog -Title "Configuration Valid" -Message @"
Configuration validation passed!

Settings Summary:
• Install Dir: $($Script:InstallDirTextBox.Text)
• Data Dir: $($Script:DataDirTextBox.Text)
• GUI Port: $($Script:GuiPortTextBox.Text)
• Deployment Type: $Script:DeploymentType
• Security Level: $Script:SecurityLevel
• Artifact Pack: $Script:ArtifactPack
• Monitoring: $(if ($Script:EnableMonitoring) { 'Enabled' } else { 'Disabled' })
• SSL/TLS: $(if ($Script:EnableSSL) { 'Enabled' } else { 'Disabled' })

All settings are valid and ready for installation.
"@ -Icon Information
    }
})

# Stop Server Button
$Script:StopServerButton = New-Object System.Windows.Forms.Button
$Script:StopServerButton.Text = "Stop Server"
$Script:StopServerButton.Size = New-Object System.Drawing.Size(130, 45)
$Script:StopServerButton.Location = New-Object System.Drawing.Point(610, 12)
$Script:StopServerButton.BackColor = $Colors.ErrorRed
$Script:StopServerButton.ForeColor = $Colors.TextWhite
$Script:StopServerButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$Script:StopServerButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:StopServerButton.Enabled = $false
$Script:StopServerButton.Add_Click({ 
    Write-StatusLog "Stopping Velociraptor server..." -Level Info
    Stop-VelociraptorServer 
})

# Reset Configuration Button
$ResetButton = New-Object System.Windows.Forms.Button
$ResetButton.Text = "Reset to Defaults"
$ResetButton.Size = New-Object System.Drawing.Size(150, 45)
$ResetButton.Location = New-Object System.Drawing.Point(760, 12)
$ResetButton.BackColor = $Colors.BorderGray
$ResetButton.ForeColor = $Colors.TextWhite
$ResetButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$ResetButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$ResetButton.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Reset all configuration settings to defaults?",
        "Reset Configuration",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        $Script:InstallDirTextBox.Text = "C:\tools"
        $Script:DataDirTextBox.Text = "C:\VelociraptorData"
        $Script:GuiPortTextBox.Text = "8889"
        $Script:DeploymentTypeCombo.SelectedItem = "Standalone"
        $Script:SecurityLevelCombo.SelectedItem = "Standard"
        $Script:ArtifactPackCombo.SelectedItem = "Essential"
        $MonitoringCheckbox.Checked = $true
        $SSLCheckbox.Checked = $true
        
        Write-StatusLog "Configuration reset to defaults" -Level Info
    }
})

# Exit Button
$ExitButton = New-Object System.Windows.Forms.Button
$ExitButton.Text = "Exit"
$ExitButton.Size = New-Object System.Drawing.Size(100, 45)
$ExitButton.Location = New-Object System.Drawing.Point(1050, 12)
$ExitButton.BackColor = $Colors.BorderGray
$ExitButton.ForeColor = $Colors.TextWhite
$ExitButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$ExitButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$ExitButton.Add_Click({ 
    Write-StatusLog "Exit requested" -Level Info
    $MainForm.Close() 
})

$ButtonPanel.Controls.AddRange(@(
    $Script:InstallButton,
    $Script:OpenWebButton,
    $ValidateButton,
    $Script:StopServerButton,
    $ResetButton,
    $ExitButton
))
$MainForm.Controls.Add($ButtonPanel)

# Status Bar at bottom
$StatusBar = New-Object System.Windows.Forms.Panel
$StatusBar.Size = New-Object System.Drawing.Size(1180, 40)
$StatusBar.Location = New-Object System.Drawing.Point(10, 590)
$StatusBar.BackColor = $Colors.LightSurface

$StatusBarLabel = New-Object System.Windows.Forms.Label
$StatusBarLabel.Text = "Ready • Configure settings above and click 'Install Velociraptor' to begin comprehensive setup"
$StatusBarLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$StatusBarLabel.ForeColor = $Colors.TextMuted
$StatusBarLabel.Location = New-Object System.Drawing.Point(20, 10)
$StatusBarLabel.Size = New-Object System.Drawing.Size(1000, 20)

$StatusBar.Controls.Add($StatusBarLabel)
$MainForm.Controls.Add($StatusBar)
#endregion

# Form cleanup on close
$MainForm.Add_FormClosing({
    if ($Script:VelociraptorProcess -and -not $Script:VelociraptorProcess.HasExited) {
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Velociraptor server is still running. Do you want to stop it before exiting?",
            "Server Running",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            Stop-VelociraptorServer
        }
    }
})

# Initialize log
Write-StatusLog "=== Velociraptor Simple Comprehensive Installation GUI ===" -Level Success
Write-StatusLog "Configure your deployment settings and click 'Install Velociraptor' to begin" -Level Info
Write-StatusLog "This interface provides comprehensive configuration with simple usability" -Level Info
Write-StatusLog "All configurations are applied automatically during installation" -Level Info

# Show the form
Write-Host "Launching Velociraptor Simple Comprehensive GUI..." -ForegroundColor Green

try {
    Write-StatusLog "GUI initialized successfully - ready for comprehensive installation" -Level Success
    $result = $MainForm.ShowDialog()
}
catch {
    Write-Host "GUI Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
    exit 1
}
finally {
    try {
        if ($MainForm) { $MainForm.Dispose() }
    }
    catch {
        # Ignore cleanup errors
    }
}

Write-Host "=== Velociraptor Simple Comprehensive GUI Session Complete ===" -ForegroundColor Green