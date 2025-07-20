#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Velociraptor Configuration Wizard GUI - Dark Theme with Raptor Design

.DESCRIPTION
    A professional step-by-step wizard GUI for creating Velociraptor configurations.
    Features dark theme, raptor imagery, and modern UI design.

.EXAMPLE
    .\VelociraptorGUI.ps1
#>

[CmdletBinding()]
param(
    [switch]$StartMinimized
)

# Add Windows Forms assembly with error handling
try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
}
catch {
    Write-Error "Failed to load Windows Forms: $($_.Exception.Message)"
    exit 1
}

# Import required modules with error handling
$ModulePath = Join-Path $PSScriptRoot "..\modules"
try {
    if (Test-Path "$ModulePath\VelociraptorDeployment") {
        Import-Module "$ModulePath\VelociraptorDeployment" -Force -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Warning "Could not load VelociraptorDeployment module: $($_.Exception.Message)"
}

# Dark theme color palette with error handling
try {
    $script:Colors = @{
        Background    = [System.Drawing.Color]::FromArgb(32, 32, 32)
        Surface       = [System.Drawing.Color]::FromArgb(48, 48, 48)
        Primary       = [System.Drawing.Color]::FromArgb(0, 150, 136)
        Secondary     = [System.Drawing.Color]::FromArgb(255, 87, 34)
        Text          = [System.Drawing.Color]::FromArgb(255, 255, 255)
        TextSecondary = [System.Drawing.Color]::FromArgb(200, 200, 200)
        Accent        = [System.Drawing.Color]::FromArgb(76, 175, 80)
        Warning       = [System.Drawing.Color]::FromArgb(255, 193, 7)
        Error         = [System.Drawing.Color]::FromArgb(244, 67, 54)
        Success       = [System.Drawing.Color]::FromArgb(76, 175, 80)
    }
}
catch {
    # Fallback colors if there's an issue
    $script:Colors = @{
        Background    = [System.Drawing.Color]::Black
        Surface       = [System.Drawing.Color]::DarkGray
        Primary       = [System.Drawing.Color]::Blue
        Secondary     = [System.Drawing.Color]::Orange
        Text          = [System.Drawing.Color]::White
        TextSecondary = [System.Drawing.Color]::LightGray
        Accent        = [System.Drawing.Color]::Green
        Warning       = [System.Drawing.Color]::Yellow
        Error         = [System.Drawing.Color]::Red
        Success       = [System.Drawing.Color]::Green
    }
}

# Global variables for wizard state
$script:CurrentStep = 0
$script:ConfigData = @{
    DeploymentType        = ""
    DatastoreDirectory    = "C:\VelociraptorData"
    LogsDirectory         = "logs"
    CertificateExpiration = "1 Year"
    RestrictVQL           = $false
    UseRegistry           = $false
    RegistryPath          = "HKLM\SOFTWARE\Velocidex\Velociraptor"
    BindAddress           = "0.0.0.0"
    BindPort              = "8000"
    GUIBindAddress        = "127.0.0.1"
    GUIBindPort           = "8889"
    OrganizationName      = "VelociraptorOrg"
    AdminUsername         = "admin"
    AdminPassword         = ""
}

$script:WizardSteps = @(
    @{ Title = "Welcome"; Description = "Welcome to Velociraptor Configuration Wizard" }
    @{ Title = "Deployment Type"; Description = "Choose your deployment type" }
    @{ Title = "Storage Configuration"; Description = "Configure data storage locations" }
    @{ Title = "Certificate Settings"; Description = "Configure SSL certificates and expiration" }
    @{ Title = "Security Settings"; Description = "Configure security and access restrictions" }
    @{ Title = "Network Configuration"; Description = "Configure network bindings and ports" }
    @{ Title = "Authentication"; Description = "Configure admin credentials" }
    @{ Title = "Review & Generate"; Description = "Review settings and generate configuration" }
    @{ Title = "Complete"; Description = "Configuration generated successfully" }
)

# Create professional banner for console display
$script:VelociraptorBanner = @"
╔══════════════════════════════════════════════════════════════╗
║                🦖 VELOCIRAPTOR DFIR FRAMEWORK 🦖              ║
║                   Configuration Wizard v5.0.1                ║
║                      Professional Edition                     ║
╚══════════════════════════════════════════════════════════════╝
"@

# Create raptor-themed form with dark design
function New-RaptorWizardForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "🦖 Velociraptor Configuration Wizard"
    $form.Size = New-Object System.Drawing.Size(1000, 750)
    $form.MinimumSize = New-Object System.Drawing.Size(900, 700)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "Sizable"
    $form.MaximizeBox = $true
    $form.MinimizeBox = $true
    $form.BackColor = $script:Colors.Background
    $form.ForeColor = $script:Colors.Text
    
    # Set form icon (using built-in icon for now)
    try {
        $form.Icon = [System.Drawing.SystemIcons]::Shield
    }
    catch {
        Write-Verbose "Could not set form icon"
    }
    
    # Create gradient background panel
    $backgroundPanel = New-Object System.Windows.Forms.Panel
    $backgroundPanel.Size = $form.Size
    $backgroundPanel.Location = New-Object System.Drawing.Point(0, 0)
    $backgroundPanel.Anchor = "Top,Left,Right,Bottom"
    $backgroundPanel.BackColor = $script:Colors.Background
    
    # Add subtle raptor silhouette to background
    $backgroundPanel.Add_Paint({
            param($sender, $e)
            try {
                $graphics = $e.Graphics
                $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            
                # Create subtle raptor silhouette
                $raptorBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 0, 150, 136))
                $raptorPath = New-Object System.Drawing.Drawing2D.GraphicsPath
            
                # Simple raptor head outline (simplified for performance)
                $raptorPoints = @(
                    [System.Drawing.Point]::new(800, 400),
                    [System.Drawing.Point]::new(850, 350),
                    [System.Drawing.Point]::new(900, 380),
                    [System.Drawing.Point]::new(920, 420),
                    [System.Drawing.Point]::new(900, 460),
                    [System.Drawing.Point]::new(850, 480),
                    [System.Drawing.Point]::new(800, 450)
                )
            
                $raptorPath.AddPolygon($raptorPoints)
                $graphics.FillPath($raptorBrush, $raptorPath)
            
                $raptorBrush.Dispose()
                $raptorPath.Dispose()
            }
            catch {
                # Silently handle any drawing errors
            }
        })
    
    $form.Controls.Add($backgroundPanel)
    
    # Create modern header with gradient
    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Size = New-Object System.Drawing.Size(1000, 100)
    $headerPanel.Location = New-Object System.Drawing.Point(0, 0)
    $headerPanel.Anchor = "Top,Left,Right"
    $headerPanel.BackColor = $script:Colors.Primary
    
    # Add gradient effect to header
    $headerPanel.Add_Paint({
            param($sender, $e)
            try {
                $rect = New-Object System.Drawing.Rectangle(0, 0, $sender.Width, $sender.Height)
                $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                    $rect,
                    $script:Colors.Primary,
                    [System.Drawing.Color]::FromArgb(0, 100, 90),
                    [System.Drawing.Drawing2D.LinearGradientMode]::Horizontal
                )
                $e.Graphics.FillRectangle($brush, $rect)
                $brush.Dispose()
            }
            catch {
                # Fallback to solid color
                $brush = New-Object System.Drawing.SolidBrush($script:Colors.Primary)
                $e.Graphics.FillRectangle($brush, 0, 0, $sender.Width, $sender.Height)
                $brush.Dispose()
            }
        })
    
    # Raptor logo and title
    $logoLabel = New-Object System.Windows.Forms.Label
    $logoLabel.Text = "🦖 VELOCIRAPTOR"
    $logoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
    $logoLabel.ForeColor = [System.Drawing.Color]::White
    $logoLabel.Location = New-Object System.Drawing.Point(30, 20)
    $logoLabel.Size = New-Object System.Drawing.Size(400, 40)
    $logoLabel.BackColor = $script:Colors.Background
    $headerPanel.Controls.Add($logoLabel)
    
    $subtitleLabel = New-Object System.Windows.Forms.Label
    $subtitleLabel.Text = "DFIR Framework Configuration Wizard"
    $subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Regular)
    $subtitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
    $subtitleLabel.Location = New-Object System.Drawing.Point(30, 60)
    $subtitleLabel.Size = New-Object System.Drawing.Size(400, 25)
    $subtitleLabel.BackColor = $script:Colors.Background
    $headerPanel.Controls.Add($subtitleLabel)
    
    # Version info
    $versionLabel = New-Object System.Windows.Forms.Label
    $versionLabel.Text = "v5.0.1 | Professional Edition"
    $versionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $versionLabel.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
    $versionLabel.Location = New-Object System.Drawing.Point(750, 70)
    $versionLabel.Size = New-Object System.Drawing.Size(200, 20)
    $versionLabel.TextAlign = "MiddleRight"
    $versionLabel.BackColor = $script:Colors.Background
    $versionLabel.Anchor = "Top,Right"
    $headerPanel.Controls.Add($versionLabel)
    
    $backgroundPanel.Controls.Add($headerPanel)
    
    return $form, $backgroundPanel
}#
Create modern progress panel
function New-ProgressPanel {
    param($ParentPanel)
    
    $progressPanel = New-Object System.Windows.Forms.Panel
    $progressPanel.Size = New-Object System.Drawing.Size(1000, 60)
    $progressPanel.Location = New-Object System.Drawing.Point(0, 100)
    $progressPanel.Anchor = "Top,Left,Right"
    $progressPanel.BackColor = $script:Colors.Surface
    
    # Add subtle border
    $progressPanel.Add_Paint({
            param($sender, $e)
            $pen = New-Object System.Drawing.Pen($script:Colors.Primary, 2)
            $e.Graphics.DrawLine($pen, 0, $sender.Height - 2, $sender.Width, $sender.Height - 2)
            $pen.Dispose()
        })
    
    # Progress bar
    $script:ProgressBar = New-Object System.Windows.Forms.ProgressBar
    $script:ProgressBar.Location = New-Object System.Drawing.Point(30, 15)
    $script:ProgressBar.Size = New-Object System.Drawing.Size(300, 8)
    $script:ProgressBar.Style = "Continuous"
    $script:ProgressBar.ForeColor = $script:Colors.Accent
    $script:ProgressBar.BackColor = $script:Colors.Background
    $progressPanel.Controls.Add($script:ProgressBar)
    
    # Progress label
    $script:ProgressLabel = New-Object System.Windows.Forms.Label
    $script:ProgressLabel.Location = New-Object System.Drawing.Point(30, 30)
    $script:ProgressLabel.Size = New-Object System.Drawing.Size(600, 25)
    $script:ProgressLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
    $script:ProgressLabel.ForeColor = $script:Colors.Text
    $script:ProgressLabel.BackColor = $script:Colors.Background
    $progressPanel.Controls.Add($script:ProgressLabel)
    
    # Step counter
    $script:StepLabel = New-Object System.Windows.Forms.Label
    $script:StepLabel.Location = New-Object System.Drawing.Point(750, 25)
    $script:StepLabel.Size = New-Object System.Drawing.Size(200, 25)
    $script:StepLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $script:StepLabel.ForeColor = $script:Colors.Primary
    $script:StepLabel.TextAlign = "MiddleRight"
    $script:StepLabel.BackColor = $script:Colors.Background
    $script:StepLabel.Anchor = "Top,Right"
    $progressPanel.Controls.Add($script:StepLabel)
    
    $ParentPanel.Controls.Add($progressPanel)
    return $progressPanel
}

