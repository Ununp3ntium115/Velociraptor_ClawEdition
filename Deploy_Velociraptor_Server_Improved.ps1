<#
.SYNOPSIS
    Enhanced Velociraptor Server deployment script with robust error handling and modern PowerShell practices.

.DESCRIPTION
    Deploys a complete Velociraptor server environment with:
    • Automatic binary download and verification
    • Interactive configuration with validation
    • SSO integration support (Google, Azure, GitHub, Okta, OIDC)
    • Windows service installation and management
    • Client MSI package generation
    • Comprehensive logging and error handling

.PARAMETER InstallDir
    Installation directory for Velociraptor. Default: C:\tools

.PARAMETER DataStore
    Data storage directory. Default: C:\VelociraptorServerData

.PARAMETER FrontendPort
    Port for agent connections. Default: 8000

.PARAMETER GuiPort
    Port for web GUI. Default: 8889

.PARAMETER PublicHostname
    Public hostname/FQDN for the server. Default: computer name

.PARAMETER SkipMSI
    Skip MSI package creation

.PARAMETER Force
    Skip confirmation prompts

.EXAMPLE
    .\Deploy_Velociraptor_Server_Improved.ps1
    
.EXAMPLE
    .\Deploy_Velociraptor_Server_Improved.ps1 -PublicHostname "velo.company.com" -FrontendPort 8443

.NOTES
    Requires Administrator privileges and PowerShell 5.1+
#>

[CmdletBinding()]
param(
    [ValidateScript({Test-Path (Split-Path $_ -Parent) -PathType Container})]
    [string]$InstallDir = 'C:\tools',
    
    [ValidateScript({Test-Path (Split-Path $_ -Parent) -PathType Container})]
    [string]$DataStore = 'C:\VelociraptorServerData',
    
    [ValidateRange(1024, 65535)]
    [int]$FrontendPort = 8000,
    
    [ValidateRange(1024, 65535)]
    [int]$GuiPort = 8889,
    
    [string]$PublicHostname,
    
    [switch]$SkipMSI,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

############  Configuration  #############################################
$script:Config = @{
    LogDir = Join-Path $env:ProgramData 'VelociraptorDeploy'
    LogFile = 'server_deploy.log'
    GitHubAPI = 'https://api.github.com/repos/Velocidex/velociraptor/releases/latest'
    UserAgent = 'VelociraptorServerDeployer/2.0'
    ServiceName = 'Velociraptor'
    RequiredPSVersion = [Version]'5.1'
}

############  Logging Functions  #########################################
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    try {
        if (-not (Test-Path $script:Config.LogDir)) {
            New-Item -ItemType Directory -Path $script:Config.LogDir -Force | Out-Null
        }
        
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logEntry = "{0}`t[{1}]`t{2}" -f $timestamp, $Level.ToUpper(), $Message
        
        $logPath = Join-Path $script:Config.LogDir $script:Config.LogFile
        $logEntry | Out-File -FilePath $logPath -Append -Encoding UTF8
        
        $color = switch ($Level) {
            'Success' { 'Green' }
            'Warning' { 'Yellow' }
            'Error' { 'Red' }
            default { 'White' }
        }
        
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
    catch {
        Write-Warning "Failed to write to log: $_"
        Write-Host "[$Level] $Message"
    }
}

############  Validation Functions  #####################################
function Test-Prerequisites {
    Write-Log "Validating system prerequisites..."
    
    # Check Administrator privileges
    $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        throw "Administrator privileges required. Please run as Administrator."
    }
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion -lt $script:Config.RequiredPSVersion) {
        throw "PowerShell $($script:Config.RequiredPSVersion) or higher required. Current: $($PSVersionTable.PSVersion)"
    }
    
    # Check network connectivity
    try {
        $null = Invoke-RestMethod -Uri 'https://api.github.com' -Method Head -TimeoutSec 10 -UseBasicParsing
        Write-Log "Network connectivity verified" -Level 'Success'
    }
    catch {
        throw "Internet connectivity required for downloading Velociraptor"
    }
    
    # Check port availability
    foreach ($port in @($FrontendPort, $GuiPort)) {
        if (-not (Test-PortAvailable -Port $port)) {
            throw "Port $port is already in use. Please choose different ports or stop conflicting services."
        }
    }
    
    Write-Log "All prerequisites validated" -Level 'Success'
}

