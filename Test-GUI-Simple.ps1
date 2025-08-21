#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Simple GUI Interactivity Test

.DESCRIPTION
    Basic validation of GUI interactivity features
#>

param(
    [string]$GUIScript = ".\Enhanced-Package-GUI-Interactive.ps1"
)

Write-Host "============================================" -ForegroundColor Green
Write-Host "GUI INTERACTIVITY TESTING" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green

Write-Host "`nTesting GUI Script: $GUIScript" -ForegroundColor Cyan

# Test 1: Syntax validation
Write-Host "`n1. Syntax Validation:" -ForegroundColor Yellow
try {
    if (Test-Path $GUIScript) {
        $errors = $null
        $content = Get-Content $GUIScript -Raw
        $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors)
        
        if ($errors.Count -eq 0) {
            Write-Host "   ✅ PowerShell syntax: VALID" -ForegroundColor Green
        } else {
            Write-Host "   ❌ PowerShell syntax: ERRORS FOUND" -ForegroundColor Red
            $errors | ForEach-Object { Write-Host "     Line $($_.Token.StartLine): $($_.Message)" -ForegroundColor Red }
        }
    } else {
        Write-Host "   ❌ File not found: $GUIScript" -ForegroundColor Red
    }
} catch {
    Write-Host "   ❌ Syntax check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Interactivity Features
Write-Host "`n2. Interactivity Features:" -ForegroundColor Yellow

$content = Get-Content $GUIScript -Raw

# Check for enabled controls
$enabledControls = ($content | Select-String "\.Enabled\s*=\s*\`$true" -AllMatches).Matches.Count
Write-Host "   • Enabled controls: $enabledControls" -ForegroundColor $(if ($enabledControls -gt 0) { "Green" } else { "Red" })

# Check for tab order
$tabOrder = ($content | Select-String "\.TabIndex\s*=" -AllMatches).Matches.Count
Write-Host "   • Tab order settings: $tabOrder" -ForegroundColor $(if ($tabOrder -gt 0) { "Green" } else { "Red" })

# Check for event handlers
$eventHandlers = ($content | Select-String "Add_\w+" -AllMatches).Matches.Count
Write-Host "   • Event handlers: $eventHandlers" -ForegroundColor $(if ($eventHandlers -gt 5) { "Green" } else { "Red" })

# Check for focus effects
$focusEffects = ($content | Select-String "GotFocus|LostFocus|BackColor.*Focus" -AllMatches).Matches.Count
Write-Host "   • Focus effects: $focusEffects" -ForegroundColor $(if ($focusEffects -gt 0) { "Green" } else { "Red" })

# Check for password fields
$passwordFields = ($content | Select-String "UseSystemPasswordChar|PasswordChar" -AllMatches).Matches.Count
Write-Host "   • Password field security: $passwordFields" -ForegroundColor $(if ($passwordFields -gt 0) { "Green" } else { "Red" })

# Check for radio buttons
$radioButtons = ($content | Select-String "RadioButton.*CheckedChanged" -AllMatches).Matches.Count
Write-Host "   • Radio button interactions: $radioButtons" -ForegroundColor $(if ($radioButtons -gt 0) { "Green" } else { "Red" })

# Check for checkboxes
$checkBoxes = ($content | Select-String "CheckBox.*Checked" -AllMatches).Matches.Count
Write-Host "   • Checkbox interactions: $checkBoxes" -ForegroundColor $(if ($checkBoxes -gt 0) { "Green" } else { "Red" })

# Check for visual feedback
$visualFeedback = ($content | Select-String "MouseEnter|MouseLeave|Cursor.*Hand" -AllMatches).Matches.Count
Write-Host "   • Visual feedback: $visualFeedback" -ForegroundColor $(if ($visualFeedback -gt 0) { "Green" } else { "Red" })

# Test 3: Overall Assessment
Write-Host "`n3. Overall Assessment:" -ForegroundColor Yellow

$totalFeatures = 8
$implementedFeatures = 0

if ($enabledControls -gt 0) { $implementedFeatures++ }
if ($tabOrder -gt 0) { $implementedFeatures++ }
if ($eventHandlers -gt 5) { $implementedFeatures++ }
if ($focusEffects -gt 0) { $implementedFeatures++ }
if ($passwordFields -gt 0) { $implementedFeatures++ }
if ($radioButtons -gt 0) { $implementedFeatures++ }
if ($checkBoxes -gt 0) { $implementedFeatures++ }
if ($visualFeedback -gt 0) { $implementedFeatures++ }

$score = [math]::Round(($implementedFeatures / $totalFeatures) * 100, 1)

Write-Host "   • Features implemented: $implementedFeatures/$totalFeatures" -ForegroundColor Cyan
Write-Host "   • Interactivity score: $score%" -ForegroundColor $(if ($score -ge 80) { "Green" } elseif ($score -ge 60) { "Yellow" } else { "Red" })

if ($score -ge 90) {
    Write-Host "`n🏆 EXCELLENT - GUI has superior interactivity!" -ForegroundColor Green
} elseif ($score -ge 80) {
    Write-Host "`n✅ GOOD - GUI meets professional interactivity standards" -ForegroundColor Green
} elseif ($score -ge 60) {
    Write-Host "`n⚠️ FAIR - GUI needs some interactivity improvements" -ForegroundColor Yellow
} else {
    Write-Host "`n❌ POOR - GUI requires significant interactivity fixes" -ForegroundColor Red
}

Write-Host "`n============================================" -ForegroundColor Green
Write-Host "Testing Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green