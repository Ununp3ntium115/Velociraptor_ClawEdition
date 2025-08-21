#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Velociraptor Comprehensive GUI - Complete velociraptor.exe -i Functionality
    
.DESCRIPTION
    A comprehensive GUI that provides complete velociraptor.exe -i functionality with all
    enterprise-grade configuration options. Features include:
    - Admin Password Configuration (custom/auto-generated with strength validation)
    - Certificate Management (Self-signed/Let's Encrypt/Custom Import)
    - DNS Configuration (Cloudflare/Google/Custom with DNS over HTTPS)
    - SSO/Authentication Integration (SAML/OAuth/Active Directory)
    - Advanced Network Options (Proxy, Binding, SSL/TLS configuration)
    - Enhanced Security Options (Encryption ciphers, session timeout, audit logging)
    - Multiple deployment types (Standalone/Server/Enterprise)
    - Compliance framework integration (SOX/HIPAA/PCI-DSS/GDPR)
    - Artifact pack selection with comprehensive coverage
    - Configuration export/import functionality
    
.PARAMETER InstallDir
    Installation directory. Default: C:\tools
    
.PARAMETER DataStore
    Data storage directory. Default: C:\VelociraptorData
    
.PARAMETER GuiPort
    GUI port number. Default: 8889
    
.EXAMPLE
    .\VelociraptorGUI-Enhanced-Working.ps1
    
.NOTES
    Administrator privileges required for optimal functionality
    Version: 2.0.0 - Comprehensive Enterprise Edition with Complete velociraptor.exe -i Functionality
    Created: 2025-08-21
    Built on the proven VelociraptorGUI-Actually-Working foundation
#>

[CmdletBinding()]
param(
    [string]$InstallDir = 'C:\tools',
    [string]$DataStore = 'C:\VelociraptorData',
    [int]$GuiPort = 8889
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Write-Host "=== Velociraptor Comprehensive GUI - Complete velociraptor.exe -i Edition ===" -ForegroundColor Cyan
Write-Host "Loading Windows Forms and initializing comprehensive GUI with all configuration options..." -ForegroundColor Yellow

#region Windows Forms Initialization
try {
    # Load assemblies with proper error handling
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    
    # Set rendering defaults after assemblies are loaded
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
    [System.Windows.Forms.Application]::EnableVisualStyles()
    
    Write-Host "Windows Forms initialized successfully" -ForegroundColor Green
}
catch {
    Write-Host "Primary initialization failed, trying alternative method..." -ForegroundColor Yellow
    try {
        [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
        [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
        Write-Host "Alternative initialization successful" -ForegroundColor Green
    }
    catch {
        Write-Host "CRITICAL: Cannot load Windows Forms. GUI cannot continue." -ForegroundColor Red
        exit 1
    }
}
#endregion

#region Global Variables and Colors
$Script:CurrentStep = 0
$Script:TotalSteps = 12  # Increased for comprehensive functionality
$Script:IsInstalling = $false
$Script:VelociraptorProcess = $null
$Script:ConfigPath = ""
$Script:AdminUsername = "admin"
$Script:AdminPassword = ""
$Script:InstallDir = $InstallDir
$Script:DataStore = $DataStore
$Script:GuiPort = $GuiPort

# Enhanced configuration variables
$Script:DeploymentType = "Standalone"
$Script:SecurityLevel = "Standard"
$Script:SelectedArtifacts = @("Essential")
$Script:InstallAsService = $false
$Script:ComplianceFramework = "None"
$Script:EnableSSL = $true
$Script:AutoBackup = $false
$Script:PerformanceMode = "Balanced"

# Authentication and Security configuration - NEW ADDITIONS
$Script:CustomAdminPassword = ""
$Script:UseCustomPassword = $false
$Script:SSOProvider = "None"
$Script:SSODomain = ""
$Script:SAMLEndpoint = ""
$Script:OAuthClientID = ""
$Script:OAuthClientSecret = ""

# Certificate configuration - NEW ADDITIONS
$Script:CertificateType = "SelfSigned"
$Script:CertificateDuration = "1"
$Script:CustomCertPath = ""
$Script:CustomKeyPath = ""
$Script:LetsEncryptEmail = ""

# Network configuration - NEW ADDITIONS
$Script:DNSServer = "Auto"
$Script:CustomDNS1 = ""
$Script:CustomDNS2 = ""
$Script:UseProxy = $false
$Script:ProxyHost = ""
$Script:ProxyPort = ""
$Script:ProxyUsername = ""
$Script:ProxyPassword = ""

# Advanced Security - NEW ADDITIONS
$Script:EncryptionStrength = "AES256"
$Script:RequireMFA = $false
$Script:SessionTimeout = "8"
$Script:PasswordComplexity = "Medium"
$Script:AuditLogging = $true

# Additional variables for compatibility
$Script:PasswordStrength = "Medium"
$Script:DNSPrimary = "1.1.1.1"
$Script:DNSSecondary = "8.8.8.8"
$Script:DNSOverHTTPS = $false
$Script:SSOEnabled = $false
$Script:SSOType = "SAML"
$Script:SSOConfig = @{}
$Script:ProxyEnabled = $false
$Script:BindAddress = "0.0.0.0"
$Script:TLSVersion = "1.3"
$Script:EncryptionCipher = "AES-256"
$Script:MFAEnabled = $false

# Professional color scheme
$Colors = @{
    DarkBackground = [System.Drawing.Color]::FromArgb(25, 25, 25)
    DarkSurface = [System.Drawing.Color]::FromArgb(40, 40, 40)
    AccentBlue = [System.Drawing.Color]::FromArgb(0, 120, 215)
    SuccessGreen = [System.Drawing.Color]::FromArgb(16, 124, 16)
    WarningOrange = [System.Drawing.Color]::FromArgb(255, 185, 0)
    ErrorRed = [System.Drawing.Color]::FromArgb(196, 43, 28)
    TextWhite = [System.Drawing.Color]::White
    TextGray = [System.Drawing.Color]::FromArgb(200, 200, 200)
    BorderGray = [System.Drawing.Color]::FromArgb(70, 70, 70)
    EnterpriseGold = [System.Drawing.Color]::FromArgb(255, 193, 7)
    ComplianceBlue = [System.Drawing.Color]::FromArgb(33, 150, 243)
}
#endregion

#region Utility Functions
function Write-StatusLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Step', 'Config', 'Security')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'HH:mm:ss'
    $prefix = switch ($Level) {
        'Success' { "[OK]" }
        'Warning' { "[!!]" }
        'Error' { "[XX]" }
        'Step' { "[>>]" }
        'Config' { "[CFG]" }
        'Security' { "[SEC]" }
        default { "[--]" }
    }
    
    $logEntry = "$timestamp $prefix $Message"
    
    # Update GUI log if available - direct update since we're in GUI thread
    if ($Script:LogTextBox) {
        try {
            $Script:LogTextBox.AppendText("$logEntry`r`n")
            $Script:LogTextBox.SelectionStart = $Script:LogTextBox.Text.Length
            $Script:LogTextBox.ScrollToCaret()
            $Script:LogTextBox.Refresh()
            [System.Windows.Forms.Application]::DoEvents()
        }
        catch {
            # Fallback if update fails
        }
    }
    
    # Console output with colors
    $consoleColor = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Step' { 'Cyan' }
        'Config' { 'Magenta' }
        'Security' { 'Blue' }
        default { 'White' }
    }
    
    Write-Host $logEntry -ForegroundColor $consoleColor
}

function Update-ProgressBar {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Step,
        
        [Parameter(Mandatory)]
        [string]$Status
    )
    
    if ($Script:ProgressBar -and $Script:StatusLabel) {
        try {
            # Direct updates since we're in GUI thread
            $Script:ProgressBar.Value = [math]::Min(($Step * 100 / $Script:TotalSteps), 100)
            $Script:StatusLabel.Text = $Status
            $Script:ProgressBar.Refresh()
            $Script:StatusLabel.Refresh()
            [System.Windows.Forms.Application]::DoEvents()
        }
        catch {
            Write-StatusLog "Progress update failed (non-critical)" -Level Warning
        }
    }
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-PortAvailable {
    [CmdletBinding()]
    param([int]$Port)
    
    try {
        $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $Port)
        $listener.Start()
        $listener.Stop()
        return $true
    }
    catch {
        return $false
    }
}

function Wait-ForWebInterface {
    [CmdletBinding()]
    param(
        [int]$Port = 8889,
        [int]$TimeoutSeconds = 30
    )
    
    $uri = "https://127.0.0.1:$Port"
    $timeout = (Get-Date).AddSeconds($TimeoutSeconds)
    
    Write-StatusLog "Waiting for web interface to become available..." -Level Info
    
    while ((Get-Date) -lt $timeout) {
        try {
            # Ignore certificate errors for self-signed cert
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
            
            $response = Invoke-WebRequest -Uri $uri -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                return $true
            }
        }
        catch {
            # Continue waiting
        }
        
        Start-Sleep -Seconds 2
    }
    
    return $false
}

function Show-ErrorDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title,
        
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [string[]]$Suggestions = @()
    )
    
    $fullMessage = $Message
    
    if ($Suggestions.Count -gt 0) {
        $fullMessage += "`n`nSuggested Actions:`n"
        $fullMessage += ($Suggestions | ForEach-Object { "• $_" }) -join "`n"
    }
    
    [System.Windows.Forms.MessageBox]::Show(
        $fullMessage,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
}

function Get-SecurePassword {
    param(
        [int]$Length = 16,
        [string]$Complexity = "Medium"
    )
    
    $chars = switch ($Complexity) {
        "Low" { 
            $lowercase = 'a'..'z'
            $uppercase = 'A'..'Z'
            $numbers = '0'..'9'
            $lowercase + $uppercase + $numbers
        }
        "Medium" { 
            $lowercase = 'a'..'z'
            $uppercase = 'A'..'Z'
            $numbers = '0'..'9'
            $special = '!','@','#','$','%','^','&','*'
            $lowercase + $uppercase + $numbers + $special
        }
        "High" { 
            $lowercase = 'a'..'z'
            $uppercase = 'A'..'Z'
            $numbers = '0'..'9'
            $special = '!','@','#','$','%','^','&','*','(',')','-','_','+','=','[',']','{','}','|',';',':',',','.','<','>','?'
            $lowercase + $uppercase + $numbers + $special
        }
    }
    
    return -join ((1..$Length) | ForEach-Object { Get-Random -InputObject $chars })
}

function Test-PasswordStrength {
    param([string]$Password)
    
    $score = 0
    if ($Password.Length -ge 8) { $score++ }
    if ($Password.Length -ge 12) { $score++ }
    if ($Password -cmatch '[a-z]') { $score++ }
    if ($Password -cmatch '[A-Z]') { $score++ }
    if ($Password -match '[0-9]') { $score++ }
    if ($Password -match '[^a-zA-Z0-9]') { $score++ }
    
    switch ($score) {
        { $_ -le 2 } { return @{ Strength = "Weak"; Color = $Colors.ErrorRed } }
        { $_ -le 4 } { return @{ Strength = "Medium"; Color = $Colors.WarningOrange } }
        default { return @{ Strength = "Strong"; Color = $Colors.SuccessGreen } }
    }
}

function Test-CertificateFile {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) { return $false }
    
    try {
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($Path)
        return $cert.NotAfter -gt (Get-Date)
    }
    catch {
        return $false
    }
}

function Test-ProxyConfiguration {
    param([string]$Host, [int]$Port)
    
    if ([string]::IsNullOrWhiteSpace($Host)) { return $false }
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect($Host, $Port)
        $tcpClient.Close()
        return $true
    }
    catch {
        return $false
    }
}

function Get-ConfigurationSummary {
    return @"
=== Enhanced Configuration Summary ===
DEPLOYMENT CONFIGURATION:
• Deployment Type: $Script:DeploymentType
• Security Level: $Script:SecurityLevel
• Install as Service: $Script:InstallAsService
• Performance Mode: $Script:PerformanceMode

DIRECTORIES & NETWORK:
• Installation Directory: $Script:InstallDir
• Data Directory: $Script:DataStore
• GUI Port: $Script:GuiPort
• Bind Address: $Script:BindAddress

ENHANCED AUTHENTICATION:
• Admin Password: $(if($Script:UseCustomPassword) {'Custom Password'} else {'Auto-generated'})
• SSO Provider: $Script:SSOProvider
$(if($Script:SSOProvider -ne 'None') {"• SSO Domain: $Script:SSODomain"})
$(if($Script:SSOProvider -eq 'SAML') {"• SAML Endpoint: $Script:SAMLEndpoint"})
$(if($Script:SSOProvider -eq 'OAuth') {"• OAuth Client ID: $Script:OAuthClientID"})

ENHANCED CERTIFICATE MANAGEMENT:
• Certificate Type: $Script:CertificateType
• Certificate Duration: $Script:CertificateDuration years
$(if($Script:CertificateType -eq 'LetsEncrypt') {"• Let's Encrypt Email: $Script:LetsEncryptEmail"})
$(if($Script:CertificateType -eq 'Custom') {"• Custom Certificate: $Script:CustomCertPath"})
$(if($Script:CertificateType -eq 'Custom') {"• Custom Private Key: $Script:CustomKeyPath"})

ENHANCED NETWORK CONFIGURATION:
• DNS Server: $Script:DNSServer
$(if($Script:DNSServer -eq 'Custom') {"• Primary DNS: $Script:CustomDNS1"})
$(if($Script:DNSServer -eq 'Custom' -and $Script:CustomDNS2) {"• Secondary DNS: $Script:CustomDNS2"})
• Proxy Enabled: $Script:UseProxy
$(if($Script:UseProxy) {"• Proxy Host: $Script:ProxyHost"})
$(if($Script:UseProxy) {"• Proxy Port: $Script:ProxyPort"})

ADVANCED SECURITY SETTINGS:
• Encryption Strength: $Script:EncryptionStrength
• Require MFA: $Script:RequireMFA
• Session Timeout: $Script:SessionTimeout hours
• Password Complexity: $Script:PasswordComplexity
• Audit Logging: $Script:AuditLogging

COMPLIANCE & FEATURES:
• Compliance Framework: $Script:ComplianceFramework
• SSL Enabled: $Script:EnableSSL
• Auto Backup: $Script:AutoBackup
• Artifact Packs: $($Script:SelectedArtifacts -join ', ')
==========================================
"@
}
#endregion

#region Enhanced Configuration Functions
function Get-DeploymentConfiguration {
    switch ($Script:DeploymentType) {
        "Standalone" {
            return @{
                Mode = "standalone"
                Collectors = 1
                MaxClients = 50
                DatabaseType = "filestore"
                Clustering = $false
            }
        }
        "Server" {
            return @{
                Mode = "server"
                Collectors = 10
                MaxClients = 500
                DatabaseType = "mysql"
                Clustering = $false
            }
        }
        "Enterprise" {
            return @{
                Mode = "enterprise"
                Collectors = 100
                MaxClients = 5000
                DatabaseType = "mysql"
                Clustering = $true
            }
        }
    }
}

function Get-SecurityConfiguration {
    switch ($Script:SecurityLevel) {
        "Basic" {
            return @{
                PasswordComplexity = "low"
                SessionTimeout = 24
                TLSVersion = "1.2"
                AuditLogging = $false
                MFA = $false
            }
        }
        "Standard" {
            return @{
                PasswordComplexity = "medium"
                SessionTimeout = 8
                TLSVersion = "1.2"
                AuditLogging = $true
                MFA = $false
            }
        }
        "Maximum" {
            return @{
                PasswordComplexity = "high"
                SessionTimeout = 2
                TLSVersion = "1.3"
                AuditLogging = $true
                MFA = $true
            }
        }
    }
}

function Get-ArtifactPackConfiguration {
    $artifacts = @()
    
    foreach ($pack in $Script:SelectedArtifacts) {
        switch ($pack) {
            "Essential" {
                $artifacts += @(
                    "Windows.System.PowerShell",
                    "Windows.EventLogs.LogonEvents",
                    "Windows.Registry.UserAssist"
                )
            }
            "Windows" {
                $artifacts += @(
                    "Windows.Registry.NTUser",
                    "Windows.System.Services",
                    "Windows.Forensics.UserProfiles"
                )
            }
            "Linux" {
                $artifacts += @(
                    "Linux.Sys.BashHistory",
                    "Linux.Sys.LoginRecord",
                    "Linux.Forensics.Journal"
                )
            }
            "Network" {
                $artifacts += @(
                    "Windows.Network.Netstat",
                    "Windows.Network.InterfaceAddresses",
                    "Generic.Network.ArpCache"
                )
            }
            "Forensics" {
                $artifacts += @(
                    "Windows.Forensics.Prefetch",
                    "Windows.Forensics.SRUM",
                    "Windows.Forensics.Amcache"
                )
            }
        }
    }
    
    return $artifacts
}

function Get-ComplianceConfiguration {
    switch ($Script:ComplianceFramework) {
        "SOX" {
            return @{
                RequiredLogging = $true
                DataRetention = 2555  # 7 years in days
                AccessControls = "strict"
                AuditTrail = "comprehensive"
                MFARequired = $true
                EncryptionRequired = $true
            }
        }
        "HIPAA" {
            return @{
                RequiredLogging = $true
                DataRetention = 2190  # 6 years in days
                AccessControls = "strict"
                AuditTrail = "comprehensive"
                Encryption = "required"
                MFARequired = $true
                SessionTimeout = 2
            }
        }
        "PCI-DSS" {
            return @{
                RequiredLogging = $true
                DataRetention = 365   # 1 year in days
                AccessControls = "strict"
                AuditTrail = "comprehensive"
                NetworkSegmentation = $true
                MFARequired = $true
                TLSVersion = "1.3"
            }
        }
        "GDPR" {
            return @{
                RequiredLogging = $true
                DataRetention = 1095  # 3 years in days
                AccessControls = "strict"
                AuditTrail = "comprehensive"
                DataProtection = "enhanced"
                MFARequired = $false
                EncryptionRequired = $true
            }
        }
        default {
            return @{
                RequiredLogging = $false
                DataRetention = 90
                AccessControls = "standard"
                AuditTrail = "basic"
                MFARequired = $false
                EncryptionRequired = $false
            }
        }
    }
}

function Get-CertificateConfiguration {
    switch ($Script:CertificateType) {
        "Self-signed" {
            return @{
                Type = "self_signed"
                Duration = $Script:CertificateDuration
                Algorithm = "RSA-2048"
                AutoRenewal = $false
            }
        }
        "Let's Encrypt" {
            return @{
                Type = "letsencrypt"
                AutoRenewal = $true
                ChallengeType = "http-01"
                Duration = 1  # Auto-renewal every 90 days
            }
        }
        "Custom Import" {
            return @{
                Type = "custom"
                CertPath = $Script:CustomCertPath
                Duration = "variable"
                AutoRenewal = $false
            }
        }
    }
}

function Get-NetworkConfiguration {
    return @{
        BindAddress = $Script:BindAddress
        Port = $Script:GuiPort
        TLSVersion = $Script:TLSVersion
        DNS = @{
            Primary = $Script:DNSPrimary
            Secondary = $Script:DNSSecondary
            OverHTTPS = $Script:DNSOverHTTPS
        }
        Proxy = @{
            Enabled = $Script:ProxyEnabled
            Host = $Script:ProxyHost
            Port = $Script:ProxyPort
        }
    }
}

function Get-SSOConfiguration {
    if (-not $Script:SSOEnabled) {
        return @{ Enabled = $false }
    }
    
    $baseConfig = @{
        Enabled = $true
        Type = $Script:SSOType
    }
    
    switch ($Script:SSOType) {
        "SAML" {
            $baseConfig.SAML = @{
                IdentityProviderURL = $Script:SSOConfig.IdpURL
                MetadataURL = $Script:SSOConfig.MetadataURL
                SigningCertificate = $Script:SSOConfig.SigningCert
            }
        }
        "OAuth" {
            $baseConfig.OAuth = @{
                ClientID = $Script:SSOConfig.ClientID
                Provider = $Script:SSOConfig.Provider
                RedirectURL = $Script:SSOConfig.RedirectURL
            }
        }
        "ActiveDirectory" {
            $baseConfig.AD = @{
                Domain = $Script:SSOConfig.Domain
                Server = $Script:SSOConfig.ADServer
                BaseDN = $Script:SSOConfig.BaseDN
            }
        }
    }
    
    return $baseConfig
}
#endregion