function Test-PortAvailable {
    param([int]$Port)
    
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
        $listener.Start()
        $listener.Stop()
        return $true
    }
    catch {
        return $false
    }
}

############  Core Functions  ############################################
function Get-LatestVelociraptorRelease {
    Write-Log "Fetching latest Velociraptor release information..."
    
    try {
        $headers = @{
            'User-Agent' = $script:Config.UserAgent
            'Accept' = 'application/vnd.github.v3+json'
        }
        
        $release = Invoke-RestMethod -Uri $script:Config.GitHubAPI -Headers $headers -TimeoutSec 30
        
        $asset = $release.assets | Where-Object { 
            $_.name -like '*windows-amd64.exe' -and $_.name -notlike '*msi*' 
        } | Select-Object -First 1
        
        if (-not $asset) {
            throw "No Windows AMD64 executable found in latest release"
        }
        
        Write-Log "Found version: $($release.tag_name)" -Level 'Success'
        return @{
            Version = $release.tag_name
            DownloadUrl = $asset.browser_download_url
            Size = $asset.size
        }
    }
    catch {
        Write-Log "Failed to fetch release information: $($_.Exception.Message)" -Level 'Error'
        throw
    }
}

function Install-VelociraptorBinary {
    param($ReleaseInfo, [string]$DestinationPath)
    
    Write-Log "Downloading Velociraptor $($ReleaseInfo.Version)..."
    
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        $tempFile = "$DestinationPath.download"
        $headers = @{ 'User-Agent' = $script:Config.UserAgent }
        
        Invoke-WebRequest -Uri $ReleaseInfo.DownloadUrl -OutFile $tempFile -UseBasicParsing -Headers $headers -TimeoutSec 300
        
        # Verify download
        $downloadedFile = Get-Item $tempFile
        if ($downloadedFile.Length -eq 0) {
            throw "Downloaded file is empty"
        }
        
        if ($downloadedFile.Length -ne $ReleaseInfo.Size) {
            Write-Log "Warning: Downloaded file size doesn't match expected size" -Level 'Warning'
        }
        
        Move-Item $tempFile $DestinationPath -Force
        Write-Log "Binary downloaded successfully ($([math]::Round($downloadedFile.Length / 1MB, 2)) MB)" -Level 'Success'
        
        # Test executable
        $version = & $DestinationPath version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Executable verified: $($version -split "`n" | Select-Object -First 1)"
        }
    }
    catch {
        if (Test-Path "$DestinationPath.download") {
            Remove-Item "$DestinationPath.download" -Force -ErrorAction SilentlyContinue
        }
        Write-Log "Failed to download Velociraptor: $($_.Exception.Message)" -Level 'Error'
        throw
    }
}

function New-ServerConfiguration {
    param([string]$ExecutablePath, [string]$ConfigPath)
    
    Write-Log "Generating server configuration..."
    
    try {
        # Generate base configuration
        $configOutput = & $ExecutablePath config generate 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Configuration generation failed: $configOutput"
        }
        
        $configOutput | Out-File $ConfigPath -Encoding UTF8
        
        # Verify configuration
        if (-not (Test-Path $ConfigPath) -or (Get-Item $ConfigPath).Length -eq 0) {
            throw "Configuration file was not created properly"
        }
        
        Write-Log "Base configuration generated successfully" -Level 'Success'
        return $ConfigPath
    }
    catch {
        Write-Log "Failed to generate configuration: $($_.Exception.Message)" -Level 'Error'
        throw
    }
}

