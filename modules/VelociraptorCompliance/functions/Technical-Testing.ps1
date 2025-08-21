function Test-AuthenticationTechnical {
    <#
    .SYNOPSIS
        Tests technical authentication implementation compliance.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Control,
        
        [Parameter(Mandatory)]
        [hashtable]$TestResult
    )
    
    try {
        $authChecks = @()
        
        # Check for local authentication policies
        if (Get-Command "Get-LocalSecurityPolicy" -ErrorAction SilentlyContinue) {
            $authChecks += "Local security policy accessible for authentication settings"
        }
        
        # Check for password policy
        if (Get-Command "net" -ErrorAction SilentlyContinue) {
            try {
                $passwordPolicy = net accounts 2>$null
                if ($passwordPolicy) {
                    $authChecks += "Password policy configuration accessible"
                    
                    # Parse password policy for specific requirements
                    $policyText = $passwordPolicy -join "`n"
                    if ($policyText -match "Minimum password length:\s*(\d+)") {
                        $minLength = [int]$Matches[1]
                        if ($minLength -ge 8) {
                            $authChecks += "Password minimum length meets requirements ($minLength characters)"
                        } else {
                            $TestResult.Findings += "Password minimum length below recommended ($minLength < 8)"
                        }
                    }
                    
                    if ($policyText -match "Maximum password age \(days\):\s*(\d+)") {
                        $maxAge = [int]$Matches[1]
                        if ($maxAge -le 90 -and $maxAge -gt 0) {
                            $authChecks += "Password maximum age within recommended range ($maxAge days)"
                        } else {
                            $TestResult.Findings += "Password maximum age outside recommended range ($maxAge days)"
                        }
                    }
                }
            } catch {
                $TestResult.Findings += "Unable to retrieve password policy: $($_.Exception.Message)"
            }
        }
        
        # Check for Windows Hello or other MFA
        if (Get-Command "Get-WindowsOptionalFeature" -ErrorAction SilentlyContinue) {
            try {
                $biometric = Get-WindowsOptionalFeature -Online -FeatureName "Biometric-Framework" -ErrorAction SilentlyContinue
                if ($biometric -and $biometric.State -eq "Enabled") {
                    $authChecks += "Biometric authentication framework enabled"
                }
            } catch {
                # Silently continue if not available
            }
        }
        
        # Check for smart card support
        if (Get-Service "SCardSvr" -ErrorAction SilentlyContinue) {
            $smartCardService = Get-Service "SCardSvr"
            if ($smartCardService.Status -eq "Running") {
                $authChecks += "Smart card service running"
            }
        }
        
        # Check certificate store for authentication certificates
        if (Get-Command "Get-ChildItem" -ErrorAction SilentlyContinue) {
            try {
                $personalCerts = Get-ChildItem Cert:\CurrentUser\My -ErrorAction SilentlyContinue
                if ($personalCerts) {
                    $authCerts = $personalCerts | Where-Object { $_.EnhancedKeyUsageList -like "*Client Authentication*" }
                    if ($authCerts) {
                        $authChecks += "Client authentication certificates found: $($authCerts.Count)"
                    }
                }
            } catch {
                # Silently continue if certificate store not accessible
            }
        }
        
        # Evaluate results
        if ($authChecks.Count -ge 2) {
            $TestResult.Status = 'Pass'
            $TestResult.Evidence += $authChecks
        } elseif ($authChecks.Count -gt 0) {
            $TestResult.Status = 'Partial'
            $TestResult.Evidence += $authChecks
            $TestResult.Findings += "Some authentication controls found but implementation may be incomplete"
        } else {
            $TestResult.Status = 'Fail'
            $TestResult.Findings += "No technical authentication controls detected"
        }
        
        return $TestResult
        
    } catch {
        $TestResult.Status = 'Error'
        $TestResult.Findings += "Authentication technical test error: $($_.Exception.Message)"
        return $TestResult
    }
}

