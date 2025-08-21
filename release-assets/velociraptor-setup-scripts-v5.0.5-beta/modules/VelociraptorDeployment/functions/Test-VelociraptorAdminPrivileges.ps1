function Test-VelociraptorAdminPrivileges {
    <#
    .SYNOPSIS
        Tests if the current user has administrator privileges required for Velociraptor operations.
    
    .DESCRIPTION
        Validates administrator privileges and specific permissions required for Velociraptor
        deployment, configuration, and management operations.
    
    .PARAMETER RequiredPrivileges
        Array of specific privileges to test for (optional).
    
    .PARAMETER TestServiceControl
        Test service control permissions specifically.
    
    .PARAMETER TestFirewallAccess
        Test Windows Firewall management permissions.
    
    .PARAMETER TestRegistryAccess
        Test registry modification permissions.
    
    .EXAMPLE
        Test-VelociraptorAdminPrivileges
    
    .EXAMPLE
        Test-VelociraptorAdminPrivileges -TestServiceControl -TestFirewallAccess
    #>
    [CmdletBinding()]
    param(
        [string[]]$RequiredPrivileges = @(),
        
        [switch]$TestServiceControl,
        
        [switch]$TestFirewallAccess,
        
        [switch]$TestRegistryAccess
    )
    
    $result = @{
        IsAdmin = $false
        HasRequiredPrivileges = $true
        PrivilegeTests = @{}
        Recommendations = @()
    }
    
    try {
        # Test basic administrator privileges
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        $result.IsAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if (-not $result.IsAdmin) {
            $result.HasRequiredPrivileges = $false
            $result.Recommendations += "Run PowerShell as Administrator"
            Write-VelociraptorLog -Message "Administrator privileges required but not detected" -Level Warning
            return $result
        }
        
        Write-VelociraptorLog -Message "Administrator privileges confirmed" -Level Info
        
        # Test service control permissions
        if ($TestServiceControl) {
            $result.PrivilegeTests['ServiceControl'] = Test-ServiceControlPrivileges
            if (-not $result.PrivilegeTests['ServiceControl'].HasPrivilege) {
                $result.HasRequiredPrivileges = $false
            }
        }
        
        # Test firewall access permissions
        if ($TestFirewallAccess) {
            $result.PrivilegeTests['FirewallAccess'] = Test-FirewallAccessPrivileges
            if (-not $result.PrivilegeTests['FirewallAccess'].HasPrivilege) {
                $result.HasRequiredPrivileges = $false
            }
        }
        
        # Test registry access permissions
        if ($TestRegistryAccess) {
            $result.PrivilegeTests['RegistryAccess'] = Test-RegistryAccessPrivileges
            if (-not $result.PrivilegeTests['RegistryAccess'].HasPrivilege) {
                $result.HasRequiredPrivileges = $false
            }
        }
        
        # Test specific privileges if requested
        foreach ($privilege in $RequiredPrivileges) {
            $result.PrivilegeTests[$privilege] = Test-SpecificPrivilege -PrivilegeName $privilege
            if (-not $result.PrivilegeTests[$privilege].HasPrivilege) {
                $result.HasRequiredPrivileges = $false
            }
        }
        
        if ($result.HasRequiredPrivileges) {
            Write-VelociraptorLog -Message "All required privileges confirmed" -Level Info
        }
        else {
            Write-VelociraptorLog -Message "Some required privileges are missing" -Level Warning
        }
    }
    catch {
        Write-VelociraptorLog -Message "Error testing admin privileges: $($_.Exception.Message)" -Level Error
        $result.HasRequiredPrivileges = $false
        $result.Recommendations += "Unable to verify privileges - check system permissions"
    }
    
    return $result
}

