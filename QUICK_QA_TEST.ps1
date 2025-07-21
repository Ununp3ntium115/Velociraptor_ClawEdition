#!/usr/bin/env pwsh

Write-Host "🚀 Quick QA Test Starting..." -ForegroundColor Green

# Test 1: Find all PowerShell scripts
Write-Host "`n=== Finding PowerShell Scripts ===" -ForegroundColor Magenta
$psScripts = Get-ChildItem "*.ps1" -Recurse | Where-Object { 
    $_.Name -notlike "*Test*" -and 
    $_.Directory.Name -notlike "*\.git*" -and
    $_.Name -ne "COMPREHENSIVE_BETA_QA.ps1" -and
    $_.Name -ne "QUICK_QA_TEST.ps1"
}

Write-Host "Found $($psScripts.Count) PowerShell scripts:" -ForegroundColor Cyan
foreach ($script in $psScripts) {
    Write-Host "  - $($script.Name)" -ForegroundColor White
    
    # Quick syntax test
    try {
        $content = Get-Content $script.FullName -Raw
        $null = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
        Write-Host "    ✅ Syntax OK" -ForegroundColor Green
    }
    catch {
        Write-Host "    ❌ Syntax Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 2: Find all shell scripts
Write-Host "`n=== Finding Shell Scripts ===" -ForegroundColor Magenta
$shellScripts = Get-ChildItem "*.sh" -Recurse | Where-Object { $_.Directory.Name -notlike "*\.git*" }

Write-Host "Found $($shellScripts.Count) shell scripts:" -ForegroundColor Cyan
foreach ($script in $shellScripts) {
    Write-Host "  - $($script.Name)" -ForegroundColor White
    
    # Check for shebang
    $firstLine = Get-Content $script.FullName -TotalCount 1
    if ($firstLine -match '^#!/') {
        Write-Host "    ✅ Has shebang: $firstLine" -ForegroundColor Green
    }
    else {
        Write-Host "    ⚠️ Missing shebang" -ForegroundColor Yellow
    }
}

# Test 3: Find all modules
Write-Host "`n=== Finding Modules ===" -ForegroundColor Magenta
$modules = Get-ChildItem "modules" -Directory -ErrorAction SilentlyContinue

if ($modules) {
    Write-Host "Found $($modules.Count) modules:" -ForegroundColor Cyan
    foreach ($module in $modules) {
        Write-Host "  - $($module.Name)" -ForegroundColor White
        
        # Check for manifest
        $manifest = Get-ChildItem $module.FullName -Filter "*.psd1" | Select-Object -First 1
        if ($manifest) {
            try {
                $manifestData = Test-ModuleManifest $manifest.FullName -ErrorAction Stop
                Write-Host "    ✅ Valid manifest (v$($manifestData.Version))" -ForegroundColor Green
            }
            catch {
                Write-Host "    ❌ Invalid manifest: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        else {
            Write-Host "    ⚠️ No manifest found" -ForegroundColor Yellow
        }
    }
}
else {
    Write-Host "No modules directory found" -ForegroundColor Yellow
}

# Test 4: Find GUI files
Write-Host "`n=== Finding GUI Files ===" -ForegroundColor Magenta
$guiFiles = @()
$guiFiles += Get-ChildItem "*GUI*.ps1" -Recurse -ErrorAction SilentlyContinue
$guiFiles += Get-ChildItem "gui/*.ps1" -Recurse -ErrorAction SilentlyContinue

if ($guiFiles.Count -gt 0) {
    Write-Host "Found $($guiFiles.Count) GUI files:" -ForegroundColor Cyan
    foreach ($gui in $guiFiles) {
        Write-Host "  - $($gui.Name)" -ForegroundColor White
        
        # Check for Windows Forms
        $content = Get-Content $gui.FullName -Raw
        if ($content -match 'System\.Windows\.Forms|System\.Drawing') {
            Write-Host "    ✅ Uses Windows Forms" -ForegroundColor Green
        }
        else {
            Write-Host "    ⚠️ No Windows Forms detected" -ForegroundColor Yellow
        }
    }
}
else {
    Write-Host "No GUI files found" -ForegroundColor Yellow
}

Write-Host "`n🎯 Quick QA Test Complete!" -ForegroundColor Green