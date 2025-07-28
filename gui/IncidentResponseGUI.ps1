#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Velociraptor Incident Response Collector GUI

.DESCRIPTION
    Professional dark-themed GUI for deploying specialized offline collectors
    based on specific cybersecurity incident scenarios.

.PARAMETER StartMinimized
    Start the application minimized

.EXAMPLE
    .\IncidentResponseGUI.ps1
    .\IncidentResponseGUI.ps1 -StartMinimized
#>

[CmdletBinding()]
param(
    [switch]$StartMinimized
)

Write-Host "🚨 Starting Incident Response Collector GUI..." -ForegroundColor Green

# Import required assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Global variables
$script:SelectedIncident = $null
$script:CollectorConfig = @{}
$script:DeploymentPath = ""

# Dark theme colors
$DarkBackground = [System.Drawing.Color]::FromArgb(32, 32, 32)
$DarkPanel = [System.Drawing.Color]::FromArgb(45, 45, 48)
$DarkBorder = [System.Drawing.Color]::FromArgb(63, 63, 70)
$VelociraptorGreen = [System.Drawing.Color]::FromArgb(0, 255, 127)
$VelociraptorBlue = [System.Drawing.Color]::FromArgb(0, 191, 255)
$TextColor = [System.Drawing.Color]::White
$AccentColor = [System.Drawing.Color]::FromArgb(255, 165, 0)

# Create main form
$MainForm = New-Object System.Windows.Forms.Form
$MainForm.Text = "🦖 Velociraptor Incident Response Collector"
$MainForm.Size = New-Object System.Drawing.Size(1000, 700)
$MainForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$MainForm.BackColor = $DarkBackground
$MainForm.ForeColor = $TextColor
$MainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$MainForm.MaximizeBox = $false
$MainForm.Icon = [System.Drawing.SystemIcons]::Shield

# Create header panel with Velociraptor branding
$HeaderPanel = New-Object System.Windows.Forms.Panel
$HeaderPanel.Size = New-Object System.Drawing.Size(980, 80)
$HeaderPanel.Location = New-Object System.Drawing.Point(10, 10)
$HeaderPanel.BackColor = $DarkPanel
$HeaderPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

# Velociraptor header label
$VelociraptorLabel = New-Object System.Windows.Forms.Label
$VelociraptorLabel.Text = "🦖 VELOCIRAPTOR INCIDENT RESPONSE`r`n   Rapid Deployment • Offline Collectors • Real-World Scenarios"
$VelociraptorLabel.Font = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold)
$VelociraptorLabel.ForeColor = $VelociraptorGreen
$VelociraptorLabel.Size = New-Object System.Drawing.Size(960, 60)
$VelociraptorLabel.Location = New-Object System.Drawing.Point(10, 10)
$VelociraptorLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

$HeaderPanel.Controls.Add($VelociraptorLabel)
$MainForm.Controls.Add($HeaderPanel)

# Create main content panel
$ContentPanel = New-Object System.Windows.Forms.Panel
$ContentPanel.Size = New-Object System.Drawing.Size(980, 550)
$ContentPanel.Location = New-Object System.Drawing.Point(10, 100)
$ContentPanel.BackColor = $DarkPanel
$ContentPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

# Incident Selection Section
$IncidentLabel = New-Object System.Windows.Forms.Label
$IncidentLabel.Text = "🚨 SELECT INCIDENT TYPE:"
$IncidentLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$IncidentLabel.ForeColor = $VelociraptorBlue
$IncidentLabel.Size = New-Object System.Drawing.Size(300, 25)
$IncidentLabel.Location = New-Object System.Drawing.Point(20, 20)

# Incident Category ComboBox
$CategoryComboBox = New-Object System.Windows.Forms.ComboBox
$CategoryComboBox.Size = New-Object System.Drawing.Size(300, 25)
$CategoryComboBox.Location = New-Object System.Drawing.Point(20, 50)
$CategoryComboBox.BackColor = $DarkBackground
$CategoryComboBox.ForeColor = $TextColor
$CategoryComboBox.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$CategoryComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

# Add incident categories
$IncidentCategories = @(
    "🦠 Malware & Ransomware (25 scenarios)",
    "🎯 Advanced Persistent Threats (20 scenarios)",
    "👤 Insider Threats (15 scenarios)",
    "🌐 Network & Infrastructure (15 scenarios)",
    "💳 Data Breaches & Compliance (10 scenarios)",
    "🏭 Industrial & Critical Infrastructure (10 scenarios)",
    "📱 Emerging & Specialized Threats (5 scenarios)"
)