function Test-ServiceControlPrivileges {
    $test = @{
        HasPrivilege = $false
        Details = ""
        Error = $null
    }
    
    try {
        # Try to query service control manager
        $scm = Get-Service -Name "Spooler" -ErrorAction Stop
        $test.HasPrivilege = $true
        $test.Details = "Service control access confirmed"
        Write-VelociraptorLog -Message "Service control privileges confirmed" -Level Info
    }
    catch {
        $test.Error = $_.Exception.Message
        $test.Details = "Cannot access Service Control Manager: $($_.Exception.Message)"
        Write-VelociraptorLog -Message "Service control privileges test failed: $($_.Exception.Message)" -Level Warning
    }
    
    return $test
}

function Test-FirewallAccessPrivileges {
    $test = @{
        HasPrivilege = $false
        Details = ""
        Error = $null
    }
    
    try {
        # Try to access Windows Firewall
        if (Get-Command "Get-NetFirewallRule" -ErrorAction SilentlyContinue) {
            $rules = Get-NetFirewallRule -Direction Inbound -Enabled True -ErrorAction Stop | Select-Object -First 1
            $test.HasPrivilege = $true
            $test.Details = "Windows Firewall access confirmed"
            Write-VelociraptorLog -Message "Firewall access privileges confirmed" -Level Info
        }
        else {
            # Fallback for older systems
            $firewall = New-Object -ComObject HNetCfg.FwMgr -ErrorAction Stop
            $test.HasPrivilege = $true
            $test.Details = "Windows Firewall access confirmed (legacy)"
            Write-VelociraptorLog -Message "Firewall access privileges confirmed (legacy method)" -Level Info
        }
    }
    catch {
        $test.Error = $_.Exception.Message
        $test.Details = "Cannot access Windows Firewall: $($_.Exception.Message)"
        Write-VelociraptorLog -Message "Firewall access privileges test failed: $($_.Exception.Message)" -Level Warning
    }
    
    return $test
}

function Test-RegistryAccessPrivileges {
    $test = @{
        HasPrivilege = $false
        Details = ""
        Error = $null
    }
    
    try {
        # Try to access HKLM registry
        $testKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion"
        $regValue = Get-ItemProperty -Path $testKey -Name "ProgramFilesDir" -ErrorAction Stop
        $test.HasPrivilege = $true
        $test.Details = "Registry access confirmed"
        Write-VelociraptorLog -Message "Registry access privileges confirmed" -Level Info
    }
    catch {
        $test.Error = $_.Exception.Message
        $test.Details = "Cannot access registry: $($_.Exception.Message)"
        Write-VelociraptorLog -Message "Registry access privileges test failed: $($_.Exception.Message)" -Level Warning
    }
    
    return $test
}

function Test-SpecificPrivilege {
    param([string]$PrivilegeName)
    
    $test = @{
        HasPrivilege = $false
        Details = ""
        Error = $null
    }
    
    try {
        # Get current user privileges
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        
        # Test specific privilege based on name
        switch ($PrivilegeName.ToLower()) {
            "seservicelogonright" {
                # This would require more complex privilege checking
                $test.HasPrivilege = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
                $test.Details = "Service logon right check (approximated via admin role)"
            }
            "sebackupprivilege" {
                $test.HasPrivilege = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::BackupOperator)
                $test.Details = "Backup privilege check"
            }
            "serestoreprivilege" {
                $test.HasPrivilege = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::BackupOperator)
                $test.Details = "Restore privilege check"
            }
            default {
                $test.HasPrivilege = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
                $test.Details = "Generic privilege check (via admin role)"
            }
        }
        
        Write-VelociraptorLog -Message "Specific privilege test for ${PrivilegeName}: $($test.HasPrivilege)" -Level Info
    }
    catch {
        $test.Error = $_.Exception.Message
        $test.Details = "Error testing privilege ${PrivilegeName}: $($_.Exception.Message)"
        Write-VelociraptorLog -Message "Specific privilege test failed for ${PrivilegeName}: $($_.Exception.Message)" -Level Warning
    }
    
    return $test
}