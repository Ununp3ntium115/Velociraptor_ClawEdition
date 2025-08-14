function Add-VelociraptorFirewallRule {
    <#
    .SYNOPSIS
        Adds Windows Firewall rules for Velociraptor services.

    .DESCRIPTION
        Creates inbound firewall rules to allow Velociraptor traffic on specified ports.
        Supports both modern PowerShell cmdlets and legacy netsh commands for compatibility.

    .PARAMETER Port
        The TCP port number to allow through the firewall.

    .PARAMETER RuleName
        Custom name for the firewall rule. If not specified, generates a default name.

    .PARAMETER Direction
        Traffic direction (Inbound or Outbound). Default is Inbound.

    .PARAMETER Protocol
        Network protocol (TCP or UDP). Default is TCP.

    .PARAMETER Force
        Remove existing rule with the same name before creating new one.

    .EXAMPLE
        Add-VelociraptorFirewallRule -Port 8889
        # Adds inbound TCP rule for Velociraptor GUI

    .EXAMPLE
        Add-VelociraptorFirewallRule -Port 8000 -RuleName "Velociraptor Frontend" -Force

    .OUTPUTS
        PSCustomObject with rule creation results.

    .NOTES
        Requires Administrator privileges. Falls back to netsh on older systems.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateRange(1, 65535)]
        [int]$Port,

        [Parameter()]
        [string]$RuleName,

        [Parameter()]
        [ValidateSet('Inbound', 'Outbound')]
        [string]$Direction = 'Inbound',

        [Parameter()]
        [ValidateSet('TCP', 'UDP')]
        [string]$Protocol = 'TCP',

        [Parameter()]
        [switch]$Force
    )

    # Test admin privileges
    if (-not (Test-VelociraptorAdminPrivileges -Quiet)) {
        throw "Administrator privileges required to modify firewall rules"
    }

    try {
        # Generate rule name if not provided
        if (-not $RuleName) {
            $RuleName = "Velociraptor $Protocol $Port ($Direction)"
        }

        Write-VelociraptorLog "Adding firewall rule: $RuleName" -Level Info

        # Check if rule already exists
        $existingRule = $null
        $ruleExists = $false

        try {
            if (Get-Command Get-NetFirewallRule -ErrorAction SilentlyContinue) {
                $existingRule = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue
                $ruleExists = $null -ne $existingRule
            }
        }
        catch {
            # Ignore errors when checking for existing rules
        }

        if ($ruleExists) {
            if ($Force) {
                Write-VelociraptorLog "Removing existing rule: $RuleName" -Level Debug
                try {
                    Remove-NetFirewallRule -DisplayName $RuleName -ErrorAction Stop
                }
                catch {
                    Write-VelociraptorLog "Failed to remove existing rule, continuing..." -Level Warning
                }
            } else {
                Write-VelociraptorLog "Firewall rule '$RuleName' already exists - skipping" -Level Warning
                return [PSCustomObject]@{
                    Success = $true
                    RuleName = $RuleName
                    Port = $Port
                    Protocol = $Protocol
                    Direction = $Direction
                    Method = "Existing"
                    Message = "Rule already exists"
                }
            }
        }

        # Try modern PowerShell method first
        $success = $false
        $method = ""
        $errorMessage = ""

        if (Get-Command New-NetFirewallRule -ErrorAction SilentlyContinue) {
            try {
                $ruleParams = @{
                    DisplayName = $RuleName
                    Direction = $Direction
                    Action = 'Allow'
                    Protocol = $Protocol
                    LocalPort = $Port
                    ErrorAction = 'Stop'
                }

                New-NetFirewallRule @ruleParams | Out-Null
                $success = $true
                $method = "PowerShell"
                Write-VelociraptorLog "Firewall rule added via New-NetFirewallRule ($Protocol $Port)" -Level Success
            }
            catch {
                $errorMessage = $_.Exception.Message
                Write-VelociraptorLog "PowerShell method failed: $errorMessage" -Level Debug
            }
        }

        # Fallback to netsh for older systems
        if (-not $success) {
            try {
                $netshDirection = if ($Direction -eq 'Inbound') { 'in' } else { 'out' }
                $netshCmd = "netsh advfirewall firewall add rule name=`"$RuleName`" dir=$netshDirection action=allow protocol=$Protocol localport=$Port"

                Write-VelociraptorLog "Attempting netsh fallback..." -Level Debug
                $netshResult = Invoke-Expression $netshCmd 2>&1

                if ($LASTEXITCODE -eq 0) {
                    $success = $true
                    $method = "netsh"
                    Write-VelociraptorLog "Firewall rule added via netsh ($Protocol $Port)" -Level Success
                } else {
                    $errorMessage = "netsh command failed: $netshResult"
                }
            }
            catch {
                $errorMessage = "netsh fallback failed: $($_.Exception.Message)"
            }
        }

        # Return result
        if ($success) {
            return [PSCustomObject]@{
                Success = $true
                RuleName = $RuleName
                Port = $Port
                Protocol = $Protocol
                Direction = $Direction
                Method = $method
                Message = "Rule created successfully"
            }
        } else {
            throw $errorMessage
        }
    }
    catch {
        $errorMsg = "Failed to add firewall rule: $($_.Exception.Message)"
        Write-VelociraptorLog $errorMsg -Level Error

        return [PSCustomObject]@{
            Success = $false
            RuleName = $RuleName
            Port = $Port
            Protocol = $Protocol
            Direction = $Direction
            Method = "Failed"
            Message = $_.Exception.Message
        }
    }
}