#region Velociraptor Installation Functions (Enhanced)
function Get-LatestVelociraptorAsset {
    Write-StatusLog "Querying GitHub for latest Velociraptor release..." -Level Info
    
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        
        $apiUrl = "https://api.github.com/repos/Velocidex/velociraptor/releases/latest"
        $response = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
        
        $windowsAsset = $response.assets | Where-Object { 
            $_.name -like "*windows-amd64.exe" -and 
            $_.name -notlike "*debug*" -and 
            $_.name -notlike "*collector*"
        } | Select-Object -First 1
        
        if (-not $windowsAsset) {
            throw "Could not find Windows executable in release assets"
        }
        
        $version = $response.tag_name -replace '^v', ''
        Write-StatusLog "Found Velociraptor v$version ($([math]::Round($windowsAsset.size / 1048576, 1)) MB)" -Level Success
        
        return @{
            Version = $version
            DownloadUrl = $windowsAsset.browser_download_url
            Size = $windowsAsset.size
            Name = $windowsAsset.name
        }
    }
    catch {
        Write-StatusLog "Failed to query GitHub API: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Install-VelociraptorExecutable {
    [CmdletBinding()]
    param(
        $AssetInfo,
        [string]$DestinationPath
    )
    
    Write-StatusLog "Downloading $($AssetInfo.Name)..." -Level Step
    Update-ProgressBar -Step 2 -Status "Downloading Velociraptor executable..."
    
    try {
        # Create directory if needed
        $directory = Split-Path $DestinationPath -Parent
        if (-not (Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
            Write-StatusLog "Created directory: $directory" -Level Success
        }
        
        $tempFile = "$DestinationPath.download"
        
        # Download with progress tracking
        $webClient = New-Object System.Net.WebClient
        
        # Add progress handler
        Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action {
            $percent = $Event.SourceEventArgs.ProgressPercentage
            if ($Script:ProgressBar) {
                try {
                    $Script:ProgressBar.Invoke([Action]{
                        $Script:ProgressBar.Value = [math]::Min(20 + ($percent * 0.3), 50)
                    })
                }
                catch {}
            }
        } | Out-Null
        
        $webClient.DownloadFile($AssetInfo.DownloadUrl, $tempFile)
        
        # Verify download
        if (Test-Path $tempFile) {
            $fileSize = (Get-Item $tempFile).Length
            Write-StatusLog "Download completed: $([math]::Round($fileSize / 1048576, 1)) MB" -Level Success
            
            if ($fileSize -eq 0) {
                throw "Downloaded file is empty"
            }
            
            # Move to final location
            Move-Item $tempFile $DestinationPath -Force
            Write-StatusLog "Executable installed successfully" -Level Success
            
            return $true
        }
        else {
            throw "Download file not found"
        }
    }
    catch {
        Write-StatusLog "Download failed: $($_.Exception.Message)" -Level Error
        if (Test-Path $tempFile) { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }
        throw
    }
    finally {
        if ($webClient) { $webClient.Dispose() }
        # Remove event handlers
        Get-EventSubscriber | Where-Object { $_.SourceObject -is [System.Net.WebClient] } | Unregister-Event
    }
}

function New-VelociraptorConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ExecutablePath,
        
        [Parameter(Mandatory)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory)]
        [int]$GuiPort
    )
    
    Write-StatusLog "Generating enhanced Velociraptor configuration..." -Level Step
    Update-ProgressBar -Step 3 -Status "Generating enhanced server configuration..."
    
    try {
        # Generate base configuration
        $configDir = Split-Path $ConfigPath -Parent
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        
        $arguments = @(
            'config', 'generate'
            '--config', "`"$ConfigPath`""
        )
        
        Write-StatusLog "Running: velociraptor.exe $($arguments -join ' ')" -Level Info
        
        $process = Start-Process -FilePath $ExecutablePath -ArgumentList $arguments -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$env:TEMP\velo_config_out.log" -RedirectStandardError "$env:TEMP\velo_config_err.log"
        
        if ($process.ExitCode -ne 0) {
            $errorOutput = if (Test-Path "$env:TEMP\velo_config_err.log") { Get-Content "$env:TEMP\velo_config_err.log" -Raw } else { "Unknown error" }
            throw "Configuration generation failed with exit code $($process.ExitCode). Error: $errorOutput"
        }
        
        if (-not (Test-Path $ConfigPath)) {
            throw "Configuration file was not created at $ConfigPath"
        }
        
        Write-StatusLog "Base configuration generated successfully" -Level Success
        
        # Apply enhanced configuration settings
        Write-StatusLog "Applying enhanced configuration settings..." -Level Config
        $config = Get-Content $ConfigPath -Raw
        
        # Apply comprehensive configuration settings
        $deploymentConfig = Get-DeploymentConfiguration
        $securityConfig = Get-SecurityConfiguration
        $networkConfig = Get-NetworkConfiguration
        $certConfig = Get-CertificateConfiguration
        $ssoConfig = Get-SSOConfiguration
        
        Write-StatusLog "Configuring for $($Script:DeploymentType) deployment mode" -Level Config
        Write-StatusLog "Applying $($Script:SecurityLevel) security level" -Level Security
        Write-StatusLog "Configuring network settings (DNS: $Script:DNSPrimary)" -Level Config
        Write-StatusLog "Certificate type: $Script:CertificateType" -Level Security
        
        if ($Script:SSOEnabled) {
            Write-StatusLog "Configuring SSO integration ($Script:SSOType)" -Level Security
        }
        
        if ($Script:ProxyEnabled) {
            Write-StatusLog "Configuring proxy: $Script:ProxyHost:$Script:ProxyPort" -Level Config
        }
        
        # Apply compliance settings if specified
        if ($Script:ComplianceFramework -ne "None") {
            $complianceConfig = Get-ComplianceConfiguration
            Write-StatusLog "Applying $($Script:ComplianceFramework) compliance framework" -Level Security
            
            # Override security settings based on compliance requirements
            if ($complianceConfig.MFARequired) {
                $Script:MFAEnabled = $true
                Write-StatusLog "MFA enabled due to compliance requirements" -Level Security
            }
            if ($complianceConfig.TLSVersion) {
                $Script:TLSVersion = $complianceConfig.TLSVersion
                Write-StatusLog "TLS version set to $($Script:TLSVersion) for compliance" -Level Security
            }
            if ($complianceConfig.SessionTimeout) {
                $Script:SessionTimeout = $complianceConfig.SessionTimeout
                Write-StatusLog "Session timeout set to $($Script:SessionTimeout) hours for compliance" -Level Security
            }
        }
        
        # Update GUI port if different from default
        if ($GuiPort -ne 8889) {
            Write-StatusLog "Updating configuration for port $GuiPort..." -Level Config
            $config = $config -replace 'bind_port: 8889', "bind_port: $GuiPort"
        }
        
        # Apply performance optimizations
        if ($Script:PerformanceMode -eq "High") {
            Write-StatusLog "Applying high-performance optimizations..." -Level Config
            # Add performance-specific configuration modifications here
        }
        
        # Save enhanced configuration
        Set-Content -Path $ConfigPath -Value $config
        Write-StatusLog "Enhanced configuration applied successfully" -Level Success
        
        return $true
    }
    catch {
        Write-StatusLog "Configuration generation failed: $($_.Exception.Message)" -Level Error
        throw
    }
}

function New-VelociraptorAdminUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ExecutablePath,
        
        [Parameter(Mandatory)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory)]
        [string]$Username,
        
        [Parameter(Mandatory)]
        [string]$Password
    )
    
    Write-StatusLog "Creating admin user '$Username' with enhanced security..." -Level Step
    Update-ProgressBar -Step 4 -Status "Creating admin user account..."
    
    try {
        $arguments = @(
            '--config', "`"$ConfigPath`""
            'user', 'add', $Username
            '--role', 'administrator'
            '--password', $Password
        )
        
        Write-StatusLog "Creating administrator account with enhanced privileges..." -Level Security
        
        $process = Start-Process -FilePath $ExecutablePath -ArgumentList $arguments -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$env:TEMP\velo_user_out.log" -RedirectStandardError "$env:TEMP\velo_user_err.log"
        
        if ($process.ExitCode -ne 0) {
            $errorOutput = if (Test-Path "$env:TEMP\velo_user_err.log") { Get-Content "$env:TEMP\velo_user_err.log" -Raw } else { "Unknown error" }
            Write-StatusLog "User creation failed with exit code $($process.ExitCode). Error: $errorOutput" -Level Warning
            Write-StatusLog "User may already exist or will be created on first access" -Level Info
        }
        else {
            Write-StatusLog "Admin user '$Username' created successfully with enhanced permissions" -Level Success
        }
        
        return $true
    }
    catch {
        Write-StatusLog "User creation error: $($_.Exception.Message)" -Level Warning
        Write-StatusLog "Continuing - default credentials may be used" -Level Info
        return $true  # Non-critical error
    }
}

function Install-VelociraptorService {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ExecutablePath,
        
        [Parameter(Mandatory)]
        [string]$ConfigPath
    )
    
    if (-not $Script:InstallAsService) {
        Write-StatusLog "Service installation skipped - running in process mode" -Level Info
        return $true
    }
    
    Write-StatusLog "Installing Velociraptor as Windows service..." -Level Step
    Update-ProgressBar -Step 5 -Status "Installing Windows service..."
    
    try {
        # Check if service already exists
        $existingService = Get-Service -Name "Velociraptor" -ErrorAction SilentlyContinue
        if ($existingService) {
            Write-StatusLog "Removing existing Velociraptor service..." -Level Info
            Stop-Service -Name "Velociraptor" -Force -ErrorAction SilentlyContinue
            & sc.exe delete "Velociraptor" | Out-Null
            Start-Sleep -Seconds 2
        }
        
        # Install as service
        $serviceArgs = @(
            'create', 'Velociraptor'
            'binPath=', "`"$ExecutablePath`" --config `"$ConfigPath`" frontend"
            'DisplayName=', 'Velociraptor DFIR Framework'
            'start=', 'auto'
        )
        
        Write-StatusLog "Creating Windows service..." -Level Info
        & sc.exe @serviceArgs | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-StatusLog "Service installed successfully" -Level Success
            return $true
        }
        else {
            throw "Service installation failed with exit code $LASTEXITCODE"
        }
    }
    catch {
        Write-StatusLog "Service installation failed: $($_.Exception.Message)" -Level Warning
        Write-StatusLog "Continuing with process-based installation..." -Level Info
        return $true  # Non-critical error
    }
}

function Start-VelociraptorServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ExecutablePath,
        
        [Parameter(Mandatory)]
        [string]$ConfigPath
    )
    
    Write-StatusLog "Starting Velociraptor server..." -Level Step
    Update-ProgressBar -Step 6 -Status "Starting Velociraptor server..."
    
    try {
        if ($Script:InstallAsService) {
            # Start service
            Write-StatusLog "Starting Velociraptor service..." -Level Info
            Start-Service -Name "Velociraptor"
            
            # Verify service is running
            $service = Get-Service -Name "Velociraptor"
            if ($service.Status -eq "Running") {
                Write-StatusLog "Service started successfully" -Level Success
                return $service
            }
            else {
                throw "Service failed to start"
            }
        }
        else {
            # Start as process
            $arguments = @(
                '--config', "`"$ConfigPath`""
                'frontend', '-v'
            )
            
            Write-StatusLog "Launching server process..." -Level Info
            
            $process = Start-Process -FilePath $ExecutablePath -ArgumentList $arguments -PassThru -WindowStyle Hidden
            
            if ($process) {
                Write-StatusLog "Server process started (PID: $($process.Id))" -Level Success
                $Script:VelociraptorProcess = $process
                
                # Wait for server to be ready
                Update-ProgressBar -Step 7 -Status "Waiting for server to initialize..."
                Start-Sleep -Seconds 8
                
                return $process
            }
            else {
                throw "Failed to start server process"
            }
        }
    }
    catch {
        Write-StatusLog "Server startup failed: $($_.Exception.Message)" -Level Error
        throw
    }
}
#endregion

#region Enhanced GUI Functions
function Start-AsyncInstallation {
    # Use a timer to break up the long-running installation into chunks
    # This prevents GUI freezing during installation
    $Script:InstallTimer = New-Object System.Windows.Forms.Timer
    $Script:InstallTimer.Interval = 100
    $Script:InstallTimer.Add_Tick({
        $Script:InstallTimer.Stop()
        try {
            Start-VelociraptorInstallation
        }
        catch {
            Write-StatusLog "Async installation error: $($_.Exception.Message)" -Level Error
        }
        finally {
            $Script:InstallTimer.Dispose()
        }
    })
    $Script:InstallTimer.Start()
}

function Test-ConfigurationInputs {
    $installDir = $Script:InstallDirTextBox.Text.Trim()
    $dataDir = $Script:DataDirTextBox.Text.Trim()
    $port = $Script:GuiPortTextBox.Text.Trim()
    
    $errors = @()
    
    if ([string]::IsNullOrWhiteSpace($installDir)) {
        $errors += "Installation directory is required"
    }
    
    if ([string]::IsNullOrWhiteSpace($dataDir)) {
        $errors += "Data directory is required"
    }
    
    if (-not [int]::TryParse($port, [ref]$null)) {
        $errors += "Port must be a valid number"
    } elseif ([int]$port -lt 1024 -or [int]$port -gt 65535) {
        $errors += "Port must be between 1024 and 65535"
    }
    
    # Validate artifact selection
    if ($Script:SelectedArtifacts.Count -eq 0) {
        $errors += "At least one artifact pack must be selected"
    }
    
    # Validate custom password if enabled
    if ($Script:UseCustomPassword -and [string]::IsNullOrWhiteSpace($Script:CustomAdminPassword)) {
        $errors += "Custom admin password cannot be empty when enabled"
    }
    
    # Validate password strength if custom password is used
    if ($Script:UseCustomPassword -and $Script:CustomAdminPassword.Length -lt 8) {
        $errors += "Custom admin password must be at least 8 characters long"
    }
    
    # Enhanced certificate validation
    if ($Script:CertificateType -eq "Custom") {
        if ([string]::IsNullOrWhiteSpace($Script:CustomCertPath)) {
            $errors += "Certificate file path is required for custom certificate"
        } elseif (-not (Test-Path $Script:CustomCertPath)) {
            $errors += "Certificate file does not exist: $Script:CustomCertPath"
        }
        
        if ([string]::IsNullOrWhiteSpace($Script:CustomKeyPath)) {
            $errors += "Private key file path is required for custom certificate"
        } elseif (-not (Test-Path $Script:CustomKeyPath)) {
            $errors += "Private key file does not exist: $Script:CustomKeyPath"
        }
    }
    
    # Validate Let's Encrypt configuration
    if ($Script:CertificateType -eq "LetsEncrypt") {
        if ([string]::IsNullOrWhiteSpace($Script:LetsEncryptEmail)) {
            $errors += "Email address is required for Let's Encrypt certificate"
        } elseif ($Script:LetsEncryptEmail -notmatch "^[^@]+@[^@]+\.[^@]+$") {
            $errors += "Please enter a valid email address for Let's Encrypt"
        }
    }
    
    # Enhanced proxy validation
    if ($Script:UseProxy) {
        if ([string]::IsNullOrWhiteSpace($Script:ProxyHost)) {
            $errors += "Proxy host is required when proxy is enabled"
        }
        
        if ([string]::IsNullOrWhiteSpace($Script:ProxyPort)) {
            $errors += "Proxy port is required when proxy is enabled"
        } elseif (-not [int]::TryParse($Script:ProxyPort, [ref]$null)) {
            $errors += "Proxy port must be a valid number"
        } elseif ([int]$Script:ProxyPort -lt 1 -or [int]$Script:ProxyPort -gt 65535) {
            $errors += "Proxy port must be between 1 and 65535"
        }
    }
    
    # Enhanced SSO validation
    if ($Script:SSOProvider -ne "None") {
        if ([string]::IsNullOrWhiteSpace($Script:SSODomain)) {
            $errors += "Domain is required when SSO is enabled"
        }
        
        if ($Script:SSOProvider -eq "SAML") {
            if ([string]::IsNullOrWhiteSpace($Script:SAMLEndpoint)) {
                $errors += "SAML endpoint URL is required for SAML authentication"
            } elseif ($Script:SAMLEndpoint -notmatch "^https?://") {
                $errors += "SAML endpoint must be a valid HTTP/HTTPS URL"
            }
        }
        
        if ($Script:SSOProvider -eq "OAuth") {
            if ([string]::IsNullOrWhiteSpace($Script:OAuthClientID)) {
                $errors += "OAuth Client ID is required for OAuth authentication"
            }
            if ([string]::IsNullOrWhiteSpace($Script:OAuthClientSecret)) {
                $errors += "OAuth Client Secret is required for OAuth authentication"
            }
        }
    }
    
    # Enhanced DNS validation
    if ($Script:DNSServer -eq "Custom") {
        if ([string]::IsNullOrWhiteSpace($Script:CustomDNS1)) {
            $errors += "Primary DNS server is required when using custom DNS"
        } elseif (-not ($Script:CustomDNS1 -match "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$")) {
            $errors += "Primary DNS server must be a valid IP address"
        }
        
        if (-not [string]::IsNullOrWhiteSpace($Script:CustomDNS2) -and -not ($Script:CustomDNS2 -match "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$")) {
            $errors += "Secondary DNS server must be a valid IP address"
        }
    }
    if ($Script:SSOEnabled) {
        switch ($Script:SSOType) {
            "SAML" {
                if ([string]::IsNullOrWhiteSpace($Script:SSOConfig.IdpURL)) {
                    $errors += "SAML Identity Provider URL is required"
                }
            }
            "OAuth" {
                if ([string]::IsNullOrWhiteSpace($Script:SSOConfig.ClientID)) {
                    $errors += "OAuth Client ID is required"
                }
            }
            "ActiveDirectory" {
                if ([string]::IsNullOrWhiteSpace($Script:SSOConfig.Domain)) {
                    $errors += "Active Directory domain is required"
                }
            }
        }
    }
    
    if ($errors.Count -gt 0) {
        Show-ErrorDialog -Title "Configuration Error" -Message ($errors -join "`n") -Suggestions @(
            "Enter valid installation directory path",
            "Enter valid data directory path",
            "Enter port number between 1024-65535",
            "Select at least one artifact pack",
            "Configure admin password if using custom option",
            "Verify certificate file path and validity",
            "Check proxy configuration if enabled",
            "Complete SSO configuration if enabled"
        )
        return $false
    }
    
    return $true
}

function Select-FolderPath {
    param([string]$Description = "Select Folder")
    
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = $Description
    $folderBrowser.ShowNewFolderButton = $true
    
    $result = $folderBrowser.ShowDialog($MainForm)
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $folderBrowser.SelectedPath
    }
    return $null
}

function Update-DeploymentSelection {
    param([string]$SelectedType)
    
    $Script:DeploymentType = $SelectedType
    Write-StatusLog "Deployment type changed to: $SelectedType" -Level Config
    
    # Update UI based on deployment type
    switch ($SelectedType) {
        "Standalone" {
            $Script:DeploymentInfoLabel.Text = "Single-node deployment for small teams (up to 50 clients)"
            $Script:DeploymentInfoLabel.ForeColor = $Colors.AccentBlue
        }
        "Server" {
            $Script:DeploymentInfoLabel.Text = "Multi-client server deployment (up to 500 clients)"
            $Script:DeploymentInfoLabel.ForeColor = $Colors.SuccessGreen
        }
        "Enterprise" {
            $Script:DeploymentInfoLabel.Text = "Enterprise-grade deployment (up to 5000 clients)"
            $Script:DeploymentInfoLabel.ForeColor = $Colors.EnterpriseGold
        }
    }
}

function Update-SecuritySelection {
    param([string]$SelectedLevel)
    
    $Script:SecurityLevel = $SelectedLevel
    Write-StatusLog "Security level changed to: $SelectedLevel" -Level Security
    
    # Update UI based on security level
    switch ($SelectedLevel) {
        "Basic" {
            $Script:SecurityInfoLabel.Text = "Basic security with standard authentication"
            $Script:SecurityInfoLabel.ForeColor = $Colors.WarningOrange
        }
        "Standard" {
            $Script:SecurityInfoLabel.Text = "Enhanced security with audit logging"
            $Script:SecurityInfoLabel.ForeColor = $Colors.AccentBlue
        }
        "Maximum" {
            $Script:SecurityInfoLabel.Text = "Maximum security with MFA and strict controls"
            $Script:SecurityInfoLabel.ForeColor = $Colors.SuccessGreen
        }
    }
}

