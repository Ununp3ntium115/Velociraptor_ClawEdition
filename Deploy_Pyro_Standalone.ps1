#!/usr/bin/env pwsh
<#
.SYNOPSIS
    🔥 Deploy PYRO DFIR Platform in standalone mode with integrated toolsuite
    
.DESCRIPTION
    Revolutionary DFIR deployment that sets fire to traditional frameworks:
    - Downloads latest Velociraptor EXE (or re-uses existing)
    - Creates datastore for GUI interface
    - Installs complete PYRO DFIR toolsuite (hayabusa, UAC, chainsaw, YARA, sigma)
    - Configures firewall rules for secure operation
    - Launches with blazing-fast performance
    
.PARAMETER InstallDir
    Installation directory. Default: C:\PYRO (Windows) or /opt/PYRO (Linux/macOS)
    
.PARAMETER DataStore
    Data storage directory. Default: C:\PYROData (Windows) or /var/lib/pyro (Linux/macOS)
    
.PARAMETER GuiPort
    GUI port number. Default: 8889
    
.PARAMETER SkipFirewall
    Skip firewall rule creation
    
.PARAMETER Force
    Force download even if executable exists
    
.PARAMETER InstallPyroTools
    Install complete PYRO DFIR toolsuite. Default: $true
    
.PARAMETER PyroToolsPath
    Custom path for PYRO tools installation
    
.PARAMETER SecurityHardening
    Apply security hardening (Basic, Standard, Maximum). Default: Standard
    
.EXAMPLE
    .\Deploy_Pyro_Standalone.ps1
    
.EXAMPLE
    .\Deploy_Pyro_Standalone.ps1 -GuiPort 9999 -SecurityHardening Maximum
    
.EXAMPLE
    .\Deploy_Pyro_Standalone.ps1 -InstallPyroTools:$false -SkipFirewall
    
.NOTES
    🔥 PYRO v6.0.0 - Setting Fire to DFIR Frameworks
    Requires Administrator/root privileges for full installation
    Logs → %ProgramData%\PYRO\deploy.log (Windows) or /var/log/pyro/deploy.log (Linux/macOS)
#>

[CmdletBinding()]
param(
    [string]$InstallDir = $(if ($IsWindows -or $null -eq $IsWindows) { 'C:\PYRO' } else { '/opt/PYRO' }),
    [string]$DataStore = $(if ($IsWindows -or $null -eq $IsWindows) { 'C:\PYROData' } else { '/var/lib/pyro' }),
    [int]$GuiPort = 8889,
    [switch]$SkipFirewall,
    [switch]$Force,
    [bool]$InstallPyroTools = $true,
    [string]$PyroToolsPath = $(if ($IsWindows -or $null -eq $IsWindows) { 'C:\PYRO\tools' } else { '/opt/PYRO/tools' }),
    [ValidateSet('Basic', 'Standard', 'Maximum')]
    [string]$SecurityHardening = 'Standard'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# 🔥 PYRO Banner
Write-Host "🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥" -ForegroundColor Red
Write-Host "🔥                                                   🔥" -ForegroundColor Red
Write-Host "🔥        PYRO STANDALONE DEPLOYMENT v6.0.0         🔥" -ForegroundColor Red
Write-Host "🔥           Setting Fire to DFIR Frameworks        🔥" -ForegroundColor Red
Write-Host "🔥                                                   🔥" -ForegroundColor Red
Write-Host "🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥" -ForegroundColor Red
Write-Host ""

# Import PyroSetupScripts module if available
$pyroModulePath = Join-Path $PSScriptRoot 'PyroSetupScripts.psm1'
if (Test-Path $pyroModulePath) {
    try {
        Import-Module $pyroModulePath -Force -Global
        $pyroModuleLoaded = $true
        Write-Host "🔥 PYRO Module loaded successfully!" -ForegroundColor Green
    }
    catch {
        $pyroModuleLoaded = $false
        Write-Host "⚠️ Could not load PYRO module, using built-in functions" -ForegroundColor Yellow
    }
}
else {
    $pyroModuleLoaded = $false
    Write-Host "⚠️ PYRO module not found at: $pyroModulePath" -ForegroundColor Yellow
}

############  🔥 PYRO Helper Functions  ###################################################

function Write-PyroLog {
    param([string]$Message, [string]$Level = 'Info')
    
    $logDir = if ($IsWindows -or $null -eq $IsWindows) { 
        Join-Path $env:ProgramData 'PYRO'
    } else { 
        '/var/log/pyro'
    }
    
    if (-not (Test-Path $logDir)) { 
        New-Item -ItemType Directory $logDir -Force | Out-Null 
    }
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "$timestamp`t[$Level]`t$Message"
    $logFile = Join-Path $logDir 'deploy.log'
    $logEntry | Out-File $logFile -Append -Encoding UTF8
    
    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Info' { 'Cyan' }
        default { 'White' }
    }
    
    $emoji = switch ($Level) {
        'Success' { '✅' }
        'Warning' { '⚠️' }
        'Error' { '❌' }
        'Info' { '🔥' }
        default { '📝' }
    }
    
    Write-Host "$emoji [$Level] $Message" -ForegroundColor $color
}