function Update-ServerConfiguration {
    param([string]$ConfigPath)
    
    Write-Log "Customizing server configuration..."
    
    try {
        [string[]]$yaml = Get-Content $ConfigPath
        
        # Set public hostname
        $hostname = if ($PublicHostname) { $PublicHostname } else { $env:COMPUTERNAME }
        $yaml = $yaml -replace '^public_hostname:.*', "public_hostname: '$hostname'"
        Write-Log "Public hostname set to: $hostname"
        
        # Configure ports
        $yaml = Update-YamlSection -Yaml $yaml -Section 'Frontend' -Property 'bind_port' -Value $FrontendPort
        $yaml = Update-YamlSection -Yaml $yaml -Section 'GUI' -Property 'bind_port' -Value $GuiPort
        Write-Log "Ports configured - Frontend: $FrontendPort, GUI: $GuiPort"
        
        # Configure datastore
        $yaml = Update-DatastoreConfiguration -Yaml $yaml -DataStorePath $DataStore
        Write-Log "Datastore configured: $DataStore"
        
        # Handle SSO configuration
        $ssoConfig = Get-SSOConfiguration
        if ($ssoConfig) {
            $yaml = Add-SSOConfiguration -Yaml $yaml -SSOConfig $ssoConfig
            Write-Log "SSO configuration added" -Level 'Success'
        }
        
        # Save updated configuration
        $yaml | Out-File $ConfigPath -Encoding UTF8
        
        # Validate configuration
        $configTest = & (Join-Path (Split-Path $ConfigPath) 'velociraptor.exe') config show --config $ConfigPath 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Configuration validation failed: $configTest"
        }
        
        Write-Log "Configuration updated and validated successfully" -Level 'Success'
    }
    catch {
        Write-Log "Failed to update configuration: $($_.Exception.Message)" -Level 'Error'
        throw
    }
}

function Update-YamlSection {
    param([string[]]$Yaml, [string]$Section, [string]$Property, $Value)
    
    for ($i = 0; $i -lt $Yaml.Count; $i++) {
        if ($Yaml[$i] -match "^${Section}:") {
            for ($j = $i + 1; $j -lt $Yaml.Count; $j++) {
                if ($Yaml[$j] -match "^\s*${Property}:") {
                    $Yaml[$j] = $Yaml[$j] -replace "^\s*${Property}:.*", "  ${Property}: $Value"
                    break
                }
                if ($Yaml[$j] -match '^[A-Za-z]' -and $Yaml[$j] -notmatch '^\s') { break }
            }
            break
        }
    }
    return $Yaml
}

function Update-DatastoreConfiguration {
    param([string[]]$Yaml, [string]$DataStorePath)
    
    $datastorePath = $DataStorePath -replace '\\', '/'
    
    for ($i = 0; $i -lt $Yaml.Count; $i++) {
        if ($Yaml[$i] -match '^Datastore:') {
            $endIdx = $i + 1
            while ($endIdx -lt $Yaml.Count -and $Yaml[$endIdx] -match '^\s+') { 
                $endIdx++ 
            }
            
            $datastoreConfig = @(
                "  implementation: FileBaseDataStore",
                "  location: '${datastorePath}/'",
                "  filestore_directory: '${datastorePath}/filestore'"
            )
            
            if ($endIdx -lt $Yaml.Count) {
                $Yaml = $Yaml[0..$i] + $datastoreConfig + $Yaml[$endIdx..($Yaml.Count - 1)]
            } else {
                $Yaml = $Yaml[0..$i] + $datastoreConfig
            }
            break
        }
    }
    return $Yaml
}

function Get-SSOConfiguration {
    if ($Force) { return $null }
    
    $enableSSO = Read-Host "Enable Single Sign-On (SSO)? [y/N]"
    if ($enableSSO -notmatch '^[Yy]') { return $null }
    
    $provider = Read-Host "SSO Provider [google/azure/github/okta/oidc]"
    
    switch ($provider.ToLower()) {
        'google' {
            $clientId = Read-Host "Google Client ID"
            $clientSecret = Read-Host "Google Client Secret" -AsSecureString
            $secretText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientSecret))
            
            return @"
authenticator:
  type: Google
  oauth_client_id: '$clientId'
  oauth_client_secret: '$secretText'
"@
        }
        'azure' {
            $clientId = Read-Host "Azure Client ID"
            $clientSecret = Read-Host "Azure Client Secret" -AsSecureString
            $tenantId = Read-Host "Azure Tenant ID"
            $secretText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientSecret))
            
            return @"
