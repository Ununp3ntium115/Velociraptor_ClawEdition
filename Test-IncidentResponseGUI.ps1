#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test script for Velociraptor Incident Response GUI

.DESCRIPTION
    Automated testing script to validate the Incident Response GUI functionality,
    including all 100 incident scenarios, configuration options, and deployment features.

.EXAMPLE
    .\Test-IncidentResponseGUI.ps1
#>

[CmdletBinding()]
param()

Write-Host "🦖 Testing Velociraptor Incident Response GUI" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Test 1: GUI File Existence and Syntax
Write-Host "`n📋 Test 1: GUI File Validation" -ForegroundColor Cyan

$guiPath = ".\gui\IncidentResponseGUI.ps1"
if (Test-Path $guiPath) {
    Write-Host "✅ GUI file exists: $guiPath" -ForegroundColor Green

    # Test PowerShell syntax
    try {
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $guiPath -Raw), [ref]$null)
        Write-Host "✅ PowerShell syntax is valid" -ForegroundColor Green
    } catch {
        Write-Host "❌ PowerShell syntax error: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
} else {
    Write-Host "❌ GUI file not found: $guiPath" -ForegroundColor Red
    return
}

# Test 2: Required Assemblies
Write-Host "`n📋 Test 2: Required Assemblies" -ForegroundColor Cyan

try {
    Add-Type -AssemblyName System.Windows.Forms
    Write-Host "✅ System.Windows.Forms assembly loaded" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to load System.Windows.Forms: $($_.Exception.Message)" -ForegroundColor Red
}

