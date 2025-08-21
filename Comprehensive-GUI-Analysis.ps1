#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Comprehensive GUI Analysis Tool for Velociraptor Setup Scripts

.DESCRIPTION
    Analyzes GUI applications for UX quality, functionality, error handling,
    and Windows Forms implementation without executing the code.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

# Define GUI files to analyze
$GUIFiles = @(
    @{
        Path = ".\VelociraptorGUI-Bulletproof.ps1"
        Name = "VelociraptorGUI-Bulletproof.ps1"
        Description = "Most robust version with comprehensive error handling"
    },
    @{
        Path = ".\VelociraptorGUI-InstallClean.ps1"
        Name = "VelociraptorGUI-InstallClean.ps1"
        Description = "Clean installation GUI with real download functionality"
    },
    @{
        Path = ".\IncidentResponseGUI-Installation.ps1"
        Name = "IncidentResponseGUI-Installation.ps1"
        Description = "Incident response focused GUI"
    },
    @{
        Path = ".\gui\VelociraptorGUI.ps1"
        Name = "gui/VelociraptorGUI.ps1"
        Description = "Main GUI application"
    }
)

function Test-PowerShellSyntax {
    param([string]$FilePath)
    
    try {
        if (-not (Test-Path $FilePath)) {
            return @{
                Valid = $false
                Errors = @("File not found: $FilePath")
            }
        }

        $errors = @()
        $tokens = @()
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$tokens, [ref]$errors)
        
        return @{
            Valid = ($errors.Count -eq 0)
            Errors = $errors | ForEach-Object { $_.Message }
            TokenCount = $tokens.Count
            HasAst = ($null -ne $ast)
        }
    }
    catch {
        return @{
            Valid = $false
            Errors = @("Parser exception: $($_.Exception.Message)")
        }
    }
}

function Analyze-WindowsFormsUsage {
    param([string]$Content)
    
    $analysis = @{
        HasWindowsFormsLoad = $false
        HasDrawingLoad = $false
        HasCompatibleTextRendering = $false
        HasEnableVisualStyles = $false
        FormCreationPattern = "Unknown"
        ColorDefinitionPattern = "Unknown"
        ErrorHandlingLevel = "Basic"
    }
    
    # Check Windows Forms initialization patterns
    if ($Content -match "Add-Type.*System\.Windows\.Forms" -or 
        $Content -match "LoadWithPartialName.*System\.Windows\.Forms") {
        $analysis.HasWindowsFormsLoad = $true
    }
    
    if ($Content -match "Add-Type.*System\.Drawing" -or 
        $Content -match "LoadWithPartialName.*System\.Drawing") {
        $analysis.HasDrawingLoad = $true
    }
    
    if ($Content -match "SetCompatibleTextRenderingDefault") {
        $analysis.HasCompatibleTextRendering = $true
    }
    
    if ($Content -match "EnableVisualStyles") {
        $analysis.HasEnableVisualStyles = $true
    }
    
    # Analyze form creation patterns
    if ($Content -match "New-Object.*System\.Windows\.Forms\.Form") {
        $analysis.FormCreationPattern = "New-Object"
    } elseif ($Content -match "\[System\.Windows\.Forms\.Form\]::new\(\)") {
        $analysis.FormCreationPattern = "Modern (.NET)"
    }
    
    # Check color definition patterns
    if ($Content -match "FromArgb") {
        $analysis.ColorDefinitionPattern = "FromArgb (Safe)"
    } elseif ($Content -match "BackColor\s*=\s*['`"]") {
        $analysis.ColorDefinitionPattern = "String-based (Risky)"
    }
    
    # Evaluate error handling sophistication
    $tryBlocks = ($Content | Select-String -Pattern "try\s*\{" -AllMatches).Matches.Count
    $catchBlocks = ($Content | Select-String -Pattern "catch\s*\{" -AllMatches).Matches.Count
    
    if ($tryBlocks -ge 5 -and $catchBlocks -ge 5) {
        $analysis.ErrorHandlingLevel = "Comprehensive"
    } elseif ($tryBlocks -ge 2 -and $catchBlocks -ge 2) {
        $analysis.ErrorHandlingLevel = "Moderate"
    }
    
    return $analysis
}