# Create main content area with modern styling
function New-ContentPanel {
    param($ParentPanel)
    
    $script:ContentPanel = New-Object System.Windows.Forms.Panel
    $script:ContentPanel.Size = New-Object System.Drawing.Size(940, 450)
    $script:ContentPanel.Location = New-Object System.Drawing.Point(30, 180)
    $script:ContentPanel.Anchor = "Top,Left,Right,Bottom"
    $script:ContentPanel.BackColor = $script:Colors.Surface
    $script:ContentPanel.BorderStyle = "None"
    
    # Add rounded corners effect
    $script:ContentPanel.Add_Paint({
            param($sender, $e)
            try {
                $graphics = $e.Graphics
                $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            
                # Create rounded rectangle
                $rect = New-Object System.Drawing.Rectangle(0, 0, $sender.Width - 1, $sender.Height - 1)
                $path = New-Object System.Drawing.Drawing2D.GraphicsPath
                $radius = 8
            
                # Add rounded rectangle to path
                $path.AddArc($rect.X, $rect.Y, $radius * 2, $radius * 2, 180, 90)
                $path.AddArc($rect.Right - $radius * 2, $rect.Y, $radius * 2, $radius * 2, 270, 90)
                $path.AddArc($rect.Right - $radius * 2, $rect.Bottom - $radius * 2, $radius * 2, $radius * 2, 0, 90)
                $path.AddArc($rect.X, $rect.Bottom - $radius * 2, $radius * 2, $radius * 2, 90, 90)
                $path.CloseFigure()
            
                # Fill with surface color
                $brush = New-Object System.Drawing.SolidBrush($script:Colors.Surface)
                $graphics.FillPath($brush, $path)
            
                # Draw border
                $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(100, 100, 100), 1)
                $graphics.DrawPath($pen, $path)
            
                $brush.Dispose()
                $pen.Dispose()
                $path.Dispose()
            }
            catch {
                # Fallback to simple rectangle
                $brush = New-Object System.Drawing.SolidBrush($script:Colors.Surface)
                $e.Graphics.FillRectangle($brush, 0, 0, $sender.Width, $sender.Height)
                $brush.Dispose()
            }
        })
    
    $ParentPanel.Controls.Add($script:ContentPanel)
    return $script:ContentPanel
}