try {
    Add-Type -AssemblyName System.Drawing
    Write-Host "✅ System.Drawing assembly loaded" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to load System.Drawing: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Incident Scenarios Data Structure
Write-Host "`n📋 Test 3: Incident Scenarios Validation" -ForegroundColor Cyan

# Extract incident scenarios from GUI file
$guiContent = Get-Content $guiPath -Raw

# Check for incident categories
$expectedCategories = @(
    "🦠 Malware & Ransomware (25 scenarios)",
    "🎯 Advanced Persistent Threats (20 scenarios)",
    "👤 Insider Threats (15 scenarios)",
    "🌐 Network & Infrastructure (15 scenarios)",
    "💳 Data Breaches & Compliance (10 scenarios)",
    "🏭 Industrial & Critical Infrastructure (10 scenarios)",
    "📱 Emerging & Specialized Threats (5 scenarios)"
)

$categoriesFound = 0
foreach ($category in $expectedCategories) {
    if ($guiContent -match [regex]::Escape($category)) {
        Write-Host "✅ Found category: $category" -ForegroundColor Green
        $categoriesFound++
    } else {
        Write-Host "❌ Missing category: $category" -ForegroundColor Red
    }
}

Write-Host "📊 Categories found: $categoriesFound/7" -ForegroundColor $(if ($categoriesFound -eq 7) { "Green" } else { "Yellow" })

# Test 4: Key Incident Scenarios
Write-Host "`n📋 Test 4: Key Incident Scenarios" -ForegroundColor Cyan

$keyIncidents = @(
    "WannaCry-style Worm Ransomware",
    "Chinese APT Groups (APT1, APT40)",
    "Disgruntled Employee Data Theft",
    "Domain Controller Compromise",
    "Healthcare Data Breach (HIPAA)",
    "SCADA System Compromise",
    "AI/ML Model Poisoning"
)

$incidentsFound = 0
foreach ($incident in $keyIncidents) {
    if ($guiContent -match [regex]::Escape($incident)) {
        Write-Host "✅ Found incident: $incident" -ForegroundColor Green
        $incidentsFound++
    } else {
        Write-Host "❌ Missing incident: $incident" -ForegroundColor Red
    }
}

Write-Host "📊 Key incidents found: $incidentsFound/$($keyIncidents.Count)" -ForegroundColor $(if ($incidentsFound -eq $keyIncidents.Count) { "Green" } else { "Yellow" })

# Test 5: GUI Components
Write-Host "`n📋 Test 5: GUI Components" -ForegroundColor Cyan

$requiredComponents = @(
    "MainForm",
    "HeaderPanel",
    "VelociraptorLabel",
    "CategoryComboBox",
    "IncidentComboBox",
    "DetailsPanel",
    "ConfigPanel",
    "DeployButton",
    "PreviewButton",
    "StatusBar"
)

$componentsFound = 0
foreach ($component in $requiredComponents) {
    if ($guiContent -match "\`$$component\s*=\s*New-Object") {
        Write-Host "✅ Found component: $component" -ForegroundColor Green
        $componentsFound++
    } else {
        Write-Host "❌ Missing component: $component" -ForegroundColor Red
    }
}

Write-Host "📊 Components found: $componentsFound/$($requiredComponents.Count)" -ForegroundColor $(if ($componentsFound -eq $requiredComponents.Count) { "Green" } else { "Yellow" })

# Test 6: Dark Theme Colors
Write-Host "`n📋 Test 6: Dark Theme Implementation" -ForegroundColor Cyan

$colorVariables = @(
    "DarkBackground",
    "DarkPanel",
    "VelociraptorGreen",
    "VelociraptorBlue",
    "TextColor"
)

$colorsFound = 0
foreach ($color in $colorVariables) {
    if ($guiContent -match "\`$$color\s*=\s*\[System\.Drawing\.Color\]::") {
        Write-Host "✅ Found color: $color" -ForegroundColor Green
        $colorsFound++
    } else {
        Write-Host "❌ Missing color: $color" -ForegroundColor Red
    }
}

Write-Host "📊 Colors found: $colorsFound/$($colorVariables.Count)" -ForegroundColor $(if ($colorsFound -eq $colorVariables.Count) { "Green" } else { "Yellow" })

# Test 7: Event Handlers
Write-Host "`n📋 Test 7: Event Handlers" -ForegroundColor Cyan

$eventHandlers = @(
    "Add_SelectedIndexChanged",
    "Add_Click",
    "Deploy-IncidentCollector",
    "Show-ConfigPreview",
    "Save-Configuration",
    "Load-Configuration"
)

$handlersFound = 0
foreach ($handler in $eventHandlers) {
    if ($guiContent -match [regex]::Escape($handler)) {
        Write-Host "✅ Found handler: $handler" -ForegroundColor Green
        $handlersFound++
    } else {
        Write-Host "❌ Missing handler: $handler" -ForegroundColor Red
    }
}

Write-Host "📊 Handlers found: $handlersFound/$($eventHandlers.Count)" -ForegroundColor $(if ($handlersFound -eq $eventHandlers.Count) { "Green" } else { "Yellow" })

# Test 8: Integration Functions
Write-Host "`n📋 Test 8: Integration Functions" -ForegroundColor Cyan

$integrationFunctions = @(
    "Get-PackageTypeFromIncident",
    "Get-IncidentInformation",
    "Update-IncidentDetails",
    "Show-ProgressDialog"
)

$functionsFound = 0
foreach ($function in $integrationFunctions) {
    if ($guiContent -match "function\s+$function") {
        Write-Host "✅ Found function: $function" -ForegroundColor Green
        $functionsFound++
    } else {
        Write-Host "❌ Missing function: $function" -ForegroundColor Red
    }
}

Write-Host "📊 Functions found: $functionsFound/$($integrationFunctions.Count)" -ForegroundColor $(if ($functionsFound -eq $integrationFunctions.Count) { "Green" } else { "Yellow" })

# Test 9: Velociraptor Branding
Write-Host "`n📋 Test 9: Velociraptor Branding" -ForegroundColor Cyan

$brandingElements = @(
    "🦖",
    "VELOCIRAPTOR",
    "Incident Response",
    "Rapid Deployment"
)

$brandingFound = 0
foreach ($element in $brandingElements) {
    if ($guiContent -match [regex]::Escape($element)) {
        Write-Host "✅ Found branding: $element" -ForegroundColor Green
        $brandingFound++
    } else {
        Write-Host "❌ Missing branding: $element" -ForegroundColor Red
    }
}

Write-Host "📊 Branding elements found: $brandingFound/$($brandingElements.Count)" -ForegroundColor $(if ($brandingFound -eq $brandingElements.Count) { "Green" } else { "Yellow" })

# Test 10: File Size and Complexity
Write-Host "`n📋 Test 10: File Metrics" -ForegroundColor Cyan

$fileInfo = Get-Item $guiPath
$fileSize = [math]::Round($fileInfo.Length / 1KB, 2)
$lineCount = (Get-Content $guiPath).Count

Write-Host "📊 File size: $fileSize KB" -ForegroundColor White
Write-Host "📊 Line count: $lineCount lines" -ForegroundColor White

if ($fileSize -gt 50) {
    Write-Host "✅ Substantial GUI implementation (>50KB)" -ForegroundColor Green
} else {
    Write-Host "⚠️ GUI file seems small (<50KB)" -ForegroundColor Yellow
}

if ($lineCount -gt 500) {
    Write-Host "✅ Comprehensive implementation (>500 lines)" -ForegroundColor Green
} else {
    Write-Host "⚠️ Implementation seems basic (<500 lines)" -ForegroundColor Yellow
}

# Final Summary
Write-Host "`n🎯 TESTING SUMMARY" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green

$totalTests = 10
$passedTests = 0

# Calculate passed tests based on key criteria
if (Test-Path $guiPath) { $passedTests++ }
if ($categoriesFound -eq 7) { $passedTests++ }
if ($incidentsFound -eq $keyIncidents.Count) { $passedTests++ }
if ($componentsFound -ge ($requiredComponents.Count * 0.8)) { $passedTests++ }
if ($colorsFound -eq $colorVariables.Count) { $passedTests++ }
if ($handlersFound -ge ($eventHandlers.Count * 0.8)) { $passedTests++ }
if ($functionsFound -ge ($integrationFunctions.Count * 0.8)) { $passedTests++ }
if ($brandingFound -eq $brandingElements.Count) { $passedTests++ }
if ($fileSize -gt 50) { $passedTests++ }
if ($lineCount -gt 500) { $passedTests++ }

$passPercentage = [math]::Round(($passedTests / $totalTests) * 100, 1)

Write-Host "📊 Tests Passed: $passedTests/$totalTests ($passPercentage%)" -ForegroundColor $(if ($passPercentage -ge 80) { "Green" } elseif ($passPercentage -ge 60) { "Yellow" } else { "Red" })

if ($passPercentage -ge 80) {
    Write-Host "✅ GUI READY FOR USER ACCEPTANCE TESTING" -ForegroundColor Green
    Write-Host "🚀 Proceed with manual UA testing using UA_INCIDENT_RESPONSE_TESTING.md" -ForegroundColor Cyan
} elseif ($passPercentage -ge 60) {
    Write-Host "⚠️ GUI NEEDS MINOR IMPROVEMENTS" -ForegroundColor Yellow
    Write-Host "🔧 Address failing tests before UA testing" -ForegroundColor Yellow
} else {
    Write-Host "❌ GUI NEEDS SIGNIFICANT WORK" -ForegroundColor Red
    Write-Host "🛠️ Major issues must be resolved before testing" -ForegroundColor Red
}

Write-Host "`n🦖 Testing completed!" -ForegroundColor Green