function Test-AuditingTechnical {
    <#
    .SYNOPSIS
        Tests technical auditing implementation compliance.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Control,
        
        [Parameter(Mandatory)]
        [hashtable]$TestResult
    )
    
    try {
        $auditChecks = @()
        
        # Check Windows Event Logs
        if (Get-Command "Get-WinEvent" -ErrorAction SilentlyContinue) {
            try {
                # Check Security log
                $securityLog = Get-WinEvent -ListLog Security -ErrorAction SilentlyContinue
                if ($securityLog) {
                    $auditChecks += "Security event log configured (Size: $([math]::Round($securityLog.MaximumSizeInBytes/1MB,2)) MB)"
                    
                    if ($securityLog.IsEnabled) {
                        $auditChecks += "Security event logging enabled"
                    } else {
                        $TestResult.Findings += "Security event logging disabled"
                    }
                    
                    # Check log retention
                    if ($securityLog.MaximumSizeInBytes -ge 100MB) {
                        $auditChecks += "Security log size meets minimum requirements"
                    } else {
                        $TestResult.Findings += "Security log size below recommended minimum (100MB)"
                    }
                }
                
                # Check System log
                $systemLog = Get-WinEvent -ListLog System -ErrorAction SilentlyContinue
                if ($systemLog -and $systemLog.IsEnabled) {
                    $auditChecks += "System event logging enabled"
                }
                
                # Check Application log
                $appLog = Get-WinEvent -ListLog Application -ErrorAction SilentlyContinue
                if ($appLog -and $appLog.IsEnabled) {
                    $auditChecks += "Application event logging enabled"
                }
                
            } catch {
                $TestResult.Findings += "Error checking Windows Event Logs: $($_.Exception.Message)"
            }
        }
        
        # Check audit policy settings
        if (Get-Command "auditpol" -ErrorAction SilentlyContinue) {
            try {
                $auditPol = auditpol /get /category:* 2>$null
                if ($auditPol) {
                    $auditChecks += "Audit policy configuration accessible"
                    
                    # Check for key audit categories
                    $auditText = $auditPol -join "`n"
                    if ($auditText -match "Logon/Logoff.*Success") {
                        $auditChecks += "Logon/Logoff success auditing enabled"
                    }
                    if ($auditText -match "Account Logon.*Success") {
                        $auditChecks += "Account Logon success auditing enabled"
                    }
                    if ($auditText -match "Privilege Use.*Success and Failure") {
                        $auditChecks += "Privilege Use auditing enabled"
                    }
                }
            } catch {
                $TestResult.Findings += "Unable to retrieve audit policy: $($_.Exception.Message)"
            }
        }
        
        # Check for PowerShell logging
        if (Get-Command "Get-ItemProperty" -ErrorAction SilentlyContinue) {
            try {
                $psLogging = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\*" -ErrorAction SilentlyContinue
                if ($psLogging) {
                    $auditChecks += "PowerShell logging policies configured"
                }
            } catch {
                # Silently continue if registry not accessible
            }
        }
        
        # Check for Sysmon
        if (Get-Service "Sysmon*" -ErrorAction SilentlyContinue) {
            $sysmon = Get-Service "Sysmon*"
            if ($sysmon -and $sysmon.Status -eq "Running") {
                $auditChecks += "Sysmon service running for enhanced logging"
            }
        }
        
        # Check for log files in common locations
        $logPaths = @(
            "$env:ProgramData\VelociraptorDeploy\*.log",
            ".\logs\*.log",
            ".\*.log"
        )
        
        foreach ($path in $logPaths) {
            $logFiles = Get-ChildItem $path -ErrorAction SilentlyContinue
            if ($logFiles) {
                $auditChecks += "Application log files found: $($logFiles.Count) files"
                break
            }
        }
        
        # Evaluate results
        if ($auditChecks.Count -ge 3) {
            $TestResult.Status = 'Pass'
            $TestResult.Evidence += $auditChecks
        } elseif ($auditChecks.Count -gt 0) {
            $TestResult.Status = 'Partial'
            $TestResult.Evidence += $auditChecks
            $TestResult.Findings += "Some auditing controls found but implementation may be incomplete"
        } else {
            $TestResult.Status = 'Fail'
            $TestResult.Findings += "No technical auditing controls detected"
        }
        
        return $TestResult
        
    } catch {
        $TestResult.Status = 'Error'
        $TestResult.Findings += "Auditing technical test error: $($_.Exception.Message)"
        return $TestResult
    }
}

