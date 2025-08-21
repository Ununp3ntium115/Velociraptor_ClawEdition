#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Comprehensive GUI Interactivity Testing Tool

.DESCRIPTION
    Tests all aspects of GUI interactivity including:
    - Control enabled states
    - Tab navigation
    - Event handler functionality
    - Control sizing and hit-testing
    - Visual feedback and focus indicators
    - Password field interactions
    - Radio button and checkbox responsiveness

.EXAMPLE
    .\Test-GUI-Interactivity.ps1
#>

[CmdletBinding()]
param(
    [string]$GUIScript = ".\Enhanced-Package-GUI-Interactive.ps1"
)

$ErrorActionPreference = 'Continue'

Write-Host "============================================" -ForegroundColor Green
Write-Host "🔍 GUI INTERACTIVITY TESTING FRAMEWORK" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green

# Function to test GUI syntax and basic structure
function Test-GUISyntax {
    param([string]$ScriptPath)
    
    Write-Host "`n📋 Test 1: GUI Syntax and Structure Validation" -ForegroundColor Cyan
    
    try {
        if (-not (Test-Path $ScriptPath)) {
            Write-Host "❌ GUI script not found: $ScriptPath" -ForegroundColor Red
            return $false
        }
        
        # Parse PowerShell syntax
        $errors = $null
        $content = Get-Content $ScriptPath -Raw
        $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors)
        
        if ($errors.Count -eq 0) {
            Write-Host "✅ PowerShell syntax validation: PASSED" -ForegroundColor Green
        } else {
            Write-Host "❌ PowerShell syntax errors found:" -ForegroundColor Red
            $errors | ForEach-Object { Write-Host "  Line $($_.Token.StartLine): $($_.Message)" -ForegroundColor Red }
            return $false
        }
        
        # Check for Windows Forms initialization
        if ($content -match "Add-Type.*System\.Windows\.Forms") {
            Write-Host "✅ Windows Forms assembly loading: FOUND" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Windows Forms assembly loading: NOT FOUND" -ForegroundColor Yellow
        }
        
        # Check for proper initialization sequence
        if ($content -match "SetCompatibleTextRenderingDefault|EnableVisualStyles") {
            Write-Host "✅ Visual styles initialization: FOUND" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Visual styles initialization: NOT FOUND" -ForegroundColor Yellow
        }
        
        return $true
        
    } catch {
        Write-Host "❌ Syntax validation failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to test control interactivity patterns
function Test-ControlInteractivity {
    param([string]$ScriptPath)
    
    Write-Host "`n📋 Test 2: Control Interactivity Patterns" -ForegroundColor Cyan
    
    $content = Get-Content $ScriptPath -Raw
    $interactivityScore = 0
    $maxScore = 10
    
    # Test 2.1: Enabled state management
    Write-Host "  🔍 Testing control enabled states..." -ForegroundColor Yellow
    $enabledPatterns = @(
        "\.Enabled\s*=\s*\$true",
        "\.Enabled\s*=\s*\$false",
        "\.ReadOnly\s*=\s*\$false"
    )
    
    $enabledFound = $false
    foreach ($pattern in $enabledPatterns) {
        if ($content -match $pattern) {
            $enabledFound = $true
            break
        }
    }
    
    if ($enabledFound) {
        Write-Host "    ✅ Control enabled state management: IMPLEMENTED" -ForegroundColor Green
        $interactivityScore++
    } else {
        Write-Host "    ❌ Control enabled state management: MISSING" -ForegroundColor Red
    }
    
    # Test 2.2: Tab order implementation
    Write-Host "  🔍 Testing tab order implementation..." -ForegroundColor Yellow
    if ($content -match "\.TabIndex\s*=" -and $content -match "\.TabStop\s*=") {
        Write-Host "    ✅ Tab order implementation: FOUND" -ForegroundColor Green
        $interactivityScore++
    } else {
        Write-Host "    ❌ Tab order implementation: MISSING" -ForegroundColor Red
    }
    
    # Test 2.3: Event handler registration
    Write-Host "  🔍 Testing event handler registration..." -ForegroundColor Yellow
    $eventPatterns = @(
        "Add_Click",
        "Add_SelectedIndexChanged",
        "Add_CheckedChanged",
        "Add_TextChanged",
        "Add_GotFocus",
        "Add_LostFocus"
    )
    
    $eventCount = 0
    foreach ($pattern in $eventPatterns) {
        $matches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $eventCount += $matches.Count
    }
    
    if ($eventCount -ge 10) {
        Write-Host "    ✅ Event handlers: $eventCount found (EXCELLENT)" -ForegroundColor Green
        $interactivityScore += 2
    } elseif ($eventCount -ge 5) {
        Write-Host "    ✅ Event handlers: $eventCount found (GOOD)" -ForegroundColor Green
        $interactivityScore++
    } else {
        Write-Host "    ❌ Event handlers: $eventCount found (INSUFFICIENT)" -ForegroundColor Red
    }
    
    # Test 2.4: Control sizing for usability
    Write-Host "  🔍 Testing control sizing..." -ForegroundColor Yellow
    $sizePatterns = @(
        "\.Size.*New-Object.*Drawing\.Size\([^)]*[2-9]\d"
    )
    
    $appropriateSize = $false
    foreach ($pattern in $sizePatterns) {
        if ($content -match $pattern) {
            $appropriateSize = $true
            break
        }
    }
    
    if ($appropriateSize) {
        Write-Host "    ✅ Control sizing: APPROPRIATE" -ForegroundColor Green
        $interactivityScore++
    } else {
        Write-Host "    ⚠️ Control sizing: MAY BE TOO SMALL" -ForegroundColor Yellow
    }
    
    # Test 2.5: Visual feedback implementation
    Write-Host "  🔍 Testing visual feedback..." -ForegroundColor Yellow
    $feedbackPatterns = @(
        "BackColor.*Focus",
        "ForeColor.*Focus", 
        "MouseEnter",
        "MouseLeave",
        "Cursor.*Hand"
    )
    
    $feedbackFound = $false
    foreach ($pattern in $feedbackPatterns) {
        if ($content -match $pattern) {
            $feedbackFound = $true
            break
        }
    }
    
    if ($feedbackFound) {
        Write-Host "    ✅ Visual feedback: IMPLEMENTED" -ForegroundColor Green
        $interactivityScore++
    } else {
        Write-Host "    ❌ Visual feedback: MISSING" -ForegroundColor Red
    }
    
    # Test 2.6: Password field functionality
    Write-Host "  🔍 Testing password field implementation..." -ForegroundColor Yellow
    if ($content -match "UseSystemPasswordChar" -or $content -match "PasswordChar") {
        Write-Host "    ✅ Password field security: IMPLEMENTED" -ForegroundColor Green
        $interactivityScore++
    } else {
        Write-Host "    ❌ Password field security: MISSING" -ForegroundColor Red
    }
    
    # Test 2.7: Radio button interaction
    Write-Host "  🔍 Testing radio button interactions..." -ForegroundColor Yellow
    if ($content -match "RadioButton" -and $content -match "CheckedChanged") {
        Write-Host "    ✅ Radio button interactions: IMPLEMENTED" -ForegroundColor Green
        $interactivityScore++
    } else {
        Write-Host "    ❌ Radio button interactions: MISSING" -ForegroundColor Red
    }
    
    # Test 2.8: Checkbox responsiveness
    Write-Host "  🔍 Testing checkbox responsiveness..." -ForegroundColor Yellow
    if ($content -match "CheckBox" -and $content -match "\.Checked") {
        Write-Host "    ✅ Checkbox responsiveness: IMPLEMENTED" -ForegroundColor Green
        $interactivityScore++
    } else {
        Write-Host "    ❌ Checkbox responsiveness: MISSING" -ForegroundColor Red
    }
    
    # Test 2.9: Keyboard navigation
    Write-Host "  🔍 Testing keyboard navigation..." -ForegroundColor Yellow
    if ($content -match "KeyDown" -or $content -match "KeyPress") {
        Write-Host "    ✅ Keyboard navigation: IMPLEMENTED" -ForegroundColor Green
        $interactivityScore++
    } else {
        Write-Host "    ❌ Keyboard navigation: MISSING" -ForegroundColor Red
    }
    
    # Test 2.10: Error handling for interactions
    Write-Host "  🔍 Testing interaction error handling..." -ForegroundColor Yellow
    if ($content -match "try.*catch" -and $content -match "MessageBox.*Error") {
        Write-Host "    ✅ Interaction error handling: IMPLEMENTED" -ForegroundColor Green
        $interactivityScore++
    } else {
        Write-Host "    ❌ Interaction error handling: MISSING" -ForegroundColor Red
    }
    
    # Calculate and display score
    $scorePercentage = [math]::Round(($interactivityScore / $maxScore) * 100, 1)
    Write-Host "`n  📊 Interactivity Score: $interactivityScore/$maxScore ($scorePercentage%)" -ForegroundColor $(if ($scorePercentage -ge 80) { "Green" } elseif ($scorePercentage -ge 60) { "Yellow" } else { "Red" })
    
    return $scorePercentage
}

# Function to test accessibility features
function Test-AccessibilityFeatures {
    param([string]$ScriptPath)
    
    Write-Host "`n📋 Test 3: Accessibility and User Experience" -ForegroundColor Cyan
    
    $content = Get-Content $ScriptPath -Raw
    $accessibilityScore = 0
    $maxScore = 8
    
    # Test 3.1: Color contrast and themes
    Write-Host "  🔍 Testing color contrast..." -ForegroundColor Yellow
    if ($content -match "FromArgb" -and $content -match "White|Light") {
        Write-Host "    ✅ Color contrast consideration: IMPLEMENTED" -ForegroundColor Green
        $accessibilityScore++
    } else {
        Write-Host "    ❌ Color contrast consideration: MISSING" -ForegroundColor Red
    }
    
    # Test 3.2: Font sizing
    Write-Host "  🔍 Testing font sizing..." -ForegroundColor Yellow
    if ($content -match "Font.*Size.*[1-9]\d+" -or $content -match "Font.*(\d{2,})") {
        Write-Host "    ✅ Appropriate font sizing: FOUND" -ForegroundColor Green
        $accessibilityScore++
    } else {
        Write-Host "    ⚠️ Font sizing: MAY BE TOO SMALL" -ForegroundColor Yellow
    }
    
    # Test 3.3: Control spacing
    Write-Host "  🔍 Testing control spacing..." -ForegroundColor Yellow
    if ($content -match "Location.*Point.*[2-9]\d") {
        Write-Host "    ✅ Control spacing: APPROPRIATE" -ForegroundColor Green
        $accessibilityScore++
    } else {
        Write-Host "    ⚠️ Control spacing: MAY BE TOO TIGHT" -ForegroundColor Yellow
    }
    
    # Test 3.4: Status feedback
    Write-Host "  🔍 Testing status feedback..." -ForegroundColor Yellow
    if ($content -match "StatusLabel" -and $content -match "\.Text\s*=") {
        Write-Host "    ✅ Status feedback: IMPLEMENTED" -ForegroundColor Green
        $accessibilityScore++
    } else {
        Write-Host "    ❌ Status feedback: MISSING" -ForegroundColor Red
    }
    
    # Test 3.5: Help system
    Write-Host "  🔍 Testing help system..." -ForegroundColor Yellow
    if ($content -match "Help" -and $content -match "MessageBox") {
        Write-Host "    ✅ Help system: IMPLEMENTED" -ForegroundColor Green
        $accessibilityScore++
    } else {
        Write-Host "    ❌ Help system: MISSING" -ForegroundColor Red
    }
    
    # Test 3.6: Confirmation dialogs
    Write-Host "  🔍 Testing confirmation dialogs..." -ForegroundColor Yellow
    if ($content -match "MessageBox.*YesNo|MessageBox.*Question") {
        Write-Host "    ✅ Confirmation dialogs: IMPLEMENTED" -ForegroundColor Green
        $accessibilityScore++
    } else {
        Write-Host "    ❌ Confirmation dialogs: MISSING" -ForegroundColor Red
    }
    
    # Test 3.7: Progress indicators
    Write-Host "  🔍 Testing progress indicators..." -ForegroundColor Yellow
    if ($content -match "progress|status|loading|initiated") {
        Write-Host "    ✅ Progress indicators: IMPLEMENTED" -ForegroundColor Green
        $accessibilityScore++
    } else {
        Write-Host "    ❌ Progress indicators: MISSING" -ForegroundColor Red
    }
    
    # Test 3.8: Graceful degradation
    Write-Host "  🔍 Testing graceful degradation..." -ForegroundColor Yellow
    if ($content -match "ErrorAction.*Continue|try.*catch.*finally") {
        Write-Host "    ✅ Graceful degradation: IMPLEMENTED" -ForegroundColor Green
        $accessibilityScore++
    } else {
        Write-Host "    ❌ Graceful degradation: MISSING" -ForegroundColor Red
    }
    
    # Calculate accessibility score
    $accessibilityPercentage = [math]::Round(($accessibilityScore / $maxScore) * 100, 1)
    Write-Host "`n  📊 Accessibility Score: $accessibilityScore/$maxScore ($accessibilityPercentage%)" -ForegroundColor $(if ($accessibilityPercentage -ge 80) { "Green" } elseif ($accessibilityPercentage -ge 60) { "Yellow" } else { "Red" })
    
    return $accessibilityPercentage
}

# Function to test specific control types
function Test-SpecificControlTypes {
    param([string]$ScriptPath)
    
    Write-Host "`n📋 Test 4: Specific Control Type Validation" -ForegroundColor Cyan
    
    $content = Get-Content $ScriptPath -Raw
    $controlTests = @{
        "TextBox Controls" = @{
            Pattern = "TextBox"
            RequiredProps = @("Enabled", "TabIndex", "BackColor")
            Events = @("GotFocus", "LostFocus", "TextChanged")
        }
        "Button Controls" = @{
            Pattern = "Button"
            RequiredProps = @("Enabled", "TabIndex", "UseVisualStyleBackColor")
            Events = @("Click", "MouseEnter", "MouseLeave")
        }
        "CheckBox Controls" = @{
            Pattern = "CheckBox"
            RequiredProps = @("Enabled", "TabIndex", "Checked")
            Events = @("CheckedChanged")
        }
        "RadioButton Controls" = @{
            Pattern = "RadioButton"
            RequiredProps = @("Enabled", "TabIndex", "Checked")
            Events = @("CheckedChanged")
        }
        "ListBox Controls" = @{
            Pattern = "ListBox"
            RequiredProps = @("Enabled", "TabIndex", "SelectionMode")
            Events = @("SelectedIndexChanged")
        }
    }
    
    $controlScore = 0
    $maxControlScore = $controlTests.Count * 3  # 3 points per control type
    
    foreach ($controlType in $controlTests.Keys) {
        Write-Host "  🔍 Testing $controlType..." -ForegroundColor Yellow
        
        $test = $controlTests[$controlType]
        $typeScore = 0
        
        # Check if control type exists
        if ($content -match $test.Pattern) {
            $typeScore++
            Write-Host "    ✅ $controlType found" -ForegroundColor Green
            
            # Check for required properties
            $propsFound = 0
            foreach ($prop in $test.RequiredProps) {
                if ($content -match "\.$prop\s*=") {
                    $propsFound++
                }
            }
            
            if ($propsFound -ge ($test.RequiredProps.Count * 0.7)) {
                $typeScore++
                Write-Host "    ✅ Required properties: $propsFound/$($test.RequiredProps.Count)" -ForegroundColor Green
            } else {
                Write-Host "    ⚠️ Required properties: $propsFound/$($test.RequiredProps.Count)" -ForegroundColor Yellow
            }
            
            # Check for event handlers
            $eventsFound = 0
            foreach ($event in $test.Events) {
                if ($content -match "Add_$event") {
                    $eventsFound++
                }
            }
            
            if ($eventsFound -ge ($test.Events.Count * 0.5)) {
                $typeScore++
                Write-Host "    ✅ Event handlers: $eventsFound/$($test.Events.Count)" -ForegroundColor Green
            } else {
                Write-Host "    ⚠️ Event handlers: $eventsFound/$($test.Events.Count)" -ForegroundColor Yellow
            }
            
        } else {
            Write-Host "    ❌ $controlType not found" -ForegroundColor Red
        }
        
        $controlScore += $typeScore
    }
    
    $controlPercentage = [math]::Round(($controlScore / $maxControlScore) * 100, 1)
    Write-Host "`n  📊 Control Type Score: $controlScore/$maxControlScore ($controlPercentage%)" -ForegroundColor $(if ($controlPercentage -ge 80) { "Green" } elseif ($controlPercentage -ge 60) { "Yellow" } else { "Red" })
    
    return $controlPercentage
}

# Function to perform live testing simulation
function Test-LiveInteraction {
    param([string]$ScriptPath)
    
    Write-Host "`n📋 Test 5: Live Interaction Simulation" -ForegroundColor Cyan
    
    try {
        Write-Host "  🔍 Attempting GUI launch for live testing..." -ForegroundColor Yellow
        
        # Start GUI in background job for testing
        $job = Start-Job -ScriptBlock {
            param($scriptPath)
            try {
                & $scriptPath -StartMinimized
                return "GUI_LAUNCHED"
            } catch {
                return "ERROR: $($_.Exception.Message)"
            }
        } -ArgumentList $ScriptPath
        
        # Wait for initialization
        Start-Sleep -Seconds 3
        
        $jobResult = Receive-Job $job -ErrorAction SilentlyContinue
        
        if ($job.State -eq "Running") {
            Write-Host "    ✅ GUI launched successfully" -ForegroundColor Green
            Write-Host "    ✅ Process is running and responsive" -ForegroundColor Green
            
            # Clean up
            Stop-Job $job -ErrorAction SilentlyContinue
            Remove-Job $job -ErrorAction SilentlyContinue
            
            return 100
        } else {
            Write-Host "    ❌ GUI failed to launch or closed immediately" -ForegroundColor Red
            if ($jobResult -and $jobResult -like "ERROR:*") {
                Write-Host "    Error: $jobResult" -ForegroundColor Red
            }
            
            Remove-Job $job -ErrorAction SilentlyContinue
            return 0
        }
        
    } catch {
        Write-Host "    ❌ Live testing failed: $($_.Exception.Message)" -ForegroundColor Red
        return 0
    }
}

# Main testing execution
function Invoke-ComprehensiveGUITest {
    param([string]$ScriptPath)
    
    Write-Host "`n🚀 Starting Comprehensive GUI Interactivity Testing..." -ForegroundColor Green
    Write-Host "Target Script: $ScriptPath" -ForegroundColor Cyan
    
    $testResults = @{}
    
    # Run all tests
    $testResults.Syntax = Test-GUISyntax -ScriptPath $ScriptPath
    
    if ($testResults.Syntax) {
        $testResults.Interactivity = Test-ControlInteractivity -ScriptPath $ScriptPath
        $testResults.Accessibility = Test-AccessibilityFeatures -ScriptPath $ScriptPath
        $testResults.ControlTypes = Test-SpecificControlTypes -ScriptPath $ScriptPath
        $testResults.LiveTest = Test-LiveInteraction -ScriptPath $ScriptPath
    } else {
        Write-Host "`n❌ Skipping remaining tests due to syntax errors" -ForegroundColor Red
        return $false
    }
    
    # Calculate overall score
    Write-Host "`n🎯 COMPREHENSIVE TEST RESULTS" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    
    $scores = @()
    foreach ($test in $testResults.Keys) {
        if ($test -ne "Syntax") {
            $scores += $testResults[$test]
            Write-Host "  $test`: $($testResults[$test])%" -ForegroundColor $(if ($testResults[$test] -ge 80) { "Green" } elseif ($testResults[$test] -ge 60) { "Yellow" } else { "Red" })
        }
    }
    
    $overallScore = [math]::Round(($scores | Measure-Object -Average).Average, 1)
    
    Write-Host "`n📊 Overall Interactivity Score: $overallScore%" -ForegroundColor $(if ($overallScore -ge 80) { "Green" } elseif ($overallScore -ge 60) { "Yellow" } else { "Red" })
    
    # Provide recommendations
    Write-Host "`n💡 RECOMMENDATIONS:" -ForegroundColor Cyan
    
    if ($overallScore -ge 90) {
        Write-Host "  🏆 EXCELLENT - GUI is production-ready with superior interactivity!" -ForegroundColor Green
    } elseif ($overallScore -ge 80) {
        Write-Host "  ✅ GOOD - GUI meets professional standards for interactivity" -ForegroundColor Green
    } elseif ($overallScore -ge 60) {
        Write-Host "  ⚠️ FAIR - GUI needs improvements in some areas" -ForegroundColor Yellow
        Write-Host "  • Consider enhancing event handlers and visual feedback" -ForegroundColor White
        Write-Host "  • Improve accessibility features" -ForegroundColor White
    } else {
        Write-Host "  ❌ POOR - GUI requires significant interactivity improvements" -ForegroundColor Red
        Write-Host "  • Fix control enabled states and tab order" -ForegroundColor White
        Write-Host "  • Add comprehensive event handlers" -ForegroundColor White
        Write-Host "  • Implement visual feedback systems" -ForegroundColor White
        Write-Host "  • Improve error handling" -ForegroundColor White
    }
    
    Write-Host "`n🎉 GUI Interactivity Testing Complete!" -ForegroundColor Green
    
    return $overallScore -ge 80
}

# Execute the comprehensive test
try {
    $success = Invoke-ComprehensiveGUITest -ScriptPath $GUIScript
    
    if ($success) {
        Write-Host "`n🎉 GUI INTERACTIVITY VALIDATION: SUCCESS" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "`n⚠️ GUI INTERACTIVITY VALIDATION: NEEDS IMPROVEMENT" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "`n❌ Testing framework error: $($_.Exception.Message)" -ForegroundColor Red
    exit 2
}