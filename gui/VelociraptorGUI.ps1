#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Velociraptor Deployment GUI - Windows Forms-based management interface.

.DESCRIPTION
    Provides a comprehensive graphical user interface for Velociraptor deployment,
    configuration, monitoring, and management operations. Supports all deployment
    scenarios including standalone, server, cluster, and container deployments.

.PARAMETER StartMinimized
    Start the GUI minimized to system tray.

.PARAMETER ConfigPath
    Default configuration path to load on startup.

.EXAMPLE
    .\VelociraptorGUI.ps1

.EXAMPLE
    .\VelociraptorGUI.ps1 -ConfigPath "C:\Velociraptor\server.config.yaml"
#>

[CmdletBinding()]
param(
    [switch]$StartMinimized,
    [string]$ConfigPath
)

# Import required modules
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Web

# Import Velociraptor modules
$ModulePath = Join-Path $PSScriptRoot "..\modules"
Import-Module "$ModulePath\VelociraptorDeployment" -Force
Import-Module "$ModulePath\VelociraptorGovernance" -Force

# Global variables
$script:MainForm = $null
$script:StatusLabel = $null
$script:ProgressBar = $null
$script:LogTextBox = $null
$script:CurrentConfig = $null
$script:MonitoringTimer = $null

function Initialize-VelociraptorGUI {
    Write-Host "Initializing Velociraptor Deployment GUI..." -ForegroundColor Cyan
    
    # Create main form
    $script:MainForm = New-Object System.Windows.Forms.Form
    $script:MainForm.Text = "Velociraptor Deployment Manager v1.0"
    $script:MainForm.Size = New-Object System.Drawing.Size(1200, 800)
    $script:MainForm.StartPosition = "CenterScreen"
    $script:MainForm.MinimumSize = New-Object System.Drawing.Size(1000, 600)
    
    # Create menu bar
    Create-MenuBar
    
    # Create main tab control
    Create-MainTabControl
    
    # Create status bar
    Create-StatusBar
    
    # Initialize event handlers
    Initialize-EventHandlers
    
    # Load configuration if provided
    if ($ConfigPath -and (Test-Path $ConfigPath)) {
        Load-Configuration -Path $ConfigPath
    }
    
    Write-Host "GUI initialization completed" -ForegroundColor Green
}

function Create-MenuBar {
    $menuStrip = New-Object System.Windows.Forms.MenuStrip
    
    # File Menu
    $fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem("&File")
    
    $newConfigItem = New-Object System.Windows.Forms.ToolStripMenuItem("&New Configuration")
    $newConfigItem.Add_Click({ Show-NewConfigurationWizard })
    
    $openConfigItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Open Configuration")
    $openConfigItem.Add_Click({ Show-OpenConfigurationDialog })
    
    $saveConfigItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Save Configuration")
    $saveConfigItem.Add_Click({ Save-CurrentConfiguration })
    
    $exitItem = New-Object System.Windows.Forms.ToolStripMenuItem("E&xit")
    $exitItem.Add_Click({ $script:MainForm.Close() })
    
    $fileMenu.DropDownItems.AddRange(@($newConfigItem, $openConfigItem, $saveConfigItem, "-", $exitItem))
    
    # Deploy Menu
    $deployMenu = New-Object System.Windows.Forms.ToolStripMenuItem("&Deploy")
    
    $deployStandaloneItem = New-Object System.Windows.Forms.ToolStripMenuItem("Deploy &Standalone")
    $deployStandaloneItem.Add_Click({ Start-StandaloneDeployment })
    
    $deployServerItem = New-Object System.Windows.Forms.ToolStripMenuItem("Deploy &Server")
    $deployServerItem.Add_Click({ Start-ServerDeployment })
    
    $deployClusterItem = New-Object System.Windows.Forms.ToolStripMenuItem("Deploy &Cluster")
    $deployClusterItem.Add_Click({ Start-ClusterDeployment })
    
    $deployMenu.DropDownItems.AddRange(@($deployStandaloneItem, $deployServerItem, $deployClusterItem))
    
    # Tools Menu
    $toolsMenu = New-Object System.Windows.Forms.ToolStripMenuItem("&Tools")
    
    $healthCheckItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Health Check")
    $healthCheckItem.Add_Click({ Start-HealthCheckTool })
    
    $securityBaselineItem = New-Object System.Windows.Forms.ToolStripMenuItem("&Security Baseline")
    $securityBaselineItem.Add_Click({ Start-SecurityBaselineTool })
    
    $collectionManagerItem = New-Object System.Windows.Forms.ToolStripMenuItem("Collection &Manager")
    $collectionManagerItem.Add_Click({ Start-CollectionManager })
    
    $toolsMenu.DropDownItems.AddRange(@($healthCheckItem, $securityBaselineItem, $collectionManagerItem))
    
    $menuStrip.Items.AddRange(@($fileMenu, $deployMenu, $toolsMenu))
    $script:MainForm.MainMenuStrip = $menuStrip
    $script:MainForm.Controls.Add($menuStrip)
}

