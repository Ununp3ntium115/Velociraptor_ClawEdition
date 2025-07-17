function Wait-VelociraptorTcpPort {
    <#
    .SYNOPSIS
        Waits for a TCP port to become available or listening.

    .DESCRIPTION
        Monitors a TCP port until it becomes available (listening) or times out.
        Useful for waiting for Velociraptor services to start up completely.

    .PARAMETER Port
        The TCP port number to monitor.

    .PARAMETER TimeoutSeconds
        Maximum time to wait in seconds. Default is 30 seconds.

    .PARAMETER IntervalSeconds
        Check interval in seconds. Default is 1 second.

    .PARAMETER ComputerName
        Target computer name or IP address. Default is localhost.

    .PARAMETER ShowProgress
        Display progress bar while waiting.

    .EXAMPLE
        Wait-VelociraptorTcpPort -Port 8889
        # Waits for port 8889 to become available

    .EXAMPLE
        Wait-VelociraptorTcpPort -Port 8000 -TimeoutSeconds 60 -ShowProgress

    .OUTPUTS
        System.Boolean
        Returns $true if port becomes available, $false if timeout occurs.

    .NOTES
        This function replaces the legacy Wait-Port function with enhanced capabilities.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateRange(1, 65535)]
        [int]$Port,
        
        [Parameter()]
        [ValidateRange(1, 3600)]
        [int]$TimeoutSeconds = 30,
        
        [Parameter()]
        [ValidateRange(1, 60)]
        [int]$IntervalSeconds = 1,
        
        [Parameter()]
        [string]$ComputerName = 'localhost',
        
        [Parameter()]
        [switch]$ShowProgress
    )
    
    try {
        Write-VelociraptorLog "Waiting for TCP port $Port on $ComputerName (timeout: ${TimeoutSeconds}s)" -Level Info
        
        $startTime = Get-Date
        $endTime = $startTime.AddSeconds($TimeoutSeconds)
        $attempt = 0
        $maxAttempts = [math]::Ceiling($TimeoutSeconds / $IntervalSeconds)
        
        while ((Get-Date) -lt $endTime) {
            $attempt++
            
            # Show progress if requested
            if ($ShowProgress) {
                $elapsed = ((Get-Date) - $startTime).TotalSeconds
                $percentComplete = [math]::Min(($elapsed / $TimeoutSeconds) * 100, 100)
                
                Write-Progress -Activity "Waiting for TCP Port $Port" -Status "Attempt $attempt of $maxAttempts" -PercentComplete $percentComplete
            }
            
            # Check if port is listening
            $portAvailable = $false
            
            try {
                # Try modern method first (Windows 8/Server 2012+)
                if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
                    $connection = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
                    $portAvailable = $null -ne $connection
                }
                
                # Fallback method using Test-NetConnection (if available)
                if (-not $portAvailable -and (Get-Command Test-NetConnection -ErrorAction SilentlyContinue)) {
                    $testResult = Test-NetConnection -ComputerName $ComputerName -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
                    $portAvailable = $testResult
                }
                
                # Final fallback using System.Net.Sockets.TcpClient
                if (-not $portAvailable) {
                    $tcpClient = New-Object System.Net.Sockets.TcpClient
                    try {
                        $tcpClient.Connect($ComputerName, $Port)
                        $portAvailable = $tcpClient.Connected
                    }
                    catch {
                        $portAvailable = $false
                    }
                    finally {
                        $tcpClient.Close()
                        $tcpClient.Dispose()
                    }
                }
            }
            catch {
                Write-VelociraptorLog "Error checking port $Port`: $($_.Exception.Message)" -Level Debug
                $portAvailable = $false
            }
            
            if ($portAvailable) {
                if ($ShowProgress) {
                    Write-Progress -Activity "Waiting for TCP Port $Port" -Completed
                }
                
                $elapsed = ((Get-Date) - $startTime).TotalSeconds
                Write-VelociraptorLog "Port $Port is now available (took $([math]::Round($elapsed, 1))s)" -Level Success
                return $true
            }
            
            # Wait before next attempt
            Start-Sleep -Seconds $IntervalSeconds
        }
        
        # Timeout reached
        if ($ShowProgress) {
            Write-Progress -Activity "Waiting for TCP Port $Port" -Completed
        }
        
        Write-VelociraptorLog "Timeout waiting for port $Port after ${TimeoutSeconds}s" -Level Warning
        return $false
    }
    catch {
        if ($ShowProgress) {
            Write-Progress -Activity "Waiting for TCP Port $Port" -Completed
        }
        
        $errorMessage = "Error waiting for port $Port`: $($_.Exception.Message)"
        Write-VelociraptorLog $errorMessage -Level Error
        return $false
    }
}