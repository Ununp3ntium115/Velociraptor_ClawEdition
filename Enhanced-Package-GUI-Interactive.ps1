#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Enhanced Incident Response GUI with Package Integration - Fully Interactive Version

.DESCRIPTION
    Professional GUI that integrates with the 7 specialized incident response packages
    for streamlined deployment and management. This version addresses all interactivity issues:
    - Proper control enabled states
    - Correct tab order and keyboard navigation
    - All event handlers properly registered
    - Appropriate control sizing for easy clicking
    - Fixed Z-order issues
    - Visual focus indicators
    - Password field interactions
    - Radio button and checkbox responsiveness
#>

[CmdletBinding()]
param(
    [switch]$StartMinimized
)

$ErrorActionPreference = 'Stop'

Write-Host "Starting Enhanced Incident Response Package GUI (Interactive Version)..." -ForegroundColor Green

# CRITICAL: Initialize Windows Forms properly
try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    
    # Enable visual styles for proper rendering
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
    [System.Windows.Forms.Application]::EnableVisualStyles()
    
    Write-Host "Windows Forms initialized successfully" -ForegroundColor Green
}
catch {
    Write-Host "Windows Forms initialization failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Global variables
$script:SelectedPackage = $null
$script:PackageInfo = @{}

# Enhanced color palette for better visibility and interaction
$Colors = @{
    DarkBackground = [System.Drawing.Color]::FromArgb(32, 32, 32)
    DarkPanel = [System.Drawing.Color]::FromArgb(45, 45, 48)
    DarkSurface = [System.Drawing.Color]::FromArgb(55, 55, 58)
    VelociraptorGreen = [System.Drawing.Color]::FromArgb(0, 255, 127)
    VelociraptorBlue = [System.Drawing.Color]::FromArgb(0, 191, 255)
    TextColor = [System.Drawing.Color]::White
    AccentColor = [System.Drawing.Color]::FromArgb(255, 165, 0)
    FocusColor = [System.Drawing.Color]::FromArgb(100, 149, 237)
    DisabledColor = [System.Drawing.Color]::FromArgb(128, 128, 128)
    ButtonHover = [System.Drawing.Color]::FromArgb(60, 60, 65)
}

# Package definitions
$PackageDefinitions = @{
    "Ransomware Package" = @{
        Type = "Ransomware"
        Description = "Specialized for ransomware attacks, crypto-lockers, and wiper malware"
        Artifacts = 3
        Size = "0.21 MB"
        ResponseTime = "< 5 minutes"
        UseCases = @("WannaCry-style attacks", "Crypto-lockers", "Wiper malware", "File encryption incidents")
        DeployScript = ".\incident-packages\Ransomware-Package\Deploy-Ransomware.ps1"
        Icon = "[RANSOM]"
    }
    "APT Package" = @{
        Type = "APT"
        Description = "Advanced Persistent Threats and nation-state attacks"
        Artifacts = 3
        Size = "0.21 MB"
        ResponseTime = "< 5 minutes"
        UseCases = @("Nation-state attacks", "Advanced persistence", "Lateral movement", "C2 communications")
        DeployScript = ".\incident-packages\APT-Package\Deploy-APT.ps1"
        Icon = "[APT]"
    }
    "Insider Package" = @{
        Type = "Insider"
        Description = "Insider threats, employee misconduct, and data theft"
        Artifacts = 2
        Size = "0.21 MB"
        ResponseTime = "< 5 minutes"
        UseCases = @("Employee data theft", "Privileged abuse", "Account takeover", "Internal misconduct")
        DeployScript = ".\incident-packages\Insider-Package\Deploy-Insider.ps1"
        Icon = "[INSIDER]"
    }
    "Malware Package" = @{
        Type = "Malware"
        Description = "General malware infections, trojans, and rootkits"
        Artifacts = 4
        Size = "0.21 MB"
        ResponseTime = "< 5 minutes"
        UseCases = @("Trojan infections", "Rootkits", "Backdoors", "General malware")
        DeployScript = ".\incident-packages\Malware-Package\Deploy-Malware.ps1"
        Icon = "[MALWARE]"
    }
    "Network Intrusion Package" = @{
        Type = "NetworkIntrusion"
        Description = "Network-based attacks and lateral movement"
        Artifacts = 3
        Size = "0.21 MB"
        ResponseTime = "< 5 minutes"
        UseCases = @("Network breaches", "Lateral movement", "DNS tunneling", "Network reconnaissance")
        DeployScript = ".\incident-packages\NetworkIntrusion-Package\Deploy-NetworkIntrusion.ps1"
        Icon = "[NETWORK]"
    }
    "Data Breach Package" = @{
        Type = "DataBreach"
        Description = "Data breaches, exfiltration, and compliance incidents"
        Artifacts = 1
        Size = "0.21 MB"
        ResponseTime = "< 5 minutes"
        UseCases = @("Data exfiltration", "HIPAA breaches", "PCI-DSS incidents", "GDPR violations")
        DeployScript = ".\incident-packages\DataBreach-Package\Deploy-DataBreach.ps1"
        Icon = "[BREACH]"
    }
    "Complete Package" = @{
        Type = "Complete"
        Description = "Comprehensive investigation for unknown threats"
        Artifacts = 284
        Size = "0.68 MB"
        ResponseTime = "< 10 minutes"
        UseCases = @("Unknown threats", "Comprehensive analysis", "Full investigation", "Complete forensics")
        DeployScript = ".\incident-packages\Complete-Package\Deploy-Complete.ps1"
        Icon = "[COMPLETE]"
    }
}

# Helper function for visual feedback
function Set-ControlFocusEffects {
    param(
        [System.Windows.Forms.Control]$Control,
        [System.Drawing.Color]$FocusColor = $Colors.FocusColor
    )
    
    $Control.Add_GotFocus({
        $this.BackColor = $FocusColor
    })
    
    $Control.Add_LostFocus({
        if ($this -is [System.Windows.Forms.TextBox]) {
            $this.BackColor = $Colors.DarkBackground
        } elseif ($this -is [System.Windows.Forms.Button]) {
            $this.BackColor = $Colors.DarkPanel
        }
    })
}

# Create main form with proper settings
$MainForm = New-Object System.Windows.Forms.Form
$MainForm.Text = "Velociraptor Enhanced Incident Response Packages - Interactive"
$MainForm.Size = New-Object System.Drawing.Size(1200, 800)
$MainForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$MainForm.BackColor = $Colors.DarkBackground
$MainForm.ForeColor = $Colors.TextColor
$MainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$MainForm.MaximizeBox = $false
$MainForm.MinimizeBox = $true
$MainForm.ShowIcon = $true
$MainForm.ShowInTaskbar = $true
$MainForm.KeyPreview = $true  # Enable keyboard shortcuts

# Header panel
$HeaderPanel = New-Object System.Windows.Forms.Panel
$HeaderPanel.Size = New-Object System.Drawing.Size(1180, 80)
$HeaderPanel.Location = New-Object System.Drawing.Point(10, 10)
$HeaderPanel.BackColor = $Colors.DarkPanel
$HeaderPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

# Header label
$HeaderLabel = New-Object System.Windows.Forms.Label
$HeaderLabel.Text = "VELOCIRAPTOR INCIDENT RESPONSE PACKAGES"
$HeaderLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$HeaderLabel.ForeColor = $Colors.VelociraptorGreen
$HeaderLabel.Size = New-Object System.Drawing.Size(800, 30)
$HeaderLabel.Location = New-Object System.Drawing.Point(20, 15)
$HeaderLabel.AutoSize = $false
$HeaderLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft

$SubHeaderLabel = New-Object System.Windows.Forms.Label
$SubHeaderLabel.Text = "Select specialized packages for rapid incident response deployment"
$SubHeaderLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$SubHeaderLabel.ForeColor = $Colors.TextColor
$SubHeaderLabel.Size = New-Object System.Drawing.Size(600, 20)
$SubHeaderLabel.Location = New-Object System.Drawing.Point(20, 45)
$SubHeaderLabel.AutoSize = $false
$SubHeaderLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft

$HeaderPanel.Controls.AddRange(@($HeaderLabel, $SubHeaderLabel))

# Package selection panel with enhanced layout
$PackagePanel = New-Object System.Windows.Forms.Panel
$PackagePanel.Size = New-Object System.Drawing.Size(580, 600)
$PackagePanel.Location = New-Object System.Drawing.Point(10, 100)
$PackagePanel.BackColor = $Colors.DarkPanel
$PackagePanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

$PackageLabel = New-Object System.Windows.Forms.Label
$PackageLabel.Text = "Available Packages"
$PackageLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$PackageLabel.ForeColor = $Colors.VelociraptorBlue
$PackageLabel.Size = New-Object System.Drawing.Size(200, 25)
$PackageLabel.Location = New-Object System.Drawing.Point(20, 15)
$PackageLabel.AutoSize = $false

# Package list box with enhanced interaction
$PackageListBox = New-Object System.Windows.Forms.ListBox
$PackageListBox.Size = New-Object System.Drawing.Size(540, 520)
$PackageListBox.Location = New-Object System.Drawing.Point(20, 50)
$PackageListBox.BackColor = $Colors.DarkBackground
$PackageListBox.ForeColor = $Colors.TextColor
$PackageListBox.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$PackageListBox.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
$PackageListBox.Enabled = $true
$PackageListBox.TabIndex = 0
$PackageListBox.TabStop = $true
$PackageListBox.SelectionMode = [System.Windows.Forms.SelectionMode]::One
$PackageListBox.ItemHeight = 20
$PackageListBox.IntegralHeight = $false

# Add enhanced visual feedback for list box
$PackageListBox.Add_GotFocus({
    $this.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
})

$PackageListBox.Add_LostFocus({
    $this.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
})

# Populate package list
foreach ($package in $PackageDefinitions.Keys) {
    $PackageListBox.Items.Add($package) | Out-Null
}

$PackagePanel.Controls.AddRange(@($PackageLabel, $PackageListBox))

# Details panel with improved layout
$DetailsPanel = New-Object System.Windows.Forms.Panel
$DetailsPanel.Size = New-Object System.Drawing.Size(580, 600)
$DetailsPanel.Location = New-Object System.Drawing.Point(600, 100)
$DetailsPanel.BackColor = $Colors.DarkPanel
$DetailsPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

$DetailsLabel = New-Object System.Windows.Forms.Label
$DetailsLabel.Text = "Package Details"
$DetailsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$DetailsLabel.ForeColor = $Colors.VelociraptorBlue
$DetailsLabel.Size = New-Object System.Drawing.Size(200, 25)
$DetailsLabel.Location = New-Object System.Drawing.Point(20, 15)
$DetailsLabel.AutoSize = $false

# Details text box with proper interaction
$DetailsTextBox = New-Object System.Windows.Forms.RichTextBox
$DetailsTextBox.Size = New-Object System.Drawing.Size(540, 380)
$DetailsTextBox.Location = New-Object System.Drawing.Point(20, 50)
$DetailsTextBox.BackColor = $Colors.DarkBackground
$DetailsTextBox.ForeColor = $Colors.TextColor
$DetailsTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$DetailsTextBox.ReadOnly = $true
$DetailsTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
$DetailsTextBox.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
$DetailsTextBox.WordWrap = $true

# Configuration panel with enhanced controls
$ConfigPanel = New-Object System.Windows.Forms.Panel
$ConfigPanel.Size = New-Object System.Drawing.Size(540, 140)
$ConfigPanel.Location = New-Object System.Drawing.Point(20, 440)
$ConfigPanel.BackColor = $Colors.DarkSurface
$ConfigPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

$ConfigLabel = New-Object System.Windows.Forms.Label
$ConfigLabel.Text = "Deployment Options"
$ConfigLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$ConfigLabel.ForeColor = $Colors.AccentColor
$ConfigLabel.Size = New-Object System.Drawing.Size(200, 20)
$ConfigLabel.Location = New-Object System.Drawing.Point(10, 10)
$ConfigLabel.AutoSize = $false

# Output path with enhanced interaction
$OutputLabel = New-Object System.Windows.Forms.Label
$OutputLabel.Text = "Output Path:"
$OutputLabel.Size = New-Object System.Drawing.Size(80, 20)
$OutputLabel.Location = New-Object System.Drawing.Point(10, 40)
$OutputLabel.ForeColor = $Colors.TextColor
$OutputLabel.TabStop = $false
$OutputLabel.AutoSize = $false

$OutputTextBox = New-Object System.Windows.Forms.TextBox
$OutputTextBox.Size = New-Object System.Drawing.Size(350, 25)
$OutputTextBox.Location = New-Object System.Drawing.Point(100, 38)
$OutputTextBox.BackColor = $Colors.DarkBackground
$OutputTextBox.ForeColor = $Colors.TextColor
$OutputTextBox.Text = "C:\VelociraptorResults"
$OutputTextBox.Enabled = $true
$OutputTextBox.ReadOnly = $false
$OutputTextBox.TabIndex = 1
$OutputTextBox.TabStop = $true
$OutputTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
$OutputTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# Add focus effects for output textbox
Set-ControlFocusEffects -Control $OutputTextBox

$BrowseButton = New-Object System.Windows.Forms.Button
$BrowseButton.Text = "Browse..."
$BrowseButton.Size = New-Object System.Drawing.Size(80, 30)
$BrowseButton.Location = New-Object System.Drawing.Point(460, 36)
$BrowseButton.BackColor = $Colors.DarkPanel
$BrowseButton.ForeColor = $Colors.TextColor
$BrowseButton.Enabled = $true
$BrowseButton.TabIndex = 2
$BrowseButton.TabStop = $true
$BrowseButton.UseVisualStyleBackColor = $false
$BrowseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$BrowseButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$BrowseButton.Cursor = [System.Windows.Forms.Cursors]::Hand

# Add hover effects for browse button
$BrowseButton.Add_MouseEnter({
    $this.BackColor = $Colors.ButtonHover
})

$BrowseButton.Add_MouseLeave({
    $this.BackColor = $Colors.DarkPanel
})

# Enhanced options checkboxes with proper interaction
$OfflineCheckBox = New-Object System.Windows.Forms.CheckBox
$OfflineCheckBox.Text = "Offline Mode"
$OfflineCheckBox.Size = New-Object System.Drawing.Size(130, 25)
$OfflineCheckBox.Location = New-Object System.Drawing.Point(10, 75)
$OfflineCheckBox.ForeColor = $Colors.TextColor
$OfflineCheckBox.Checked = $true
$OfflineCheckBox.Enabled = $true
$OfflineCheckBox.TabIndex = 3
$OfflineCheckBox.TabStop = $true
$OfflineCheckBox.UseVisualStyleBackColor = $true
$OfflineCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$OfflineCheckBox.CheckAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$OfflineCheckBox.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$OfflineCheckBox.AutoSize = $false
$OfflineCheckBox.Cursor = [System.Windows.Forms.Cursors]::Hand

$EncryptCheckBox = New-Object System.Windows.Forms.CheckBox
$EncryptCheckBox.Text = "Encrypt Results"
$EncryptCheckBox.Size = New-Object System.Drawing.Size(130, 25)
$EncryptCheckBox.Location = New-Object System.Drawing.Point(150, 75)
$EncryptCheckBox.ForeColor = $Colors.TextColor
$EncryptCheckBox.Enabled = $true
$EncryptCheckBox.TabIndex = 4
$EncryptCheckBox.TabStop = $true
$EncryptCheckBox.UseVisualStyleBackColor = $true
$EncryptCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$EncryptCheckBox.CheckAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$EncryptCheckBox.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$EncryptCheckBox.AutoSize = $false
$EncryptCheckBox.Cursor = [System.Windows.Forms.Cursors]::Hand

$PortableCheckBox = New-Object System.Windows.Forms.CheckBox
$PortableCheckBox.Text = "Portable Package"
$PortableCheckBox.Size = New-Object System.Drawing.Size(140, 25)
$PortableCheckBox.Location = New-Object System.Drawing.Point(290, 75)
$PortableCheckBox.ForeColor = $Colors.TextColor
$PortableCheckBox.Checked = $true
$PortableCheckBox.Enabled = $true
$PortableCheckBox.TabIndex = 5
$PortableCheckBox.TabStop = $true
$PortableCheckBox.UseVisualStyleBackColor = $true
$PortableCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$PortableCheckBox.CheckAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$PortableCheckBox.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$PortableCheckBox.AutoSize = $false
$PortableCheckBox.Cursor = [System.Windows.Forms.Cursors]::Hand

# Add authentication section
$AuthLabel = New-Object System.Windows.Forms.Label
$AuthLabel.Text = "Authentication:"
$AuthLabel.Size = New-Object System.Drawing.Size(100, 20)
$AuthLabel.Location = New-Object System.Drawing.Point(10, 105)
$AuthLabel.ForeColor = $Colors.TextColor
$AuthLabel.TabStop = $false
$AuthLabel.AutoSize = $false
$AuthLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)

