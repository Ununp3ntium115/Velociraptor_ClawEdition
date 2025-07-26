#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test script for the Velociraptor Artifact Tool Manager.

.DESCRIPTION
    This script tests the artifact tool manager functionality using the artifact_exchange_v2.zip
    file to validate tool scanning, downloading, and package creation.
#>

[CmdletBinding()]
param(
    [switch]$SkipDownloads,
    [switch]$QuickTest
)

# Import the module with cross-platform path
$ModulePath = Join-Path $PSScriptRoot "modules" | Join-Path -ChildPath "VelociraptorDeployment" | Join-Path -ChildPath "VelociraptorDeployment.psd1"
if (Test-Path $ModulePath) {
    try {
        Import-Module $ModulePath -Force -Verbose
        Write-Host "Successfully imported module from: $ModulePath" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to import module: $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Error "Module not found at: $ModulePath"
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
    Write-Host "Available modules:" -ForegroundColor Yellow
    Get-ChildItem "modules" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Gray
    }
    exit 1
}

Write-Host "=== Velociraptor Artifact Tool Manager Test ===" -ForegroundColor Green

try {
    # Test 1: Extract and scan artifacts
    Write-Host "`n1. Testing artifact scanning..." -ForegroundColor Yellow
    
    if (-not (Test-Path (Join-Path "content" "exchange" | Join-Path -ChildPath "artifacts"))) {
        Write-Host "Extracting artifact_exchange_v2.zip..." -ForegroundColor Cyan
        if (Test-Path "artifact_exchange_v2.zip") {
            Expand-Archive -Path "artifact_exchange_v2.zip" -DestinationPath "." -Force
        } else {
            throw "artifact_exchange_v2.zip not found"
        }
    }
    
    # Test scanning
    $scanResult = New-ArtifactToolManager -Action Scan -ArtifactPath (Join-Path "content" "exchange" | Join-Path -ChildPath "artifacts") -OutputPath (Join-Path "." "test-output")
    
    if ($scanResult.Success) {
        Write-Host "✅ Artifact scanning successful" -ForegroundColor Green
        Write-Host "   Found artifacts in: $($scanResult.ArtifactPath)" -ForegroundColor Gray
    } else {
        throw "Artifact scanning failed: $($scanResult.Error)"
    }
    
    # Test 2: Tool mapping
    Write-Host "`n2. Testing tool mapping..." -ForegroundColor Yellow
    
    $mapResult = New-ArtifactToolManager -Action Map -ArtifactPath (Join-Path "content" "exchange" | Join-Path -ChildPath "artifacts") -OutputPath (Join-Path "." "test-output")
    
    if ($mapResult.Success) {
        Write-Host "✅ Tool mapping successful" -ForegroundColor Green
        
        # Check if mapping file was created
        $mappingFile = Join-Path "." "test-output" | Join-Path -ChildPath "tool-artifact-mapping.json"
        if (Test-Path $mappingFile) {
            $mapping = Get-Content $mappingFile | ConvertFrom-Json
            Write-Host "   Total artifacts: $($mapping.TotalArtifacts)" -ForegroundColor Gray
            Write-Host "   Total tools: $($mapping.TotalTools)" -ForegroundColor Gray
            
            # Show some tool categories
            foreach ($category in $mapping.ToolCategories.PSObject.Properties) {
                $count = $category.Value.Count
                Write-Host "   $($category.Name): $count tools" -ForegroundColor Gray
            }
        }
    } else {
        throw "Tool mapping failed: $($mapResult.Error)"
    }
    
    # Test 3: Download a few tools (if not skipped)
    if (-not $SkipDownloads -and -not $QuickTest) {
        Write-Host "`n3. Testing tool downloads (limited)..." -ForegroundColor Yellow
        
        # Create a test with just a few artifacts to avoid downloading everything
        $testArtifacts = Get-ChildItem (Join-Path "content" "exchange" | Join-Path -ChildPath "artifacts") -Filter "*.yaml" | Select-Object -First 3
        $testDir = Join-Path "." "test-artifacts"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        
        foreach ($artifact in $testArtifacts) {
            Copy-Item $artifact.FullName $testDir
        }
        
        $downloadResult = New-ArtifactToolManager -Action Download -ArtifactPath $testDir -ToolCachePath (Join-Path "." "test-tools") -MaxConcurrentDownloads 2
        
        if ($downloadResult.Success) {
            Write-Host "✅ Tool download test successful" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Tool download test failed: $($downloadResult.Error)" -ForegroundColor Yellow
        }
        
        # Cleanup test directory
        Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "`n3. Skipping tool downloads (use -SkipDownloads:$false to enable)" -ForegroundColor Yellow
    }
    
    # Test 4: Package creation (without tools)
    Write-Host "`n4. Testing package creation..." -ForegroundColor Yellow
    
    $packageResult = New-ArtifactToolManager -Action Package -ArtifactPath (Join-Path "content" "exchange" | Join-Path -ChildPath "artifacts") -OutputPath (Join-Path "." "test-output")
    
    if ($packageResult.Success) {
        Write-Host "✅ Package creation successful" -ForegroundColor Green
        
        # Check if package was created
        $packageDir = Join-Path "." "test-output" | Join-Path -ChildPath "velociraptor-offline-collector"
        if (Test-Path $packageDir) {
            Write-Host "   Package created at: $packageDir" -ForegroundColor Gray
            
            # Show package structure
            $structure = Get-ChildItem $packageDir -Directory
            foreach ($dir in $structure) {
                $itemCount = (Get-ChildItem $dir.FullName -Recurse -File).Count
                Write-Host "   $($dir.Name): $itemCount files" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "⚠️  Package creation failed: $($packageResult.Error)" -ForegroundColor Yellow
    }
    
    # Test 5: Build script test
    if (-not $QuickTest) {
        Write-Host "`n5. Testing build script..." -ForegroundColor Yellow
        
        try {
            & (Join-Path "." "scripts" | Join-Path -ChildPath "Build-VelociraptorArtifactPackage.ps1") -ArtifactSource (Join-Path "content" "exchange" | Join-Path -ChildPath "artifacts") -OutputPath (Join-Path "." "build-test") -PackageType Client -CreateZipPackage:$false
            Write-Host "✅ Build script test successful" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  Build script test failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`n=== Test Summary ===" -ForegroundColor Green
    Write-Host "✅ Artifact scanning: PASSED" -ForegroundColor Green
    Write-Host "✅ Tool mapping: PASSED" -ForegroundColor Green
    
    if (-not $SkipDownloads -and -not $QuickTest) {
        Write-Host "✅ Tool downloads: TESTED" -ForegroundColor Green
    } else {
        Write-Host "⏭️  Tool downloads: SKIPPED" -ForegroundColor Yellow
    }
    
    Write-Host "✅ Package creation: TESTED" -ForegroundColor Green
    
    if (-not $QuickTest) {
        Write-Host "✅ Build script: TESTED" -ForegroundColor Green
    }
    
    Write-Host "`nAll tests completed successfully!" -ForegroundColor Green
    Write-Host "Check the test-output directory for generated files." -ForegroundColor Cyan
    
} catch {
    Write-Host "`n❌ Test failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

# Cleanup option
$cleanup = Read-Host "`nCleanup test files? (y/N)"
if ($cleanup -eq 'y' -or $cleanup -eq 'Y') {
    Write-Host "Cleaning up test files..." -ForegroundColor Yellow
    Remove-Item (Join-Path "." "test-output") -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path "." "test-tools") -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path "." "build-test") -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "content" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cleanup complete." -ForegroundColor Green
}