<#
.SYNOPSIS
    Deploy Velociraptor in standalone mode with GUI interface.

.DESCRIPTION
    Downloads latest Velociraptor EXE (or re-uses an existing one)
    Creates C:\VelociraptorData as the GUI's datastore
    Adds an inbound firewall rule for TCP 8889 (netsh fallback)
    Launches velociraptor.exe gui --datastore C:\VelociraptorData
    Waits until the port is listening, then exits

.PARAMETER InstallDir
    Installation directory. Default: C:\tools

.PARAMETER DataStore
    Data storage directory. Default: C:\VelociraptorData

.PARAMETER GuiPort
    GUI port number. Default: 8889

.PARAMETER SkipFirewall
    Skip firewall rule creation

.PARAMETER Force
    Force download even if executable exists

.EXAMPLE
    .\Deploy_Velociraptor_Standalone.ps1

.EXAMPLE
    .\Deploy_Velociraptor_Standalone.ps1 -GuiPort 9999 -SkipFirewall

.NOTES
    Requires Administrator privileges
    Logs → %ProgramData%\VelociraptorDeploy\standalone_deploy.log
#>

[CmdletBinding()]
param(
    [string]$InstallDir = 'C:\tools',
    [string]$DataStore = 'C:\VelociraptorData',
    [int]$GuiPort = 8889,
    [switch]$SkipFirewall,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

############  Helper Functions  ###################################################

function Log {
    param([string]$Message)
    $logDir = Join-Path $env:ProgramData 'VelociraptorDeploy'
    if (-not (Test-Path $logDir)) { 
        New-Item -ItemType Directory $logDir -Force | Out-Null 
    }
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "$timestamp`t$Message"
    $logFile = Join-Path $logDir 'standalone_deploy.log'
    $logEntry | Out-File $logFile -Append -Encoding UTF8
    Write-Host $Message
}

function Test-AdminPrivileges {
    $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        throw 'This script must be run as Administrator.'
    }
}

function Get-LatestVelociraptorAsset {
    Log 'Querying GitHub for the latest Velociraptor release...'
    try {
        $headers = @{ 
            'User-Agent' = 'VelociraptorStandaloneDeployer/1.0'
            'Accept' = 'application/vnd.github.v3+json'
        }
        $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/Velocidex/velociraptor/releases/latest' -Headers $headers -TimeoutSec 30
        $asset = $release.assets | Where-Object { $_.name -like '*windows-amd64.exe' -and $_.name -notlike '*msi*' } | Select-Object -First 1
        
        if (-not $asset) { 
            throw 'Could not locate a Windows AMD64 asset in the latest release.' 
        }
        
        Log "Found version: $($release.tag_name)"
        return $asset.browser_download_url
    }
    catch {
        Log "ERROR: Failed to query GitHub API - $($_.Exception.Message)"
        throw
    }
}

function Install-VelociraptorExecutable {
    param([string]$Url, [string]$DestinationPath)
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Log "Downloading $($Url.Split('/')[-1])..."
    
    try {
        $tempFile = "$DestinationPath.download"
        Invoke-WebRequest -Uri $Url -OutFile $tempFile -UseBasicParsing -Headers @{ 'User-Agent' = 'Mozilla/5.0' } -TimeoutSec 300
        
        # Verify download
        if (-not (Test-Path $tempFile) -or (Get-Item $tempFile).Length -eq 0) {
            throw "Download failed or file is empty"
        }
        
        Move-Item $tempFile $DestinationPath -Force
        Log 'Download completed successfully.'
    }
    catch {
        # Cleanup on failure
        if (Test-Path "$DestinationPath.download") {
            Remove-Item "$DestinationPath.download" -Force -ErrorAction SilentlyContinue
        }
        Log "ERROR: Download failed - $($_.Exception.Message)"
        throw
    }
}