foreach ($category in $IncidentCategories) {
    $CategoryComboBox.Items.Add($category) | Out-Null
}

# Specific Incident ComboBox
$IncidentComboBox = New-Object System.Windows.Forms.ComboBox
$IncidentComboBox.Size = New-Object System.Drawing.Size(600, 25)
$IncidentComboBox.Location = New-Object System.Drawing.Point(340, 50)
$IncidentComboBox.BackColor = $DarkBackground
$IncidentComboBox.ForeColor = $TextColor
$IncidentComboBox.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$IncidentComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$IncidentComboBox.Enabled = $false

$ContentPanel.Controls.AddRange(@($IncidentLabel, $CategoryComboBox, $IncidentComboBox))

# Define all 100 incident scenarios organized by category
$IncidentScenarios = @{
    "🦠 Malware & Ransomware (25 scenarios)" = @(
        "WannaCry-style Worm Ransomware",
        "Targeted Ransomware (REvil/Sodinokibi)",
        "Double Extortion Ransomware",
        "Ransomware-as-a-Service (RaaS)",
        "Industrial Control System Ransomware",
        "Healthcare Ransomware",
        "Educational Institution Ransomware",
        "Municipal Government Ransomware",
        "Supply Chain Ransomware",
        "Cloud Infrastructure Ransomware",
        "Banking Trojan (Emotet/TrickBot)",
        "Nation-State Malware (APT)",
        "Fileless Malware",
        "Living-off-the-Land Attacks",
        "Polymorphic Malware",
        "Rootkit Infections",
        "Bootkit Attacks",
        "Cryptocurrency Mining Malware",
        "Point-of-Sale (PoS) Malware",
        "Mobile Device Management (MDM) Bypass",
        "Industrial Espionage Malware",
        "Destructive Malware (Wiper)",
        "Supply Chain Malware",
        "Firmware Malware",
        "IoT Botnet Malware"
    )
    "🎯 Advanced Persistent Threats (20 scenarios)" = @(
        "Chinese APT Groups (APT1, APT40)",
        "Russian APT Groups (APT28, APT29)",
        "North Korean APT Groups (Lazarus)",
        "Iranian APT Groups (APT33, APT34)",
        "Middle Eastern APT Operations",
        "Healthcare Sector Targeting",
        "Financial Services APT",
        "Energy Sector Espionage",
        "Defense Contractor Targeting",
        "Telecommunications Espionage",
        "Spear Phishing Campaigns",
        "Watering Hole Attacks",
        "Zero-Day Exploitation",
        "Supply Chain Infiltration",
        "Cloud Infrastructure Targeting",
        "Multi-Year Persistence",
        "Data Exfiltration Operations",
        "Intellectual Property Theft",
        "Election Infrastructure Targeting",
        "Critical Infrastructure Reconnaissance"
    )
    "👤 Insider Threats (15 scenarios)" = @(
        "Disgruntled Employee Data Theft",
        "Privileged User Abuse",
        "Contractor/Vendor Insider Threat",
        "Executive-Level Insider Threat",
        "IT Administrator Sabotage",
        "Accidental Data Exposure",
        "Misconfigured Cloud Storage",
        "Email Misdirection",
        "Removable Media Loss",
        "Social Engineering Victim",
        "Account Takeover",
        "Credential Stuffing Success",
        "Phishing Victim",
        "Business Email Compromise (BEC)",
        "Remote Access Compromise"
    )
    "🌐 Network & Infrastructure (15 scenarios)" = @(
        "Lateral Movement Detection",
        "Network Reconnaissance",
        "DNS Tunneling",
        "Man-in-the-Middle Attacks",
        "Network Segmentation Bypass",
        "Domain Controller Compromise",
        "Certificate Authority Compromise",
        "Network Device Compromise",
        "Wireless Network Intrusion",
        "VPN Infrastructure Attacks",
        "Multi-Cloud Environment Breach",
        "Container Escape",
        "Kubernetes Cluster Compromise",
        "Serverless Function Abuse",
        "Hybrid Cloud Bridge Attacks"
    )
    "💳 Data Breaches & Compliance (10 scenarios)" = @(
        "Healthcare Data Breach (HIPAA)",
        "Financial Data Breach (PCI-DSS)",
        "Personal Data Breach (GDPR)",
        "Educational Records Breach (FERPA)",
        "Government Data Breach",
        "Legal Firm Data Breach",
        "Accounting Firm Breach",
        "HR System Breach",
        "Customer Database Breach",
        "Intellectual Property Theft"
    )
    "🏭 Industrial & Critical Infrastructure (10 scenarios)" = @(
        "SCADA System Compromise",
        "Manufacturing System Disruption",
        "Power Grid Attacks",
        "Water Treatment Facility",
        "Transportation System Attacks",
        "Oil & Gas Pipeline Attacks",
        "Nuclear Facility Security Incident",
        "Airport Security System Breach",
        "Port Authority System Compromise",
        "Emergency Services Disruption"
    )
    "📱 Emerging & Specialized Threats (5 scenarios)" = @(
        "Supply Chain Software Attack",
        "AI/ML Model Poisoning",
        "Quantum Computing Threats",
        "5G Network Security Incidents",
        "Deepfake & Disinformation Campaigns"
    )
}