function Test-AccessControlTechnical {
    <#
    .SYNOPSIS
        Tests technical access control implementation compliance.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Control,
        
        [Parameter(Mandatory)]
        [hashtable]$TestResult
    )
    
    try {
        $accessChecks = @()
        
        # Check file system permissions
        if (Get-Command "Get-Acl" -ErrorAction SilentlyContinue) {
            try {
                # Check system directory permissions
                $systemAcl = Get-Acl "$env:SystemRoot" -ErrorAction SilentlyContinue
                if ($systemAcl) {
                    $accessChecks += "File system access controls present on system directories"
                    
                    # Check for appropriate permissions
                    $adminAccess = $systemAcl.Access | Where-Object { $_.IdentityReference -like "*Administrators*" }
                    if ($adminAccess) {
                        $accessChecks += "Administrative access controls configured"
                    }
                }
                
                # Check program files permissions
                $programFilesAcl = Get-Acl "$env:ProgramFiles" -ErrorAction SilentlyContinue
                if ($programFilesAcl) {
                    $userAccess = $programFilesAcl.Access | Where-Object { $_.IdentityReference -like "*Users*" -and $_.FileSystemRights -like "*Write*" }
                    if (-not $userAccess) {
                        $accessChecks += "Program Files directory properly protected from user write access"
                    } else {
                        $TestResult.Findings += "Program Files directory may have inappropriate user write access"
                    }
                }
            } catch {
                $TestResult.Findings += "Error checking file system permissions: $($_.Exception.Message)"
            }
        }
        
        # Check registry permissions
        if (Get-Command "Get-Acl" -ErrorAction SilentlyContinue) {
            try {
                $regAcl = Get-Acl "HKLM:\SOFTWARE" -ErrorAction SilentlyContinue
                if ($regAcl) {
                    $accessChecks += "Registry access controls present"
                }
            } catch {
                # Silently continue if registry not accessible
            }
        }
        
        # Check local security groups
        if (Get-Command "Get-LocalGroup" -ErrorAction SilentlyContinue) {
            try {
                $adminGroup = Get-LocalGroup "Administrators" -ErrorAction SilentlyContinue
                if ($adminGroup) {
                    $adminMembers = Get-LocalGroupMember "Administrators" -ErrorAction SilentlyContinue
                    if ($adminMembers) {
                        $accessChecks += "Administrative group access controls configured ($($adminMembers.Count) members)"
                        
                        # Check for excessive admin members
                        if ($adminMembers.Count -le 5) {
                            $accessChecks += "Administrative group membership appears controlled"
                        } else {
                            $TestResult.Findings += "Administrative group has many members - review may be needed"
                        }
                    }
                }
            } catch {
                $TestResult.Findings += "Error checking local security groups: $($_.Exception.Message)"
            }
        }
        
        # Check Windows Firewall
        if (Get-Command "Get-NetFirewallProfile" -ErrorAction SilentlyContinue) {
            try {
                $firewallProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
                if ($firewallProfiles) {
                    $enabledProfiles = $firewallProfiles | Where-Object { $_.Enabled -eq $true }
                    if ($enabledProfiles) {
                        $accessChecks += "Windows Firewall enabled ($($enabledProfiles.Count) profiles)"
                    } else {
                        $TestResult.Findings += "Windows Firewall appears to be disabled"
                    }
                }
            } catch {
                $TestResult.Findings += "Error checking Windows Firewall: $($_.Exception.Message)"
            }
        }
        
        # Check UAC settings
        if (Get-Command "Get-ItemProperty" -ErrorAction SilentlyContinue) {
            try {
                $uacSetting = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue
                if ($uacSetting -and $uacSetting.EnableLUA -eq 1) {
                    $accessChecks += "User Account Control (UAC) enabled"
                } else {
                    $TestResult.Findings += "User Account Control (UAC) may be disabled"
                }
            } catch {
                # Silently continue if registry not accessible
            }
        }
        
        # Check for network access restrictions
        if (Get-Command "Get-NetConnectionProfile" -ErrorAction SilentlyContinue) {
            try {
                $networkProfiles = Get-NetConnectionProfile -ErrorAction SilentlyContinue
                if ($networkProfiles) {
                    $publicProfiles = $networkProfiles | Where-Object { $_.NetworkCategory -eq "Public" }
                    if ($publicProfiles) {
                        $accessChecks += "Network profiles configured with public network restrictions"
                    }
                }
            } catch {
                # Silently continue if network information not accessible
            }
        }
        
        # Evaluate results
        if ($accessChecks.Count -ge 3) {
            $TestResult.Status = 'Pass'
            $TestResult.Evidence += $accessChecks
        } elseif ($accessChecks.Count -gt 0) {
            $TestResult.Status = 'Partial'
            $TestResult.Evidence += $accessChecks
            $TestResult.Findings += "Some access controls found but implementation may be incomplete"
        } else {
            $TestResult.Status = 'Fail'
            $TestResult.Findings += "No technical access controls detected"
        }
        
        return $TestResult
        
    } catch {
        $TestResult.Status = 'Error'
        $TestResult.Findings += "Access control technical test error: $($_.Exception.Message)"
        return $TestResult
    }
}