function Analyze-UserExperience {
    param([string]$Content)
    
    $uxAnalysis = @{
        HasProgressIndicators = $false
        HasUserFeedback = $false
        HasValidationMessages = $false
        HasHelpText = $false
        AccessibilityFeatures = @()
        UsabilityScore = 0
    }
    
    # Check for progress indicators
    if ($Content -match "ProgressBar|Progress|Percent|\.Value\s*=") {
        $uxAnalysis.HasProgressIndicators = $true
        $uxAnalysis.UsabilityScore += 2
    }
    
    # Check for user feedback mechanisms
    if ($Content -match "MessageBox|Write-Host.*ForegroundColor|StatusBar") {
        $uxAnalysis.HasUserFeedback = $true
        $uxAnalysis.UsabilityScore += 2
    }
    
    # Check for validation
    if ($Content -match "Test-Path|Validate|Verification|Check") {
        $uxAnalysis.HasValidationMessages = $true
        $uxAnalysis.UsabilityScore += 1
    }
    
    # Check for help/guidance
    if ($Content -match "ToolTip|HelpText|Instructions|Guide") {
        $uxAnalysis.HasHelpText = $true
        $uxAnalysis.UsabilityScore += 1
    }
    
    # Check for accessibility features
    if ($Content -match "TabIndex|TabStop") {
        $uxAnalysis.AccessibilityFeatures += "Keyboard Navigation"
        $uxAnalysis.UsabilityScore += 1
    }
    
    if ($Content -match "Font.*Size|Font.*Style") {
        $uxAnalysis.AccessibilityFeatures += "Font Customization"
        $uxAnalysis.UsabilityScore += 1
    }
    
    return $uxAnalysis
}

function Analyze-FunctionalityImplementation {
    param([string]$Content)
    
    $funcAnalysis = @{
        HasDownloadLogic = $false
        HasInstallationLogic = $false
        HasConfigurationManagement = $false
        HasServiceManagement = $false
        HasErrorRecovery = $false
        ComplexityScore = 0
    }
    
    # Check for download functionality
    if ($Content -match "Invoke-WebRequest|WebClient|Download|HTTP|URL") {
        $funcAnalysis.HasDownloadLogic = $true
        $funcAnalysis.ComplexityScore += 2
    }
    
    # Check for installation logic
    if ($Content -match "MSI|Install|Setup|Deploy|Extract") {
        $funcAnalysis.HasInstallationLogic = $true
        $funcAnalysis.ComplexityScore += 3
    }
    
    # Check for configuration management
    if ($Content -match "YAML|Config|Configuration|Settings|Template") {
        $funcAnalysis.HasConfigurationManagement = $true
        $funcAnalysis.ComplexityScore += 2
    }
    
    # Check for service management
    if ($Content -match "Service|Start-Process|Stop-Process|Get-Process") {
        $funcAnalysis.HasServiceManagement = $true
        $funcAnalysis.ComplexityScore += 2
    }
    
    # Check for error recovery
    if ($Content -match "Retry|Recovery|Fallback|Emergency") {
        $funcAnalysis.HasErrorRecovery = $true
        $funcAnalysis.ComplexityScore += 2
    }
    
    return $funcAnalysis
}

# Main Analysis Loop
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "            COMPREHENSIVE GUI ANALYSIS REPORT" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$OverallResults = @{}

foreach ($gui in $GUIFiles) {
    Write-Host "Analyzing: $($gui.Name)" -ForegroundColor Yellow
    Write-Host "Description: $($gui.Description)" -ForegroundColor Gray
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    # Initialize results for this GUI
    $results = @{
        FilePath = $gui.Path
        Name = $gui.Name
        Description = $gui.Description
        FileExists = $false
        FileSize = 0
        SyntaxAnalysis = $null
        WindowsFormsAnalysis = $null
        UXAnalysis = $null
        FunctionalityAnalysis = $null
        OverallGrade = "F"
    }
    
    # Check if file exists
    if (Test-Path $gui.Path) {
        $results.FileExists = $true
        $fileInfo = Get-Item $gui.Path
        $results.FileSize = $fileInfo.Length
        $content = Get-Content $gui.Path -Raw -ErrorAction SilentlyContinue
        
        if ($content) {
            # Perform analyses
            $results.SyntaxAnalysis = Test-PowerShellSyntax -FilePath $gui.Path
            $results.WindowsFormsAnalysis = Analyze-WindowsFormsUsage -Content $content
            $results.UXAnalysis = Analyze-UserExperience -Content $content
            $results.FunctionalityAnalysis = Analyze-FunctionalityImplementation -Content $content
            
            # Calculate overall grade
            $grade = 0
            if ($results.SyntaxAnalysis.Valid) { $grade += 25 }
            if ($results.WindowsFormsAnalysis.HasWindowsFormsLoad -and $results.WindowsFormsAnalysis.HasDrawingLoad) { $grade += 20 }
            $grade += [Math]::Min($results.UXAnalysis.UsabilityScore * 3, 25)
            $grade += [Math]::Min($results.FunctionalityAnalysis.ComplexityScore * 2.5, 30)
            
            if ($grade -ge 90) { $results.OverallGrade = "A" }
            elseif ($grade -ge 80) { $results.OverallGrade = "B" }
            elseif ($grade -ge 70) { $results.OverallGrade = "C" }
            elseif ($grade -ge 60) { $results.OverallGrade = "D" }
            else { $results.OverallGrade = "F" }
            
            # Display results
            Write-Host "   File Size: $([Math]::Round($results.FileSize / 1KB, 1)) KB" -ForegroundColor Gray
            Write-Host "   Syntax Valid: $($results.SyntaxAnalysis.Valid)" -ForegroundColor $(if ($results.SyntaxAnalysis.Valid) { 'Green' } else { 'Red' })
            
            if (-not $results.SyntaxAnalysis.Valid) {
                Write-Host "   Syntax Errors:" -ForegroundColor Red
                $results.SyntaxAnalysis.Errors | ForEach-Object { Write-Host "      - $_" -ForegroundColor Red }
            }
            
            Write-Host "   Windows Forms Setup: $(if ($results.WindowsFormsAnalysis.HasWindowsFormsLoad -and $results.WindowsFormsAnalysis.HasDrawingLoad) { 'Complete' } else { 'Incomplete' })" -ForegroundColor $(if ($results.WindowsFormsAnalysis.HasWindowsFormsLoad -and $results.WindowsFormsAnalysis.HasDrawingLoad) { 'Green' } else { 'Red' })
            Write-Host "   Error Handling Level: $($results.WindowsFormsAnalysis.ErrorHandlingLevel)" -ForegroundColor Gray
            Write-Host "   UX Usability Score: $($results.UXAnalysis.UsabilityScore)/8" -ForegroundColor Gray
            Write-Host "   Functionality Complexity: $($results.FunctionalityAnalysis.ComplexityScore)" -ForegroundColor Gray
            Write-Host "   Overall Grade: $($results.OverallGrade)" -ForegroundColor $(
                switch ($results.OverallGrade) {
                    'A' { 'Green' }
                    'B' { 'Cyan' }
                    'C' { 'Yellow' }
                    'D' { 'DarkYellow' }
                    'F' { 'Red' }
                }
            )
        }
        else {
            Write-Host "   ERROR: Could not read file content" -ForegroundColor Red
        }
    }
    else {
        Write-Host "   ERROR: File not found at path: $($gui.Path)" -ForegroundColor Red
    }
    
    $OverallResults[$gui.Name] = $results
    Write-Host ""
}

