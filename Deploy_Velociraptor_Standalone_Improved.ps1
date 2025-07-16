<#
.SYNOPSIS
    Deploy Velociraptor in standalone mode with GUI interface.

.DESCRIPTION
    This script automates the deployment of Velociraptor in standalone mode by:
    • Downloading the latest Velociraptor executable (or reusing existing)
    • Creating the datastore directory with proper permissions
    • Configuring Windows Firewall rules for GUI access
    • Launching the Velociraptor GUI service
    • Validating successful deployment

.PARAMETER InstallDir
    Directory where Velociraptor executable will be stored. Default: C:\tools

.PARAMETER DataStore
    Directory for Velociraptor's datastore. Default: C:\VelociraptorData

.PARAMETER GuiPort
    TCP port for the GUI interface. Default: 8889

.PARAMETER SkipFirewall
    Skip firewall rule creation (useful for environments with custom firewall policies)

.PARAMETER Force
    Force download even if executable already exists

.EXAMPLE
    .\Deploy_Velociraptor_Standalone.ps1
    
.EXAMPLE
    .\Deploy_Velociraptor_Standalone.ps1 -InstallDir "D:\Velociraptor" -GuiPort 9999

.NOTES
    Requires Administrator privileges
    Logs are written to %ProgramData%\VelociraptorDeploy\standalone_deploy.log
#>

