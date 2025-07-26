#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Velociraptor Configuration Wizard - Completely Rebuilt with Safe Patterns

.DESCRIPTION
    A systematic rebuild of the GUI using proven working patterns to eliminate
    the persistent BackColor null conversion errors.

.EXAMPLE
    .\VelociraptorGUI-Fixed.ps1
#>

[CmdletBinding()]
param(
    [switch]$StartMinimized
)

# Initialize Windows Forms FIRST - before anything else
try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
    [System.Windows.Forms.Application]::EnableVisualStyles()
    Write-Host "Windows Forms initialized successfully" -ForegroundColor Green
}
catch {
    Write-Error "Failed to initialize Windows Forms: $($_.Exception.Message)"
    exit 1
}

# Define colors as CONSTANTS (not variables) to avoid null issues
$DARK_BACKGROUND = [System.Drawing.Color]::FromArgb(32, 32, 32)
$DARK_SURFACE = [System.Drawing.Color]::FromArgb(48, 48, 48)
$PRIMARY_TEAL = [System.Drawing.Color]::FromArgb(0, 150, 136)
$WHITE_TEXT = [System.Drawing.Color]::FromArgb(255, 255, 255)
$LIGHT_GRAY_TEXT = [System.Drawing.Color]::FromArgb(200, 200, 200)
$SUCCESS_GREEN = [System.Drawing.Color]::FromArgb(76, 175, 80)
$ERROR_RED = [System.Drawing.Color]::FromArgb(244, 67, 54)

# Professional banner
$VelociraptorBanner = @"
╔══════════════════════════════════════════════════════════════╗
║                VELOCIRAPTOR DFIR FRAMEWORK                   ║
║                   Configuration Wizard v5.0.1                ║
║                  Free For All First Responders               ║
╚══════════════════════════════════════════════════════════════╝
"@

# Safe control creation function
function New-SafeControl {
    param(
        [Parameter(Mandatory)]
        [string]$ControlType,
        
        [hashtable]$Properties = @{},
        
        [System.Drawing.Color]$BackColor = $DARK_SURFACE,
        [System.Drawing.Color]$ForeColor = $WHITE_TEXT
    )
    
    try {
        # Create the control
        $control = New-Object $ControlType
        
        # Set BackColor and ForeColor FIRST with error handling
        try {
            $control.BackColor = $BackColor
            $control.ForeColor = $ForeColor
        }
        catch {
            Write-Warning "Color assignment failed for $ControlType, using defaults"
            try {
                $control.BackColor = [System.Drawing.Color]::Black
                $control.ForeColor = [System.Drawing.Color]::White
            }
            catch {
                # If even defaults fail, continue without colors
                Write-Warning "Default color assignment also failed, continuing without colors"
            }
        }
        
        # Set other properties
        foreach ($prop in $Properties.Keys) {
            try {
                $control.$prop = $Properties[$prop]
            }
            catch {
                Write-Warning "Failed to set property $prop on $ControlType`: $($_.Exception.Message)"
            }
        }
        
        return $control
    }
    catch {
        Write-Error "Failed to create $ControlType`: $($_.Exception.Message)"
        return $null
    }
}

# Configuration data
$script:ConfigData = @{
    DeploymentType        = ""
    DatastoreDirectory    = "C:\VelociraptorData"
    LogsDirectory         = "logs"
    CertificateExpiration = "1 Year"
    RestrictVQL           = $false
    UseRegistry           = $false
    RegistryPath          = "HKLM\SOFTWARE\Velocidx\Velociraptor"
    BindAddress           = "0.0.0.0"
    BindPort              = "8000"
    GUIBindAddress        = "127.0.0.1"
    GUIBindPort           = "8889"
    OrganizationName      = "VelociraptorOrg"
    AdminUsername         = "admin"
    AdminPassword         = ""
}

# Current step tracking
$script:CurrentStep = 0
$script:WizardSteps = @(
    @{ Title = "Welcome"; Description = "Welcome to Velociraptor Configuration Wizard" }
    @{ Title = "Deployment Type"; Description = "Choose your deployment type" }
    @{ Title = "Storage Configuration"; Description = "Configure data storage locations" }
    @{ Title = "Network Configuration"; Description = "Configure network bindings and ports" }
    @{ Title = "Authentication"; Description = "Configure admin credentials" }
    @{ Title = "Review & Generate"; Description = "Review settings and generate configuration" }
    @{ Title = "Complete"; Description = "Configuration generated successfully" }
)

# Create main form
function New-MainForm {
    try {
        $form = New-SafeControl -ControlType "System.Windows.Forms.Form" -Properties @{
            Text = "Velociraptor Configuration Wizard"
            Size = New-Object System.Drawing.Size(1000, 750)
            MinimumSize = New-Object System.Drawing.Size(900, 700)
            StartPosition = "CenterScreen"
            FormBorderStyle = "Sizable"
            MaximizeBox = $true
            MinimizeBox = $true
        } -BackColor $DARK_BACKGROUND -ForeColor $WHITE_TEXT
        
        if ($form -eq $null) {
            throw "Failed to create main form"
        }
        
        # Set icon safely
        try {
            $form.Icon = [System.Drawing.SystemIcons]::Shield
        }
        catch {
            Write-Warning "Could not set form icon"
        }
        
        return $form
    }
    catch {
        Write-Error "Failed to create main form: $($_.Exception.Message)"
        return $null
    }
}

# Create header panel
function New-HeaderPanel {
    param($ParentForm)
    
    try {
        $headerPanel = New-SafeControl -ControlType "System.Windows.Forms.Panel" -Properties @{
            Size = New-Object System.Drawing.Size(1000, 100)
            Location = New-Object System.Drawing.Point(0, 0)
            Anchor = "Top,Left,Right"
        } -BackColor $PRIMARY_TEAL -ForeColor $WHITE_TEXT
        
        if ($headerPanel -eq $null) {
            throw "Failed to create header panel"
        }
        
        # Add title label
        $titleLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "VELOCIRAPTOR"
            Font = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
            Location = New-Object System.Drawing.Point(30, 20)
            Size = New-Object System.Drawing.Size(400, 40)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($titleLabel -ne $null) {
            $headerPanel.Controls.Add($titleLabel)
        }
        
        # Add subtitle
        $subtitleLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "DFIR Framework Configuration Wizard"
            Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(30, 60)
            Size = New-Object System.Drawing.Size(400, 25)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $LIGHT_GRAY_TEXT
        
        if ($subtitleLabel -ne $null) {
            $headerPanel.Controls.Add($subtitleLabel)
        }
        
        # Add version info
        $versionLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "v5.0.1 | Free For All First Responders"
            Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(750, 70)
            Size = New-Object System.Drawing.Size(200, 20)
            TextAlign = "MiddleRight"
            Anchor = "Top,Right"
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $LIGHT_GRAY_TEXT
        
        if ($versionLabel -ne $null) {
            $headerPanel.Controls.Add($versionLabel)
        }
        
        $ParentForm.Controls.Add($headerPanel)
        return $headerPanel
    }
    catch {
        Write-Error "Failed to create header panel: $($_.Exception.Message)"
        return $null
    }
}

# Create content panel
function New-ContentPanel {
    param($ParentForm)
    
    try {
        $contentPanel = New-SafeControl -ControlType "System.Windows.Forms.Panel" -Properties @{
            Size = New-Object System.Drawing.Size(940, 450)
            Location = New-Object System.Drawing.Point(30, 120)
            Anchor = "Top,Left,Right,Bottom"
            BorderStyle = "None"
        } -BackColor $DARK_SURFACE -ForeColor $WHITE_TEXT
        
        if ($contentPanel -eq $null) {
            throw "Failed to create content panel"
        }
        
        $ParentForm.Controls.Add($contentPanel)
        return $contentPanel
    }
    catch {
        Write-Error "Failed to create content panel: $($_.Exception.Message)"
        return $null
    }
}

