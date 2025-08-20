#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Builds consolidated incident response packages without code duplication.

.DESCRIPTION
    This script rebuilds all incident response packages using the new shared module
    approach, eliminating code duplication while maintaining full functionality.

.PARAMETER OutputPath
    The path where consolidated packages will be created.

.PARAMETER PackageTypes
    Array of package types to build. Defaults to all types.

.PARAMETER CleanupOldPackages
    Whether to remove existing duplicated packages.

.PARAMETER CreateSymbolicLinks
    Whether to create symbolic links to main scripts (Windows only).

.EXAMPLE
    .\Build-ConsolidatedIncidentPackages.ps1

.EXAMPLE
    .\Build-ConsolidatedIncidentPackages.ps1 -PackageTypes @('APT', 'Ransomware') -CleanupOldPackages
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\incident-packages-consolidated'),

    [Parameter()]
    [ValidateSet('APT', 'Ransomware', 'Malware', 'DataBreach', 'Insider', 'NetworkIntrusion', 'Complete')]
    [string[]]$PackageTypes = @('APT', 'Ransomware', 'Malware', 'DataBreach', 'Insider', 'NetworkIntrusion', 'Complete'),

    [Parameter()]
    [switch]$CleanupOldPackages,

    [Parameter()]
    [switch]$CreateSymbolicLinks = $true
)

# Set up error handling
$ErrorActionPreference = 'Stop'

# Import the VelociraptorDeployment module
$ModulePath = Join-Path $PSScriptRoot '..\modules\VelociraptorDeployment\VelociraptorDeployment.psd1'
if (-not (Test-Path $ModulePath)) {
    throw "VelociraptorDeployment module not found at: $ModulePath"
}

Import-Module $ModulePath -Force
Write-VelociraptorLog "Loaded VelociraptorDeployment module" -Level Info

# Validate admin privileges
if (-not (Test-VelociraptorAdminPrivileges)) {
    Write-Warning "Administrator privileges recommended for symbolic link creation"
}

Write-VelociraptorLog "Building consolidated incident response packages..." -Level Info

try {
    # Create output directory
    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-VelociraptorLog "Created output directory: $OutputPath" -Level Info
    }

    # Build statistics
    $BuildStats = @{
        PackagesBuilt = 0
        TotalArtifacts = 0
        SpaceSaved = 0
        BuildTime = Measure-Command {
            foreach ($packageType in $PackageTypes) {
                Write-VelociraptorLog "Building $packageType package..." -Level Info
                
                try {
                    $result = New-IncidentResponsePackage -IncidentType $packageType -OutputPath $OutputPath
                    
                    if ($result.Success) {
                        Write-VelociraptorLog "✓ $packageType package created successfully" -Level Success
                        Write-VelociraptorLog "  - Path: $($result.PackagePath)" -Level Info
                        Write-VelociraptorLog "  - Artifacts: $($result.ArtifactCount)" -Level Info
                        Write-VelociraptorLog "  - Size: $([Math]::Round($result.Size / 1KB, 2)) KB" -Level Info
                        
                        $BuildStats.PackagesBuilt++
                        $BuildStats.TotalArtifacts += $result.ArtifactCount
                    }
                } catch {
                    Write-VelociraptorLog "✗ Failed to build $packageType package: $($_.Exception.Message)" -Level Error
                }
            }
        }
    }

    # Calculate space savings by comparing with old approach
    $OldPackagesPath = Join-Path $PSScriptRoot '..\incident-packages'
    if (Test-Path $OldPackagesPath) {
        $OldSize = (Get-ChildItem $OldPackagesPath -Recurse -File | Measure-Object -Property Length -Sum).Sum
        $NewSize = (Get-ChildItem $OutputPath -Recurse -File | Measure-Object -Property Length -Sum).Sum
        $BuildStats.SpaceSaved = $OldSize - $NewSize
        
        Write-VelociraptorLog "Space savings analysis:" -Level Info
        Write-VelociraptorLog "  - Old packages size: $([Math]::Round($OldSize / 1MB, 2)) MB" -Level Info
        Write-VelociraptorLog "  - New packages size: $([Math]::Round($NewSize / 1MB, 2)) MB" -Level Info
        Write-VelociraptorLog "  - Space saved: $([Math]::Round($BuildStats.SpaceSaved / 1MB, 2)) MB" -Level Success
        Write-VelociraptorLog "  - Reduction: $([Math]::Round(($BuildStats.SpaceSaved / $OldSize) * 100, 1))%" -Level Success
    }

    # Create package index
    $PackageIndex = @{
        BuildDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        BuildDuration = $BuildStats.BuildTime.ToString()
        PackagesBuilt = $BuildStats.PackagesBuilt
        TotalArtifacts = $BuildStats.TotalArtifacts
        SpaceSaved = $BuildStats.SpaceSaved
        ConsolidatedApproach = $true
        Packages = @()
    }

    # Add package information to index
    foreach ($packageType in $PackageTypes) {
        $packagePath = Join-Path $OutputPath "$packageType-Package"
        if (Test-Path $packagePath) {
            $manifestPath = Join-Path $packagePath 'package-manifest.json'
            if (Test-Path $manifestPath) {
                $manifest = Get-Content $manifestPath | ConvertFrom-Json
                $PackageIndex.Packages += @{
                    Type = $packageType
                    Path = $packagePath
                    ArtifactCount = $manifest.ArtifactCount
                    Version = $manifest.Version
                    Description = $manifest.Description
                }
            }
        }
    }

    # Save package index
    $indexPath = Join-Path $OutputPath 'package-index.json'
    $PackageIndex | ConvertTo-Json -Depth 3 | Set-Content -Path $indexPath -Encoding UTF8

    # Create consolidated README
    $consolidatedReadme = @"
