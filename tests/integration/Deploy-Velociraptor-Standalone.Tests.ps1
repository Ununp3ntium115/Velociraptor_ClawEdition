#Requires -Modules Pester

<#
.SYNOPSIS
    Integration tests for Deploy-Velociraptor-Standalone.ps1 script.

.DESCRIPTION
    Tests the standalone deployment script functionality including
    prerequisite checks, download operations, and service configuration.
#>

BeforeAll {
    # Set up test environment
    $ScriptPath = Join-Path $PSScriptRoot '..\..\Deploy_Velociraptor_Standalone.ps1'
    $TestInstallDir = Join-Path $env:TEMP 'VelociraptorTest'
    $TestDataStore = Join-Path $env:TEMP 'VelociraptorTestData'
    
    # Import the module for testing
    $ModulePath = Join-Path $PSScriptRoot '..\..\modules\VelociraptorDeployment\VelociraptorDeployment.psd1'
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -Force
    }
}

Describe "Deploy-Velociraptor-Standalone Script" {
    Context "Script Existence and Structure" {
        It "Should exist" {
            Test-Path $ScriptPath | Should -Be $true
        }
        
        It "Should be a valid PowerShell script" {
            { Get-Content $ScriptPath -Raw | Invoke-Expression } | Should -Not -Throw
        }
        
        It "Should contain required functions" {
            $scriptContent = Get-Content $ScriptPath -Raw
            
            # Check for key functions (either direct or via module)
            $scriptContent | Should -Match 'function.*Write-Log|Write-VelociraptorLog'
            $scriptContent | Should -Match 'function.*Test-AdminPrivileges|Test-VelociraptorAdminPrivileges'
        }
    }
    
    Context "Prerequisites Check" {
        It "Should check for administrator privileges" {
            $scriptContent = Get-Content $ScriptPath -Raw
            $scriptContent | Should -Match 'Test-AdminPrivileges|Test-VelociraptorAdminPrivileges'
        }
        
        It "Should create required directories" {
            $scriptContent = Get-Content $ScriptPath -Raw
            $scriptContent | Should -Match 'New-Item.*Directory'
        }
    }
    
    Context "Download Functionality" {
        It "Should have GitHub API integration" {
            $scriptContent = Get-Content $ScriptPath -Raw
            $scriptContent | Should -Match 'api\.github\.com'
            $scriptContent | Should -Match 'Velocidex/velociraptor'
        }
        
        It "Should handle existing executables" {
            $scriptContent = Get-Content $ScriptPath -Raw
            $scriptContent | Should -Match 'Test-Path.*exe'
        }
    }
    
    Context "Firewall Configuration" {
        It "Should configure firewall rules" {
            $scriptContent = Get-Content $ScriptPath -Raw
            $scriptContent | Should -Match 'New-NetFirewallRule|netsh.*firewall'
        }
        
        It "Should handle both modern and legacy firewall commands" {
            $scriptContent = Get-Content $ScriptPath -Raw
            $scriptContent | Should -Match 'New-NetFirewallRule'
            $scriptContent | Should -Match 'netsh'
        }
    }
    
    Context "Service Management" {
        It "Should start Velociraptor GUI" {
            $scriptContent = Get-Content $ScriptPath -Raw
            $scriptContent | Should -Match 'Start-Process.*gui'
        }
        
        It "Should wait for port availability" {
            $scriptContent = Get-Content $ScriptPath -Raw
            $scriptContent | Should -Match 'Wait.*Port|Get-NetTCPConnection'
        }
    }
    
    Context "Logging" {
        It "Should implement logging functionality" {
            $scriptContent = Get-Content $ScriptPath -Raw
            $scriptContent | Should -Match 'Write-Log|Write-VelociraptorLog'
        }
        
        It "Should log to ProgramData directory" {
            $scriptContent = Get-Content $ScriptPath -Raw
            $scriptContent | Should -Match '\$env:ProgramData.*VelociraptorDeploy'
        }
    }
}

Describe "Module Integration" {
    Context "Function Availability" -Skip:(-not (Get-Module VelociraptorDeployment)) {
        It "Should have Write-VelociraptorLog available" {
            Get-Command Write-VelociraptorLog -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have Test-VelociraptorAdminPrivileges available" {
            Get-Command Test-VelociraptorAdminPrivileges -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have Get-VelociraptorLatestRelease available" {
            Get-Command Get-VelociraptorLatestRelease -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have backward compatibility aliases" {
            Get-Alias Log -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Alias Require-Admin -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Error Handling" {
    Context "Script Robustness" {
        It "Should set ErrorActionPreference to Stop" {
            $scriptContent = Get-Content $ScriptPath -Raw
            $scriptContent | Should -Match '\$ErrorActionPreference.*Stop'
        }
        
        It "Should have try-catch blocks for critical operations" {
            $scriptContent = Get-Content $ScriptPath -Raw
            $scriptContent | Should -Match 'try\s*\{'
            $scriptContent | Should -Match 'catch\s*\{'
        }
    }
}

AfterAll {
    # Clean up test environment
    if (Test-Path $TestInstallDir) {
        Remove-Item $TestInstallDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    if (Test-Path $TestDataStore) {
        Remove-Item $TestDataStore -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Remove module
    Remove-Module VelociraptorDeployment -Force -ErrorAction SilentlyContinue
}