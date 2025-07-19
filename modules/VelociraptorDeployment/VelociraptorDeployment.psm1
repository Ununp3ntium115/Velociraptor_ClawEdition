#Requires -Version 5.1

<#
.SYNOPSIS
    VelociraptorDeployment PowerShell Module

.DESCRIPTION
    This module provides comprehensive functions for Velociraptor deployment,
    configuration, and management operations. It standardizes common operations
    across all Velociraptor setup scripts while maintaining backward compatibility.

.NOTES
    Author: Velociraptor Community
    Version: 1.0.0
    Requires: PowerShell 5.1 or higher
#>

# Set strict mode for better error handling
Set-StrictMode -Version Latest

# Module variables
$script:ModuleRoot = $PSScriptRoot
$script:LogPath = $null
$script:VerboseLogging = $false

# Import all function files
$functionPath = Join-Path $script:ModuleRoot 'functions'
if (Test-Path $functionPath) {
    $functionFiles = Get-ChildItem -Path $functionPath -Filter '*.ps1' -Recurse
    foreach ($file in $functionFiles) {
        try {
            . $file.FullName
            Write-Verbose "Imported function file: $($file.Name)"
        }
        catch {
            Write-Error "Failed to import function file $($file.Name): $($_.Exception.Message)"
        }
    }
}

# Create backward compatibility aliases
$aliases = @{
    'Log' = 'Write-VelociraptorLog'
    'Write-Log' = 'Write-VelociraptorLog'
    'Require-Admin' = 'Test-VelociraptorAdminPrivileges'
    'Test-Admin' = 'Test-VelociraptorAdminPrivileges'
    'Latest-WindowsAsset' = 'Get-VelociraptorLatestRelease'
    'Download-EXE' = 'Invoke-VelociraptorDownload'
    'Ask' = 'Read-VelociraptorUserInput'
    'AskSecret' = 'Read-VelociraptorSecureInput'
    'Wait-Port' = 'Wait-VelociraptorTcpPort'
    'Manage-VelociraptorCollections' = 'Invoke-VelociraptorCollections'
}

foreach ($alias in $aliases.GetEnumerator()) {
    try {
        Set-Alias -Name $alias.Key -Value $alias.Value -Scope Global -Force
        Write-Verbose "Created alias: $($alias.Key) -> $($alias.Value)"
    }
    catch {
        Write-Warning "Failed to create alias $($alias.Key): $($_.Exception.Message)"
    }
}

# Module initialization
Write-Verbose "VelociraptorDeployment module loaded successfully"

# Export module members (functions are exported via manifest)
Export-ModuleMember -Function * -Alias *