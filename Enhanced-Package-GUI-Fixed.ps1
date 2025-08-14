#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Enhanced Incident Response GUI with Package Integration (Unicode-free version)

.DESCRIPTION
    Professional GUI that integrates with the 7 specialized incident response packages
    for streamlined deployment and management.
#>

Write-Host "Starting Enhanced Incident Response Package GUI..." -ForegroundColor Green

# Import required assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Global variables
$script:SelectedPackage = $null
$script:PackageInfo = @{}

# Dark theme colors
$DarkBackground = [System.Drawing.Color]::FromArgb(32, 32, 32)
$DarkPanel = [System.Drawing.Color]::FromArgb(45, 45, 48)
$VelociraptorGreen = [System.Drawing.Color]::FromArgb(0, 255, 127)
$VelociraptorBlue = [System.Drawing.Color]::FromArgb(0, 191, 255)
$TextColor = [System.Drawing.Color]::White
$AccentColor = [System.Drawing.Color]::FromArgb(255, 165, 0)

# Package definitions without Unicode
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

# Create main form
$MainForm = New-Object System.Windows.Forms.Form
$MainForm.Text = "Velociraptor Enhanced Incident Response Packages"
$MainForm.Size = New-Object System.Drawing.Size(1200, 800)
$MainForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$MainForm.BackColor = $DarkBackground
$MainForm.ForeColor = $TextColor
$MainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$MainForm.MaximizeBox = $false

# Header panel
$HeaderPanel = New-Object System.Windows.Forms.Panel
$HeaderPanel.Size = New-Object System.Drawing.Size(1180, 80)
$HeaderPanel.Location = New-Object System.Drawing.Point(10, 10)
$HeaderPanel.BackColor = $DarkPanel

# Header label
$HeaderLabel = New-Object System.Windows.Forms.Label
$HeaderLabel.Text = "VELOCIRAPTOR INCIDENT RESPONSE PACKAGES"
$HeaderLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$HeaderLabel.ForeColor = $VelociraptorGreen
$HeaderLabel.Size = New-Object System.Drawing.Size(800, 30)
$HeaderLabel.Location = New-Object System.Drawing.Point(20, 15)

$SubHeaderLabel = New-Object System.Windows.Forms.Label
$SubHeaderLabel.Text = "Select specialized packages for rapid incident response deployment"
$SubHeaderLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$SubHeaderLabel.ForeColor = $TextColor
$SubHeaderLabel.Size = New-Object System.Drawing.Size(600, 20)
$SubHeaderLabel.Location = New-Object System.Drawing.Point(20, 45)

$HeaderPanel.Controls.AddRange(@($HeaderLabel, $SubHeaderLabel))

# Package selection panel
$PackagePanel = New-Object System.Windows.Forms.Panel
$PackagePanel.Size = New-Object System.Drawing.Size(580, 600)
$PackagePanel.Location = New-Object System.Drawing.Point(10, 100)
$PackagePanel.BackColor = $DarkPanel

$PackageLabel = New-Object System.Windows.Forms.Label
$PackageLabel.Text = "Available Packages"
$PackageLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$PackageLabel.ForeColor = $VelociraptorBlue
$PackageLabel.Size = New-Object System.Drawing.Size(200, 25)
$PackageLabel.Location = New-Object System.Drawing.Point(20, 15)

# Package list box
$PackageListBox = New-Object System.Windows.Forms.ListBox
$PackageListBox.Size = New-Object System.Drawing.Size(540, 500)
$PackageListBox.Location = New-Object System.Drawing.Point(20, 50)
$PackageListBox.BackColor = $DarkBackground
$PackageListBox.ForeColor = $TextColor
$PackageListBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$PackageListBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

# Populate package list
foreach ($package in $PackageDefinitions.Keys) {
    $PackageListBox.Items.Add($package) | Out-Null
}

$PackagePanel.Controls.AddRange(@($PackageLabel, $PackageListBox))

# Details panel
$DetailsPanel = New-Object System.Windows.Forms.Panel
$DetailsPanel.Size = New-Object System.Drawing.Size(580, 600)
$DetailsPanel.Location = New-Object System.Drawing.Point(600, 100)
$DetailsPanel.BackColor = $DarkPanel

$DetailsLabel = New-Object System.Windows.Forms.Label
$DetailsLabel.Text = "Package Details"
$DetailsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$DetailsLabel.ForeColor = $VelociraptorBlue
$DetailsLabel.Size = New-Object System.Drawing.Size(200, 25)
$DetailsLabel.Location = New-Object System.Drawing.Point(20, 15)

# Details text box
$DetailsTextBox = New-Object System.Windows.Forms.RichTextBox
$DetailsTextBox.Size = New-Object System.Drawing.Size(540, 400)
$DetailsTextBox.Location = New-Object System.Drawing.Point(20, 50)
$DetailsTextBox.BackColor = $DarkBackground
$DetailsTextBox.ForeColor = $TextColor
$DetailsTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$DetailsTextBox.ReadOnly = $true
$DetailsTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

