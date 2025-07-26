#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Beta Testing Environment Setup Script

.DESCRIPTION
    Sets up clean testing environment for Velociraptor Setup Scripts beta testing.
    Creates test data, validates prerequisites, and prepares testing scenarios.

.EXAMPLE
    .\setup-beta-environment.ps1
#>

[CmdletBinding()]
param(
    [string]$TestDataPath = ".\test-data",
    [switch]$SkipVMCheck
)

Write-Host "🦖 Setting up Beta Testing Environment" -ForegroundColor Cyan
Write-Host "=" * 50

# Create test data directory
if (-not (Test-Path $TestDataPath)) {
    New-Item -ItemType Directory -Path $TestDataPath -Force
    Write-Host "✅ Created test data directory: $TestDataPath" -ForegroundColor Green
}

# Create test certificate files for custom cert testing
$testCertPath = Join-Path $TestDataPath "test-certificates"
if (-not (Test-Path $testCertPath)) {
    New-Item -ItemType Directory -Path $testCertPath -Force
    
    # Create dummy certificate files for testing
    @"
-----BEGIN CERTIFICATE-----
MIICljCCAX4CCQDKn7+5Z5Z5ZjANBgkqhkiG9w0BAQsFADCBjDELMAkGA1UEBhMC
VVMxCzAJBgNVBAgMAkNBMRYwFAYDVQQHDA1TYW4gRnJhbmNpc2NvMRMwEQYDVQQK
DApWZWxvY2lyYXB0b3IxEzARBgNVBAsMClRlc3QgU3VpdGUxKDAmBgNVBAMMH1Rl
c3QgQ2VydGlmaWNhdGUgLSBOT1QgRk9SIFBST0Q=
-----END CERTIFICATE-----
"@ | Out-File -FilePath (Join-Path $testCertPath "test-cert.pem") -Encoding UTF8

    @"
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC5Z5Z5Z5Z5Z5Z5
Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5
Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5
TEST PRIVATE KEY - NOT FOR PRODUCTION USE
-----END PRIVATE KEY-----
"@ | Out-File -FilePath (Join-Path $testCertPath "test-key.pem") -Encoding UTF8

    Write-Host "✅ Created test certificate files" -ForegroundColor Green
}

# Create test domains list for Let's Encrypt testing
$testDomainsFile = Join-Path $TestDataPath "test-domains.txt"
@"
# Test domains for Let's Encrypt testing
# WARNING: These are for testing only - do not use in production

test-velociraptor.example.com
beta-velociraptor.example.com
staging-velociraptor.example.com

# Note: Replace with actual domains you control for real testing
"@ | Out-File -FilePath $testDomainsFile -Encoding UTF8

Write-Host "✅ Created test domains file" -ForegroundColor Green

# Create beta testing checklist tracker
$checklistTracker = Join-Path $TestDataPath "beta-testing-progress.json"
$progressData = @{
    "testingStarted" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "scenarios" = @{
        "freshInstallation" = @{
            "status" = "pending"
            "platforms" = @{
                "windowsServer2019" = "pending"
                "windowsServer2022" = "pending"
                "windows10Pro" = "pending"
                "ubuntu2004" = "pending"
                "ubuntu2204" = "pending"
            }
        }
        "moduleImport" = @{
            "status" = "pending"
            "tests" = @{
                "individualScripts" = "pending"
                "functionAvailability" = "pending"
                "parameterValidation" = "pending"
                "crossScriptDependencies" = "pending"
            }
        }
        "guiWorkflow" = @{
            "status" = "pending"
            "encryptionOptions" = @{
                "selfSigned" = "pending"
                "customCert" = "pending"
                "letsEncrypt" = "pending"
            }
        }
        "crossPlatform" = @{
            "status" = "pending"
            "platforms" = @{
                "windows" = "pending"
                "linux" = "pending"
                "macos" = "pending"
            }
        }
        "errorHandling" = @{
            "status" = "pending"
            "scenarios" = @{
                "networkFailure" = "pending"
                "insufficientPermissions" = "pending"
                "invalidConfiguration" = "pending"
                "portConflicts" = "pending"
            }
        }
        "documentation" = @{
            "status" = "pending"
            "areas" = @{
                "readmeInstructions" = "pending"
                "configurationExamples" = "pending"
                "troubleshootingGuide" = "pending"
                "faqSections" = "pending"
            }
        }
    }
}

