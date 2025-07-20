#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Fix ALL remaining BackColor issues in the GUI
#>

Write-Host "=== Fixing ALL BackColor Issues ===" -ForegroundColor Red

$guiPath = "gui/VelociraptorGUI.ps1"

if (-not (Test-Path $guiPath)) {
    Write-Error "GUI file not found"
    exit 1
}

try {
    $content = Get-Content $guiPath -Raw
    
    Write-Host "Replacing all remaining BackColor script variable references..." -ForegroundColor Cyan
    
    # Replace all remaining $script:Colors references with safe values
    $replacements = @{
        '\$script:Colors\.Surface' = '[System.Drawing.Color]::FromArgb(48, 48, 48)'
        '\$script:Colors\.Primary' = '[System.Drawing.Color]::FromArgb(0, 150, 136)'
        '\$script:Colors\.Text' = '[System.Drawing.Color]::FromArgb(255, 255, 255)'
        '\$script:Colors\.Success' = '[System.Drawing.Color]::FromArgb(76, 175, 80)'
        '\$script:Colors\.Error' = '[System.Drawing.Color]::FromArgb(244, 67, 54)'
        '\$script:Colors\.Warning' = '[System.Drawing.Color]::FromArgb(255, 193, 7)'
        '\$script:Colors\.Accent' = '[System.Drawing.Color]::FromArgb(76, 175, 80)'
        '\$script:Colors\.TextSecondary' = '[System.Drawing.Color]::FromArgb(200, 200, 200)'
    }
    
    foreach ($pattern in $replacements.Keys) {
        $replacement = $replacements[$pattern]
        $oldCount = ($content | Select-String $pattern -AllMatches).Matches.Count
        $content = $content -replace $pattern, $replacement
        $newCount = ($content | Select-String $pattern -AllMatches).Matches.Count
        if ($oldCount -gt 0) {
            Write-Host "✓ Replaced $oldCount instances of $pattern" -ForegroundColor Green
        }
    }
    
    Write-Host "`nWriting fixed GUI file..." -ForegroundColor Cyan
    Set-Content -Path $guiPath -Value $content -Encoding UTF8
    
    Write-Host "`n=== ALL BackColor Issues Fixed ===" -ForegroundColor Green
    Write-Host "• All \$script:Colors references replaced with safe color values" -ForegroundColor Gray
    Write-Host "• GUI should now load without any BackColor conversion errors" -ForegroundColor Gray
    
} catch {
    Write-Error "Error fixing BackColor issues: $($_.Exception.Message)"
}