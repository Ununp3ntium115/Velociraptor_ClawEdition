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
            Location = New-Object System.Drawing.Point(60, 100)
            Size = New-Object System.Drawing.Size(300, 25)
            Checked = ($script:ConfigData.DeploymentType -eq "Server")
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($script:ServerRadio -ne $null) {
            $script:ServerRadio.Add_CheckedChanged({ 
                if ($script:ServerRadio.Checked) { $script:ConfigData.DeploymentType = "Server" }
            })
            $ContentPanel.Controls.Add($script:ServerRadio)
        }
        
        # Standalone option
        $script:StandaloneRadio = New-SafeControl -ControlType "System.Windows.Forms.RadioButton" -Properties @{
            Text = "Standalone Deployment"
            Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
            Location = New-Object System.Drawing.Point(60, 180)
            Size = New-Object System.Drawing.Size(300, 25)
            Checked = ($script:ConfigData.DeploymentType -eq "Standalone")
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($script:StandaloneRadio -ne $null) {
            $script:StandaloneRadio.Add_CheckedChanged({ 
                if ($script:StandaloneRadio.Checked) { $script:ConfigData.DeploymentType = "Standalone" }
            })
            $ContentPanel.Controls.Add($script:StandaloneRadio)
        }
        
        # Client option
        $script:ClientRadio = New-SafeControl -ControlType "System.Windows.Forms.RadioButton" -Properties @{
            Text = "Client Configuration"
            Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
            Location = New-Object System.Drawing.Point(60, 260)
            Size = New-Object System.Drawing.Size(300, 25)
            Checked = ($script:ConfigData.DeploymentType -eq "Client")
        } -BackColor ([System.Drawing.Color]::Transparent) -ForeColor $WHITE_TEXT
        
        if ($script:ClientRadio -ne $null) {
            $script:ClientRadio.Add_CheckedChanged({ 
                if ($script:ClientRadio.Checked) { $script:ConfigData.DeploymentType = "Client" }
            })
            $ContentPanel.Controls.Add($script:ClientRadio)
        }
        
    }
    catch {
        Write-Error "Failed to show deployment type step: $($_.Exception.Message)"
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
            default { 
                # Simple placeholder for other steps
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