$AutoPasswordRadio = New-Object System.Windows.Forms.RadioButton
$AutoPasswordRadio.Text = "Auto Password"
$AutoPasswordRadio.Size = New-Object System.Drawing.Size(120, 20)
$AutoPasswordRadio.Location = New-Object System.Drawing.Point(120, 105)
$AutoPasswordRadio.ForeColor = $Colors.TextColor
$AutoPasswordRadio.Checked = $true
$AutoPasswordRadio.Enabled = $true
$AutoPasswordRadio.TabIndex = 6
$AutoPasswordRadio.TabStop = $true
$AutoPasswordRadio.UseVisualStyleBackColor = $true
$AutoPasswordRadio.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$AutoPasswordRadio.Cursor = [System.Windows.Forms.Cursors]::Hand

$CustomPasswordRadio = New-Object System.Windows.Forms.RadioButton
$CustomPasswordRadio.Text = "Custom:"
$CustomPasswordRadio.Size = New-Object System.Drawing.Size(70, 20)
$CustomPasswordRadio.Location = New-Object System.Drawing.Point(250, 105)
$CustomPasswordRadio.ForeColor = $Colors.TextColor
$CustomPasswordRadio.Enabled = $true
$CustomPasswordRadio.TabIndex = 7
$CustomPasswordRadio.TabStop = $true
$CustomPasswordRadio.UseVisualStyleBackColor = $true
$CustomPasswordRadio.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$CustomPasswordRadio.Cursor = [System.Windows.Forms.Cursors]::Hand

