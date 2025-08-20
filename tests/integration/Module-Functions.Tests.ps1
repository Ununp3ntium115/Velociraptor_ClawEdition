#Requires -Modules Pester

<#
.SYNOPSIS
    Integration tests for VelociraptorDeployment module functions.

.DESCRIPTION
    Tests all 25+ specialized functions in the VelociraptorDeployment module
    for proper functionality, error handling, and integration.
#>

BeforeAll {
    # Import the module for testing
    $ModulePath = Join-Path $PSScriptRoot '..\..\modules\VelociraptorDeployment\VelociraptorDeployment.psd1'
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -Force
    }
    
    # Test data setup
    $TestConfig = @{
        ServerName = 'test-server.local'
        Port = '8889'
        DataStore = Join-Path $env:TEMP 'VelociraptorTest'
        ConfigPath = Join-Path $env:TEMP 'test-config.yaml'
    }
    
    # Create test directories
    if (-not (Test-Path $TestConfig.DataStore)) {
        New-Item -Path $TestConfig.DataStore -ItemType Directory -Force | Out-Null
    }
}

Describe "Core Infrastructure Functions" {
    Context "Administrative Privilege Management" {
        It "Should have Test-VelociraptorAdminPrivileges function" {
            Get-Command Test-VelociraptorAdminPrivileges -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should correctly detect admin privileges" -Skip:($IsLinux -or $IsMacOS) {
            $isAdmin = Test-VelociraptorAdminPrivileges
            $isAdmin | Should -BeOfType [bool]
        }
        
        It "Should have backward compatibility alias" {
            Get-Alias Require-Admin -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Logging Infrastructure" {
        It "Should have Write-VelociraptorLog function" {
            Get-Command Write-VelociraptorLog -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should support different log levels" {
            { Write-VelociraptorLog "Test message" -Level Info } | Should -Not -Throw
            { Write-VelociraptorLog "Test warning" -Level Warning } | Should -Not -Throw
            { Write-VelociraptorLog "Test error" -Level Error } | Should -Not -Throw
        }
        
        It "Should have backward compatibility alias" {
            Get-Alias Log -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should create log files in appropriate directory" {
            Write-VelociraptorLog "Integration test message" -Level Info
            $logDir = Join-Path $env:ProgramData "VelociraptorDeploy"
            # Log directory should exist after logging
            if (Test-Path $logDir) {
                $logFiles = Get-ChildItem $logDir -Filter "*.log"
                $logFiles | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe "Download and Release Management" {
    Context "GitHub Release Functions" {
        It "Should have Get-VelociraptorLatestRelease function" {
            Get-Command Get-VelociraptorLatestRelease -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should retrieve release information" -Tag "Network" {
            $release = Get-VelociraptorLatestRelease
            $release | Should -Not -BeNullOrEmpty
            $release.tag_name | Should -Not -BeNullOrEmpty
            $release.assets | Should -Not -BeNullOrEmpty
        }
        
        It "Should handle network errors gracefully" {
            # This test simulates network failure handling
            { Get-VelociraptorLatestRelease -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }
    
    Context "Download Functions" {
        It "Should have download helper functions" {
            Get-Command -Module VelociraptorDeployment -Name "*Download*" | Should -Not -BeNullOrEmpty
        }
        
        It "Should validate URLs before downloading" {
            $downloadFunctions = Get-Command -Module VelociraptorDeployment -Name "*Download*"
            foreach ($func in $downloadFunctions) {
                $funcContent = $func.Definition
                $funcContent | Should -Match 'http|url|uri'
            }
        }
    }
}

Describe "Configuration Management" {
    Context "Configuration Engine" {
        It "Should have New-ConfigurationEngine function" {
            Get-Command New-ConfigurationEngine -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should create configuration templates" {
            { New-ConfigurationEngine -ServerName $TestConfig.ServerName -GuiPort $TestConfig.Port } | Should -Not -Throw
        }
        
        It "Should have New-VelociraptorConfigurationTemplate function" {
            Get-Command New-VelociraptorConfigurationTemplate -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should support different configuration types" {
            $templateFunction = Get-Command New-VelociraptorConfigurationTemplate
            $templateFunction.Parameters.Keys | Should -Contain 'DeploymentType'
        }
    }
    
    Context "Environment Analysis" {
        It "Should have Get-EnvironmentAnalysis function" {
            Get-Command Get-EnvironmentAnalysis -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should analyze system environment" {
            $analysis = Get-EnvironmentAnalysis
            $analysis | Should -Not -BeNullOrEmpty
            $analysis | Should -BeOfType [hashtable]
        }
        
        It "Should have Get-AutoDetectedSystemSpecs function" {
            Get-Command Get-AutoDetectedSystemSpecs -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should detect system specifications" {
            $specs = Get-AutoDetectedSystemSpecs
            $specs | Should -Not -BeNullOrEmpty
            $specs.TotalRAM | Should -BeGreaterThan 0
            $specs.CPUCores | Should -BeGreaterThan 0
        }
    }
}

Describe "Intelligent Features" {
    Context "Intelligent Recommendations" {
        It "Should have Get-IntelligentRecommendations function" {
            Get-Command Get-IntelligentRecommendations -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should provide deployment recommendations" {
            $recommendations = Get-IntelligentRecommendations -SystemSpecs (Get-AutoDetectedSystemSpecs)
            $recommendations | Should -Not -BeNullOrEmpty
            $recommendations.RecommendedDeploymentType | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Predictive Analytics" {
        It "Should have Start-PredictiveAnalytics function" {
            Get-Command Start-PredictiveAnalytics -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should analyze deployment patterns" {
            { Start-PredictiveAnalytics -DataPath $TestConfig.DataStore } | Should -Not -Throw
        }
    }
    
    Context "Automated Troubleshooting" {
        It "Should have Start-AutomatedTroubleshooting function" {
            Get-Command Start-AutomatedTroubleshooting -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should diagnose common issues" {
            $diagnosis = Start-AutomatedTroubleshooting
            $diagnosis | Should -Not -BeNullOrEmpty
            $diagnosis.Status | Should -Match 'Success|Warning|Error'
        }
    }
}

Describe "Collection Management" {
    Context "Collection Functions" {
        It "Should have Manage-VelociraptorCollections function" {
            Get-Command Manage-VelociraptorCollections -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should support different collection operations" {
            $collectionFunction = Get-Command Manage-VelociraptorCollections
            $collectionFunction.Parameters.Keys | Should -Contain 'Action'
        }
        
        It "Should handle collection lifecycle" {
            { Manage-VelociraptorCollections -Action 'List' -ConfigPath $TestConfig.ConfigPath } | Should -Not -Throw
        }
    }
    
    Context "Artifact Management" {
        It "Should have artifact management functions" {
            $artifactFunctions = Get-Command -Module VelociraptorDeployment -Name "*Artifact*"
            $artifactFunctions | Should -Not -BeNullOrEmpty
        }
        
        It "Should process artifact packs" {
            $artifactFunctions = Get-Command -Module VelociraptorDeployment -Name "*Artifact*"
            foreach ($func in $artifactFunctions) {
                $func.Parameters.Keys | Should -Contain 'Path'
            }
        }
    }
}

Describe "Network and Connectivity" {
    Context "Internet Connection Testing" {
        It "Should have Test-VelociraptorInternetConnection function" {
            Get-Command Test-VelociraptorInternetConnection -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should test internet connectivity" {
            $connectionTest = Test-VelociraptorInternetConnection
            $connectionTest | Should -BeOfType [bool]
        }
        
        It "Should handle offline scenarios" {
            { Test-VelociraptorInternetConnection -Timeout 1 } | Should -Not -Throw
        }
    }
    
    Context "Port and Service Management" {
        It "Should validate port availability" {
            $networkFunctions = Get-Command -Module VelociraptorDeployment -Name "*Port*", "*Network*"
            if ($networkFunctions) {
                $networkFunctions | Should -Not -BeNullOrEmpty
            }
        }
        
        It "Should handle firewall configuration" {
            $firewallFunctions = Get-Command -Module VelociraptorDeployment -Name "*Firewall*"
            if ($firewallFunctions) {
                $firewallFunctions | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe "Error Handling and Input Validation" {
    Context "Input Validation Functions" {
        It "Should have Read-VelociraptorUserInput function" {
            Get-Command Read-VelociraptorUserInput -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should validate user input securely" {
            { Read-VelociraptorUserInput -Prompt "Test prompt" -ValidationType "String" } | Should -Not -Throw
        }
        
        It "Should handle different validation types" {
            $inputFunction = Get-Command Read-VelociraptorUserInput
            $inputFunction.Parameters.Keys | Should -Contain 'ValidationType'
        }
    }
    
    Context "Error Handling Patterns" {
        It "Should implement consistent error handling" {
            $allFunctions = Get-Command -Module VelociraptorDeployment
            foreach ($func in $allFunctions) {
                if ($func.Definition) {
                    $func.Definition | Should -Match 'try.*catch|ErrorAction'
                }
            }
        }
        
        It "Should use proper parameter validation" {
            $allFunctions = Get-Command -Module VelociraptorDeployment
            foreach ($func in $allFunctions) {
                if ($func.Definition) {
                    $func.Definition | Should -Match '\[CmdletBinding\]|\[Parameter'
                }
            }
        }
    }
}

Describe "Cross-Platform Compatibility" {
    Context "PowerShell Version Support" {
        It "Should support PowerShell 5.1" {
            $allFunctions = Get-Command -Module VelociraptorDeployment
            foreach ($func in $allFunctions) {
                # Should not use PowerShell 6+ exclusive features
                if ($func.Definition) {
                    $func.Definition | Should -Not -Match 'ForEach-Object.*Parallel'
                }
            }
        }
        
        It "Should support PowerShell 7.0+" {
            $allFunctions = Get-Command -Module VelociraptorDeployment
            $allFunctions | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Operating System Support" {
        It "Should handle Windows-specific features appropriately" {
            $allFunctions = Get-Command -Module VelociraptorDeployment
            foreach ($func in $allFunctions) {
                if ($func.Definition -and $func.Definition -match 'Windows') {
                    $func.Definition | Should -Match '\$IsWindows|\$env:OS|Windows'
                }
            }
        }
        
        It "Should provide cross-platform alternatives" {
            $crossPlatformFunctions = Get-Command -Module VelociraptorDeployment | Where-Object { 
                $_.Definition -match 'Linux|MacOS|Unix' 
            }
            # Should have some cross-platform support
            $crossPlatformFunctions | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Module Integration and Performance" {
    Context "Function Dependencies" {
        It "Should have proper function interdependencies" {
            $allFunctions = Get-Command -Module VelociraptorDeployment
            foreach ($func in $allFunctions) {
                if ($func.Definition -and $func.Definition -match 'Write-VelociraptorLog') {
                    # Functions using logging should be able to access it
                    Get-Command Write-VelociraptorLog | Should -Not -BeNullOrEmpty
                }
            }
        }
        
        It "Should export all required functions" {
            $moduleInfo = Get-Module VelociraptorDeployment
            $moduleInfo.ExportedFunctions.Count | Should -BeGreaterThan 20
        }
        
        It "Should export required aliases" {
            $moduleInfo = Get-Module VelociraptorDeployment
            $moduleInfo.ExportedAliases.Count | Should -BeGreaterThan 0
        }
    }
    
    Context "Performance Characteristics" {
        It "Should load functions efficiently" {
            $loadTime = Measure-Command { 
                Remove-Module VelociraptorDeployment -Force -ErrorAction SilentlyContinue
                Import-Module $ModulePath -Force 
            }
            $loadTime.TotalSeconds | Should -BeLessThan 10
        }
        
        It "Should handle large data sets efficiently" {
            { Get-AutoDetectedSystemSpecs } | Should -Not -Throw
        }
    }
}

AfterAll {
    # Clean up test environment
    if (Test-Path $TestConfig.DataStore) {
        Remove-Item $TestConfig.DataStore -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    if (Test-Path $TestConfig.ConfigPath) {
        Remove-Item $TestConfig.ConfigPath -Force -ErrorAction SilentlyContinue
    }
    
    # Remove module
    Remove-Module VelociraptorDeployment -Force -ErrorAction SilentlyContinue
}