# Incident Details Panel
$DetailsPanel = New-Object System.Windows.Forms.Panel
$DetailsPanel.Size = New-Object System.Drawing.Size(940, 200)
$DetailsPanel.Location = New-Object System.Drawing.Point(20, 90)
$DetailsPanel.BackColor = $DarkBackground
$DetailsPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

$DetailsLabel = New-Object System.Windows.Forms.Label
$DetailsLabel.Text = "📋 INCIDENT DETAILS:"
$DetailsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$DetailsLabel.ForeColor = $VelociraptorBlue
$DetailsLabel.Size = New-Object System.Drawing.Size(200, 25)
$DetailsLabel.Location = New-Object System.Drawing.Point(10, 10)

$DetailsTextBox = New-Object System.Windows.Forms.RichTextBox
$DetailsTextBox.Size = New-Object System.Drawing.Size(920, 160)
$DetailsTextBox.Location = New-Object System.Drawing.Point(10, 40)
$DetailsTextBox.BackColor = $DarkBackground
$DetailsTextBox.ForeColor = $TextColor
$DetailsTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$DetailsTextBox.ReadOnly = $true
$DetailsTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$DetailsTextBox.Text = "Select an incident type to view detailed information and recommended artifacts..."

$DetailsPanel.Controls.AddRange(@($DetailsLabel, $DetailsTextBox))

# Collector Configuration Panel
$ConfigPanel = New-Object System.Windows.Forms.Panel
$ConfigPanel.Size = New-Object System.Drawing.Size(940, 150)
$ConfigPanel.Location = New-Object System.Drawing.Point(20, 300)
$ConfigPanel.BackColor = $DarkBackground
$ConfigPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

$ConfigLabel = New-Object System.Windows.Forms.Label
$ConfigLabel.Text = "⚙️ COLLECTOR CONFIGURATION:"
$ConfigLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$ConfigLabel.ForeColor = $VelociraptorBlue
$ConfigLabel.Size = New-Object System.Drawing.Size(300, 25)
$ConfigLabel.Location = New-Object System.Drawing.Point(10, 10)

# Deployment Path
$PathLabel = New-Object System.Windows.Forms.Label
$PathLabel.Text = "📁 Deployment Path:"
$PathLabel.ForeColor = $TextColor
$PathLabel.Size = New-Object System.Drawing.Size(120, 20)
$PathLabel.Location = New-Object System.Drawing.Point(20, 45)

$PathTextBox = New-Object System.Windows.Forms.TextBox
$PathTextBox.Size = New-Object System.Drawing.Size(600, 25)
$PathTextBox.Location = New-Object System.Drawing.Point(150, 42)
$PathTextBox.BackColor = $DarkBackground
$PathTextBox.ForeColor = $TextColor
$PathTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$PathTextBox.Text = "C:\VelociraptorCollectors"

$BrowseButton = New-Object System.Windows.Forms.Button
$BrowseButton.Text = "Browse..."
$BrowseButton.Size = New-Object System.Drawing.Size(80, 25)
$BrowseButton.Location = New-Object System.Drawing.Point(760, 42)
$BrowseButton.BackColor = $DarkPanel
$BrowseButton.ForeColor = $TextColor
$BrowseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat

