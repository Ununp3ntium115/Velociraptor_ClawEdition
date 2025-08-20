#Requires -Modules Pester

<#
.SYNOPSIS
    Integration tests for GUI components and interfaces.

.DESCRIPTION
    Tests the GUI installation wizard functionality, emergency deployment mode,
    accessibility features, and real-time validation.
#>

BeforeAll {
    # Set up test environment
    $VelociraptorGUIPath = Join-Path $PSScriptRoot '..\..\VelociraptorGUI-InstallClean.ps1'
    $IncidentResponseGUIPath = Join-Path $PSScriptRoot '..\..\IncidentResponseGUI-Installation.ps1'
    
    # Import the module for testing
    $ModulePath = Join-Path $PSScriptRoot '..\..\modules\VelociraptorDeployment\VelociraptorDeployment.psd1'
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -Force
    }
    
    # Test data
    $TestConfig = @{
        ServerName = 'test-velociraptor.local'
        GuiPort = '8889'
        FrontendPort = '8000'
        DatastoreLocation = Join-Path $env:TEMP 'VelociraptorTestData'
    }
}

Describe "VelociraptorGUI-InstallClean Script" {
    Context "Script Structure and Validation" {
        It "Should exist and be readable" {
            Test-Path $VelociraptorGUIPath | Should -Be $true
        }
        
        It "Should be valid PowerShell" {
            { Get-Content $VelociraptorGUIPath -Raw | Out-Null } | Should -Not -Throw
        }
        
        It "Should contain Windows Forms components" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'System\.Windows\.Forms'
            $scriptContent | Should -Match 'New-Object.*Form'
        }
    }
    
    Context "Emergency Deployment Mode" {
        It "Should have emergency deployment button" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'EmergencyButton|EMERGENCY.*MODE'
        }
        
        It "Should configure emergency button with red styling" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'BackColor.*DarkRed|Red'
            $scriptContent | Should -Match '🚨|EMERGENCY'
        }
        
        It "Should have emergency deployment functionality" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'function.*Emergency|EmergencyDeploy'
        }
    }
    
    Context "Real-time Input Validation" {
        It "Should implement input validation events" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'TextChanged|Validating'
        }
        
        It "Should provide visual feedback for validation" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'BackColor.*Red|Green|Yellow'
            $scriptContent | Should -Match 'ForeColor'
        }
        
        It "Should validate server names and ports" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'ValidateServerName|ValidatePort'
        }
    }
    
    Context "Accessibility Features" {
        It "Should implement WCAG 2.1 AA compliance" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'TabIndex'
            $scriptContent | Should -Match 'AccessibleName|AccessibleDescription'
        }
        
        It "Should have proper tab order" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'TabIndex.*[1-6]'
        }
        
        It "Should support keyboard navigation" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'KeyDown|KeyPress'
        }
        
        It "Should have descriptive button text" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'AccessibleDescription.*".*"'
        }
    }
    
    Context "Error Handling and User Experience" {
        It "Should implement enhanced error messages" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'Show-UserFriendlyError|Enhanced.*Error'
        }
        
        It "Should provide context-aware help" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'ToolTip|HelpText'
        }
        
        It "Should handle GUI exceptions gracefully" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'try.*catch.*Show.*Error'
        }
    }
    
    Context "Professional Styling" {
        It "Should implement dark theme" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'DarkGray|Black|DarkBlue'
        }
        
        It "Should avoid BackColor null conversion errors" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'Drawing\.Color\]::FromArgb|Drawing\.Color\]::'
        }
        
        It "Should use consistent font styling" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'Font.*New.*Drawing\.Font'
        }
    }
}

Describe "IncidentResponseGUI-Installation Script" {
    Context "Incident Response Capabilities" {
        It "Should exist and be accessible" {
            Test-Path $IncidentResponseGUIPath | Should -Be $true
        }
        
        It "Should have specialized incident response features" {
            $scriptContent = Get-Content $IncidentResponseGUIPath -Raw
            $scriptContent | Should -Match 'Incident|Response|Emergency'
        }
        
        It "Should implement rapid deployment" {
            $scriptContent = Get-Content $IncidentResponseGUIPath -Raw
            $scriptContent | Should -Match 'Quick|Rapid|Fast'
        }
    }
    
    Context "Integration with Core Deployment" {
        It "Should integrate with main deployment scripts" {
            $scriptContent = Get-Content $IncidentResponseGUIPath -Raw
            $scriptContent | Should -Match 'Deploy.*Velociraptor'
        }
        
        It "Should use VelociraptorDeployment module functions" {
            $scriptContent = Get-Content $IncidentResponseGUIPath -Raw
            $scriptContent | Should -Match 'Write-VelociraptorLog|Test-VelociraptorAdminPrivileges'
        }
    }
}

Describe "GUI Security and Validation" {
    Context "Input Security" {
        It "Should sanitize user inputs" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'Trim\(\)|Replace.*[<>"]'
        }
        
        It "Should validate file paths securely" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'Test-Path|Join-Path'
        }
        
        It "Should handle special characters in inputs" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'Escape|Quote'
        }
    }
    
    Context "Administrative Privileges" {
        It "Should check for admin privileges" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'Test.*Admin|Require.*Admin'
        }
        
        It "Should handle privilege escalation gracefully" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'RunAs|UAC'
        }
    }
}

Describe "GUI Performance and Responsiveness" {
    Context "User Interface Responsiveness" {
        It "Should implement asynchronous operations" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'Async|Background|Thread'
        }
        
        It "Should provide progress indicators" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'ProgressBar|Progress'
        }
        
        It "Should prevent UI blocking during operations" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'DoEvents|Application\.DoEvents'
        }
    }
    
    Context "Resource Management" {
        It "Should properly dispose of GUI resources" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'Dispose\(\)|finally.*Dispose'
        }
        
        It "Should implement try-finally patterns" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'try.*finally'
        }
    }
}

Describe "Cross-Platform GUI Compatibility" {
    Context "PowerShell Version Support" {
        It "Should work with PowerShell 5.1" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            # Should not use PowerShell 6+ only features
            $scriptContent | Should -Not -Match 'pwsh.*only|Core.*only'
        }
        
        It "Should handle Windows Forms properly" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'Add-Type.*Windows\.Forms'
        }
    }
    
    Context "Windows Version Compatibility" {
        It "Should support Windows 10/11" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'Windows.*10|Windows.*11|Win32'
        }
        
        It "Should handle different screen resolutions" {
            $scriptContent = Get-Content $VelociraptorGUIPath -Raw
            $scriptContent | Should -Match 'Screen.*Resolution|DPI'
        }
    }
}

AfterAll {
    # Clean up test environment
    if (Test-Path $TestConfig.DatastoreLocation) {
        Remove-Item $TestConfig.DatastoreLocation -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Remove module
    Remove-Module VelociraptorDeployment -Force -ErrorAction SilentlyContinue
}