#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Velociraptor Incident Response Collector GUI - Working Version

.DESCRIPTION
    Fixed version of the Incident Response GUI with proper Windows Forms initialization.

.EXAMPLE
    .\IncidentResponseGUI-Working.ps1
#>

[CmdletBinding()]
param(
    [switch]$StartMinimized
)

$ErrorActionPreference = 'Stop'

Write-Host "🚨 Velociraptor Incident Response Collector" -ForegroundColor Red
Write-Host "===========================================" -ForegroundColor Red

# CRITICAL: Initialize Windows Forms properly
Write-Host "🔧 Initializing Windows Forms..." -ForegroundColor Yellow

try {
    # Skip SetCompatibleTextRenderingDefault if Windows Forms is already initialized
    try {
        [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
        Write-Host "✅ SetCompatibleTextRenderingDefault successful" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️  SetCompatibleTextRenderingDefault already called (this is normal)" -ForegroundColor Yellow
    }
    
    # Load assemblies
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
    
    # Enable visual styles (safe to call multiple times)
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
}

# Incident types
$IncidentTypes = @(
    @{ Name = "APT Attack"; Description = "Advanced Persistent Threat investigation"; Icon = "🎯" }
    @{ Name = "Ransomware"; Description = "Ransomware incident response"; Icon = "🔒" }
    @{ Name = "Malware Analysis"; Description = "Malware infection investigation"; Icon = "🦠" }
    @{ Name = "Data Breach"; Description = "Data exfiltration investigation"; Icon = "📊" }
    @{ Name = "Network Intrusion"; Description = "Network compromise investigation"; Icon = "🌐" }
    @{ Name = "Insider Threat"; Description = "Internal threat investigation"; Icon = "👤" }
)

Write-Host "🏗️ Creating main form..." -ForegroundColor Yellow

try {
    # Create main form
    $MainForm = New-Object System.Windows.Forms.Form
    $MainForm.Text = "🦖 Velociraptor Incident Response Collector"
    $MainForm.Size = New-Object System.Drawing.Size(1000, 700)
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
    $HeaderPanel.Size = New-Object System.Drawing.Size(980, 80)
    $HeaderPanel.Location = New-Object System.Drawing.Point(10, 10)
    $HeaderPanel.BackColor = $Colors.DarkPanel
    
    # Title
    $TitleLabel = New-Object System.Windows.Forms.Label
    $TitleLabel.Text = "🚨 INCIDENT RESPONSE COLLECTOR"
    $TitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    $TitleLabel.ForeColor = $Colors.VelociraptorGreen
    $TitleLabel.Location = New-Object System.Drawing.Point(20, 15)
    $TitleLabel.Size = New-Object System.Drawing.Size(600, 25)
    
    # Subtitle
    $SubtitleLabel = New-Object System.Windows.Forms.Label
    $SubtitleLabel.Text = "Deploy specialized collectors for cybersecurity incidents"
    $SubtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $SubtitleLabel.ForeColor = $Colors.TextColor
    $SubtitleLabel.Location = New-Object System.Drawing.Point(20, 45)
    $SubtitleLabel.Size = New-Object System.Drawing.Size(600, 20)
    
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
    # Incident selection panel
    $IncidentPanel = New-Object System.Windows.Forms.Panel
    $IncidentPanel.Size = New-Object System.Drawing.Size(980, 500)
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
        $IncidentButton.Size = New-Object System.Drawing.Size(300, 50)
        $IncidentButton.Location = New-Object System.Drawing.Point(50, $ButtonY)
        $IncidentButton.BackColor = $Colors.DarkBackground
        $IncidentButton.ForeColor = $Colors.TextColor
        $IncidentButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $IncidentButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        
        # Add click event
        $IncidentButton.Add_Click({
            param($sender, $e)
            $selectedIncident = $IncidentTypes | Where-Object { "$($_.Icon) $($_.Name)" -eq $sender.Text }
            [System.Windows.Forms.MessageBox]::Show(
                "Selected: $($selectedIncident.Name)`n`nDescription: $($selectedIncident.Description)`n`nThis would deploy a specialized collector for this incident type.",
                "Incident Response Collector",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }.GetNewClosure())
        
        # Description label
        $DescLabel = New-Object System.Windows.Forms.Label
        $DescLabel.Text = $incident.Description
        $DescLabel.Size = New-Object System.Drawing.Size(600, 20)
        $DescLabel.Location = New-Object System.Drawing.Point(370, ($ButtonY + 15))
        $DescLabel.ForeColor = $Colors.TextColor
        $DescLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        
        $IncidentPanel.Controls.Add($IncidentButton)
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

Write-Host "🔘 Creating buttons..." -ForegroundColor Yellow

try {
    # Button panel
    $ButtonPanel = New-Object System.Windows.Forms.Panel
    $ButtonPanel.Size = New-Object System.Drawing.Size(980, 60)
    $ButtonPanel.Location = New-Object System.Drawing.Point(10, 610)
    $ButtonPanel.BackColor = $Colors.DarkPanel
    
    # Deploy button
    $DeployButton = New-Object System.Windows.Forms.Button
    $DeployButton.Text = "🚀 Deploy Collector"
    $DeployButton.Size = New-Object System.Drawing.Size(150, 35)
    $DeployButton.Location = New-Object System.Drawing.Point(700, 15)
    $DeployButton.BackColor = $Colors.VelociraptorGreen
    $DeployButton.ForeColor = [System.Drawing.Color]::Black
    $DeployButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $DeployButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $DeployButton.Add_Click({
        [System.Windows.Forms.MessageBox]::Show(
            "Collector deployment functionality would be implemented here.`n`nThis would create and deploy a specialized Velociraptor collector based on your incident type selection.",
            "Deploy Collector",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    })
    
    # Exit button
    $ExitButton = New-Object System.Windows.Forms.Button
    $ExitButton.Text = "Exit"
    $ExitButton.Size = New-Object System.Drawing.Size(80, 35)
    $ExitButton.Location = New-Object System.Drawing.Point(870, 15)
    $ExitButton.BackColor = $Colors.DarkBackground
    $ExitButton.ForeColor = $Colors.TextColor
    $ExitButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ExitButton.Add_Click({ $MainForm.Close() })
    
    $ButtonPanel.Controls.Add($DeployButton)
    $ButtonPanel.Controls.Add($ExitButton)
    $MainForm.Controls.Add($ButtonPanel)
    
    Write-Host "✅ Buttons created successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to create buttons: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

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

Write-Host "🎉 Incident Response session completed!" -ForegroundColor Green