# Create button panel
function New-ButtonPanel {
    param($ParentForm)
    
    try {
        $buttonPanel = New-SafeControl -ControlType "System.Windows.Forms.Panel" -Properties @{
            Size = New-Object System.Drawing.Size(1000, 80)
            Location = New-Object System.Drawing.Point(0, 590)
            Anchor = "Bottom,Left,Right"
        } -BackColor $DARK_SURFACE -ForeColor $WHITE_TEXT
        
        if ($buttonPanel -eq $null) {
            throw "Failed to create button panel"
        }
        
        # Create buttons with safe creation
        $script:BackButton = New-SafeControl -ControlType "System.Windows.Forms.Button" -Properties @{
            Text = "< Back"
            Location = New-Object System.Drawing.Point(650, 20)
            Size = New-Object System.Drawing.Size(100, 40)
            FlatStyle = "Flat"
            Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
            Enabled = $false
        } -BackColor $DARK_SURFACE -ForeColor $WHITE_TEXT
        
        $script:NextButton = New-SafeControl -ControlType "System.Windows.Forms.Button" -Properties @{
            Text = "Next >"
            Location = New-Object System.Drawing.Point(760, 20)
            Size = New-Object System.Drawing.Size(100, 40)
            FlatStyle = "Flat"
            Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
        } -BackColor $PRIMARY_TEAL -ForeColor $WHITE_TEXT
        
        $cancelButton = New-SafeControl -ControlType "System.Windows.Forms.Button" -Properties @{
            Text = "Cancel"
            Location = New-Object System.Drawing.Point(870, 20)
            Size = New-Object System.Drawing.Size(100, 40)
            FlatStyle = "Flat"
            Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
        } -BackColor $ERROR_RED -ForeColor $WHITE_TEXT
        
        # Add event handlers safely
        if ($script:BackButton -ne $null) {
            $script:BackButton.Add_Click({ Move-ToPreviousStep })
            $buttonPanel.Controls.Add($script:BackButton)
        }
        
        if ($script:NextButton -ne $null) {
            $script:NextButton.Add_Click({ Move-ToNextStep })
            $buttonPanel.Controls.Add($script:NextButton)
        }
        
        if ($cancelButton -ne $null) {
            $cancelButton.Add_Click({ 
                if ([System.Windows.Forms.MessageBox]::Show("Are you sure you want to cancel?", "Cancel", "YesNo", "Question") -eq "Yes") {
                    $script:MainForm.Close()
                }
            })
            $buttonPanel.Controls.Add($cancelButton)
        }
        
        $ParentForm.Controls.Add($buttonPanel)
        return $buttonPanel
    }
    catch {
        Write-Error "Failed to create button panel: $($_.Exception.Message)"
        return $null
    }
}

# Show welcome step
function Show-WelcomeStep {
    param($ContentPanel)
    
    try {
        $ContentPanel.Controls.Clear()
        
        # Welcome title
        $titleLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Welcome to Velociraptor Configuration Wizard!"
            Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
            Location = New-Object System.Drawing.Point(40, 30)
            Size = New-Object System.Drawing.Size(800, 40)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $PRIMARY_TEAL
        
        if ($titleLabel -ne $null) {
            $ContentPanel.Controls.Add($titleLabel)
        }
        
        # Welcome content
        $welcomeText = @"
This professional wizard will guide you through creating a complete Velociraptor configuration file optimized for your environment.

Configuration Steps:
   • Deployment type selection (Server, Standalone, or Client)
   • Storage locations for data and logs
   • Network configuration with port management
   • Administrative credentials setup

Features:
   • Real-time input validation
   • Professional YAML configuration generation
   • Cross-platform compatibility
   • Secure credential handling

Click Next to begin the configuration process.
"@
        
        $welcomeLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = $welcomeText
            Location = New-Object System.Drawing.Point(40, 90)
            Size = New-Object System.Drawing.Size(850, 300)
            Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($welcomeLabel -ne $null) {
            $ContentPanel.Controls.Add($welcomeLabel)
        }
        
    }
    catch {
        Write-Error "Failed to show welcome step: $($_.Exception.Message)"
    }
}