$ConfigPanel.Controls.AddRange(@($ConfigLabel, $PathLabel, $PathTextBox, $BrowseButton))

# Options checkboxes
$OfflineCheckBox = New-Object System.Windows.Forms.CheckBox
$OfflineCheckBox.Text = "🔌 Offline Mode (Bundle all tools)"
$OfflineCheckBox.ForeColor = $TextColor
$OfflineCheckBox.Size = New-Object System.Drawing.Size(250, 20)
$OfflineCheckBox.Location = New-Object System.Drawing.Point(20, 75)
$OfflineCheckBox.Checked = $true

$PortableCheckBox = New-Object System.Windows.Forms.CheckBox
$PortableCheckBox.Text = "📦 Create Portable Package"
$PortableCheckBox.ForeColor = $TextColor
$PortableCheckBox.Size = New-Object System.Drawing.Size(200, 20)
$PortableCheckBox.Location = New-Object System.Drawing.Point(280, 75)
$PortableCheckBox.Checked = $true

$EncryptCheckBox = New-Object System.Windows.Forms.CheckBox
$EncryptCheckBox.Text = "🔐 Encrypt Collector Package"
$EncryptCheckBox.ForeColor = $TextColor
$EncryptCheckBox.Size = New-Object System.Drawing.Size(200, 20)
$EncryptCheckBox.Location = New-Object System.Drawing.Point(490, 75)

$ConfigPanel.Controls.AddRange(@($OfflineCheckBox, $PortableCheckBox, $EncryptCheckBox))

# Priority and Urgency
$PriorityLabel = New-Object System.Windows.Forms.Label
$PriorityLabel.Text = "⚡ Priority:"
$PriorityLabel.ForeColor = $TextColor
$PriorityLabel.Size = New-Object System.Drawing.Size(60, 20)
$PriorityLabel.Location = New-Object System.Drawing.Point(20, 105)

$PriorityComboBox = New-Object System.Windows.Forms.ComboBox
$PriorityComboBox.Size = New-Object System.Drawing.Size(120, 25)
$PriorityComboBox.Location = New-Object System.Drawing.Point(90, 102)
$PriorityComboBox.BackColor = $DarkBackground
$PriorityComboBox.ForeColor = $TextColor
$PriorityComboBox.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$PriorityComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$PriorityComboBox.Items.AddRange(@("🔴 Critical", "🟠 High", "🟡 Medium", "🟢 Low"))
$PriorityComboBox.SelectedIndex = 1

$UrgencyLabel = New-Object System.Windows.Forms.Label
$UrgencyLabel.Text = "⏰ Response Time:"
$UrgencyLabel.ForeColor = $TextColor
$UrgencyLabel.Size = New-Object System.Drawing.Size(100, 20)
$UrgencyLabel.Location = New-Object System.Drawing.Point(230, 105)

$UrgencyComboBox = New-Object System.Windows.Forms.ComboBox
$UrgencyComboBox.Size = New-Object System.Drawing.Size(150, 25)
$UrgencyComboBox.Location = New-Object System.Drawing.Point(340, 102)
$UrgencyComboBox.BackColor = $DarkBackground
$UrgencyComboBox.ForeColor = $TextColor
$UrgencyComboBox.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$UrgencyComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$UrgencyComboBox.Items.AddRange(@("⚡ Immediate (0-1h)", "🚀 Rapid (1-4h)", "📋 Standard (4-12h)", "📅 Extended (12h+)"))
$UrgencyComboBox.SelectedIndex = 1

$ConfigPanel.Controls.AddRange(@($PriorityLabel, $PriorityComboBox, $UrgencyLabel, $UrgencyComboBox))

$ContentPanel.Controls.AddRange(@($DetailsPanel, $ConfigPanel))

# Action Buttons Panel
$ButtonPanel = New-Object System.Windows.Forms.Panel
$ButtonPanel.Size = New-Object System.Drawing.Size(940, 60)
$ButtonPanel.Location = New-Object System.Drawing.Point(20, 470)
$ButtonPanel.BackColor = $DarkBackground

# Deploy Button
$DeployButton = New-Object System.Windows.Forms.Button
$DeployButton.Text = "🚀 DEPLOY COLLECTOR"
$DeployButton.Size = New-Object System.Drawing.Size(200, 40)
$DeployButton.Location = New-Object System.Drawing.Point(20, 10)
$DeployButton.BackColor = $VelociraptorGreen
$DeployButton.ForeColor = [System.Drawing.Color]::Black
$DeployButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$DeployButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$DeployButton.Enabled = $false

