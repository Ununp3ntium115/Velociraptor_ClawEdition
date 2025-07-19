#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Velociraptor Configuration Wizard GUI

.DESCRIPTION
    A step-by-step wizard GUI for creating Velociraptor configurations.
    Guides users through all configuration options with Next/Back navigation.

.EXAMPLE
    .\VelociraptorGUI.ps1
#>

[CmdletBinding()]
param(
    [switch]$StartMinimized
)

# Add Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Import required modules
$ModulePath = Join-Path $PSScriptRoot "..\modules"
try {
    Import-Module "$ModulePath\VelociraptorDeployment" -Force
} catch {
    Write-Warning "Could not load VelociraptorDeployment module: $($_.Exception.Message)"
}

# Global variables for wizard state
$script:CurrentStep = 0
$script:ConfigData = @{
    DeploymentType = ""
    DatastoreDirectory = "C:\VelociraptorData"
    LogsDirectory = "logs"
    CertificateExpiration = "1 Year"
    RestrictVQL = $false
    UseRegistry = $false
    RegistryPath = "HKLM\SOFTWARE\Velocidex\Velociraptor"
    BindAddress = "0.0.0.0"
    BindPort = "8000"
    GUIBindAddress = "127.0.0.1"
    GUIBindPort = "8889"
    FrontendCertificate = ""
    CACertificate = ""
    ServerPrivateKey = ""
    ClientPrivateKey = ""
    PinnedServerName = ""
    OrganizationName = "VelociraptorOrg"
    AdminUsername = "admin"
    AdminPassword = ""
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

# Create main form
function New-WizardForm {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Velociraptor Configuration Wizard"
    $form.Size = New-Object System.Drawing.Size(800, 600)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $true
    $form.BackColor = [System.Drawing.Color]::White
    
    # Add Velociraptor logo/header
    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Size = New-Object System.Drawing.Size(800, 80)
    $headerPanel.Location = New-Object System.Drawing.Point(0, 0)
    $headerPanel.BackColor = [System.Drawing.Color]::FromArgb(41, 128, 185)
    
    $logoLabel = New-Object System.Windows.Forms.Label
    $logoLabel.Text = "🦖 VELOCIRAPTOR"
    $logoLabel.Font = New-Object System.Drawing.Font("Arial", 18, [System.Drawing.FontStyle]::Bold)
    $logoLabel.ForeColor = [System.Drawing.Color]::White
    $logoLabel.Location = New-Object System.Drawing.Point(20, 20)
    $logoLabel.Size = New-Object System.Drawing.Size(300, 40)
    $headerPanel.Controls.Add($logoLabel)
    
    $subtitleLabel = New-Object System.Windows.Forms.Label
    $subtitleLabel.Text = "Configuration Wizard"
    $subtitleLabel.Font = New-Object System.Drawing.Font("Arial", 10)
    $subtitleLabel.ForeColor = [System.Drawing.Color]::White
    $subtitleLabel.Location = New-Object System.Drawing.Point(20, 50)
    $subtitleLabel.Size = New-Object System.Drawing.Size(200, 20)
    $headerPanel.Controls.Add($subtitleLabel)
    
    $form.Controls.Add($headerPanel)
    
    # Progress indicator
    $progressPanel = New-Object System.Windows.Forms.Panel
    $progressPanel.Size = New-Object System.Drawing.Size(800, 40)
    $progressPanel.Location = New-Object System.Drawing.Point(0, 80)
    $progressPanel.BackColor = [System.Drawing.Color]::FromArgb(236, 240, 241)
    
    $script:ProgressLabel = New-Object System.Windows.Forms.Label
    $script:ProgressLabel.Location = New-Object System.Drawing.Point(20, 10)
    $script:ProgressLabel.Size = New-Object System.Drawing.Size(600, 20)
    $script:ProgressLabel.Font = New-Object System.Drawing.Font("Arial", 9)
    $progressPanel.Controls.Add($script:ProgressLabel)
    
    $script:StepLabel = New-Object System.Windows.Forms.Label
    $script:StepLabel.Location = New-Object System.Drawing.Point(650, 10)
    $script:StepLabel.Size = New-Object System.Drawing.Size(100, 20)
    $script:StepLabel.Font = New-Object System.Drawing.Font("Arial", 9)
    $script:StepLabel.TextAlign = "MiddleRight"
    $progressPanel.Controls.Add($script:StepLabel)
    
    $form.Controls.Add($progressPanel)
    
    # Main content area
    $script:ContentPanel = New-Object System.Windows.Forms.Panel
    $script:ContentPanel.Size = New-Object System.Drawing.Size(760, 400)
    $script:ContentPanel.Location = New-Object System.Drawing.Point(20, 140)
    $script:ContentPanel.BackColor = [System.Drawing.Color]::White
    $form.Controls.Add($script:ContentPanel)
    
    # Button panel
    $buttonPanel = New-Object System.Windows.Forms.Panel
    $buttonPanel.Size = New-Object System.Drawing.Size(800, 60)
    $buttonPanel.Location = New-Object System.Drawing.Point(0, 540)
    $buttonPanel.BackColor = [System.Drawing.Color]::FromArgb(236, 240, 241)
    
    # Back button
    $script:BackButton = New-Object System.Windows.Forms.Button
    $script:BackButton.Text = "< Back"
    $script:BackButton.Size = New-Object System.Drawing.Size(100, 35)
    $script:BackButton.Location = New-Object System.Drawing.Point(480, 12)
    $script:BackButton.Enabled = $false
    $script:BackButton.Add_Click({ Move-ToPreviousStep })
    $buttonPanel.Controls.Add($script:BackButton)
    
    # Next button
    $script:NextButton = New-Object System.Windows.Forms.Button
    $script:NextButton.Text = "Next >"
    $script:NextButton.Size = New-Object System.Drawing.Size(100, 35)
    $script:NextButton.Location = New-Object System.Drawing.Point(590, 12)
    $script:NextButton.Add_Click({ Move-ToNextStep })
    $buttonPanel.Controls.Add($script:NextButton)
    
    # Cancel button
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Size = New-Object System.Drawing.Size(100, 35)
    $cancelButton.Location = New-Object System.Drawing.Point(700, 12)
    $cancelButton.Add_Click({ $form.Close() })
    $buttonPanel.Controls.Add($cancelButton)
    
    $form.Controls.Add($buttonPanel)
    
    return $form
}

# Update progress display
function Update-Progress {
    $currentStep = $script:WizardSteps[$script:CurrentStep]
    $script:ProgressLabel.Text = "$($currentStep.Title) - $($currentStep.Description)"
    $script:StepLabel.Text = "Step $($script:CurrentStep + 1) of $($script:WizardSteps.Count)"
    
    # Update button states
    $script:BackButton.Enabled = ($script:CurrentStep -gt 0)
    
    if ($script:CurrentStep -eq ($script:WizardSteps.Count - 1)) {
        $script:NextButton.Text = "Finish"
    } elseif ($script:CurrentStep -eq ($script:WizardSteps.Count - 2)) {
        $script:NextButton.Text = "Generate"
    } else {
        $script:NextButton.Text = "Next >"
    }
}

# Move to next step
function Move-ToNextStep {
    if (Confirm-CurrentStep) {
        if ($script:CurrentStep -eq ($script:WizardSteps.Count - 2)) {
            # Generate configuration before moving to final step
            Generate-Configuration
        }
        
        if ($script:CurrentStep -lt ($script:WizardSteps.Count - 1)) {
            $script:CurrentStep++
            Show-CurrentStep
        } else {
            # Finish wizard
            $script:MainForm.Close()
        }
    }
}

# Move to previous step
function Move-ToPreviousStep {
    if ($script:CurrentStep -gt 0) {
        $script:CurrentStep--
        Show-CurrentStep
    }
}

# Validate current step
function Confirm-CurrentStep {
    switch ($script:CurrentStep) {
        1 { # Deployment Type
            if (-not $script:ConfigData.DeploymentType) {
                [System.Windows.Forms.MessageBox]::Show("Please select a deployment type.", "Validation Error", "OK", "Warning")
                return $false
            }
        }
        2 { # Storage Configuration
            if (-not $script:ConfigData.DatastoreDirectory) {
                [System.Windows.Forms.MessageBox]::Show("Please specify a datastore directory.", "Validation Error", "OK", "Warning")
                return $false
            }
        }
        6 { # Authentication
            if (-not $script:ConfigData.AdminPassword) {
                [System.Windows.Forms.MessageBox]::Show("Please set an admin password.", "Validation Error", "OK", "Warning")
                return $false
            }
        }
    }
    return $true
}

# Show current step content
function Show-CurrentStep {
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
    }
}