# Consolidated Incident Response Packages

**Build Date**: $($PackageIndex.BuildDate)  
**Build Duration**: $($PackageIndex.BuildDuration)  
**Packages Built**: $($PackageIndex.PackagesBuilt)  
**Total Artifacts**: $($PackageIndex.TotalArtifacts)

## Architecture Improvements

### Zero Code Duplication
- Before: Each package contained complete copies of deployment scripts, modules, and GUIs
- After: Packages reference the main codebase through module imports
- Space Savings: $([Math]::Round($BuildStats.SpaceSaved / 1MB, 2)) MB reduction

### Shared Module Approach
- All packages use the same VelociraptorDeployment module
- Consistent functionality across all incident types
- Easier maintenance and updates
- No synchronization issues between packages

### Incident-Specific Configurations
- Each package contains only unique artifacts and configurations
- Optimized for specific incident response scenarios
- Maintains full functionality with minimal footprint

## Available Packages

$(foreach ($pkg in $PackageIndex.Packages) {
"### $($pkg.Type) Package
- **Description**: $($pkg.Description)
- **Artifacts**: $($pkg.ArtifactCount) specialized artifacts
- **Version**: $($pkg.Version)
- **Path**: ``$($pkg.Path -replace [regex]::Escape($OutputPath), '.')``

"
})

## Usage

Each package can be deployed independently:

```powershell
# Emergency deployment (2-3 minutes)
.\APT-Package\Deploy-APT.ps1 -EmergencyMode

# Standard deployment
.\Ransomware-Package\Deploy-Ransomware.ps1

# Custom configuration
.\Malware-Package\Deploy-Malware.ps1 -ServerName "custom.local" -GuiPort 9000
```

## Benefits of Consolidation

1. **Reduced Maintenance**: Single codebase to maintain
2. **Consistent Updates**: All packages automatically benefit from core improvements
3. **Space Efficiency**: $([Math]::Round(($BuildStats.SpaceSaved / (Get-ChildItem $OldPackagesPath -Recurse -File | Measure-Object -Property Length -Sum).Sum) * 100, 1))% reduction in package size
4. **Version Consistency**: No synchronization issues between packages
5. **Enterprise Ready**: Professional architecture suitable for production use

## Migration from Old Packages

The old incident packages (with duplicated code) are now superseded by this 
consolidated approach. Use the cleanup option to remove old packages:

```powershell
.\Build-ConsolidatedIncidentPackages.ps1 -CleanupOldPackages
```

---

**Built with**: Velociraptor Setup Scripts v$(Get-Module VelociraptorDeployment | Select-Object -ExpandProperty Version)  
**Architecture**: Zero-duplication shared module approach
"@

    Set-Content -Path (Join-Path $OutputPath 'README.md') -Value $consolidatedReadme -Encoding UTF8

    # Clean up old packages if requested
    if ($CleanupOldPackages -and (Test-Path $OldPackagesPath)) {
        Write-VelociraptorLog "Cleaning up old duplicated packages..." -Level Info
        
        # Move old packages to backup location
        $BackupPath = Join-Path $PSScriptRoot '..\incident-packages-backup'
        if (Test-Path $BackupPath) {
            Remove-Item $BackupPath -Recurse -Force
        }
        
        Move-Item -Path $OldPackagesPath -Destination $BackupPath
        Write-VelociraptorLog "Old packages backed up to: $BackupPath" -Level Info
        Write-VelociraptorLog "You can safely delete the backup after verifying new packages work correctly" -Level Warning
    }

    # Display final summary
    Write-VelociraptorLog "`n" -Level Info
    Write-VelociraptorLog "=== BUILD SUMMARY ===" -Level Success
    Write-VelociraptorLog "Packages Built: $($BuildStats.PackagesBuilt)" -Level Info
    Write-VelociraptorLog "Total Artifacts: $($BuildStats.TotalArtifacts)" -Level Info
    Write-VelociraptorLog "Build Time: $($BuildStats.BuildTime.TotalSeconds.ToString('F1')) seconds" -Level Info
    Write-VelociraptorLog "Space Saved: $([Math]::Round($BuildStats.SpaceSaved / 1MB, 2)) MB" -Level Success
    Write-VelociraptorLog "Output Location: $OutputPath" -Level Info
    Write-VelociraptorLog "=== CODE DUPLICATION ELIMINATED ===" -Level Success

} catch {
    Write-VelociraptorLog "Build failed: $($_.Exception.Message)" -Level Error
    throw
}