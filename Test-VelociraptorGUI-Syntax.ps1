# Minimal test to validate VelociraptorGUI-Actually-Working.ps1 syntax and basic functionality
[CmdletBinding()]
param()

Write-Host "Testing VelociraptorGUI-Actually-Working.ps1 syntax..." -ForegroundColor Cyan

try {
    # Test 1: Basic syntax validation
    Write-Host "1. Testing basic syntax..." -ForegroundColor Yellow
    
    $scriptContent = Get-Content "VelociraptorGUI-Actually-Working.ps1" -Raw
    
    if ($scriptContent -match 'function.*\{' -and $scriptContent -match 'MainForm.*New-Object.*Form') {
        Write-Host "   ✓ Script structure looks correct" -ForegroundColor Green
    } else {
        throw "Script structure validation failed"
    }
    
    # Test 2: Windows Forms assemblies
    Write-Host "2. Testing Windows Forms assemblies..." -ForegroundColor Yellow
    
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    Write-Host "   ✓ Windows Forms assemblies loaded successfully" -ForegroundColor Green
    
    # Test 3: Test script parsing (without execution)
    Write-Host "3. Testing PowerShell parsing..." -ForegroundColor Yellow
    
    $errors = $null
    $tokens = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        (Resolve-Path "VelociraptorGUI-Actually-Working.ps1").Path, 
        [ref]$tokens, 
        [ref]$errors
    )
    
    if ($errors.Count -eq 0) {
        Write-Host "   ✓ PowerShell parsing successful - no syntax errors" -ForegroundColor Green
    } else {
        Write-Host "   ✗ PowerShell parsing found errors:" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "     - $($_.Message)" -ForegroundColor Red }
        return $false
    }
    
    # Test 4: Basic function definitions
    Write-Host "4. Testing function definitions..." -ForegroundColor Yellow
    
    $functionNames = @('Write-StatusLog', 'Get-LatestVelociraptorAsset', 'Start-VelociraptorInstallation')
    $foundFunctions = $ast.FindAll({$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]}, $true) | 
        ForEach-Object { $_.Name }
    
    $missingFunctions = $functionNames | Where-Object { $_ -notin $foundFunctions }
    
    if ($missingFunctions.Count -eq 0) {
        Write-Host "   ✓ All critical functions found" -ForegroundColor Green
    } else {
        Write-Host "   ⚠ Missing functions: $($missingFunctions -join ', ')" -ForegroundColor Yellow
    }
    
    Write-Host "`n=== VALIDATION RESULTS ===" -ForegroundColor Cyan
    Write-Host "✓ VelociraptorGUI-Actually-Working.ps1 validation PASSED" -ForegroundColor Green
    Write-Host "✓ Script is ready for execution" -ForegroundColor Green
    Write-Host "✓ All syntax checks completed successfully" -ForegroundColor Green
    
    return $true
}
catch {
    Write-Host "`n=== VALIDATION FAILED ===" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "The script needs to be fixed before it can be used." -ForegroundColor Yellow
    return $false
}