# Step 0: Welcome
function Show-WelcomeStep {
    $welcomeLabel = New-Object System.Windows.Forms.Label
    $welcomeLabel.Text = @"
Welcome to the Velociraptor Configuration Wizard!

This wizard will guide you through creating a complete Velociraptor configuration file.

You will be asked to configure:
• Deployment type (Server, Standalone, or Client)
• Storage locations for data and logs
• SSL certificate settings
• Security and access restrictions
• Network configuration
• Administrative credentials

Click Next to begin the configuration process.
"@
    $welcomeLabel.Location = New-Object System.Drawing.Point(20, 20)
    $welcomeLabel.Size = New-Object System.Drawing.Size(700, 300)
    $welcomeLabel.Font = New-Object System.Drawing.Font("Arial", 11)
    $script:ContentPanel.Controls.Add($welcomeLabel)
}

# Step 1: Deployment Type
function Show-DeploymentTypeStep {
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Select Deployment Type"
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 30)
    $script:ContentPanel.Controls.Add($titleLabel)
    
    $descLabel = New-Object System.Windows.Forms.Label
    $descLabel.Text = "Choose the type of Velociraptor deployment you want to configure:"
    $descLabel.Location = New-Object System.Drawing.Point(20, 60)
    $descLabel.Size = New-Object System.Drawing.Size(600, 20)
    $script:ContentPanel.Controls.Add($descLabel)
    
    # Server option
    $script:ServerRadio = New-Object System.Windows.Forms.RadioButton
    $script:ServerRadio.Text = "Server Deployment"
    $script:ServerRadio.Location = New-Object System.Drawing.Point(40, 100)
    $script:ServerRadio.Size = New-Object System.Drawing.Size(200, 20)
    $script:ServerRadio.Checked = ($script:ConfigData.DeploymentType -eq "Server")
    $script:ServerRadio.Add_CheckedChanged({ 
        if ($script:ServerRadio.Checked) { $script:ConfigData.DeploymentType = "Server" }
    })
    $script:ContentPanel.Controls.Add($script:ServerRadio)
    
    $serverDesc = New-Object System.Windows.Forms.Label
    $serverDesc.Text = "Full server with web GUI and client management capabilities"
    $serverDesc.Location = New-Object System.Drawing.Point(60, 125)
    $serverDesc.Size = New-Object System.Drawing.Size(500, 20)
    $serverDesc.ForeColor = [System.Drawing.Color]::Gray
    $script:ContentPanel.Controls.Add($serverDesc)
    
    # Standalone option
    $script:StandaloneRadio = New-Object System.Windows.Forms.RadioButton
    $script:StandaloneRadio.Text = "Standalone Deployment"
    $script:StandaloneRadio.Location = New-Object System.Drawing.Point(40, 160)
    $script:StandaloneRadio.Size = New-Object System.Drawing.Size(200, 20)
    $script:StandaloneRadio.Checked = ($script:ConfigData.DeploymentType -eq "Standalone")
    $script:StandaloneRadio.Add_CheckedChanged({ 
        if ($script:StandaloneRadio.Checked) { $script:ConfigData.DeploymentType = "Standalone" }
    })
    $script:ContentPanel.Controls.Add($script:StandaloneRadio)
    
    $standaloneDesc = New-Object System.Windows.Forms.Label
    $standaloneDesc.Text = "Single-user deployment with local GUI access only"
    $standaloneDesc.Location = New-Object System.Drawing.Point(60, 185)
    $standaloneDesc.Size = New-Object System.Drawing.Size(500, 20)
    $standaloneDesc.ForeColor = [System.Drawing.Color]::Gray
    $script:ContentPanel.Controls.Add($standaloneDesc)
    
    # Client option
    $script:ClientRadio = New-Object System.Windows.Forms.RadioButton
    $script:ClientRadio.Text = "Client Configuration"
    $script:ClientRadio.Location = New-Object System.Drawing.Point(40, 220)
    $script:ClientRadio.Size = New-Object System.Drawing.Size(200, 20)
    $script:ClientRadio.Checked = ($script:ConfigData.DeploymentType -eq "Client")
    $script:ClientRadio.Add_CheckedChanged({ 
        if ($script:ClientRadio.Checked) { $script:ConfigData.DeploymentType = "Client" }
    })
    $script:ContentPanel.Controls.Add($script:ClientRadio)
    
    $clientDesc = New-Object System.Windows.Forms.Label
    $clientDesc.Text = "Client agent configuration for connecting to a Velociraptor server"
    $clientDesc.Location = New-Object System.Drawing.Point(60, 245)
    $clientDesc.Size = New-Object System.Drawing.Size(500, 20)
    $clientDesc.ForeColor = [System.Drawing.Color]::Gray
    $script:ContentPanel.Controls.Add($clientDesc)
}