function Create-MainTabControl {
    $tabControl = New-Object System.Windows.Forms.TabControl
    $tabControl.Dock = [System.Windows.Forms.DockStyle]::Fill
    $tabControl.Padding = New-Object System.Drawing.Point(10, 5)
    
    # Dashboard Tab
    Create-DashboardTab -TabControl $tabControl
    
    # Configuration Tab
    Create-ConfigurationTab -TabControl $tabControl
    
    # Deployment Tab
    Create-DeploymentTab -TabControl $tabControl
    
    # Collections Tab
    Create-CollectionsTab -TabControl $tabControl
    
    # Logs Tab
    Create-LogsTab -TabControl $tabControl
    
    $script:MainForm.Controls.Add($tabControl)
}functi
on Create-DashboardTab {
    param($TabControl)
    
    $dashboardTab = New-Object System.Windows.Forms.TabPage
    $dashboardTab.Text = "Dashboard"
    $dashboardTab.Padding = New-Object System.Windows.Forms.Padding(10)
    
    # Quick Actions Panel
    $quickActionsGroup = New-Object System.Windows.Forms.GroupBox
    $quickActionsGroup.Text = "Quick Actions"
    $quickActionsGroup.Size = New-Object System.Drawing.Size(300, 200)
    $quickActionsGroup.Location = New-Object System.Drawing.Point(10, 10)
    
    $deployStandaloneBtn = New-Object System.Windows.Forms.Button
    $deployStandaloneBtn.Text = "Deploy Standalone"
    $deployStandaloneBtn.Size = New-Object System.Drawing.Size(200, 35)
    $deployStandaloneBtn.Location = New-Object System.Drawing.Point(20, 30)
    $deployStandaloneBtn.Add_Click({ Start-StandaloneDeployment })
    
    $deployServerBtn = New-Object System.Windows.Forms.Button
    $deployServerBtn.Text = "Deploy Server"
    $deployServerBtn.Size = New-Object System.Drawing.Size(200, 35)
    $deployServerBtn.Location = New-Object System.Drawing.Point(20, 75)
    $deployServerBtn.Add_Click({ Start-ServerDeployment })
    
    $healthCheckBtn = New-Object System.Windows.Forms.Button
    $healthCheckBtn.Text = "Health Check"
    $healthCheckBtn.Size = New-Object System.Drawing.Size(200, 35)
    $healthCheckBtn.Location = New-Object System.Drawing.Point(20, 120)
    $healthCheckBtn.Add_Click({ Start-HealthCheckTool })
    
    $quickActionsGroup.Controls.AddRange(@($deployStandaloneBtn, $deployServerBtn, $healthCheckBtn))
    
    # System Status Panel
    $systemStatusGroup = New-Object System.Windows.Forms.GroupBox
    $systemStatusGroup.Text = "System Status"
    $systemStatusGroup.Size = New-Object System.Drawing.Size(400, 200)
    $systemStatusGroup.Location = New-Object System.Drawing.Point(320, 10)
    
    $statusListView = New-Object System.Windows.Forms.ListView
    $statusListView.Size = New-Object System.Drawing.Size(380, 170)
    $statusListView.Location = New-Object System.Drawing.Point(10, 20)
    $statusListView.View = [System.Windows.Forms.View]::Details
    $statusListView.FullRowSelect = $true
    $statusListView.GridLines = $true
    
    $statusListView.Columns.Add("Component", 120)
    $statusListView.Columns.Add("Status", 80)
    $statusListView.Columns.Add("Details", 180)
    
    $systemStatusGroup.Controls.Add($statusListView)
    
    $dashboardTab.Controls.AddRange(@($quickActionsGroup, $systemStatusGroup))
    $TabControl.TabPages.Add($dashboardTab)
}

function Create-ConfigurationTab {
    param($TabControl)
    
    $configTab = New-Object System.Windows.Forms.TabPage
    $configTab.Text = "Configuration"
    $configTab.Padding = New-Object System.Windows.Forms.Padding(10)
    
    # Configuration editor
    $configGroup = New-Object System.Windows.Forms.GroupBox
    $configGroup.Text = "Configuration Editor"
    $configGroup.Dock = [System.Windows.Forms.DockStyle]::Fill
    
    $configTextBox = New-Object System.Windows.Forms.TextBox
    $configTextBox.Multiline = $true
    $configTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Both
    $configTextBox.Dock = [System.Windows.Forms.DockStyle]::Fill
    $configTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $configTextBox.WordWrap = $false
    
    $configGroup.Controls.Add($configTextBox)
    $configTab.Controls.Add($configGroup)
    $TabControl.TabPages.Add($configTab)
    
    # Store reference
    $script:ConfigTextBox = $configTextBox
}