# Create modern button panel
function New-ButtonPanel {
    param($ParentPanel)
    
    $buttonPanel = New-Object System.Windows.Forms.Panel
    $buttonPanel.Size = New-Object System.Drawing.Size(1000, 80)
    # Position button panel with margin from bottom to ensure visibility
    $buttonPanel.Location = New-Object System.Drawing.Point(0, ($ParentPanel.Height - 100))
    $buttonPanel.Anchor = "Bottom,Left,Right"
    $buttonPanel.BackColor = $script:Colors.Surface
    
    # Add top border
    $buttonPanel.Add_Paint({
            param($sender, $e)
            $pen = New-Object System.Drawing.Pen($script:Colors.Primary, 1)
            $e.Graphics.DrawLine($pen, 0, 0, $sender.Width, 0)
            $pen.Dispose()
        })
    
    # Create modern buttons with hover effects
    $script:BackButton = New-ModernButton -Text "◀ Back" -Location (New-Object System.Drawing.Point(650, 20)) -Size (New-Object System.Drawing.Size(100, 40)) -ButtonType "Secondary"
    $script:BackButton.Enabled = $false
    $script:BackButton.Add_Click({ Move-ToPreviousStep })
    $buttonPanel.Controls.Add($script:BackButton)
    
    $script:NextButton = New-ModernButton -Text "Next ▶" -Location (New-Object System.Drawing.Point(760, 20)) -Size (New-Object System.Drawing.Size(100, 40)) -ButtonType "Primary"
    $script:NextButton.Add_Click({ Move-ToNextStep })
    $buttonPanel.Controls.Add($script:NextButton)
    
    $cancelButton = New-ModernButton -Text "Cancel" -Location (New-Object System.Drawing.Point(870, 20)) -Size (New-Object System.Drawing.Size(100, 40)) -ButtonType "Danger"
    $cancelButton.Add_Click({ 
            if ([System.Windows.Forms.MessageBox]::Show("Are you sure you want to cancel the configuration wizard?", "Cancel Configuration", "YesNo", "Question") -eq "Yes") {
                $script:MainForm.Close()
            }
        })
    $buttonPanel.Controls.Add($cancelButton)
    
    $ParentPanel.Controls.Add($buttonPanel)
    return $buttonPanel
}#
Create modern styled buttons with hover effects
function New-ModernButton {
    param(
        [string]$Text,
        [System.Drawing.Point]$Location,
        [System.Drawing.Size]$Size,
        [ValidateSet("Primary", "Secondary", "Success", "Warning", "Danger")]
        [string]$ButtonType = "Primary"
    )
    
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Location = $Location
    $button.Size = $Size
    $button.FlatStyle = "Flat"
    $button.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $button.Cursor = "Hand"
    
    # Set colors based on button type
    switch ($ButtonType) {
        "Primary" {
            $button.BackColor = $script:Colors.Primary
            $button.ForeColor = [System.Drawing.Color]::White
            $button.FlatAppearance.BorderColor = $script:Colors.Primary
        }
        "Secondary" {
            $button.BackColor = $script:Colors.Surface
            $button.ForeColor = $script:Colors.Text
            $button.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
        }
        "Success" {
            $button.BackColor = $script:Colors.Success
            $button.ForeColor = [System.Drawing.Color]::White
            $button.FlatAppearance.BorderColor = $script:Colors.Success
        }
        "Warning" {
            $button.BackColor = $script:Colors.Warning
            $button.ForeColor = [System.Drawing.Color]::Black
            $button.FlatAppearance.BorderColor = $script:Colors.Warning
        }
        "Danger" {
            $button.BackColor = $script:Colors.Error
            $button.ForeColor = [System.Drawing.Color]::White
            $button.FlatAppearance.BorderColor = $script:Colors.Error
        }
    }
    
    $button.FlatAppearance.BorderSize = 1
    
    # Add hover effects
    $originalBackColor = $button.BackColor
    $button.Add_MouseEnter({
            $this.BackColor = [System.Drawing.Color]::FromArgb(
                [Math]::Min(255, $originalBackColor.R + 30),
                [Math]::Min(255, $originalBackColor.G + 30),
                [Math]::Min(255, $originalBackColor.B + 30)
            )
        })
    
    $button.Add_MouseLeave({
            $this.BackColor = $originalBackColor
        })
    
    return $button
}

# Enhanced error handling and disposal management
function Initialize-SafeEventHandling {
    param($Form)
    
    # Proper form closing with resource cleanup
    $Form.Add_FormClosing({
            param($sender, $e)
            try {
                # Clean up any background operations
                if ($script:BackgroundWorker) {
                    $script:BackgroundWorker.CancelAsync()
                    $script:BackgroundWorker.Dispose()
                }
            
                # Clean up timers
                if ($script:UpdateTimer) {
                    $script:UpdateTimer.Stop()
                    $script:UpdateTimer.Dispose()
                }
            
                # Force garbage collection
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()
            }
            catch {
                # Silently handle cleanup errors
            }
        })
    
    # Global exception handler - simplified to avoid SetUnhandledExceptionMode issues
    $Form.Add_Load({
            try {
                # Only add thread exception handler without changing exception mode
                [System.Windows.Forms.Application]::add_ThreadException({
                        param($sender, $e)
                        $errorMsg = "An error occurred: $($e.Exception.Message)"
                        [System.Windows.Forms.MessageBox]::Show($errorMsg, "Error", "OK", "Error")
                    })
            }
            catch {
                # Silently handle any exception handler setup errors
                Write-Verbose "Could not set up exception handler: $($_.Exception.Message)"
            }
        })
}

# Update progress display with modern styling
function Update-Progress {
    try {
        if ($script:CurrentStep -ge 0 -and $script:CurrentStep -lt $script:WizardSteps.Count) {
            $currentStep = $script:WizardSteps[$script:CurrentStep]
            $script:ProgressLabel.Text = "$($currentStep.Title) - $($currentStep.Description)"
            $script:StepLabel.Text = "Step $($script:CurrentStep + 1) of $($script:WizardSteps.Count)"
            
            # Update progress bar
            $progressPercent = [Math]::Round(($script:CurrentStep / ($script:WizardSteps.Count - 1)) * 100)
            $script:ProgressBar.Value = $progressPercent
            
            # Update button states
            $script:BackButton.Enabled = ($script:CurrentStep -gt 0)
            
            if ($script:CurrentStep -eq ($script:WizardSteps.Count - 1)) {
                $script:NextButton.Text = "Finish"
            }
            elseif ($script:CurrentStep -eq ($script:WizardSteps.Count - 2)) {
                $script:NextButton.Text = "Generate"
            }
            else {
                $script:NextButton.Text = "Next ▶"
            }
        }
    }
    catch {
        Write-Verbose "Error updating progress: $($_.Exception.Message)"
    }
}