# Step 2: Storage Configuration
function Show-StorageConfigurationStep {
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Storage Configuration"
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 30)
    $script:ContentPanel.Controls.Add($titleLabel)
    
    # Datastore directory
    $datastoreLabel = New-Object System.Windows.Forms.Label
    $datastoreLabel.Text = "Datastore Directory:"
    $datastoreLabel.Location = New-Object System.Drawing.Point(20, 70)
    $datastoreLabel.Size = New-Object System.Drawing.Size(150, 20)
    $script:ContentPanel.Controls.Add($datastoreLabel)
    
    $datastoreDesc = New-Object System.Windows.Forms.Label
    $datastoreDesc.Text = "The datastore directory is where Velociraptor will store all files.`nThis should be located on a partition large enough to contain all data you are likely to collect.`nMake sure there is sufficient disk space available!"
    $datastoreDesc.Location = New-Object System.Drawing.Point(20, 95)
    $datastoreDesc.Size = New-Object System.Drawing.Size(700, 60)
    $datastoreDesc.ForeColor = [System.Drawing.Color]::Gray
    $script:ContentPanel.Controls.Add($datastoreDesc)
    
    $script:DatastoreTextBox = New-Object System.Windows.Forms.TextBox
    $script:DatastoreTextBox.Text = $script:ConfigData.DatastoreDirectory
    $script:DatastoreTextBox.Location = New-Object System.Drawing.Point(20, 165)
    $script:DatastoreTextBox.Size = New-Object System.Drawing.Size(500, 25)
    $script:DatastoreTextBox.Add_TextChanged({ 
        $script:ConfigData.DatastoreDirectory = $script:DatastoreTextBox.Text 
    })
    $script:ContentPanel.Controls.Add($script:DatastoreTextBox)
    
    $browseButton = New-Object System.Windows.Forms.Button
    $browseButton.Text = "Browse..."
    $browseButton.Location = New-Object System.Drawing.Point(530, 163)
    $browseButton.Size = New-Object System.Drawing.Size(80, 25)
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
    $logsLabel.Text = "Path to the logs directory:"
    $logsLabel.Location = New-Object System.Drawing.Point(20, 210)
    $logsLabel.Size = New-Object System.Drawing.Size(200, 20)
    $script:ContentPanel.Controls.Add($logsLabel)
    
    $logsDesc = New-Object System.Windows.Forms.Label
    $logsDesc.Text = "Velociraptor will write logs to this directory. By default it resides within the datastore directory but you can place it anywhere."
    $logsDesc.Location = New-Object System.Drawing.Point(20, 235)
    $logsDesc.Size = New-Object System.Drawing.Size(700, 40)
    $logsDesc.ForeColor = [System.Drawing.Color]::Gray
    $script:ContentPanel.Controls.Add($logsDesc)
    
    $script:LogsTextBox = New-Object System.Windows.Forms.TextBox
    $script:LogsTextBox.Text = $script:ConfigData.LogsDirectory
    $script:LogsTextBox.Location = New-Object System.Drawing.Point(20, 285)
    $script:LogsTextBox.Size = New-Object System.Drawing.Size(500, 25)
    $script:LogsTextBox.Add_TextChanged({ 
        $script:ConfigData.LogsDirectory = $script:LogsTextBox.Text 
    })
    $script:ContentPanel.Controls.Add($script:LogsTextBox)
}