authenticator:
  type: Azure
  oauth_client_id: '$clientId'
  oauth_client_secret: '$secretText'
  tenant: '$tenantId'
"@
        }
        'github' {
            $clientId = Read-Host "GitHub Client ID"
            $clientSecret = Read-Host "GitHub Client Secret" -AsSecureString
            $secretText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientSecret))
            
            return @"
authenticator:
  type: GitHub
  oauth_client_id: '$clientId'
  oauth_client_secret: '$secretText'
"@
        }
        default {
            Write-Log "Unsupported or invalid SSO provider: $provider" -Level 'Warning'
            return $null
        }
    }
}

function Add-SSOConfiguration {
    param([string[]]$Yaml, [string]$SSOConfig)
    
    $ssoLines = ($SSOConfig -split "`n") | ForEach-Object { 
        if ($_.Trim() -ne '') { '  ' + $_ } else { $_ }
    }
    
    for ($i = 0; $i -lt $Yaml.Count; $i++) {
        if ($Yaml[$i] -match '^GUI:') {
            $insertIdx = $i + 1
            while ($insertIdx -lt $Yaml.Count -and $Yaml[$insertIdx] -match '^\s+') { 
                $insertIdx++ 
            }
            
            if ($insertIdx -lt $Yaml.Count) {
                $Yaml = $Yaml[0..($insertIdx - 1)] + $ssoLines + $Yaml[$insertIdx..($Yaml.Count - 1)]
            } else {
                $Yaml += $ssoLines
            }
            break
        }
    }
    return $Yaml
}

function Set-FirewallRules {
    Write-Log "Configuring Windows Firewall rules..."
    
    foreach ($port in @($FrontendPort, $GuiPort)) {
        $ruleName = "Velociraptor TCP $port"
        
        try {
            $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
            if ($existingRule) {
                Write-Log "Firewall rule already exists for port $port"
                continue
            }
            
            New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port -ErrorAction Stop | Out-Null
            Write-Log "Firewall rule created for TCP port $port" -Level 'Success'
        }
        catch {
            # Fallback to netsh
            try {
                $result = netsh advfirewall firewall add rule name="$ruleName" dir=in action=allow protocol=TCP localport=$port 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "Firewall rule created via netsh for TCP port $port" -Level 'Success'
                } else {
                    throw "netsh failed: $result"
                }
            }
            catch {
                Write-Log "Warning: Failed to create firewall rule for port $port - $($_.Exception.Message)" -Level 'Warning'
            }
        }
    }
}

function Install-VelociraptorService {
    param([string]$ExecutablePath, [string]$ConfigPath)
    
    Write-Log "Installing Velociraptor Windows service..."
    
    try {
        # Stop and remove existing service if present
        $existingService = Get-Service -Name $script:Config.ServiceName -ErrorAction SilentlyContinue
        if ($existingService) {
            Write-Log "Removing existing Velociraptor service..."
            if ($existingService.Status -eq 'Running') {
                Stop-Service -Name $script:Config.ServiceName -Force
            }
            & $ExecutablePath service remove 2>&1 | Out-Null
            Start-Sleep -Seconds 3
        }
        
        # Install new service
        $serviceResult = & $ExecutablePath service install --config $ConfigPath 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Service installation failed: $serviceResult"
        }
        
        # Configure service
        Set-Service -Name $script:Config.ServiceName -StartupType Automatic
        
        # Start service
        Start-Service -Name $script:Config.ServiceName
        
        # Verify service is running
        Start-Sleep -Seconds 5
        $service = Get-Service -Name $script:Config.ServiceName
        if ($service.Status -eq 'Running') {
            Write-Log "Velociraptor service installed and started successfully" -Level 'Success'
        } else {
            throw "Service installed but not running (Status: $($service.Status))"
        }
    }
    catch {
        Write-Log "Failed to install/start service: $($_.Exception.Message)" -Level 'Error'
        throw
    }
}