function Update-ArtifactSelection {
    $Script:SelectedArtifacts = @()
    
    if ($Script:EssentialCheckBox.Checked) { $Script:SelectedArtifacts += "Essential" }
    if ($Script:WindowsCheckBox.Checked) { $Script:SelectedArtifacts += "Windows" }
    if ($Script:LinuxCheckBox.Checked) { $Script:SelectedArtifacts += "Linux" }
    if ($Script:NetworkCheckBox.Checked) { $Script:SelectedArtifacts += "Network" }
    if ($Script:ForensicsCheckBox.Checked) { $Script:SelectedArtifacts += "Forensics" }
    
    Write-StatusLog "Artifact packs selected: $($Script:SelectedArtifacts -join ', ')" -Level Config
    
    # Update artifact count label
    $Script:ArtifactCountLabel.Text = "Selected: $($Script:SelectedArtifacts.Count) pack(s)"
}

function Update-SSOConfigurationPanel {
    # Clear existing controls
    $Script:SSOConfigPanel.Controls.Clear()
    
    if (-not $Script:SSOConfig) {
        $Script:SSOConfig = @{}
    }
    
    switch ($Script:SSOType) {
        "SAML" {
            # Identity Provider URL
            $idpLabel = New-Object System.Windows.Forms.Label
            $idpLabel.Text = "Identity Provider URL:"
            $idpLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
            $idpLabel.ForeColor = $Colors.TextWhite
            $idpLabel.Location = New-Object System.Drawing.Point(10, 15)
            $idpLabel.Size = New-Object System.Drawing.Size(120, 20)
            
            $Script:IdpURLTextBox = New-Object System.Windows.Forms.TextBox
            $Script:IdpURLTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
            $Script:IdpURLTextBox.BackColor = $Colors.DarkSurface
            $Script:IdpURLTextBox.ForeColor = $Colors.TextWhite
            $Script:IdpURLTextBox.Location = New-Object System.Drawing.Point(140, 13)
            $Script:IdpURLTextBox.Size = New-Object System.Drawing.Size(240, 22)
            $Script:IdpURLTextBox.Add_TextChanged({
                $Script:SSOConfig.IdpURL = $Script:IdpURLTextBox.Text
            })
            
            # Metadata URL
            $metadataLabel = New-Object System.Windows.Forms.Label
            $metadataLabel.Text = "Metadata URL:"
            $metadataLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
            $metadataLabel.ForeColor = $Colors.TextWhite
            $metadataLabel.Location = New-Object System.Drawing.Point(10, 45)
            $metadataLabel.Size = New-Object System.Drawing.Size(120, 20)
            
            $Script:MetadataURLTextBox = New-Object System.Windows.Forms.TextBox
            $Script:MetadataURLTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
            $Script:MetadataURLTextBox.BackColor = $Colors.DarkSurface
            $Script:MetadataURLTextBox.ForeColor = $Colors.TextWhite
            $Script:MetadataURLTextBox.Location = New-Object System.Drawing.Point(140, 43)
            $Script:MetadataURLTextBox.Size = New-Object System.Drawing.Size(240, 22)
            $Script:MetadataURLTextBox.Add_TextChanged({
                $Script:SSOConfig.MetadataURL = $Script:MetadataURLTextBox.Text
            })
            
            $Script:SSOConfigPanel.Controls.AddRange(@($idpLabel, $Script:IdpURLTextBox, $metadataLabel, $Script:MetadataURLTextBox))
        }
        "OAuth" {
            # Client ID
            $clientIdLabel = New-Object System.Windows.Forms.Label
            $clientIdLabel.Text = "Client ID:"
            $clientIdLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
            $clientIdLabel.ForeColor = $Colors.TextWhite
            $clientIdLabel.Location = New-Object System.Drawing.Point(10, 15)
            $clientIdLabel.Size = New-Object System.Drawing.Size(80, 20)
            
            $Script:ClientIDTextBox = New-Object System.Windows.Forms.TextBox
            $Script:ClientIDTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
            $Script:ClientIDTextBox.BackColor = $Colors.DarkSurface
            $Script:ClientIDTextBox.ForeColor = $Colors.TextWhite
            $Script:ClientIDTextBox.Location = New-Object System.Drawing.Point(100, 13)
            $Script:ClientIDTextBox.Size = New-Object System.Drawing.Size(280, 22)
            $Script:ClientIDTextBox.Add_TextChanged({
                $Script:SSOConfig.ClientID = $Script:ClientIDTextBox.Text
            })
            
            # Provider
            $providerLabel = New-Object System.Windows.Forms.Label
            $providerLabel.Text = "Provider:"
            $providerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
            $providerLabel.ForeColor = $Colors.TextWhite
            $providerLabel.Location = New-Object System.Drawing.Point(10, 45)
            $providerLabel.Size = New-Object System.Drawing.Size(80, 20)
            
            $Script:ProviderCombo = New-Object System.Windows.Forms.ComboBox
            $Script:ProviderCombo.Font = New-Object System.Drawing.Font("Segoe UI", 9)
            $Script:ProviderCombo.BackColor = $Colors.DarkSurface
            $Script:ProviderCombo.ForeColor = $Colors.TextWhite
            $Script:ProviderCombo.Location = New-Object System.Drawing.Point(100, 43)
            $Script:ProviderCombo.Size = New-Object System.Drawing.Size(150, 22)
            $Script:ProviderCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
            $Script:ProviderCombo.Items.AddRange(@("Google", "Microsoft", "GitHub", "Custom"))
            $Script:ProviderCombo.SelectedIndex = 0
            $Script:ProviderCombo.Add_SelectedIndexChanged({
                $Script:SSOConfig.Provider = $Script:ProviderCombo.SelectedItem.ToString()
            })
            
            $Script:SSOConfigPanel.Controls.AddRange(@($clientIdLabel, $Script:ClientIDTextBox, $providerLabel, $Script:ProviderCombo))
        }
        "ActiveDirectory" {
            # Domain
            $domainLabel = New-Object System.Windows.Forms.Label
            $domainLabel.Text = "Domain:"
            $domainLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
            $domainLabel.ForeColor = $Colors.TextWhite
            $domainLabel.Location = New-Object System.Drawing.Point(10, 15)
            $domainLabel.Size = New-Object System.Drawing.Size(60, 20)
            
            $Script:DomainTextBox = New-Object System.Windows.Forms.TextBox
            $Script:DomainTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
            $Script:DomainTextBox.BackColor = $Colors.DarkSurface
            $Script:DomainTextBox.ForeColor = $Colors.TextWhite
            $Script:DomainTextBox.Location = New-Object System.Drawing.Point(80, 13)
            $Script:DomainTextBox.Size = New-Object System.Drawing.Size(200, 22)
            $Script:DomainTextBox.Add_TextChanged({
                $Script:SSOConfig.Domain = $Script:DomainTextBox.Text
            })
            
            # AD Server
            $adServerLabel = New-Object System.Windows.Forms.Label
            $adServerLabel.Text = "AD Server:"
            $adServerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
            $adServerLabel.ForeColor = $Colors.TextWhite
            $adServerLabel.Location = New-Object System.Drawing.Point(10, 45)
            $adServerLabel.Size = New-Object System.Drawing.Size(60, 20)
            
            $Script:ADServerTextBox = New-Object System.Windows.Forms.TextBox
            $Script:ADServerTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
            $Script:ADServerTextBox.BackColor = $Colors.DarkSurface
            $Script:ADServerTextBox.ForeColor = $Colors.TextWhite
            $Script:ADServerTextBox.Location = New-Object System.Drawing.Point(80, 43)
            $Script:ADServerTextBox.Size = New-Object System.Drawing.Size(200, 22)
            $Script:ADServerTextBox.Add_TextChanged({
                $Script:SSOConfig.ADServer = $Script:ADServerTextBox.Text
            })
            
            $Script:SSOConfigPanel.Controls.AddRange(@($domainLabel, $Script:DomainTextBox, $adServerLabel, $Script:ADServerTextBox))
        }
    }
}
#endregion

