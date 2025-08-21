#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Simple GUI Analysis Tool for Velociraptor Setup Scripts
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

# Define GUI files to analyze
$GUIFiles = @(
    'VelociraptorGUI-Bulletproof.ps1',
    'VelociraptorGUI-InstallClean.ps1',
    'IncidentResponseGUI-Installation.ps1',
    'gui\VelociraptorGUI.ps1'
)

function Test-GUIFile {
    param([string]$FilePath)
    
    Write-Host "Analyzing: $FilePath" -ForegroundColor Yellow
    
    $analysis = @{
        FileExists = Test-Path $FilePath
        FileSize = 0
        HasWindowsForms = $false
        HasProgressBar = $false
        HasErrorHandling = $false
        HasDownloadLogic = $false
        SyntaxValid = $false
        Grade = "F"
    }
    
    if (-not $analysis.FileExists) {
        Write-Host "  ERROR: File not found" -ForegroundColor Red
        return $analysis
    }
    
    $fileInfo = Get-Item $FilePath
    $analysis.FileSize = [Math]::Round($fileInfo.Length / 1KB, 1)
    Write-Host "  File Size: $($analysis.FileSize) KB" -ForegroundColor Gray
    
    try {
        $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
        
        if ($content) {
            # Test syntax
            try {
                $errors = @()
                $tokens = @()
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$tokens, [ref]$errors)
                $analysis.SyntaxValid = ($errors.Count -eq 0)
                
                if ($analysis.SyntaxValid) {
                    Write-Host "  Syntax: VALID" -ForegroundColor Green
                } else {
                    Write-Host "  Syntax: INVALID ($($errors.Count) errors)" -ForegroundColor Red
                }
            }
            catch {
                Write-Host "  Syntax: PARSE ERROR" -ForegroundColor Red
            }
            
            # Analyze Windows Forms usage
            if ($content -match "System\.Windows\.Forms" -or $content -match "LoadWithPartialName.*Forms") {
                $analysis.HasWindowsForms = $true
                Write-Host "  Windows Forms: YES" -ForegroundColor Green
            } else {
                Write-Host "  Windows Forms: NO" -ForegroundColor Red
            }
            
            # Check for progress indicators
            if ($content -match "ProgressBar|Progress") {
                $analysis.HasProgressBar = $true
                Write-Host "  Progress Indicators: YES" -ForegroundColor Green
            } else {
                Write-Host "  Progress Indicators: NO" -ForegroundColor Yellow
            }
            
            # Check error handling
            $tryCount = ($content -split "try").Count - 1
            $catchCount = ($content -split "catch").Count - 1
            if ($tryCount -ge 3 -and $catchCount -ge 3) {
                $analysis.HasErrorHandling = $true
                Write-Host "  Error Handling: COMPREHENSIVE ($tryCount try blocks)" -ForegroundColor Green
            } elseif ($tryCount -ge 1) {
                Write-Host "  Error Handling: BASIC ($tryCount try blocks)" -ForegroundColor Yellow
            } else {
                Write-Host "  Error Handling: NONE" -ForegroundColor Red
            }
            
            # Check download functionality
            if ($content -match "Invoke-WebRequest|WebClient|Download") {
                $analysis.HasDownloadLogic = $true
                Write-Host "  Download Logic: YES" -ForegroundColor Green
            } else {
                Write-Host "  Download Logic: NO" -ForegroundColor Yellow
            }
            
            # Calculate grade
            $score = 0
            if ($analysis.SyntaxValid) { $score += 30 }
            if ($analysis.HasWindowsForms) { $score += 25 }
            if ($analysis.HasProgressBar) { $score += 15 }
            if ($analysis.HasErrorHandling) { $score += 20 }
            if ($analysis.HasDownloadLogic) { $score += 10 }
            
            if ($score -ge 85) { $analysis.Grade = "A" }
            elseif ($score -ge 75) { $analysis.Grade = "B" }
            elseif ($score -ge 65) { $analysis.Grade = "C" }
            elseif ($score -ge 55) { $analysis.Grade = "D" }
            else { $analysis.Grade = "F" }
            
            $gradeColor = switch ($analysis.Grade) {
                'A' { 'Green' }
                'B' { 'Cyan' }
                'C' { 'Yellow' }
                'D' { 'DarkYellow' }
                'F' { 'Red' }
            }
            
            Write-Host "  Overall Grade: $($analysis.Grade) ($score/100)" -ForegroundColor $gradeColor
        }
    }
    catch {
        Write-Host "  ERROR: Could not analyze file - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    return $analysis
}

# Main Analysis
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "            VELOCIRAPTOR GUI ANALYSIS REPORT" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$Results = @{}
foreach ($gui in $GUIFiles) {
    $Results[$gui] = Test-GUIFile -FilePath $gui
}

# Summary
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                        SUMMARY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan

$validFiles = $Results.Values | Where-Object { $_.FileExists }
$syntaxValid = $validFiles | Where-Object { $_.SyntaxValid }
$hasWinForms = $validFiles | Where-Object { $_.HasWindowsForms }
$passingGrade = $validFiles | Where-Object { $_.Grade -in @('A', 'B', 'C') }

Write-Host "Files Found: $($validFiles.Count)/$($GUIFiles.Count)" -ForegroundColor White
Write-Host "Syntax Valid: $($syntaxValid.Count)/$($validFiles.Count)" -ForegroundColor $(if ($syntaxValid.Count -eq $validFiles.Count) { 'Green' } else { 'Red' })
Write-Host "Windows Forms Setup: $($hasWinForms.Count)/$($validFiles.Count)" -ForegroundColor $(if ($hasWinForms.Count -ge ($validFiles.Count * 0.8)) { 'Green' } else { 'Yellow' })
Write-Host "Passing Grade (C+): $($passingGrade.Count)/$($validFiles.Count)" -ForegroundColor $(if ($passingGrade.Count -ge ($validFiles.Count * 0.75)) { 'Green' } else { 'Red' })

Write-Host ""
Write-Host "RECOMMENDED FOR PRODUCTION:" -ForegroundColor Green
$Results.Keys | Where-Object { $Results[$_].Grade -in @('A', 'B') } | ForEach-Object {
    Write-Host "  ✓ $_ (Grade: $($Results[$_].Grade))" -ForegroundColor Green
}

Write-Host ""
Write-Host "REQUIRES ATTENTION:" -ForegroundColor Yellow  
$Results.Keys | Where-Object { $Results[$_].Grade -in @('D', 'F') } | ForEach-Object {
    Write-Host "  ⚠ $_ (Grade: $($Results[$_].Grade))" -ForegroundColor Red
}

Write-Host ""
Write-Host "Analysis completed!" -ForegroundColor Cyan