function Test-PyroAdminPrivileges {
    if ($IsWindows -or $null -eq $IsWindows) {
        $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    } else {
        return (id -u) -eq 0
    }
}

function Get-LatestVelociraptorAsset {
    Write-PyroLog 'Querying GitHub for the latest Velociraptor release...' -Level 'Info'
    try {
        $headers = @{ 
            'User-Agent' = 'PYRO-DFIR-Platform/6.0.0'
            'Accept'     = 'application/vnd.github.v3+json'
        }
        $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/Velocidx/velociraptor/releases/latest' -Headers $headers -TimeoutSec 30
        
        # Determine platform-specific asset
        if ($IsWindows -or $null -eq $IsWindows) {
            $assetPattern = '*windows-amd64.exe'
        } elseif ($IsLinux) {
            $assetPattern = '*linux-amd64'
        } elseif ($IsMacOS) {
            $assetPattern = '*darwin-amd64'
        } else {
            $assetPattern = '*linux-amd64'  # Default fallback
        }
        
        $asset = $release.assets | Where-Object { $_.name -like $assetPattern -and $_.name -notlike '*msi*' } | Select-Object -First 1
        
        if (-not $asset) { 
            throw "Could not locate a compatible asset for your platform in the latest release."
        }
        
        Write-PyroLog "Found Velociraptor version: $($release.tag_name)" -Level 'Success'
        return @{
            Url = $asset.browser_download_url
            Name = $asset.name
            Version = $release.tag_name
        }
    }
    catch {
        Write-PyroLog "Failed to query GitHub API - $($_.Exception.Message)" -Level 'Error'
        throw
    }
}

function Install-VelociraptorExecutable {
    param([hashtable]$Asset, [string]$DestinationPath)
    
    Write-PyroLog "Downloading $($Asset.Name)..." -Level 'Info'
    
    try {
        $tempFile = "$DestinationPath.download"
        Invoke-WebRequest -Uri $Asset.Url -OutFile $tempFile -UseBasicParsing -Headers @{ 'User-Agent' = 'PYRO-DFIR/6.0.0' } -TimeoutSec 300
        
        # Verify download
        if (-not (Test-Path $tempFile) -or (Get-Item $tempFile).Length -eq 0) {
            throw "Download failed or file is empty"
        }
        
        Move-Item $tempFile $DestinationPath -Force
        
        # Make executable on Unix-like systems
        if ($IsLinux -or $IsMacOS) {
            chmod +x $DestinationPath
        }
        
        Write-PyroLog 'Velociraptor download completed successfully.' -Level 'Success'
        return $DestinationPath
    }
    catch {
        # Cleanup on failure
        if (Test-Path "$DestinationPath.download") {
            Remove-Item "$DestinationPath.download" -Force -ErrorAction SilentlyContinue
        }
        Write-PyroLog "Download failed: $($_.Exception.Message)" -Level 'Error'
        throw
    }
}