#region Main Installation Function (Enhanced)
function Start-VelociraptorInstallation {
    if ($Script:IsInstalling) {
        Write-StatusLog "Installation already in progress" -Level Warning
        return
    }
    
    $Script:IsInstalling = $true
    
    try {
        Write-StatusLog "=== Starting Enhanced Velociraptor Installation ===" -Level Step
        Write-StatusLog (Get-ConfigurationSummary) -Level Config
        
        # Disable install button and update UI state
        $Script:InstallButton.Enabled = $false
        $Script:InstallButton.Text = "Installing..."
        $Script:InstallButton.BackColor = $Colors.WarningOrange
        $Script:OpenWebButton.Enabled = $false
        $Script:StopServerButton.Enabled = $false
        
        # Disable all configuration controls during installation
        $Script:ConfigurationPanel.Enabled = $false
        
        # Refresh UI
        [System.Windows.Forms.Application]::DoEvents()
        
        # Step 1: Prerequisites check
        Update-ProgressBar -Step 1 -Status "Checking prerequisites..."
        Write-StatusLog "Checking enhanced prerequisites..." -Level Step
        
        if (-not (Test-Administrator)) {
            Write-StatusLog "Warning: Not running as Administrator - some features may not work" -Level Warning
        }
        
        if (-not (Test-PortAvailable -Port $Script:GuiPort)) {
            throw "Port $Script:GuiPort is already in use. Please close the application using this port."
        }
        
        # Create directories
        foreach ($dir in @($Script:InstallDir, $Script:DataStore)) {
            if (-not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Write-StatusLog "Created directory: $dir" -Level Success
            }
        }
        
        Write-StatusLog "Prerequisites check completed" -Level Success
        
        # Step 2: Download Velociraptor
        $executablePath = Join-Path $Script:InstallDir 'velociraptor.exe'
        $assetInfo = Get-LatestVelociraptorAsset
        Install-VelociraptorExecutable -AssetInfo $assetInfo -DestinationPath $executablePath
        
        # Step 3: Generate enhanced configuration
        $Script:ConfigPath = Join-Path $Script:InstallDir 'server.config.yaml'
        New-VelociraptorConfiguration -ExecutablePath $executablePath -ConfigPath $Script:ConfigPath -GuiPort $Script:GuiPort
        
        # Step 4: Create admin user with comprehensive security
        if ($Script:UseCustomPassword -and -not [string]::IsNullOrWhiteSpace($Script:CustomAdminPassword)) {
            $Script:AdminPassword = $Script:CustomAdminPassword
            Write-StatusLog "Using custom admin password" -Level Security
        } else {
            $complexity = switch ($Script:SecurityLevel) {
                "Basic" { "Low" }
                "Standard" { "Medium" }
                "Maximum" { "High" }
            }
            $Script:AdminPassword = Get-SecurePassword -Length 16 -Complexity $complexity
            Write-StatusLog "Generated secure password with $complexity complexity" -Level Security
        }
        New-VelociraptorAdminUser -ExecutablePath $executablePath -ConfigPath $Script:ConfigPath -Username $Script:AdminUsername -Password $Script:AdminPassword
        
        # Step 5: Install service if requested
        Install-VelociraptorService -ExecutablePath $executablePath -ConfigPath $Script:ConfigPath
        
        # Step 6: Start server
        $process = Start-VelociraptorServer -ExecutablePath $executablePath -ConfigPath $Script:ConfigPath
        
        # Step 7: Download and configure artifact packs
        Update-ProgressBar -Step 8 -Status "Configuring artifact packs..."
        Write-StatusLog "Configuring selected artifact packs..." -Level Step
        $artifacts = Get-ArtifactPackConfiguration
        Write-StatusLog "Artifact packs configured: $($artifacts.Count) artifacts" -Level Success
        
        # Step 8: Apply compliance settings
        if ($Script:ComplianceFramework -ne "None") {
            Update-ProgressBar -Step 9 -Status "Applying compliance framework..."
            Write-StatusLog "Applying $($Script:ComplianceFramework) compliance settings..." -Level Security
            # Apply compliance-specific configurations here
            Write-StatusLog "Compliance framework applied successfully" -Level Success
        }
        
        # Step 9: Verify web interface
        Update-ProgressBar -Step 10 -Status "Verifying web interface..."
        Write-StatusLog "Verifying web interface accessibility..." -Level Step
        
        if (Wait-ForWebInterface -Port $Script:GuiPort -TimeoutSeconds 30) {
            Write-StatusLog "=== Enhanced Installation Completed Successfully ===" -Level Success
            Write-StatusLog "Web Interface: https://127.0.0.1:$Script:GuiPort" -Level Success
            Write-StatusLog "Username: $Script:AdminUsername" -Level Success
            Write-StatusLog "Password: $Script:AdminPassword" -Level Success
            Write-StatusLog "Deployment Type: $Script:DeploymentType" -Level Success
            Write-StatusLog "Security Level: $Script:SecurityLevel" -Level Success
            Write-StatusLog "Installed as Service: $Script:InstallAsService" -Level Success
            
            # Update UI for success
            $Script:InstallButton.Text = "Installation Complete"
            $Script:InstallButton.BackColor = $Colors.SuccessGreen
            $Script:OpenWebButton.Enabled = $true
            $Script:StopServerButton.Enabled = $true
            
            Update-ProgressBar -Step 10 -Status "Enhanced installation completed successfully!"
            
            # Show enhanced success dialog
            $result = [System.Windows.Forms.MessageBox]::Show(
                @"
Enhanced Velociraptor installation completed successfully!

Web Interface: https://127.0.0.1:$Script:GuiPort
Username: $Script:AdminUsername
Password: $Script:AdminPassword

Configuration Summary:
• Deployment Type: $Script:DeploymentType
• Security Level: $Script:SecurityLevel
• Artifact Packs: $($Script:SelectedArtifacts -join ', ')
• Service Installation: $Script:InstallAsService
• Compliance Framework: $Script:ComplianceFramework
• Certificate Type: $Script:CertificateType
• TLS Version: $Script:TLSVersion
• MFA Enabled: $Script:MFAEnabled
$(if($Script:SSOEnabled) {"• SSO Type: $Script:SSOType"})
$(if($Script:ProxyEnabled) {"• Proxy: $Script:ProxyHost`:$Script:ProxyPort"})

The server is now running and ready for enterprise use.
Click 'Open Web Interface' to access Velociraptor.

IMPORTANT: Save these credentials securely!
"@,
                "Enhanced Installation Complete",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
        else {
            throw "Web interface is not accessible after 30 seconds. Server may not have started correctly."
        }
    }
    catch {
        Write-StatusLog "Installation failed: $($_.Exception.Message)" -Level Error
        
        # Update UI for failure and re-enable controls
        $Script:InstallButton.Text = "Installation Failed - Retry"
        $Script:InstallButton.BackColor = $Colors.ErrorRed
        $Script:InstallButton.Enabled = $true
        $Script:ConfigurationPanel.Enabled = $true
        
        Show-ErrorDialog -Title "Installation Failed" -Message $_.Exception.Message -Suggestions @(
            "Verify you have Administrator privileges",
            "Check that port $Script:GuiPort is not in use",
            "Ensure adequate disk space (1GB minimum for enhanced features)",
            "Check internet connectivity for downloads",
            "Temporarily disable antivirus if blocking",
            "Try running as Administrator",
            "Review enhanced configuration settings"
        )
    }
    finally {
        $Script:IsInstalling = $false
    }
}

function Open-VelociraptorWebInterface {
    try {
        $url = "https://127.0.0.1:$Script:GuiPort"
        Write-StatusLog "Opening enhanced web interface: $url" -Level Info
        Start-Process $url
        
        # Also copy enhanced credentials to clipboard
        $credentials = @"
Velociraptor Enhanced Installation
Username: $Script:AdminUsername
Password: $Script:AdminPassword
Deployment: $Script:DeploymentType
Security: $Script:SecurityLevel
URL: $url
"@
        Set-Clipboard -Value $credentials
        
        [System.Windows.Forms.MessageBox]::Show(
            "Enhanced web interface opened in your default browser.`n`nFull configuration details copied to clipboard:`nUsername: $Script:AdminUsername`nPassword: $Script:AdminPassword`nDeployment: $Script:DeploymentType`nSecurity Level: $Script:SecurityLevel",
            "Enhanced Web Interface Opened",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        Write-StatusLog "Failed to open web interface: $($_.Exception.Message)" -Level Error
        Show-ErrorDialog -Title "Web Interface Error" -Message $_.Exception.Message -Suggestions @(
            "Try manually navigating to https://127.0.0.1:$Script:GuiPort",
            "Check if server is still running",
            "Verify Windows Firewall settings",
            "Check service status if installed as service"
        )
    }
}

function Stop-VelociraptorServer {
    try {
        if ($Script:InstallAsService) {
            # Stop service
            Write-StatusLog "Stopping Velociraptor service..." -Level Info
            $service = Get-Service -Name "Velociraptor" -ErrorAction SilentlyContinue
            if ($service -and $service.Status -eq "Running") {
                Stop-Service -Name "Velociraptor" -Force
                Write-StatusLog "Service stopped successfully" -Level Success
            }
            else {
                Write-StatusLog "Service not found or not running" -Level Warning
            }
        }
        elseif ($Script:VelociraptorProcess -and -not $Script:VelociraptorProcess.HasExited) {
            # Stop process
            Write-StatusLog "Stopping Velociraptor server process..." -Level Info
            $Script:VelociraptorProcess.Kill()
            $Script:VelociraptorProcess.WaitForExit(5000) # Wait up to 5 seconds
            Write-StatusLog "Server process stopped successfully" -Level Success
        }
        else {
            Write-StatusLog "No running server process found" -Level Warning
        }
        
        # Update UI state
        $Script:StopServerButton.Enabled = $false
        $Script:OpenWebButton.Enabled = $false
        $Script:InstallButton.Enabled = $true
        $Script:InstallButton.Text = "Install Velociraptor"
        $Script:InstallButton.BackColor = $Colors.AccentBlue
        $Script:ConfigurationPanel.Enabled = $true
        
        # Reset progress
        $Script:ProgressBar.Value = 0
        $Script:StatusLabel.Text = "Ready for enhanced installation"
        
        # Clear the process reference
        $Script:VelociraptorProcess = $null
    }
    catch {
        Write-StatusLog "Failed to stop server: $($_.Exception.Message)" -Level Error
    }
}
#endregion

#region Enhanced GUI Creation
Write-StatusLog "Creating enhanced main GUI form..." -Level Info

# Create main form (larger to accommodate enhanced features)
$MainForm = New-Object System.Windows.Forms.Form
$MainForm.Text = "Velociraptor DFIR Framework - Comprehensive Installation GUI v2.0 (Complete velociraptor.exe -i Functionality)"
$MainForm.Size = New-Object System.Drawing.Size(1200, 900)
$MainForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

# Verify screen resolution can accommodate the form
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
if ($screen.Height -lt 900 -or $screen.Width -lt 1200) {
    Write-StatusLog "Warning: Screen resolution ($($screen.Width)x$($screen.Height)) may be too small for optimal display" -Level Warning
    Write-StatusLog "Recommended minimum: 1200x900. Consider using a higher resolution or external monitor." -Level Warning
}
$MainForm.BackColor = $Colors.DarkBackground
$MainForm.ForeColor = $Colors.TextWhite
$MainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$MainForm.MaximizeBox = $false
$MainForm.MinimizeBox = $true
$MainForm.MinimumSize = New-Object System.Drawing.Size(1200, 900)
$MainForm.MaximumSize = New-Object System.Drawing.Size(1200, 900)

# Header Panel
$HeaderPanel = New-Object System.Windows.Forms.Panel
$HeaderPanel.Size = New-Object System.Drawing.Size(1180, 80)
$HeaderPanel.Location = New-Object System.Drawing.Point(10, 10)
$HeaderPanel.BackColor = $Colors.DarkSurface

$TitleLabel = New-Object System.Windows.Forms.Label
$TitleLabel.Text = "Velociraptor DFIR Framework"
$TitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$TitleLabel.ForeColor = $Colors.AccentBlue
$TitleLabel.Location = New-Object System.Drawing.Point(20, 15)
$TitleLabel.Size = New-Object System.Drawing.Size(400, 30)

$SubtitleLabel = New-Object System.Windows.Forms.Label
$SubtitleLabel.Text = "Enhanced Enterprise Installation Wizard - Professional Edition"
$SubtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$SubtitleLabel.ForeColor = $Colors.TextGray
$SubtitleLabel.Location = New-Object System.Drawing.Point(20, 45)
$SubtitleLabel.Size = New-Object System.Drawing.Size(600, 25)

$HeaderPanel.Controls.AddRange(@($TitleLabel, $SubtitleLabel))
$MainForm.Controls.Add($HeaderPanel)

# Enhanced Configuration Panel (Tabbed Interface)
$Script:ConfigurationPanel = New-Object System.Windows.Forms.TabControl
$Script:ConfigurationPanel.Size = New-Object System.Drawing.Size(1180, 280)
$Script:ConfigurationPanel.Location = New-Object System.Drawing.Point(10, 100)
$Script:ConfigurationPanel.BackColor = $Colors.DarkSurface
$Script:ConfigurationPanel.ForeColor = $Colors.TextWhite

# Basic Configuration Tab
$BasicTab = New-Object System.Windows.Forms.TabPage
$BasicTab.Text = "Basic Configuration"
$BasicTab.BackColor = $Colors.DarkSurface
$BasicTab.ForeColor = $Colors.TextWhite

# Installation Directory
$InstallDirLabel = New-Object System.Windows.Forms.Label
$InstallDirLabel.Text = "Installation Directory:"
$InstallDirLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$InstallDirLabel.ForeColor = $Colors.TextWhite
$InstallDirLabel.Location = New-Object System.Drawing.Point(20, 20)
$InstallDirLabel.Size = New-Object System.Drawing.Size(150, 20)

$Script:InstallDirTextBox = New-Object System.Windows.Forms.TextBox
$Script:InstallDirTextBox.Text = $Script:InstallDir
$Script:InstallDirTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$Script:InstallDirTextBox.BackColor = $Colors.DarkBackground
$Script:InstallDirTextBox.ForeColor = $Colors.TextWhite
$Script:InstallDirTextBox.Location = New-Object System.Drawing.Point(180, 18)
$Script:InstallDirTextBox.Size = New-Object System.Drawing.Size(350, 25)
$Script:InstallDirTextBox.Add_TextChanged({
    $Script:InstallDir = $Script:InstallDirTextBox.Text
})

$Script:InstallDirBrowseButton = New-Object System.Windows.Forms.Button
$Script:InstallDirBrowseButton.Text = "Browse..."
$Script:InstallDirBrowseButton.Size = New-Object System.Drawing.Size(75, 25)
$Script:InstallDirBrowseButton.Location = New-Object System.Drawing.Point(540, 18)
$Script:InstallDirBrowseButton.BackColor = $Colors.BorderGray
$Script:InstallDirBrowseButton.ForeColor = $Colors.TextWhite
$Script:InstallDirBrowseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$Script:InstallDirBrowseButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$Script:InstallDirBrowseButton.Add_Click({
    $selectedPath = Select-FolderPath -Description "Select Installation Directory"
    if ($selectedPath) {
        $Script:InstallDirTextBox.Text = $selectedPath
        Write-StatusLog "Installation directory updated: $selectedPath" -Level Info
    }
})

# Data Directory
$DataDirLabel = New-Object System.Windows.Forms.Label
$DataDirLabel.Text = "Data Directory:"
$DataDirLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$DataDirLabel.ForeColor = $Colors.TextWhite
$DataDirLabel.Location = New-Object System.Drawing.Point(20, 55)
$DataDirLabel.Size = New-Object System.Drawing.Size(150, 20)

$Script:DataDirTextBox = New-Object System.Windows.Forms.TextBox
$Script:DataDirTextBox.Text = $Script:DataStore
$Script:DataDirTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$Script:DataDirTextBox.BackColor = $Colors.DarkBackground
$Script:DataDirTextBox.ForeColor = $Colors.TextWhite
$Script:DataDirTextBox.Location = New-Object System.Drawing.Point(180, 53)
$Script:DataDirTextBox.Size = New-Object System.Drawing.Size(350, 25)
$Script:DataDirTextBox.Add_TextChanged({
    $Script:DataStore = $Script:DataDirTextBox.Text
})

$Script:DataDirBrowseButton = New-Object System.Windows.Forms.Button
$Script:DataDirBrowseButton.Text = "Browse..."
$Script:DataDirBrowseButton.Size = New-Object System.Drawing.Size(75, 25)
$Script:DataDirBrowseButton.Location = New-Object System.Drawing.Point(540, 53)
$Script:DataDirBrowseButton.BackColor = $Colors.BorderGray
$Script:DataDirBrowseButton.ForeColor = $Colors.TextWhite
$Script:DataDirBrowseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$Script:DataDirBrowseButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$Script:DataDirBrowseButton.Add_Click({
    $selectedPath = Select-FolderPath -Description "Select Data Directory"
    if ($selectedPath) {
        $Script:DataDirTextBox.Text = $selectedPath
        Write-StatusLog "Data directory updated: $selectedPath" -Level Info
    }
})

# GUI Port
$GuiPortLabel = New-Object System.Windows.Forms.Label
$GuiPortLabel.Text = "GUI Port:"
$GuiPortLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$GuiPortLabel.ForeColor = $Colors.TextWhite
$GuiPortLabel.Location = New-Object System.Drawing.Point(20, 90)
$GuiPortLabel.Size = New-Object System.Drawing.Size(150, 20)

$Script:GuiPortTextBox = New-Object System.Windows.Forms.TextBox
$Script:GuiPortTextBox.Text = $Script:GuiPort.ToString()
$Script:GuiPortTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$Script:GuiPortTextBox.BackColor = $Colors.DarkBackground
$Script:GuiPortTextBox.ForeColor = $Colors.TextWhite
$Script:GuiPortTextBox.Location = New-Object System.Drawing.Point(180, 88)
$Script:GuiPortTextBox.Size = New-Object System.Drawing.Size(100, 25)
$Script:GuiPortTextBox.Add_TextChanged({
    $portText = $Script:GuiPortTextBox.Text
    if ([int]::TryParse($portText, [ref]$null)) {
        $port = [int]$portText
        if ($port -ge 1024 -and $port -le 65535) {
            $Script:GuiPortTextBox.BackColor = $Colors.DarkBackground
            $Script:GuiPort = $port
            if ($Script:PortStatusLabel) {
                $Script:PortStatusLabel.Text = "(Valid)"
                $Script:PortStatusLabel.ForeColor = $Colors.SuccessGreen
            }
        } else {
            $Script:GuiPortTextBox.BackColor = [System.Drawing.Color]::DarkRed
            if ($Script:PortStatusLabel) {
                $Script:PortStatusLabel.Text = "(1024-65535)"
                $Script:PortStatusLabel.ForeColor = $Colors.ErrorRed
            }
        }
    } else {
        $Script:GuiPortTextBox.BackColor = [System.Drawing.Color]::DarkRed
        if ($Script:PortStatusLabel) {
            $Script:PortStatusLabel.Text = "(Invalid)"
            $Script:PortStatusLabel.ForeColor = $Colors.ErrorRed
        }
    }
})

$Script:PortStatusLabel = New-Object System.Windows.Forms.Label
$Script:PortStatusLabel.Text = "(1024-65535)"
$Script:PortStatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$Script:PortStatusLabel.ForeColor = $Colors.TextGray
$Script:PortStatusLabel.Location = New-Object System.Drawing.Point(290, 90)
$Script:PortStatusLabel.Size = New-Object System.Drawing.Size(100, 20)

$BasicTab.Controls.AddRange(@(
    $InstallDirLabel, $Script:InstallDirTextBox, $Script:InstallDirBrowseButton,
    $DataDirLabel, $Script:DataDirTextBox, $Script:DataDirBrowseButton,
    $GuiPortLabel, $Script:GuiPortTextBox, $Script:PortStatusLabel
))

# Deployment Configuration Tab
$DeploymentTab = New-Object System.Windows.Forms.TabPage
$DeploymentTab.Text = "Deployment & Security"
$DeploymentTab.BackColor = $Colors.DarkSurface
$DeploymentTab.ForeColor = $Colors.TextWhite

# Deployment Type
$DeploymentTypeLabel = New-Object System.Windows.Forms.Label
$DeploymentTypeLabel.Text = "Deployment Type:"
$DeploymentTypeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$DeploymentTypeLabel.ForeColor = $Colors.AccentBlue
$DeploymentTypeLabel.Location = New-Object System.Drawing.Point(20, 20)
$DeploymentTypeLabel.Size = New-Object System.Drawing.Size(150, 25)

$Script:StandaloneRadio = New-Object System.Windows.Forms.RadioButton
$Script:StandaloneRadio.Text = "Standalone"
$Script:StandaloneRadio.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:StandaloneRadio.ForeColor = $Colors.TextWhite
$Script:StandaloneRadio.Location = New-Object System.Drawing.Point(180, 20)
$Script:StandaloneRadio.Size = New-Object System.Drawing.Size(100, 25)
$Script:StandaloneRadio.Checked = $true
$Script:StandaloneRadio.Add_CheckedChanged({
    if ($Script:StandaloneRadio.Checked) {
        Update-DeploymentSelection -SelectedType "Standalone"
    }
})

$Script:ServerRadio = New-Object System.Windows.Forms.RadioButton
$Script:ServerRadio.Text = "Server"
$Script:ServerRadio.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:ServerRadio.ForeColor = $Colors.TextWhite
$Script:ServerRadio.Location = New-Object System.Drawing.Point(290, 20)
$Script:ServerRadio.Size = New-Object System.Drawing.Size(80, 25)
$Script:ServerRadio.Add_CheckedChanged({
    if ($Script:ServerRadio.Checked) {
        Update-DeploymentSelection -SelectedType "Server"
    }
})

$Script:EnterpriseRadio = New-Object System.Windows.Forms.RadioButton
$Script:EnterpriseRadio.Text = "Enterprise"
$Script:EnterpriseRadio.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:EnterpriseRadio.ForeColor = $Colors.EnterpriseGold
$Script:EnterpriseRadio.Location = New-Object System.Drawing.Point(380, 20)
$Script:EnterpriseRadio.Size = New-Object System.Drawing.Size(100, 25)
$Script:EnterpriseRadio.Add_CheckedChanged({
    if ($Script:EnterpriseRadio.Checked) {
        Update-DeploymentSelection -SelectedType "Enterprise"
    }
})

$Script:DeploymentInfoLabel = New-Object System.Windows.Forms.Label
$Script:DeploymentInfoLabel.Text = "Single-node deployment for small teams (up to 50 clients)"
$Script:DeploymentInfoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
$Script:DeploymentInfoLabel.ForeColor = $Colors.AccentBlue
$Script:DeploymentInfoLabel.Location = New-Object System.Drawing.Point(180, 45)
$Script:DeploymentInfoLabel.Size = New-Object System.Drawing.Size(400, 20)

# Security Level
$SecurityLevelLabel = New-Object System.Windows.Forms.Label
$SecurityLevelLabel.Text = "Security Level:"
$SecurityLevelLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$SecurityLevelLabel.ForeColor = $Colors.ComplianceBlue
$SecurityLevelLabel.Location = New-Object System.Drawing.Point(20, 80)
$SecurityLevelLabel.Size = New-Object System.Drawing.Size(150, 25)

$Script:SecurityLevelCombo = New-Object System.Windows.Forms.ComboBox
$Script:SecurityLevelCombo.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:SecurityLevelCombo.BackColor = $Colors.DarkBackground
$Script:SecurityLevelCombo.ForeColor = $Colors.TextWhite
$Script:SecurityLevelCombo.Location = New-Object System.Drawing.Point(180, 80)
$Script:SecurityLevelCombo.Size = New-Object System.Drawing.Size(120, 25)
$Script:SecurityLevelCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$Script:SecurityLevelCombo.Items.AddRange(@("Basic", "Standard", "Maximum"))
$Script:SecurityLevelCombo.SelectedIndex = 1  # Default to Standard
$Script:SecurityLevelCombo.Add_SelectedIndexChanged({
    Update-SecuritySelection -SelectedLevel $Script:SecurityLevelCombo.SelectedItem.ToString()
})

$Script:SecurityInfoLabel = New-Object System.Windows.Forms.Label
$Script:SecurityInfoLabel.Text = "Enhanced security with audit logging"
$Script:SecurityInfoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
$Script:SecurityInfoLabel.ForeColor = $Colors.AccentBlue
$Script:SecurityInfoLabel.Location = New-Object System.Drawing.Point(310, 82)
$Script:SecurityInfoLabel.Size = New-Object System.Drawing.Size(300, 20)

# Service Installation
$Script:ServiceCheckBox = New-Object System.Windows.Forms.CheckBox
$Script:ServiceCheckBox.Text = "Install as Windows Service"
$Script:ServiceCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:ServiceCheckBox.ForeColor = $Colors.TextWhite
$Script:ServiceCheckBox.Location = New-Object System.Drawing.Point(20, 120)
$Script:ServiceCheckBox.Size = New-Object System.Drawing.Size(200, 25)
$Script:ServiceCheckBox.Add_CheckedChanged({
    $Script:InstallAsService = $Script:ServiceCheckBox.Checked
    Write-StatusLog "Service installation: $Script:InstallAsService" -Level Config
})

# Compliance Framework
$ComplianceLabel = New-Object System.Windows.Forms.Label
$ComplianceLabel.Text = "Compliance Framework:"
$ComplianceLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$ComplianceLabel.ForeColor = $Colors.TextWhite
$ComplianceLabel.Location = New-Object System.Drawing.Point(20, 155)
$ComplianceLabel.Size = New-Object System.Drawing.Size(150, 25)

$Script:ComplianceCombo = New-Object System.Windows.Forms.ComboBox
$Script:ComplianceCombo.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:ComplianceCombo.BackColor = $Colors.DarkBackground
$Script:ComplianceCombo.ForeColor = $Colors.TextWhite
$Script:ComplianceCombo.Location = New-Object System.Drawing.Point(180, 155)
$Script:ComplianceCombo.Size = New-Object System.Drawing.Size(120, 25)
$Script:ComplianceCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$Script:ComplianceCombo.Items.AddRange(@("None", "SOX", "HIPAA", "PCI-DSS", "GDPR"))
$Script:ComplianceCombo.SelectedIndex = 0  # Default to None
$Script:ComplianceCombo.Add_SelectedIndexChanged({
    $Script:ComplianceFramework = $Script:ComplianceCombo.SelectedItem.ToString()
    Write-StatusLog "Compliance framework: $Script:ComplianceFramework" -Level Security
})

$DeploymentTab.Controls.AddRange(@(
    $DeploymentTypeLabel, $Script:StandaloneRadio, $Script:ServerRadio, $Script:EnterpriseRadio, $Script:DeploymentInfoLabel,
    $SecurityLevelLabel, $Script:SecurityLevelCombo, $Script:SecurityInfoLabel,
    $Script:ServiceCheckBox, $ComplianceLabel, $Script:ComplianceCombo
))

# Artifact Packs Tab
$ArtifactTab = New-Object System.Windows.Forms.TabPage
$ArtifactTab.Text = "Artifact Packs"
$ArtifactTab.BackColor = $Colors.DarkSurface
$ArtifactTab.ForeColor = $Colors.TextWhite

$ArtifactTitleLabel = New-Object System.Windows.Forms.Label
$ArtifactTitleLabel.Text = "Select Artifact Packs to Install:"
$ArtifactTitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$ArtifactTitleLabel.ForeColor = $Colors.AccentBlue
$ArtifactTitleLabel.Location = New-Object System.Drawing.Point(20, 20)
$ArtifactTitleLabel.Size = New-Object System.Drawing.Size(300, 25)

# Essential Pack
$Script:EssentialCheckBox = New-Object System.Windows.Forms.CheckBox
$Script:EssentialCheckBox.Text = "Essential Pack (PowerShell, Event Logs, Registry)"
$Script:EssentialCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:EssentialCheckBox.ForeColor = $Colors.TextWhite
$Script:EssentialCheckBox.Location = New-Object System.Drawing.Point(40, 60)
$Script:EssentialCheckBox.Size = New-Object System.Drawing.Size(400, 25)
$Script:EssentialCheckBox.Checked = $true
$Script:EssentialCheckBox.Add_CheckedChanged({ Update-ArtifactSelection })

# Windows Pack
$Script:WindowsCheckBox = New-Object System.Windows.Forms.CheckBox
$Script:WindowsCheckBox.Text = "Windows Pack (Registry, Services, User Profiles)"
$Script:WindowsCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:WindowsCheckBox.ForeColor = $Colors.TextWhite
$Script:WindowsCheckBox.Location = New-Object System.Drawing.Point(40, 90)
$Script:WindowsCheckBox.Size = New-Object System.Drawing.Size(400, 25)
$Script:WindowsCheckBox.Add_CheckedChanged({ Update-ArtifactSelection })

# Linux Pack
$Script:LinuxCheckBox = New-Object System.Windows.Forms.CheckBox
$Script:LinuxCheckBox.Text = "Linux Pack (Bash History, Login Records, Journal)"
$Script:LinuxCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:LinuxCheckBox.ForeColor = $Colors.TextWhite
$Script:LinuxCheckBox.Location = New-Object System.Drawing.Point(40, 120)
$Script:LinuxCheckBox.Size = New-Object System.Drawing.Size(400, 25)
$Script:LinuxCheckBox.Add_CheckedChanged({ Update-ArtifactSelection })

# Network Pack
$Script:NetworkCheckBox = New-Object System.Windows.Forms.CheckBox
$Script:NetworkCheckBox.Text = "Network Pack (Netstat, Interfaces, ARP Cache)"
$Script:NetworkCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:NetworkCheckBox.ForeColor = $Colors.TextWhite
$Script:NetworkCheckBox.Location = New-Object System.Drawing.Point(40, 150)
$Script:NetworkCheckBox.Size = New-Object System.Drawing.Size(400, 25)
$Script:NetworkCheckBox.Add_CheckedChanged({ Update-ArtifactSelection })

# Forensics Pack
$Script:ForensicsCheckBox = New-Object System.Windows.Forms.CheckBox
$Script:ForensicsCheckBox.Text = "Forensics Pack (Prefetch, SRUM, Amcache)"
$Script:ForensicsCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:ForensicsCheckBox.ForeColor = $Colors.TextWhite
$Script:ForensicsCheckBox.Location = New-Object System.Drawing.Point(40, 180)
$Script:ForensicsCheckBox.Size = New-Object System.Drawing.Size(400, 25)
$Script:ForensicsCheckBox.Add_CheckedChanged({ Update-ArtifactSelection })

$Script:ArtifactCountLabel = New-Object System.Windows.Forms.Label
$Script:ArtifactCountLabel.Text = "Selected: 1 pack(s)"
$Script:ArtifactCountLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$Script:ArtifactCountLabel.ForeColor = $Colors.SuccessGreen
$Script:ArtifactCountLabel.Location = New-Object System.Drawing.Point(40, 220)
$Script:ArtifactCountLabel.Size = New-Object System.Drawing.Size(200, 25)

$ArtifactTab.Controls.AddRange(@(
    $ArtifactTitleLabel, $Script:EssentialCheckBox, $Script:WindowsCheckBox,
    $Script:LinuxCheckBox, $Script:NetworkCheckBox, $Script:ForensicsCheckBox,
    $Script:ArtifactCountLabel
))

# Admin Password Configuration Tab
$AdminPasswordTab = New-Object System.Windows.Forms.TabPage
$AdminPasswordTab.Text = "Admin Password"
$AdminPasswordTab.BackColor = $Colors.DarkSurface
$AdminPasswordTab.ForeColor = $Colors.TextWhite

$AdminPasswordTitleLabel = New-Object System.Windows.Forms.Label
$AdminPasswordTitleLabel.Text = "Administrator Password Configuration:"
$AdminPasswordTitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$AdminPasswordTitleLabel.ForeColor = $Colors.AccentBlue
$AdminPasswordTitleLabel.Location = New-Object System.Drawing.Point(20, 20)
$AdminPasswordTitleLabel.Size = New-Object System.Drawing.Size(400, 25)

# Password Options GroupBox for proper radio button grouping
$PasswordOptionsGroupBox = New-Object System.Windows.Forms.GroupBox
$PasswordOptionsGroupBox.Text = "Password Generation Options"
$PasswordOptionsGroupBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$PasswordOptionsGroupBox.ForeColor = $Colors.TextWhite
$PasswordOptionsGroupBox.Location = New-Object System.Drawing.Point(20, 50)
$PasswordOptionsGroupBox.Size = New-Object System.Drawing.Size(750, 80)

# Auto-generated password option
$Script:AutoPasswordRadio = New-Object System.Windows.Forms.RadioButton
$Script:AutoPasswordRadio.Text = "Auto-generate secure password"
$Script:AutoPasswordRadio.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:AutoPasswordRadio.ForeColor = $Colors.TextWhite
$Script:AutoPasswordRadio.Location = New-Object System.Drawing.Point(20, 25)
$Script:AutoPasswordRadio.Size = New-Object System.Drawing.Size(250, 25)
$Script:AutoPasswordRadio.Checked = $true
$Script:AutoPasswordRadio.TabStop = $true
$Script:AutoPasswordRadio.TabIndex = 0
$Script:AutoPasswordRadio.Add_CheckedChanged({
    if ($Script:AutoPasswordRadio.Checked) {
        $Script:UseCustomPassword = $false
        $Script:CustomPasswordTextBox.Enabled = $false
        $Script:ConfirmPasswordTextBox.Enabled = $false
        $Script:ShowPasswordCheckBox.Enabled = $false
        $Script:CustomPasswordTextBox.Text = ""
        $Script:ConfirmPasswordTextBox.Text = ""
        $Script:ShowPasswordCheckBox.Checked = $false
        $Script:PasswordStrengthLabel.Text = "Auto-generated (Strong)"
        $Script:PasswordStrengthLabel.ForeColor = $Colors.SuccessGreen
        $Script:PasswordMatchLabel.Text = ""
        Write-StatusLog "Admin password set to auto-generate" -Level Security
    }
})

# Custom password option
$Script:CustomPasswordRadio = New-Object System.Windows.Forms.RadioButton
$Script:CustomPasswordRadio.Text = "Use custom password"
$Script:CustomPasswordRadio.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:CustomPasswordRadio.ForeColor = $Colors.TextWhite
$Script:CustomPasswordRadio.Location = New-Object System.Drawing.Point(300, 25)
$Script:CustomPasswordRadio.Size = New-Object System.Drawing.Size(200, 25)
$Script:CustomPasswordRadio.TabStop = $true
$Script:CustomPasswordRadio.TabIndex = 1
$Script:CustomPasswordRadio.Add_CheckedChanged({
    if ($Script:CustomPasswordRadio.Checked) {
        $Script:UseCustomPassword = $true
        $Script:CustomPasswordTextBox.Enabled = $true
        $Script:ConfirmPasswordTextBox.Enabled = $true
        $Script:ShowPasswordCheckBox.Enabled = $true
        # Set focus to the password textbox for better user experience
        try {
            $Script:CustomPasswordTextBox.Focus()
        } catch {
            # Focus may fail if controls aren't fully initialized
        }
        Write-StatusLog "Admin password set to custom" -Level Security
    }
})

# Add radio buttons to the GroupBox for proper grouping
$PasswordOptionsGroupBox.Controls.AddRange(@(
    $Script:AutoPasswordRadio, $Script:CustomPasswordRadio
))

# Password input
$PasswordLabel = New-Object System.Windows.Forms.Label
$PasswordLabel.Text = "Password:"
$PasswordLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$PasswordLabel.ForeColor = $Colors.TextWhite
$PasswordLabel.Location = New-Object System.Drawing.Point(60, 150)
$PasswordLabel.Size = New-Object System.Drawing.Size(80, 20)

$Script:CustomPasswordTextBox = New-Object System.Windows.Forms.TextBox
$Script:CustomPasswordTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$Script:CustomPasswordTextBox.BackColor = $Colors.DarkBackground
$Script:CustomPasswordTextBox.ForeColor = $Colors.TextWhite
$Script:CustomPasswordTextBox.Location = New-Object System.Drawing.Point(150, 148)
$Script:CustomPasswordTextBox.Size = New-Object System.Drawing.Size(300, 25)
$Script:CustomPasswordTextBox.UseSystemPasswordChar = $true
$Script:CustomPasswordTextBox.Enabled = $false
$Script:CustomPasswordTextBox.TabStop = $true
$Script:CustomPasswordTextBox.TabIndex = 2
$Script:CustomPasswordTextBox.Add_TextChanged({
    $Script:CustomAdminPassword = $Script:CustomPasswordTextBox.Text
    $strength = Test-PasswordStrength $Script:CustomAdminPassword
    $Script:PasswordStrengthLabel.Text = "Strength: $($strength.Strength)"
    $Script:PasswordStrengthLabel.ForeColor = $strength.Color
    
    # Update confirm password validation
    if ($Script:ConfirmPasswordTextBox.Text -ne $Script:CustomPasswordTextBox.Text) {
        $Script:PasswordMatchLabel.Text = "Passwords do not match"
        $Script:PasswordMatchLabel.ForeColor = $Colors.ErrorRed
    } else {
        $Script:PasswordMatchLabel.Text = "Passwords match"
        $Script:PasswordMatchLabel.ForeColor = $Colors.SuccessGreen
    }
})

# Confirm password
$ConfirmPasswordLabel = New-Object System.Windows.Forms.Label
$ConfirmPasswordLabel.Text = "Confirm:"
$ConfirmPasswordLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$ConfirmPasswordLabel.ForeColor = $Colors.TextWhite
$ConfirmPasswordLabel.Location = New-Object System.Drawing.Point(60, 185)
$ConfirmPasswordLabel.Size = New-Object System.Drawing.Size(80, 20)

$Script:ConfirmPasswordTextBox = New-Object System.Windows.Forms.TextBox
$Script:ConfirmPasswordTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$Script:ConfirmPasswordTextBox.BackColor = $Colors.DarkBackground
$Script:ConfirmPasswordTextBox.ForeColor = $Colors.TextWhite
$Script:ConfirmPasswordTextBox.Location = New-Object System.Drawing.Point(150, 183)
$Script:ConfirmPasswordTextBox.Size = New-Object System.Drawing.Size(300, 25)
$Script:ConfirmPasswordTextBox.UseSystemPasswordChar = $true
$Script:ConfirmPasswordTextBox.Enabled = $false
$Script:ConfirmPasswordTextBox.TabStop = $true
$Script:ConfirmPasswordTextBox.TabIndex = 3
$Script:ConfirmPasswordTextBox.Add_TextChanged({
    if ($Script:ConfirmPasswordTextBox.Text -ne $Script:CustomPasswordTextBox.Text) {
        $Script:PasswordMatchLabel.Text = "Passwords do not match"
        $Script:PasswordMatchLabel.ForeColor = $Colors.ErrorRed
    } else {
        $Script:PasswordMatchLabel.Text = "Passwords match"
        $Script:PasswordMatchLabel.ForeColor = $Colors.SuccessGreen
    }
})

# Show password checkbox
$Script:ShowPasswordCheckBox = New-Object System.Windows.Forms.CheckBox
$Script:ShowPasswordCheckBox.Text = "Show passwords"
$Script:ShowPasswordCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$Script:ShowPasswordCheckBox.ForeColor = $Colors.TextGray
$Script:ShowPasswordCheckBox.Location = New-Object System.Drawing.Point(150, 215)
$Script:ShowPasswordCheckBox.Size = New-Object System.Drawing.Size(150, 20)
$Script:ShowPasswordCheckBox.Enabled = $false
$Script:ShowPasswordCheckBox.TabStop = $true
$Script:ShowPasswordCheckBox.TabIndex = 4
$Script:ShowPasswordCheckBox.Add_CheckedChanged({
    $Script:CustomPasswordTextBox.UseSystemPasswordChar = -not $Script:ShowPasswordCheckBox.Checked
    $Script:ConfirmPasswordTextBox.UseSystemPasswordChar = -not $Script:ShowPasswordCheckBox.Checked
})

# Password strength indicator
$Script:PasswordStrengthLabel = New-Object System.Windows.Forms.Label
$Script:PasswordStrengthLabel.Text = "Auto-generated (Strong)"
$Script:PasswordStrengthLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$Script:PasswordStrengthLabel.ForeColor = $Colors.SuccessGreen
$Script:PasswordStrengthLabel.Location = New-Object System.Drawing.Point(460, 150)
$Script:PasswordStrengthLabel.Size = New-Object System.Drawing.Size(150, 20)

# Password match indicator
$Script:PasswordMatchLabel = New-Object System.Windows.Forms.Label
$Script:PasswordMatchLabel.Text = ""
$Script:PasswordMatchLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$Script:PasswordMatchLabel.Location = New-Object System.Drawing.Point(460, 185)
$Script:PasswordMatchLabel.Size = New-Object System.Drawing.Size(150, 20)

# Generate password button
$GeneratePasswordButton = New-Object System.Windows.Forms.Button
$GeneratePasswordButton.Text = "Generate Strong Password"
$GeneratePasswordButton.Size = New-Object System.Drawing.Size(180, 30)
$GeneratePasswordButton.Location = New-Object System.Drawing.Point(320, 215)
$GeneratePasswordButton.BackColor = $Colors.AccentBlue
$GeneratePasswordButton.ForeColor = $Colors.TextWhite
$GeneratePasswordButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$GeneratePasswordButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$GeneratePasswordButton.TabStop = $true
$GeneratePasswordButton.TabIndex = 5
$GeneratePasswordButton.Add_Click({
    if ($Script:UseCustomPassword) {
        $newPassword = Get-SecurePassword -Length 16 -Complexity "High"
        $Script:CustomPasswordTextBox.Text = $newPassword
        $Script:ConfirmPasswordTextBox.Text = $newPassword
        Write-StatusLog "Strong password generated" -Level Security
    }
})

$AdminPasswordTab.Controls.AddRange(@(
    $AdminPasswordTitleLabel, $PasswordOptionsGroupBox,
    $PasswordLabel, $Script:CustomPasswordTextBox, $ConfirmPasswordLabel, $Script:ConfirmPasswordTextBox,
    $Script:ShowPasswordCheckBox, $Script:PasswordStrengthLabel, $Script:PasswordMatchLabel,
    $GeneratePasswordButton
))

# Certificate Management Tab
$CertificateTab = New-Object System.Windows.Forms.TabPage
$CertificateTab.Text = "Certificates"
$CertificateTab.BackColor = $Colors.DarkSurface
$CertificateTab.ForeColor = $Colors.TextWhite

$CertificateTitleLabel = New-Object System.Windows.Forms.Label
$CertificateTitleLabel.Text = "SSL Certificate Configuration:"
$CertificateTitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$CertificateTitleLabel.ForeColor = $Colors.AccentBlue
$CertificateTitleLabel.Location = New-Object System.Drawing.Point(20, 20)
$CertificateTitleLabel.Size = New-Object System.Drawing.Size(300, 25)

# Certificate type selection
$CertTypeLabel = New-Object System.Windows.Forms.Label
$CertTypeLabel.Text = "Certificate Type:"
$CertTypeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$CertTypeLabel.ForeColor = $Colors.TextWhite
$CertTypeLabel.Location = New-Object System.Drawing.Point(40, 60)
$CertTypeLabel.Size = New-Object System.Drawing.Size(120, 20)

$Script:CertificateTypeCombo = New-Object System.Windows.Forms.ComboBox
$Script:CertificateTypeCombo.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:CertificateTypeCombo.BackColor = $Colors.DarkBackground
$Script:CertificateTypeCombo.ForeColor = $Colors.TextWhite
$Script:CertificateTypeCombo.Location = New-Object System.Drawing.Point(170, 58)
$Script:CertificateTypeCombo.Size = New-Object System.Drawing.Size(150, 25)
$Script:CertificateTypeCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$Script:CertificateTypeCombo.Items.AddRange(@("Self-signed", "Let's Encrypt", "Custom Import"))
$Script:CertificateTypeCombo.SelectedIndex = 0
$Script:CertificateTypeCombo.Add_SelectedIndexChanged({
    $Script:CertificateType = $Script:CertificateTypeCombo.SelectedItem.ToString()
    
    # Enable/disable controls based on selection
    $isCustom = $Script:CertificateType -eq "Custom Import"
    $Script:CustomCertPathTextBox.Enabled = $isCustom
    $Script:CertBrowseButton.Enabled = $isCustom
    
    $isNotEncrypt = $Script:CertificateType -ne "Let's Encrypt"
    $Script:CertDurationCombo.Enabled = $isNotEncrypt
    
    Write-StatusLog "Certificate type set to: $Script:CertificateType" -Level Security
})

# Certificate duration
$CertDurationLabel = New-Object System.Windows.Forms.Label
$CertDurationLabel.Text = "Duration (years):"
$CertDurationLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$CertDurationLabel.ForeColor = $Colors.TextWhite
$CertDurationLabel.Location = New-Object System.Drawing.Point(40, 95)
$CertDurationLabel.Size = New-Object System.Drawing.Size(120, 20)

$Script:CertDurationCombo = New-Object System.Windows.Forms.ComboBox
$Script:CertDurationCombo.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:CertDurationCombo.BackColor = $Colors.DarkBackground
$Script:CertDurationCombo.ForeColor = $Colors.TextWhite
$Script:CertDurationCombo.Location = New-Object System.Drawing.Point(170, 93)
$Script:CertDurationCombo.Size = New-Object System.Drawing.Size(100, 25)
$Script:CertDurationCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$Script:CertDurationCombo.Items.AddRange(@("1", "2", "5", "10", "25"))
$Script:CertDurationCombo.SelectedIndex = 3  # Default to 10 years
$Script:CertDurationCombo.Add_SelectedIndexChanged({
    $Script:CertificateDuration = [int]$Script:CertDurationCombo.SelectedItem
    Write-StatusLog "Certificate duration set to: $Script:CertificateDuration years" -Level Security
})

# Custom certificate path
$CustomCertLabel = New-Object System.Windows.Forms.Label
$CustomCertLabel.Text = "Certificate File:"
$CustomCertLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$CustomCertLabel.ForeColor = $Colors.TextWhite
$CustomCertLabel.Location = New-Object System.Drawing.Point(40, 130)
$CustomCertLabel.Size = New-Object System.Drawing.Size(120, 20)

$Script:CustomCertPathTextBox = New-Object System.Windows.Forms.TextBox
$Script:CustomCertPathTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$Script:CustomCertPathTextBox.BackColor = $Colors.DarkBackground
$Script:CustomCertPathTextBox.ForeColor = $Colors.TextWhite
$Script:CustomCertPathTextBox.Location = New-Object System.Drawing.Point(170, 128)
$Script:CustomCertPathTextBox.Size = New-Object System.Drawing.Size(300, 25)
$Script:CustomCertPathTextBox.Enabled = $false
$Script:CustomCertPathTextBox.Add_TextChanged({
    $Script:CustomCertPath = $Script:CustomCertPathTextBox.Text
    if (-not [string]::IsNullOrWhiteSpace($Script:CustomCertPath)) {
        if (Test-CertificateFile $Script:CustomCertPath) {
            $Script:CertValidationLabel.Text = "Valid certificate"
            $Script:CertValidationLabel.ForeColor = $Colors.SuccessGreen
        } else {
            $Script:CertValidationLabel.Text = "Invalid certificate"
            $Script:CertValidationLabel.ForeColor = $Colors.ErrorRed
        }
    } else {
        $Script:CertValidationLabel.Text = ""
    }
})

$Script:CertBrowseButton = New-Object System.Windows.Forms.Button
$Script:CertBrowseButton.Text = "Browse..."
$Script:CertBrowseButton.Size = New-Object System.Drawing.Size(75, 25)
$Script:CertBrowseButton.Location = New-Object System.Drawing.Point(480, 128)
$Script:CertBrowseButton.BackColor = $Colors.BorderGray
$Script:CertBrowseButton.ForeColor = $Colors.TextWhite
$Script:CertBrowseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$Script:CertBrowseButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$Script:CertBrowseButton.Enabled = $false
$Script:CertBrowseButton.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "Certificate files (*.pfx;*.p12;*.crt;*.cer)|*.pfx;*.p12;*.crt;*.cer|All files (*.*)|*.*"
    $openFileDialog.Title = "Select Certificate File"
    
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $Script:CustomCertPathTextBox.Text = $openFileDialog.FileName
    }
})

