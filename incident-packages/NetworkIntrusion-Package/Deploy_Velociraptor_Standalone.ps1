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
$ProgressPreference = 'SilentlyContinue'

# Import our VelociraptorDeployment module if available
$modulePath = Join-Path $PSScriptRoot 'VelociraptorDeployment\VelociraptorDeployment.psd1'
if (Test-Path $modulePath) {
    try {
        Import-Module $modulePath -Force -ErrorAction SilentlyContinue
        $moduleLoaded = $true
        Write-Host "[INFO] VelociraptorDeployment module loaded successfully" -ForegroundColor Green
    }
    catch {
        $moduleLoaded = $false
        Write-Host "[WARNING] Could not load VelociraptorDeployment module, using built-in functions" -ForegroundColor Yellow
    }
}
else {
    $moduleLoaded = $false
}

############  Helper Functions  ###################################################

function Write-Log {
    param([string]$Message, [string]$Level = 'Info')

    $logDir = Join-Path $env:ProgramData 'VelociraptorDeploy'
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory $logDir -Force | Out-Null
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "$timestamp`t[$Level]`t$Message"
    $logFile = Join-Path $logDir 'standalone_deploy.log'
    $logEntry | Out-File $logFile -Append -Encoding UTF8

    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        default { 'White' }
    }

    Write-Host "[$Level] $Message" -ForegroundColor $color
}

function Test-AdminPrivileges {
    $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Get-LatestVelociraptorAsset {
    Write-Log 'Querying GitHub for the latest Velociraptor release...'
    try {
        $headers = @{
            'User-Agent' = 'VelociraptorStandaloneDeployer/1.0'
            'Accept'     = 'application/vnd.github.v3+json'
        }
        $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/Velocidex/velociraptor/releases/latest' -Headers $headers -TimeoutSec 30
        $asset = $release.assets | Where-Object { $_.name -like '*windows-amd64.exe' -and $_.name -notlike '*msi*' } | Select-Object -First 1

        if (-not $asset) {
            throw 'Could not locate a Windows AMD64 asset in the latest release.'
        }

        Write-Log "Found version: $($release.tag_name)" -Level 'Success'
        return $asset.browser_download_url
    }
    catch {
        Write-Log "Failed to query GitHub API - $($_.Exception.Message)" -Level 'Error'
        throw
    }
}

function Install-VelociraptorExecutable {
    param([string]$Url, [string]$DestinationPath)

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Write-Log "Downloading $($Url.Split('/')[-1])..."

    try {
        $tempFile = "$DestinationPath.download"
        Invoke-WebRequest -Uri $Url -OutFile $tempFile -UseBasicParsing -Headers @{ 'User-Agent' = 'Mozilla/5.0' } -TimeoutSec 300

        # Verify download
        if (-not (Test-Path $tempFile) -or (Get-Item $tempFile).Length -eq 0) {
            throw "Download failed or file is empty"
        }

        Move-Item $tempFile $DestinationPath -Force
        Write-Log 'Download completed successfully.' -Level 'Success'
    }
    catch {
        # Cleanup on failure
        if (Test-Path "$DestinationPath.download") {
            Remove-Item "$DestinationPath.download" -Force -ErrorAction SilentlyContinue
        }
        Write-Log "Download failed - $($_.Exception.Message)" -Level 'Error'
        throw
    }
}

function Add-FirewallRule {
    param([int]$Port)

    if ($SkipFirewall) {
        Write-Log "Skipping firewall configuration as requested"
        return
    }

    $ruleName = 'Velociraptor Standalone GUI'

    # Check if rule already exists
    if (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue) {
        Write-Log "Firewall rule '$ruleName' already exists - skipping."
        return
    }

    # Try PowerShell cmdlet first
    if (Get-Command New-NetFirewallRule -ErrorAction SilentlyContinue) {
        try {
            New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $Port -ErrorAction Stop | Out-Null
            Write-Log "Firewall rule added via PowerShell (TCP $Port)." -Level 'Success'
            return
        }
        catch {
            Write-Log "PowerShell firewall cmdlet failed - $($_.Exception.Message)" -Level 'Warning'
        }
    }

    # Fallback to netsh
    try {
        $result = netsh advfirewall firewall add rule name="$ruleName" dir=in action=allow protocol=TCP localport=$Port 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Firewall rule added via netsh (TCP $Port)." -Level 'Success'
        }
        else {
            Write-Log "netsh failed - add the rule manually if you need remote access." -Level 'Warning'
            Write-Log "netsh output: $result" -Level 'Warning'
        }
    }
    catch {
        Write-Log "Failed to create firewall rule - $($_.Exception.Message)" -Level 'Warning'
    }
}