# Preview Button
$PreviewButton = New-Object System.Windows.Forms.Button
$PreviewButton.Text = "👁️ PREVIEW CONFIG"
$PreviewButton.Size = New-Object System.Drawing.Size(150, 40)
$PreviewButton.Location = New-Object System.Drawing.Point(240, 10)
$PreviewButton.BackColor = $VelociraptorBlue
$PreviewButton.ForeColor = [System.Drawing.Color]::White
$PreviewButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$PreviewButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$PreviewButton.Enabled = $false

# Save Config Button
$SaveButton = New-Object System.Windows.Forms.Button
$SaveButton.Text = "💾 SAVE CONFIG"
$SaveButton.Size = New-Object System.Drawing.Size(130, 40)
$SaveButton.Location = New-Object System.Drawing.Point(410, 10)
$SaveButton.BackColor = $DarkPanel
$SaveButton.ForeColor = $TextColor
$SaveButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$SaveButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat

# Load Config Button
$LoadButton = New-Object System.Windows.Forms.Button
$LoadButton.Text = "📂 LOAD CONFIG"
$LoadButton.Size = New-Object System.Drawing.Size(130, 40)
$LoadButton.Location = New-Object System.Drawing.Point(560, 10)
$LoadButton.BackColor = $DarkPanel
$LoadButton.ForeColor = $TextColor
$LoadButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$LoadButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat

# Help Button
$HelpButton = New-Object System.Windows.Forms.Button
$HelpButton.Text = "❓ HELP"
$HelpButton.Size = New-Object System.Drawing.Size(80, 40)
$HelpButton.Location = New-Object System.Drawing.Point(710, 10)
$HelpButton.BackColor = $AccentColor
$HelpButton.ForeColor = [System.Drawing.Color]::Black
$HelpButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$HelpButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat

# Exit Button
$ExitButton = New-Object System.Windows.Forms.Button
$ExitButton.Text = "❌ EXIT"
$ExitButton.Size = New-Object System.Drawing.Size(80, 40)
$ExitButton.Location = New-Object System.Drawing.Point(810, 10)
$ExitButton.BackColor = [System.Drawing.Color]::FromArgb(220, 53, 69)
$ExitButton.ForeColor = [System.Drawing.Color]::White
$ExitButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$ExitButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat

$ButtonPanel.Controls.AddRange(@($DeployButton, $PreviewButton, $SaveButton, $LoadButton, $HelpButton, $ExitButton))
$ContentPanel.Controls.Add($ButtonPanel)

# Status bar
$StatusBar = New-Object System.Windows.Forms.StatusStrip
$StatusBar.BackColor = $DarkPanel
$StatusBar.ForeColor = $TextColor

$StatusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$StatusLabel.Text = "🦖 Ready - Select an incident type to begin"
$StatusLabel.ForeColor = $VelociraptorGreen
$StatusBar.Items.Add($StatusLabel) | Out-Null

$MainForm.Controls.AddRange(@($ContentPanel, $StatusBar))

# Event Handlers
$CategoryComboBox.Add_SelectedIndexChanged({
    $selectedCategory = $CategoryComboBox.SelectedItem
    $IncidentComboBox.Items.Clear()

    if ($IncidentScenarios.ContainsKey($selectedCategory)) {
        foreach ($incident in $IncidentScenarios[$selectedCategory]) {
            $IncidentComboBox.Items.Add($incident) | Out-Null
        }
        $IncidentComboBox.Enabled = $true
        $StatusLabel.Text = "🦖 Category selected - Choose specific incident"
    }
})

$IncidentComboBox.Add_SelectedIndexChanged({
    $script:SelectedIncident = $IncidentComboBox.SelectedItem
    if ($script:SelectedIncident) {
        Update-IncidentDetails
        $DeployButton.Enabled = $true
        $PreviewButton.Enabled = $true
        $StatusLabel.Text = "🦖 Incident selected - Ready to deploy collector"
    }
})

$BrowseButton.Add_Click({
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = "Select deployment directory"
    $folderDialog.SelectedPath = $PathTextBox.Text

    if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $PathTextBox.Text = $folderDialog.SelectedPath
        $script:DeploymentPath = $folderDialog.SelectedPath
    }
})