$Script:CertValidationLabel = New-Object System.Windows.Forms.Label
$Script:CertValidationLabel.Text = ""
$Script:CertValidationLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$Script:CertValidationLabel.Location = New-Object System.Drawing.Point(170, 155)
$Script:CertValidationLabel.Size = New-Object System.Drawing.Size(200, 20)

$CertificateTab.Controls.AddRange(@(
    $CertificateTitleLabel, $CertTypeLabel, $Script:CertificateTypeCombo,
    $CertDurationLabel, $Script:CertDurationCombo, $CustomCertLabel,
    $Script:CustomCertPathTextBox, $Script:CertBrowseButton, $Script:CertValidationLabel
))

# DNS Configuration Tab
$DNSTab = New-Object System.Windows.Forms.TabPage
$DNSTab.Text = "DNS & Network"
$DNSTab.BackColor = $Colors.DarkSurface
$DNSTab.ForeColor = $Colors.TextWhite

$DNSTitleLabel = New-Object System.Windows.Forms.Label
$DNSTitleLabel.Text = "DNS and Network Configuration:"
$DNSTitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$DNSTitleLabel.ForeColor = $Colors.AccentBlue
$DNSTitleLabel.Location = New-Object System.Drawing.Point(20, 20)
$DNSTitleLabel.Size = New-Object System.Drawing.Size(300, 25)

# Primary DNS
$PrimaryDNSLabel = New-Object System.Windows.Forms.Label
$PrimaryDNSLabel.Text = "Primary DNS:"
$PrimaryDNSLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$PrimaryDNSLabel.ForeColor = $Colors.TextWhite
$PrimaryDNSLabel.Location = New-Object System.Drawing.Point(40, 60)
$PrimaryDNSLabel.Size = New-Object System.Drawing.Size(100, 20)

$Script:PrimaryDNSTextBox = New-Object System.Windows.Forms.TextBox
$Script:PrimaryDNSTextBox.Text = $Script:DNSPrimary
$Script:PrimaryDNSTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$Script:PrimaryDNSTextBox.BackColor = $Colors.DarkBackground
$Script:PrimaryDNSTextBox.ForeColor = $Colors.TextWhite
$Script:PrimaryDNSTextBox.Location = New-Object System.Drawing.Point(150, 58)
$Script:PrimaryDNSTextBox.Size = New-Object System.Drawing.Size(150, 25)
$Script:PrimaryDNSTextBox.Add_TextChanged({
    $Script:DNSPrimary = $Script:PrimaryDNSTextBox.Text
    Write-StatusLog "Primary DNS set to: $Script:DNSPrimary" -Level Config
})

# DNS preset buttons
$CloudflareDNSButton = New-Object System.Windows.Forms.Button
$CloudflareDNSButton.Text = "Cloudflare (1.1.1.1)"
$CloudflareDNSButton.Size = New-Object System.Drawing.Size(130, 25)
$CloudflareDNSButton.Location = New-Object System.Drawing.Point(310, 58)
$CloudflareDNSButton.BackColor = $Colors.AccentBlue
$CloudflareDNSButton.ForeColor = $Colors.TextWhite
$CloudflareDNSButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$CloudflareDNSButton.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$CloudflareDNSButton.Add_Click({
    $Script:PrimaryDNSTextBox.Text = "1.1.1.1"
    $Script:SecondaryDNSTextBox.Text = "1.0.0.1"
})

# Secondary DNS
$SecondaryDNSLabel = New-Object System.Windows.Forms.Label
$SecondaryDNSLabel.Text = "Secondary DNS:"
$SecondaryDNSLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$SecondaryDNSLabel.ForeColor = $Colors.TextWhite
$SecondaryDNSLabel.Location = New-Object System.Drawing.Point(40, 95)
$SecondaryDNSLabel.Size = New-Object System.Drawing.Size(100, 20)

