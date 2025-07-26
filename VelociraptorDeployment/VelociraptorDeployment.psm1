# VelociraptorDeployment PowerShell Module
# Provides functions for deploying and managing Velociraptor

#region Private Functions

function Write-VeloLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info',
        
        [string]$LogPath
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "{0}`t[{1}]`t{2}" -f $timestamp, $Level.ToUpper(), $Message
    
    if ($LogPath) {
        $logDir = Split-Path $LogPath -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        $logEntry | Out-File -FilePath $LogPath -Append -Encoding UTF8
    }
    
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

function Get-LatestVelociraptorRelease {
    try {
        $headers = @{
            'User-Agent' = 'VelociraptorDeploymentModule/2.0'
            'Accept' = 'application/vnd.github.v3+json'
        }
        
        $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/Velocidex/velociraptor/releases/latest' -Headers $headers -TimeoutSec 30
        
        $asset = $release.assets | Where-Object { 
            $_.name -like '*windows-amd64.exe' -and $_.name -notlike '*msi*' 
        } | Select-Object -First 1
        
        if (-not $asset) {
            throw "No Windows AMD64 executable found in latest release"
        }
        
        return @{
            Version = $release.tag_name
            DownloadUrl = $asset.browser_download_url
            Size = $asset.size
        }
    }
    catch {
        throw "Failed to get latest Velociraptor release: $($_.Exception.Message)"
    }
}

#endregion

#region Public Functions

function Test-VelociraptorPrerequisites {
    <#
    .SYNOPSIS
        Tests system prerequisites for Velociraptor deployment.
    
    .DESCRIPTION
        Validates that the system meets requirements for Velociraptor installation including
        administrator privileges, PowerShell version, network connectivity, and port availability.
    
    .PARAMETER Ports
        Array of ports to test for availability. Default: @(8889, 8000)
    
    .EXAMPLE
        Test-VelociraptorPrerequisites
        
    .EXAMPLE
        Test-VelociraptorPrerequisites -Ports @(9999, 8443)
    #>
    
    [CmdletBinding()]
    param(
        [int[]]$Ports = @(8889, 8000)
    )
    
    $results = @{
        AdminPrivileges = $false
        PowerShellVersion = $false
        NetworkConnectivity = $false
        PortsAvailable = @{}
        Overall = $false
    }
    
    # Check admin privileges
    $results.AdminPrivileges = Test-AdminPrivileges
    Write-VeloLog "Administrator privileges: $(if($results.AdminPrivileges){'✓ Pass'}else{'✗ Fail'})" -Level $(if($results.AdminPrivileges){'Success'}else{'Error'})
    
    # Check PowerShell version
    $results.PowerShellVersion = $PSVersionTable.PSVersion -ge [Version]'5.1'
    Write-VeloLog "PowerShell version ($($PSVersionTable.PSVersion)): $(if($results.PowerShellVersion){'✓ Pass'}else{'✗ Fail'})" -Level $(if($results.PowerShellVersion){'Success'}else{'Error'})
    
    # Check network connectivity
    try {
        $null = Invoke-RestMethod -Uri 'https://api.github.com' -Method Head -TimeoutSec 10 -UseBasicParsing
        $results.NetworkConnectivity = $true
        Write-VeloLog "Network connectivity: ✓ Pass" -Level 'Success'
    }
    catch {
        $results.NetworkConnectivity = $false
        Write-VeloLog "Network connectivity: ✗ Fail" -Level 'Error'
    }
    
    # Check port availability
    foreach ($port in $Ports) {
        $available = Test-PortAvailable -Port $port
        $results.PortsAvailable[$port] = $available
        Write-VeloLog "Port $port availability: $(if($available){'✓ Pass'}else{'✗ Fail'})" -Level $(if($available){'Success'}else{'Error'})
    }
    
    # Overall result
    $results.Overall = $results.AdminPrivileges -and $results.PowerShellVersion -and $results.NetworkConnectivity -and ($results.PortsAvailable.Values -notcontains $false)
    
    Write-VeloLog "Overall prerequisites: $(if($results.Overall){'✓ Pass'}else{'✗ Fail'})" -Level $(if($results.Overall){'Success'}else{'Error'})
    
    return $results
}