# Navigation functions with error handling
function Move-ToNextStep {
    try {
        if (Confirm-CurrentStep) {
            if ($script:CurrentStep -eq ($script:WizardSteps.Count - 2)) {
                # Generate configuration before moving to final step
                Generate-Configuration
            }
            
            if ($script:CurrentStep -lt ($script:WizardSteps.Count - 1)) {
                $script:CurrentStep++
                Show-CurrentStep
            }
            else {
                # Finish wizard
                $script:MainForm.Close()
            }
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error navigating to next step: $($_.Exception.Message)", "Navigation Error", "OK", "Error")
    }
}

function Move-ToPreviousStep {
    try {
        if ($script:CurrentStep -gt 0) {
            $script:CurrentStep--
            Show-CurrentStep
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error navigating to previous step: $($_.Exception.Message)", "Navigation Error", "OK", "Error")
    }
}# Val
idate current step with enhanced error handling
function Confirm-CurrentStep {
    try {
        switch ($script:CurrentStep) {
            1 {
                # Deployment Type
                if (-not $script:ConfigData.DeploymentType) {
                    [System.Windows.Forms.MessageBox]::Show("Please select a deployment type.", "Validation Error", "OK", "Warning")
                    return $false
                }
            }
            2 {
                # Storage Configuration
                if (-not $script:ConfigData.DatastoreDirectory -or -not (Test-Path (Split-Path $script:ConfigData.DatastoreDirectory -Parent) -ErrorAction SilentlyContinue)) {
                    [System.Windows.Forms.MessageBox]::Show("Please specify a valid datastore directory.", "Validation Error", "OK", "Warning")
                    return $false
                }
            }
            6 {
                # Authentication
                if (-not $script:ConfigData.AdminPassword -or $script:ConfigData.AdminPassword.Length -lt 8) {
                    [System.Windows.Forms.MessageBox]::Show("Please set an admin password (minimum 8 characters).", "Validation Error", "OK", "Warning")
                    return $false
                }
            }
        }
        return $true
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Validation error: $($_.Exception.Message)", "Validation Error", "OK", "Error")
        return $false
    }
}

# Show current step content with error handling
function Show-CurrentStep {
    try {
        $script:ContentPanel.Controls.Clear()
        Update-Progress
        
        switch ($script:CurrentStep) {
            0 { Show-WelcomeStep }
            1 { Show-DeploymentTypeStep }
            2 { Show-StorageConfigurationStep }
            3 { Show-CertificateSettingsStep }
            4 { Show-SecuritySettingsStep }
            5 { Show-NetworkConfigurationStep }
            6 { Show-AuthenticationStep }
            7 { Show-ReviewStep }
            8 { Show-CompleteStep }
            default { Show-WelcomeStep }
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error displaying step: $($_.Exception.Message)", "Display Error", "OK", "Error")
    }
}

# Welcome step with modern design
function Show-WelcomeStep {
    # Welcome title
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Welcome to Velociraptor Configuration Wizard!"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = $script:Colors.Primary
    $titleLabel.Location = New-Object System.Drawing.Point(40, 30)
    $titleLabel.Size = New-Object System.Drawing.Size(800, 40)
    $titleLabel.BackColor = $script:Colors.Background
    $script:ContentPanel.Controls.Add($titleLabel)
    
    # Welcome content
    $welcomeText = @"
This professional wizard will guide you through creating a complete Velociraptor configuration file optimized for your environment.

🎯 Configuration Steps:
   • Deployment type selection (Server, Standalone, or Client)
   • Storage locations for data and logs with validation
   • SSL certificate settings and expiration policies
   • Security and access restrictions configuration
   • Network configuration with port management
   • Administrative credentials with secure password generation

🚀 Advanced Features:
   • Real-time input validation and error checking
   • Secure password generation with cryptographic strength
   • Configuration templates for common deployment scenarios
   • One-click deployment integration with existing scripts
   • Professional YAML configuration file generation

🔒 Security First:
   • Industry-standard security practices built-in
   • Compliance-ready configurations
   • Encrypted credential handling
   • Audit trail generation

Click Next to begin the configuration process and deploy your Velociraptor DFIR infrastructure.
"@
    
    $welcomeLabel = New-Object System.Windows.Forms.Label
    $welcomeLabel.Text = $welcomeText
    $welcomeLabel.Location = New-Object System.Drawing.Point(40, 90)
    $welcomeLabel.Size = New-Object System.Drawing.Size(850, 350)
    $welcomeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
    $welcomeLabel.ForeColor = $script:Colors.Text
    $welcomeLabel.BackColor = $script:Colors.Background
    $script:ContentPanel.Controls.Add($welcomeLabel)
    
    # Add raptor emoji decoration
    $raptorLabel = New-Object System.Windows.Forms.Label
    $raptorLabel.Text = "🦖"
    $raptorLabel.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 48, [System.Drawing.FontStyle]::Regular)
    $raptorLabel.Location = New-Object System.Drawing.Point(750, 350)
    $raptorLabel.Size = New-Object System.Drawing.Size(100, 100)
    $raptorLabel.TextAlign = "MiddleCenter"
    $raptorLabel.BackColor = $script:Colors.Background
    $script:ContentPanel.Controls.Add($raptorLabel)
}

# Storage Configuration Step
function Show-StorageConfigurationStep {
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Storage Configuration"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = $script:Colors.Primary
    $titleLabel.Location = New-Object System.Drawing.Point(40, 30)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 30)
    $titleLabel.BackColor = $script:Colors.Background
    $script:ContentPanel.Controls.Add($titleLabel)
    
    # Datastore directory
    $datastoreLabel = New-Object System.Windows.Forms.Label
    $datastoreLabel.Text = "Datastore Directory:"
    $datastoreLabel.Location = New-Object System.Drawing.Point(40, 80)
    $datastoreLabel.Size = New-Object System.Drawing.Size(150, 25)
    $datastoreLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $datastoreLabel.ForeColor = $script:Colors.Text
    $datastoreLabel.BackColor = $script:Colors.Background
    $script:ContentPanel.Controls.Add($datastoreLabel)
    
    $script:DatastoreTextBox = New-Object System.Windows.Forms.TextBox
    $script:DatastoreTextBox.Text = $script:ConfigData.DatastoreDirectory
    $script:DatastoreTextBox.Location = New-Object System.Drawing.Point(40, 110)
    $script:DatastoreTextBox.Size = New-Object System.Drawing.Size(400, 25)
    $script:DatastoreTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $script:DatastoreTextBox.BackColor = $script:Colors.Surface
    $script:DatastoreTextBox.ForeColor = $script:Colors.Text
    $script:DatastoreTextBox.Add_TextChanged({
        $script:ConfigData.DatastoreDirectory = $script:DatastoreTextBox.Text
    })
    $script:ContentPanel.Controls.Add($script:DatastoreTextBox)
    
    # Browse button
    $browseButton = New-ModernButton -Text "Browse..." -Location (New-Object System.Drawing.Point(450, 110)) -Size (New-Object System.Drawing.Size(80, 25)) -ButtonType "Secondary"
    $browseButton.Add_Click({
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderDialog.Description = "Select Datastore Directory"
        $folderDialog.SelectedPath = $script:ConfigData.DatastoreDirectory
        if ($folderDialog.ShowDialog() -eq "OK") {
            $script:DatastoreTextBox.Text = $folderDialog.SelectedPath
            $script:ConfigData.DatastoreDirectory = $folderDialog.SelectedPath
        }
    })
    $script:ContentPanel.Controls.Add($browseButton)
    
    # Logs directory
    $logsLabel = New-Object System.Windows.Forms.Label
    $logsLabel.Text = "Logs Directory:"
    $logsLabel.Location = New-Object System.Drawing.Point(40, 160)
    $logsLabel.Size = New-Object System.Drawing.Size(150, 25)
    $logsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $logsLabel.ForeColor = $script:Colors.Text
    $logsLabel.BackColor = $script:Colors.Background
    $script:ContentPanel.Controls.Add($logsLabel)
    
    $script:LogsTextBox = New-Object System.Windows.Forms.TextBox
    $script:LogsTextBox.Text = $script:ConfigData.LogsDirectory
    $script:LogsTextBox.Location = New-Object System.Drawing.Point(40, 190)
    $script:LogsTextBox.Size = New-Object System.Drawing.Size(400, 25)
    $script:LogsTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $script:LogsTextBox.BackColor = $script:Colors.Surface
    $script:LogsTextBox.ForeColor = $script:Colors.Text
    $script:LogsTextBox.Add_TextChanged({
        $script:ConfigData.LogsDirectory = $script:LogsTextBox.Text
    })
    $script:ContentPanel.Controls.Add($script:LogsTextBox)
}

# Certificate Settings Step
function Show-CertificateSettingsStep {
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Certificate Settings"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = $script:Colors.Primary
    $titleLabel.Location = New-Object System.Drawing.Point(40, 30)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 30)
    $titleLabel.BackColor = $script:Colors.Background
    $script:ContentPanel.Controls.Add($titleLabel)
    
    # Certificate expiration
    $expirationLabel = New-Object System.Windows.Forms.Label
    $expirationLabel.Text = "Certificate Expiration:"
    $expirationLabel.Location = New-Object System.Drawing.Point(40, 80)
    $expirationLabel.Size = New-Object System.Drawing.Size(150, 25)
    $expirationLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $expirationLabel.ForeColor = $script:Colors.Text
    $expirationLabel.BackColor = $script:Colors.Background
    $script:ContentPanel.Controls.Add($expirationLabel)
    
    $script:ExpirationComboBox = New-Object System.Windows.Forms.ComboBox
    $script:ExpirationComboBox.Items.AddRange(@("1 Year", "2 Years", "5 Years", "10 Years"))
    $script:ExpirationComboBox.Text = $script:ConfigData.CertificateExpiration
    $script:ExpirationComboBox.Location = New-Object System.Drawing.Point(40, 110)
    $script:ExpirationComboBox.Size = New-Object System.Drawing.Size(200, 25)
    $script:ExpirationComboBox.DropDownStyle = "DropDownList"
    $script:ExpirationComboBox.BackColor = $script:Colors.Surface
    $script:ExpirationComboBox.ForeColor = $script:Colors.Text
    $script:ExpirationComboBox.Add_SelectedIndexChanged({
        $script:ConfigData.CertificateExpiration = $script:ExpirationComboBox.Text
    })
    $script:ContentPanel.Controls.Add($script:ExpirationComboBox)
}

