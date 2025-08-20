#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Create Velociraptor Setup Scripts v5.0.3-beta Release ZIP

.DESCRIPTION
    Creates a complete release package with all essential files for deployment
#>

Write-Host "Creating Velociraptor Setup Scripts v5.0.3-beta Release Package..." -ForegroundColor Cyan

# Define release files
$releaseFiles = @(
    # Core installation scripts
    "Deploy_Velociraptor_Standalone.ps1",
    "Deploy_Velociraptor_Server.ps1", 
    "VelociraptorGUI-InstallClean.ps1",
    "IncidentResponseGUI-Installation.ps1",
    
    # Documentation
    "RELEASE-NOTES-v5.0.3-beta.md",
    "QUICK-START-v5.0.3.md",
    "CLAUDE.md",
    "VERSION",
    "README.md",
    
    # PowerShell Module (entire directory)
    "modules/",
    
    # Configuration files
    "package.json",
    "VelociraptorSetupScripts.psd1"
)

$releaseDir = "release-assets\velociraptor-setup-scripts-v5.0.3-beta"
$zipFile = "release-assets\velociraptor-setup-scripts-v5.0.3-beta.zip"

# Create release directory
if (Test-Path $releaseDir) {
    Remove-Item $releaseDir -Recurse -Force
}
New-Item -ItemType Directory $releaseDir -Force | Out-Null

# Copy files to release directory
foreach ($file in $releaseFiles) {
    if (Test-Path $file) {
        if ($file.EndsWith('/')) {
            # Directory
            $destDir = Join-Path $releaseDir $file
            Copy-Item $file $destDir -Recurse -Force
            Write-Host "Copied directory: $file" -ForegroundColor Green
        } else {
            # File
            $destFile = Join-Path $releaseDir $file
            $destFileDir = Split-Path $destFile -Parent
            if (-not (Test-Path $destFileDir)) {
                New-Item -ItemType Directory $destFileDir -Force | Out-Null
            }
            Copy-Item $file $destFile -Force
            Write-Host "Copied file: $file" -ForegroundColor Green
        }
    } else {
        Write-Host "Warning: File not found: $file" -ForegroundColor Yellow
    }
}

# Create ZIP file
if (Test-Path $zipFile) {
    Remove-Item $zipFile -Force
}

Compress-Archive -Path $releaseDir -DestinationPath $zipFile -CompressionLevel Optimal

$zipSize = [math]::Round((Get-Item $zipFile).Length / 1MB, 2)
Write-Host "" -ForegroundColor Green
Write-Host "Release package created successfully!" -ForegroundColor Green
Write-Host "Location: $zipFile" -ForegroundColor Cyan
Write-Host "Size: ${zipSize} MB" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Green

# List contents for verification
Write-Host "Package contents:" -ForegroundColor Yellow
Get-ChildItem $releaseDir -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Substring($releaseDir.Length + 1)
    if ($_.PSIsContainer) {
        Write-Host "  DIR  $relativePath/" -ForegroundColor Blue
    } else {
        $size = [math]::Round($_.Length / 1KB, 1)
        Write-Host "  FILE $relativePath (${size} KB)" -ForegroundColor White
    }
}

Write-Host "" -ForegroundColor Green
Write-Host "Ready for GitHub release upload!" -ForegroundColor Green