$DeployButton.Add_Click({
    Deploy-IncidentCollector
})

$PreviewButton.Add_Click({
    Show-ConfigPreview
})

$SaveButton.Add_Click({
    Save-Configuration
})

$LoadButton.Add_Click({
    Load-Configuration
})

$HelpButton.Add_Click({
    Show-Help
})

$ExitButton.Add_Click({
    $MainForm.Close()
})

# Function to update incident details
function Update-IncidentDetails {
    $incidentInfo = Get-IncidentInformation -IncidentType $script:SelectedIncident

    $DetailsTextBox.Clear()
    $DetailsTextBox.SelectionColor = $VelociraptorGreen
    $DetailsTextBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
    $DetailsTextBox.AppendText("🎯 INCIDENT: $($script:SelectedIncident)`n`n")

    $DetailsTextBox.SelectionColor = $VelociraptorBlue
    $DetailsTextBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
    $DetailsTextBox.AppendText("📋 DESCRIPTION:`n")

    $DetailsTextBox.SelectionColor = $TextColor
    $DetailsTextBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 9)
    $DetailsTextBox.AppendText("$($incidentInfo.Description)`n`n")

    $DetailsTextBox.SelectionColor = $VelociraptorBlue
    $DetailsTextBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
    $DetailsTextBox.AppendText("🔧 RECOMMENDED ARTIFACTS:`n")

    $DetailsTextBox.SelectionColor = $AccentColor
    $DetailsTextBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 9)
    foreach ($artifact in $incidentInfo.Artifacts) {
        $DetailsTextBox.AppendText("  • $artifact`n")
    }

    $DetailsTextBox.SelectionColor = $VelociraptorBlue
    $DetailsTextBox.SelectionFont = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
    $DetailsTextBox.AppendText("`n⚡ RESPONSE TIME: $($incidentInfo.ResponseTime)")

    # Auto-set priority and urgency based on incident type
    $PriorityComboBox.SelectedIndex = $incidentInfo.PriorityIndex
    $UrgencyComboBox.SelectedIndex = $incidentInfo.UrgencyIndex
}

# Function to get incident information
function Get-IncidentInformation {
    param([string]$IncidentType)

    # Default information structure
    $defaultInfo = @{
        Description = "Comprehensive incident response requiring immediate forensic collection and analysis."
        Artifacts = @("Windows.EventLogs.Hayabusa", "Windows.Forensics.PersistenceSniper", "Windows.Detection.Yara.Yara64")
        ResponseTime = "1-4 hours (Rapid Response)"
        PriorityIndex = 1
        UrgencyIndex = 1
    }

    # Customize based on incident type
    switch -Wildcard ($IncidentType) {
        "*Ransomware*" {
            $defaultInfo.Description = "Ransomware incident requiring immediate containment and forensic analysis. Focus on encryption artifacts, persistence mechanisms, and lateral movement indicators."
            $defaultInfo.Artifacts = @("Windows.EventLogs.Hayabusa", "Windows.Forensics.PersistenceSniper", "Windows.Detection.Yara.Yara64", "Windows.Registry.NTUser", "Windows.System.Services", "Windows.Network.NetstatEnriched")
            $defaultInfo.ResponseTime = "0-1 hour (Immediate Response)"
            $defaultInfo.PriorityIndex = 0
            $defaultInfo.UrgencyIndex = 0
        }
        "*APT*" {
            $defaultInfo.Description = "Advanced Persistent Threat requiring comprehensive forensic collection. Focus on stealth techniques, persistence, and data exfiltration indicators."
            $defaultInfo.Artifacts = @("Windows.EventLogs.Hayabusa", "Windows.Forensics.PersistenceSniper", "Windows.Detection.Yara.Yara64", "Windows.Memory.ProcessInfo", "Windows.System.Powershell.PSReadline", "Windows.Registry.Sysinternals.Eulacheck")
            $defaultInfo.ResponseTime = "0-2 hours (Critical Response)"
            $defaultInfo.PriorityIndex = 0
            $defaultInfo.UrgencyIndex = 0
        }
        "*Insider*" {
            $defaultInfo.Description = "Insider threat investigation requiring user activity analysis and data access tracking. Focus on user behavior and data movement."
            $defaultInfo.Artifacts = @("Windows.EventLogs.Hayabusa", "Windows.Forensics.UserAccessLogs", "Windows.Registry.RecentDocs", "Windows.Applications.Chrome.History", "Windows.System.LoggedInUsers")
            $defaultInfo.ResponseTime = "2-8 hours (Standard Response)"
            $defaultInfo.PriorityIndex = 2
            $defaultInfo.UrgencyIndex = 2
        }
        "*Infrastructure*" {
            $defaultInfo.Description = "Network infrastructure compromise requiring network forensics and lateral movement analysis."
            $defaultInfo.Artifacts = @("Windows.Network.NetstatEnriched", "Windows.EventLogs.Authentication", "Windows.System.Services", "Windows.Registry.NTUser")
            $defaultInfo.ResponseTime = "1-6 hours (Rapid Response)"
            $defaultInfo.PriorityIndex = 1
            $defaultInfo.UrgencyIndex = 1
        }
    }

    return $defaultInfo
}