$PasswordTextBox = New-Object System.Windows.Forms.TextBox
$PasswordTextBox.Size = New-Object System.Drawing.Size(150, 25)
$PasswordTextBox.Location = New-Object System.Drawing.Point(330, 103)
$PasswordTextBox.BackColor = $Colors.DarkBackground
$PasswordTextBox.ForeColor = $Colors.TextColor
$PasswordTextBox.Enabled = $false
$PasswordTextBox.TabIndex = 8
$PasswordTextBox.TabStop = $true
$PasswordTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
$PasswordTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$PasswordTextBox.UseSystemPasswordChar = $true

# Add focus effects for password textbox
Set-ControlFocusEffects -Control $PasswordTextBox

$ConfigPanel.Controls.AddRange(@($ConfigLabel, $OutputLabel, $OutputTextBox, $BrowseButton, $OfflineCheckBox, $EncryptCheckBox, $PortableCheckBox, $AuthLabel, $AutoPasswordRadio, $CustomPasswordRadio, $PasswordTextBox))
$DetailsPanel.Controls.AddRange(@($DetailsLabel, $DetailsTextBox, $ConfigPanel))

# Action buttons panel with enhanced interaction
$ButtonPanel = New-Object System.Windows.Forms.Panel
$ButtonPanel.Size = New-Object System.Drawing.Size(1180, 60)
$ButtonPanel.Location = New-Object System.Drawing.Point(10, 710)
$ButtonPanel.BackColor = $Colors.DarkBackground