# Step 3: Certificate Settings
function Show-CertificateSettingsStep {
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Certificate Configuration"
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 30)
    $script:ContentPanel.Controls.Add($titleLabel)
    
    # Certificate expiration
    $certLabel = New-Object System.Windows.Forms.Label
    $certLabel.Text = "Internal PKI Certificate Expiration:"
    $certLabel.Location = New-Object System.Drawing.Point(20, 70)
    $certLabel.Size = New-Object System.Drawing.Size(250, 20)
    $script:ContentPanel.Controls.Add($certLabel)
    
    $certDesc = New-Object System.Windows.Forms.Label
    $certDesc.Text = "By default internal certificates are issued for 1 year.`n`nIf you expect this deployment to exist past one year you might consider extending the default validation."
    $certDesc.Location = New-Object System.Drawing.Point(20, 95)
    $certDesc.Size = New-Object System.Drawing.Size(700, 60)
    $certDesc.ForeColor = [System.Drawing.Color]::Gray
    $script:ContentPanel.Controls.Add($certDesc)
    
    # Certificate expiration options
    $script:Cert1YearRadio = New-Object System.Windows.Forms.RadioButton
    $script:Cert1YearRadio.Text = "1 Year"
    $script:Cert1YearRadio.Location = New-Object System.Drawing.Point(40, 170)
    $script:Cert1YearRadio.Size = New-Object System.Drawing.Size(100, 20)
    $script:Cert1YearRadio.Checked = ($script:ConfigData.CertificateExpiration -eq "1 Year")
    $script:Cert1YearRadio.Add_CheckedChanged({ 
        if ($script:Cert1YearRadio.Checked) { $script:ConfigData.CertificateExpiration = "1 Year" }
    })
    $script:ContentPanel.Controls.Add($script:Cert1YearRadio)
    
    $script:Cert2YearRadio = New-Object System.Windows.Forms.RadioButton
    $script:Cert2YearRadio.Text = "2 Years"
    $script:Cert2YearRadio.Location = New-Object System.Drawing.Point(40, 200)
    $script:Cert2YearRadio.Size = New-Object System.Drawing.Size(100, 20)
    $script:Cert2YearRadio.Checked = ($script:ConfigData.CertificateExpiration -eq "2 Years")
    $script:Cert2YearRadio.Add_CheckedChanged({ 
        if ($script:Cert2YearRadio.Checked) { $script:ConfigData.CertificateExpiration = "2 Years" }
    })
    $script:ContentPanel.Controls.Add($script:Cert2YearRadio)
    
    $script:Cert10YearRadio = New-Object System.Windows.Forms.RadioButton
    $script:Cert10YearRadio.Text = "10 Years"
    $script:Cert10YearRadio.Location = New-Object System.Drawing.Point(40, 230)
    $script:Cert10YearRadio.Size = New-Object System.Drawing.Size(100, 20)
    $script:Cert10YearRadio.Checked = ($script:ConfigData.CertificateExpiration -eq "10 Years")
    $script:Cert10YearRadio.Add_CheckedChanged({ 
        if ($script:Cert10YearRadio.Checked) { $script:ConfigData.CertificateExpiration = "10 Years" }
    })
    $script:ContentPanel.Controls.Add($script:Cert10YearRadio)
}

