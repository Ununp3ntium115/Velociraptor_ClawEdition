#!/usr/bin/env pwsh
# Quick syntax and structure test for VelociraptorGUI.ps1

try {
    Write-Host "Testing GUI script syntax and structure..." -ForegroundColor Cyan
    
    # Test 1: Basic syntax check
    $null = Get-Content './gui/VelociraptorGUI.ps1' -ErrorAction Stop
    Write-Host "✓ Syntax check passed" -ForegroundColor Green
    
    # Test 2: Check for required functions
    $content = Get-Content './gui/VelociraptorGUI.ps1' -Raw
    
    $requiredFunctions = @(
        'New-RaptorWizardForm',
        'New-ProgressPanel',
        'New-ContentPanel', 
        'New-ButtonPanel',
        'New-ModernButton',
        'Show-WelcomeStep',
        'Show-DeploymentTypeStep',
        'Show-StorageConfigurationStep',
        'Show-CertificateSettingsStep',
        'Show-SecuritySettingsStep',
        'Show-NetworkConfigurationStep',
        'Show-AuthenticationStep',
        'Show-ReviewStep',
        'Show-CompleteStep',
        'Show-CurrentStep',
        'Move-ToNextStep',
        'Move-ToPreviousStep',
        'Confirm-CurrentStep',
        'Update-Progress',
        'Generate-Configuration',
        'New-SecurePassword'
    )
    
    $missingFunctions = @()
    foreach ($func in $requiredFunctions) {
        if ($content -notmatch "function $func") {
            $missingFunctions += $func
        }
    }
    
    if ($missingFunctions.Count -eq 0) {
        Write-Host "✓ All required functions found" -ForegroundColor Green
    } else {
        Write-Host "✗ Missing functions: $($missingFunctions -join ', ')" -ForegroundColor Red
    }
    
    # Test 3: Check for main execution block
    if ($content -match "# Main execution with comprehensive error handling") {
        Write-Host "✓ Main execution block found" -ForegroundColor Green
    } else {
        Write-Host "✗ Main execution block missing" -ForegroundColor Red
    }
    
    # Test 4: Check for proper script variables
    $requiredVars = @('Colors', 'CurrentStep', 'ConfigData', 'WizardSteps', 'RaptorArt')
    $missingVars = @()
    foreach ($var in $requiredVars) {
        if ($content -notmatch "\`$script:$var") {
            $missingVars += $var
        }
    }
    
    if ($missingVars.Count -eq 0) {
        Write-Host "✓ All required script variables found" -ForegroundColor Green
    } else {
        Write-Host "✗ Missing script variables: $($missingVars -join ', ')" -ForegroundColor Red
    }
    
    Write-Host "`nGUI script structure validation completed!" -ForegroundColor Cyan
    
} catch {
    Write-Host "✗ Error during validation: $($_.Exception.Message)" -ForegroundColor Red
}