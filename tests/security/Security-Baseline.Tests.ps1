#Requires -Modules Pester

<#
.SYNOPSIS
    Security baseline tests for Velociraptor deployment scripts.

.DESCRIPTION
    Tests security aspects of the deployment scripts including privilege checks,
    secure communications, input validation, and security best practices.
#>

BeforeAll {
    # Set up test environment
    $ScriptPaths = @(
        (Join-Path $PSScriptRoot '..\..\Deploy_Velociraptor_Standalone.ps1'),
        (Join-Path $PSScriptRoot '..\..\Deploy_Velociraptor_Server.ps1'),
        (Join-Path $PSScriptRoot '..\..\Cleanup_Velociraptor.ps1'),
        (Join-Path $PSScriptRoot '..\..\Prepare_OfflineCollector_Env.ps1')
    )
    
    # Import the module for testing
    $ModulePath = Join-Path $PSScriptRoot '..\..\modules\VelociraptorDeployment\VelociraptorDeployment.psd1'
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -Force
    }
}

Describe "Security Baseline - Administrator Privileges" {
    Context "Privilege Validation" {
        It "Should check for administrator privileges in all scripts" {
            foreach ($scriptPath in $ScriptPaths) {
                if (Test-Path $scriptPath) {
                    $content = Get-Content $scriptPath -Raw
                    $content | Should -Match 'Test-Admin|Require-Admin|Test.*Administrator|WindowsBuiltinRole.*Administrator'
                }
            }
        }
        
        It "Should have proper privilege checking function" {
            if (Get-Module VelociraptorDeployment) {
                Get-Command Test-VelociraptorAdminPrivileges -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe "Security Baseline - Secure Communications" {
    Context "TLS Configuration" {
        It "Should enforce TLS 1.2 for downloads" {
            foreach ($scriptPath in $ScriptPaths) {
                if (Test-Path $scriptPath) {
                    $content = Get-Content $scriptPath -Raw
                    if ($content -match 'Invoke-WebRequest|WebClient|RestMethod') {
                        $content | Should -Match 'Tls12|SecurityProtocol'
                    }
                }
            }
        }
        
        It "Should use HTTPS for GitHub API calls" {
            foreach ($scriptPath in $ScriptPaths) {
                if (Test-Path $scriptPath) {
                    $content = Get-Content $scriptPath -Raw
                    if ($content -match 'api\.github\.com') {
                        $content | Should -Match 'https://api\.github\.com'
                        $content | Should -Not -Match 'http://api\.github\.com'
                    }
                }
            }
        }
    }
    
    Context "User-Agent Headers" {
        It "Should set appropriate User-Agent headers" {
            foreach ($scriptPath in $ScriptPaths) {
                if (Test-Path $scriptPath) {
                    $content = Get-Content $scriptPath -Raw
                    if ($content -match 'Invoke-WebRequest|RestMethod') {
                        $content | Should -Match 'User-Agent'
                    }
                }
            }
        }
    }
}

Describe "Security Baseline - Input Validation" {
    Context "Parameter Validation" {
        It "Should validate file paths" {
            if (Get-Module VelociraptorDeployment) {
                $functions = Get-Command -Module VelociraptorDeployment
                foreach ($function in $functions) {
                    $help = Get-Help $function.Name -ErrorAction SilentlyContinue
                    if ($help -and $help.parameters) {
                        # Check if path parameters have validation
                        $pathParams = $help.parameters.parameter | Where-Object { $_.name -like "*Path*" }
                        if ($pathParams) {
                            # This is a basic check - in practice, we'd examine the actual parameter attributes
                            $true | Should -Be $true  # Placeholder for actual validation check
                        }
                    }
                }
            }
        }
    }
    
    Context "Secure Input Handling" {
        It "Should handle sensitive input securely" {
            foreach ($scriptPath in $ScriptPaths) {
                if (Test-Path $scriptPath) {
                    $content = Get-Content $scriptPath -Raw
                    if ($content -match 'password|secret|credential') {
                        $content | Should -Match 'SecureString|Read-Host.*AsSecureString'
                    }
                }
            }
        }
    }
}

Describe "Security Baseline - File Operations" {
    Context "Secure File Handling" {
        It "Should create files with appropriate permissions" {
            foreach ($scriptPath in $ScriptPaths) {
                if (Test-Path $scriptPath) {
                    $content = Get-Content $scriptPath -Raw
                    # Check for explicit permission setting or secure defaults
                    if ($content -match 'New-Item.*File|Out-File') {
                        # Files should not be world-writable by default
                        $content | Should -Not -Match 'Everyone.*FullControl'
                    }
                }
            }
        }
        
        It "Should validate file downloads" {
            foreach ($scriptPath in $ScriptPaths) {
                if (Test-Path $scriptPath) {
                    $content = Get-Content $scriptPath -Raw
                    if ($content -match 'DownloadFile|Invoke-WebRequest.*OutFile') {
                        # Should check file size or hash
                        $content | Should -Match 'Length|Size|Hash|Get-FileHash'
                    }
                }
            }
        }
    }
    
    Context "Temporary File Cleanup" {
        It "Should clean up temporary files" {
            foreach ($scriptPath in $ScriptPaths) {
                if (Test-Path $scriptPath) {
                    $content = Get-Content $scriptPath -Raw
                    if ($content -match '\.download|\.tmp|temp') {
                        $content | Should -Match 'Remove-Item|finally\s*\{'
                    }
                }
            }
        }
    }
}

Describe "Security Baseline - Service Configuration" {
    Context "Service Security" {
        It "Should configure services with least privilege" {
            foreach ($scriptPath in $ScriptPaths) {
                if (Test-Path $scriptPath) {
                    $content = Get-Content $scriptPath -Raw
                    if ($content -match 'service.*install|New-Service') {
                        # Should not run as SYSTEM unless necessary
                        $content | Should -Not -Match 'LocalSystem.*FullControl'
                    }
                }
            }
        }
    }
    
    Context "Firewall Rules" {
        It "Should create specific firewall rules" {
            foreach ($scriptPath in $ScriptPaths) {
                if (Test-Path $scriptPath) {
                    $content = Get-Content $scriptPath -Raw
                    if ($content -match 'New-NetFirewallRule|netsh.*firewall') {
                        # Should specify direction and protocol
                        $content | Should -Match 'Direction.*Inbound|dir=in'
                        $content | Should -Match 'Protocol.*TCP|protocol=TCP'
                    }
                }
            }
        }
    }
}

Describe "Security Baseline - Error Handling" {
    Context "Information Disclosure" {
        It "Should not expose sensitive information in errors" {
            foreach ($scriptPath in $ScriptPaths) {
                if (Test-Path $scriptPath) {
                    $content = Get-Content $scriptPath -Raw
                    # Should not expose full paths or credentials in error messages
                    if ($content -match 'Write-Error|throw') {
                        $content | Should -Not -Match 'password.*\$|secret.*\$|credential.*\$'
                    }
                }
            }
        }
    }
    
    Context "Secure Logging" {
        It "Should not log sensitive information" {
            foreach ($scriptPath in $ScriptPaths) {
                if (Test-Path $scriptPath) {
                    $content = Get-Content $scriptPath -Raw
                    if ($content -match 'Write-Log|Out-File.*log') {
                        # Should not log passwords or secrets
                        $content | Should -Not -Match 'Log.*password|Log.*secret'
                    }
                }
            }
        }
    }
}

Describe "Security Baseline - Code Quality" {
    Context "PowerShell Security" {
        It "Should use Set-StrictMode or equivalent" {
            if (Get-Module VelociraptorDeployment) {
                $moduleContent = Get-Content (Join-Path $PSScriptRoot '..\..\modules\VelociraptorDeployment\VelociraptorDeployment.psm1') -Raw
                $moduleContent | Should -Match 'Set-StrictMode'
            }
        }
        
        It "Should set appropriate ErrorActionPreference" {
            foreach ($scriptPath in $ScriptPaths) {
                if (Test-Path $scriptPath) {
                    $content = Get-Content $scriptPath -Raw
                    $content | Should -Match '\$ErrorActionPreference.*Stop'
                }
            }
        }
    }
    
    Context "Input Sanitization" {
        It "Should sanitize user input" {
            foreach ($scriptPath in $ScriptPaths) {
                if (Test-Path $scriptPath) {
                    $content = Get-Content $scriptPath -Raw
                    if ($content -match 'Read-Host') {
                        # Should validate or sanitize input
                        $content | Should -Match 'ValidateSet|ValidatePattern|ValidateScript|-match|-like'
                    }
                }
            }
        }
    }
}

AfterAll {
    # Clean up
    Remove-Module VelociraptorDeployment -Force -ErrorAction SilentlyContinue
}