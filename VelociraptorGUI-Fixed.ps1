#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Fixed version of Velociraptor Configuration Wizard

.DESCRIPTION
    A working version with simplified error handling and robust control creation.

.EXAMPLE
    .\VelociraptorGUI-Fixed.ps1
#>

[CmdletBinding()]
param(
    [switch]$StartMinimized
)

# Initialize Windows Forms
try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
    [System.Windows.Forms.Application]::EnableVisualStyles()
    Write-Host "✅ Windows Forms initialized successfully" -ForegroundColor Green
}
catch {
    Write-Error "❌ Failed to initialize Windows Forms: $($_.Exception.Message)"
    exit 1
}

# Define colors
$DARK_BACKGROUND = [System.Drawing.Color]::FromArgb(32, 32, 32)
$DARK_SURFACE = [System.Drawing.Color]::FromArgb(48, 48, 48)
$PRIMARY_TEAL = [System.Drawing.Color]::FromArgb(0, 150, 136)
$WHITE_TEXT = [System.Drawing.Color]::FromArgb(255, 255, 255)
$LIGHT_GRAY_TEXT = [System.Drawing.Color]::FromArgb(200, 200, 200)

# Banner
$VelociraptorBanner = @"
╔══════════════════════════════════════════════════════════════╗
║                VELOCIRAPTOR DFIR FRAMEWORK                   ║
║                   Configuration Wizard v5.0.2                ║
║                  Free For All First Responders               ║
╚══════════════════════════════════════════════════════════════╝
"@

# Script variables
$script:MainForm = $null
$script:CurrentStep = 0
$script:WizardSteps = @(
    @{ Title = "Welcome"; Description = "Welcome to Velociraptor Configuration Wizard" }
    @{ Title = "Deployment Type"; Description = "Choose your deployment type" }
    @{ Title = "Configuration"; Description = "Configure your deployment" }
    @{ Title = "Summary"; Description = "Review and deploy" }
)

# Safe control creation function
function New-SafeControl {
    param(
        [Parameter(Mandatory)]
        [string]$ControlType,
        [hashtable]$Properties = @{}
    )
    
    try {
        $control = New-Object $ControlType
        
        # Set properties safely
        foreach ($prop in $Properties.Keys) {
            try {
                $control.$prop = $Properties[$prop]
            }
            catch {
                Write-Warning "Failed to set property $prop on $ControlType"
            }
        }
        
        return $control
    }
    catch {
        Write-Error "Failed to create $ControlType`: $($_.Exception.Message)"
        return $null
    }
}