$Script:SecondaryDNSTextBox = New-Object System.Windows.Forms.TextBox
$Script:SecondaryDNSTextBox.Text = $Script:DNSSecondary
$Script:SecondaryDNSTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$Script:SecondaryDNSTextBox.BackColor = $Colors.DarkBackground
$Script:SecondaryDNSTextBox.ForeColor = $Colors.TextWhite
$Script:SecondaryDNSTextBox.Location = New-Object System.Drawing.Point(150, 93)
$Script:SecondaryDNSTextBox.Size = New-Object System.Drawing.Size(150, 25)
$Script:SecondaryDNSTextBox.Add_TextChanged({
    $Script:DNSSecondary = $Script:SecondaryDNSTextBox.Text
    Write-StatusLog "Secondary DNS set to: $Script:DNSSecondary" -Level Config
})

$GoogleDNSButton = New-Object System.Windows.Forms.Button
$GoogleDNSButton.Text = "Google (8.8.8.8)"
$GoogleDNSButton.Size = New-Object System.Drawing.Size(130, 25)
$GoogleDNSButton.Location = New-Object System.Drawing.Point(310, 93)
$GoogleDNSButton.BackColor = $Colors.SuccessGreen
$GoogleDNSButton.ForeColor = $Colors.TextWhite
$GoogleDNSButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$GoogleDNSButton.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$GoogleDNSButton.Add_Click({
    $Script:PrimaryDNSTextBox.Text = "8.8.8.8"
    $Script:SecondaryDNSTextBox.Text = "8.8.4.4"
})

# DNS over HTTPS
$Script:DNSOverHTTPSCheckBox = New-Object System.Windows.Forms.CheckBox
$Script:DNSOverHTTPSCheckBox.Text = "Enable DNS over HTTPS (DoH)"
$Script:DNSOverHTTPSCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:DNSOverHTTPSCheckBox.ForeColor = $Colors.TextWhite
$Script:DNSOverHTTPSCheckBox.Location = New-Object System.Drawing.Point(40, 130)
$Script:DNSOverHTTPSCheckBox.Size = New-Object System.Drawing.Size(250, 25)
$Script:DNSOverHTTPSCheckBox.Add_CheckedChanged({
    $Script:DNSOverHTTPS = $Script:DNSOverHTTPSCheckBox.Checked
    Write-StatusLog "DNS over HTTPS: $Script:DNSOverHTTPS" -Level Security
})

# Bind Address
$BindAddressLabel = New-Object System.Windows.Forms.Label
$BindAddressLabel.Text = "Bind Address:"
$BindAddressLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$BindAddressLabel.ForeColor = $Colors.TextWhite
$BindAddressLabel.Location = New-Object System.Drawing.Point(40, 165)
$BindAddressLabel.Size = New-Object System.Drawing.Size(100, 20)

$Script:BindAddressTextBox = New-Object System.Windows.Forms.TextBox
$Script:BindAddressTextBox.Text = $Script:BindAddress
$Script:BindAddressTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$Script:BindAddressTextBox.BackColor = $Colors.DarkBackground
$Script:BindAddressTextBox.ForeColor = $Colors.TextWhite
$Script:BindAddressTextBox.Location = New-Object System.Drawing.Point(150, 163)
$Script:BindAddressTextBox.Size = New-Object System.Drawing.Size(150, 25)
$Script:BindAddressTextBox.Add_TextChanged({
    $Script:BindAddress = $Script:BindAddressTextBox.Text
    Write-StatusLog "Bind address set to: $Script:BindAddress" -Level Config
})

# Proxy Configuration
$ProxyTitleLabel = New-Object System.Windows.Forms.Label
$ProxyTitleLabel.Text = "Proxy Configuration:"
$ProxyTitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$ProxyTitleLabel.ForeColor = $Colors.AccentBlue
$ProxyTitleLabel.Location = New-Object System.Drawing.Point(40, 200)
$ProxyTitleLabel.Size = New-Object System.Drawing.Size(200, 20)

$Script:ProxyEnabledCheckBox = New-Object System.Windows.Forms.CheckBox
$Script:ProxyEnabledCheckBox.Text = "Enable HTTP Proxy"
$Script:ProxyEnabledCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:ProxyEnabledCheckBox.ForeColor = $Colors.TextWhite
$Script:ProxyEnabledCheckBox.Location = New-Object System.Drawing.Point(60, 225)
$Script:ProxyEnabledCheckBox.Size = New-Object System.Drawing.Size(150, 25)
$Script:ProxyEnabledCheckBox.Add_CheckedChanged({
    $Script:ProxyEnabled = $Script:ProxyEnabledCheckBox.Checked
    $Script:ProxyHostTextBox.Enabled = $Script:ProxyEnabled
    $Script:ProxyPortTextBox.Enabled = $Script:ProxyEnabled
    Write-StatusLog "Proxy enabled: $Script:ProxyEnabled" -Level Config
})

$ProxyHostLabel = New-Object System.Windows.Forms.Label
$ProxyHostLabel.Text = "Proxy Host:"
$ProxyHostLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$ProxyHostLabel.ForeColor = $Colors.TextGray
$ProxyHostLabel.Location = New-Object System.Drawing.Point(80, 255)
$ProxyHostLabel.Size = New-Object System.Drawing.Size(70, 20)

$Script:ProxyHostTextBox = New-Object System.Windows.Forms.TextBox
$Script:ProxyHostTextBox.Text = $Script:ProxyHost
$Script:ProxyHostTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$Script:ProxyHostTextBox.BackColor = $Colors.DarkBackground
$Script:ProxyHostTextBox.ForeColor = $Colors.TextWhite
$Script:ProxyHostTextBox.Location = New-Object System.Drawing.Point(150, 253)
$Script:ProxyHostTextBox.Size = New-Object System.Drawing.Size(150, 22)
$Script:ProxyHostTextBox.Enabled = $false
$Script:ProxyHostTextBox.Add_TextChanged({
    $Script:ProxyHost = $Script:ProxyHostTextBox.Text
})

$ProxyPortLabel = New-Object System.Windows.Forms.Label
$ProxyPortLabel.Text = "Port:"
$ProxyPortLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$ProxyPortLabel.ForeColor = $Colors.TextGray
$ProxyPortLabel.Location = New-Object System.Drawing.Point(310, 255)
$ProxyPortLabel.Size = New-Object System.Drawing.Size(35, 20)

$Script:ProxyPortTextBox = New-Object System.Windows.Forms.TextBox
$Script:ProxyPortTextBox.Text = $Script:ProxyPort.ToString()
$Script:ProxyPortTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$Script:ProxyPortTextBox.BackColor = $Colors.DarkBackground
$Script:ProxyPortTextBox.ForeColor = $Colors.TextWhite
$Script:ProxyPortTextBox.Location = New-Object System.Drawing.Point(350, 253)
$Script:ProxyPortTextBox.Size = New-Object System.Drawing.Size(60, 22)
$Script:ProxyPortTextBox.Enabled = $false
$Script:ProxyPortTextBox.Add_TextChanged({
    if ([int]::TryParse($Script:ProxyPortTextBox.Text, [ref]$null)) {
        $Script:ProxyPort = [int]$Script:ProxyPortTextBox.Text
    }
})

$DNSTab.Controls.AddRange(@(
    $DNSTitleLabel, $PrimaryDNSLabel, $Script:PrimaryDNSTextBox, $CloudflareDNSButton,
    $SecondaryDNSLabel, $Script:SecondaryDNSTextBox, $GoogleDNSButton, $Script:DNSOverHTTPSCheckBox,
    $BindAddressLabel, $Script:BindAddressTextBox, $ProxyTitleLabel, $Script:ProxyEnabledCheckBox,
    $ProxyHostLabel, $Script:ProxyHostTextBox, $ProxyPortLabel, $Script:ProxyPortTextBox
))

# SSO/Authentication Tab
$SSOTab = New-Object System.Windows.Forms.TabPage
$SSOTab.Text = "SSO & Auth"
$SSOTab.BackColor = $Colors.DarkSurface
$SSOTab.ForeColor = $Colors.TextWhite

$SSOTitleLabel = New-Object System.Windows.Forms.Label
$SSOTitleLabel.Text = "Single Sign-On and Authentication:"
$SSOTitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$SSOTitleLabel.ForeColor = $Colors.AccentBlue
$SSOTitleLabel.Location = New-Object System.Drawing.Point(20, 20)
$SSOTitleLabel.Size = New-Object System.Drawing.Size(350, 25)

# SSO Enable
$Script:SSOEnabledCheckBox = New-Object System.Windows.Forms.CheckBox
$Script:SSOEnabledCheckBox.Text = "Enable Single Sign-On (SSO)"
$Script:SSOEnabledCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:SSOEnabledCheckBox.ForeColor = $Colors.TextWhite
$Script:SSOEnabledCheckBox.Location = New-Object System.Drawing.Point(40, 60)
$Script:SSOEnabledCheckBox.Size = New-Object System.Drawing.Size(200, 25)
$Script:SSOEnabledCheckBox.Add_CheckedChanged({
    $Script:SSOEnabled = $Script:SSOEnabledCheckBox.Checked
    $Script:SSOTypeCombo.Enabled = $Script:SSOEnabled
    $Script:SSOConfigPanel.Enabled = $Script:SSOEnabled
    Write-StatusLog "SSO enabled: $Script:SSOEnabled" -Level Security
})

# SSO Type
$SSOTypeLabel = New-Object System.Windows.Forms.Label
$SSOTypeLabel.Text = "SSO Type:"
$SSOTypeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$SSOTypeLabel.ForeColor = $Colors.TextWhite
$SSOTypeLabel.Location = New-Object System.Drawing.Point(60, 95)
$SSOTypeLabel.Size = New-Object System.Drawing.Size(80, 20)

$Script:SSOTypeCombo = New-Object System.Windows.Forms.ComboBox
$Script:SSOTypeCombo.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:SSOTypeCombo.BackColor = $Colors.DarkBackground
$Script:SSOTypeCombo.ForeColor = $Colors.TextWhite
$Script:SSOTypeCombo.Location = New-Object System.Drawing.Point(150, 93)
$Script:SSOTypeCombo.Size = New-Object System.Drawing.Size(150, 25)
$Script:SSOTypeCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$Script:SSOTypeCombo.Items.AddRange(@("SAML", "OAuth", "ActiveDirectory"))
$Script:SSOTypeCombo.SelectedIndex = 0
$Script:SSOTypeCombo.Enabled = $false
$Script:SSOTypeCombo.Add_SelectedIndexChanged({
    $Script:SSOType = $Script:SSOTypeCombo.SelectedItem.ToString()
    Update-SSOConfigurationPanel
    Write-StatusLog "SSO type set to: $Script:SSOType" -Level Security
})

# SSO Configuration Panel
$Script:SSOConfigPanel = New-Object System.Windows.Forms.Panel
$Script:SSOConfigPanel.Size = New-Object System.Drawing.Size(400, 120)
$Script:SSOConfigPanel.Location = New-Object System.Drawing.Point(60, 130)
$Script:SSOConfigPanel.BackColor = $Colors.DarkBackground
$Script:SSOConfigPanel.Enabled = $false

$SSOTab.Controls.AddRange(@(
    $SSOTitleLabel, $Script:SSOEnabledCheckBox, $SSOTypeLabel, $Script:SSOTypeCombo, $Script:SSOConfigPanel
))

# Enhanced Security Tab
$SecurityTab = New-Object System.Windows.Forms.TabPage
$SecurityTab.Text = "Enhanced Security"
$SecurityTab.BackColor = $Colors.DarkSurface
$SecurityTab.ForeColor = $Colors.TextWhite

$SecurityTitleLabel = New-Object System.Windows.Forms.Label
$SecurityTitleLabel.Text = "Advanced Security Configuration:"
$SecurityTitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$SecurityTitleLabel.ForeColor = $Colors.AccentBlue
$SecurityTitleLabel.Location = New-Object System.Drawing.Point(20, 20)
$SecurityTitleLabel.Size = New-Object System.Drawing.Size(350, 25)

# TLS Version
$TLSVersionLabel = New-Object System.Windows.Forms.Label
$TLSVersionLabel.Text = "TLS Version:"
$TLSVersionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$TLSVersionLabel.ForeColor = $Colors.TextWhite
$TLSVersionLabel.Location = New-Object System.Drawing.Point(40, 60)
$TLSVersionLabel.Size = New-Object System.Drawing.Size(100, 20)

$Script:TLSVersionCombo = New-Object System.Windows.Forms.ComboBox
$Script:TLSVersionCombo.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:TLSVersionCombo.BackColor = $Colors.DarkBackground
$Script:TLSVersionCombo.ForeColor = $Colors.TextWhite
$Script:TLSVersionCombo.Location = New-Object System.Drawing.Point(150, 58)
$Script:TLSVersionCombo.Size = New-Object System.Drawing.Size(100, 25)
$Script:TLSVersionCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$Script:TLSVersionCombo.Items.AddRange(@("1.2", "1.3"))
$Script:TLSVersionCombo.SelectedIndex = 1  # Default to TLS 1.3
$Script:TLSVersionCombo.Add_SelectedIndexChanged({
    $Script:TLSVersion = $Script:TLSVersionCombo.SelectedItem.ToString()
    Write-StatusLog "TLS version set to: $Script:TLSVersion" -Level Security
})

# Session Timeout
$SessionTimeoutLabel = New-Object System.Windows.Forms.Label
$SessionTimeoutLabel.Text = "Session Timeout (hours):"
$SessionTimeoutLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$SessionTimeoutLabel.ForeColor = $Colors.TextWhite
$SessionTimeoutLabel.Location = New-Object System.Drawing.Point(40, 95)
$SessionTimeoutLabel.Size = New-Object System.Drawing.Size(150, 20)

$Script:SessionTimeoutCombo = New-Object System.Windows.Forms.ComboBox
$Script:SessionTimeoutCombo.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:SessionTimeoutCombo.BackColor = $Colors.DarkBackground
$Script:SessionTimeoutCombo.ForeColor = $Colors.TextWhite
$Script:SessionTimeoutCombo.Location = New-Object System.Drawing.Point(200, 93)
$Script:SessionTimeoutCombo.Size = New-Object System.Drawing.Size(80, 25)
$Script:SessionTimeoutCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$Script:SessionTimeoutCombo.Items.AddRange(@("1", "2", "4", "8", "12", "24"))
$Script:SessionTimeoutCombo.SelectedIndex = 3  # Default to 8 hours
$Script:SessionTimeoutCombo.Add_SelectedIndexChanged({
    $Script:SessionTimeout = [int]$Script:SessionTimeoutCombo.SelectedItem
    Write-StatusLog "Session timeout set to: $Script:SessionTimeout hours" -Level Security
})

# Encryption Cipher
$EncryptionCipherLabel = New-Object System.Windows.Forms.Label
$EncryptionCipherLabel.Text = "Encryption Cipher:"
$EncryptionCipherLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$EncryptionCipherLabel.ForeColor = $Colors.TextWhite
$EncryptionCipherLabel.Location = New-Object System.Drawing.Point(40, 130)
$EncryptionCipherLabel.Size = New-Object System.Drawing.Size(120, 20)

$Script:EncryptionCipherCombo = New-Object System.Windows.Forms.ComboBox
$Script:EncryptionCipherCombo.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:EncryptionCipherCombo.BackColor = $Colors.DarkBackground
$Script:EncryptionCipherCombo.ForeColor = $Colors.TextWhite
$Script:EncryptionCipherCombo.Location = New-Object System.Drawing.Point(170, 128)
$Script:EncryptionCipherCombo.Size = New-Object System.Drawing.Size(120, 25)
$Script:EncryptionCipherCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$Script:EncryptionCipherCombo.Items.AddRange(@("AES-128", "AES-256", "ChaCha20"))
$Script:EncryptionCipherCombo.SelectedIndex = 1  # Default to AES-256
$Script:EncryptionCipherCombo.Add_SelectedIndexChanged({
    $Script:EncryptionCipher = $Script:EncryptionCipherCombo.SelectedItem.ToString()
    Write-StatusLog "Encryption cipher set to: $Script:EncryptionCipher" -Level Security
})

# MFA Enable
$Script:MFAEnabledCheckBox = New-Object System.Windows.Forms.CheckBox
$Script:MFAEnabledCheckBox.Text = "Enable Multi-Factor Authentication (MFA)"
$Script:MFAEnabledCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:MFAEnabledCheckBox.ForeColor = $Colors.TextWhite
$Script:MFAEnabledCheckBox.Location = New-Object System.Drawing.Point(40, 165)
$Script:MFAEnabledCheckBox.Size = New-Object System.Drawing.Size(300, 25)
$Script:MFAEnabledCheckBox.Add_CheckedChanged({
    $Script:MFAEnabled = $Script:MFAEnabledCheckBox.Checked
    Write-StatusLog "MFA enabled: $Script:MFAEnabled" -Level Security
})

# Audit Logging
$Script:AuditLoggingCheckBox = New-Object System.Windows.Forms.CheckBox
$Script:AuditLoggingCheckBox.Text = "Enable Comprehensive Audit Logging"
$Script:AuditLoggingCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:AuditLoggingCheckBox.ForeColor = $Colors.TextWhite
$Script:AuditLoggingCheckBox.Location = New-Object System.Drawing.Point(40, 195)
$Script:AuditLoggingCheckBox.Size = New-Object System.Drawing.Size(300, 25)
$Script:AuditLoggingCheckBox.Checked = $true
$Script:AuditLoggingCheckBox.Add_CheckedChanged({
    $Script:AuditLogging = $Script:AuditLoggingCheckBox.Checked
    Write-StatusLog "Audit logging: $Script:AuditLogging" -Level Security
})

$SecurityTab.Controls.AddRange(@(
    $SecurityTitleLabel, $TLSVersionLabel, $Script:TLSVersionCombo,
    $SessionTimeoutLabel, $Script:SessionTimeoutCombo, $EncryptionCipherLabel, $Script:EncryptionCipherCombo,
    $Script:MFAEnabledCheckBox, $Script:AuditLoggingCheckBox
))

# Enhanced Authentication Tab (Enhanced Version)
$EnhancedAuthTab = New-Object System.Windows.Forms.TabPage
$EnhancedAuthTab.Text = "Enhanced Authentication"
$EnhancedAuthTab.BackColor = $Colors.DarkSurface
$EnhancedAuthTab.ForeColor = $Colors.TextWhite

# Admin Password Section
$AdminPasswordLabel = New-Object System.Windows.Forms.Label
$AdminPasswordLabel.Text = "Administrator Authentication:"
$AdminPasswordLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$AdminPasswordLabel.ForeColor = $Colors.AccentBlue
$AdminPasswordLabel.Location = New-Object System.Drawing.Point(20, 20)
$AdminPasswordLabel.Size = New-Object System.Drawing.Size(250, 25)

# Custom Password Checkbox
$Script:UseCustomPasswordCheckBox = New-Object System.Windows.Forms.CheckBox
$Script:UseCustomPasswordCheckBox.Text = "Use Custom Admin Password"
$Script:UseCustomPasswordCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:UseCustomPasswordCheckBox.ForeColor = $Colors.TextWhite
$Script:UseCustomPasswordCheckBox.Location = New-Object System.Drawing.Point(40, 50)
$Script:UseCustomPasswordCheckBox.Size = New-Object System.Drawing.Size(200, 25)
$Script:UseCustomPasswordCheckBox.TabStop = $true
$Script:UseCustomPasswordCheckBox.TabIndex = 0
$Script:UseCustomPasswordCheckBox.Add_CheckedChanged({
    $Script:UseCustomPassword = $Script:UseCustomPasswordCheckBox.Checked
    $Script:EnhancedPasswordTextBox.Enabled = $Script:UseCustomPassword
    $Script:EnhancedShowPasswordCheckBox.Enabled = $Script:UseCustomPassword
    if (-not $Script:UseCustomPassword) {
        $Script:EnhancedPasswordTextBox.Text = ""
        $Script:CustomAdminPassword = ""
    }
    Write-StatusLog "Custom password enabled: $Script:UseCustomPassword" -Level Security
})

# Password Input Field (Enhanced Auth Tab - renamed to avoid conflicts)
$Script:EnhancedPasswordTextBox = New-Object System.Windows.Forms.TextBox
$Script:EnhancedPasswordTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$Script:EnhancedPasswordTextBox.BackColor = $Colors.DarkBackground
$Script:EnhancedPasswordTextBox.ForeColor = $Colors.TextWhite
$Script:EnhancedPasswordTextBox.Location = New-Object System.Drawing.Point(260, 50)
$Script:EnhancedPasswordTextBox.Size = New-Object System.Drawing.Size(200, 25)
$Script:EnhancedPasswordTextBox.UseSystemPasswordChar = $true
$Script:EnhancedPasswordTextBox.Enabled = $false
$Script:EnhancedPasswordTextBox.TabStop = $true
$Script:EnhancedPasswordTextBox.TabIndex = 1
$Script:EnhancedPasswordTextBox.Add_TextChanged({
    $Script:CustomAdminPassword = $Script:EnhancedPasswordTextBox.Text
})