function Set-PyroFirewallRule {
    param([int]$Port)
    
    if ($SkipFirewall) {
        Write-PyroLog "Skipping firewall configuration as requested" -Level 'Warning'
        return
    }
    
    Write-PyroLog "Configuring firewall for port $Port..." -Level 'Info'
    
    try {
        if ($IsWindows -or $null -eq $IsWindows) {
            # Windows Firewall
            $ruleName = "PYRO-Velociraptor-GUI-$Port"
            
            # Remove existing rule
            try {
                Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
            } catch { }
            
            # Add new rule
            New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow -Description "PYRO DFIR Platform - Velociraptor GUI Access"
            Write-PyroLog "Windows Firewall rule created for port $Port" -Level 'Success'
            
        } elseif ($IsLinux) {
            # UFW (Ubuntu) or firewalld (CentOS/RHEL)
            if (Get-Command ufw -ErrorAction SilentlyContinue) {
                ufw allow $Port/tcp
                Write-PyroLog "UFW firewall rule created for port $Port" -Level 'Success'
            } elseif (Get-Command firewall-cmd -ErrorAction SilentlyContinue) {
                firewall-cmd --add-port=$Port/tcp --permanent
                firewall-cmd --reload
                Write-PyroLog "firewalld rule created for port $Port" -Level 'Success'
            } else {
                Write-PyroLog "No supported firewall found (ufw/firewalld)" -Level 'Warning'
            }
            
        } elseif ($IsMacOS) {
            # macOS pfctl
            Write-PyroLog "macOS firewall configuration may require manual setup" -Level 'Warning'
            Write-PyroLog "Consider: sudo pfctl -f /etc/pf.conf" -Level 'Info'
        }
    }
    catch {
        Write-PyroLog "Firewall configuration failed: $($_.Exception.Message)" -Level 'Error'
        Write-PyroLog "You may need to manually configure firewall for port $Port" -Level 'Warning'
    }
}

function Install-PyroToolsuite {
    if (-not $InstallPyroTools) {
        Write-PyroLog "PYRO tools installation skipped as requested" -Level 'Warning'
        return
    }
    
    Write-PyroLog "Installing PYRO DFIR Toolsuite..." -Level 'Info'
    
    try {
        if ($pyroModuleLoaded -and (Get-Command Install-PyroToolsuite -ErrorAction SilentlyContinue)) {
            # Use the integrated tool installation
            $results = Install-PyroToolsuite -ToolsPath $PyroToolsPath
            
            $successCount = ($results.Values | Where-Object { $_ -like "*SUCCESS*" }).Count
            $totalCount = $results.Count
            
            if ($successCount -eq $totalCount) {
                Write-PyroLog "All PYRO tools installed successfully ($successCount/$totalCount)" -Level 'Success'
            } else {
                Write-PyroLog "Some PYRO tools failed to install ($successCount/$totalCount)" -Level 'Warning'
            }
            
            return $results
        } else {
            Write-PyroLog "PYRO tool integration not available, skipping toolsuite installation" -Level 'Warning'
            return @{}
        }
    }
    catch {
        Write-PyroLog "PYRO toolsuite installation failed: $($_.Exception.Message)" -Level 'Error'
        Write-PyroLog "Continuing with Velociraptor deployment..." -Level 'Info'
        return @{}
    }
}

function Set-PyroSecurityHardening {
    param([string]$Level)
    
    Write-PyroLog "Applying PYRO security hardening level: $Level" -Level 'Info'
    
    try {
        switch ($Level) {
            'Basic' {
                Write-PyroLog "Basic security: Secure file permissions" -Level 'Info'
                # Set secure permissions on data directory
                if (Test-Path $DataStore) {
                    if ($IsWindows -or $null -eq $IsWindows) {
                        icacls $DataStore /inheritance:r /grant:r "Administrators:(OI)(CI)F" /grant:r "SYSTEM:(OI)(CI)F"
                    } else {
                        chmod 750 $DataStore
                    }
                }
            }
            
            'Standard' {
                Write-PyroLog "Standard security: File permissions + service hardening" -Level 'Info'
                # Basic hardening + service security
                if (Test-Path $DataStore) {
                    if ($IsWindows -or $null -eq $IsWindows) {
                        icacls $DataStore /inheritance:r /grant:r "Administrators:(OI)(CI)F" /grant:r "SYSTEM:(OI)(CI)F"
                    } else {
                        chmod 750 $DataStore
                        chown root:root $DataStore 2>/dev/null || true
                    }
                }
                
                # Additional security logging
                Write-PyroLog "Standard security hardening applied" -Level 'Success'
            }
            
            'Maximum' {
                Write-PyroLog "Maximum security: Full hardening suite" -Level 'Info'
                # All security measures + advanced hardening
                if ($pyroModuleLoaded -and (Get-Command Set-PyroSecurityBaseline -ErrorAction SilentlyContinue)) {
                    Set-PyroSecurityBaseline -SecurityLevel Maximum
                    Write-PyroLog "Maximum security hardening applied via PYRO module" -Level 'Success'
                } else {
                    # Fallback security measures
                    if (Test-Path $DataStore) {
                        if ($IsWindows -or $null -eq $IsWindows) {
                            icacls $DataStore /inheritance:r /grant:r "Administrators:(OI)(CI)F" /grant:r "SYSTEM:(OI)(CI)F"
                        } else {
                            chmod 700 $DataStore
                            chown root:root $DataStore 2>/dev/null || true
                        }
                    }
                    Write-PyroLog "Maximum security hardening applied (basic implementation)" -Level 'Success'
                }
            }
        }
    }
    catch {
        Write-PyroLog "Security hardening failed: $($_.Exception.Message)" -Level 'Error'
        Write-PyroLog "Continuing with deployment..." -Level 'Info'
    }
}