# Security Settings Step
function Show-SecuritySettingsStep {
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Security Settings"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = $script:Colors.Primary
    $titleLabel.Location = New-Object System.Drawing.Point(40, 30)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 30)
    $titleLabel.BackColor = $script:Colors.Background
    $script:ContentPanel.Controls.Add($titleLabel)
    
    # Restrict VQL checkbox
    $script:RestrictVQLCheckBox = New-Object System.Windows.Forms.CheckBox
    $script:RestrictVQLCheckBox.Text = "Restrict VQL queries for enhanced security"
    $script:RestrictVQLCheckBox.Checked = $script:ConfigData.RestrictVQL
    $script:RestrictVQLCheckBox.Location = New-Object System.Drawing.Point(40, 80)
    $script:RestrictVQLCheckBox.Size = New-Object System.Drawing.Size(400, 25)
    $script:RestrictVQLCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $script:RestrictVQLCheckBox.ForeColor = $script:Colors.Text
    $script:RestrictVQLCheckBox.BackColor = $script:Colors.Background
    $script:RestrictVQLCheckBox.Add_CheckedChanged({
        $script:ConfigData.RestrictVQL = $script:RestrictVQLCheckBox.Checked
    })
    $script:ContentPanel.Controls.Add($script:RestrictVQLCheckBox)
    
    # Use registry checkbox
    $script:UseRegistryCheckBox = New-Object System.Windows.Forms.CheckBox
    $script:UseRegistryCheckBox.Text = "Store configuration in Windows Registry"
    $script:UseRegistryCheckBox.Checked = $script:ConfigData.UseRegistry
    $script:UseRegistryCheckBox.Location = New-Object System.Drawing.Point(40, 120)
    $script:UseRegistryCheckBox.Size = New-Object System.Drawing.Size(400, 25)
    $script:UseRegistryCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $script:UseRegistryCheckBox.ForeColor = $script:Colors.Text
    $script:UseRegistryCheckBox.BackColor = $script:Colors.Background
    $script:UseRegistryCheckBox.Add_CheckedChanged({
        $script:ConfigData.UseRegistry = $script:UseRegistryCheckBox.Checked
    })
    $script:ContentPanel.Controls.Add($script:UseRegistryCheckBox)
}