function Add-FirewallRule {
    param([int]$Port)
    
    if ($SkipFirewall) {
        Log "Skipping firewall configuration as requested"
        return
    }
    
    $ruleName = 'Velociraptor Standalone GUI'
    
    # Check if rule already exists
    if (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue) {
        Log "Firewall rule '$ruleName' already exists - skipping."
        return
    }
    
    # Try PowerShell cmdlet first
    if (Get-Command New-NetFirewallRule -ErrorAction SilentlyContinue) {
        try {
            New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $Port -ErrorAction Stop | Out-Null
            Log "Firewall rule added via PowerShell (TCP $Port)."
            return
        }
        catch {
            Log "Warning: PowerShell firewall cmdlet failed - $($_.Exception.Message)"
        }
    }
    
    # Fallback to netsh
    try {
        $result = netsh advfirewall firewall add rule name="$ruleName" dir=in action=allow protocol=TCP localport=$Port 2>&1
        if ($LASTEXITCODE -eq 0) {
            Log "Firewall rule added via netsh (TCP $Port)."
        } else {
            Log "Warning: netsh failed - add the rule manually if you need remote access."
            Log "netsh output: $result"
        }
    }
    catch {
        Log "Warning: Failed to create firewall rule - $($_.Exception.Message)"
    }
}

function Wait-ForPort {
    param([int]$Port, [int]$TimeoutSeconds = 15)
    
    Log "Waiting for port $Port to become available..."
    
    for ($i = 1; $i -le $TimeoutSeconds; $i++) {
        Start-Sleep -Seconds 1
        $connection = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
        if ($connection) { 
            Log "Port $Port is now listening after $i seconds."
            return $true 
        }
    }
    
    Log "Timeout: Port $Port did not become available within $TimeoutSeconds seconds."
    return $false
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

############  Main Execution  #######################################################

try {
    Test-AdminPrivileges
    Log '==== Velociraptor Standalone Deployment Started ===='
    
    # Pre-flight checks
    if (-not (Test-PortAvailable -Port $GuiPort)) {
        throw "Port $GuiPort is already in use. Please stop the conflicting service or choose a different port."
    }
    
    # Create directories
    foreach ($directory in @($InstallDir, $DataStore)) {
        if (-not (Test-Path $directory)) { 
            New-Item -ItemType Directory $directory -Force | Out-Null 
            Log "Created directory: $directory"
        } else {
            Log "Directory exists: $directory"
        }
    }
    
    # Handle executable
    $executablePath = Join-Path $InstallDir 'velociraptor.exe'
    if (-not (Test-Path $executablePath) -or $Force) {
        $downloadUrl = Get-LatestVelociraptorAsset
        Install-VelociraptorExecutable -Url $downloadUrl -DestinationPath $executablePath
    } else {
        Log "Using existing executable: $executablePath"
    }
    
    # Configure firewall
    Add-FirewallRule -Port $GuiPort
    
    # Launch Velociraptor
    Log "Starting Velociraptor GUI service..."
    $arguments = "gui --datastore `"$DataStore`""
    $process = Start-Process $executablePath -ArgumentList $arguments -WorkingDirectory $InstallDir -PassThru
    
    if ($process) {
        Log "Velociraptor process started (PID: $($process.Id))"
        
        if (Wait-ForPort -Port $GuiPort -TimeoutSeconds 15) {
            Log "==== Deployment Completed Successfully ===="
            Log "Velociraptor GUI is ready at: https://127.0.0.1:$GuiPort"
            Log "Default credentials: admin / password"
            Log "Process ID: $($process.Id)"
            Log "Data Store: $DataStore"
        } else {
            Log "WARNING: Velociraptor may not have started correctly on port $GuiPort."
            Log "Check the process manually with: & `"$executablePath`" gui --datastore `"$DataStore`" -v"
        }
    } else {
        throw "Failed to start Velociraptor process"
    }
}
catch {
    Log "ERROR: Deployment failed - $($_.Exception.Message)"
    Log '==== Deployment FAILED ===='
    exit 1
}