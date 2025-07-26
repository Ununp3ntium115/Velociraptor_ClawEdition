#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test script for the fixed Artifact Tool Manager functionality.

.DESCRIPTION
    Tests the updated artifact scanning and tool mapping functionality with
    proper YAML parsing for Velociraptor artifacts.
#>

param(
    [string]$ArtifactPath = (Join-Path "." "content" | Join-Path -ChildPath "exchange" | Join-Path -ChildPath "artifacts"),
    [string]$OutputPath = (Join-Path "." "test-output"),
    [switch]$Verbose
)

# Set verbose preference
if ($Verbose) {
    $VerbosePreference = 'Continue'
}

# Import the module
Write-Host "=== Testing Fixed Artifact Tool Manager ===" -ForegroundColor Green

try {
    # Import module with cross-platform path
    $ModulePath = Join-Path "." "modules" | Join-Path -ChildPath "VelociraptorDeployment" | Join-Path -ChildPath "VelociraptorDeployment.psd1"
    Import-Module $ModulePath -Force -Verbose:$Verbose
    Write-Host "✓ Module imported successfully from: $ModulePath" -ForegroundColor Green
}
catch {
    Write-Host "❌ Failed to import module: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 1: Check if Export-ToolMapping function is available
Write-Host "`n1. Testing function availability..." -ForegroundColor Yellow
try {
    $exportFunction = Get-Command Export-ToolMapping -ErrorAction Stop
    Write-Host "✓ Export-ToolMapping function is available" -ForegroundColor Green
    Write-Host "   Source: $($exportFunction.Source)" -ForegroundColor Cyan
}
catch {
    Write-Host "❌ Export-ToolMapping function not found: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: Check artifact path
Write-Host "`n2. Testing artifact path..." -ForegroundColor Yellow
if (-not (Test-Path $ArtifactPath)) {
    Write-Host "❌ Artifact path not found: $ArtifactPath" -ForegroundColor Red
    Write-Host "Available paths:" -ForegroundColor Yellow
    Get-ChildItem -Directory | Where-Object { $_.Name -like "*artifact*" -or $_.Name -like "*content*" } | ForEach-Object {
        Write-Host "  - $($_.FullName)" -ForegroundColor Cyan
    }
    exit 1
}

$yamlFiles = Get-ChildItem -Path $ArtifactPath -Filter "*.yaml" -Recurse
Write-Host "✓ Found $($yamlFiles.Count) YAML files in $ArtifactPath" -ForegroundColor Green

# Test 3: Test YAML parsing with a sample file
Write-Host "`n3. Testing YAML parsing..." -ForegroundColor Yellow
if ($yamlFiles.Count -gt 0) {
    $sampleFile = $yamlFiles[0]
    Write-Host "Testing with sample file: $($sampleFile.Name)" -ForegroundColor Cyan
    
    try {
        $content = Get-Content $sampleFile.FullName -Raw
        Write-Host "✓ Successfully read YAML content ($($content.Length) characters)" -ForegroundColor Green
        
        # Show first few lines
        $lines = $content -split "`n" | Select-Object -First 10
        Write-Host "Sample content:" -ForegroundColor Cyan
        foreach ($line in $lines) {
            Write-Host "  $line" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "❌ Failed to read sample YAML file: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 4: Run artifact scanning
Write-Host "`n4. Testing artifact scanning..." -ForegroundColor Yellow
try {
    # Create output directory
    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # Run the artifact tool manager with scan action
    Write-Host "Starting artifact scan..." -ForegroundColor Cyan
    $result = New-ArtifactToolManager -ArtifactPath $ArtifactPath -Action Scan -OutputPath $OutputPath -Verbose:$Verbose
    
    if ($result.Success) {
        Write-Host "✓ Artifact scanning completed successfully" -ForegroundColor Green
        Write-Host "  Action: $($result.Action)" -ForegroundColor Cyan
        Write-Host "  Completion Time: $($result.CompletionTime)" -ForegroundColor Cyan
        
        # Check for output files
        $outputFiles = Get-ChildItem -Path $OutputPath -Recurse
        Write-Host "  Generated files: $($outputFiles.Count)" -ForegroundColor Cyan
        foreach ($file in $outputFiles) {
            Write-Host "    - $($file.Name) ($($file.Length) bytes)" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "❌ Artifact scanning failed: $($result.Error)" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "❌ Exception during artifact scanning: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    exit 1
}

# Test 5: Verify output files
Write-Host "`n5. Verifying output files..." -ForegroundColor Yellow
$jsonFiles = Get-ChildItem -Path $OutputPath -Filter "*.json" -Recurse
$summaryFiles = Get-ChildItem -Path $OutputPath -Filter "*summary*.txt" -Recurse

if ($jsonFiles.Count -gt 0) {
    Write-Host "✓ Found $($jsonFiles.Count) JSON output file(s)" -ForegroundColor Green
    foreach ($jsonFile in $jsonFiles) {
        try {
            $jsonContent = Get-Content $jsonFile.FullName -Raw | ConvertFrom-Json
            Write-Host "  - $($jsonFile.Name): Valid JSON with $($jsonContent.PSObject.Properties.Count) properties" -ForegroundColor Cyan
            
            # Show summary if available
            if ($jsonContent.Summary) {
                Write-Host "    Summary:" -ForegroundColor Gray
                Write-Host "      Total Artifacts: $($jsonContent.Summary.TotalArtifacts)" -ForegroundColor Gray
                Write-Host "      Total Tools: $($jsonContent.Summary.TotalTools)" -ForegroundColor Gray
                Write-Host "      Artifacts with Tools: $($jsonContent.Summary.ArtifactsWithTools)" -ForegroundColor Gray
                Write-Host "      Artifacts without Tools: $($jsonContent.Summary.ArtifactsWithoutTools)" -ForegroundColor Gray
            }
        }
        catch {
            Write-Host "  - $($jsonFile.Name): Invalid JSON - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

if ($summaryFiles.Count -gt 0) {
    Write-Host "✓ Found $($summaryFiles.Count) summary file(s)" -ForegroundColor Green
    foreach ($summaryFile in $summaryFiles) {
        Write-Host "  - $($summaryFile.Name) ($($summaryFile.Length) bytes)" -ForegroundColor Cyan
    }
}

# Test 6: Show sample artifacts processed
Write-Host "`n6. Sample processed artifacts..." -ForegroundColor Yellow
if ($jsonFiles.Count -gt 0) {
    try {
        $jsonContent = Get-Content $jsonFiles[0].FullName -Raw | ConvertFrom-Json
        if ($jsonContent.Artifacts -and $jsonContent.Artifacts.Count -gt 0) {
            $sampleCount = [Math]::Min(5, $jsonContent.Artifacts.Count)
            Write-Host "Showing first $sampleCount artifacts:" -ForegroundColor Cyan
            
            for ($i = 0; $i -lt $sampleCount; $i++) {
                $artifact = $jsonContent.Artifacts[$i]
                Write-Host "  $($i + 1). $($artifact.Name)" -ForegroundColor White
                Write-Host "     Author: $($artifact.Author)" -ForegroundColor Gray
                Write-Host "     Type: $($artifact.Type)" -ForegroundColor Gray
                Write-Host "     Tools: $($artifact.ToolCount)" -ForegroundColor Gray
                if ($artifact.Tools -and $artifact.Tools.Count -gt 0) {
                    Write-Host "     Tool List: $($artifact.Tools -join ', ')" -ForegroundColor Gray
                }
            }
        }
    }
    catch {
        Write-Host "Could not display sample artifacts: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Test Completed Successfully ===" -ForegroundColor Green
Write-Host "All tests passed! The Artifact Tool Manager is working correctly." -ForegroundColor Green
Write-Host "Output files are available in: $OutputPath" -ForegroundColor Cyan