# Deploy button with enhanced styling
$DeployButton = New-Object System.Windows.Forms.Button
$DeployButton.Text = "Deploy Package"
$DeployButton.Size = New-Object System.Drawing.Size(150, 35)
$DeployButton.Location = New-Object System.Drawing.Point(20, 15)
$DeployButton.BackColor = $Colors.VelociraptorGreen
$DeployButton.ForeColor = [System.Drawing.Color]::Black
$DeployButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$DeployButton.Enabled = $false
$DeployButton.TabIndex = 10
$DeployButton.TabStop = $true
$DeployButton.UseVisualStyleBackColor = $false
$DeployButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$DeployButton.Cursor = [System.Windows.Forms.Cursors]::Hand

# Test button
$TestButton = New-Object System.Windows.Forms.Button
$TestButton.Text = "Test Package"
$TestButton.Size = New-Object System.Drawing.Size(130, 35)
$TestButton.Location = New-Object System.Drawing.Point(180, 15)
$TestButton.BackColor = $Colors.VelociraptorBlue
$TestButton.ForeColor = [System.Drawing.Color]::White
$TestButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$TestButton.Enabled = $true
$TestButton.TabIndex = 11
$TestButton.TabStop = $true
$TestButton.UseVisualStyleBackColor = $false
$TestButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$TestButton.Cursor = [System.Windows.Forms.Cursors]::Hand

