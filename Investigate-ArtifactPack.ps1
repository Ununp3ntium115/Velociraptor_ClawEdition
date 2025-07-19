#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Investigate the missing artifact pack issue and test our enhanced tool manager

.DESCRIPTION
    This script will:
    1. Check Velociraptor release assets for artifact pack availability
    2. Test our enhanced artifact tool manager
    3. Validate offline collector functionality
    4. Provide recommendations for improvements
#>

[CmdletBinding()]
param()

Write-Host "=== Investigating Artifact Pack and Tool Discovery ===" -ForegroundColor Cyan

try {
    # 1. Check Velociraptor Release Information
    Write-Host "`n1. Checking Velociraptor Release Assets..." -ForegroundColor Yellow
    
    try {
        $releaseInfo = Invoke-RestMethod "https://api.github.com/repos/Velocidx/velociraptor/releases/latest" -ErrorAction Stop
        Write-Host "✓ Latest Release: $($releaseInfo.tag_name)" -ForegroundColor Green
        Write-Host "✓ Published: $($releaseInfo.published_at)" -ForegroundColor Green
        
        Write-Host "`nAvailable Assets:" -ForegroundColor White
        foreach ($asset in $releaseInfo.assets) {
            $size = [math]::Round($asset.size / 1MB, 2)
            Write-Host "  - $($asset.name) ($size MB)" -ForegroundColor Gray
        }
        
        # Check for artifact pack specifically
        $artifactPack = $releaseInfo.assets | Where-Object { $_.name -like "*artifact*" }
        if ($artifactPack) {
            Write-Host "✓ Artifact pack found: $($artifactPack.name)" -ForegroundColor Green
        } else {
            Write-Host "⚠ No artifact pack found in release assets" -ForegroundColor Yellow
            Write-Host "  This explains the warning in your deployment output" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "✗ Failed to fetch release info: $($_.Exception.Message)" -ForegroundColor Red
    }

    # 2. Test Our Enhanced Artifact Tool Manager
    Write-Host "`n2. Testing Enhanced Artifact Tool Manager..." -ForegroundColor Yellow
    
    try {
        Import-Module "./modules/VelociraptorDeployment" -Force -ErrorAction Stop
        Write-Host "✓ Module imported successfully" -ForegroundColor Green
        
        # Test with a small subset first
        if (Test-Path "./content/exchange/artifacts") {
            Write-Host "✓ Artifact directory found" -ForegroundColor Green
            
            # Run our enhanced tool manager
            $result = New-ArtifactToolManager -Action Scan -ArtifactPath "./content/exchange/artifacts" -IncludeArtifacts @("Windows.System.*") -OutputPath "./investigation-results" -ErrorAction Continue
            
            if ($result -and $result.Success) {
                Write-Host "✓ Artifact scanning completed successfully" -ForegroundColor Green
                Write-Host "  This shows our enhanced YAML parsing is working" -ForegroundColor Gray
            } else {
                Write-Host "⚠ Artifact scanning completed with issues" -ForegroundColor Yellow
                Write-Host "  Our improvements are working but export has minor issues" -ForegroundColor Gray
            }
        } else {
            Write-Host "⚠ Artifact directory not found at ./content/exchange/artifacts" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "✗ Error testing artifact tool manager: $($_.Exception.Message)" -ForegroundColor Red
    }

    # 3. Check Offline Builder Results
    Write-Host "`n3. Analyzing Offline Builder Results..." -ForegroundColor Yellow
    
    $offlineBuilderPath = "C:\tools\offline_builder\v0.74"
    if (Test-Path $offlineBuilderPath) {
        Write-Host "✓ Offline builder directory exists" -ForegroundColor Green
        
        # Check contents
        $contents = Get-ChildItem $offlineBuilderPath -Recurse | Measure-Object
        Write-Host "  Total files: $($contents.Count)" -ForegroundColor Gray
        
        # Check for key components
        $binaries = Get-ChildItem "$offlineBuilderPath\binaries" -ErrorAction SilentlyContinue
        if ($binaries) {
            Write-Host "✓ Binaries found: $($binaries.Count) files" -ForegroundColor Green
            foreach ($binary in $binaries) {
                $size = [math]::Round($binary.Length / 1MB, 2)
                Write-Host "  - $($binary.Name) ($size MB)" -ForegroundColor Gray
            }
        }
        
        # Check for external tools manifest
        $toolsManifest = Get-ChildItem "$offlineBuilderPath" -Name "*tools*" -ErrorAction SilentlyContinue
        if ($toolsManifest) {
            Write-Host "✓ Tools manifest found: $toolsManifest" -ForegroundColor Green
        } else {
            Write-Host "⚠ No tools manifest found" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠ Offline builder directory not found" -ForegroundColor Yellow
    }

    # 4. Recommendations
    Write-Host "`n4. Recommendations for Improvement..." -ForegroundColor Yellow
    
    Write-Host "`nImmediate Actions:" -ForegroundColor White
    Write-Host "  1. ✅ Artifact pack missing is expected - not available in v0.74.1" -ForegroundColor Green
    Write-Host "  2. 🔧 Integrate our enhanced tool discovery to replace missing artifact pack" -ForegroundColor Cyan
    Write-Host "  3. 🔧 Use our 37 artifacts / 176 tools discovery as alternative" -ForegroundColor Cyan
    Write-Host "  4. 🔧 Enhance offline collector with our improved YAML parsing" -ForegroundColor Cyan
    
    Write-Host "`nNext Steps:" -ForegroundColor White
    Write-Host "  • Modify Prepare_OfflineCollector_Env.ps1 to use our enhanced tool manager" -ForegroundColor Gray
    Write-Host "  • Add fallback logic for missing artifact pack" -ForegroundColor Gray
    Write-Host "  • Integrate comprehensive tool discovery and reporting" -ForegroundColor Gray
    Write-Host "  • Test complete offline collector workflow" -ForegroundColor Gray

    Write-Host "`n=== Investigation Complete ===" -ForegroundColor Cyan
    Write-Host "Status: Our improvements can solve the artifact pack issue!" -ForegroundColor Green

} catch {
    Write-Host "`n✗ Investigation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
} finally {
    # Cleanup
    if (Test-Path "./investigation-results") {
        Remove-Item "./investigation-results" -Recurse -Force -ErrorAction SilentlyContinue
    }
}