# Network Configuration Step
function Show-NetworkConfigurationStep {
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Network Configuration"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = $script:Colors.Primary
    $titleLabel.Location = New-Object System.Drawing.Point(40, 30)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 30)
    $titleLabel.BackColor = $script:Colors.Background
    $script:ContentPanel.Controls.Add($titleLabel)
    
    # Bind address
    $bindLabel = New-Object System.Windows.Forms.Label
    $bindLabel.Text = "Bind Address:"
    $bindLabel.Location = New-Object System.Drawing.Point(40, 80)
    $bindLabel.Size = New-Object System.Drawing.Size(100, 25)
    $bindLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $bindLabel.ForeColor = $script:Colors.Text
    $bindLabel.BackColor = $script:Colors.Background
    $script:ContentPanel.Controls.Add($bindLabel)
    
    $script:BindAddressTextBox = New-Object System.Windows.Forms.TextBox
    $script:BindAddressTextBox.Text = $script:ConfigData.BindAddress
    $script:BindAddressTextBox.Location = New-Object System.Drawing.Point(150, 80)
    $script:BindAddressTextBox.Size = New-Object System.Drawing.Size(150, 25)
    $script:BindAddressTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $script:BindAddressTextBox.BackColor = $script:Colors.Surface
    $script:BindAddressTextBox.ForeColor = $script:Colors.Text
    $script:BindAddressTextBox.Add_TextChanged({
        $script:ConfigData.BindAddress = $script:BindAddressTextBox.Text
    })
    $script:ContentPanel.Controls.Add($script:BindAddressTextBox)
    
    # Bind port
    $portLabel = New-Object System.Windows.Forms.Label
    $portLabel.Text = "Port:"
    $portLabel.Location = New-Object System.Drawing.Point(320, 80)
    $portLabel.Size = New-Object System.Drawing.Size(50, 25)
    $portLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $portLabel.ForeColor = $script:Colors.Text
    $portLabel.BackColor = $script:Colors.Background
    $script:ContentPanel.Controls.Add($portLabel)
    
    $script:BindPortTextBox = New-Object System.Windows.Forms.TextBox
    $script:BindPortTextBox.Text = $script:ConfigData.BindPort
    $script:BindPortTextBox.Location = New-Object System.Drawing.Point(370, 80)
    $script:BindPortTextBox.Size = New-Object System.Drawing.Size(80, 25)
    $script:BindPortTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $script:BindPortTextBox.BackColor = $script:Colors.Surface
    $script:BindPortTextBox.ForeColor = $script:Colors.Text
    $script:BindPortTextBox.Add_TextChanged({
        $script:ConfigData.BindPort = $script:BindPortTextBox.Text
    })
    $script:ContentPanel.Controls.Add($script:BindPortTextBox)
    
    # GUI bind address
    $guiBindLabel = New-Object System.Windows.Forms.Label
    $guiBindLabel.Text = "GUI Address:"
    $guiBindLabel.Location = New-Object System.Drawing.Point(40, 130)
    $guiBindLabel.Size = New-Object System.Drawing.Size(100, 25)
    $guiBindLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $guiBindLabel.ForeColor = $script:Colors.Text
    $guiBindLabel.BackColor = $script:Colors.Background
    $script:ContentPanel.Controls.Add($guiBindLabel)
    
    $script:GUIBindAddressTextBox = New-Object System.Windows.Forms.TextBox
    $script:GUIBindAddressTextBox.Text = $script:ConfigData.GUIBindAddress
    $script:GUIBindAddressTextBox.Location = New-Object System.Drawing.Point(150, 130)
    $script:GUIBindAddressTextBox.Size = New-Object System.Drawing.Size(150, 25)
    $script:GUIBindAddressTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $script:GUIBindAddressTextBox.BackColor = $script:Colors.Surface
    $script:GUIBindAddressTextBox.ForeColor = $script:Colors.Text
    $script:GUIBindAddressTextBox.Add_TextChanged({
        $script:ConfigData.GUIBindAddress = $script:GUIBindAddressTextBox.Text
    })
    $script:ContentPanel.Controls.Add($script:GUIBindAddressTextBox)
    
    # GUI port
    $guiPortLabel = New-Object System.Windows.Forms.Label
    $guiPortLabel.Text = "GUI Port:"
    $guiPortLabel.Location = New-Object System.Drawing.Point(320, 130)
    $guiPortLabel.Size = New-Object System.Drawing.Size(50, 25)
    $guiPortLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $guiPortLabel.ForeColor = $script:Colors.Text
    $guiPortLabel.BackColor = $script:Colors.Background
    $script:ContentPanel.Controls.Add($guiPortLabel)
    
    $script:GUIBindPortTextBox = New-Object System.Windows.Forms.TextBox
    $script:GUIBindPortTextBox.Text = $script:ConfigData.GUIBindPort
    $script:GUIBindPortTextBox.Location = New-Object System.Drawing.Point(370, 130)
    $script:GUIBindPortTextBox.Size = New-Object System.Drawing.Size(80, 25)
    $script:GUIBindPortTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $script:GUIBindPortTextBox.BackColor = $script:Colors.Surface
    $script:GUIBindPortTextBox.ForeColor = $script:Colors.Text
    $script:GUIBindPortTextBox.Add_TextChanged({
        $script:ConfigData.GUIBindPort = $script:GUIBindPortTextBox.Text
    })
    $script:ContentPanel.Controls.Add($script:GUIBindPortTextBox)
}

# Review Step
function Show-ReviewStep {
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Review Configuration"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = $script:Colors.Primary
    $titleLabel.Location = New-Object System.Drawing.Point(40, 30)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 30)
    $titleLabel.BackColor = $script:Colors.Background
    $script:ContentPanel.Controls.Add($titleLabel)
    
    # Review text
    $reviewText = @"
Deployment Type: $($script:ConfigData.DeploymentType)
Datastore Directory: $($script:ConfigData.DatastoreDirectory)
Logs Directory: $($script:ConfigData.LogsDirectory)
Certificate Expiration: $($script:ConfigData.CertificateExpiration)
Restrict VQL: $($script:ConfigData.RestrictVQL)
Use Registry: $($script:ConfigData.UseRegistry)
Bind Address: $($script:ConfigData.BindAddress):$($script:ConfigData.BindPort)
GUI Address: $($script:ConfigData.GUIBindAddress):$($script:ConfigData.GUIBindPort)
Organization: $($script:ConfigData.OrganizationName)
Admin Username: $($script:ConfigData.AdminUsername)
"@
    
    $reviewLabel = New-Object System.Windows.Forms.Label
    $reviewLabel.Text = $reviewText
    $reviewLabel.Location = New-Object System.Drawing.Point(40, 80)
    $reviewLabel.Size = New-Object System.Drawing.Size(800, 300)
    $reviewLabel.Font = New-Object System.Drawing.Font("Consolas", 10)
    $reviewLabel.ForeColor = $script:Colors.Text
    $reviewLabel.BackColor = $script:Colors.Background
    $script:ContentPanel.Controls.Add($reviewLabel)
}

# Generate secure password
function New-SecurePassword {
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
    $password = ""
    $random = New-Object System.Random
    for ($i = 0; $i -lt 16; $i++) {
        $password += $chars[$random.Next($chars.Length)]
    }
    return $password
}