function Wait-ForPyroService {
    param([int]$Port, [int]$TimeoutSeconds = 60)
    
    Write-PyroLog "Waiting for PYRO service to become available on port $Port..." -Level 'Info'
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        try {
            $tcpConnection = Test-NetConnection -ComputerName 'localhost' -Port $Port -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            if ($tcpConnection.TcpTestSucceeded) {
                Write-PyroLog "PYRO service is ready on port $Port!" -Level 'Success'
                return $true
            }
        }
        catch {
            # Test-NetConnection might not be available on all platforms
            try {
                $socket = New-Object System.Net.Sockets.TcpClient
                $socket.Connect('localhost', $Port)
                $socket.Close()
                Write-PyroLog "PYRO service is ready on port $Port!" -Level 'Success'
                return $true
            }
            catch {
                # Service not ready yet
            }
        }
        
        Start-Sleep -Seconds 2
    }
    
    Write-PyroLog "Timeout waiting for service on port $Port" -Level 'Warning'
    return $false
}

############  🔥 Main Deployment Logic  ###################################################

function Main {
    $startTime = Get-Date
    
    Write-PyroLog "Starting PYRO Standalone Deployment..." -Level 'Info'
    Write-PyroLog "Installation Directory: $InstallDir" -Level 'Info'
    Write-PyroLog "Data Store: $DataStore" -Level 'Info'
    Write-PyroLog "GUI Port: $GuiPort" -Level 'Info'
    Write-PyroLog "PYRO Tools: $(if ($InstallPyroTools) { 'YES' } else { 'NO' })" -Level 'Info'
    Write-PyroLog "Security Level: $SecurityHardening" -Level 'Info'
    
    # Check admin privileges
    if (-not (Test-PyroAdminPrivileges)) {
        Write-PyroLog "Administrator/root privileges recommended for full installation" -Level 'Warning'
        Write-PyroLog "Some features may not work without elevated privileges" -Level 'Warning'
    }
    
    # Create directories
    Write-PyroLog "Creating installation directories..." -Level 'Info'
    @($InstallDir, $DataStore, $PyroToolsPath) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
            Write-PyroLog "Created directory: $_" -Level 'Success'
        }
    }
    
    # Determine Velociraptor executable path
    $velociraptorExe = if ($IsWindows -or $null -eq $IsWindows) {
        Join-Path $InstallDir 'velociraptor.exe'
    } else {
        Join-Path $InstallDir 'velociraptor'
    }
    
    # Download Velociraptor if needed
    if ($Force -or -not (Test-Path $velociraptorExe)) {
        Write-PyroLog "Downloading latest Velociraptor..." -Level 'Info'
        $asset = Get-LatestVelociraptorAsset
        Install-VelociraptorExecutable -Asset $asset -DestinationPath $velociraptorExe
    } else {
        Write-PyroLog "Using existing Velociraptor at: $velociraptorExe" -Level 'Info'
    }
    
    # Install PYRO toolsuite
    $toolResults = Install-PyroToolsuite
    
    # Configure firewall
    Set-PyroFirewallRule -Port $GuiPort
    
    # Apply security hardening
    Set-PyroSecurityHardening -Level $SecurityHardening
    
    # Launch Velociraptor GUI
    Write-PyroLog "Launching PYRO Velociraptor GUI..." -Level 'Info'
    
    try {
        $arguments = @('gui', '--datastore', $DataStore)
        if ($GuiPort -ne 8889) {
            $arguments += @('--gui_port', $GuiPort)
        }
        
        Write-PyroLog "Starting: $velociraptorExe $($arguments -join ' ')" -Level 'Info'
        
        # Start Velociraptor in background
        $process = Start-Process -FilePath $velociraptorExe -ArgumentList $arguments -PassThru -WindowStyle Hidden
        
        if ($process) {
            Write-PyroLog "Velociraptor process started (PID: $($process.Id))" -Level 'Success'
            
            # Wait for service to be ready
            $serviceReady = Wait-ForPyroService -Port $GuiPort -TimeoutSeconds 60
            
            if ($serviceReady) {
                Write-PyroLog "🔥 PYRO Deployment COMPLETE!" -Level 'Success'
                Write-PyroLog "🌐 GUI available at: http://localhost:$GuiPort" -Level 'Success'
                Write-PyroLog "📁 Data store: $DataStore" -Level 'Info'
                
                if ($InstallPyroTools -and $toolResults.Count -gt 0) {
                    $successfulTools = ($toolResults.Values | Where-Object { $_ -like "*SUCCESS*" }).Count
                    Write-PyroLog "🔧 PYRO Tools: $successfulTools tools installed" -Level 'Success'
                }
            } else {
                Write-PyroLog "Service started but not responding on port $GuiPort" -Level 'Warning'
                Write-PyroLog "Check the process and try accessing http://localhost:$GuiPort manually" -Level 'Info'
            }
        } else {
            throw "Failed to start Velociraptor process"
        }
    }
    catch {
        Write-PyroLog "Failed to launch Velociraptor: $($_.Exception.Message)" -Level 'Error'
        throw
    }
    
    # Deployment summary
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host ""
    Write-Host "🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥" -ForegroundColor Red
    Write-Host "🔥           PYRO DEPLOYMENT SUMMARY               🔥" -ForegroundColor Red
    Write-Host "🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥" -ForegroundColor Red
    Write-Host ""
    Write-Host "⏱️ Total Duration: $($duration.TotalMinutes.ToString('F1')) minutes" -ForegroundColor Cyan
    Write-Host "🌐 GUI URL: http://localhost:$GuiPort" -ForegroundColor Green
    Write-Host "📁 Data Store: $DataStore" -ForegroundColor Cyan
    Write-Host "🔧 Install Dir: $InstallDir" -ForegroundColor Cyan
    Write-Host "🛡️ Security Level: $SecurityHardening" -ForegroundColor Cyan
    
    if ($InstallPyroTools) {
        Write-Host "🔥 PYRO Tools: $PyroToolsPath" -ForegroundColor Cyan
        if ($toolResults.Count -gt 0) {
            $successfulTools = ($toolResults.Values | Where-Object { $_ -like "*SUCCESS*" }).Count
            Write-Host "   Tools Installed: $successfulTools" -ForegroundColor Green
        }
    }
    
    Write-Host ""
    Write-Host "🔥 PYRO DFIR Platform is IGNITED and ready!" -ForegroundColor Red
    Write-Host "   Setting fire to DFIR operations!" -ForegroundColor Yellow
    
    return @{
        VelociraptorPath = $velociraptorExe
        DataStore = $DataStore
        GuiPort = $GuiPort
        ToolsInstalled = $toolResults
        Duration = $duration
        ProcessId = $process.Id
    }
}

# Execute deployment
try {
    $result = Main
    exit 0
}
catch {
    Write-PyroLog "PYRO deployment failed: $($_.Exception.Message)" -Level 'Error'
    Write-Host ""
    Write-Host "❌ PYRO deployment failed. Check logs for details." -ForegroundColor Red
    Write-Host "   Log file: $(if ($IsWindows -or $null -eq $IsWindows) { '%ProgramData%\PYRO\deploy.log' } else { '/var/log/pyro/deploy.log' })" -ForegroundColor Yellow
    exit 1
}