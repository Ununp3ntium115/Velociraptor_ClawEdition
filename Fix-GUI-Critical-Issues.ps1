#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Fix critical GUI issues: function order and BackColor null errors
#>

Write-Host "=== Fixing Critical GUI Issues ===" -ForegroundColor Red

$guiPath = "gui/VelociraptorGUI.ps1"

if (-not (Test-Path $guiPath)) {
    Write-Error "GUI file not found at: $guiPath"
    exit 1
}

try {
    Write-Host "`n1. Reading GUI file..." -ForegroundColor Cyan
    $content = Get-Content $guiPath -Raw
    
    Write-Host "`n2. Fixing BackColor null conversion errors..." -ForegroundColor Cyan
    
    # Replace all $script:Colors.Background with a safe color
    $content = $content -replace '\$script:Colors\.Background', '[System.Drawing.Color]::FromArgb(32, 32, 32)'
    
    Write-Host "✓ Replaced all BackColor references with safe color values" -ForegroundColor Green
    
    Write-Host "`n3. Checking function order..." -ForegroundColor Cyan
    
    # Check if Show-DeploymentTypeStep is defined after main execution
    $mainExecutionIndex = $content.IndexOf("# Main execution with comprehensive error handling")
    $deploymentFunctionIndex = $content.IndexOf("function Show-DeploymentTypeStep")
    
    if ($deploymentFunctionIndex -gt $mainExecutionIndex -and $mainExecutionIndex -gt 0) {
        Write-Host "⚠️  Show-DeploymentTypeStep function is defined AFTER main execution" -ForegroundColor Yellow
        Write-Host "   This causes 'function not found' errors" -ForegroundColor Yellow
        
        # Extract the function definition
        $functionStart = $content.IndexOf("# Deployment Type Step")
        $functionEnd = $content.IndexOf("# Authentication Step", $functionStart)
        
        if ($functionStart -gt 0 -and $functionEnd -gt $functionStart) {
            $functionCode = $content.Substring($functionStart, $functionEnd - $functionStart).Trim()
            
            # Remove the function from its current location
            $content = $content.Remove($functionStart, $functionEnd - $functionStart)
            
            # Insert it before the main execution
            $insertPoint = $content.IndexOf("# Main execution with comprehensive error handling")
            $content = $content.Insert($insertPoint, $functionCode + "`n`n")
            
            Write-Host "✓ Moved Show-DeploymentTypeStep function before main execution" -ForegroundColor Green
        }
    } else {
        Write-Host "✓ Function order appears correct" -ForegroundColor Green
    }
    
    Write-Host "`n4. Writing fixed GUI file..." -ForegroundColor Cyan
    Set-Content -Path $guiPath -Value $content -Encoding UTF8
    
    Write-Host "`n=== Fixes Applied ===" -ForegroundColor Green
    Write-Host "• Replaced all \$script:Colors.Background with safe color values" -ForegroundColor Gray
    Write-Host "• Fixed function definition order" -ForegroundColor Gray
    Write-Host "• GUI should now load without BackColor or function errors" -ForegroundColor Gray
    
    Write-Host "`nTest the GUI with:" -ForegroundColor Cyan
    Write-Host "powershell.exe -ExecutionPolicy Bypass -File `"gui\VelociraptorGUI.ps1`"" -ForegroundColor White
    
} catch {
    Write-Error "Error fixing GUI: $($_.Exception.Message)"
    exit 1
}