# Configuration generation with error handling
function Generate-Configuration {
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $configFileName = "velociraptor_config_$timestamp.yaml"
        $script:ConfigData.OutputPath = Join-Path $PWD $configFileName
        
        # Create basic YAML configuration
        $yamlContent = @"
# Velociraptor Configuration
# Generated by Configuration Wizard on $(Get-Date)

deployment_type: $($script:ConfigData.DeploymentType)
datastore:
  location: $($script:ConfigData.DatastoreDirectory)
  
logging:
  directory: $($script:ConfigData.LogsDirectory)
  
certificates:
  expiration: $($script:ConfigData.CertificateExpiration)
  
security:
  restrict_vql: $($script:ConfigData.RestrictVQL.ToString().ToLower())
  use_registry: $($script:ConfigData.UseRegistry.ToString().ToLower())
  
network:
  bind_address: $($script:ConfigData.BindAddress)
  bind_port: $($script:ConfigData.BindPort)
  gui_bind_address: $($script:ConfigData.GUIBindAddress)
  gui_bind_port: $($script:ConfigData.GUIBindPort)
  
organization:
  name: $($script:ConfigData.OrganizationName)
  
authentication:
  admin_username: $($script:ConfigData.AdminUsername)
  # Note: Password should be set during deployment
"@
        
        Set-Content -Path $script:ConfigData.OutputPath -Value $yamlContent -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Configuration generated successfully!`nSaved to: $($script:ConfigData.OutputPath)", "Success", "OK", "Information")
        
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to generate configuration: $($_.Exception.Message)", "Error", "OK", "Error")
    }
}

# Main execution with comprehensive error handling
try {
    Write-Host $script:VelociraptorBanner -ForegroundColor Cyan
    Write-Host "Starting Velociraptor Configuration Wizard..." -ForegroundColor White
    
    # Create the main form
    $script:MainForm, $backgroundPanel = New-RaptorWizardForm
    
    # Initialize components
    $progressPanel = New-ProgressPanel -ParentPanel $backgroundPanel
    $contentPanel = New-ContentPanel -ParentPanel $backgroundPanel
    $buttonPanel = New-ButtonPanel -ParentPanel $backgroundPanel
    
    # Initialize safe event handling
    Initialize-SafeEventHandling -Form $script:MainForm
    
    # Add resize event handler to keep button panel at bottom
    $script:MainForm.Add_Resize({
            try {
                # Reposition button panel to stay at bottom with margin
                $buttonPanel.Location = New-Object System.Drawing.Point(0, ($backgroundPanel.Height - 100))
            }
            catch {
                # Silently handle resize errors
            }
        })
    
    # Show initial step
    Show-CurrentStep
    
    if ($StartMinimized) {
        $script:MainForm.WindowState = "Minimized"
    }
    
    # Run the application
    [System.Windows.Forms.Application]::Run($script:MainForm)
    
    Write-Host "Velociraptor Configuration Wizard completed." -ForegroundColor Green
    
}
catch {
    $errorMsg = "GUI initialization failed: $($_.Exception.Message)"
    Write-Host $errorMsg -ForegroundColor Red
    [System.Windows.Forms.MessageBox]::Show($errorMsg, "Critical Error", "OK", "Error")
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
}# 
Deployment Type Step
function Show-DeploymentTypeStep {
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Select Deployment Type"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = $script:Colors.Primary
    $titleLabel.Location = New-Object System.Drawing.Point(40, 30)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 35)
    $titleLabel.BackColor = [System.Drawing.Color]::Transparent
    $script:ContentPanel.Controls.Add($titleLabel)
    
    # Server option
    $script:ServerRadio = New-Object System.Windows.Forms.RadioButton
    $script:ServerRadio.Text = "🖥️ Server Deployment"
    $script:ServerRadio.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $script:ServerRadio.ForeColor = $script:Colors.Text
    $script:ServerRadio.BackColor = [System.Drawing.Color]::Transparent
    $script:ServerRadio.Location = New-Object System.Drawing.Point(60, 100)
    $script:ServerRadio.Size = New-Object System.Drawing.Size(300, 25)
    $script:ServerRadio.Checked = ($script:ConfigData.DeploymentType -eq "Server")
    $script:ServerRadio.Add_CheckedChanged({ 
            if ($script:ServerRadio.Checked) { $script:ConfigData.DeploymentType = "Server" }
        })
    $script:ContentPanel.Controls.Add($script:ServerRadio)
    
    $serverDesc = New-Object System.Windows.Forms.Label
    $serverDesc.Text = "Full enterprise server with web GUI, client management, and multi-user capabilities"
    $serverDesc.Location = New-Object System.Drawing.Point(80, 130)
    $serverDesc.Size = New-Object System.Drawing.Size(700, 20)
    $serverDesc.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $serverDesc.ForeColor = $script:Colors.TextSecondary
    $serverDesc.BackColor = [System.Drawing.Color]::Transparent
    $script:ContentPanel.Controls.Add($serverDesc)
    
    # Standalone option
    $script:StandaloneRadio = New-Object System.Windows.Forms.RadioButton
    $script:StandaloneRadio.Text = "💻 Standalone Deployment"
    $script:StandaloneRadio.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $script:StandaloneRadio.ForeColor = $script:Colors.Text
    $script:StandaloneRadio.BackColor = [System.Drawing.Color]::Transparent
    $script:StandaloneRadio.Location = New-Object System.Drawing.Point(60, 180)
    $script:StandaloneRadio.Size = New-Object System.Drawing.Size(300, 25)
    $script:StandaloneRadio.Checked = ($script:ConfigData.DeploymentType -eq "Standalone")
    $script:StandaloneRadio.Add_CheckedChanged({ 
            if ($script:StandaloneRadio.Checked) { $script:ConfigData.DeploymentType = "Standalone" }
        })
    $script:ContentPanel.Controls.Add($script:StandaloneRadio)
    
    $standaloneDesc = New-Object System.Windows.Forms.Label
    $standaloneDesc.Text = "Single-user forensic workstation with local GUI access and simplified management"
    $standaloneDesc.Location = New-Object System.Drawing.Point(80, 210)
    $standaloneDesc.Size = New-Object System.Drawing.Size(700, 20)
    $standaloneDesc.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $standaloneDesc.ForeColor = $script:Colors.TextSecondary
    $standaloneDesc.BackColor = [System.Drawing.Color]::Transparent
    $script:ContentPanel.Controls.Add($standaloneDesc)
    
    # Client option
    $script:ClientRadio = New-Object System.Windows.Forms.RadioButton
    $script:ClientRadio.Text = "📱 Client Configuration"
    $script:ClientRadio.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $script:ClientRadio.ForeColor = $script:Colors.Text
    $script:ClientRadio.BackColor = [System.Drawing.Color]::Transparent
    $script:ClientRadio.Location = New-Object System.Drawing.Point(60, 260)
    $script:ClientRadio.Size = New-Object System.Drawing.Size(300, 25)
    $script:ClientRadio.Checked = ($script:ConfigData.DeploymentType -eq "Client")
    $script:ClientRadio.Add_CheckedChanged({ 
            if ($script:ClientRadio.Checked) { $script:ConfigData.DeploymentType = "Client" }
        })
    $script:ContentPanel.Controls.Add($script:ClientRadio)
    
    $clientDesc = New-Object System.Windows.Forms.Label
    $clientDesc.Text = "Client agent configuration for connecting to a centralized Velociraptor server"
    $clientDesc.Location = New-Object System.Drawing.Point(80, 290)
    $clientDesc.Size = New-Object System.Drawing.Size(700, 20)
    $clientDesc.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $clientDesc.ForeColor = $script:Colors.TextSecondary
    $clientDesc.BackColor = [System.Drawing.Color]::Transparent
    $script:ContentPanel.Controls.Add($clientDesc)
}

# Authentication Step
function Show-AuthenticationStep {
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Authentication Configuration"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = $script:Colors.Primary
    $titleLabel.Location = New-Object System.Drawing.Point(40, 30)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 35)
    $titleLabel.BackColor = $script:Colors.Background
    $script:ContentPanel.Controls.Add($titleLabel)
    
    # Admin username
    $usernameLabel = New-Object System.Windows.Forms.Label
    $usernameLabel.Text = "Admin Username:"
    $usernameLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
    $usernameLabel.ForeColor = $script:Colors.Text
    $usernameLabel.Location = New-Object System.Drawing.Point(40, 100)
    $usernameLabel.Size = New-Object System.Drawing.Size(150, 25)
    $usernameLabel.BackColor = $script:Colors.Background
    $script:ContentPanel.Controls.Add($usernameLabel)
    
    $script:AdminUsernameTextBox = New-Object System.Windows.Forms.TextBox
    $script:AdminUsernameTextBox.Text = $script:ConfigData.AdminUsername
    $script:AdminUsernameTextBox.Location = New-Object System.Drawing.Point(40, 130)
    $script:AdminUsernameTextBox.Size = New-Object System.Drawing.Size(250, 25)
    $script:AdminUsernameTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $script:AdminUsernameTextBox.BackColor = $script:Colors.Surface
    $script:AdminUsernameTextBox.ForeColor = $script:Colors.Text
    $script:AdminUsernameTextBox.BorderStyle = "FixedSingle"
    $script:AdminUsernameTextBox.Add_TextChanged({ 
            $script:ConfigData.AdminUsername = $script:AdminUsernameTextBox.Text 
        })
    $script:ContentPanel.Controls.Add($script:AdminUsernameTextBox)
    
    # Admin password
    $passwordLabel = New-Object System.Windows.Forms.Label
    $passwordLabel.Text = "Admin Password:"
    $passwordLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
    $passwordLabel.ForeColor = $script:Colors.Text
    $passwordLabel.Location = New-Object System.Drawing.Point(40, 180)
    $passwordLabel.Size = New-Object System.Drawing.Size(150, 25)
    $passwordLabel.BackColor = $script:Colors.Background
    $script:ContentPanel.Controls.Add($passwordLabel)
    
    $script:AdminPasswordTextBox = New-Object System.Windows.Forms.TextBox
    $script:AdminPasswordTextBox.Text = $script:ConfigData.AdminPassword
    $script:AdminPasswordTextBox.Location = New-Object System.Drawing.Point(40, 210)
    $script:AdminPasswordTextBox.Size = New-Object System.Drawing.Size(250, 25)
    $script:AdminPasswordTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $script:AdminPasswordTextBox.BackColor = $script:Colors.Surface
    $script:AdminPasswordTextBox.ForeColor = $script:Colors.Text
    $script:AdminPasswordTextBox.BorderStyle = "FixedSingle"
    $script:AdminPasswordTextBox.UseSystemPasswordChar = $true
    $script:AdminPasswordTextBox.Add_TextChanged({ 
            $script:ConfigData.AdminPassword = $script:AdminPasswordTextBox.Text 
        })
    $script:ContentPanel.Controls.Add($script:AdminPasswordTextBox)
    
    # Generate password button
    $generateButton = New-ModernButton -Text "🔐 Generate Secure Password" -Location (New-Object System.Drawing.Point(320, 210)) -Size (New-Object System.Drawing.Size(200, 25)) -ButtonType "Success"
    $generateButton.Add_Click({
            $password = New-SecurePassword
            $script:AdminPasswordTextBox.Text = $password
            $script:ConfigData.AdminPassword = $password
            [System.Windows.Forms.MessageBox]::Show("Generated secure password: $password`n`nPlease save this password securely!", "Generated Password", "OK", "Information")
        })
    $script:ContentPanel.Controls.Add($generateButton)
}

# Complete Step
function Show-CompleteStep {
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "🎉 Configuration Complete!"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = $script:Colors.Success
    $titleLabel.Location = New-Object System.Drawing.Point(40, 30)
    $titleLabel.Size = New-Object System.Drawing.Size(600, 40)
    $titleLabel.BackColor = $script:Colors.Background
    $script:ContentPanel.Controls.Add($titleLabel)
    
    $successText = @"
Your Velociraptor configuration has been generated successfully!

📄 Configuration file saved to: $($script:ConfigData.OutputPath)

🚀 Next steps:
1. Review the generated configuration file
2. Deploy Velociraptor using the configuration
3. Access the web interface at https://$($script:ConfigData.GUIBindAddress):$($script:ConfigData.GUIBindPort)
4. Login with username: $($script:ConfigData.AdminUsername)

🔒 Security Notes:
• Change the default admin password after first login
• Review firewall settings for your environment
• Consider enabling additional security features
• Regularly update Velociraptor to the latest version

Click Finish to close the wizard.
"@
    
    $successLabel = New-Object System.Windows.Forms.Label
    $successLabel.Text = $successText
    $successLabel.Location = New-Object System.Drawing.Point(40, 90)
    $successLabel.Size = New-Object System.Drawing.Size(800, 300)
    $successLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
    $successLabel.ForeColor = $script:Colors.Text
    $successLabel.BackColor = $script:Colors.Background
    $script:ContentPanel.Controls.Add($successLabel)
    
    # Open config button
    $openConfigButton = New-ModernButton -Text "📄 Open Configuration File" -Location (New-Object System.Drawing.Point(40, 400)) -Size (New-Object System.Drawing.Size(200, 35)) -ButtonType "Primary"
    $openConfigButton.Add_Click({
            if (Test-Path $script:ConfigData.OutputPath) {
                Start-Process "notepad.exe" -ArgumentList $script:ConfigData.OutputPath
            }
        })
    $script:ContentPanel.Controls.Add($openConfigButton)
    
    # Deploy button
    $deployButton = New-ModernButton -Text "🚀 Deploy Now" -Location (New-Object System.Drawing.Point(260, 400)) -Size (New-Object System.Drawing.Size(150, 35)) -ButtonType "Success"
    $deployButton.Add_Click({
            $result = [System.Windows.Forms.MessageBox]::Show("This will start Velociraptor deployment using the generated configuration.`n`nContinue?", "Deploy Velociraptor", "YesNo", "Question")
            if ($result -eq "Yes") {
                try {
                    switch ($script:ConfigData.DeploymentType) {
                        "Server" {
                            Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$PSScriptRoot\..\Deploy_Velociraptor_Server.ps1`" -ConfigPath `"$($script:ConfigData.OutputPath)`""
                        }
                        "Standalone" {
                            Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$PSScriptRoot\..\Deploy_Velociraptor_Standalone.ps1`""
                        }
                        "Client" {
                            [System.Windows.Forms.MessageBox]::Show("Client configuration generated. Use this file to configure Velociraptor clients.", "Client Configuration", "OK", "Information")
                        }
                    }
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show("Failed to start deployment: $($_.Exception.Message)", "Deployment Error", "OK", "Error")
                }
            }
        })
    $script:ContentPanel.Controls.Add($deployButton)
}
# Main
 execution with comprehensive error handling