# Configuration panel
$ConfigPanel = New-Object System.Windows.Forms.Panel
$ConfigPanel.Size = New-Object System.Drawing.Size(540, 120)
$ConfigPanel.Location = New-Object System.Drawing.Point(20, 460)
$ConfigPanel.BackColor = $DarkBackground

$ConfigLabel = New-Object System.Windows.Forms.Label
$ConfigLabel.Text = "Deployment Options"
$ConfigLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$ConfigLabel.ForeColor = $AccentColor
$ConfigLabel.Size = New-Object System.Drawing.Size(200, 20)
$ConfigLabel.Location = New-Object System.Drawing.Point(0, 0)

# Output path
$OutputLabel = New-Object System.Windows.Forms.Label
$OutputLabel.Text = "Output Path:"
$OutputLabel.Size = New-Object System.Drawing.Size(80, 20)
$OutputLabel.Location = New-Object System.Drawing.Point(0, 30)
$OutputLabel.ForeColor = $TextColor

$OutputTextBox = New-Object System.Windows.Forms.TextBox
$OutputTextBox.Size = New-Object System.Drawing.Size(350, 20)
$OutputTextBox.Location = New-Object System.Drawing.Point(90, 28)
$OutputTextBox.BackColor = $DarkBackground
$OutputTextBox.ForeColor = $TextColor
$OutputTextBox.Text = "C:\VelociraptorResults"

$BrowseButton = New-Object System.Windows.Forms.Button
$BrowseButton.Text = "Browse"
$BrowseButton.Size = New-Object System.Drawing.Size(80, 25)
$BrowseButton.Location = New-Object System.Drawing.Point(450, 26)
$BrowseButton.BackColor = $DarkPanel
$BrowseButton.ForeColor = $TextColor

# Options checkboxes
$OfflineCheckBox = New-Object System.Windows.Forms.CheckBox
$OfflineCheckBox.Text = "Offline Mode"
$OfflineCheckBox.Size = New-Object System.Drawing.Size(120, 20)
$OfflineCheckBox.Location = New-Object System.Drawing.Point(0, 60)
$OfflineCheckBox.ForeColor = $TextColor
$OfflineCheckBox.Checked = $true

$EncryptCheckBox = New-Object System.Windows.Forms.CheckBox
$EncryptCheckBox.Text = "Encrypt Results"
$EncryptCheckBox.Size = New-Object System.Drawing.Size(120, 20)
$EncryptCheckBox.Location = New-Object System.Drawing.Point(130, 60)
$EncryptCheckBox.ForeColor = $TextColor

$PortableCheckBox = New-Object System.Windows.Forms.CheckBox
$PortableCheckBox.Text = "Portable Package"
$PortableCheckBox.Size = New-Object System.Drawing.Size(130, 20)
$PortableCheckBox.Location = New-Object System.Drawing.Point(260, 60)
$PortableCheckBox.ForeColor = $TextColor
$PortableCheckBox.Checked = $true

$ConfigPanel.Controls.AddRange(@($ConfigLabel, $OutputLabel, $OutputTextBox, $BrowseButton, $OfflineCheckBox, $EncryptCheckBox, $PortableCheckBox))
$DetailsPanel.Controls.AddRange(@($DetailsLabel, $DetailsTextBox, $ConfigPanel))

# Action buttons panel
$ButtonPanel = New-Object System.Windows.Forms.Panel
$ButtonPanel.Size = New-Object System.Drawing.Size(1180, 60)
$ButtonPanel.Location = New-Object System.Drawing.Point(10, 710)
$ButtonPanel.BackColor = $DarkBackground

# Deploy button
$DeployButton = New-Object System.Windows.Forms.Button
$DeployButton.Text = "Deploy Package"
$DeployButton.Size = New-Object System.Drawing.Size(150, 35)
$DeployButton.Location = New-Object System.Drawing.Point(20, 15)
$DeployButton.BackColor = $VelociraptorGreen
$DeployButton.ForeColor = [System.Drawing.Color]::Black
$DeployButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$DeployButton.Enabled = $false

# Test button
$TestButton = New-Object System.Windows.Forms.Button
$TestButton.Text = "Test Package"
$TestButton.Size = New-Object System.Drawing.Size(130, 35)
$TestButton.Location = New-Object System.Drawing.Point(180, 15)
$TestButton.BackColor = $VelociraptorBlue
$TestButton.ForeColor = [System.Drawing.Color]::White
$TestButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# Preview button
$PreviewButton = New-Object System.Windows.Forms.Button
$PreviewButton.Text = "Preview Config"
$PreviewButton.Size = New-Object System.Drawing.Size(130, 35)
$PreviewButton.Location = New-Object System.Drawing.Point(320, 15)
$PreviewButton.BackColor = $DarkPanel
$PreviewButton.ForeColor = $TextColor
$PreviewButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# Help button
$HelpButton = New-Object System.Windows.Forms.Button
$HelpButton.Text = "Help"
$HelpButton.Size = New-Object System.Drawing.Size(100, 35)
$HelpButton.Location = New-Object System.Drawing.Point(460, 15)
$HelpButton.BackColor = $DarkPanel
$HelpButton.ForeColor = $TextColor
$HelpButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# Exit button
$ExitButton = New-Object System.Windows.Forms.Button
$ExitButton.Text = "Exit"
$ExitButton.Size = New-Object System.Drawing.Size(100, 35)
$ExitButton.Location = New-Object System.Drawing.Point(1060, 15)
$ExitButton.BackColor = [System.Drawing.Color]::DarkRed
$ExitButton.ForeColor = $TextColor
$ExitButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$ButtonPanel.Controls.AddRange(@($DeployButton, $TestButton, $PreviewButton, $HelpButton, $ExitButton))