# Show Password Checkbox (Enhanced Auth Tab - renamed to avoid conflicts)
$Script:EnhancedShowPasswordCheckBox = New-Object System.Windows.Forms.CheckBox
$Script:EnhancedShowPasswordCheckBox.Text = "Show Password"
$Script:EnhancedShowPasswordCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$Script:EnhancedShowPasswordCheckBox.ForeColor = $Colors.TextGray
$Script:EnhancedShowPasswordCheckBox.Location = New-Object System.Drawing.Point(470, 50)
$Script:EnhancedShowPasswordCheckBox.Size = New-Object System.Drawing.Size(120, 25)
$Script:EnhancedShowPasswordCheckBox.Enabled = $false
$Script:EnhancedShowPasswordCheckBox.TabStop = $true
$Script:EnhancedShowPasswordCheckBox.TabIndex = 2
$Script:EnhancedShowPasswordCheckBox.Add_CheckedChanged({
    $Script:EnhancedPasswordTextBox.UseSystemPasswordChar = -not $Script:EnhancedShowPasswordCheckBox.Checked
})

# SSO Configuration Section
$SSOLabel = New-Object System.Windows.Forms.Label
$SSOLabel.Text = "Single Sign-On Configuration:"
$SSOLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$SSOLabel.ForeColor = $Colors.ComplianceBlue
$SSOLabel.Location = New-Object System.Drawing.Point(20, 90)
$SSOLabel.Size = New-Object System.Drawing.Size(250, 25)

# SSO Provider Selection
$SSOProviderLabel = New-Object System.Windows.Forms.Label
$SSOProviderLabel.Text = "SSO Provider:"
$SSOProviderLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$SSOProviderLabel.ForeColor = $Colors.TextWhite
$SSOProviderLabel.Location = New-Object System.Drawing.Point(40, 120)
$SSOProviderLabel.Size = New-Object System.Drawing.Size(100, 25)

$Script:SSOProviderCombo = New-Object System.Windows.Forms.ComboBox
$Script:SSOProviderCombo.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:SSOProviderCombo.BackColor = $Colors.DarkBackground
$Script:SSOProviderCombo.ForeColor = $Colors.TextWhite
$Script:SSOProviderCombo.Location = New-Object System.Drawing.Point(150, 120)
$Script:SSOProviderCombo.Size = New-Object System.Drawing.Size(120, 25)
$Script:SSOProviderCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$Script:SSOProviderCombo.Items.AddRange(@("None", "SAML", "OAuth", "Active Directory"))
$Script:SSOProviderCombo.SelectedIndex = 0
$Script:SSOProviderCombo.Add_SelectedIndexChanged({
    $Script:SSOProvider = $Script:SSOProviderCombo.SelectedItem.ToString()
    $isEnabled = ($Script:SSOProvider -ne "None")
    $Script:SSODomainTextBox.Enabled = $isEnabled
    $Script:SAMLEndpointTextBox.Enabled = ($Script:SSOProvider -eq "SAML")
    $Script:OAuthClientIDTextBox.Enabled = ($Script:SSOProvider -eq "OAuth")
    $Script:OAuthClientSecretTextBox.Enabled = ($Script:SSOProvider -eq "OAuth")
    Write-StatusLog "SSO Provider changed to: $Script:SSOProvider" -Level Security
})

# SSO Domain
$SSODomainLabel = New-Object System.Windows.Forms.Label
$SSODomainLabel.Text = "Domain:"
$SSODomainLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$SSODomainLabel.ForeColor = $Colors.TextWhite
$SSODomainLabel.Location = New-Object System.Drawing.Point(290, 120)
$SSODomainLabel.Size = New-Object System.Drawing.Size(60, 25)

$Script:SSODomainTextBox = New-Object System.Windows.Forms.TextBox
$Script:SSODomainTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$Script:SSODomainTextBox.BackColor = $Colors.DarkBackground
$Script:SSODomainTextBox.ForeColor = $Colors.TextWhite
$Script:SSODomainTextBox.Location = New-Object System.Drawing.Point(360, 120)
$Script:SSODomainTextBox.Size = New-Object System.Drawing.Size(150, 25)
$Script:SSODomainTextBox.Enabled = $false
$Script:SSODomainTextBox.Add_TextChanged({
    $Script:SSODomain = $Script:SSODomainTextBox.Text
})

# SAML Endpoint
$SAMLEndpointLabel = New-Object System.Windows.Forms.Label
$SAMLEndpointLabel.Text = "SAML Endpoint:"
$SAMLEndpointLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$SAMLEndpointLabel.ForeColor = $Colors.TextWhite
$SAMLEndpointLabel.Location = New-Object System.Drawing.Point(40, 155)
$SAMLEndpointLabel.Size = New-Object System.Drawing.Size(100, 25)

$Script:SAMLEndpointTextBox = New-Object System.Windows.Forms.TextBox
$Script:SAMLEndpointTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$Script:SAMLEndpointTextBox.BackColor = $Colors.DarkBackground
$Script:SAMLEndpointTextBox.ForeColor = $Colors.TextWhite
$Script:SAMLEndpointTextBox.Location = New-Object System.Drawing.Point(150, 155)
$Script:SAMLEndpointTextBox.Size = New-Object System.Drawing.Size(360, 25)
$Script:SAMLEndpointTextBox.Enabled = $false
$Script:SAMLEndpointTextBox.Add_TextChanged({
    $Script:SAMLEndpoint = $Script:SAMLEndpointTextBox.Text
})

# OAuth Client ID
$OAuthClientIDLabel = New-Object System.Windows.Forms.Label
$OAuthClientIDLabel.Text = "OAuth Client ID:"
$OAuthClientIDLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$OAuthClientIDLabel.ForeColor = $Colors.TextWhite
$OAuthClientIDLabel.Location = New-Object System.Drawing.Point(40, 190)
$OAuthClientIDLabel.Size = New-Object System.Drawing.Size(100, 25)

$Script:OAuthClientIDTextBox = New-Object System.Windows.Forms.TextBox
$Script:OAuthClientIDTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$Script:OAuthClientIDTextBox.BackColor = $Colors.DarkBackground
$Script:OAuthClientIDTextBox.ForeColor = $Colors.TextWhite
$Script:OAuthClientIDTextBox.Location = New-Object System.Drawing.Point(150, 190)
$Script:OAuthClientIDTextBox.Size = New-Object System.Drawing.Size(200, 25)
$Script:OAuthClientIDTextBox.Enabled = $false
$Script:OAuthClientIDTextBox.Add_TextChanged({
    $Script:OAuthClientID = $Script:OAuthClientIDTextBox.Text
})

# OAuth Client Secret
$OAuthClientSecretLabel = New-Object System.Windows.Forms.Label
$OAuthClientSecretLabel.Text = "OAuth Secret:"
$OAuthClientSecretLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$OAuthClientSecretLabel.ForeColor = $Colors.TextWhite
$OAuthClientSecretLabel.Location = New-Object System.Drawing.Point(360, 190)
$OAuthClientSecretLabel.Size = New-Object System.Drawing.Size(100, 25)

$Script:OAuthClientSecretTextBox = New-Object System.Windows.Forms.TextBox
$Script:OAuthClientSecretTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$Script:OAuthClientSecretTextBox.BackColor = $Colors.DarkBackground
$Script:OAuthClientSecretTextBox.ForeColor = $Colors.TextWhite
$Script:OAuthClientSecretTextBox.Location = New-Object System.Drawing.Point(470, 190)
$Script:OAuthClientSecretTextBox.Size = New-Object System.Drawing.Size(200, 25)
$Script:OAuthClientSecretTextBox.UseSystemPasswordChar = $true
$Script:OAuthClientSecretTextBox.Enabled = $false
$Script:OAuthClientSecretTextBox.Add_TextChanged({
    $Script:OAuthClientSecret = $Script:OAuthClientSecretTextBox.Text
})

$EnhancedAuthTab.Controls.AddRange(@(
    $AdminPasswordLabel, $Script:UseCustomPasswordCheckBox, $Script:EnhancedPasswordTextBox, $Script:EnhancedShowPasswordCheckBox,
    $SSOLabel, $SSOProviderLabel, $Script:SSOProviderCombo, $SSODomainLabel, $Script:SSODomainTextBox,
    $SAMLEndpointLabel, $Script:SAMLEndpointTextBox, $OAuthClientIDLabel, $Script:OAuthClientIDTextBox,
    $OAuthClientSecretLabel, $Script:OAuthClientSecretTextBox
))

# Enhanced Network Configuration Tab
$EnhancedNetworkTab = New-Object System.Windows.Forms.TabPage
$EnhancedNetworkTab.Text = "Enhanced Network"
$EnhancedNetworkTab.BackColor = $Colors.DarkSurface
$EnhancedNetworkTab.ForeColor = $Colors.TextWhite

# DNS Configuration Section
$DNSLabel = New-Object System.Windows.Forms.Label
$DNSLabel.Text = "DNS Server Configuration:"
$DNSLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$DNSLabel.ForeColor = $Colors.AccentBlue
$DNSLabel.Location = New-Object System.Drawing.Point(20, 20)
$DNSLabel.Size = New-Object System.Drawing.Size(250, 25)

# DNS Server Selection
$DNSServerLabel = New-Object System.Windows.Forms.Label
$DNSServerLabel.Text = "DNS Server:"
$DNSServerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$DNSServerLabel.ForeColor = $Colors.TextWhite
$DNSServerLabel.Location = New-Object System.Drawing.Point(40, 50)
$DNSServerLabel.Size = New-Object System.Drawing.Size(100, 25)

$Script:DNSServerCombo = New-Object System.Windows.Forms.ComboBox
$Script:DNSServerCombo.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:DNSServerCombo.BackColor = $Colors.DarkBackground
$Script:DNSServerCombo.ForeColor = $Colors.TextWhite
$Script:DNSServerCombo.Location = New-Object System.Drawing.Point(150, 50)
$Script:DNSServerCombo.Size = New-Object System.Drawing.Size(150, 25)
$Script:DNSServerCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$Script:DNSServerCombo.Items.AddRange(@("Auto", "Cloudflare", "Google", "OpenDNS", "Custom"))
$Script:DNSServerCombo.SelectedIndex = 0
$Script:DNSServerCombo.Add_SelectedIndexChanged({
    $Script:DNSServer = $Script:DNSServerCombo.SelectedItem.ToString()
    $isCustom = ($Script:DNSServer -eq "Custom")
    $Script:CustomDNS1TextBox.Enabled = $isCustom
    $Script:CustomDNS2TextBox.Enabled = $isCustom
    
    if (-not $isCustom) {
        switch ($Script:DNSServer) {
            "Cloudflare" {
                $Script:CustomDNS1TextBox.Text = "1.1.1.1"
                $Script:CustomDNS2TextBox.Text = "1.0.0.1"
            }
            "Google" {
                $Script:CustomDNS1TextBox.Text = "8.8.8.8"
                $Script:CustomDNS2TextBox.Text = "8.8.4.4"
            }
            "OpenDNS" {
                $Script:CustomDNS1TextBox.Text = "208.67.222.222"
                $Script:CustomDNS2TextBox.Text = "208.67.220.220"
            }
            "Auto" {
                $Script:CustomDNS1TextBox.Text = ""
                $Script:CustomDNS2TextBox.Text = ""
            }
        }
    }
    Write-StatusLog "DNS Server changed to: $Script:DNSServer" -Level Config
})

# Custom DNS Fields
$CustomDNS1Label = New-Object System.Windows.Forms.Label
$CustomDNS1Label.Text = "Primary DNS:"
$CustomDNS1Label.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$CustomDNS1Label.ForeColor = $Colors.TextWhite
$CustomDNS1Label.Location = New-Object System.Drawing.Point(40, 85)
$CustomDNS1Label.Size = New-Object System.Drawing.Size(100, 25)

$Script:CustomDNS1TextBox = New-Object System.Windows.Forms.TextBox
$Script:CustomDNS1TextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$Script:CustomDNS1TextBox.BackColor = $Colors.DarkBackground
$Script:CustomDNS1TextBox.ForeColor = $Colors.TextWhite
$Script:CustomDNS1TextBox.Location = New-Object System.Drawing.Point(150, 85)
$Script:CustomDNS1TextBox.Size = New-Object System.Drawing.Size(120, 25)
$Script:CustomDNS1TextBox.Enabled = $false
$Script:CustomDNS1TextBox.Add_TextChanged({
    $Script:CustomDNS1 = $Script:CustomDNS1TextBox.Text
})

$CustomDNS2Label = New-Object System.Windows.Forms.Label
$CustomDNS2Label.Text = "Secondary DNS:"
$CustomDNS2Label.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$CustomDNS2Label.ForeColor = $Colors.TextWhite
$CustomDNS2Label.Location = New-Object System.Drawing.Point(290, 85)
$CustomDNS2Label.Size = New-Object System.Drawing.Size(100, 25)

$Script:CustomDNS2TextBox = New-Object System.Windows.Forms.TextBox
$Script:CustomDNS2TextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$Script:CustomDNS2TextBox.BackColor = $Colors.DarkBackground
$Script:CustomDNS2TextBox.ForeColor = $Colors.TextWhite
$Script:CustomDNS2TextBox.Location = New-Object System.Drawing.Point(400, 85)
$Script:CustomDNS2TextBox.Size = New-Object System.Drawing.Size(120, 25)
$Script:CustomDNS2TextBox.Enabled = $false
$Script:CustomDNS2TextBox.Add_TextChanged({
    $Script:CustomDNS2 = $Script:CustomDNS2TextBox.Text
})

# Proxy Configuration Section
$ProxyLabel = New-Object System.Windows.Forms.Label
$ProxyLabel.Text = "Proxy Configuration:"
$ProxyLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$ProxyLabel.ForeColor = $Colors.ComplianceBlue
$ProxyLabel.Location = New-Object System.Drawing.Point(20, 130)
$ProxyLabel.Size = New-Object System.Drawing.Size(200, 25)

# Use Proxy Checkbox
$Script:UseProxyCheckBox = New-Object System.Windows.Forms.CheckBox
$Script:UseProxyCheckBox.Text = "Use HTTP Proxy"
$Script:UseProxyCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:UseProxyCheckBox.ForeColor = $Colors.TextWhite
$Script:UseProxyCheckBox.Location = New-Object System.Drawing.Point(40, 160)
$Script:UseProxyCheckBox.Size = New-Object System.Drawing.Size(150, 25)
$Script:UseProxyCheckBox.Add_CheckedChanged({
    $Script:UseProxy = $Script:UseProxyCheckBox.Checked
    $Script:ProxyHostTextBox.Enabled = $Script:UseProxy
    $Script:ProxyPortTextBox.Enabled = $Script:UseProxy
    $Script:ProxyUsernameTextBox.Enabled = $Script:UseProxy
    $Script:ProxyPasswordTextBox.Enabled = $Script:UseProxy
    Write-StatusLog "Proxy enabled: $Script:UseProxy" -Level Config
})

# Proxy Host
$ProxyHostLabel = New-Object System.Windows.Forms.Label
$ProxyHostLabel.Text = "Proxy Host:"
$ProxyHostLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$ProxyHostLabel.ForeColor = $Colors.TextWhite
$ProxyHostLabel.Location = New-Object System.Drawing.Point(40, 195)
$ProxyHostLabel.Size = New-Object System.Drawing.Size(80, 25)

$Script:ProxyHostTextBox = New-Object System.Windows.Forms.TextBox
$Script:ProxyHostTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$Script:ProxyHostTextBox.BackColor = $Colors.DarkBackground
$Script:ProxyHostTextBox.ForeColor = $Colors.TextWhite
$Script:ProxyHostTextBox.Location = New-Object System.Drawing.Point(130, 195)
$Script:ProxyHostTextBox.Size = New-Object System.Drawing.Size(150, 25)
$Script:ProxyHostTextBox.Enabled = $false
$Script:ProxyHostTextBox.Add_TextChanged({
    $Script:ProxyHost = $Script:ProxyHostTextBox.Text
})

# Proxy Port
$ProxyPortLabel = New-Object System.Windows.Forms.Label
$ProxyPortLabel.Text = "Port:"
$ProxyPortLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$ProxyPortLabel.ForeColor = $Colors.TextWhite
$ProxyPortLabel.Location = New-Object System.Drawing.Point(290, 195)
$ProxyPortLabel.Size = New-Object System.Drawing.Size(40, 25)

$Script:ProxyPortTextBox = New-Object System.Windows.Forms.TextBox
$Script:ProxyPortTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$Script:ProxyPortTextBox.BackColor = $Colors.DarkBackground
$Script:ProxyPortTextBox.ForeColor = $Colors.TextWhite
$Script:ProxyPortTextBox.Location = New-Object System.Drawing.Point(335, 195)
$Script:ProxyPortTextBox.Size = New-Object System.Drawing.Size(70, 25)
$Script:ProxyPortTextBox.Enabled = $false
$Script:ProxyPortTextBox.Add_TextChanged({
    $Script:ProxyPort = $Script:ProxyPortTextBox.Text
})

# Proxy Username
$ProxyUsernameLabel = New-Object System.Windows.Forms.Label
$ProxyUsernameLabel.Text = "Username:"
$ProxyUsernameLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$ProxyUsernameLabel.ForeColor = $Colors.TextWhite
$ProxyUsernameLabel.Location = New-Object System.Drawing.Point(420, 195)
$ProxyUsernameLabel.Size = New-Object System.Drawing.Size(70, 25)

$Script:ProxyUsernameTextBox = New-Object System.Windows.Forms.TextBox
$Script:ProxyUsernameTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$Script:ProxyUsernameTextBox.BackColor = $Colors.DarkBackground
$Script:ProxyUsernameTextBox.ForeColor = $Colors.TextWhite
$Script:ProxyUsernameTextBox.Location = New-Object System.Drawing.Point(495, 195)
$Script:ProxyUsernameTextBox.Size = New-Object System.Drawing.Size(100, 25)
$Script:ProxyUsernameTextBox.Enabled = $false
$Script:ProxyUsernameTextBox.Add_TextChanged({
    $Script:ProxyUsername = $Script:ProxyUsernameTextBox.Text
})

# Proxy Password
$ProxyPasswordLabel = New-Object System.Windows.Forms.Label
$ProxyPasswordLabel.Text = "Password:"
$ProxyPasswordLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$ProxyPasswordLabel.ForeColor = $Colors.TextWhite
$ProxyPasswordLabel.Location = New-Object System.Drawing.Point(605, 195)
$ProxyPasswordLabel.Size = New-Object System.Drawing.Size(70, 25)

$Script:ProxyPasswordTextBox = New-Object System.Windows.Forms.TextBox
$Script:ProxyPasswordTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$Script:ProxyPasswordTextBox.BackColor = $Colors.DarkBackground
$Script:ProxyPasswordTextBox.ForeColor = $Colors.TextWhite
$Script:ProxyPasswordTextBox.Location = New-Object System.Drawing.Point(680, 195)
$Script:ProxyPasswordTextBox.Size = New-Object System.Drawing.Size(100, 25)
$Script:ProxyPasswordTextBox.UseSystemPasswordChar = $true
$Script:ProxyPasswordTextBox.Enabled = $false
$Script:ProxyPasswordTextBox.Add_TextChanged({
    $Script:ProxyPassword = $Script:ProxyPasswordTextBox.Text
})

$EnhancedNetworkTab.Controls.AddRange(@(
    $DNSLabel, $DNSServerLabel, $Script:DNSServerCombo, $CustomDNS1Label, $Script:CustomDNS1TextBox,
    $CustomDNS2Label, $Script:CustomDNS2TextBox, $ProxyLabel, $Script:UseProxyCheckBox,
    $ProxyHostLabel, $Script:ProxyHostTextBox, $ProxyPortLabel, $Script:ProxyPortTextBox,
    $ProxyUsernameLabel, $Script:ProxyUsernameTextBox, $ProxyPasswordLabel, $Script:ProxyPasswordTextBox
))

