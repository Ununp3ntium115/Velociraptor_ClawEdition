#Requires -Modules Pester

<#
.SYNOPSIS
    Unit tests for the VelociraptorDeployment PowerShell module.

.DESCRIPTION
    Comprehensive unit tests covering all functions in the VelociraptorDeployment module.
    Tests functionality, parameter validation, error handling, and backward compatibility.
#>

BeforeAll {
    # Import the module
    $ModulePath = Join-Path $PSScriptRoot '..\..\modules\VelociraptorDeployment\VelociraptorDeployment.psd1'
    Import-Module $ModulePath -Force
}

Describe "VelociraptorDeployment Module" {
    Context "Module Import" {
        It "Should import successfully" {
            Get-Module VelociraptorDeployment | Should -Not -BeNullOrEmpty
        }
        
        It "Should have correct version" {
            $module = Get-Module VelociraptorDeployment
            $module.Version | Should -Be '1.0.0'
        }
        
        It "Should export expected functions" {
            $module = Get-Module VelociraptorDeployment
            $expectedFunctions = @(
                'Write-VelociraptorLog',
                'Test-VelociraptorAdminPrivileges',
                'Get-VelociraptorLatestRelease',
                'Invoke-VelociraptorDownload'
            )
            
            foreach ($function in $expectedFunctions) {
                $module.ExportedFunctions.Keys | Should -Contain $function
            }
        }
        
        It "Should create backward compatibility aliases" {
            $expectedAliases = @(
                'Log',
                'Write-Log',
                'Require-Admin',
                'Test-Admin',
                'Latest-WindowsAsset',
                'Download-EXE'
            )
            
            foreach ($alias in $expectedAliases) {
                Get-Alias $alias -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe "Write-VelociraptorLog" {
    Context "Basic Functionality" {
        It "Should write log message with default parameters" {
            { Write-VelociraptorLog "Test message" } | Should -Not -Throw
        }
        
        It "Should accept different log levels" {
            $levels = @('Info', 'Warning', 'Error', 'Success', 'Debug', 'Verbose')
            
            foreach ($level in $levels) {
                { Write-VelociraptorLog "Test $level message" -Level $level } | Should -Not -Throw
            }
        }
        
        It "Should work with NoConsole switch" {
            { Write-VelociraptorLog "Silent test" -NoConsole } | Should -Not -Throw
        }
        
        It "Should work with NoTimestamp switch" {
            { Write-VelociraptorLog "No timestamp test" -NoTimestamp } | Should -Not -Throw
        }
        
        It "Should accept Component parameter" {
            { Write-VelociraptorLog "Component test" -Component "TestComponent" } | Should -Not -Throw
        }
    }
    
    Context "Parameter Validation" {
        It "Should require Message parameter" {
            { Write-VelociraptorLog } | Should -Throw
        }
        
        It "Should validate Level parameter" {
            { Write-VelociraptorLog "Test" -Level "InvalidLevel" } | Should -Throw
        }
    }
    
    Context "Backward Compatibility" {
        It "Should work with Log alias" {
            { Log "Test message" } | Should -Not -Throw
        }
        
        It "Should work with Write-Log alias" {
            { Write-Log "Test message" } | Should -Not -Throw
        }
    }
}

Describe "Test-VelociraptorAdminPrivileges" {
    Context "Basic Functionality" {
        It "Should return boolean value" {
            $result = Test-VelociraptorAdminPrivileges
            $result | Should -BeOfType [bool]
        }
        
        It "Should work with Quiet switch" {
            { Test-VelociraptorAdminPrivileges -Quiet } | Should -Not -Throw
        }
        
        It "Should throw when ThrowOnFailure is set and not admin" {
            # This test assumes we're not running as admin
            if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
                { Test-VelociraptorAdminPrivileges -ThrowOnFailure } | Should -Throw
            }
        }
    }
    
    Context "Backward Compatibility" {
        It "Should work with Require-Admin alias" {
            { Require-Admin -Quiet } | Should -Not -Throw
        }
        
        It "Should work with Test-Admin alias" {
            { Test-Admin -Quiet } | Should -Not -Throw
        }
    }
}

Describe "Get-VelociraptorLatestRelease" {
    Context "Basic Functionality" {
        It "Should return release information" {
            $result = Get-VelociraptorLatestRelease
            $result | Should -Not -BeNullOrEmpty
            $result.Version | Should -Not -BeNullOrEmpty
            $result.Asset | Should -Not -BeNullOrEmpty
            $result.Asset.DownloadUrl | Should -Not -BeNullOrEmpty
        }
        
        It "Should accept Platform parameter" {
            $platforms = @('Windows', 'Linux', 'Darwin')
            
            foreach ($platform in $platforms) {
                { Get-VelociraptorLatestRelease -Platform $platform } | Should -Not -Throw
            }
        }
        
        It "Should accept Architecture parameter" {
            $architectures = @('amd64', 'arm64')
            
            foreach ($arch in $architectures) {
                { Get-VelociraptorLatestRelease -Architecture $arch } | Should -Not -Throw
            }
        }
        
        It "Should return correct object structure" {
            $result = Get-VelociraptorLatestRelease
            
            $result.PSObject.Properties.Name | Should -Contain 'Version'
            $result.PSObject.Properties.Name | Should -Contain 'Asset'
            $result.PSObject.Properties.Name | Should -Contain 'Platform'
            $result.PSObject.Properties.Name | Should -Contain 'Architecture'
            
            $result.Asset.PSObject.Properties.Name | Should -Contain 'Name'
            $result.Asset.PSObject.Properties.Name | Should -Contain 'DownloadUrl'
            $result.Asset.PSObject.Properties.Name | Should -Contain 'Size'
        }
    }
    
    Context "Parameter Validation" {
        It "Should validate Platform parameter" {
            { Get-VelociraptorLatestRelease -Platform "InvalidPlatform" } | Should -Throw
        }
        
        It "Should validate Architecture parameter" {
            { Get-VelociraptorLatestRelease -Architecture "InvalidArch" } | Should -Throw
        }
    }
    
    Context "Backward Compatibility" {
        It "Should work with Latest-WindowsAsset alias" {
            { Latest-WindowsAsset } | Should -Not -Throw
        }
    }
}

Describe "Invoke-VelociraptorDownload" {
    Context "Parameter Validation" {
        It "Should require Url parameter" {
            { Invoke-VelociraptorDownload -DestinationPath "C:\temp\test.exe" } | Should -Throw
        }
        
        It "Should require DestinationPath parameter" {
            { Invoke-VelociraptorDownload -Url "https://example.com/file.exe" } | Should -Throw
        }
        
        It "Should validate MaxRetries range" {
            { Invoke-VelociraptorDownload -Url "https://example.com/file.exe" -DestinationPath "C:\temp\test.exe" -MaxRetries 0 } | Should -Throw
            { Invoke-VelociraptorDownload -Url "https://example.com/file.exe" -DestinationPath "C:\temp\test.exe" -MaxRetries 11 } | Should -Throw
        }
        
        It "Should validate TimeoutSeconds range" {
            { Invoke-VelociraptorDownload -Url "https://example.com/file.exe" -DestinationPath "C:\temp\test.exe" -TimeoutSeconds 29 } | Should -Throw
            { Invoke-VelociraptorDownload -Url "https://example.com/file.exe" -DestinationPath "C:\temp\test.exe" -TimeoutSeconds 3601 } | Should -Throw
        }
    }
    
    Context "Return Object Structure" {
        It "Should return object with expected properties on failure" {
            # Test with invalid URL to trigger failure
            $result = Invoke-VelociraptorDownload -Url "https://invalid.url.that.does.not.exist.com/file.exe" -DestinationPath "$env:TEMP\test.exe"
            
            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Contain 'Success'
            $result.PSObject.Properties.Name | Should -Contain 'FilePath'
            $result.Success | Should -Be $false
        }
    }
    
    Context "Backward Compatibility" {
        It "Should work with Download-EXE alias" {
            # Test parameter binding only, not actual download
            $command = Get-Command Download-EXE
            $command | Should -Not -BeNullOrEmpty
            $command.ResolvedCommand.Name | Should -Be 'Invoke-VelociraptorDownload'
        }
    }
}

AfterAll {
    # Clean up
    Remove-Module VelociraptorDeployment -Force -ErrorAction SilentlyContinue
}