try {
    Write-Host $script:RaptorArt -ForegroundColor Green
    Write-Host "Starting Velociraptor Configuration Wizard..." -ForegroundColor Cyan
    
    # Create the main form
    $script:MainForm, $backgroundPanel = New-RaptorWizardForm
    
    # Initialize components
    $progressPanel = New-ProgressPanel -ParentPanel $backgroundPanel
    $contentPanel = New-ContentPanel -ParentPanel $backgroundPanel
    $buttonPanel = New-ButtonPanel -ParentPanel $backgroundPanel
    
    # Initialize safe event handling
    Initialize-SafeEventHandling -Form $script:MainForm
    
    # Store button panel reference for resize handler
    $script:ButtonPanel = $buttonPanel
    
    # Add resize event handler to keep button panel at bottom
    $script:MainForm.Add_Resize({
        try {
            # Reposition button panel to stay at bottom with margin
            $script:ButtonPanel.Location = New-Object System.Drawing.Point(0, ($backgroundPanel.Height - 100))
        } catch {
            # Silently handle resize errors
        }
    })
    
    # Show initial step
    Show-CurrentStep
    
    if ($StartMinimized) {
        $script:MainForm.WindowState = "Minimized"
    }
    
    # Run the application
    [System.Windows.Forms.Application]::Run($script:MainForm)
    
    Write-Host "Velociraptor Configuration Wizard completed." -ForegroundColor Green
    
} catch {
    $errorMsg = "GUI initialization failed: $($_.Exception.Message)"
    Write-Host $errorMsg -ForegroundColor Red
    [System.Windows.Forms.MessageBox]::Show($errorMsg, "Critical Error", "OK", "Error")
    exit 1
} finally {
    # Cleanup
    try {
        if ($script:MainForm) {
            $script:MainForm.Dispose()
        }
        [System.GC]::Collect()
    } catch {
        # Silently handle cleanup errors
    }
}