function Test-CommunicationsProtection {
    <#
    .SYNOPSIS
        Tests technical communications protection compliance.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Control,
        
        [Parameter(Mandatory)]
        [hashtable]$TestResult
    )
    
    try {
        $commChecks = @()
        
        # Check TLS/SSL configuration
        if (Get-Command "Get-TlsCipherSuite" -ErrorAction SilentlyContinue) {
            try {
                $tlsCiphers = Get-TlsCipherSuite -ErrorAction SilentlyContinue
                if ($tlsCiphers) {
                    $strongCiphers = $tlsCiphers | Where-Object { $_.Name -like "*AES*" -or $_.Name -like "*CHACHA*" }
                    if ($strongCiphers) {
                        $commChecks += "Strong TLS cipher suites available ($($strongCiphers.Count) ciphers)"
                    }
                    
                    # Check for weak ciphers
                    $weakCiphers = $tlsCiphers | Where-Object { $_.Name -like "*RC4*" -or $_.Name -like "*DES*" -or $_.Name -like "*NULL*" }
                    if ($weakCiphers) {
                        $TestResult.Findings += "Weak cipher suites detected: $($weakCiphers.Count)"
                    } else {
                        $commChecks += "No weak cipher suites detected"
                    }
                }
            } catch {
                $TestResult.Findings += "Error checking TLS configuration: $($_.Exception.Message)"
            }
        }
        
        # Check certificate store
        if (Get-Command "Get-ChildItem" -ErrorAction SilentlyContinue) {
            try {
                # Check for SSL certificates
                $sslCerts = Get-ChildItem Cert:\LocalMachine\My -ErrorAction SilentlyContinue
                if ($sslCerts) {
                    $validCerts = $sslCerts | Where-Object { $_.NotAfter -gt (Get-Date) }
                    if ($validCerts) {
                        $commChecks += "Valid SSL certificates found: $($validCerts.Count)"
                        
                        # Check certificate key sizes
                        $strongKeys = $validCerts | Where-Object { $_.PublicKey.Key.KeySize -ge 2048 }
                        if ($strongKeys.Count -eq $validCerts.Count) {
                            $commChecks += "All certificates use strong key sizes (≥2048 bits)"
                        } else {
                            $TestResult.Findings += "Some certificates may use weak key sizes"
                        }
                    }
                }
                
                # Check for CA certificates
                $caCerts = Get-ChildItem Cert:\LocalMachine\Root -ErrorAction SilentlyContinue
                if ($caCerts) {
                    $commChecks += "Certificate Authority store configured ($($caCerts.Count) CA certificates)"
                }
            } catch {
                $TestResult.Findings += "Error checking certificate stores: $($_.Exception.Message)"
            }
        }
        
        # Check network encryption protocols
        if (Get-Command "Get-ItemProperty" -ErrorAction SilentlyContinue) {
            try {
                # Check SSL/TLS protocol settings
                $sslProtocols = @()
                
                # Check TLS 1.2
                $tls12Client = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" -Name "Enabled" -ErrorAction SilentlyContinue
                if ($tls12Client -and $tls12Client.Enabled -eq 1) {
                    $sslProtocols += "TLS 1.2 Client"
                }
                
                $tls12Server = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" -Name "Enabled" -ErrorAction SilentlyContinue
                if ($tls12Server -and $tls12Server.Enabled -eq 1) {
                    $sslProtocols += "TLS 1.2 Server"
                }
                
                # Check TLS 1.3 (Windows 10/Server 2019+)
                $tls13Client = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client" -Name "Enabled" -ErrorAction SilentlyContinue
                if ($tls13Client -and $tls13Client.Enabled -eq 1) {
                    $sslProtocols += "TLS 1.3 Client"
                }
                
                if ($sslProtocols.Count -gt 0) {
                    $commChecks += "Secure protocols enabled: $($sslProtocols -join ', ')"
                }
                
                # Check for disabled weak protocols
                $ssl30Disabled = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client" -Name "Enabled" -ErrorAction SilentlyContinue
                if ($ssl30Disabled -and $ssl30Disabled.Enabled -eq 0) {
                    $commChecks += "SSL 3.0 properly disabled"
                }
                
            } catch {
                # Silently continue if registry not accessible
            }
        }
        
        # Check IPSec configuration
        if (Get-Command "Get-NetIPsecMainModeRule" -ErrorAction SilentlyContinue) {
            try {
                $ipsecRules = Get-NetIPsecMainModeRule -ErrorAction SilentlyContinue
                if ($ipsecRules) {
                    $commChecks += "IPSec configuration found ($($ipsecRules.Count) rules)"
                }
            } catch {
                # Silently continue if IPSec not available
            }
        }
        
        # Check Windows Defender Firewall advanced settings
        if (Get-Command "Get-NetFirewallRule" -ErrorAction SilentlyContinue) {
            try {
                $firewallRules = Get-NetFirewallRule -Enabled True -ErrorAction SilentlyContinue
                if ($firewallRules) {
                    $commChecks += "Network firewall rules active ($($firewallRules.Count) rules)"
                }
            } catch {
                # Silently continue if firewall not accessible
            }
        }
        
        # Evaluate results
        if ($commChecks.Count -ge 2) {
            $TestResult.Status = 'Pass'
            $TestResult.Evidence += $commChecks
        } elseif ($commChecks.Count -gt 0) {
            $TestResult.Status = 'Partial'
            $TestResult.Evidence += $commChecks
            $TestResult.Findings += "Some communications protection found but implementation may be incomplete"
        } else {
            $TestResult.Status = 'Fail'
            $TestResult.Findings += "No technical communications protection detected"
        }
        
        return $TestResult
        
    } catch {
        $TestResult.Status = 'Error'
        $TestResult.Findings += "Communications protection test error: $($_.Exception.Message)"
        return $TestResult
    }
}