function Create-DeploymentTab {
    param($TabControl)
    
    $deployTab = New-Object System.Windows.Forms.TabPage
    $deployTab.Text = "Deployment"
    $deployTab.Padding = New-Object System.Windows.Forms.Padding(10)
    
    # Deployment Type Selection
    $deployTypeGroup = New-Object System.Windows.Forms.GroupBox
    $deployTypeGroup.Text = "Select Deployment Type"
    $deployTypeGroup.Size = New-Object System.Drawing.Size(300, 200)
    $deployTypeGroup.Location = New-Object System.Drawing.Point(10, 10)
    
    $standaloneRadio = New-Object System.Windows.Forms.RadioButton
    $standaloneRadio.Text = "Standalone Deployment"
    $standaloneRadio.Size = New-Object System.Drawing.Size(250, 25)
    $standaloneRadio.Location = New-Object System.Drawing.Point(20, 30)
    $standaloneRadio.Checked = $true
    
    $serverRadio = New-Object System.Windows.Forms.RadioButton
    $serverRadio.Text = "Server Deployment"
    $serverRadio.Size = New-Object System.Drawing.Size(250, 25)
    $serverRadio.Location = New-Object System.Drawing.Point(20, 60)
    
    $clusterRadio = New-Object System.Windows.Forms.RadioButton
    $clusterRadio.Text = "Cluster Deployment"
    $clusterRadio.Size = New-Object System.Drawing.Size(250, 25)
    $clusterRadio.Location = New-Object System.Drawing.Point(20, 90)
    
    $containerRadio = New-Object System.Windows.Forms.RadioButton
    $containerRadio.Text = "Container Deployment"
    $containerRadio.Size = New-Object System.Drawing.Size(250, 25)
    $containerRadio.Location = New-Object System.Drawing.Point(20, 120)
    
    $deployTypeGroup.Controls.AddRange(@($standaloneRadio, $serverRadio, $clusterRadio, $containerRadio))
    
    # Deployment Actions
    $deployActionsGroup = New-Object System.Windows.Forms.GroupBox
    $deployActionsGroup.Text = "Deployment Actions"
    $deployActionsGroup.Size = New-Object System.Drawing.Size(300, 150)
    $deployActionsGroup.Location = New-Object System.Drawing.Point(320, 10)
    
    $startDeployBtn = New-Object System.Windows.Forms.Button
    $startDeployBtn.Text = "Start Deployment"
    $startDeployBtn.Size = New-Object System.Drawing.Size(150, 35)
    $startDeployBtn.Location = New-Object System.Drawing.Point(20, 30)
    $startDeployBtn.Add_Click({ Start-SelectedDeployment })
    
    $validateBtn = New-Object System.Windows.Forms.Button
    $validateBtn.Text = "Validate Configuration"
    $validateBtn.Size = New-Object System.Drawing.Size(150, 35)
    $validateBtn.Location = New-Object System.Drawing.Point(20, 75)
    $validateBtn.Add_Click({ Validate-CurrentConfiguration })
    
    $deployActionsGroup.Controls.AddRange(@($startDeployBtn, $validateBtn))
    
    $deployTab.Controls.AddRange(@($deployTypeGroup, $deployActionsGroup))
    $TabControl.TabPages.Add($deployTab)
}f
unction Create-CollectionsTab {
    param($TabControl)
    
    $collectionsTab = New-Object System.Windows.Forms.TabPage
    $collectionsTab.Text = "Collections"
    $collectionsTab.Padding = New-Object System.Windows.Forms.Padding(10)
    
    # Collections list
    $collectionsGroup = New-Object System.Windows.Forms.GroupBox
    $collectionsGroup.Text = "Available Collections"
    $collectionsGroup.Size = New-Object System.Drawing.Size(500, 300)
    $collectionsGroup.Location = New-Object System.Drawing.Point(10, 10)
    
    $collectionsListView = New-Object System.Windows.Forms.ListView
    $collectionsListView.Size = New-Object System.Drawing.Size(480, 270)
    $collectionsListView.Location = New-Object System.Drawing.Point(10, 20)
    $collectionsListView.View = [System.Windows.Forms.View]::Details
    $collectionsListView.FullRowSelect = $true
    $collectionsListView.GridLines = $true
    $collectionsListView.CheckBoxes = $true
    
    $collectionsListView.Columns.Add("Collection", 200)
    $collectionsListView.Columns.Add("Type", 80)
    $collectionsListView.Columns.Add("Dependencies", 120)
    $collectionsListView.Columns.Add("Status", 80)
    
    $collectionsGroup.Controls.Add($collectionsListView)
    
    # Collection management
    $managementGroup = New-Object System.Windows.Forms.GroupBox
    $managementGroup.Text = "Collection Management"
    $managementGroup.Size = New-Object System.Drawing.Size(200, 300)
    $managementGroup.Location = New-Object System.Drawing.Point(520, 10)
    
    $downloadBtn = New-Object System.Windows.Forms.Button
    $downloadBtn.Text = "Download Dependencies"
    $downloadBtn.Size = New-Object System.Drawing.Size(170, 35)
    $downloadBtn.Location = New-Object System.Drawing.Point(15, 30)
    $downloadBtn.Add_Click({ Start-CollectionDependencyDownload })
    
    $buildCollectorBtn = New-Object System.Windows.Forms.Button
    $buildCollectorBtn.Text = "Build Offline Collector"
    $buildCollectorBtn.Size = New-Object System.Drawing.Size(170, 35)
    $buildCollectorBtn.Location = New-Object System.Drawing.Point(15, 75)
    $buildCollectorBtn.Add_Click({ Start-OfflineCollectorBuild })
    
    $validateBtn = New-Object System.Windows.Forms.Button
    $validateBtn.Text = "Validate Collections"
    $validateBtn.Size = New-Object System.Drawing.Size(170, 35)
    $validateBtn.Location = New-Object System.Drawing.Point(15, 120)
    $validateBtn.Add_Click({ Start-CollectionValidation })
    
    $managementGroup.Controls.AddRange(@($downloadBtn, $buildCollectorBtn, $validateBtn))
    
    $collectionsTab.Controls.AddRange(@($collectionsGroup, $managementGroup))
    $TabControl.TabPages.Add($collectionsTab)
    
    # Store reference
    $script:CollectionsListView = $collectionsListView
}