# Step 4: Security Settings
function Show-SecuritySettingsStep {
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Security Configuration"
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 30)
    $script:ContentPanel.Controls.Add($titleLabel)
    
    # VQL restriction
    $vqlLabel = New-Object System.Windows.Forms.Label
    $vqlLabel.Text = "Do you want to restrict VQL functionality on the server?"
    $vqlLabel.Location = New-Object System.Drawing.Point(20, 70)
    $vqlLabel.Size = New-Object System.Drawing.Size(400, 20)
    $script:ContentPanel.Controls.Add($vqlLabel)
    
    $vqlDesc = New-Object System.Windows.Forms.Label
    $vqlDesc.Text = @"
This is useful for a shared server where users are not fully trusted.
It removes potentially dangerous plugins like execve(), filesystem access etc.

NOTE: This is an experimental feature only useful in limited situations. If you do not know you need it select No here!
"@
    $vqlDesc.Location = New-Object System.Drawing.Point(20, 95)
    $vqlDesc.Size = New-Object System.Drawing.Size(700, 80)
    $vqlDesc.ForeColor = [System.Drawing.Color]::Gray
    $script:ContentPanel.Controls.Add($vqlDesc)
    
    $script:VQLYesRadio = New-Object System.Windows.Forms.RadioButton
    $script:VQLYesRadio.Text = "Yes"
    $script:VQLYesRadio.Location = New-Object System.Drawing.Point(40, 185)
    $script:VQLYesRadio.Size = New-Object System.Drawing.Size(60, 20)
    $script:VQLYesRadio.Checked = $script:ConfigData.RestrictVQL
    $script:VQLYesRadio.Add_CheckedChanged({ 
        $script:ConfigData.RestrictVQL = $script:VQLYesRadio.Checked
    })
    $script:ContentPanel.Controls.Add($script:VQLYesRadio)
    
    $script:VQLNoRadio = New-Object System.Windows.Forms.RadioButton
    $script:VQLNoRadio.Text = "No"
    $script:VQLNoRadio.Location = New-Object System.Drawing.Point(120, 185)
    $script:VQLNoRadio.Size = New-Object System.Drawing.Size(60, 20)
    $script:VQLNoRadio.Checked = (-not $script:ConfigData.RestrictVQL)
    $script:VQLNoRadio.Add_CheckedChanged({ 
        $script:ConfigData.RestrictVQL = (-not $script:VQLNoRadio.Checked)
    })
    $script:ContentPanel.Controls.Add($script:VQLNoRadio)
    
    # Registry usage
    $regLabel = New-Object System.Windows.Forms.Label
    $regLabel.Text = "Use registry for client writeback?"
    $regLabel.Location = New-Object System.Drawing.Point(20, 230)
    $regLabel.Size = New-Object System.Drawing.Size(300, 20)
    $script:ContentPanel.Controls.Add($regLabel)
    
    $regDesc = New-Object System.Windows.Forms.Label
    $regDesc.Text = @"
Traditionally Velociraptor uses files to store client state on all operating systems.

You can instead use the registry on Windows. NOTE: It is your responsibility to ensure the registry keys used are properly secured!

By default we use HKLM\SOFTWARE\Velocidex\Velociraptor
"@
    $regDesc.Location = New-Object System.Drawing.Point(20, 255)
    $regDesc.Size = New-Object System.Drawing.Size(700, 80)
    $regDesc.ForeColor = [System.Drawing.Color]::Gray
    $script:ContentPanel.Controls.Add($regDesc)
    
    $script:RegYesRadio = New-Object System.Windows.Forms.RadioButton
    $script:RegYesRadio.Text = "Yes"
    $script:RegYesRadio.Location = New-Object System.Drawing.Point(40, 345)
    $script:RegYesRadio.Size = New-Object System.Drawing.Size(60, 20)
    $script:RegYesRadio.Checked = $script:ConfigData.UseRegistry
    $script:RegYesRadio.Add_CheckedChanged({ 
        $script:ConfigData.UseRegistry = $script:RegYesRadio.Checked
    })
    $script:ContentPanel.Controls.Add($script:RegYesRadio)
    
    $script:RegNoRadio = New-Object System.Windows.Forms.RadioButton
    $script:RegNoRadio.Text = "No"
    $script:RegNoRadio.Location = New-Object System.Drawing.Point(120, 345)
    $script:RegNoRadio.Size = New-Object System.Drawing.Size(60, 20)
    $script:RegNoRadio.Checked = (-not $script:ConfigData.UseRegistry)
    $script:RegNoRadio.Add_CheckedChanged({ 
        $script:ConfigData.UseRegistry = (-not $script:RegNoRadio.Checked)
    })
    $script:ContentPanel.Controls.Add($script:RegNoRadio)
}