[CmdletBinding()]
param(
    [ValidateScript({Test-Path (Split-Path $_ -Parent) -PathType Container})]
    [string]$InstallDir = 'C:\tools',
    
    [ValidateScript({Test-Path (Split-Path $_ -Parent) -PathType Container})]
    [string]$DataStore = 'C:\VelociraptorData',
    
    [ValidateRange(1024, 65535)]
    [int]$GuiPort = 8889,
    
    [switch]$SkipFirewall,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

############  Configuration  #############################################
$script:Config = @{
    LogDir = Join-Path $env:ProgramData 'VelociraptorDeploy'
    LogFile = 'standalone_deploy.log'
    GitHubAPI = 'https://api.github.com/repos/Velocidex/velociraptor/releases/latest'
    UserAgent = 'VelociraptorStandaloneDeployer/1.0'
    FirewallRuleName = 'Velociraptor Standalone GUI'
    MaxWaitSeconds = 30
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
        
        # Console output with colors
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

function Write-LogError {
    param([string]$Message, [System.Management.Automation.ErrorRecord]$ErrorRecord)
    
    $errorMsg = if ($ErrorRecord) {
        "$Message - $($ErrorRecord.Exception.Message)"
    } else {
        $Message
    }
    
    Write-Log -Message $errorMsg -Level 'Error'
}

############  Validation Functions  #####################################
function Test-AdminPrivileges {
    $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Test-NetworkConnectivity {
    try {
        $null = Invoke-RestMethod -Uri 'https://api.github.com' -Method Head -TimeoutSec 10 -UseBasicParsing
        return $true
    }
    catch {
        return $false
    }
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
function Get-LatestVelociraptorUrl {
    Write-Log "Querying GitHub API for latest Velociraptor release..."
    
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
        
        Write-Log "Found latest version: $($release.tag_name)" -Level 'Success'
        return @{
            Url = $asset.browser_download_url
            Version = $release.tag_name
            Size = $asset.size
        }
    }
    catch {
        Write-LogError "Failed to get latest Velociraptor release" $_
        throw
    }
}

function Install-VelociraptorExecutable {
    param(
        [string]$DownloadUrl,
        [string]$DestinationPath,
        [string]$Version
    )
    
    try {
        Write-Log "Downloading Velociraptor $Version..."
        
        # Ensure TLS 1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        $tempFile = "$DestinationPath.download"
        $headers = @{ 'User-Agent' = $script:Config.UserAgent }
        
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $tempFile -UseBasicParsing -Headers $headers -TimeoutSec 300
        
        # Verify download
        if (-not (Test-Path $tempFile) -or (Get-Item $tempFile).Length -eq 0) {
            throw "Download failed or file is empty"
        }
        
        # Move to final location
        Move-Item $tempFile $DestinationPath -Force
        Write-Log "Download completed successfully" -Level 'Success'
        
        # Verify executable
        $fileInfo = Get-Item $DestinationPath
        Write-Log "Executable size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB"
        
    }
    catch {
        # Cleanup on failure
        if (Test-Path "$DestinationPath.download") {
            Remove-Item "$DestinationPath.download" -Force -ErrorAction SilentlyContinue
        }
        Write-LogError "Failed to download Velociraptor executable" $_
        throw
    }
}

function Set-FirewallRule {
    param([int]$Port)
    
    if ($SkipFirewall) {
        Write-Log "Skipping firewall configuration as requested"
        return
    }
    
    $ruleName = $script:Config.FirewallRuleName
    
    try {
        # Check if rule already exists
        $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
        if ($existingRule) {
            Write-Log "Firewall rule '$ruleName' already exists"
            return
        }
        
        # Try PowerShell cmdlet first
        if (Get-Command New-NetFirewallRule -ErrorAction SilentlyContinue) {
            New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $Port -ErrorAction Stop
            Write-Log "Firewall rule created successfully (PowerShell)" -Level 'Success'
            return
        }
        
        # Fallback to netsh
        $result = netsh advfirewall firewall add rule name="$ruleName" dir=in action=allow protocol=TCP localport=$Port 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Firewall rule created successfully (netsh)" -Level 'Success'
        } else {
            Write-Log "Warning: Failed to create firewall rule. Manual configuration may be required." -Level 'Warning'
            Write-Log "netsh output: $result"
        }
    }
    catch {
        Write-Log "Warning: Failed to create firewall rule - $($_.Exception.Message)" -Level 'Warning'
    }
}

function Start-VelociraptorGUI {
    param(
        [string]$ExecutablePath,
        [string]$DataStorePath,
        [int]$Port
    )
    
    try {
        Write-Log "Starting Velociraptor GUI service..."
        
        $arguments = @(
            'gui'
            '--datastore'
            "`"$DataStorePath`""
        )
        
        $processInfo = @{
            FilePath = $ExecutablePath
            ArgumentList = $arguments
            WorkingDirectory = Split-Path $ExecutablePath -Parent
            WindowStyle = 'Hidden'
            PassThru = $true
        }
        
        $process = Start-Process @processInfo
        
        if ($process) {
            Write-Log "Velociraptor process started (PID: $($process.Id))" -Level 'Success'
            return $process
        } else {
            throw "Failed to start Velociraptor process"
        }
    }
    catch {
        Write-LogError "Failed to start Velociraptor GUI" $_
        throw
    }
}

function Wait-ForService {
    param([int]$Port, [int]$TimeoutSeconds = 30)
    
    Write-Log "Waiting for Velociraptor GUI to become available on port $Port..."
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        try {
            $connections = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
            if ($connections) {
                $stopwatch.Stop()
                Write-Log "Service is ready after $([math]::Round($stopwatch.Elapsed.TotalSeconds, 1)) seconds" -Level 'Success'
                return $true
            }
        }
        catch {
            # Continue waiting
        }
        
        Start-Sleep -Seconds 1
    }
    
    $stopwatch.Stop()
    Write-Log "Timeout waiting for service to start" -Level 'Warning'
    return $false
}

############  Main Execution  ############################################
function Main {
    try {
        Write-Log "==== Velociraptor Standalone Deployment Started ====" -Level 'Success'
        
        # Pre-flight checks
        if (-not (Test-AdminPrivileges)) {
            throw "This script requires Administrator privileges. Please run as Administrator."
        }
        
        if (-not (Test-NetworkConnectivity)) {
            Write-Log "Warning: Limited network connectivity detected. Download may fail." -Level 'Warning'
        }
        
        if (-not (Test-PortAvailable -Port $GuiPort)) {
            throw "Port $GuiPort is already in use. Please choose a different port or stop the conflicting service."
        }
        
        # Create directories
        Write-Log "Creating required directories..."
        foreach ($dir in @($InstallDir, $DataStore)) {
            if (-not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Write-Log "Created directory: $dir"
            } else {
                Write-Log "Directory exists: $dir"
            }
        }
        
        # Handle executable
        $executablePath = Join-Path $InstallDir 'velociraptor.exe'
        
        if ((Test-Path $executablePath) -and -not $Force) {
            Write-Log "Using existing executable: $executablePath"
        } else {
            $releaseInfo = Get-LatestVelociraptorUrl
            Install-VelociraptorExecutable -DownloadUrl $releaseInfo.Url -DestinationPath $executablePath -Version $releaseInfo.Version
        }
        
        # Configure firewall
        Set-FirewallRule -Port $GuiPort
        
        # Start service
        $process = Start-VelociraptorGUI -ExecutablePath $executablePath -DataStorePath $DataStore -Port $GuiPort
        
        # Wait for service to be ready
        if (Wait-ForService -Port $GuiPort -TimeoutSeconds $script:Config.MaxWaitSeconds) {
            Write-Log "==== Deployment Completed Successfully ====" -Level 'Success'
            Write-Log ""
            Write-Log "Velociraptor GUI is now available at: https://127.0.0.1:$GuiPort" -Level 'Success'
            Write-Log "Default credentials: admin / password" -Level 'Info'
            Write-Log ""
            Write-Log "Process ID: $($process.Id)"
            Write-Log "Data Store: $DataStore"
            Write-Log "Executable: $executablePath"
        } else {
            Write-Log "Service may not have started correctly. Check the process manually:" -Level 'Warning'
            Write-Log "Command: & `"$executablePath`" gui --datastore `"$DataStore`" -v"
        }
    }
    catch {
        Write-LogError "Deployment failed" $_
        Write-Log "==== Deployment Failed ====" -Level 'Error'
        exit 1
    }
}

# Execute main function
Main