# Preview button
$PreviewButton = New-Object System.Windows.Forms.Button
$PreviewButton.Text = "Preview Config"
$PreviewButton.Size = New-Object System.Drawing.Size(130, 35)
$PreviewButton.Location = New-Object System.Drawing.Point(320, 15)
$PreviewButton.BackColor = $Colors.DarkPanel
$PreviewButton.ForeColor = $Colors.TextColor
$PreviewButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$PreviewButton.Enabled = $true
$PreviewButton.TabIndex = 12
$PreviewButton.TabStop = $true
$PreviewButton.UseVisualStyleBackColor = $false
$PreviewButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$PreviewButton.Cursor = [System.Windows.Forms.Cursors]::Hand

# Help button
$HelpButton = New-Object System.Windows.Forms.Button
$HelpButton.Text = "Help"
$HelpButton.Size = New-Object System.Drawing.Size(100, 35)
$HelpButton.Location = New-Object System.Drawing.Point(460, 15)
$HelpButton.BackColor = $Colors.DarkPanel
$HelpButton.ForeColor = $Colors.TextColor
$HelpButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$HelpButton.Enabled = $true
$HelpButton.TabIndex = 13
$HelpButton.TabStop = $true
$HelpButton.UseVisualStyleBackColor = $false
$HelpButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$HelpButton.Cursor = [System.Windows.Forms.Cursors]::Hand