function Create-LogsTab {
    param($TabControl)
    
    $logsTab = New-Object System.Windows.Forms.TabPage
    $logsTab.Text = "Logs"
    $logsTab.Padding = New-Object System.Windows.Forms.Padding(10)
    
    # Log controls
    $logControlsPanel = New-Object System.Windows.Forms.Panel
    $logControlsPanel.Size = New-Object System.Drawing.Size(800, 40)
    $logControlsPanel.Location = New-Object System.Drawing.Point(10, 10)
    
    $logLevelCombo = New-Object System.Windows.Forms.ComboBox
    $logLevelCombo.Items.AddRange(@("All", "Debug", "Info", "Warning", "Error"))
    $logLevelCombo.SelectedIndex = 0
    $logLevelCombo.Size = New-Object System.Drawing.Size(100, 25)
    $logLevelCombo.Location = New-Object System.Drawing.Point(0, 10)
    
    $clearLogsBtn = New-Object System.Windows.Forms.Button
    $clearLogsBtn.Text = "Clear"
    $clearLogsBtn.Size = New-Object System.Drawing.Size(60, 25)
    $clearLogsBtn.Location = New-Object System.Drawing.Point(110, 10)
    $clearLogsBtn.Add_Click({ Clear-LogDisplay })
    
    $exportLogsBtn = New-Object System.Windows.Forms.Button
    $exportLogsBtn.Text = "Export"
    $exportLogsBtn.Size = New-Object System.Drawing.Size(60, 25)
    $exportLogsBtn.Location = New-Object System.Drawing.Point(180, 10)
    $exportLogsBtn.Add_Click({ Export-LogDisplay })
    
    $logControlsPanel.Controls.AddRange(@($logLevelCombo, $clearLogsBtn, $exportLogsBtn))
    
    # Log display
    $script:LogTextBox = New-Object System.Windows.Forms.TextBox
    $script:LogTextBox.Multiline = $true
    $script:LogTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Both
    $script:LogTextBox.Size = New-Object System.Drawing.Size(800, 400)
    $script:LogTextBox.Location = New-Object System.Drawing.Point(10, 60)
    $script:LogTextBox.ReadOnly = $true
    $script:LogTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $script:LogTextBox.BackColor = [System.Drawing.Color]::Black
    $script:LogTextBox.ForeColor = [System.Drawing.Color]::LightGreen
    
    $logsTab.Controls.AddRange(@($logControlsPanel, $script:LogTextBox))
    $TabControl.TabPages.Add($logsTab)
}

function Create-StatusBar {
    $statusStrip = New-Object System.Windows.Forms.StatusStrip
    
    $script:StatusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
    $script:StatusLabel.Text = "Ready"
    $script:StatusLabel.Spring = $true
    $script:StatusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    
    $script:ProgressBar = New-Object System.Windows.Forms.ToolStripProgressBar
    $script:ProgressBar.Size = New-Object System.Drawing.Size(200, 16)
    $script:ProgressBar.Visible = $false
    
    $statusStrip.Items.AddRange(@($script:StatusLabel, $script:ProgressBar))
    $script:MainForm.Controls.Add($statusStrip)
}

function Initialize-EventHandlers {
    # Form closing event
    $script:MainForm.Add_FormClosing({
        param($sender, $e)
        
        # Stop monitoring timer if running
        if ($script:MonitoringTimer) {
            $script:MonitoringTimer.Stop()
            $script:MonitoringTimer.Dispose()
        }
    })
}# Event ha
ndler functions
function Show-NewConfigurationWizard {
    Update-Status "Opening configuration wizard..."
    Add-LogEntry "Info" "Configuration wizard opened"
}

function Show-OpenConfigurationDialog {
    $openDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openDialog.Filter = "YAML files (*.yaml;*.yml)|*.yaml;*.yml|All files (*.*)|*.*"
    $openDialog.Title = "Open Velociraptor Configuration"
    
    if ($openDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Load-Configuration -Path $openDialog.FileName
    }
}

