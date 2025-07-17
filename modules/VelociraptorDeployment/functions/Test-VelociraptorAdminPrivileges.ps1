function Test-VelociraptorAdminPrivileges {
    <#
    .SYNOPSIS
        Tests if the current PowerShell session is running with Administrator privileges.

    .DESCRIPTION
        Checks if the current user context has Administrator privileges required for
        Velociraptor deployment operations. Can either return a boolean result or
        throw an exception based on parameters.

    .PARAMETER ThrowOnFailure
        If specified, throws an exception when not running as Administrator.
        Otherwise returns $false.

    .PARAMETER Quiet
        Suppresses warning messages when not running as Administrator.

    .EXAMPLE
        Test-VelociraptorAdminPrivileges -ThrowOnFailure
        # Throws exception if not Administrator

    .EXAMPLE
        if (-not (Test-VelociraptorAdminPrivileges)) {
            Write-Warning "Administrator privileges required"
            exit 1
        }

    .OUTPUTS
        System.Boolean
        Returns $true if running as Administrator, $false otherwise.

    .NOTES
        This function replaces the legacy Require-Admin function while maintaining compatibility.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter()]
        [switch]$ThrowOnFailure,
        
        [Parameter()]
        [switch]$Quiet
    )
    
    try {
        $currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
        
        if (-not $isAdmin) {
            $message = "Administrator privileges required. Please run PowerShell as Administrator."
            
            if ($ThrowOnFailure) {
                throw $message
            }
            
            if (-not $Quiet) {
                Write-VelociraptorLog $message -Level Warning
            }
            
            return $false
        }
        
        Write-VelociraptorLog "Administrator privileges confirmed" -Level Debug
        return $true
    }
    catch {
        $errorMessage = "Failed to check Administrator privileges: $($_.Exception.Message)"
        
        if ($ThrowOnFailure) {
            throw $errorMessage
        }
        
        if (-not $Quiet) {
            Write-VelociraptorLog $errorMessage -Level Error
        }
        
        return $false
    }
}