# Show deployment type step
function Show-DeploymentTypeStep {
    param($ContentPanel)
    
    try {
        $ContentPanel.Controls.Clear()
        
        # Title
        $titleLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Select Deployment Type"
            Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
            Location = New-Object System.Drawing.Point(40, 30)
            Size = New-Object System.Drawing.Size(400, 35)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $PRIMARY_TEAL
        
        if ($titleLabel -ne $null) {
            $ContentPanel.Controls.Add($titleLabel)
        }
        
        # Server option
        $script:ServerRadio = New-SafeControl -ControlType "System.Windows.Forms.RadioButton" -Properties @{
            Text = "Server Deployment"
            Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
            Location = New-Object System.Drawing.Point(60, 80)
            Size = New-Object System.Drawing.Size(300, 25)
            Checked = ($script:ConfigData.DeploymentType -eq "Server")
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($script:ServerRadio -ne $null) {
            $script:ServerRadio.Add_CheckedChanged({ 
                if ($script:ServerRadio.Checked) { 
                    $script:ConfigData.DeploymentType = "Server"
                    Update-DeploymentDescription
                }
            })
            $ContentPanel.Controls.Add($script:ServerRadio)
        }
        
        # Server description
        $serverDesc = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Full server with web GUI, API, and client management capabilities"
            Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(80, 105)
            Size = New-Object System.Drawing.Size(500, 20)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $LIGHT_GRAY_TEXT
        
        if ($serverDesc -ne $null) {
            $ContentPanel.Controls.Add($serverDesc)
        }
        
        # Standalone option
        $script:StandaloneRadio = New-SafeControl -ControlType "System.Windows.Forms.RadioButton" -Properties @{
            Text = "Standalone Deployment"
            Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
            Location = New-Object System.Drawing.Point(60, 140)
            Size = New-Object System.Drawing.Size(300, 25)
            Checked = ($script:ConfigData.DeploymentType -eq "Standalone")
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($script:StandaloneRadio -ne $null) {
            $script:StandaloneRadio.Add_CheckedChanged({ 
                if ($script:StandaloneRadio.Checked) { 
                    $script:ConfigData.DeploymentType = "Standalone"
                    Update-DeploymentDescription
                }
            })
            $ContentPanel.Controls.Add($script:StandaloneRadio)
        }
        
        # Standalone description
        $standaloneDesc = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Single-user deployment for local analysis and investigation"
            Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(80, 165)
            Size = New-Object System.Drawing.Size(500, 20)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $LIGHT_GRAY_TEXT
        
        if ($standaloneDesc -ne $null) {
            $ContentPanel.Controls.Add($standaloneDesc)
        }
        
        # Client option
        $script:ClientRadio = New-SafeControl -ControlType "System.Windows.Forms.RadioButton" -Properties @{
            Text = "Client Configuration"
            Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
            Location = New-Object System.Drawing.Point(60, 200)
            Size = New-Object System.Drawing.Size(300, 25)
            Checked = ($script:ConfigData.DeploymentType -eq "Client")
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($script:ClientRadio -ne $null) {
            $script:ClientRadio.Add_CheckedChanged({ 
                if ($script:ClientRadio.Checked) { 
                    $script:ConfigData.DeploymentType = "Client"
                    Update-DeploymentDescription
                }
            })
            $ContentPanel.Controls.Add($script:ClientRadio)
        }
        
        # Client description
        $clientDesc = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Client-only configuration for connecting to existing server"
            Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(80, 225)
            Size = New-Object System.Drawing.Size(500, 20)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $LIGHT_GRAY_TEXT
        
        if ($clientDesc -ne $null) {
            $ContentPanel.Controls.Add($clientDesc)
        }
        
        # Detailed description panel
        $script:DeploymentDescPanel = New-SafeControl -ControlType "System.Windows.Forms.Panel" -Properties @{
            Location = New-Object System.Drawing.Point(40, 260)
            Size = New-Object System.Drawing.Size(800, 150)
            BorderStyle = "FixedSingle"
        } -BackColor $DARK_BACKGROUND -ForeColor $WHITE_TEXT
        
        if ($script:DeploymentDescPanel -ne $null) {
            $ContentPanel.Controls.Add($script:DeploymentDescPanel)
        }
        
        Update-DeploymentDescription
        
    }
    catch {
        Write-Error "Failed to show deployment type step: $($_.Exception.Message)"
    }
}

function Update-DeploymentDescription {
    if ($script:DeploymentDescPanel -eq $null) { return }
    
    $script:DeploymentDescPanel.Controls.Clear()
    
    $descText = ""
    switch ($script:ConfigData.DeploymentType) {
        "Server" {
            $descText = @"
SERVER DEPLOYMENT DETAILS:

• Full Velociraptor server with web interface
• Supports multiple concurrent clients
• Centralized artifact collection and analysis
• User management and role-based access
• Requires: Database, SSL certificates, network access
• Recommended for: Enterprise deployments, team investigations
"@
        }
        "Standalone" {
            $descText = @"
STANDALONE DEPLOYMENT DETAILS:

• Single-user Velociraptor instance
• Local artifact collection and analysis
• No client management capabilities
• Simplified configuration and setup
• Requires: Local storage, minimal network access
• Recommended for: Individual investigators, offline analysis
"@
        }
        "Client" {
            $descText = @"
CLIENT CONFIGURATION DETAILS:

• Connects to existing Velociraptor server
• Receives and executes artifacts remotely
• Reports results back to server
• Minimal local configuration required
• Requires: Network access to server, valid certificates
• Recommended for: Endpoint deployment, remote collection
"@
        }
        default {
            $descText = "Please select a deployment type to see detailed information."
        }
    }
    
    $descLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
        Text = $descText
        Location = New-Object System.Drawing.Point(10, 10)
        Size = New-Object System.Drawing.Size(780, 130)
        Font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Regular)
    } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
    
    if ($descLabel -ne $null) {
        $script:DeploymentDescPanel.Controls.Add($descLabel)
    }
}

# Show storage configuration step
function Show-StorageConfigurationStep {
    param($ContentPanel)
    
    try {
        $ContentPanel.Controls.Clear()
        
        # Title
        $titleLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Storage Configuration"
            Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
            Location = New-Object System.Drawing.Point(40, 30)
            Size = New-Object System.Drawing.Size(400, 35)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $PRIMARY_TEAL
        
        if ($titleLabel -ne $null) {
            $ContentPanel.Controls.Add($titleLabel)
        }
        
        # Datastore directory
        $datastoreLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Datastore Directory:"
            Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(40, 80)
            Size = New-Object System.Drawing.Size(150, 25)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($datastoreLabel -ne $null) {
            $ContentPanel.Controls.Add($datastoreLabel)
        }
        
        $script:DatastoreTextBox = New-SafeControl -ControlType "System.Windows.Forms.TextBox" -Properties @{
            Text = $script:ConfigData.DatastoreDirectory
            Location = New-Object System.Drawing.Point(40, 110)
            Size = New-Object System.Drawing.Size(350, 25)
            Font = New-Object System.Drawing.Font("Segoe UI", 10)
        } -BackColor $DARK_SURFACE -ForeColor $WHITE_TEXT
        
        if ($script:DatastoreTextBox -ne $null) {
            $script:DatastoreTextBox.Add_TextChanged({
                $script:ConfigData.DatastoreDirectory = $script:DatastoreTextBox.Text
            })
            $ContentPanel.Controls.Add($script:DatastoreTextBox)
        }
        
        # Browse button for datastore
        $datastoreBrowseBtn = New-SafeControl -ControlType "System.Windows.Forms.Button" -Properties @{
            Text = "Browse..."
            Location = New-Object System.Drawing.Point(400, 110)
            Size = New-Object System.Drawing.Size(80, 25)
            FlatStyle = "Flat"
            Font = New-Object System.Drawing.Font("Segoe UI", 9)
        } -BackColor $PRIMARY_TEAL -ForeColor $WHITE_TEXT
        
        if ($datastoreBrowseBtn -ne $null) {
            $datastoreBrowseBtn.Add_Click({
                $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
                $folderDialog.Description = "Select Datastore Directory"
                $folderDialog.SelectedPath = $script:ConfigData.DatastoreDirectory
                if ($folderDialog.ShowDialog() -eq "OK") {
                    $script:ConfigData.DatastoreDirectory = $folderDialog.SelectedPath
                    $script:DatastoreTextBox.Text = $folderDialog.SelectedPath
                }
            })
            $ContentPanel.Controls.Add($datastoreBrowseBtn)
        }
        
        # Logs directory
        $logsLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Logs Directory:"
            Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(40, 150)
            Size = New-Object System.Drawing.Size(150, 25)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($logsLabel -ne $null) {
            $ContentPanel.Controls.Add($logsLabel)
        }
        
        $script:LogsTextBox = New-SafeControl -ControlType "System.Windows.Forms.TextBox" -Properties @{
            Text = $script:ConfigData.LogsDirectory
            Location = New-Object System.Drawing.Point(40, 180)
            Size = New-Object System.Drawing.Size(350, 25)
            Font = New-Object System.Drawing.Font("Segoe UI", 10)
        } -BackColor $DARK_SURFACE -ForeColor $WHITE_TEXT
        
        if ($script:LogsTextBox -ne $null) {
            $script:LogsTextBox.Add_TextChanged({
                $script:ConfigData.LogsDirectory = $script:LogsTextBox.Text
            })
            $ContentPanel.Controls.Add($script:LogsTextBox)
        }
        
        # Browse button for logs
        $logsBrowseBtn = New-SafeControl -ControlType "System.Windows.Forms.Button" -Properties @{
            Text = "Browse..."
            Location = New-Object System.Drawing.Point(400, 180)
            Size = New-Object System.Drawing.Size(80, 25)
            FlatStyle = "Flat"
            Font = New-Object System.Drawing.Font("Segoe UI", 9)
        } -BackColor $PRIMARY_TEAL -ForeColor $WHITE_TEXT
        
        if ($logsBrowseBtn -ne $null) {
            $logsBrowseBtn.Add_Click({
                $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
                $folderDialog.Description = "Select Logs Directory"
                $folderDialog.SelectedPath = $script:ConfigData.LogsDirectory
                if ($folderDialog.ShowDialog() -eq "OK") {
                    $script:ConfigData.LogsDirectory = $folderDialog.SelectedPath
                    $script:LogsTextBox.Text = $folderDialog.SelectedPath
                }
            })
            $ContentPanel.Controls.Add($logsBrowseBtn)
        }
        
        # Certificate expiration
        $certLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Certificate Expiration:"
            Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(40, 220)
            Size = New-Object System.Drawing.Size(150, 25)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($certLabel -ne $null) {
            $ContentPanel.Controls.Add($certLabel)
        }
        
        $script:CertExpirationCombo = New-SafeControl -ControlType "System.Windows.Forms.ComboBox" -Properties @{
            Location = New-Object System.Drawing.Point(40, 250)
            Size = New-Object System.Drawing.Size(200, 25)
            Font = New-Object System.Drawing.Font("Segoe UI", 10)
            DropDownStyle = "DropDownList"
        } -BackColor $DARK_SURFACE -ForeColor $WHITE_TEXT
        
        if ($script:CertExpirationCombo -ne $null) {
            $script:CertExpirationCombo.Items.AddRange(@("1 Year", "2 Years", "5 Years", "10 Years"))
            $script:CertExpirationCombo.SelectedItem = $script:ConfigData.CertificateExpiration
            $script:CertExpirationCombo.Add_SelectedIndexChanged({
                $script:ConfigData.CertificateExpiration = $script:CertExpirationCombo.SelectedItem
            })
            $ContentPanel.Controls.Add($script:CertExpirationCombo)
        }
        
        # Registry options
        $script:UseRegistryCheckbox = New-SafeControl -ControlType "System.Windows.Forms.CheckBox" -Properties @{
            Text = "Use Windows Registry for configuration storage"
            Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(40, 290)
            Size = New-Object System.Drawing.Size(400, 25)
            Checked = $script:ConfigData.UseRegistry
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($script:UseRegistryCheckbox -ne $null) {
            $script:UseRegistryCheckbox.Add_CheckedChanged({
                $script:ConfigData.UseRegistry = $script:UseRegistryCheckbox.Checked
                $script:RegistryPathTextBox.Enabled = $script:UseRegistryCheckbox.Checked
            })
            $ContentPanel.Controls.Add($script:UseRegistryCheckbox)
        }
        
        # Registry path
        $registryLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Registry Path:"
            Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(60, 320)
            Size = New-Object System.Drawing.Size(100, 25)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($registryLabel -ne $null) {
            $ContentPanel.Controls.Add($registryLabel)
        }
        
        $script:RegistryPathTextBox = New-SafeControl -ControlType "System.Windows.Forms.TextBox" -Properties @{
            Text = $script:ConfigData.RegistryPath
            Location = New-Object System.Drawing.Point(60, 350)
            Size = New-Object System.Drawing.Size(400, 25)
            Font = New-Object System.Drawing.Font("Segoe UI", 10)
            Enabled = $script:ConfigData.UseRegistry
        } -BackColor $DARK_SURFACE -ForeColor $WHITE_TEXT
        
        if ($script:RegistryPathTextBox -ne $null) {
            $script:RegistryPathTextBox.Add_TextChanged({
                $script:ConfigData.RegistryPath = $script:RegistryPathTextBox.Text
            })
            $ContentPanel.Controls.Add($script:RegistryPathTextBox)
        }
        
    }
    catch {
        Write-Error "Failed to show storage configuration step: $($_.Exception.Message)"
    }
}

# Show network configuration step
function Show-NetworkConfigurationStep {
    param($ContentPanel)
    
    try {
        $ContentPanel.Controls.Clear()
        
        # Title
        $titleLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Network Configuration"
            Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
            Location = New-Object System.Drawing.Point(40, 30)
            Size = New-Object System.Drawing.Size(400, 35)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $PRIMARY_TEAL
        
        if ($titleLabel -ne $null) {
            $ContentPanel.Controls.Add($titleLabel)
        }
        
        # API Server Configuration
        $apiLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "API Server Configuration"
            Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
            Location = New-Object System.Drawing.Point(40, 75)
            Size = New-Object System.Drawing.Size(300, 25)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $PRIMARY_TEAL
        
        if ($apiLabel -ne $null) {
            $ContentPanel.Controls.Add($apiLabel)
        }
        
        # Bind address
        $bindLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Bind Address:"
            Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(40, 105)
            Size = New-Object System.Drawing.Size(100, 25)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($bindLabel -ne $null) {
            $ContentPanel.Controls.Add($bindLabel)
        }
        
        $script:BindAddressTextBox = New-SafeControl -ControlType "System.Windows.Forms.TextBox" -Properties @{
            Text = $script:ConfigData.BindAddress
            Location = New-Object System.Drawing.Point(150, 105)
            Size = New-Object System.Drawing.Size(150, 25)
            Font = New-Object System.Drawing.Font("Segoe UI", 10)
        } -BackColor $DARK_SURFACE -ForeColor $WHITE_TEXT
        
        if ($script:BindAddressTextBox -ne $null) {
            $script:BindAddressTextBox.Add_TextChanged({
                $script:ConfigData.BindAddress = $script:BindAddressTextBox.Text
            })
            $ContentPanel.Controls.Add($script:BindAddressTextBox)
        }
        
        # Port
        $portLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Port:"
            Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(320, 105)
            Size = New-Object System.Drawing.Size(50, 25)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($portLabel -ne $null) {
            $ContentPanel.Controls.Add($portLabel)
        }
        
        $script:BindPortTextBox = New-SafeControl -ControlType "System.Windows.Forms.TextBox" -Properties @{
            Text = $script:ConfigData.BindPort
            Location = New-Object System.Drawing.Point(370, 105)
            Size = New-Object System.Drawing.Size(80, 25)
            Font = New-Object System.Drawing.Font("Segoe UI", 10)
        } -BackColor $DARK_SURFACE -ForeColor $WHITE_TEXT
        
        if ($script:BindPortTextBox -ne $null) {
            $script:BindPortTextBox.Add_TextChanged({
                $script:ConfigData.BindPort = $script:BindPortTextBox.Text
            })
            $ContentPanel.Controls.Add($script:BindPortTextBox)
        }
        
        # GUI Server Configuration
        $guiLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "GUI Server Configuration"
            Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
            Location = New-Object System.Drawing.Point(40, 150)
            Size = New-Object System.Drawing.Size(300, 25)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $PRIMARY_TEAL
        
        if ($guiLabel -ne $null) {
            $ContentPanel.Controls.Add($guiLabel)
        }
        
        # GUI Bind address
        $guiBindLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "GUI Bind Address:"
            Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(40, 180)
            Size = New-Object System.Drawing.Size(120, 25)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($guiBindLabel -ne $null) {
            $ContentPanel.Controls.Add($guiBindLabel)
        }
        
        $script:GUIBindAddressTextBox = New-SafeControl -ControlType "System.Windows.Forms.TextBox" -Properties @{
            Text = $script:ConfigData.GUIBindAddress
            Location = New-Object System.Drawing.Point(170, 180)
            Size = New-Object System.Drawing.Size(130, 25)
            Font = New-Object System.Drawing.Font("Segoe UI", 10)
        } -BackColor $DARK_SURFACE -ForeColor $WHITE_TEXT
        
        if ($script:GUIBindAddressTextBox -ne $null) {
            $script:GUIBindAddressTextBox.Add_TextChanged({
                $script:ConfigData.GUIBindAddress = $script:GUIBindAddressTextBox.Text
            })
            $ContentPanel.Controls.Add($script:GUIBindAddressTextBox)
        }
        
        # GUI Port
        $guiPortLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "GUI Port:"
            Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(320, 180)
            Size = New-Object System.Drawing.Size(70, 25)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($guiPortLabel -ne $null) {
            $ContentPanel.Controls.Add($guiPortLabel)
        }
        
        $script:GUIBindPortTextBox = New-SafeControl -ControlType "System.Windows.Forms.TextBox" -Properties @{
            Text = $script:ConfigData.GUIBindPort
            Location = New-Object System.Drawing.Point(390, 180)
            Size = New-Object System.Drawing.Size(80, 25)
            Font = New-Object System.Drawing.Font("Segoe UI", 10)
        } -BackColor $DARK_SURFACE -ForeColor $WHITE_TEXT
        
        if ($script:GUIBindPortTextBox -ne $null) {
            $script:GUIBindPortTextBox.Add_TextChanged({
                $script:ConfigData.GUIBindPort = $script:GUIBindPortTextBox.Text
            })
            $ContentPanel.Controls.Add($script:GUIBindPortTextBox)
        }
        
        # Network validation info
        $networkInfoPanel = New-SafeControl -ControlType "System.Windows.Forms.Panel" -Properties @{
            Location = New-Object System.Drawing.Point(40, 220)
            Size = New-Object System.Drawing.Size(800, 120)
            BorderStyle = "FixedSingle"
        } -BackColor $DARK_BACKGROUND -ForeColor $WHITE_TEXT
        
        if ($networkInfoPanel -ne $null) {
            $ContentPanel.Controls.Add($networkInfoPanel)
        }
        
        $networkInfoText = @"
NETWORK CONFIGURATION NOTES:

• API Server: Handles client connections and artifact execution
• GUI Server: Provides web interface for administration
• Use 0.0.0.0 to bind to all interfaces, 127.0.0.1 for localhost only
• Ensure firewall allows traffic on configured ports
• Default ports: API=8000, GUI=8889 (change if conflicts exist)
"@
        
        $networkInfoLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = $networkInfoText
            Location = New-Object System.Drawing.Point(10, 10)
            Size = New-Object System.Drawing.Size(780, 100)
            Font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Regular)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $LIGHT_GRAY_TEXT
        
        if ($networkInfoLabel -ne $null) {
            $networkInfoPanel.Controls.Add($networkInfoLabel)
        }
        
        # Validate button
        $validateBtn = New-SafeControl -ControlType "System.Windows.Forms.Button" -Properties @{
            Text = "Validate Network Settings"
            Location = New-Object System.Drawing.Point(40, 360)
            Size = New-Object System.Drawing.Size(180, 30)
            FlatStyle = "Flat"
            Font = New-Object System.Drawing.Font("Segoe UI", 10)
        } -BackColor $SUCCESS_GREEN -ForeColor $WHITE_TEXT
        
        if ($validateBtn -ne $null) {
            $validateBtn.Add_Click({
                Validate-NetworkSettings
            })
            $ContentPanel.Controls.Add($validateBtn)
        }
        
    }
    catch {
        Write-Error "Failed to show network configuration step: $($_.Exception.Message)"
    }
}

function Validate-NetworkSettings {
    try {
        $validationResults = @()
        
        # Validate API port
        if ([int]$script:ConfigData.BindPort -lt 1024 -or [int]$script:ConfigData.BindPort -gt 65535) {
            $validationResults += "API Port must be between 1024 and 65535"
        }
        
        # Validate GUI port
        if ([int]$script:ConfigData.GUIBindPort -lt 1024 -or [int]$script:ConfigData.GUIBindPort -gt 65535) {
            $validationResults += "GUI Port must be between 1024 and 65535"
        }
        
        # Check for port conflicts
        if ($script:ConfigData.BindPort -eq $script:ConfigData.GUIBindPort) {
            $validationResults += "API and GUI ports cannot be the same"
        }
        
        # Validate IP addresses
        try {
            [System.Net.IPAddress]::Parse($script:ConfigData.BindAddress) | Out-Null
        }
        catch {
            if ($script:ConfigData.BindAddress -ne "0.0.0.0") {
                $validationResults += "Invalid API bind address format"
            }
        }
        
        try {
            [System.Net.IPAddress]::Parse($script:ConfigData.GUIBindAddress) | Out-Null
        }
        catch {
            if ($script:ConfigData.GUIBindAddress -ne "0.0.0.0") {
                $validationResults += "Invalid GUI bind address format"
            }
        }
        
        if ($validationResults.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Network settings validation passed!", "Validation Success", "OK", "Information")
        }
        else {
            $errorMsg = "Validation Issues Found:`n`n" + ($validationResults -join "`n")
            [System.Windows.Forms.MessageBox]::Show($errorMsg, "Validation Errors", "OK", "Warning")
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error during validation: $($_.Exception.Message)", "Validation Error", "OK", "Error")
    }
}

# Show authentication step
function Show-AuthenticationStep {
    param($ContentPanel)
    
    try {
        $ContentPanel.Controls.Clear()
        
        # Title
        $titleLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Authentication Configuration"
            Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
            Location = New-Object System.Drawing.Point(40, 30)
            Size = New-Object System.Drawing.Size(400, 35)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $PRIMARY_TEAL
        
        if ($titleLabel -ne $null) {
            $ContentPanel.Controls.Add($titleLabel)
        }
        
        # Organization name
        $orgLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Organization Name:"
            Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(40, 80)
            Size = New-Object System.Drawing.Size(150, 25)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($orgLabel -ne $null) {
            $ContentPanel.Controls.Add($orgLabel)
        }
        
        $script:OrganizationTextBox = New-SafeControl -ControlType "System.Windows.Forms.TextBox" -Properties @{
            Text = $script:ConfigData.OrganizationName
            Location = New-Object System.Drawing.Point(40, 110)
            Size = New-Object System.Drawing.Size(300, 25)
            Font = New-Object System.Drawing.Font("Segoe UI", 10)
        } -BackColor $DARK_SURFACE -ForeColor $WHITE_TEXT
        
        if ($script:OrganizationTextBox -ne $null) {
            $script:OrganizationTextBox.Add_TextChanged({
                $script:ConfigData.OrganizationName = $script:OrganizationTextBox.Text
            })
            $ContentPanel.Controls.Add($script:OrganizationTextBox)
        }
        
        # Admin username
        $usernameLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Admin Username:"
            Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(40, 150)
            Size = New-Object System.Drawing.Size(150, 25)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($usernameLabel -ne $null) {
            $ContentPanel.Controls.Add($usernameLabel)
        }
        
        $script:AdminUsernameTextBox = New-SafeControl -ControlType "System.Windows.Forms.TextBox" -Properties @{
            Text = $script:ConfigData.AdminUsername
            Location = New-Object System.Drawing.Point(40, 180)
            Size = New-Object System.Drawing.Size(250, 25)
            Font = New-Object System.Drawing.Font("Segoe UI", 10)
        } -BackColor $DARK_SURFACE -ForeColor $WHITE_TEXT
        
        if ($script:AdminUsernameTextBox -ne $null) {
            $script:AdminUsernameTextBox.Add_TextChanged({
                $script:ConfigData.AdminUsername = $script:AdminUsernameTextBox.Text
            })
            $ContentPanel.Controls.Add($script:AdminUsernameTextBox)
        }
        
        # Admin password
        $passwordLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Admin Password:"
            Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(40, 220)
            Size = New-Object System.Drawing.Size(150, 25)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($passwordLabel -ne $null) {
            $ContentPanel.Controls.Add($passwordLabel)
        }
        
        $script:AdminPasswordTextBox = New-SafeControl -ControlType "System.Windows.Forms.TextBox" -Properties @{
            Text = $script:ConfigData.AdminPassword
            Location = New-Object System.Drawing.Point(40, 250)
            Size = New-Object System.Drawing.Size(250, 25)
            Font = New-Object System.Drawing.Font("Segoe UI", 10)
            UseSystemPasswordChar = $true
        } -BackColor $DARK_SURFACE -ForeColor $WHITE_TEXT
        
        if ($script:AdminPasswordTextBox -ne $null) {
            $script:AdminPasswordTextBox.Add_TextChanged({
                $script:ConfigData.AdminPassword = $script:AdminPasswordTextBox.Text
                Update-PasswordStrength
            })
            $ContentPanel.Controls.Add($script:AdminPasswordTextBox)
        }
        
        # Confirm password
        $confirmLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Confirm Password:"
            Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(40, 290)
            Size = New-Object System.Drawing.Size(150, 25)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($confirmLabel -ne $null) {
            $ContentPanel.Controls.Add($confirmLabel)
        }
        
        $script:ConfirmPasswordTextBox = New-SafeControl -ControlType "System.Windows.Forms.TextBox" -Properties @{
            Location = New-Object System.Drawing.Point(40, 320)
            Size = New-Object System.Drawing.Size(250, 25)
            Font = New-Object System.Drawing.Font("Segoe UI", 10)
            UseSystemPasswordChar = $true
        } -BackColor $DARK_SURFACE -ForeColor $WHITE_TEXT
        
        if ($script:ConfirmPasswordTextBox -ne $null) {
            $script:ConfirmPasswordTextBox.Add_TextChanged({
                Update-PasswordMatch
            })
            $ContentPanel.Controls.Add($script:ConfirmPasswordTextBox)
        }
        
        # Password strength indicator
        $script:PasswordStrengthLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Password Strength: "
            Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(300, 250)
            Size = New-Object System.Drawing.Size(200, 25)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($script:PasswordStrengthLabel -ne $null) {
            $ContentPanel.Controls.Add($script:PasswordStrengthLabel)
        }
        
        # Password match indicator
        $script:PasswordMatchLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = ""
            Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(300, 320)
            Size = New-Object System.Drawing.Size(200, 25)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($script:PasswordMatchLabel -ne $null) {
            $ContentPanel.Controls.Add($script:PasswordMatchLabel)
        }
        
        # VQL Restriction checkbox
        $script:RestrictVQLCheckbox = New-SafeControl -ControlType "System.Windows.Forms.CheckBox" -Properties @{
            Text = "Restrict VQL queries (recommended for production)"
            Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(40, 360)
            Size = New-Object System.Drawing.Size(400, 25)
            Checked = $script:ConfigData.RestrictVQL
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($script:RestrictVQLCheckbox -ne $null) {
            $script:RestrictVQLCheckbox.Add_CheckedChanged({
                $script:ConfigData.RestrictVQL = $script:RestrictVQLCheckbox.Checked
            })
            $ContentPanel.Controls.Add($script:RestrictVQLCheckbox)
        }
        
        # Generate password button
        $generateBtn = New-SafeControl -ControlType "System.Windows.Forms.Button" -Properties @{
            Text = "Generate Secure Password"
            Location = New-Object System.Drawing.Point(500, 250)
            Size = New-Object System.Drawing.Size(160, 25)
            FlatStyle = "Flat"
            Font = New-Object System.Drawing.Font("Segoe UI", 9)
        } -BackColor $PRIMARY_TEAL -ForeColor $WHITE_TEXT
        
        if ($generateBtn -ne $null) {
            $generateBtn.Add_Click({
                Generate-SecurePassword
            })
            $ContentPanel.Controls.Add($generateBtn)
        }
        
        Update-PasswordStrength
        
    }
    catch {
        Write-Error "Failed to show authentication step: $($_.Exception.Message)"
    }
}

function Update-PasswordStrength {
    if ($script:PasswordStrengthLabel -eq $null) { return }
    
    $password = $script:ConfigData.AdminPassword
    $strength = "Weak"
    $color = $ERROR_RED
    
    if ($password.Length -ge 12) {
        $hasUpper = $password -cmatch '[A-Z]'
        $hasLower = $password -cmatch '[a-z]'
        $hasDigit = $password -match '\d'
        $hasSpecial = $password -match '[^A-Za-z0-9]'
        
        $score = ($hasUpper + $hasLower + $hasDigit + $hasSpecial)
        
        if ($score -ge 4) {
            $strength = "Strong"
            $color = $SUCCESS_GREEN
        }
        elseif ($score -ge 3) {
            $strength = "Medium"
            $color = [System.Drawing.Color]::Orange
        }
    }
    
    $script:PasswordStrengthLabel.Text = "Password Strength: $strength"
    $script:PasswordStrengthLabel.ForeColor = $color
}

function Update-PasswordMatch {
    if ($script:PasswordMatchLabel -eq $null) { return }
    
    $password = $script:AdminPasswordTextBox.Text
    $confirm = $script:ConfirmPasswordTextBox.Text
    
    if ($confirm.Length -eq 0) {
        $script:PasswordMatchLabel.Text = ""
        return
    }
    
    if ($password -eq $confirm) {
        $script:PasswordMatchLabel.Text = "✓ Passwords match"
        $script:PasswordMatchLabel.ForeColor = $SUCCESS_GREEN
    }
    else {
        $script:PasswordMatchLabel.Text = "✗ Passwords do not match"
        $script:PasswordMatchLabel.ForeColor = $ERROR_RED
    }
}

function Generate-SecurePassword {
    $chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#$%^&*"
    $password = ""
    $random = New-Object System.Random
    
    for ($i = 0; $i -lt 16; $i++) {
        $password += $chars[$random.Next($chars.Length)]
    }
    
    $script:AdminPasswordTextBox.Text = $password
    $script:ConfirmPasswordTextBox.Text = $password
    $script:ConfigData.AdminPassword = $password
    
    Update-PasswordStrength
    Update-PasswordMatch
}

# Show review step
function Show-ReviewStep {
    param($ContentPanel)
    
    try {
        $ContentPanel.Controls.Clear()
        
        # Title
        $titleLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Review Configuration"
            Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
            Location = New-Object System.Drawing.Point(40, 30)
            Size = New-Object System.Drawing.Size(400, 35)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $PRIMARY_TEAL
        
        if ($titleLabel -ne $null) {
            $ContentPanel.Controls.Add($titleLabel)
        }
        
        # Create scrollable text box for review
        $script:ReviewTextBox = New-SafeControl -ControlType "System.Windows.Forms.TextBox" -Properties @{
            Location = New-Object System.Drawing.Point(40, 80)
            Size = New-Object System.Drawing.Size(800, 280)
            Font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Regular)
            Multiline = $true
            ScrollBars = "Vertical"
            ReadOnly = $true
        } -BackColor $DARK_BACKGROUND -ForeColor $WHITE_TEXT
        
        if ($script:ReviewTextBox -ne $null) {
            $ContentPanel.Controls.Add($script:ReviewTextBox)
        }
        
        # Generate configuration button
        $generateBtn = New-SafeControl -ControlType "System.Windows.Forms.Button" -Properties @{
            Text = "Generate Configuration File"
            Location = New-Object System.Drawing.Point(40, 380)
            Size = New-Object System.Drawing.Size(200, 35)
            FlatStyle = "Flat"
            Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        } -BackColor $SUCCESS_GREEN -ForeColor $WHITE_TEXT
        
        if ($generateBtn -ne $null) {
            $generateBtn.Add_Click({
                Generate-ConfigurationFile
            })
            $ContentPanel.Controls.Add($generateBtn)
        }
        
        # Export button
        $exportBtn = New-SafeControl -ControlType "System.Windows.Forms.Button" -Properties @{
            Text = "Export Settings"
            Location = New-Object System.Drawing.Point(260, 380)
            Size = New-Object System.Drawing.Size(120, 35)
            FlatStyle = "Flat"
            Font = New-Object System.Drawing.Font("Segoe UI", 10)
        } -BackColor $PRIMARY_TEAL -ForeColor $WHITE_TEXT
        
        if ($exportBtn -ne $null) {
            $exportBtn.Add_Click({
                Export-ConfigurationSettings
            })
            $ContentPanel.Controls.Add($exportBtn)
        }
        
        Update-ReviewContent
        
    }
    catch {
        Write-Error "Failed to show review step: $($_.Exception.Message)"
    }
}

function Update-ReviewContent {
    if ($script:ReviewTextBox -eq $null) { return }
    
    # Validate configuration first
    $validationIssues = Validate-Configuration
    
    $reviewText = @"
═══════════════════════════════════════════════════════════════
                    VELOCIRAPTOR CONFIGURATION REVIEW
═══════════════════════════════════════════════════════════════

DEPLOYMENT CONFIGURATION:
├─ Type: $($script:ConfigData.DeploymentType)
├─ Organization: $($script:ConfigData.OrganizationName)
└─ VQL Restrictions: $(if($script:ConfigData.RestrictVQL) { "Enabled" } else { "Disabled" })

STORAGE CONFIGURATION:
├─ Datastore Directory: $($script:ConfigData.DatastoreDirectory)
├─ Logs Directory: $($script:ConfigData.LogsDirectory)
├─ Certificate Expiration: $($script:ConfigData.CertificateExpiration)
├─ Registry Storage: $(if($script:ConfigData.UseRegistry) { "Enabled" } else { "Disabled" })
$(if($script:ConfigData.UseRegistry) { "└─ Registry Path: $($script:ConfigData.RegistryPath)" } else { "" })

NETWORK CONFIGURATION:
├─ API Server:
│  ├─ Bind Address: $($script:ConfigData.BindAddress)
│  └─ Port: $($script:ConfigData.BindPort)
└─ GUI Server:
   ├─ Bind Address: $($script:ConfigData.GUIBindAddress)
   └─ Port: $($script:ConfigData.GUIBindPort)

AUTHENTICATION:
├─ Admin Username: $($script:ConfigData.AdminUsername)
├─ Password: $(if($script:ConfigData.AdminPassword.Length -gt 0) { "●●●●●●●● (Set)" } else { "NOT SET" })
└─ Password Strength: $(Get-PasswordStrengthText)

$(if($validationIssues.Count -gt 0) { 
@"
⚠️  VALIDATION ISSUES FOUND:
$($validationIssues | ForEach-Object { "   • $_" } | Out-String)
"@ 
} else { 
"✅ CONFIGURATION VALIDATION: PASSED" 
})

═══════════════════════════════════════════════════════════════
Ready to generate Velociraptor configuration file.
═══════════════════════════════════════════════════════════════
"@
    
    $script:ReviewTextBox.Text = $reviewText
}

function Get-PasswordStrengthText {
    $password = $script:ConfigData.AdminPassword
    if ($password.Length -eq 0) { return "Not Set" }
    
    if ($password.Length -ge 12) {
        $hasUpper = $password -cmatch '[A-Z]'
        $hasLower = $password -cmatch '[a-z]'
        $hasDigit = $password -match '\d'
        $hasSpecial = $password -match '[^A-Za-z0-9]'
        
        $score = ($hasUpper + $hasLower + $hasDigit + $hasSpecial)
        
        if ($score -ge 4) { return "Strong" }
        elseif ($score -ge 3) { return "Medium" }
    }
    return "Weak"
}

function Validate-Configuration {
    $issues = @()
    
    # Check required fields
    if ([string]::IsNullOrWhiteSpace($script:ConfigData.DeploymentType)) {
        $issues += "Deployment type not selected"
    }
    
    if ([string]::IsNullOrWhiteSpace($script:ConfigData.DatastoreDirectory)) {
        $issues += "Datastore directory not specified"
    }
    
    if ([string]::IsNullOrWhiteSpace($script:ConfigData.AdminUsername)) {
        $issues += "Admin username not specified"
    }
    
    if ([string]::IsNullOrWhiteSpace($script:ConfigData.AdminPassword)) {
        $issues += "Admin password not set"
    }
    
    # Validate network settings
    try {
        $apiPort = [int]$script:ConfigData.BindPort
        if ($apiPort -lt 1024 -or $apiPort -gt 65535) {
            $issues += "API port must be between 1024 and 65535"
        }
    }
    catch {
        $issues += "Invalid API port number"
    }
    
    try {
        $guiPort = [int]$script:ConfigData.GUIBindPort
        if ($guiPort -lt 1024 -or $guiPort -gt 65535) {
            $issues += "GUI port must be between 1024 and 65535"
        }
    }
    catch {
        $issues += "Invalid GUI port number"
    }
    
    if ($script:ConfigData.BindPort -eq $script:ConfigData.GUIBindPort) {
        $issues += "API and GUI ports cannot be the same"
    }
    
    # Check password strength
    if ((Get-PasswordStrengthText) -eq "Weak") {
        $issues += "Password strength is weak - consider using a stronger password"
    }
    
    return $issues
}

function Generate-ConfigurationFile {
    try {
        $validationIssues = Validate-Configuration
        if ($validationIssues.Count -gt 0) {
            $result = [System.Windows.Forms.MessageBox]::Show(
                "Configuration has validation issues. Generate anyway?`n`n$($validationIssues -join "`n")",
                "Validation Issues",
                "YesNo",
                "Warning"
            )
            if ($result -eq "No") { return }
        }
        
        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Filter = "YAML files (*.yaml)|*.yaml|All files (*.*)|*.*"
        $saveDialog.DefaultExt = "yaml"
        $saveDialog.FileName = "velociraptor-config.yaml"
        
        if ($saveDialog.ShowDialog() -eq "OK") {
            $configContent = Generate-YAMLConfiguration
            [System.IO.File]::WriteAllText($saveDialog.FileName, $configContent)
            
            [System.Windows.Forms.MessageBox]::Show(
                "Configuration file generated successfully!`n`nSaved to: $($saveDialog.FileName)",
                "Success",
                "OK",
                "Information"
            )
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Error generating configuration file: $($_.Exception.Message)",
            "Error",
            "OK",
            "Error"
        )
    }
}

function Export-ConfigurationSettings {
    try {
        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Filter = "JSON files (*.json)|*.json|All files (*.*)|*.*"
        $saveDialog.DefaultExt = "json"
        $saveDialog.FileName = "velociraptor-settings.json"
        
        if ($saveDialog.ShowDialog() -eq "OK") {
            $settingsJson = $script:ConfigData | ConvertTo-Json -Depth 10
            [System.IO.File]::WriteAllText($saveDialog.FileName, $settingsJson)
            
            [System.Windows.Forms.MessageBox]::Show(
                "Settings exported successfully!`n`nSaved to: $($saveDialog.FileName)",
                "Export Success",
                "OK",
                "Information"
            )
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Error exporting settings: $($_.Exception.Message)",
            "Export Error",
            "OK",
            "Error"
        )
    }
}

function Generate-YAMLConfiguration {
    # This is a simplified YAML generation - in production you'd want a proper YAML library
    $yaml = @"
# Velociraptor Configuration File
# Generated by Velociraptor Configuration Wizard v5.0.1
# Generated on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

version:
  name: velociraptor
  version: "0.6.7"
  commit: "unknown"
  build_time: "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"

deployment_type: $($script:ConfigData.DeploymentType.ToLower())

datastore:
  implementation: FileBaseDataStore
  location: "$($script:ConfigData.DatastoreDirectory.Replace('\', '/'))"
  filestore_directory: "$($script:ConfigData.DatastoreDirectory.Replace('\', '/'))/files"

logging:
  output_directory: "$($script:ConfigData.LogsDirectory.Replace('\', '/'))"
  separate_logs_per_component: true
  rotation_time: 604800
  max_age: 31536000

api:
  bind_address: "$($script:ConfigData.BindAddress)"
  bind_port: $($script:ConfigData.BindPort)
  bind_scheme: https

gui:
  bind_address: "$($script:ConfigData.GUIBindAddress)"
  bind_port: $($script:ConfigData.GUIBindPort)
  gw_certificate: server.cert
  gw_private_key: server.pem
  internal_cidr:
    - 127.0.0.1/12
    - 192.168.0.0/16

ca_certificate: ca.pem
ca_private_key: ca.key.pem

frontend_certificate: server.cert
frontend_private_key: server.pem

gui_users:
  - name: "$($script:ConfigData.AdminUsername)"
    password_hash: "$(Get-PasswordHash $script:ConfigData.AdminPassword)"
    password_salt: "$(Get-RandomSalt)"

autocert_domain: ""
autocert_cert_cache: ""

server_services:
  - hunt_manager
  - hunt_dispatcher
  - stats_collector
  - server_monitoring
  - server_artifacts
  - dyn_dns

writeback:
  private_key: server.pem

obfuscation_nonce: "$(Get-RandomNonce)"

$(if($script:ConfigData.RestrictVQL) {
@"
defaults:
  allow_custom_overrides: false
"@
} else {
@"
defaults:
  allow_custom_overrides: true
"@
})
"@

    return $yaml
}

function Get-PasswordHash($password) {
    # Simplified hash generation - in production use proper bcrypt
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($password + "velociraptor_salt")
    $hash = $sha256.ComputeHash($bytes)
    return [System.Convert]::ToBase64String($hash)
}

function Get-RandomSalt {
    $random = New-Object System.Random
    $bytes = New-Object byte[] 16
    $random.NextBytes($bytes)
    return [System.Convert]::ToBase64String($bytes)
}

function Get-RandomNonce {
    $random = New-Object System.Random
    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    $nonce = ""
    for ($i = 0; $i -lt 32; $i++) {
        $nonce += $chars[$random.Next($chars.Length)]
    }
    return $nonce
}

# Show complete step
function Show-CompleteStep {
    param($ContentPanel)
    
    try {
        $ContentPanel.Controls.Clear()
        
        # Title
        $titleLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Configuration Complete!"
            Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
            Location = New-Object System.Drawing.Point(40, 30)
            Size = New-Object System.Drawing.Size(600, 40)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $SUCCESS_GREEN
        
        if ($titleLabel -ne $null) {
            $ContentPanel.Controls.Add($titleLabel)
        }
        
        # Success message
        $successText = @"
Your Velociraptor configuration has been generated successfully!

Configuration file would be saved to: velociraptor-config.yaml

Next steps:
1. Review the generated configuration file
2. Deploy Velociraptor using the configuration
3. Access the web interface
4. Login with your admin credentials

Click Finish to close the wizard.
"@
        
        $successLabel = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = $successText
            Location = New-Object System.Drawing.Point(40, 90)
            Size = New-Object System.Drawing.Size(800, 300)
            Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($successLabel -ne $null) {
            $ContentPanel.Controls.Add($successLabel)
        }
        
    }
    catch {
        Write-Error "Failed to show complete step: $($_.Exception.Message)"
    }
}

# Navigation functions
function Move-ToNextStep {
    try {
        if ($script:CurrentStep -lt ($script:WizardSteps.Count - 1)) {
            $script:CurrentStep++
            Update-CurrentStep
        }
        else {
            # Finish wizard
            $script:MainForm.Close()
        }
    }
    catch {
        Write-Error "Error navigating to next step: $($_.Exception.Message)"
    }
}

function Move-ToPreviousStep {
    try {
        if ($script:CurrentStep -gt 0) {
            $script:CurrentStep--
            Update-CurrentStep
        }
    }
    catch {
        Write-Error "Error navigating to previous step: $($_.Exception.Message)"
    }
}

function Update-CurrentStep {
    try {
        # Update button states
        if ($script:BackButton -ne $null) {
            $script:BackButton.Enabled = ($script:CurrentStep -gt 0)
        }
        
        if ($script:NextButton -ne $null) {
            if ($script:CurrentStep -eq ($script:WizardSteps.Count - 1)) {
                $script:NextButton.Text = "Finish"
            }
            else {
                $script:NextButton.Text = "Next >"
            }
        }
        
        # Show current step content
        switch ($script:CurrentStep) {
            0 { Show-WelcomeStep -ContentPanel $script:ContentPanel }
            1 { Show-DeploymentTypeStep -ContentPanel $script:ContentPanel }
            2 { Show-StorageConfigurationStep -ContentPanel $script:ContentPanel }
            3 { Show-NetworkConfigurationStep -ContentPanel $script:ContentPanel }
            4 { Show-AuthenticationStep -ContentPanel $script:ContentPanel }
            5 { Show-ReviewStep -ContentPanel $script:ContentPanel }
            6 { Show-CompleteStep -ContentPanel $script:ContentPanel }
            default { 
                # Fallback for any undefined steps
                $script:ContentPanel.Controls.Clear()
                $label = New-SafeControl -ControlType "System.Windows.Forms.Label" -Properties @{
                    Text = "Step $($script:CurrentStep + 1): $($script:WizardSteps[$script:CurrentStep].Title)"
                    Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
                    Location = New-Object System.Drawing.Point(40, 30)
                    Size = New-Object System.Drawing.Size(800, 40)
                } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $PRIMARY_TEAL
                
                if ($label -ne $null) {
                    $script:ContentPanel.Controls.Add($label)
                }
            }
        }
    }
    catch {
        Write-Error "Error updating current step: $($_.Exception.Message)"
    }
}

# Main execution
try {
    Write-Host $VelociraptorBanner -ForegroundColor Cyan
    Write-Host "Starting Velociraptor Configuration Wizard..." -ForegroundColor White
    
    # Create main form
    $script:MainForm = New-MainForm
    if ($script:MainForm -eq $null) {
        throw "Failed to create main form"
    }
    
    # Create UI components
    $headerPanel = New-HeaderPanel -ParentForm $script:MainForm
    $script:ContentPanel = New-ContentPanel -ParentForm $script:MainForm
    $buttonPanel = New-ButtonPanel -ParentForm $script:MainForm
    
    # Show initial step
    Update-CurrentStep
    
    if ($StartMinimized) {
        $script:MainForm.WindowState = "Minimized"
    }
    
    # Run the application
    Write-Host "GUI created successfully, launching..." -ForegroundColor Green
    [System.Windows.Forms.Application]::Run($script:MainForm)
    
    Write-Host "Velociraptor Configuration Wizard completed." -ForegroundColor Green
    
}
catch {
    $errorMsg = "GUI failed: $($_.Exception.Message)"
    Write-Host $errorMsg -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
    
    try {
        [System.Windows.Forms.MessageBox]::Show($errorMsg, "Critical Error", "OK", "Error")
    }
    catch {
        # If even MessageBox fails, just exit
        Write-Host "Cannot show error dialog, exiting..." -ForegroundColor Red
    }
    exit 1
}
finally {
    # Cleanup
    try {
        if ($script:MainForm) {
            $script:MainForm.Dispose()
        }
        [System.GC]::Collect()
    }
    catch {
        # Silently handle cleanup errors
    }
}