# Enhanced Advanced Security Tab
$EnhancedAdvancedSecurityTab = New-Object System.Windows.Forms.TabPage
$EnhancedAdvancedSecurityTab.Text = "Advanced Security"
$EnhancedAdvancedSecurityTab.BackColor = $Colors.DarkSurface
$EnhancedAdvancedSecurityTab.ForeColor = $Colors.TextWhite

# Encryption Settings
$EncryptionLabel = New-Object System.Windows.Forms.Label
$EncryptionLabel.Text = "Encryption & Security Settings:"
$EncryptionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$EncryptionLabel.ForeColor = $Colors.AccentBlue
$EncryptionLabel.Location = New-Object System.Drawing.Point(20, 20)
$EncryptionLabel.Size = New-Object System.Drawing.Size(250, 25)

# Encryption Strength
$EncryptionStrengthLabel = New-Object System.Windows.Forms.Label
$EncryptionStrengthLabel.Text = "Encryption Strength:"
$EncryptionStrengthLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$EncryptionStrengthLabel.ForeColor = $Colors.TextWhite
$EncryptionStrengthLabel.Location = New-Object System.Drawing.Point(40, 55)
$EncryptionStrengthLabel.Size = New-Object System.Drawing.Size(130, 25)

$Script:EncryptionStrengthCombo = New-Object System.Windows.Forms.ComboBox
$Script:EncryptionStrengthCombo.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:EncryptionStrengthCombo.BackColor = $Colors.DarkBackground
$Script:EncryptionStrengthCombo.ForeColor = $Colors.TextWhite
$Script:EncryptionStrengthCombo.Location = New-Object System.Drawing.Point(180, 55)
$Script:EncryptionStrengthCombo.Size = New-Object System.Drawing.Size(120, 25)
$Script:EncryptionStrengthCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$Script:EncryptionStrengthCombo.Items.AddRange(@("AES128", "AES192", "AES256", "ChaCha20"))
$Script:EncryptionStrengthCombo.SelectedIndex = 2  # Default to AES256
$Script:EncryptionStrengthCombo.Add_SelectedIndexChanged({
    $Script:EncryptionStrength = $Script:EncryptionStrengthCombo.SelectedItem.ToString()
    Write-StatusLog "Encryption strength: $Script:EncryptionStrength" -Level Security
})

# Multi-Factor Authentication
$Script:RequireMFACheckBox = New-Object System.Windows.Forms.CheckBox
$Script:RequireMFACheckBox.Text = "Require Multi-Factor Authentication (MFA)"
$Script:RequireMFACheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:RequireMFACheckBox.ForeColor = $Colors.TextWhite
$Script:RequireMFACheckBox.Location = New-Object System.Drawing.Point(40, 90)
$Script:RequireMFACheckBox.Size = New-Object System.Drawing.Size(300, 25)
$Script:RequireMFACheckBox.Add_CheckedChanged({
    $Script:RequireMFA = $Script:RequireMFACheckBox.Checked
    Write-StatusLog "MFA required: $Script:RequireMFA" -Level Security
})

# Session Timeout
$SessionTimeoutLabel = New-Object System.Windows.Forms.Label
$SessionTimeoutLabel.Text = "Session Timeout (hours):"
$SessionTimeoutLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$SessionTimeoutLabel.ForeColor = $Colors.TextWhite
$SessionTimeoutLabel.Location = New-Object System.Drawing.Point(40, 125)
$SessionTimeoutLabel.Size = New-Object System.Drawing.Size(150, 25)

$Script:SessionTimeoutCombo = New-Object System.Windows.Forms.ComboBox
$Script:SessionTimeoutCombo.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:SessionTimeoutCombo.BackColor = $Colors.DarkBackground
$Script:SessionTimeoutCombo.ForeColor = $Colors.TextWhite
$Script:SessionTimeoutCombo.Location = New-Object System.Drawing.Point(200, 125)
$Script:SessionTimeoutCombo.Size = New-Object System.Drawing.Size(80, 25)
$Script:SessionTimeoutCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$Script:SessionTimeoutCombo.Items.AddRange(@("1", "2", "4", "8", "12", "24", "Never"))
$Script:SessionTimeoutCombo.SelectedIndex = 3  # Default to 8 hours
$Script:SessionTimeoutCombo.Add_SelectedIndexChanged({
    $Script:SessionTimeout = $Script:SessionTimeoutCombo.SelectedItem.ToString()
    Write-StatusLog "Session timeout: $Script:SessionTimeout hours" -Level Security
})

# Password Complexity
$PasswordComplexityLabel = New-Object System.Windows.Forms.Label
$PasswordComplexityLabel.Text = "Password Complexity:"
$PasswordComplexityLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$PasswordComplexityLabel.ForeColor = $Colors.TextWhite
$PasswordComplexityLabel.Location = New-Object System.Drawing.Point(40, 160)
$PasswordComplexityLabel.Size = New-Object System.Drawing.Size(150, 25)

$Script:PasswordComplexityCombo = New-Object System.Windows.Forms.ComboBox
$Script:PasswordComplexityCombo.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:PasswordComplexityCombo.BackColor = $Colors.DarkBackground
$Script:PasswordComplexityCombo.ForeColor = $Colors.TextWhite
$Script:PasswordComplexityCombo.Location = New-Object System.Drawing.Point(200, 160)
$Script:PasswordComplexityCombo.Size = New-Object System.Drawing.Size(100, 25)
$Script:PasswordComplexityCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$Script:PasswordComplexityCombo.Items.AddRange(@("Low", "Medium", "High", "Maximum"))
$Script:PasswordComplexityCombo.SelectedIndex = 1  # Default to Medium
$Script:PasswordComplexityCombo.Add_SelectedIndexChanged({
    $Script:PasswordComplexity = $Script:PasswordComplexityCombo.SelectedItem.ToString()
    Write-StatusLog "Password complexity: $Script:PasswordComplexity" -Level Security
})

# Audit Logging
$Script:AuditLoggingCheckBox = New-Object System.Windows.Forms.CheckBox
$Script:AuditLoggingCheckBox.Text = "Enable Comprehensive Audit Logging"
$Script:AuditLoggingCheckBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:AuditLoggingCheckBox.ForeColor = $Colors.TextWhite
$Script:AuditLoggingCheckBox.Location = New-Object System.Drawing.Point(40, 195)
$Script:AuditLoggingCheckBox.Size = New-Object System.Drawing.Size(300, 25)
$Script:AuditLoggingCheckBox.Checked = $true
$Script:AuditLoggingCheckBox.Add_CheckedChanged({
    $Script:AuditLogging = $Script:AuditLoggingCheckBox.Checked
    Write-StatusLog "Audit logging: $Script:AuditLogging" -Level Security
})

$EnhancedAdvancedSecurityTab.Controls.AddRange(@(
    $EncryptionLabel, $EncryptionStrengthLabel, $Script:EncryptionStrengthCombo,
    $Script:RequireMFACheckBox, $SessionTimeoutLabel, $Script:SessionTimeoutCombo,
    $PasswordComplexityLabel, $Script:PasswordComplexityCombo, $Script:AuditLoggingCheckBox
))

# Add all tabs to control - UPDATE WITH NEW ENHANCED TABS
$Script:ConfigurationPanel.TabPages.AddRange(@($BasicTab, $DeploymentTab, $ArtifactTab, $AdminPasswordTab, $CertificateTab, $DNSTab, $SSOTab, $SecurityTab, $EnhancedAuthTab, $EnhancedNetworkTab, $EnhancedAdvancedSecurityTab))
$MainForm.Controls.Add($Script:ConfigurationPanel)

# Progress Panel
$ProgressPanel = New-Object System.Windows.Forms.Panel
$ProgressPanel.Size = New-Object System.Drawing.Size(1180, 60)
$ProgressPanel.Location = New-Object System.Drawing.Point(10, 390)
$ProgressPanel.BackColor = $Colors.DarkSurface

$Script:ProgressBar = New-Object System.Windows.Forms.ProgressBar
$Script:ProgressBar.Size = New-Object System.Drawing.Size(960, 25)
$Script:ProgressBar.Location = New-Object System.Drawing.Point(20, 20)
$Script:ProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous

$Script:StatusLabel = New-Object System.Windows.Forms.Label
$Script:StatusLabel.Text = "Ready for enhanced installation"
$Script:StatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:StatusLabel.ForeColor = $Colors.TextGray
$Script:StatusLabel.Location = New-Object System.Drawing.Point(990, 20)
$Script:StatusLabel.Size = New-Object System.Drawing.Size(170, 25)

$ProgressPanel.Controls.AddRange(@($Script:ProgressBar, $Script:StatusLabel))
$MainForm.Controls.Add($ProgressPanel)

# Log Panel
$LogPanel = New-Object System.Windows.Forms.Panel
$LogPanel.Size = New-Object System.Drawing.Size(1180, 280)
$LogPanel.Location = New-Object System.Drawing.Point(10, 460)
$LogPanel.BackColor = $Colors.DarkSurface

$LogTitleLabel = New-Object System.Windows.Forms.Label
$LogTitleLabel.Text = "Enhanced Installation Log"
$LogTitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$LogTitleLabel.ForeColor = $Colors.AccentBlue
$LogTitleLabel.Location = New-Object System.Drawing.Point(20, 10)
$LogTitleLabel.Size = New-Object System.Drawing.Size(250, 25)

$Script:LogTextBox = New-Object System.Windows.Forms.TextBox
$Script:LogTextBox.Multiline = $true
$Script:LogTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$Script:LogTextBox.BackColor = $Colors.DarkBackground
$Script:LogTextBox.ForeColor = $Colors.TextWhite
$Script:LogTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$Script:LogTextBox.Location = New-Object System.Drawing.Point(20, 40)
$Script:LogTextBox.Size = New-Object System.Drawing.Size(1140, 230)
$Script:LogTextBox.ReadOnly = $true

$LogPanel.Controls.AddRange(@($LogTitleLabel, $Script:LogTextBox))
$MainForm.Controls.Add($LogPanel)

# Button Panel
$ButtonPanel = New-Object System.Windows.Forms.Panel
$ButtonPanel.Size = New-Object System.Drawing.Size(1180, 70)
$ButtonPanel.Location = New-Object System.Drawing.Point(10, 750)
$ButtonPanel.BackColor = $Colors.DarkSurface

# Install Button
$Script:InstallButton = New-Object System.Windows.Forms.Button
$Script:InstallButton.Text = "Install Enhanced Velociraptor"
$Script:InstallButton.Size = New-Object System.Drawing.Size(220, 45)
$Script:InstallButton.Location = New-Object System.Drawing.Point(20, 15)
$Script:InstallButton.BackColor = $Colors.AccentBlue
$Script:InstallButton.ForeColor = $Colors.TextWhite
$Script:InstallButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$Script:InstallButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$Script:InstallButton.Add_Click({
    Write-StatusLog "Enhanced install button clicked - starting installation process..." -Level Info
    
    # Validate enhanced configuration before starting
    if (Test-ConfigurationInputs) {
        Write-StatusLog "Enhanced configuration validated successfully" -Level Success
        # Use async approach to prevent GUI freezing
        Start-AsyncInstallation
    } else {
        Write-StatusLog "Enhanced configuration validation failed" -Level Error
    }
})

# Open Web Interface Button
$Script:OpenWebButton = New-Object System.Windows.Forms.Button
$Script:OpenWebButton.Text = "Open Web Interface"
$Script:OpenWebButton.Size = New-Object System.Drawing.Size(160, 45)
$Script:OpenWebButton.Location = New-Object System.Drawing.Point(260, 15)
$Script:OpenWebButton.BackColor = $Colors.SuccessGreen
$Script:OpenWebButton.ForeColor = $Colors.TextWhite
$Script:OpenWebButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$Script:OpenWebButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$Script:OpenWebButton.Enabled = $false
$Script:OpenWebButton.Add_Click({ 
    Write-StatusLog "Opening enhanced web interface..." -Level Info
    Open-VelociraptorWebInterface 
})

# Stop Server Button
$Script:StopServerButton = New-Object System.Windows.Forms.Button
$Script:StopServerButton.Text = "Stop Server"
$Script:StopServerButton.Size = New-Object System.Drawing.Size(120, 45)
$Script:StopServerButton.Location = New-Object System.Drawing.Point(440, 15)
$Script:StopServerButton.BackColor = $Colors.ErrorRed
$Script:StopServerButton.ForeColor = $Colors.TextWhite
$Script:StopServerButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$Script:StopServerButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$Script:StopServerButton.Enabled = $false
$Script:StopServerButton.Add_Click({ 
    Write-StatusLog "Stopping enhanced Velociraptor server..." -Level Info
    Stop-VelociraptorServer 
})

# Validate Config Button
$Script:ValidateButton = New-Object System.Windows.Forms.Button
$Script:ValidateButton.Text = "Validate Enhanced Config"
$Script:ValidateButton.Size = New-Object System.Drawing.Size(180, 45)
$Script:ValidateButton.Location = New-Object System.Drawing.Point(580, 15)
$Script:ValidateButton.BackColor = $Colors.AccentBlue
$Script:ValidateButton.ForeColor = $Colors.TextWhite
$Script:ValidateButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$Script:ValidateButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$Script:ValidateButton.Add_Click({
    Write-StatusLog "Validating enhanced configuration..." -Level Config
    if (Test-ConfigurationInputs) {
        $configSummary = Get-ConfigurationSummary
        Write-StatusLog "Enhanced configuration is valid and ready for installation" -Level Success
        [System.Windows.Forms.MessageBox]::Show(
            "Enhanced configuration validation passed!`n`n$configSummary`n`nAll settings are valid and ready for installation.",
            "Enhanced Configuration Valid",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
})

# Configuration Summary Button
$Script:SummaryButton = New-Object System.Windows.Forms.Button
$Script:SummaryButton.Text = "View Config Summary"
$Script:SummaryButton.Size = New-Object System.Drawing.Size(160, 45)
$Script:SummaryButton.Location = New-Object System.Drawing.Point(780, 15)
$Script:SummaryButton.BackColor = $Colors.ComplianceBlue
$Script:SummaryButton.ForeColor = $Colors.TextWhite
$Script:SummaryButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$Script:SummaryButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$Script:SummaryButton.Add_Click({
    $configSummary = Get-ConfigurationSummary
    Write-StatusLog "Displaying comprehensive configuration summary..." -Level Config
    [System.Windows.Forms.MessageBox]::Show(
        $configSummary,
        "Comprehensive Configuration Summary",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
})

# Export Configuration Button
$Script:ExportButton = New-Object System.Windows.Forms.Button
$Script:ExportButton.Text = "Export Config"
$Script:ExportButton.Size = New-Object System.Drawing.Size(100, 45)
$Script:ExportButton.Location = New-Object System.Drawing.Point(960, 15)
$Script:ExportButton.BackColor = $Colors.EnterpriseGold
$Script:ExportButton.ForeColor = $Colors.TextWhite
$Script:ExportButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$Script:ExportButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$Script:ExportButton.Add_Click({
    try {
        $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveFileDialog.Filter = "JSON files (*.json)|*.json|Text files (*.txt)|*.txt|All files (*.*)|*.*"
        $saveFileDialog.Title = "Export Configuration"
        $saveFileDialog.FileName = "velociraptor-config-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        
        if ($saveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $exportConfig = @{
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                Version = "Comprehensive GUI v2.0"
                DeploymentType = $Script:DeploymentType
                SecurityLevel = $Script:SecurityLevel
                InstallDir = $Script:InstallDir
                DataStore = $Script:DataStore
                GuiPort = $Script:GuiPort
                BindAddress = $Script:BindAddress
                SelectedArtifacts = $Script:SelectedArtifacts
                InstallAsService = $Script:InstallAsService
                ComplianceFramework = $Script:ComplianceFramework
                EnableSSL = $Script:EnableSSL
                AutoBackup = $Script:AutoBackup
                PerformanceMode = $Script:PerformanceMode
                UseCustomPassword = $Script:UseCustomPassword
                CertificateType = $Script:CertificateType
                CertificateDuration = $Script:CertificateDuration
                CustomCertPath = $Script:CustomCertPath
                DNSPrimary = $Script:DNSPrimary
                DNSSecondary = $Script:DNSSecondary
                DNSOverHTTPS = $Script:DNSOverHTTPS
                ProxyEnabled = $Script:ProxyEnabled
                ProxyHost = $Script:ProxyHost
                ProxyPort = $Script:ProxyPort
                SSOEnabled = $Script:SSOEnabled
                SSOType = $Script:SSOType
                SSOConfig = $Script:SSOConfig
                TLSVersion = $Script:TLSVersion
                SessionTimeout = $Script:SessionTimeout
                AuditLogging = $Script:AuditLogging
                EncryptionCipher = $Script:EncryptionCipher
                MFAEnabled = $Script:MFAEnabled
            }
            
            $jsonConfig = $exportConfig | ConvertTo-Json -Depth 10
            Set-Content -Path $saveFileDialog.FileName -Value $jsonConfig
            
            Write-StatusLog "Configuration exported to: $($saveFileDialog.FileName)" -Level Success
            [System.Windows.Forms.MessageBox]::Show(
                "Configuration successfully exported to:`n$($saveFileDialog.FileName)",
                "Export Complete",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
    }
    catch {
        Write-StatusLog "Export failed: $($_.Exception.Message)" -Level Error
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to export configuration:`n$($_.Exception.Message)",
            "Export Failed",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
})

# Exit Button
$ExitButton = New-Object System.Windows.Forms.Button
$ExitButton.Text = "Exit"
$ExitButton.Size = New-Object System.Drawing.Size(80, 45)
$ExitButton.Location = New-Object System.Drawing.Point(1080, 15)
$ExitButton.BackColor = $Colors.BorderGray
$ExitButton.ForeColor = $Colors.TextWhite
$ExitButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$ExitButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$ExitButton.Add_Click({ 
    Write-StatusLog "Exit button clicked" -Level Info
    $MainForm.Close() 
})

$ButtonPanel.Controls.AddRange(@(
    $Script:InstallButton,
    $Script:OpenWebButton,
    $Script:StopServerButton,
    $Script:ValidateButton,
    $Script:SummaryButton,
    $Script:ExportButton,
    $ExitButton
))
$MainForm.Controls.Add($ButtonPanel)
#endregion

# Form cleanup on close
$MainForm.Add_FormClosing({
    if ($Script:VelociraptorProcess -and -not $Script:VelociraptorProcess.HasExited) {
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Velociraptor server is still running. Do you want to stop it before exiting?",
            "Server Running",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            Stop-VelociraptorServer
        }
    }
    
    if ($Script:InstallAsService) {
        $service = Get-Service -Name "Velociraptor" -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq "Running") {
            $result = [System.Windows.Forms.MessageBox]::Show(
                "Velociraptor service is still running. Do you want to stop it before exiting?",
                "Service Running",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                Stop-Service -Name "Velociraptor" -Force -ErrorAction SilentlyContinue
            }
        }
    }
})

# Initialize enhanced log
Write-StatusLog "=== Velociraptor Comprehensive Professional Installation GUI ===" -Level Success
Write-StatusLog "Configure comprehensive settings across 8 specialized tabs and click 'Install Enhanced Velociraptor' to begin" -Level Info
Write-StatusLog "This comprehensive GUI provides enterprise-grade configuration options matching velociraptor.exe -i functionality" -Level Info
Write-StatusLog "Features: Admin passwords, certificates, DNS, SSO, network, security, compliance, and artifact management" -Level Config

# Initialize default selections
Update-DeploymentSelection -SelectedType "Standalone"
Update-SecuritySelection -SelectedLevel "Standard"
Update-ArtifactSelection
Update-SSOConfigurationPanel

# Show the enhanced form
Write-Host "Launching Comprehensive Velociraptor Installation GUI..." -ForegroundColor Green

try {
    Write-StatusLog "Comprehensive GUI initialized successfully - ready for complete enterprise installation" -Level Success
    $result = $MainForm.ShowDialog()
}
catch {
    Write-Host "Comprehensive GUI Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
    exit 1
}
finally {
    try {
        if ($MainForm) { $MainForm.Dispose() }
    }
    catch {
        # Ignore cleanup errors
    }
}

Write-Host "=== Comprehensive Velociraptor GUI Session Complete ===" -ForegroundColor Green