# Step 5: Network Configuration
function Show-NetworkConfigurationStep {
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Network Configuration"
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 30)
    $script:ContentPanel.Controls.Add($titleLabel)
    
    # Frontend bind address
    $bindLabel = New-Object System.Windows.Forms.Label
    $bindLabel.Text = "Frontend Bind Address:"
    $bindLabel.Location = New-Object System.Drawing.Point(20, 70)
    $bindLabel.Size = New-Object System.Drawing.Size(200, 20)
    $script:ContentPanel.Controls.Add($bindLabel)
    
    $script:BindAddressTextBox = New-Object System.Windows.Forms.TextBox
    $script:BindAddressTextBox.Text = $script:ConfigData.BindAddress
    $script:BindAddressTextBox.Location = New-Object System.Drawing.Point(20, 95)
    $script:BindAddressTextBox.Size = New-Object System.Drawing.Size(200, 25)
    $script:BindAddressTextBox.Add_TextChanged({ 
        $script:ConfigData.BindAddress = $script:BindAddressTextBox.Text 
    })
    $script:ContentPanel.Controls.Add($script:BindAddressTextBox)
    
    # Frontend bind port
    $portLabel = New-Object System.Windows.Forms.Label
    $portLabel.Text = "Frontend Bind Port:"
    $portLabel.Location = New-Object System.Drawing.Point(250, 70)
    $portLabel.Size = New-Object System.Drawing.Size(150, 20)
    $script:ContentPanel.Controls.Add($portLabel)
    
    $script:BindPortTextBox = New-Object System.Windows.Forms.TextBox
    $script:BindPortTextBox.Text = $script:ConfigData.BindPort
    $script:BindPortTextBox.Location = New-Object System.Drawing.Point(250, 95)
    $script:BindPortTextBox.Size = New-Object System.Drawing.Size(100, 25)
    $script:BindPortTextBox.Add_TextChanged({ 
        $script:ConfigData.BindPort = $script:BindPortTextBox.Text 
    })
    $script:ContentPanel.Controls.Add($script:BindPortTextBox)
    
    # GUI bind address
    $guiBindLabel = New-Object System.Windows.Forms.Label
    $guiBindLabel.Text = "GUI Bind Address:"
    $guiBindLabel.Location = New-Object System.Drawing.Point(20, 140)
    $guiBindLabel.Size = New-Object System.Drawing.Size(200, 20)
    $script:ContentPanel.Controls.Add($guiBindLabel)
    
    $script:GUIBindAddressTextBox = New-Object System.Windows.Forms.TextBox
    $script:GUIBindAddressTextBox.Text = $script:ConfigData.GUIBindAddress
    $script:GUIBindAddressTextBox.Location = New-Object System.Drawing.Point(20, 165)
    $script:GUIBindAddressTextBox.Size = New-Object System.Drawing.Size(200, 25)
    $script:GUIBindAddressTextBox.Add_TextChanged({ 
        $script:ConfigData.GUIBindAddress = $script:GUIBindAddressTextBox.Text 
    })
    $script:ContentPanel.Controls.Add($script:GUIBindAddressTextBox)
    
    # GUI bind port
    $guiPortLabel = New-Object System.Windows.Forms.Label
    $guiPortLabel.Text = "GUI Bind Port:"
    $guiPortLabel.Location = New-Object System.Drawing.Point(250, 140)
    $guiPortLabel.Size = New-Object System.Drawing.Size(150, 20)
    $script:ContentPanel.Controls.Add($guiPortLabel)
    
    $script:GUIBindPortTextBox = New-Object System.Windows.Forms.TextBox
    $script:GUIBindPortTextBox.Text = $script:ConfigData.GUIBindPort
    $script:GUIBindPortTextBox.Location = New-Object System.Drawing.Point(250, 165)
    $script:GUIBindPortTextBox.Size = New-Object System.Drawing.Size(100, 25)
    $script:GUIBindPortTextBox.Add_TextChanged({ 
        $script:ConfigData.GUIBindPort = $script:GUIBindPortTextBox.Text 
    })
    $script:ContentPanel.Controls.Add($script:GUIBindPortTextBox)
    
    # Organization name
    $orgLabel = New-Object System.Windows.Forms.Label
    $orgLabel.Text = "Organization Name:"
    $orgLabel.Location = New-Object System.Drawing.Point(20, 210)
    $orgLabel.Size = New-Object System.Drawing.Size(200, 20)
    $script:ContentPanel.Controls.Add($orgLabel)
    
    $script:OrganizationTextBox = New-Object System.Windows.Forms.TextBox
    $script:OrganizationTextBox.Text = $script:ConfigData.OrganizationName
    $script:OrganizationTextBox.Location = New-Object System.Drawing.Point(20, 235)
    $script:OrganizationTextBox.Size = New-Object System.Drawing.Size(300, 25)
    $script:OrganizationTextBox.Add_TextChanged({ 
        $script:ConfigData.OrganizationName = $script:OrganizationTextBox.Text 
    })
    $script:ContentPanel.Controls.Add($script:OrganizationTextBox)
}