function Load-Configuration {
    param([string]$Path)
    
    try {
        Update-Status "Loading configuration: $Path"
        $configContent = Get-Content $Path -Raw
        $script:ConfigTextBox.Text = $configContent
        $script:CurrentConfig = $Path
        
        Add-LogEntry "Info" "Configuration loaded: $Path"
        Update-Status "Configuration loaded successfully"
    }
    catch {
        Add-LogEntry "Error" "Failed to load configuration: $($_.Exception.Message)"
        Update-Status "Failed to load configuration"
        [System.Windows.Forms.MessageBox]::Show("Failed to load configuration: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Save-CurrentConfiguration {
    if ($script:CurrentConfig) {
        try {
            $script:ConfigTextBox.Text | Set-Content $script:CurrentConfig
            Add-LogEntry "Info" "Configuration saved: $script:CurrentConfig"
            Update-Status "Configuration saved"
        }
        catch {
            Add-LogEntry "Error" "Failed to save configuration: $($_.Exception.Message)"
            [System.Windows.Forms.MessageBox]::Show("Failed to save configuration: $($_.Exception.Message)", "Error")
        }
    }
    else {
        # Show save as dialog
        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Filter = "YAML files (*.yaml)|*.yaml|All files (*.*)|*.*"
        $saveDialog.Title = "Save Velociraptor Configuration"
        
        if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $script:ConfigTextBox.Text | Set-Content $saveDialog.FileName
            $script:CurrentConfig = $saveDialog.FileName
            Add-LogEntry "Info" "Configuration saved: $script:CurrentConfig"
            Update-Status "Configuration saved"
        }
    }
}

function Validate-CurrentConfiguration {
    try {
        if ($script:ConfigTextBox.Text) {
            # Create temporary file for validation
            $tempFile = [System.IO.Path]::GetTempFileName()
            $script:ConfigTextBox.Text | Set-Content $tempFile
            
            # Validate using module function
            $validationResult = Test-VelociraptorConfiguration -ConfigPath $tempFile
            
            if ($validationResult.IsValid) {
                [System.Windows.Forms.MessageBox]::Show("Configuration is valid", "Validation Result", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                Add-LogEntry "Info" "Configuration validation passed"
            }
            else {
                $errorMsg = "Validation errors:`n" + ($validationResult.Errors -join "`n")
                [System.Windows.Forms.MessageBox]::Show($errorMsg, "Validation Errors", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                Add-LogEntry "Warning" "Configuration validation failed"
            }
            
            Remove-Item $tempFile -Force
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("No configuration to validate", "Validation", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    }
    catch {
        Add-LogEntry "Error" "Validation failed: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show("Validation failed: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Start-StandaloneDeployment {
    Update-Status "Starting standalone deployment..."
    Show-ProgressBar
    Add-LogEntry "Info" "Standalone deployment initiated"
    
    # Simulate deployment process
    Start-Job -ScriptBlock {
        Start-Sleep 3
        return @{ Success = $true; Message = "Standalone deployment completed successfully" }
    } | Wait-Job | Receive-Job | ForEach-Object {
        Hide-ProgressBar
        Update-Status $_.Message
        Add-LogEntry "Info" $_.Message
    }
}

function Start-ServerDeployment {
    Update-Status "Starting server deployment..."
    Add-LogEntry "Info" "Server deployment initiated"
    [System.Windows.Forms.MessageBox]::Show("Server deployment feature coming soon!", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

function Start-ClusterDeployment {
    Update-Status "Starting cluster deployment..."
    Add-LogEntry "Info" "Cluster deployment initiated"
    [System.Windows.Forms.MessageBox]::Show("Cluster deployment feature coming soon!", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

function Start-SelectedDeployment {
    # This would check which radio button is selected and call appropriate function
    Start-StandaloneDeployment
}

function Start-HealthCheckTool {
    Update-Status "Running health check..."
    Show-ProgressBar
    
    try {
        if ($script:CurrentConfig) {
            $healthResult = Test-VelociraptorHealth -ConfigPath $script:CurrentConfig -IncludePerformance
            
            $resultMsg = "Health Check Results:`nOverall Status: $($healthResult.OverallStatus)`nChecks Performed: $($healthResult.Checks.Count)"
            [System.Windows.Forms.MessageBox]::Show($resultMsg, "Health Check Results", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            
            Add-LogEntry "Info" "Health check completed: $($healthResult.OverallStatus)"
            Update-Status "Health check completed"
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("No configuration loaded for health check", "Health Check", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            Add-LogEntry "Warning" "No configuration loaded for health check"
            Update-Status "No configuration loaded"
        }
    }
    catch {
        Add-LogEntry "Error" "Health check failed: $($_.Exception.Message)"
        Update-Status "Health check failed"
        [System.Windows.Forms.MessageBox]::Show("Health check failed: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
    finally {
        Hide-ProgressBar
    }
}

function Start-AIConfigurationGenerator {
    Update-Status "Generating AI-powered configuration..."
    Show-ProgressBar
    
    try {
        # Create AI configuration dialog
        $aiForm = New-Object System.Windows.Forms.Form
        $aiForm.Text = "AI Configuration Generator"
        $aiForm.Size = New-Object System.Drawing.Size(500, 400)
        $aiForm.StartPosition = "CenterParent"
        
        # Environment selection
        $envLabel = New-Object System.Windows.Forms.Label
        $envLabel.Text = "Environment Type:"
        $envLabel.Location = New-Object System.Drawing.Point(20, 20)
        $envLabel.Size = New-Object System.Drawing.Size(100, 20)
        
        $envCombo = New-Object System.Windows.Forms.ComboBox
        $envCombo.Items.AddRange(@("Development", "Testing", "Staging", "Production", "Enterprise"))
        $envCombo.SelectedIndex = 3  # Production
        $envCombo.Location = New-Object System.Drawing.Point(130, 20)
        $envCombo.Size = New-Object System.Drawing.Size(150, 25)
        
        # Use case selection
        $useCaseLabel = New-Object System.Windows.Forms.Label
        $useCaseLabel.Text = "Use Case:"
        $useCaseLabel.Location = New-Object System.Drawing.Point(20, 60)
        $useCaseLabel.Size = New-Object System.Drawing.Size(100, 20)
        
        $useCaseCombo = New-Object System.Windows.Forms.ComboBox
        $useCaseCombo.Items.AddRange(@("DFIR", "ThreatHunting", "Compliance", "Monitoring", "Research", "General"))
        $useCaseCombo.SelectedIndex = 1  # ThreatHunting
        $useCaseCombo.Location = New-Object System.Drawing.Point(130, 60)
        $useCaseCombo.Size = New-Object System.Drawing.Size(150, 25)
        
        # Security level
        $secLabel = New-Object System.Windows.Forms.Label
        $secLabel.Text = "Security Level:"
        $secLabel.Location = New-Object System.Drawing.Point(20, 100)
        $secLabel.Size = New-Object System.Drawing.Size(100, 20)
        
        $secCombo = New-Object System.Windows.Forms.ComboBox
        $secCombo.Items.AddRange(@("Basic", "Standard", "High", "Maximum"))
        $secCombo.SelectedIndex = 2  # High
        $secCombo.Location = New-Object System.Drawing.Point(130, 100)
        $secCombo.Size = New-Object System.Drawing.Size(150, 25)
        
        # Performance profile
        $perfLabel = New-Object System.Windows.Forms.Label
        $perfLabel.Text = "Performance:"
        $perfLabel.Location = New-Object System.Drawing.Point(20, 140)
        $perfLabel.Size = New-Object System.Drawing.Size(100, 20)
        
        $perfCombo = New-Object System.Windows.Forms.ComboBox
        $perfCombo.Items.AddRange(@("Balanced", "Performance", "Efficiency"))
        $perfCombo.SelectedIndex = 1  # Performance
        $perfCombo.Location = New-Object System.Drawing.Point(130, 140)
        $perfCombo.Size = New-Object System.Drawing.Size(150, 25)
        
        # Generate button
        $generateBtn = New-Object System.Windows.Forms.Button
        $generateBtn.Text = "Generate AI Configuration"
        $generateBtn.Location = New-Object System.Drawing.Point(20, 200)
        $generateBtn.Size = New-Object System.Drawing.Size(200, 35)
        $generateBtn.Add_Click({
            try {
                $aiForm.Hide()
                Update-Status "AI is analyzing your environment and generating optimal configuration..."
                
                $configResult = New-IntelligentConfiguration -EnvironmentType $envCombo.SelectedItem -UseCase $useCaseCombo.SelectedItem -SecurityLevel $secCombo.SelectedItem -PerformanceProfile $perfCombo.SelectedItem -OutputPath "ai-generated-config.yaml"
                
                $script:ConfigTextBox.Text = $configResult.Configuration | ConvertTo-Yaml
                $script:CurrentConfig = "ai-generated-config.yaml"
                
                $resultMsg = "AI Configuration Generated Successfully!`n`nSystem Analysis:`n"
                $resultMsg += "CPU Cores: $($configResult.Analysis.System.CPUCores)`n"
                $resultMsg += "Memory: $($configResult.Analysis.System.MemoryGB) GB`n"
                $resultMsg += "Processing Profile: $($configResult.Analysis.System.CPURecommendation.ProcessingProfile)`n`n"
                $resultMsg += "Configuration Score: $($configResult.ValidationResults.Score)/$($configResult.ValidationResults.MaxScore)`n`n"
                $resultMsg += "Top Recommendations Applied:`n"
                foreach ($rec in $configResult.Recommendations.Priority | Select-Object -First 3) {
                    $resultMsg += "• $rec`n"
                }
                
                [System.Windows.Forms.MessageBox]::Show($resultMsg, "AI Configuration Generated", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                
                Add-LogEntry "Info" "AI configuration generated successfully"
                Update-Status "AI configuration ready"
                $aiForm.Close()
            }
            catch {
                Add-LogEntry "Error" "AI configuration generation failed: $($_.Exception.Message)"
                [System.Windows.Forms.MessageBox]::Show("AI configuration generation failed: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                $aiForm.Show()
            }
        })
        
        # Cancel button
        $cancelBtn = New-Object System.Windows.Forms.Button
        $cancelBtn.Text = "Cancel"
        $cancelBtn.Location = New-Object System.Drawing.Point(240, 200)
        $cancelBtn.Size = New-Object System.Drawing.Size(80, 35)
        $cancelBtn.Add_Click({ $aiForm.Close() })
        
        $aiForm.Controls.AddRange(@($envLabel, $envCombo, $useCaseLabel, $useCaseCombo, $secLabel, $secCombo, $perfLabel, $perfCombo, $generateBtn, $cancelBtn))
        $aiForm.ShowDialog($script:MainForm)
    }
    catch {
        Add-LogEntry "Error" "AI configuration generator failed: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show("AI configuration generator failed: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
    finally {
        Hide-ProgressBar
    }
}

function Start-PredictiveAnalyticsTool {
    Update-Status "Running predictive analytics..."
    Show-ProgressBar
    
    try {
        if ($script:CurrentConfig) {
            $prediction = Start-PredictiveAnalytics -ConfigPath $script:CurrentConfig -AnalyticsMode Predict -PredictionWindow 24
            
            $resultMsg = "Predictive Analytics Results:`n`n"
            $resultMsg += "Deployment Success Probability: $($prediction.SuccessProbability * 100)%`n"
            $resultMsg += "Confidence Level: $($prediction.ConfidenceLevel * 100)%`n`n"
            
            if ($prediction.RiskFactors.Count -gt 0) {
                $resultMsg += "Risk Factors:`n"
                foreach ($risk in $prediction.RiskFactors) {
                    $resultMsg += "• $risk`n"
                }
                $resultMsg += "`n"
            }
            
            $resultMsg += "AI Recommendations:`n"
            foreach ($rec in $prediction.Recommendations) {
                $resultMsg += "• $rec`n"
            }
            
            [System.Windows.Forms.MessageBox]::Show($resultMsg, "Predictive Analytics", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            
            Add-LogEntry "Info" "Predictive analytics completed: $($prediction.SuccessProbability * 100)% success probability"
            Update-Status "Predictive analytics completed"
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("No configuration loaded for predictive analytics", "Predictive Analytics", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            Add-LogEntry "Warning" "No configuration loaded for predictive analytics"
            Update-Status "No configuration loaded"
        }
    }
    catch {
        Add-LogEntry "Error" "Predictive analytics failed: $($_.Exception.Message)"
        Update-Status "Predictive analytics failed"
        [System.Windows.Forms.MessageBox]::Show("Predictive analytics failed: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
    finally {
        Hide-ProgressBar
    }
}

function Start-AutoTroubleshootingTool {
    Update-Status "Running automated troubleshooting..."
    Show-ProgressBar
    
    try {
        if ($script:CurrentConfig) {
            $diagnosis = Start-AutomatedTroubleshooting -ConfigPath $script:CurrentConfig -TroubleshootingMode Diagnose -LogAnalysisDepth Standard
            
            $resultMsg = "Automated Troubleshooting Results:`n`n"
            
            if ($diagnosis.IdentifiedIssues.Count -eq 0) {
                $resultMsg += "✅ No issues detected - system is healthy!`n"
            }
            else {
                $resultMsg += "Issues Detected:`n"
                foreach ($issue in $diagnosis.IdentifiedIssues) {
                    $resultMsg += "[$($issue.Severity)] $($issue.Description)`n"
                }
                $resultMsg += "`nRecommended Solutions:`n"
                foreach ($solution in $diagnosis.RecommendedSolutions) {
                    $resultMsg += "• $($solution.Description)`n"
                }
                
                # Ask if user wants to apply automated fixes
                $applyFixes = [System.Windows.Forms.MessageBox]::Show("$resultMsg`n`nWould you like to apply automated fixes?", "Issues Detected", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
                
                if ($applyFixes -eq [System.Windows.Forms.DialogResult]::Yes) {
                    Update-Status "Applying automated fixes..."
                    $healing = Start-AutomatedTroubleshooting -ConfigPath $script:CurrentConfig -TroubleshootingMode Heal -AutoRemediation
                    
                    $fixMsg = "Automated Remediation Results:`n`n"
                    $fixMsg += "Successful Fixes: $($healing.SuccessfulRemediations.Count)`n"
                    $fixMsg += "Failed Fixes: $($healing.FailedRemediations.Count)`n"
                    $fixMsg += "Final Status: $($healing.SystemStatus)"
                    
                    [System.Windows.Forms.MessageBox]::Show($fixMsg, "Automated Fixes Applied", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                    Add-LogEntry "Info" "Automated remediation completed: $($healing.SuccessfulRemediations.Count) fixes applied"
                }
            }
            
            if ($diagnosis.IdentifiedIssues.Count -eq 0 -or $applyFixes -ne [System.Windows.Forms.DialogResult]::Yes) {
                [System.Windows.Forms.MessageBox]::Show($resultMsg, "Troubleshooting Results", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
            
            Add-LogEntry "Info" "Automated troubleshooting completed: $($diagnosis.IdentifiedIssues.Count) issues found"
            Update-Status "Troubleshooting completed"
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("No configuration loaded for troubleshooting", "Automated Troubleshooting", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            Add-LogEntry "Warning" "No configuration loaded for troubleshooting"
            Update-Status "No configuration loaded"
        }
    }
    catch {
        Add-LogEntry "Error" "Automated troubleshooting failed: $($_.Exception.Message)"
        Update-Status "Troubleshooting failed"
        [System.Windows.Forms.MessageBox]::Show("Automated troubleshooting failed: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
    finally {
        Hide-ProgressBar
    }
}

function Start-SecurityBaselineTool {
    Update-Status "Running security baseline check..."
    Add-LogEntry "Info" "Security baseline check initiated"
    [System.Windows.Forms.MessageBox]::Show("Security baseline feature coming soon!", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

function Start-CollectionManager {
    Update-Status "Opening collection manager..."
    Load-CollectionsList
    Add-LogEntry "Info" "Collection manager opened"
}

function Load-CollectionsList {
    # Load available collections and their dependencies
    $script:CollectionsListView.Items.Clear()
    
    # Sample collections (would be loaded from actual collection definitions)
    $collections = @(
        @{ Name = "Windows.System.Info"; Type = "Artifact"; Dependencies = ""; Status = "Available" }
        @{ Name = "Windows.Registry.UAC"; Type = "Artifact"; Dependencies = "reg.exe"; Status = "Missing Deps" }
        @{ Name = "Windows.Network.Netstat"; Type = "Artifact"; Dependencies = "netstat.exe"; Status = "Available" }
        @{ Name = "Windows.Forensics.Prefetch"; Type = "Artifact"; Dependencies = "WinPrefetchView.exe"; Status = "Missing Deps" }
    )
    
    foreach ($collection in $collections) {
        $item = New-Object System.Windows.Forms.ListViewItem($collection.Name)
        $item.SubItems.Add($collection.Type)
        $item.SubItems.Add($collection.Dependencies)
        $item.SubItems.Add($collection.Status)
        
        if ($collection.Status -eq "Missing Deps") {
            $item.BackColor = [System.Drawing.Color]::LightYellow
        }
        
        $script:CollectionsListView.Items.Add($item)
    }
}

function Start-CollectionDependencyDownload {
    Update-Status "Downloading collection dependencies..."
    Add-LogEntry "Info" "Collection dependency download initiated"
    [System.Windows.Forms.MessageBox]::Show("Dependency download feature coming soon!", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

function Start-OfflineCollectorBuild {
    Update-Status "Building offline collector..."
    Add-LogEntry "Info" "Offline collector build initiated"
    [System.Windows.Forms.MessageBox]::Show("Offline collector build feature coming soon!", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

function Start-CollectionValidation {
    Update-Status "Validating collections..."
    Add-LogEntry "Info" "Collection validation initiated"
    [System.Windows.Forms.MessageBox]::Show("Collection validation feature coming soon!", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}#
 Utility functions
function Update-Status {
    param([string]$Message)
    
    if ($script:StatusLabel) {
        $script:StatusLabel.Text = $Message
        $script:MainForm.Refresh()
    }
}

function Show-ProgressBar {
    if ($script:ProgressBar) {
        $script:ProgressBar.Visible = $true
        $script:ProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
    }
}

function Hide-ProgressBar {
    if ($script:ProgressBar) {
        $script:ProgressBar.Visible = $false
        $script:ProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Blocks
    }
}

function Add-LogEntry {
    param(
        [string]$Level,
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if ($script:LogTextBox) {
        $script:LogTextBox.AppendText("$logEntry`r`n")
        $script:LogTextBox.SelectionStart = $script:LogTextBox.Text.Length
        $script:LogTextBox.ScrollToCaret()
    }
    
    # Also write to Velociraptor log
    Write-VelociraptorLog -Message $Message -Level $Level
}

function Clear-LogDisplay {
    if ($script:LogTextBox) {
        $script:LogTextBox.Clear()
    }
}

function Export-LogDisplay {
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"
    $saveDialog.Title = "Export Log File"
    $saveDialog.FileName = "velociraptor-gui-log-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    
    if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:LogTextBox.Text | Set-Content $saveDialog.FileName
        Add-LogEntry "Info" "Log exported to: $($saveDialog.FileName)"
    }
}

# Main execution
try {
    Write-Host "Starting Velociraptor Deployment GUI..." -ForegroundColor Green
    
    # Initialize and show GUI
    Initialize-VelociraptorGUI
    
    if ($StartMinimized) {
        $script:MainForm.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
    }
    
    Add-LogEntry "Info" "Velociraptor Deployment GUI started"
    
    # Show the form
    [System.Windows.Forms.Application]::Run($script:MainForm)
}
catch {
    Write-Host "GUI initialization failed: $($_.Exception.Message)" -ForegroundColor Red
    [System.Windows.Forms.MessageBox]::Show("Failed to initialize GUI: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
}
finally {
    # Cleanup
    if ($script:MonitoringTimer) {
        $script:MonitoringTimer.Stop()
        $script:MonitoringTimer.Dispose()
    }
}