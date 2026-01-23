<#
.SYNOPSIS
    Gets real macOS system specifications.

.DESCRIPTION
    Implements macOS system detection using native tools:
    - sw_vers for OS version
    - sysctl for CPU and memory
    - system_profiler for hardware details
    - df for disk space

.EXAMPLE
    Get-MacOSSystemSpecs

.OUTPUTS
    PSCustomObject with system specifications
#>

function Get-MacOSSystemSpecs {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    if (-not $IsMacOS) {
        Write-Warning "This function is designed for macOS only"
        return $null
    }
    
    Write-Verbose "Detecting macOS system specifications..."
    
    $specs = [PSCustomObject]@{
        # OS Information
        OS = 'macOS'
        OSVersion = ''
        OSBuild = ''
        KernelVersion = ''
        
        # Hardware
        Architecture = ''
        HardwareModel = ''
        HardwareModelName = ''
        SerialNumber = ''
        
        # CPU
        CPUModel = ''
        CPUCores = 0
        CPUThreads = 0
        CPUFrequencyMHz = 0
        
        # Memory
        MemoryGB = 0
        MemoryBytes = 0
        
        # Disk
        DiskTotalGB = 0
        DiskFreeGB = 0
        DiskUsedGB = 0
        DiskUsedPercent = 0
        
        # Network
        Hostname = ''
        LocalIP = ''
        
        # User
        Username = ''
        UserHome = ''
        IsAdmin = $false
        
        # Timestamps
        DetectedAt = (Get-Date -Format 'o')
        Uptime = ''
    }
    
    #region OS Information
    try {
        $specs.OSVersion = (& sw_vers -productVersion).Trim()
        $specs.OSBuild = (& sw_vers -buildVersion).Trim()
        $specs.KernelVersion = (& uname -r).Trim()
    }
    catch {
        Write-Warning "Could not detect OS version: $_"
    }
    #endregion
    
    #region Hardware Information
    try {
        $specs.Architecture = (& uname -m).Trim()
        $specs.HardwareModel = (& sysctl -n hw.model).Trim()
        
        # Get friendly name from system_profiler
        $hwInfo = & system_profiler SPHardwareDataType 2>&1
        if ($hwInfo -match 'Model Name:\s*(.+)') {
            $specs.HardwareModelName = $Matches[1].Trim()
        }
        if ($hwInfo -match 'Serial Number \(system\):\s*(.+)') {
            $specs.SerialNumber = $Matches[1].Trim()
        }
    }
    catch {
        Write-Warning "Could not detect hardware info: $_"
    }
    #endregion
    
    #region CPU Information
    try {
        $specs.CPUModel = (& sysctl -n machdep.cpu.brand_string).Trim()
        $specs.CPUCores = [int](& sysctl -n hw.physicalcpu)
        $specs.CPUThreads = [int](& sysctl -n hw.logicalcpu)
        
        # CPU frequency (may not be available on Apple Silicon)
        try {
            $freqHz = [long](& sysctl -n hw.cpufrequency 2>&1)
            $specs.CPUFrequencyMHz = [math]::Round($freqHz / 1000000, 0)
        }
        catch {
            # Apple Silicon doesn't expose this
            $specs.CPUFrequencyMHz = 0
        }
    }
    catch {
        Write-Warning "Could not detect CPU info: $_"
        $specs.CPUModel = "Unknown"
        $specs.CPUCores = 1
        $specs.CPUThreads = 1
    }
    #endregion
    
    #region Memory Information
    try {
        $specs.MemoryBytes = [long](& sysctl -n hw.memsize)
        $specs.MemoryGB = [math]::Round($specs.MemoryBytes / 1GB, 2)
    }
    catch {
        Write-Warning "Could not detect memory: $_"
    }
    #endregion
    
    #region Disk Information
    try {
        $dfOutput = & df -g / | Select-Object -Skip 1
        $dfParts = ($dfOutput.Trim() -split '\s+')
        
        $specs.DiskTotalGB = [int]$dfParts[1]
        $specs.DiskUsedGB = [int]$dfParts[2]
        $specs.DiskFreeGB = [int]$dfParts[3]
        
        if ($specs.DiskTotalGB -gt 0) {
            $specs.DiskUsedPercent = [math]::Round(($specs.DiskUsedGB / $specs.DiskTotalGB) * 100, 1)
        }
    }
    catch {
        Write-Warning "Could not detect disk space: $_"
    }
    #endregion
    
    #region Network Information
    try {
        $specs.Hostname = (& hostname).Trim()
        
        # Get primary IP
        $ipOutput = & ipconfig getifaddr en0 2>&1
        if ($LASTEXITCODE -eq 0) {
            $specs.LocalIP = $ipOutput.Trim()
        }
        else {
            # Try en1 (WiFi on some Macs)
            $ipOutput = & ipconfig getifaddr en1 2>&1
            if ($LASTEXITCODE -eq 0) {
                $specs.LocalIP = $ipOutput.Trim()
            }
        }
    }
    catch {
        Write-Warning "Could not detect network info: $_"
    }
    #endregion
    
    #region User Information
    try {
        $specs.Username = $env:USER
        $specs.UserHome = $env:HOME
        
        # Check admin membership
        $groups = & id -Gn
        $specs.IsAdmin = $groups -match '\badmin\b'
    }
    catch {
        Write-Warning "Could not detect user info: $_"
    }
    #endregion
    
    #region Uptime
    try {
        $bootTime = & sysctl -n kern.boottime
        if ($bootTime -match 'sec = (\d+)') {
            $bootEpoch = [long]$Matches[1]
            $bootDate = [DateTimeOffset]::FromUnixTimeSeconds($bootEpoch).LocalDateTime
            $uptime = (Get-Date) - $bootDate
            $specs.Uptime = '{0}d {1}h {2}m' -f $uptime.Days, $uptime.Hours, $uptime.Minutes
        }
    }
    catch {
        Write-Warning "Could not detect uptime: $_"
    }
    #endregion
    
    return $specs
}

# Export function
Export-ModuleMember -Function Get-MacOSSystemSpecs
