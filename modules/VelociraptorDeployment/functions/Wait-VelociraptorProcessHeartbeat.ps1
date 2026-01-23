function Wait-VelociraptorProcessHeartbeat {
    <#
    .SYNOPSIS
        Waits for Velociraptor process to complete before allowing re-execution.

    .DESCRIPTION
        Monitors Velociraptor processes with heartbeat checking to ensure a process
        has completed before allowing the deployment to run again. This prevents
        concurrent execution issues and ensures clean state between runs.

    .PARAMETER ProcessName
        The process name to monitor. Default is 'velociraptor'.

    .PARAMETER ProcessId
        Specific process ID to monitor. If not provided, monitors all matching processes.

    .PARAMETER TimeoutSeconds
        Maximum time to wait for process completion in seconds. Default is 300 (5 minutes).

    .PARAMETER HeartbeatIntervalSeconds
        Interval between heartbeat checks in seconds. Default is 5 seconds.

    .PARAMETER Action
        Action to take: 'Wait' to wait for completion, 'Check' to only check status,
        'Kill' to terminate and wait. Default is 'Wait'.

    .PARAMETER Force
        When used with -Action Kill, forcefully terminates the process.

    .PARAMETER ShowProgress
        Display progress bar while waiting.

    .EXAMPLE
        Wait-VelociraptorProcessHeartbeat
        # Waits for any velociraptor process to complete

    .EXAMPLE
        Wait-VelociraptorProcessHeartbeat -ProcessId 1234 -TimeoutSeconds 600 -ShowProgress
        # Waits up to 10 minutes for specific process with progress display

    .EXAMPLE
        Wait-VelociraptorProcessHeartbeat -Action Check
        # Returns current status without waiting

    .EXAMPLE
        Wait-VelociraptorProcessHeartbeat -Action Kill -Force
        # Terminates any running velociraptor processes and waits for cleanup

    .OUTPUTS
        PSCustomObject with properties:
        - IsComplete: Boolean indicating if process has completed
        - WasRunning: Boolean indicating if process was found running
        - ProcessInfo: Array of process information if found
        - ElapsedSeconds: Time spent waiting
        - Message: Status message

    .NOTES
        This function implements heartbeat-based process monitoring to ensure
        deployment scripts wait for previous executions to complete before
        starting new ones.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [string]$ProcessName = 'velociraptor',

        [Parameter()]
        [int]$ProcessId,

        [Parameter()]
        [ValidateRange(1, 3600)]
        [int]$TimeoutSeconds = 300,

        [Parameter()]
        [ValidateRange(1, 60)]
        [int]$HeartbeatIntervalSeconds = 5,

        [Parameter()]
        [ValidateSet('Wait', 'Check', 'Kill')]
        [string]$Action = 'Wait',

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$ShowProgress
    )

    # Initialize result object
    $result = [PSCustomObject]@{
        IsComplete      = $false
        WasRunning      = $false
        ProcessInfo     = @()
        ElapsedSeconds  = 0
        Message         = ''
        HeartbeatCount  = 0
    }

    try {
        Write-VelociraptorLog "Starting process heartbeat monitoring for '$ProcessName' (Action: $Action, Timeout: ${TimeoutSeconds}s)" -Level Info

        $startTime = Get-Date
        $endTime = $startTime.AddSeconds($TimeoutSeconds)
        $heartbeatCount = 0
        $maxHeartbeats = [math]::Ceiling($TimeoutSeconds / $HeartbeatIntervalSeconds)

        # Function to get running processes
        $getProcesses = {
            $processes = @()

            if ($ProcessId) {
                # Monitor specific process
                $proc = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
                if ($proc) {
                    $processes += $proc
                }
            }
            else {
                # Monitor by name
                $procs = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
                if ($procs) {
                    $processes += $procs
                }

                # Also check for service processes
                $serviceProcs = Get-Process | Where-Object {
                    $_.ProcessName -like "*$ProcessName*" -or
                    $_.MainWindowTitle -like "*$ProcessName*"
                } -ErrorAction SilentlyContinue

                if ($serviceProcs) {
                    foreach ($sp in $serviceProcs) {
                        if ($sp.Id -notin $processes.Id) {
                            $processes += $sp
                        }
                    }
                }
            }

            return $processes
        }

        # Initial check
        $runningProcesses = & $getProcesses
        $result.WasRunning = $runningProcesses.Count -gt 0

        if ($runningProcesses.Count -gt 0) {
            $result.ProcessInfo = $runningProcesses | ForEach-Object {
                [PSCustomObject]@{
                    Id          = $_.Id
                    Name        = $_.ProcessName
                    StartTime   = $_.StartTime
                    CPU         = $_.CPU
                    Memory      = [math]::Round($_.WorkingSet64 / 1MB, 2)
                    Responding  = $_.Responding
                }
            }

            Write-VelociraptorLog "Found $($runningProcesses.Count) running process(es): $($runningProcesses.Id -join ', ')" -Level Info
        }
        else {
            Write-VelociraptorLog "No running '$ProcessName' processes found" -Level Info
            $result.IsComplete = $true
            $result.Message = "No processes running - safe to proceed"
            return $result
        }

        # Handle different actions
        switch ($Action) {
            'Check' {
                # Just return current status
                $result.Message = "Process check completed - $($runningProcesses.Count) process(es) running"
                $result.ElapsedSeconds = ((Get-Date) - $startTime).TotalSeconds
                return $result
            }

            'Kill' {
                # Terminate processes
                Write-VelociraptorLog "Attempting to terminate $($runningProcesses.Count) process(es)..." -Level Warning

                foreach ($proc in $runningProcesses) {
                    try {
                        if ($Force) {
                            $proc | Stop-Process -Force -ErrorAction Stop
                            Write-VelociraptorLog "Forcefully terminated process $($proc.Id)" -Level Warning
                        }
                        else {
                            $proc | Stop-Process -ErrorAction Stop
                            Write-VelociraptorLog "Terminated process $($proc.Id)" -Level Info
                        }
                    }
                    catch {
                        Write-VelociraptorLog "Failed to terminate process $($proc.Id): $($_.Exception.Message)" -Level Error
                    }
                }

                # Continue to wait loop to confirm termination
            }

            'Wait' {
                # Continue to wait loop
            }
        }

        # Heartbeat wait loop
        while ((Get-Date) -lt $endTime) {
            $heartbeatCount++
            $result.HeartbeatCount = $heartbeatCount

            # Show progress if requested
            if ($ShowProgress) {
                $elapsed = ((Get-Date) - $startTime).TotalSeconds
                $percentComplete = [math]::Min(($elapsed / $TimeoutSeconds) * 100, 100)

                Write-Progress -Activity "Waiting for process completion" `
                    -Status "Heartbeat $heartbeatCount of $maxHeartbeats - Checking processes..." `
                    -PercentComplete $percentComplete
            }

            # Heartbeat check
            $currentProcesses = & $getProcesses

            if ($currentProcesses.Count -eq 0) {
                # All processes completed
                if ($ShowProgress) {
                    Write-Progress -Activity "Waiting for process completion" -Completed
                }

                $elapsed = ((Get-Date) - $startTime).TotalSeconds
                $result.IsComplete = $true
                $result.ElapsedSeconds = $elapsed
                $result.Message = "Process completed after $([math]::Round($elapsed, 1))s ($heartbeatCount heartbeats)"

                Write-VelociraptorLog $result.Message -Level Success
                return $result
            }

            # Log heartbeat status
            $processIds = $currentProcesses.Id -join ', '
            Write-VelociraptorLog "Heartbeat #$heartbeatCount`: Process(es) still running (PIDs: $processIds)" -Level Debug

            # Update process info with current state
            $result.ProcessInfo = $currentProcesses | ForEach-Object {
                [PSCustomObject]@{
                    Id          = $_.Id
                    Name        = $_.ProcessName
                    StartTime   = $_.StartTime
                    CPU         = $_.CPU
                    Memory      = [math]::Round($_.WorkingSet64 / 1MB, 2)
                    Responding  = $_.Responding
                }
            }

            # Check for hung processes
            $hungProcesses = $currentProcesses | Where-Object { -not $_.Responding }
            if ($hungProcesses.Count -gt 0) {
                Write-VelociraptorLog "Warning: $($hungProcesses.Count) process(es) not responding (PIDs: $($hungProcesses.Id -join ', '))" -Level Warning
            }

            # Wait for next heartbeat
            Start-Sleep -Seconds $HeartbeatIntervalSeconds
        }

        # Timeout reached
        if ($ShowProgress) {
            Write-Progress -Activity "Waiting for process completion" -Completed
        }

        $elapsed = ((Get-Date) - $startTime).TotalSeconds
        $result.ElapsedSeconds = $elapsed
        $result.Message = "Timeout after ${TimeoutSeconds}s - process(es) still running"

        Write-VelociraptorLog $result.Message -Level Warning
        return $result
    }
    catch {
        if ($ShowProgress) {
            Write-Progress -Activity "Waiting for process completion" -Completed
        }

        $errorMessage = "Error during process heartbeat monitoring: $($_.Exception.Message)"
        Write-VelociraptorLog $errorMessage -Level Error

        $result.Message = $errorMessage
        $result.ElapsedSeconds = ((Get-Date) - $startTime).TotalSeconds
        return $result
    }
}

# Alias for backward compatibility
Set-Alias -Name Wait-ProcessHeartbeat -Value Wait-VelociraptorProcessHeartbeat -Scope Global