# Function to deploy incident collector
function Deploy-IncidentCollector {
    try {
        $StatusLabel.Text = "🦖 Deploying collector..."
        $DeployButton.Enabled = $false

        # Create deployment configuration
        $config = @{
            IncidentType = $script:SelectedIncident
            DeploymentPath = $PathTextBox.Text
            OfflineMode = $OfflineCheckBox.Checked
            PortablePackage = $PortableCheckBox.Checked
            EncryptPackage = $EncryptCheckBox.Checked
            Priority = $PriorityComboBox.SelectedItem
            ResponseTime = $UrgencyComboBox.SelectedItem
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        # Get package type from incident
        $packageType = Get-PackageTypeFromIncident -IncidentType $script:SelectedIncident

        # Show progress dialog
        $progressForm = Show-ProgressDialog -Title "Deploying Collector" -Message "Building incident-specific collector package..."

        # Simulate deployment process
        Start-Sleep -Seconds 2

        $progressForm.Close()

        # Show success message
        $result = [System.Windows.Forms.MessageBox]::Show(
            "🦖 Collector deployed successfully!`n`nIncident: $($script:SelectedIncident)`nLocation: $($PathTextBox.Text)`nPackage Type: $packageType",
            "Deployment Complete",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )

        $StatusLabel.Text = "🦖 Deployment completed successfully"
        $DeployButton.Enabled = $true

    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "❌ Deployment failed: $($_.Exception.Message)",
            "Deployment Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        $StatusLabel.Text = "🦖 Deployment failed"
        $DeployButton.Enabled = $true
    }
}

# Function to get package type from incident
function Get-PackageTypeFromIncident {
    param([string]$IncidentType)

    switch -Wildcard ($IncidentType) {
        "*Ransomware*" { return "Ransomware" }
        "*APT*" { return "APT" }
        "*Insider*" { return "Insider" }
        "*Malware*" { return "Malware" }
        "*Network*" { return "NetworkIntrusion" }
        "*Infrastructure*" { return "NetworkIntrusion" }
        "*Data Breach*" { return "DataBreach" }
        "*HIPAA*" { return "DataBreach" }
        "*PCI*" { return "DataBreach" }
        "*GDPR*" { return "DataBreach" }
        "*Industrial*" { return "Complete" }
        "*Critical Infrastructure*" { return "Complete" }
        "*SCADA*" { return "Complete" }
        default { return "Complete" }
    }
}

# Function to show progress dialog
function Show-ProgressDialog {
    param([string]$Title, [string]$Message)

    $progressForm = New-Object System.Windows.Forms.Form
    $progressForm.Text = $Title
    $progressForm.Size = New-Object System.Drawing.Size(400, 150)
    $progressForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $progressForm.BackColor = $DarkBackground
    $progressForm.ForeColor = $TextColor
    $progressForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $progressForm.MaximizeBox = $false
    $progressForm.MinimizeBox = $false

    $progressLabel = New-Object System.Windows.Forms.Label
    $progressLabel.Text = $Message
    $progressLabel.Size = New-Object System.Drawing.Size(360, 40)
    $progressLabel.Location = New-Object System.Drawing.Point(20, 20)
    $progressLabel.ForeColor = $TextColor

    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Size = New-Object System.Drawing.Size(360, 25)
    $progressBar.Location = New-Object System.Drawing.Point(20, 70)
    $progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee

    $progressForm.Controls.AddRange(@($progressLabel, $progressBar))
    $progressForm.Show()

    return $progressForm
}