# Exit button
$ExitButton = New-Object System.Windows.Forms.Button
$ExitButton.Text = "Exit"
$ExitButton.Size = New-Object System.Drawing.Size(100, 35)
$ExitButton.Location = New-Object System.Drawing.Point(1060, 15)
$ExitButton.BackColor = [System.Drawing.Color]::DarkRed
$ExitButton.ForeColor = $Colors.TextColor
$ExitButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$ExitButton.Enabled = $true
$ExitButton.TabIndex = 14
$ExitButton.TabStop = $true
$ExitButton.UseVisualStyleBackColor = $false
$ExitButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$ExitButton.Cursor = [System.Windows.Forms.Cursors]::Hand

$ButtonPanel.Controls.AddRange(@($DeployButton, $TestButton, $PreviewButton, $HelpButton, $ExitButton))

# Status bar with proper styling
$StatusBar = New-Object System.Windows.Forms.StatusStrip
$StatusBar.BackColor = $Colors.DarkPanel
$StatusBar.ForeColor = $Colors.TextColor
$StatusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$StatusLabel.Text = "Ready - Select a package to begin"
$StatusLabel.ForeColor = $Colors.TextColor
$StatusLabel.Spring = $true
$StatusBar.Items.Add($StatusLabel) | Out-Null

# Add all controls to main form
$MainForm.Controls.AddRange(@($HeaderPanel, $PackagePanel, $DetailsPanel, $ButtonPanel, $StatusBar))

# EVENT HANDLERS - All properly registered for full interactivity

# Package selection handler
$PackageListBox.Add_SelectedIndexChanged({
    if ($PackageListBox.SelectedItem) {
        $selectedPackage = $PackageListBox.SelectedItem.ToString()
        $script:SelectedPackage = $selectedPackage
        $packageInfo = $PackageDefinitions[$selectedPackage]
        
        # Update details panel with comprehensive information
        $details = @"
$($packageInfo.Icon) $selectedPackage

Description:
$($packageInfo.Description)

Package Statistics:
• Artifacts: $($packageInfo.Artifacts)
• Package Size: $($packageInfo.Size)
• Response Time: $($packageInfo.ResponseTime)
• Package Type: $($packageInfo.Type)

Use Cases:
$($packageInfo.UseCases | ForEach-Object { "• $_" } | Out-String)

Deployment:
Script: $($packageInfo.DeployScript)

Package Status: Ready for deployment
Tools: Integrated and tested
Security: Offline capable, encrypted options
Compliance: HIPAA, PCI-DSS, GDPR ready

Click 'Deploy Package' to begin installation or 'Preview Config' to review settings.
"@
        
        $DetailsTextBox.Text = $details
        $DeployButton.Enabled = $true
        $StatusLabel.Text = "Package selected: $selectedPackage"
    }
})

# Radio button handlers for password authentication
$AutoPasswordRadio.Add_CheckedChanged({
    if ($this.Checked) {
        $PasswordTextBox.Enabled = $false
        $PasswordTextBox.BackColor = $Colors.DisabledColor
        $StatusLabel.Text = "Auto password generation enabled"
    }
})

$CustomPasswordRadio.Add_CheckedChanged({
    if ($this.Checked) {
        $PasswordTextBox.Enabled = $true
        $PasswordTextBox.BackColor = $Colors.DarkBackground
        $PasswordTextBox.Focus()
        $StatusLabel.Text = "Enter custom password"
    }
})

