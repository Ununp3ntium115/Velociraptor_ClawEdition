function Write-VelociraptorLog {
    <#
    .SYNOPSIS
        Enhanced logging function for Velociraptor deployment operations.

    .DESCRIPTION
        Provides comprehensive logging capabilities with multiple output options,
        log levels, and formatting. Supports both console and file output with
        timestamps and structured formatting.

    .PARAMETER Message
        The message to log.

    .PARAMETER Level
        The log level (Info, Warning, Error, Success, Debug, Verbose).

    .PARAMETER LogPath
        Optional path to log file. If not specified, uses default location.

    .PARAMETER NoTimestamp
        Skip adding timestamp to the log entry.

    .PARAMETER NoConsole
        Skip writing to console output.

    .PARAMETER Component
        Optional component name for structured logging.

    .EXAMPLE
        Write-VelociraptorLog "Starting deployment process"

    .EXAMPLE
        Write-VelociraptorLog "Configuration validated successfully" -Level Success

    .EXAMPLE
        Write-VelociraptorLog "Failed to connect to server" -Level Error -Component "Network"

    .NOTES
        This function replaces the legacy Log function while maintaining compatibility.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Debug', 'Verbose')]
        [string]$Level = 'Info',
        
        [Parameter()]
        [string]$LogPath,
        
        [Parameter()]
        [switch]$NoTimestamp,
        
        [Parameter()]
        [switch]$NoConsole,
        
        [Parameter()]
        [string]$Component
    )
    
    # Determine log file path with cross-platform support
    if (-not $LogPath) {
        # Cross-platform log directory selection (PowerShell 5.1+ compatible)
        if ($env:OS -eq "Windows_NT" -or [System.Environment]::OSVersion.Platform -eq "Win32NT") {
            $logDir = Join-Path $env:ProgramData 'VelociraptorDeploy'
        } elseif ($env:HOME) {
            $logDir = Join-Path $env:HOME '.velociraptor'
        } else {
            $logDir = Join-Path '/tmp' 'velociraptor'
        }
        
        if (-not (Test-Path $logDir)) {
            try {
                New-Item -ItemType Directory -Path $logDir -Force | Out-Null
            }
            catch {
                Write-Warning "Could not create log directory: $logDir"
                # Fallback to temp directory
                $logDir = if ($env:TEMP) { $env:TEMP } elseif ($env:TMPDIR) { $env:TMPDIR } else { '/tmp' }
            }
        }
        $LogPath = Join-Path $logDir 'velociraptor_deployment.log'
    }
    
    # Format timestamp
    $timestamp = if (-not $NoTimestamp) {
        Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    } else {
        $null
    }
    
    # Format component
    $componentText = if ($Component) {
        "[$Component]"
    } else {
        ""
    }
    
    # Create log entry (PowerShell 5.1+ compatible)
    $logEntry = (@(
        $timestamp,
        "[$Level]",
        $componentText,
        $Message
    ) | Where-Object { $_ }) -join ' '
    
    # Write to file
    try {
        $logEntry | Out-File -FilePath $LogPath -Append -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch {
        # Silently continue if file logging fails
    }
    
    # Write to console unless suppressed
    if (-not $NoConsole) {
        $consoleMessage = if ($NoTimestamp -and -not $Component) {
            $Message
        } else {
            $logEntry
        }
        
        switch ($Level) {
            'Success' { 
                Write-Host $consoleMessage -ForegroundColor Green 
            }
            'Warning' { 
                Write-Host $consoleMessage -ForegroundColor Yellow 
            }
            'Error' { 
                Write-Host $consoleMessage -ForegroundColor Red 
            }
            'Debug' { 
                if ($DebugPreference -ne 'SilentlyContinue') {
                    Write-Host $consoleMessage -ForegroundColor Cyan
                }
            }
            'Verbose' { 
                if ($VerbosePreference -ne 'SilentlyContinue') {
                    Write-Host $consoleMessage -ForegroundColor Magenta
                }
            }
            default { 
                Write-Host $consoleMessage -ForegroundColor White 
            }
        }
    }
    
    # Also write to appropriate PowerShell streams
    switch ($Level) {
        'Warning' { Write-Warning $Message }
        'Error' { Write-Error $Message -ErrorAction Continue }
        'Debug' { Write-Debug $Message }
        'Verbose' { Write-Verbose $Message }
    }
}