function Install-VelociraptorStandalone {
    <#
    .SYNOPSIS
        Installs Velociraptor in standalone mode.
    
    .DESCRIPTION
        Downloads and configures Velociraptor for single-machine use with GUI interface.
        Creates necessary directories, configures firewall rules, and starts the service.
    
    .PARAMETER InstallDir
        Installation directory. Default: C:\tools
    
    .PARAMETER DataStore
        Data storage directory. Default: C:\VelociraptorData
    
    .PARAMETER GuiPort
        GUI port number. Default: 8889
    
    .PARAMETER SkipFirewall
        Skip firewall rule creation
    
    .PARAMETER Force
        Force reinstallation even if already exists
    
    .EXAMPLE
        Install-VelociraptorStandalone
        
    .EXAMPLE
        Install-VelociraptorStandalone -InstallDir "D:\Velociraptor" -GuiPort 9999
    #>
    
    [CmdletBinding()]
    param(
        [string]$InstallDir = 'C:\tools',
        [string]$DataStore = 'C:\VelociraptorData',
        [int]$GuiPort = 8889,
        [switch]$SkipFirewall,
        [switch]$Force
    )
    
    try {
        $logPath = Join-Path $env:ProgramData 'VelociraptorDeploy\standalone_install.log'
        Write-VeloLog "Starting Velociraptor standalone installation..." -Level 'Success' -LogPath $logPath
        
        # Prerequisites check
        $prereqs = Test-VelociraptorPrerequisites -Ports @($GuiPort)
        if (-not $prereqs.Overall) {
            throw "Prerequisites check failed. Please resolve the issues above."
        }
        
        # Create directories
        foreach ($dir in @($InstallDir, $DataStore)) {
            if (-not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Write-VeloLog "Created directory: $dir" -LogPath $logPath
            }
        }
        
        # Download executable
        $executablePath = Join-Path $InstallDir 'velociraptor.exe'
        if (-not (Test-Path $executablePath) -or $Force) {
            $release = Get-LatestVelociraptorRelease
            Write-VeloLog "Downloading Velociraptor $($release.Version)..." -LogPath $logPath
            
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $release.DownloadUrl -OutFile $executablePath -UseBasicParsing -TimeoutSec 300
            
            Write-VeloLog "Download completed successfully" -Level 'Success' -LogPath $logPath
        }
        
        # Configure firewall
        if (-not $SkipFirewall) {
            $ruleName = "Velociraptor Standalone GUI"
            try {
                $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
                if (-not $existingRule) {
                    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $GuiPort | Out-Null
                    Write-VeloLog "Firewall rule created for port $GuiPort" -Level 'Success' -LogPath $logPath
                }
            }
            catch {
                Write-VeloLog "Warning: Failed to create firewall rule" -Level 'Warning' -LogPath $logPath
            }
        }
        
        # Start Velociraptor
        Write-VeloLog "Starting Velociraptor GUI..." -LogPath $logPath
        $process = Start-Process $executablePath -ArgumentList "gui --datastore `"$DataStore`"" -PassThru
        
        # Wait for service to be ready
        $timeout = 30
        $elapsed = 0
        do {
            Start-Sleep -Seconds 1
            $elapsed++
            $connection = Get-NetTCPConnection -LocalPort $GuiPort -State Listen -ErrorAction SilentlyContinue
        } while (-not $connection -and $elapsed -lt $timeout)
        
        if ($connection) {
            Write-VeloLog "Velociraptor GUI is ready at https://127.0.0.1:$GuiPort" -Level 'Success' -LogPath $logPath
            Write-VeloLog "Default credentials: admin / password" -LogPath $logPath
        } else {
            Write-VeloLog "Warning: GUI may not have started correctly" -Level 'Warning' -LogPath $logPath
        }
        
        return @{
            Success = $true
            ProcessId = $process.Id
            GuiUrl = "https://127.0.0.1:$GuiPort"
            InstallPath = $executablePath
            DataStore = $DataStore
        }
    }
    catch {
        Write-VeloLog "Installation failed: $($_.Exception.Message)" -Level 'Error' -LogPath $logPath
        throw
    }
}

function Get-VelociraptorStatus {
    <#
    .SYNOPSIS
        Gets the status of Velociraptor installations.
    
    .DESCRIPTION
        Checks for running Velociraptor processes, services, and listening ports.
    
    .EXAMPLE
        Get-VelociraptorStatus
    #>
    
    [CmdletBinding()]
    param()
    
    $status = @{
        Processes = @()
        Services = @()
        ListeningPorts = @()
        InstallationPaths = @()
    }
    
    # Check processes
    $processes = Get-Process -Name "*velociraptor*" -ErrorAction SilentlyContinue
    foreach ($proc in $processes) {
        $status.Processes += @{
            Name = $proc.Name
            Id = $proc.Id
            Path = $proc.Path
            StartTime = $proc.StartTime
        }
    }
    
    # Check services
    $services = Get-Service -Name "*Velociraptor*" -ErrorAction SilentlyContinue
    foreach ($svc in $services) {
        $status.Services += @{
            Name = $svc.Name
            Status = $svc.Status
            StartType = $svc.StartType
        }
    }
    
    # Check listening ports
    $commonPorts = @(8889, 8000, 8443)
    foreach ($port in $commonPorts) {
        $connection = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
        if ($connection) {
            $status.ListeningPorts += @{
                Port = $port
                ProcessId = $connection.OwningProcess
            }
        }
    }
    
    # Check common installation paths
    $commonPaths = @(
        'C:\tools\velociraptor.exe',
        'C:\Program Files\Velociraptor\velociraptor.exe',
        'C:\VelociraptorData',
        'C:\VelociraptorServerData'
    )
    
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            $item = Get-Item $path
            $status.InstallationPaths += @{
                Path = $path
                Type = if ($item.PSIsContainer) { 'Directory' } else { 'File' }
                Size = if (-not $item.PSIsContainer) { $item.Length } else { $null }
                LastModified = $item.LastWriteTime
            }
        }
    }
    
    return $status
}

function Remove-VelociraptorInstallation {
    <#
    .SYNOPSIS
        Completely removes Velociraptor installation.
    
    .DESCRIPTION
        Stops services, kills processes, removes files, registry entries, and firewall rules.
    
    .PARAMETER Force
        Skip confirmation prompts
    
    .PARAMETER AdditionalPaths
        Additional paths to remove
    
    .EXAMPLE
        Remove-VelociraptorInstallation -Force
    #>
    
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$Force,
        [string[]]$AdditionalPaths = @()
    )
    
    if (-not (Test-AdminPrivileges)) {
        throw "Administrator privileges required for removal"
    }
    
    if (-not $Force -and -not $PSCmdlet.ShouldProcess("Velociraptor Installation", "Remove")) {
        return
    }
    
    $logPath = Join-Path $env:ProgramData 'VelociraptorCleanup\removal.log'
    Write-VeloLog "Starting Velociraptor removal..." -Level 'Success' -LogPath $logPath
    
    try {
        # Stop and remove services
        $services = Get-Service -Name "*Velociraptor*" -ErrorAction SilentlyContinue
        foreach ($service in $services) {
            if ($service.Status -eq 'Running') {
                Stop-Service -Name $service.Name -Force
                Write-VeloLog "Stopped service: $($service.Name)" -LogPath $logPath
            }
            & sc.exe delete $service.Name | Out-Null
            Write-VeloLog "Removed service: $($service.Name)" -LogPath $logPath
        }
        
        # Kill processes
        $processes = Get-Process -Name "*velociraptor*" -ErrorAction SilentlyContinue
        foreach ($process in $processes) {
            Stop-Process -Id $process.Id -Force
            Write-VeloLog "Killed process: $($process.Name) (PID: $($process.Id))" -LogPath $logPath
        }
        
        # Remove firewall rules
        $rules = Get-NetFirewallRule -DisplayName "*Velociraptor*" -ErrorAction SilentlyContinue
        foreach ($rule in $rules) {
            Remove-NetFirewallRule -Name $rule.Name -Confirm:$false
            Write-VeloLog "Removed firewall rule: $($rule.DisplayName)" -LogPath $logPath
        }
        
        # Remove files and directories
        $pathsToRemove = @(
            "$env:ProgramFiles\Velociraptor",
            "$env:ProgramData\Velociraptor",
            'C:\tools\velociraptor.exe',
            'C:\tools\server.yaml',
            'C:\VelociraptorData',
            'C:\VelociraptorServerData'
        ) + $AdditionalPaths
        
        foreach ($path in $pathsToRemove) {
            if (Test-Path $path) {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                Write-VeloLog "Removed: $path" -LogPath $logPath
            }
        }
        
        Write-VeloLog "Velociraptor removal completed successfully" -Level 'Success' -LogPath $logPath
        Write-VeloLog "A system reboot is recommended" -Level 'Warning' -LogPath $logPath
        
        return @{ Success = $true; Message = "Removal completed successfully" }
    }
    catch {
        Write-VeloLog "Removal failed: $($_.Exception.Message)" -Level 'Error' -LogPath $logPath
        throw
    }
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Test-VelociraptorPrerequisites',
    'Install-VelociraptorStandalone', 
    'Get-VelociraptorStatus',
    'Remove-VelociraptorInstallation'
)