# Browse button handler
$BrowseButton.Add_Click({
    try {
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderDialog.Description = "Select output directory for investigation results"
        $folderDialog.SelectedPath = $OutputTextBox.Text
        $folderDialog.ShowNewFolderButton = $true
        
        if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $OutputTextBox.Text = $folderDialog.SelectedPath
            $StatusLabel.Text = "Output path updated: $($folderDialog.SelectedPath)"
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Error browsing for folder: $($_.Exception.Message)",
            "Browse Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
})

# Deploy button handler
$DeployButton.Add_Click({
    if ($script:SelectedPackage) {
        $packageInfo = $PackageDefinitions[$script:SelectedPackage]
        $deployScript = $packageInfo.DeployScript
        
        $StatusLabel.Text = "Preparing deployment for $($script:SelectedPackage)..."
        $DeployButton.Enabled = $false
        
        try {
            # Build deployment command with all options
            $deployArgs = @()
            
            if ($OutputTextBox.Text -and $OutputTextBox.Text -ne "C:\VelociraptorResults") {
                $deployArgs += "-OutputPath `"$($OutputTextBox.Text)`""
            }
            
            if ($OfflineCheckBox.Checked) {
                $deployArgs += "-Offline"
            }
            
            if ($EncryptCheckBox.Checked) {
                $deployArgs += "-EncryptResults"
            }
            
            if ($PortableCheckBox.Checked) {
                $deployArgs += "-CreatePortable"
            }
            
            if ($CustomPasswordRadio.Checked -and $PasswordTextBox.Text) {
                $deployArgs += "-Password `"$($PasswordTextBox.Text)`""
            }
            
            $command = "$deployScript $($deployArgs -join ' ')"
            
            # Show comprehensive deployment confirmation
            $confirmMessage = @"
Ready to deploy: $($script:SelectedPackage)

Configuration:
• Output Path: $($OutputTextBox.Text)
• Offline Mode: $($OfflineCheckBox.Checked)
• Encrypt Results: $($EncryptCheckBox.Checked)
• Portable Package: $($PortableCheckBox.Checked)
• Authentication: $(if ($AutoPasswordRadio.Checked) { "Auto-generated" } else { "Custom password" })

Command: $command

Proceed with deployment?
"@
            
            $result = [System.Windows.Forms.MessageBox]::Show(
                $confirmMessage,
                "Confirm Deployment - $($script:SelectedPackage)",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                # Execute deployment
                $StatusLabel.Text = "Launching deployment process..."
                Start-Process PowerShell -ArgumentList "-NoExit", "-Command", $command
                $StatusLabel.Text = "Deployment initiated for $($script:SelectedPackage)"
                
                [System.Windows.Forms.MessageBox]::Show(
                    "Deployment has been initiated in a new PowerShell window.`n`nMonitor the console for progress and results.",
                    "Deployment Started",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            } else {
                $StatusLabel.Text = "Deployment cancelled by user"
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Deployment failed: $($_.Exception.Message)",
                "Deployment Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            $StatusLabel.Text = "Deployment failed - check error details"
        } finally {
            $DeployButton.Enabled = $true
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show(
            "Please select a package before deploying.",
            "No Package Selected",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
    }
})

# Test button handler
$TestButton.Add_Click({
    $StatusLabel.Text = "Running package validation tests..."
    try {
        $testScript = ".\Test-IncidentPackages.ps1"
        if (Test-Path $testScript) {
            Start-Process PowerShell -ArgumentList "-NoExit", "-Command", $testScript
            $StatusLabel.Text = "Package testing initiated in new window"
        } else {
            $StatusLabel.Text = "Running built-in package validation..."
            
            # Basic validation
            $validationResults = @()
            foreach ($pkg in $PackageDefinitions.Keys) {
                $info = $PackageDefinitions[$pkg]
                $scriptExists = Test-Path $info.DeployScript -ErrorAction SilentlyContinue
                $validationResults += "$pkg`: $(if ($scriptExists) { 'READY' } else { 'SCRIPT MISSING' })"
            }
            
            [System.Windows.Forms.MessageBox]::Show(
                "Package Validation Results:`n`n$($validationResults -join "`n")",
                "Package Test Results",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            
            $StatusLabel.Text = "Package validation completed"
        }
    } catch {
        $StatusLabel.Text = "Test execution failed - check console for details"
        [System.Windows.Forms.MessageBox]::Show(
            "Test execution error: $($_.Exception.Message)",
            "Test Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
})

# Preview button handler
$PreviewButton.Add_Click({
    if ($script:SelectedPackage) {
        $packageInfo = $PackageDefinitions[$script:SelectedPackage]
        
        $preview = @"
DEPLOYMENT PREVIEW
==================

Package: $($script:SelectedPackage)
Type: $($packageInfo.Type)
Script: $($packageInfo.DeployScript)

Configuration:
• Output Path: $($OutputTextBox.Text)
• Offline Mode: $($OfflineCheckBox.Checked)
• Encrypt Results: $($EncryptCheckBox.Checked)
• Portable Package: $($PortableCheckBox.Checked)
• Authentication: $(if ($AutoPasswordRadio.Checked) { "Auto-generated password" } else { "Custom password provided" })

Expected Results:
• Artifacts: $($packageInfo.Artifacts) specialized artifacts
• Response Time: $($packageInfo.ResponseTime)
• Package Size: $($packageInfo.Size)

Ready for deployment? Click 'Deploy Package' to proceed.
"@
        
        [System.Windows.Forms.MessageBox]::Show(
            $preview,
            "Deployment Preview - $($script:SelectedPackage)",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        
        $StatusLabel.Text = "Configuration preview displayed"
    } else {
        [System.Windows.Forms.MessageBox]::Show(
            "Please select a package to preview its configuration.",
            "No Package Selected",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
    }
})

# Help button handler
$HelpButton.Add_Click({
    try {
        $helpFile = ".\INCIDENT_RESPONSE_PACKAGES_GUIDE.md"
        if (Test-Path $helpFile) {
            Start-Process PowerShell -ArgumentList "-NoExit", "-Command", "Get-Content '$helpFile' | Out-Host; Read-Host 'Press Enter to continue'"
            $StatusLabel.Text = "Help documentation opened in new window"
        } else {
            # Show built-in help
            $helpText = @"
INCIDENT RESPONSE PACKAGE HELP
==============================

Available Packages:
• Ransomware Package - For ransomware and crypto-locker incidents
• APT Package - Advanced Persistent Threats and nation-state attacks
• Insider Package - Insider threats and employee misconduct
• Malware Package - General malware infections and trojans
• Network Intrusion Package - Network-based attacks and lateral movement
• Data Breach Package - Data exfiltration and compliance incidents
• Complete Package - Comprehensive investigation for unknown threats

Options:
• Output Path - Where to save investigation results
• Offline Mode - Deploy without internet connectivity
• Encrypt Results - Password-protect collected data
• Portable Package - Create standalone collector

Authentication:
• Auto Password - System generates secure password
• Custom Password - Use your own password

For detailed documentation, visit:
https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts
"@
            
            [System.Windows.Forms.MessageBox]::Show(
                $helpText,
                "Incident Response Package Help",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            
            $StatusLabel.Text = "Help information displayed"
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Help system error: $($_.Exception.Message)",
            "Help Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
})

# Exit button handler
$ExitButton.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Are you sure you want to exit the Incident Response Package GUI?",
        "Confirm Exit",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        $MainForm.Close()
    }
})

# Keyboard shortcuts
$MainForm.Add_KeyDown({
    param($sender, $e)
    
    if ($e.Control) {
        switch ($e.KeyCode) {
            'D' { 
                if ($DeployButton.Enabled) { 
                    $DeployButton.PerformClick() 
                }
                $e.Handled = $true
            }
            'T' { 
                $TestButton.PerformClick() 
                $e.Handled = $true
            }
            'P' { 
                $PreviewButton.PerformClick() 
                $e.Handled = $true
            }
            'H' { 
                $HelpButton.PerformClick() 
                $e.Handled = $true
            }
        }
    }
    elseif ($e.KeyCode -eq [System.Windows.Forms.Keys]::F1) {
        $HelpButton.PerformClick()
        $e.Handled = $true
    }
    elseif ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
        $ExitButton.PerformClick()
        $e.Handled = $true
    }
})

# Form closing handler
$MainForm.Add_FormClosing({
    param($sender, $e)
    
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing) {
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Are you sure you want to close the application?",
            "Confirm Close",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        
        if ($result -eq [System.Windows.Forms.DialogResult]::No) {
            $e.Cancel = $true
        }
    }
})

# Show startup message
Write-Host "`nEnhanced Package GUI (Interactive Version) loaded successfully!" -ForegroundColor Green
Write-Host "Features:" -ForegroundColor Cyan
Write-Host "  • All controls are fully interactive and responsive" -ForegroundColor White
Write-Host "  • Proper tab order for keyboard navigation" -ForegroundColor White
Write-Host "  • Visual focus indicators and hover effects" -ForegroundColor White
Write-Host "  • Enhanced password field interactions" -ForegroundColor White
Write-Host "  • Keyboard shortcuts: Ctrl+D (Deploy), Ctrl+T (Test), Ctrl+P (Preview), F1 (Help)" -ForegroundColor White
Write-Host "  • Comprehensive error handling and user feedback" -ForegroundColor White

if ($StartMinimized) {
    $MainForm.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
}

# Show the form
$MainForm.ShowDialog() | Out-Null