# Create main form
function New-MainForm {
    try {
        $form = New-Object System.Windows.Forms.Form
        $form.Text = "Velociraptor Configuration Wizard v5.0.2"
        $form.Size = New-Object System.Drawing.Size(900, 700)
        $form.StartPosition = "CenterScreen"
        $form.BackColor = $DARK_BACKGROUND
        $form.ForeColor = $WHITE_TEXT
        $form.FormBorderStyle = "FixedDialog"
        $form.MaximizeBox = $false
        $form.MinimizeBox = $true
        
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
        $panel = New-Object System.Windows.Forms.Panel
        $panel.Size = New-Object System.Drawing.Size(880, 100)
        $panel.Location = New-Object System.Drawing.Point(10, 10)
        $panel.BackColor = $DARK_SURFACE
        
        $titleLabel = New-Object System.Windows.Forms.Label
        $titleLabel.Text = "Velociraptor DFIR Framework"
        $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
        $titleLabel.ForeColor = $PRIMARY_TEAL
        $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
        $titleLabel.Size = New-Object System.Drawing.Size(500, 30)
        
        $subtitleLabel = New-Object System.Drawing.Label
        $subtitleLabel.Text = "Configuration Wizard v5.0.2 - Free For All First Responders"
        $subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        $subtitleLabel.ForeColor = $LIGHT_GRAY_TEXT
        $subtitleLabel.Location = New-Object System.Drawing.Point(20, 55)
        $subtitleLabel.Size = New-Object System.Drawing.Size(600, 20)
        
        $panel.Controls.Add($titleLabel)
        $panel.Controls.Add($subtitleLabel)
        $ParentForm.Controls.Add($panel)
        
        return $panel
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
        $panel = New-Object System.Windows.Forms.Panel
        $panel.Size = New-Object System.Drawing.Size(880, 450)
        $panel.Location = New-Object System.Drawing.Point(10, 120)
        $panel.BackColor = $DARK_SURFACE
        
        $script:ContentPanel = $panel
        $ParentForm.Controls.Add($panel)
        
        return $panel
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
        $panel = New-Object System.Windows.Forms.Panel
        $panel.Size = New-Object System.Drawing.Size(880, 60)
        $panel.Location = New-Object System.Drawing.Point(10, 580)
        $panel.BackColor = $DARK_SURFACE
        
        # Previous button
        $script:PrevButton = New-Object System.Windows.Forms.Button
        $script:PrevButton.Text = "Previous"
        $script:PrevButton.Size = New-Object System.Drawing.Size(100, 35)
        $script:PrevButton.Location = New-Object System.Drawing.Point(650, 15)
        $script:PrevButton.BackColor = $DARK_BACKGROUND
        $script:PrevButton.ForeColor = $WHITE_TEXT
        $script:PrevButton.FlatStyle = "Flat"
        $script:PrevButton.Enabled = $false
        $script:PrevButton.Add_Click({ Move-ToPreviousStep })
        
        # Next button
        $script:NextButton = New-Object System.Windows.Forms.Button
        $script:NextButton.Text = "Next"
        $script:NextButton.Size = New-Object System.Drawing.Size(100, 35)
        $script:NextButton.Location = New-Object System.Drawing.Point(760, 15)
        $script:NextButton.BackColor = $PRIMARY_TEAL
        $script:NextButton.ForeColor = $WHITE_TEXT
        $script:NextButton.FlatStyle = "Flat"
        $script:NextButton.Add_Click({ Move-ToNextStep })
        
        $panel.Controls.Add($script:PrevButton)
        $panel.Controls.Add($script:NextButton)
        $ParentForm.Controls.Add($panel)
        
        return $panel
    }
    catch {
        Write-Error "Failed to create button panel: $($_.Exception.Message)"
        return $null
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
            # Finish
            [System.Windows.Forms.MessageBox]::Show("Configuration wizard completed!", "Success", "OK", "Information")
            $script:MainForm.Close()
        }
    }
    catch {
        Write-Error "Failed to move to next step: $($_.Exception.Message)"
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
        Write-Error "Failed to move to previous step: $($_.Exception.Message)"
    }
}

function Update-CurrentStep {
    try {
        # Update button states
        $script:PrevButton.Enabled = ($script:CurrentStep -gt 0)
        
        if ($script:CurrentStep -eq ($script:WizardSteps.Count - 1)) {
            $script:NextButton.Text = "Finish"
        }
        else {
            $script:NextButton.Text = "Next"
        }
        
        # Update content
        if ($script:ContentPanel) {
            $script:ContentPanel.Controls.Clear()
            
            $stepLabel = New-Object System.Windows.Forms.Label
            $stepLabel.Text = "Step $($script:CurrentStep + 1): $($script:WizardSteps[$script:CurrentStep].Title)"
            $stepLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
            $stepLabel.ForeColor = $PRIMARY_TEAL
            $stepLabel.Location = New-Object System.Drawing.Point(40, 30)
            $stepLabel.Size = New-Object System.Drawing.Size(800, 30)
            
            $descLabel = New-Object System.Windows.Forms.Label
            $descLabel.Text = $script:WizardSteps[$script:CurrentStep].Description
            $descLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12)
            $descLabel.ForeColor = $WHITE_TEXT
            $descLabel.Location = New-Object System.Drawing.Point(40, 80)
            $descLabel.Size = New-Object System.Drawing.Size(800, 300)
            
            $script:ContentPanel.Controls.Add($stepLabel)
            $script:ContentPanel.Controls.Add($descLabel)
        }
    }
    catch {
        Write-Error "Failed to update current step: $($_.Exception.Message)"
    }
}

# Main execution
try {
    Write-Host $VelociraptorBanner -ForegroundColor Cyan
    Write-Host "Starting Velociraptor Configuration Wizard..." -ForegroundColor Green
    
    # Create main form
    $script:MainForm = New-MainForm
    if ($script:MainForm -eq $null) {
        throw "Failed to create main form"
    }
    
    # Create UI components
    $headerPanel = New-HeaderPanel -ParentForm $script:MainForm
    $contentPanel = New-ContentPanel -ParentForm $script:MainForm
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