function Wait-ForPort {
    param([int]$Port, [int]$TimeoutSeconds = 15)

    Write-Log "Waiting for port $Port to become available..."

    for ($i = 1; $i -le $TimeoutSeconds; $i++) {
        Start-Sleep -Seconds 1
        $connection = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
        if ($connection) {
            Write-Log "Port $Port is now listening after $i seconds." -Level 'Success'
            return $true
        }
    }

    Write-Log "Timeout: Port $Port did not become available within $TimeoutSeconds seconds." -Level 'Warning'
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
    # Check admin privileges
    if (-not (Test-AdminPrivileges)) {
        throw "This script must be run as Administrator. Please restart PowerShell as Administrator and try again."
    }

    Write-Log '==== Velociraptor Standalone Deployment Started ====' -Level 'Success'

    # Use module functions if available, otherwise use built-in functions
    if ($moduleLoaded) {
        Write-Log "Using VelociraptorDeployment module functions"

        # Run prerequisites check from module
        $prereqs = Test-VelociraptorPrerequisites -Ports @($GuiPort)
        if (-not $prereqs.Overall) {
            throw "Prerequisites check failed. Please resolve the issues above."
        }
    }
    else {
        # Pre-flight checks using built-in functions
        if (-not (Test-PortAvailable -Port $GuiPort)) {
            throw "Port $GuiPort is already in use. Please stop the conflicting service or choose a different port."
        }
    }

    # Create directories
    foreach ($directory in @($InstallDir, $DataStore)) {
        if (-not (Test-Path $directory)) {
            New-Item -ItemType Directory $directory -Force | Out-Null
            Write-Log "Created directory: $directory" -Level 'Success'
        }
        else {
            Write-Log "Directory exists: $directory"
        }
    }

    # Handle executable
    $executablePath = Join-Path $InstallDir 'velociraptor.exe'
    if (-not (Test-Path $executablePath) -or $Force) {
        $downloadUrl = Get-LatestVelociraptorAsset
        Install-VelociraptorExecutable -Url $downloadUrl -DestinationPath $executablePath
    }
    else {
        Write-Log "Using existing executable: $executablePath"
    }

    # Configure firewall
    Add-FirewallRule -Port $GuiPort

    # Launch Velociraptor
    Write-Log "Starting Velociraptor GUI service..."
    $arguments = "gui --datastore `"$DataStore`""
    $process = Start-Process $executablePath -ArgumentList $arguments -WorkingDirectory $InstallDir -PassThru

    if ($process) {
        Write-Log "Velociraptor process started (PID: $($process.Id))" -Level 'Success'

        if (Wait-ForPort -Port $GuiPort -TimeoutSeconds 15) {
            Write-Log "==== Deployment Completed Successfully ====" -Level 'Success'
            Write-Log "Velociraptor GUI is ready at: https://127.0.0.1:$GuiPort" -Level 'Success'
            Write-Log "Default credentials: admin / password"
            Write-Log "Process ID: $($process.Id)"
            Write-Log "Data Store: $DataStore"
        }
        else {
            Write-Log "Velociraptor may not have started correctly on port $GuiPort." -Level 'Warning'
            Write-Log "Check the process manually with: & `"$executablePath`" gui --datastore `"$DataStore`" -v" -Level 'Warning'
        }
    }
    else {
        throw "Failed to start Velociraptor process"
    }
}
catch {
    Write-Log "Deployment failed - $($_.Exception.Message)" -Level 'Error'
    Write-Log '==== Deployment FAILED ====' -Level 'Error'
    exit 1
}