function Test-SystemIntegrity {
    <#
    .SYNOPSIS
        Tests technical system integrity compliance.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Control,
        
        [Parameter(Mandatory)]
        [hashtable]$TestResult
    )
    
    try {
        $integrityChecks = @()
        
        # Check Windows Defender
        if (Get-Command "Get-MpComputerStatus" -ErrorAction SilentlyContinue) {
            try {
                $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
                if ($defenderStatus) {
                    if ($defenderStatus.AntivirusEnabled) {
                        $integrityChecks += "Windows Defender Antivirus enabled"
                    }
                    if ($defenderStatus.RealTimeProtectionEnabled) {
                        $integrityChecks += "Real-time protection enabled"
                    }
                    if ($defenderStatus.BehaviorMonitorEnabled) {
                        $integrityChecks += "Behavior monitoring enabled"
                    }
                    
                    # Check signature freshness
                    if ($defenderStatus.AntivirusSignatureLastUpdated) {
                        $daysSinceUpdate = (Get-Date) - $defenderStatus.AntivirusSignatureLastUpdated
                        if ($daysSinceUpdate.Days -le 7) {
                            $integrityChecks += "Antivirus signatures recently updated ($($daysSinceUpdate.Days) days ago)"
                        } else {
                            $TestResult.Findings += "Antivirus signatures may be outdated ($($daysSinceUpdate.Days) days old)"
                        }
                    }
                }
            } catch {
                $TestResult.Findings += "Error checking Windows Defender status: $($_.Exception.Message)"
            }
        }
        
        # Check Windows Update settings
        if (Get-Command "Get-ItemProperty" -ErrorAction SilentlyContinue) {
            try {
                $windowsUpdate = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -ErrorAction SilentlyContinue
                if ($windowsUpdate) {
                    $integrityChecks += "Windows Update configuration accessible"
                    
                    if ($windowsUpdate.AUOptions -in @(3, 4)) {
                        $integrityChecks += "Automatic updates configured"
                    }
                }
            } catch {
                # Silently continue if registry not accessible
            }
        }
        
        # Check system file integrity
        if (Get-Command "sfc" -ErrorAction SilentlyContinue) {
            # Note: We don't run sfc /scannow as it takes too long, but we check if it's available
            $integrityChecks += "System File Checker (sfc) available for integrity verification"
        }
        
        # Check DISM for system health
        if (Get-Command "dism" -ErrorAction SilentlyContinue) {
            $integrityChecks += "DISM available for system image health verification"
        }
        
        # Check BitLocker
        if (Get-Command "Get-BitLockerVolume" -ErrorAction SilentlyContinue) {
            try {
                $bitlockerVolumes = Get-BitLockerVolume -ErrorAction SilentlyContinue
                if ($bitlockerVolumes) {
                    $protectedVolumes = $bitlockerVolumes | Where-Object { $_.ProtectionStatus -eq "On" }
                    if ($protectedVolumes) {
                        $integrityChecks += "BitLocker protection enabled on $($protectedVolumes.Count) volume(s)"
                    }
                }
            } catch {
                # Silently continue if BitLocker not available
            }
        }
        
        # Check code integrity policies
        if (Get-Command "Get-CIPolicy" -ErrorAction SilentlyContinue) {
            try {
                $ciPolicies = Get-CIPolicy -ErrorAction SilentlyContinue
                if ($ciPolicies) {
                    $integrityChecks += "Code Integrity policies configured ($($ciPolicies.Count) policies)"
                }
            } catch {
                # Silently continue if CI policies not available
            }
        }
        
        # Check Windows Defender Application Guard
        if (Get-Command "Get-WindowsOptionalFeature" -ErrorAction SilentlyContinue) {
            try {
                $appGuard = Get-WindowsOptionalFeature -Online -FeatureName "Windows-Defender-ApplicationGuard" -ErrorAction SilentlyContinue
                if ($appGuard -and $appGuard.State -eq "Enabled") {
                    $integrityChecks += "Windows Defender Application Guard enabled"
                }
            } catch {
                # Silently continue if feature not available
            }
        }
        
        # Check for virtualization-based security
        if (Get-Command "Get-ItemProperty" -ErrorAction SilentlyContinue) {
            try {
                $vbs = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name "EnableVirtualizationBasedSecurity" -ErrorAction SilentlyContinue
                if ($vbs -and $vbs.EnableVirtualizationBasedSecurity -eq 1) {
                    $integrityChecks += "Virtualization-based security enabled"
                }
            } catch {
                # Silently continue if registry not accessible
            }
        }
        
        # Evaluate results
        if ($integrityChecks.Count -ge 3) {
            $TestResult.Status = 'Pass'
            $TestResult.Evidence += $integrityChecks
        } elseif ($integrityChecks.Count -gt 0) {
            $TestResult.Status = 'Partial'
            $TestResult.Evidence += $integrityChecks
            $TestResult.Findings += "Some system integrity controls found but implementation may be incomplete"
        } else {
            $TestResult.Status = 'Fail'
            $TestResult.Findings += "No technical system integrity controls detected"
        }
        
        return $TestResult
        
    } catch {
        $TestResult.Status = 'Error'
        $TestResult.Findings += "System integrity test error: $($_.Exception.Message)"
        return $TestResult
    }
}