# Summary Report
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                        SUMMARY REPORT" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$summary = @{
    TotalGUIs = $GUIFiles.Count
    ValidSyntax = 0
    CompleteWinForms = 0
    HighUX = 0
    HighFunctionality = 0
    OverallPassing = 0
}

foreach ($result in $OverallResults.Values) {
    if ($result.FileExists -and $result.SyntaxAnalysis) {
        if ($result.SyntaxAnalysis.Valid) { $summary.ValidSyntax++ }
        if ($result.WindowsFormsAnalysis.HasWindowsFormsLoad -and $result.WindowsFormsAnalysis.HasDrawingLoad) { $summary.CompleteWinForms++ }
        if ($result.UXAnalysis.UsabilityScore -ge 5) { $summary.HighUX++ }
        if ($result.FunctionalityAnalysis.ComplexityScore -ge 8) { $summary.HighFunctionality++ }
        if ($result.OverallGrade -in @('A', 'B', 'C')) { $summary.OverallPassing++ }
    }
}

Write-Host "Total GUI Applications Analyzed: $($summary.TotalGUIs)" -ForegroundColor White
Write-Host "GUIs with Valid Syntax: $($summary.ValidSyntax)/$($summary.TotalGUIs)" -ForegroundColor $(if ($summary.ValidSyntax -eq $summary.TotalGUIs) { 'Green' } else { 'Yellow' })
Write-Host "GUIs with Complete Windows Forms Setup: $($summary.CompleteWinForms)/$($summary.TotalGUIs)" -ForegroundColor $(if ($summary.CompleteWinForms -ge $summary.TotalGUIs * 0.8) { 'Green' } else { 'Yellow' })
Write-Host "GUIs with High UX Score (5+/8): $($summary.HighUX)/$($summary.TotalGUIs)" -ForegroundColor $(if ($summary.HighUX -ge $summary.TotalGUIs * 0.5) { 'Green' } else { 'Yellow' })
Write-Host "GUIs with High Functionality (8+): $($summary.HighFunctionality)/$($summary.TotalGUIs)" -ForegroundColor $(if ($summary.HighFunctionality -ge $summary.TotalGUIs * 0.5) { 'Green' } else { 'Yellow' })
Write-Host "GUIs with Passing Grade (C+ or better): $($summary.OverallPassing)/$($summary.TotalGUIs)" -ForegroundColor $(if ($summary.OverallPassing -ge $summary.TotalGUIs * 0.75) { 'Green' } else { 'Red' })

Write-Host ""
Write-Host "Recommended GUIs for Production Use:" -ForegroundColor Green
foreach ($result in $OverallResults.Values | Where-Object { $_.OverallGrade -in @('A', 'B') } | Sort-Object OverallGrade) {
    Write-Host "  ✓ $($result.Name) (Grade: $($result.OverallGrade))" -ForegroundColor Green
}

Write-Host ""
Write-Host "GUIs Requiring Attention:" -ForegroundColor Yellow
foreach ($result in $OverallResults.Values | Where-Object { $_.OverallGrade -in @('D', 'F') } | Sort-Object OverallGrade) {
    Write-Host "  ⚠ $($result.Name) (Grade: $($result.OverallGrade))" -ForegroundColor Red
}

Write-Host ""
Write-Host "Analysis completed successfully!" -ForegroundColor Cyan