# Step 6: Authentication
function Show-AuthenticationStep {
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Authentication Configuration"
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 30)
    $script:ContentPanel.Controls.Add($titleLabel)
    
    $descLabel = New-Object System.Windows.Forms.Label
    $descLabel.Text = "Configure the initial administrator account for Velociraptor:"
    $descLabel.Location = New-Object System.Drawing.Point(20, 60)
    $descLabel.Size = New-Object System.Drawing.Size(500, 20)
    $script:ContentPanel.Controls.Add($descLabel)
    
    # Admin username
    $usernameLabel = New-Object System.Windows.Forms.Label
    $usernameLabel.Text = "Admin Username:"
    $usernameLabel.Location = New-Object System.Drawing.Point(20, 100)
    $usernameLabel.Size = New-Object System.Drawing.Size(150, 20)
    $script:ContentPanel.Controls.Add($usernameLabel)
    
    $script:AdminUsernameTextBox = New-Object System.Windows.Forms.TextBox
    $script:AdminUsernameTextBox.Text = $script:ConfigData.AdminUsername
    $script:AdminUsernameTextBox.Location = New-Object System.Drawing.Point(20, 125)
    $script:AdminUsernameTextBox.Size = New-Object System.Drawing.Size(200, 25)
    $script:AdminUsernameTextBox.Add_TextChanged({ 
        $script:ConfigData.AdminUsername = $script:AdminUsernameTextBox.Text 
    })
    $script:ContentPanel.Controls.Add($script:AdminUsernameTextBox)
    
    # Admin password
    $passwordLabel = New-Object System.Windows.Forms.Label
    $passwordLabel.Text = "Admin Password:"
    $passwordLabel.Location = New-Object System.Drawing.Point(20, 170)
    $passwordLabel.Size = New-Object System.Drawing.Size(150, 20)
    $script:ContentPanel.Controls.Add($passwordLabel)
    
    $script:AdminPasswordTextBox = New-Object System.Windows.Forms.TextBox
    $script:AdminPasswordTextBox.Text = $script:ConfigData.AdminPassword
    $script:AdminPasswordTextBox.Location = New-Object System.Drawing.Point(20, 195)
    $script:AdminPasswordTextBox.Size = New-Object System.Drawing.Size(200, 25)
    $script:AdminPasswordTextBox.UseSystemPasswordChar = $true
    $script:AdminPasswordTextBox.Add_TextChanged({ 
        $script:ConfigData.AdminPassword = $script:AdminPasswordTextBox.Text 
    })
    $script:ContentPanel.Controls.Add($script:AdminPasswordTextBox)
    
    # Confirm password
    $confirmLabel = New-Object System.Windows.Forms.Label
    $confirmLabel.Text = "Confirm Password:"
    $confirmLabel.Location = New-Object System.Drawing.Point(20, 240)
    $confirmLabel.Size = New-Object System.Drawing.Size(150, 20)
    $script:ContentPanel.Controls.Add($confirmLabel)
    
    $script:ConfirmPasswordTextBox = New-Object System.Windows.Forms.TextBox
    $script:ConfirmPasswordTextBox.Location = New-Object System.Drawing.Point(20, 265)
    $script:ConfirmPasswordTextBox.Size = New-Object System.Drawing.Size(200, 25)
    $script:ConfirmPasswordTextBox.UseSystemPasswordChar = $true
    $script:ContentPanel.Controls.Add($script:ConfirmPasswordTextBox)
    
    # Generate password button
    $generateButton = New-Object System.Windows.Forms.Button
    $generateButton.Text = "Generate Secure Password"
    $generateButton.Location = New-Object System.Drawing.Point(250, 195)
    $generateButton.Size = New-Object System.Drawing.Size(180, 25)
    $generateButton.Add_Click({
        $password = New-SecurePassword
        $script:AdminPasswordTextBox.Text = $password
        $script:ConfirmPasswordTextBox.Text = $password
        $script:ConfigData.AdminPassword = $password
        [System.Windows.Forms.MessageBox]::Show("Generated password: $password`n`nPlease save this password securely!", "Generated Password", "OK", "Information")
    })
    $script:ContentPanel.Controls.Add($generateButton)
}

# Step 7: Review
function Show-ReviewStep {
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Review Configuration"
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 30)
    $script:ContentPanel.Controls.Add($titleLabel)
    
    $descLabel = New-Object System.Windows.Forms.Label
    $descLabel.Text = "Please review your configuration settings before generating the configuration file:"
    $descLabel.Location = New-Object System.Drawing.Point(20, 60)
    $descLabel.Size = New-Object System.Drawing.Size(600, 20)
    $script:ContentPanel.Controls.Add($descLabel)
    
    # Create review text
    $reviewText = @"
Deployment Type: $($script:ConfigData.DeploymentType)
Datastore Directory: $($script:ConfigData.DatastoreDirectory)
Logs Directory: $($script:ConfigData.LogsDirectory)
Certificate Expiration: $($script:ConfigData.CertificateExpiration)
Restrict VQL: $($script:ConfigData.RestrictVQL)
Use Registry: $($script:ConfigData.UseRegistry)
Frontend Address: $($script:ConfigData.BindAddress):$($script:ConfigData.BindPort)
GUI Address: $($script:ConfigData.GUIBindAddress):$($script:ConfigData.GUIBindPort)
Organization: $($script:ConfigData.OrganizationName)
Admin Username: $($script:ConfigData.AdminUsername)
"@
    
    $reviewTextBox = New-Object System.Windows.Forms.TextBox
    $reviewTextBox.Text = $reviewText
    $reviewTextBox.Location = New-Object System.Drawing.Point(20, 90)
    $reviewTextBox.Size = New-Object System.Drawing.Size(700, 280)
    $reviewTextBox.Multiline = $true
    $reviewTextBox.ReadOnly = $true
    $reviewTextBox.ScrollBars = "Vertical"
    $reviewTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $script:ContentPanel.Controls.Add($reviewTextBox)
}