function Test-ConfigurationManagement {
    <#
    .SYNOPSIS
        Tests technical configuration management compliance.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Control,
        
        [Parameter(Mandatory)]
        [hashtable]$TestResult
    )
    
    try {
        $configChecks = @()
        
        # Check for configuration baselines
        $baselinePaths = @(
            ".\baselines\",
            ".\configuration\",
            "$env:ProgramData\VelociraptorCompliance\baselines\"
        )
        
        foreach ($path in $baselinePaths) {
            if (Test-Path $path) {
                $baselineFiles = Get-ChildItem $path -Filter "*baseline*", "*config*" -ErrorAction SilentlyContinue
                if ($baselineFiles) {
                    $configChecks += "Configuration baseline files found: $($baselineFiles.Count)"
                    break
                }
            }
        }
        
        # Check Group Policy (if domain-joined)
        if (Get-Command "Get-ItemProperty" -ErrorAction SilentlyContinue) {
            try {
                $gpResult = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy" -ErrorAction SilentlyContinue
                if ($gpResult) {
                    $configChecks += "Group Policy configuration management present"
                }
            } catch {
                # Silently continue if not domain-joined
            }
        }
        
        # Check for PowerShell DSC
        if (Get-Command "Get-DscConfiguration" -ErrorAction SilentlyContinue) {
            try {
                $dscConfig = Get-DscConfiguration -ErrorAction SilentlyContinue
                if ($dscConfig) {
                    $configChecks += "PowerShell Desired State Configuration active"
                }
            } catch {
                # Silently continue if DSC not configured
            }
        }
        
        # Check for version control evidence
        $versionControlPaths = @(
            ".\.git",
            ".\src\.git",
            ".\.hg",
            ".\.svn"
        )
        
        foreach ($path in $versionControlPaths) {
            if (Test-Path $path) {
                $configChecks += "Version control system detected"
                break
            }
        }
        
        # Check system restore points
        if (Get-Command "Get-ComputerRestorePoint" -ErrorAction SilentlyContinue) {
            try {
                $restorePoints = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
                if ($restorePoints) {
                    $recentRestorePoints = $restorePoints | Where-Object { $_.CreationTime -gt (Get-Date).AddDays(-30) }
                    if ($recentRestorePoints) {
                        $configChecks += "Recent system restore points available ($($recentRestorePoints.Count))"
                    }
                }
            } catch {
                # Silently continue if restore points not available
            }
        }
        
        # Check Windows Registry backup
        if (Test-Path "$env:SystemRoot\System32\config") {
            $configChecks += "System registry configuration files present"
        }
        
        # Check for change tracking logs
        $changeLogPaths = @(
            ".\changes\",
            ".\logs\changes\",
            "$env:ProgramData\VelociraptorCompliance\changes\"
        )
        
        foreach ($path in $changeLogPaths) {
            if (Test-Path $path) {
                $changeFiles = Get-ChildItem $path -Filter "*change*", "*modify*" -ErrorAction SilentlyContinue
                if ($changeFiles) {
                    $configChecks += "Change tracking files found"
                    break
                }
            }
        }
        
        # Evaluate results
        if ($configChecks.Count -ge 2) {
            $TestResult.Status = 'Pass'
            $TestResult.Evidence += $configChecks
        } elseif ($configChecks.Count -gt 0) {
            $TestResult.Status = 'Partial'
            $TestResult.Evidence += $configChecks
            $TestResult.Findings += "Some configuration management found but implementation may be incomplete"
        } else {
            $TestResult.Status = 'Fail'
            $TestResult.Findings += "No technical configuration management detected"
        }
        
        return $TestResult
        
    } catch {
        $TestResult.Status = 'Error'
        $TestResult.Findings += "Configuration management test error: $($_.Exception.Message)"
        return $TestResult
    }
}

function Test-GenericTechnical {
    <#
    .SYNOPSIS
        Tests generic technical compliance controls.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Control,
        
        [Parameter(Mandatory)]
        [hashtable]$TestResult
    )
    
    try {
        # Generic technical test
        $TestResult.Status = 'Partial'
        $TestResult.Findings += "Generic technical control - automated testing not yet implemented"
        $TestResult.Evidence += "Control requires manual technical verification"
        
        return $TestResult
        
    } catch {
        $TestResult.Status = 'Error'
        $TestResult.Findings += "Generic technical test error: $($_.Exception.Message)"
        return $TestResult
    }
}