$progressData | ConvertTo-Json -Depth 10 | Out-File -FilePath $checklistTracker -Encoding UTF8
Write-Host "✅ Created beta testing progress tracker" -ForegroundColor Green

# Validate prerequisites
Write-Host "`n🔍 Validating Prerequisites..." -ForegroundColor Yellow

# Check PowerShell version
$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -ge 5) {
    Write-Host "✅ PowerShell $($psVersion.ToString()) - Compatible" -ForegroundColor Green
} else {
    Write-Host "❌ PowerShell $($psVersion.ToString()) - May have compatibility issues" -ForegroundColor Red
}

# Check Windows Forms availability
try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Write-Host "✅ Windows Forms - Available" -ForegroundColor Green
} catch {
    Write-Host "❌ Windows Forms - Not available (GUI testing will fail)" -ForegroundColor Red
}

# Check network connectivity
try {
    $testConnection = Test-NetConnection -ComputerName "github.com" -Port 443 -InformationLevel Quiet
    if ($testConnection) {
        Write-Host "✅ Network Connectivity - Available" -ForegroundColor Green
    } else {
        Write-Host "❌ Network Connectivity - Issues detected" -ForegroundColor Red
    }
} catch {
    Write-Host "⚠️ Network Connectivity - Could not test" -ForegroundColor Yellow
}

# VM Environment Check (if not skipped)
if (-not $SkipVMCheck) {
    Write-Host "`n🖥️ VM Environment Recommendations:" -ForegroundColor Yellow
    Write-Host "For comprehensive testing, prepare these VMs:" -ForegroundColor White
    Write-Host "  • Windows Server 2019 (Clean install)" -ForegroundColor Gray
    Write-Host "  • Windows Server 2022 (Clean install)" -ForegroundColor Gray
    Write-Host "  • Windows 10/11 Pro (Clean install)" -ForegroundColor Gray
    Write-Host "  • Ubuntu 20.04 LTS (Clean install)" -ForegroundColor Gray
    Write-Host "  • Ubuntu 22.04 LTS (Clean install)" -ForegroundColor Gray
    Write-Host "  • macOS (if PowerShell Core available)" -ForegroundColor Gray
}

# Create quick test script
$quickTestScript = Join-Path $TestDataPath "quick-test.ps1"
@"
#!/usr/bin/env pwsh
# Quick validation test for beta environment

Write-Host "🦖 Quick Beta Environment Test" -ForegroundColor Cyan

# Test GUI launch
try {
    Write-Host "Testing GUI launch..." -NoNewline
    . .\gui\VelociraptorGUI.ps1 -StartMinimized
    Write-Host " ✅ Success" -ForegroundColor Green
} catch {
    Write-Host " ❌ Failed: `$(`$_.Exception.Message)" -ForegroundColor Red
}

# Test module imports
try {
    Write-Host "Testing module imports..." -NoNewline
    . .\Deploy_Velociraptor_Server.ps1 -WhatIf
    Write-Host " ✅ Success" -ForegroundColor Green
} catch {
    Write-Host " ❌ Failed: `$(`$_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Quick test complete!" -ForegroundColor Green
"@ | Out-File -FilePath $quickTestScript -Encoding UTF8

Write-Host "✅ Created quick test script" -ForegroundColor Green

Write-Host "`n🎯 Beta Testing Environment Setup Complete!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Run quick test: .\test-data\quick-test.ps1" -ForegroundColor Gray
Write-Host "  2. Set up VM environments" -ForegroundColor Gray
Write-Host "  3. Begin UAT checklist execution" -ForegroundColor Gray
Write-Host "  4. Update progress in: $checklistTracker" -ForegroundColor Gray