# Step 8: Complete
function Show-CompleteStep {
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Configuration Complete!"
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 30)
    $titleLabel.ForeColor = [System.Drawing.Color]::Green
    $script:ContentPanel.Controls.Add($titleLabel)
    
    $successLabel = New-Object System.Windows.Forms.Label
    $successLabel.Text = @"
Your Velociraptor configuration has been generated successfully!

Configuration file saved to: $($script:ConfigData.OutputPath)

Next steps:
1. Review the generated configuration file
2. Deploy Velociraptor using the configuration
3. Access the web interface at https://$($script:ConfigData.GUIBindAddress):$($script:ConfigData.GUIBindPort)
4. Login with username: $($script:ConfigData.AdminUsername)

Click Finish to close the wizard.
"@
    $successLabel.Location = New-Object System.Drawing.Point(20, 60)
    $successLabel.Size = New-Object System.Drawing.Size(700, 200)
    $successLabel.Font = New-Object System.Drawing.Font("Arial", 11)
    $script:ContentPanel.Controls.Add($successLabel)
    
    # Open config button
    $openConfigButton = New-Object System.Windows.Forms.Button
    $openConfigButton.Text = "Open Configuration File"
    $openConfigButton.Location = New-Object System.Drawing.Point(20, 280)
    $openConfigButton.Size = New-Object System.Drawing.Size(180, 35)
    $openConfigButton.Add_Click({
        if (Test-Path $script:ConfigData.OutputPath) {
            Start-Process "notepad.exe" -ArgumentList $script:ConfigData.OutputPath
        }
    })
    $script:ContentPanel.Controls.Add($openConfigButton)
    
    # Deploy button
    $deployButton = New-Object System.Windows.Forms.Button
    $deployButton.Text = "Deploy Now"
    $deployButton.Location = New-Object System.Drawing.Point(220, 280)
    $deployButton.Size = New-Object System.Drawing.Size(120, 35)
    $deployButton.Add_Click({
        Start-VelociraptorDeployment
    })
    $script:ContentPanel.Controls.Add($deployButton)
}

# Generate configuration file
function Generate-Configuration {
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $configFileName = "velociraptor_config_$timestamp.yaml"
        $script:ConfigData.OutputPath = Join-Path $PWD $configFileName
        
        # Use our configuration template generator
        $templateResult = New-VelociraptorConfigurationTemplate -TemplateName $script:ConfigData.DeploymentType -OutputPath $script:ConfigData.OutputPath -ConfigurationData $script:ConfigData
        
        if ($templateResult.Success) {
            [System.Windows.Forms.MessageBox]::Show("Configuration generated successfully!`nSaved to: $($script:ConfigData.OutputPath)", "Success", "OK", "Information")
        } else {
            throw $templateResult.Error
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to generate configuration: $($_.Exception.Message)", "Error", "OK", "Error")
    }
}

# Generate secure password
function New-SecurePassword {
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
    $password = ""
    for ($i = 0; $i -lt 16; $i++) {
        $password += $chars[(Get-Random -Maximum $chars.Length)]
    }
    return $password
}

# Start Velociraptor deployment
function Start-VelociraptorDeployment {
    try {
        $result = [System.Windows.Forms.MessageBox]::Show("This will start Velociraptor deployment using the generated configuration.`n`nContinue?", "Deploy Velociraptor", "YesNo", "Question")
        if ($result -eq "Yes") {
            # Use our deployment functions
            switch ($script:ConfigData.DeploymentType) {
                "Server" {
                    # Start server deployment
                    Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$PSScriptRoot\..\Deploy_Velociraptor_Server.ps1`" -ConfigPath `"$($script:ConfigData.OutputPath)`""
                }
                "Standalone" {
                    # Start standalone deployment
                    Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$PSScriptRoot\..\Deploy_Velociraptor_Standalone.ps1`""
                }
                "Client" {
                    [System.Windows.Forms.MessageBox]::Show("Client configuration generated. Use this file to configure Velociraptor clients.", "Client Configuration", "OK", "Information")
                }
            }
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to start deployment: $($_.Exception.Message)", "Deployment Error", "OK", "Error")
    }
}

# Main execution
try {
    Write-Host "Starting Velociraptor Configuration Wizard..." -ForegroundColor Cyan
    
    # Create and show the wizard
    $script:MainForm = New-WizardForm
    Show-CurrentStep
    
    if ($StartMinimized) {
        $script:MainForm.WindowState = "Minimized"
    }
    
    # Show the form
    [System.Windows.Forms.Application]::Run($script:MainForm)
    
    Write-Host "Velociraptor Configuration Wizard completed." -ForegroundColor Green
}
catch {
    Write-Host "GUI initialization failed: $($_.Exception.Message)" -ForegroundColor Red
    [System.Windows.Forms.MessageBox]::Show("Failed to initialize GUI: $($_.Exception.Message)", "Error", "OK", "Error")
}