function New-ClientMSI {
    param([string]$ExecutablePath, [string]$ConfigPath, [string]$OutputPath)
    
    if ($SkipMSI) {
        Write-Log "Skipping MSI creation as requested"
        return
    }
    
    Write-Log "Creating client MSI package..."
    
    try {
        if (Test-Path $OutputPath) {
            Remove-Item $OutputPath -Force
        }
        
        $msiResult = & $ExecutablePath package windows msi --msi_out $OutputPath --config $ConfigPath 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "MSI creation failed: $msiResult"
        }
        
        if (-not (Test-Path $OutputPath) -or (Get-Item $OutputPath).Length -eq 0) {
            throw "MSI file was not created or is empty"
        }
        
        $msiSize = [math]::Round((Get-Item $OutputPath).Length / 1MB, 2)
        Write-Log "Client MSI created successfully: $OutputPath (${msiSize} MB)" -Level 'Success'
    }
    catch {
        Write-Log "Failed to create client MSI: $($_.Exception.Message)" -Level 'Warning'
        Write-Log "Server installation will continue without MSI package"
    }
}

############  Main Execution  ############################################
function Main {
    try {
        Write-Log "==== Velociraptor Server Deployment Started ====" -Level 'Success'
        
        # Prerequisites
        Test-Prerequisites
        
        # Create directories
        Write-Log "Creating installation directories..."
        foreach ($dir in @($InstallDir, $DataStore)) {
            if (-not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Write-Log "Created directory: $dir"
            }
        }
        
        # Download and install binary
        $executablePath = Join-Path $InstallDir 'velociraptor.exe'
        if (-not (Test-Path $executablePath) -or $Force) {
            $releaseInfo = Get-LatestVelociraptorRelease
            Install-VelociraptorBinary -ReleaseInfo $releaseInfo -DestinationPath $executablePath
        } else {
            Write-Log "Using existing executable: $executablePath"
        }
        
        # Generate and configure server
        $configPath = Join-Path $InstallDir 'server.yaml'
        New-ServerConfiguration -ExecutablePath $executablePath -ConfigPath $configPath
        Update-ServerConfiguration -ConfigPath $configPath
        
        # Configure firewall
        Set-FirewallRules
        
        # Install and start service
        Install-VelociraptorService -ExecutablePath $executablePath -ConfigPath $configPath
        
        # Create client MSI
        $hostname = if ($PublicHostname) { $PublicHostname } else { $env:COMPUTERNAME }
        $msiPath = Join-Path $InstallDir "velociraptor_client_${hostname}.msi"
        New-ClientMSI -ExecutablePath $executablePath -ConfigPath $configPath -OutputPath $msiPath
        
        # Final status
        Write-Log "==== Deployment Completed Successfully ====" -Level 'Success'
        Write-Log ""
        Write-Log "Server Configuration:" -Level 'Success'
        Write-Log "  - Installation Directory: $InstallDir"
        Write-Log "  - Data Storage: $DataStore"
        Write-Log "  - Frontend Port: $FrontendPort (agents)"
        Write-Log "  - GUI Port: $GuiPort (web interface)"
        Write-Log "  - Public Hostname: $hostname"
        Write-Log "  - Configuration: $configPath"
        if (Test-Path $msiPath) {
            Write-Log "  - Client MSI: $msiPath"
        }
        Write-Log ""
        Write-Log "Next Steps:"
        Write-Log "  1. Access web interface: https://${hostname}:${GuiPort}"
        Write-Log "  2. Create admin user account"
        Write-Log "  3. Deploy agents using MSI package"
        Write-Log ""
        Write-Log "Service Management:"
        Write-Log "  - Status: Get-Service Velociraptor"
        Write-Log "  - Logs: Get-WinEvent -LogName Application -Source Velociraptor"
        
    }
    catch {
        Write-Log "Deployment failed: $($_.Exception.Message)" -Level 'Error'
        Write-Log "==== Deployment Failed ====" -Level 'Error'
        exit 1
    }
}

# Execute main function
Main