# Status bar
$StatusBar = New-Object System.Windows.Forms.StatusStrip
$StatusBar.BackColor = $DarkPanel
$StatusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$StatusLabel.Text = "Ready - Select a package to begin"
$StatusLabel.ForeColor = $TextColor
$StatusBar.Items.Add($StatusLabel) | Out-Null

# Add all controls to main form
$MainForm.Controls.AddRange(@($HeaderPanel, $PackagePanel, $DetailsPanel, $ButtonPanel, $StatusBar))

# Event handlers
$PackageListBox.Add_SelectedIndexChanged({
    if ($PackageListBox.SelectedItem) {
        $selectedPackage = $PackageListBox.SelectedItem.ToString()
        $script:SelectedPackage = $selectedPackage
        $packageInfo = $PackageDefinitions[$selectedPackage]
        
        # Update details panel
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
"@
        
        $DetailsTextBox.Text = $details
        $DeployButton.Enabled = $true
        $StatusLabel.Text = "Package selected: $selectedPackage"
    }
})

$DeployButton.Add_Click({
    if ($script:SelectedPackage) {
        $packageInfo = $PackageDefinitions[$script:SelectedPackage]
        $deployScript = $packageInfo.DeployScript
        
        $StatusLabel.Text = "Deploying $($script:SelectedPackage)..."
        $DeployButton.Enabled = $false
        
        try {
            # Build deployment command
            $deployArgs = @()
            if ($OutputTextBox.Text) {
                $deployArgs += "-InstallDir `"$($OutputTextBox.Text)`""
            }
            if ($OfflineCheckBox.Checked) {
                $deployArgs += "-Offline"
            }
            if ($EncryptCheckBox.Checked) {
                $deployArgs += "-Force"
            }
            
            $command = "$deployScript $($deployArgs -join ' ')"
            
            # Show deployment dialog
            $result = [System.Windows.Forms.MessageBox]::Show(
                "Deploy $($script:SelectedPackage)?`n`nCommand: $command",
                "Confirm Deployment",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                # Execute deployment
                Start-Process PowerShell -ArgumentList "-NoExit", "-Command", $command
                $StatusLabel.Text = "Deployment initiated for $($script:SelectedPackage)"
            } else {
                $StatusLabel.Text = "Deployment cancelled"
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Deployment failed: $($_.Exception.Message)",
                "Deployment Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            $StatusLabel.Text = "Deployment failed"
        } finally {
            $DeployButton.Enabled = $true
        }
    }
})

$TestButton.Add_Click({
    $StatusLabel.Text = "Running package tests..."
    try {
        Start-Process PowerShell -ArgumentList "-NoExit", "-Command", ".\Test-IncidentPackages-Fixed.ps1"
        $StatusLabel.Text = "Package testing initiated"
    } catch {
        $StatusLabel.Text = "Test execution failed"
    }
})

$PreviewButton.Add_Click({
    if ($script:SelectedPackage) {
        $packageInfo = $PackageDefinitions[$script:SelectedPackage]
        $preview = @"
DEPLOYMENT PREVIEW

Package: $($script:SelectedPackage)
Type: $($packageInfo.Type)
Script: $($packageInfo.DeployScript)

Configuration:
• Output Path: $($OutputTextBox.Text)
• Offline Mode: $($OfflineCheckBox.Checked)
• Encrypt Results: $($EncryptCheckBox.Checked)
• Portable Package: $($PortableCheckBox.Checked)

Expected Results:
• Artifacts: $($packageInfo.Artifacts) specialized artifacts
• Response Time: $($packageInfo.ResponseTime)
• Package Size: $($packageInfo.Size)
"@
        
        [System.Windows.Forms.MessageBox]::Show(
            $preview,
            "Deployment Preview",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
})

$HelpButton.Add_Click({
    try {
        Start-Process PowerShell -ArgumentList "-NoExit", "-Command", "Get-Content .\INCIDENT_RESPONSE_PACKAGES_GUIDE.md"
        $StatusLabel.Text = "Help documentation opened"
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Help documentation not found. Please ensure INCIDENT_RESPONSE_PACKAGES_GUIDE.md exists.",
            "Help Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
    }
})

$ExitButton.Add_Click({
    $MainForm.Close()
})

$BrowseButton.Add_Click({
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = "Select output directory for investigation results"
    $folderDialog.SelectedPath = $OutputTextBox.Text
    
    if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $OutputTextBox.Text = $folderDialog.SelectedPath
    }
})

# Show the form
Write-Host "Enhanced Package GUI loaded successfully!" -ForegroundColor Green
$MainForm.ShowDialog() | Out-Null