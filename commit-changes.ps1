#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Automated script to commit Phase 3+ changes to main branch.

.DESCRIPTION
    This script automates the Git commit process for the Phase 3+ enterprise features
    implementation. It stages all changes, commits with a detailed message, and pushes
    to the main branch.

.PARAMETER DryRun
    Show what would be committed without actually committing.

.PARAMETER CreateTag
    Create a version tag after successful commit.

.EXAMPLE
    .\commit-changes.ps1

.EXAMPLE
    .\commit-changes.ps1 -DryRun
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$CreateTag
)

Write-Host "=== VELOCIRAPTOR SETUP SCRIPTS - PHASE 3+ COMMIT ===" -ForegroundColor Cyan
Write-Host "Preparing to commit enterprise features to main branch" -ForegroundColor Green
Write-Host ""

# Check if we're in a Git repository
if (-not (Test-Path ".git")) {
    Write-Host "ERROR: Not in a Git repository. Please run this script from the repository root." -ForegroundColor Red
    exit 1
}

# Check Git status
Write-Host "Checking Git status..." -ForegroundColor Yellow
git status

Write-Host ""
Write-Host "Files to be committed:" -ForegroundColor Yellow

# List new and modified files
$newFiles = @(
    "gui/VelociraptorGUI.ps1"
    "scripts/cross-platform/Deploy-VelociraptorLinux.ps1"
    "modules/VelociraptorDeployment/functions/Manage-VelociraptorCollections.ps1"
    "ROADMAP.md"
    "PHASE4_SUMMARY.md"
    "COMMIT_MESSAGE.md"
    "commit-changes.ps1"
)

$modifiedFiles = @(
    "README.md"
    "modules/VelociraptorDeployment/VelociraptorDeployment.psd1"
)

Write-Host "New Files:" -ForegroundColor Green
foreach ($file in $newFiles) {
    if (Test-Path $file) {
        Write-Host "  + $file" -ForegroundColor Green
    }
}

Write-Host "Modified Files:" -ForegroundColor Yellow
foreach ($file in $modifiedFiles) {
    if (Test-Path $file) {
        Write-Host "  M $file" -ForegroundColor Yellow
    }
}

Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "Would execute:" -ForegroundColor Magenta
    Write-Host "  git add ." -ForegroundColor Gray
    Write-Host "  git commit -F COMMIT_MESSAGE.md" -ForegroundColor Gray
    Write-Host "  git push origin main" -ForegroundColor Gray
    if ($CreateTag) {
        Write-Host "  git tag -a v3.0.0 -m 'Version 3.0.0 - Phase 3+ Enterprise Features'" -ForegroundColor Gray
        Write-Host "  git push origin v3.0.0" -ForegroundColor Gray
    }
    exit 0
}

# Confirm with user
Write-Host "Ready to commit Phase 3+ enterprise features to main branch." -ForegroundColor Yellow
$confirm = Read-Host "Continue? (y/N)"

if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "Commit cancelled by user." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Committing changes..." -ForegroundColor Green

try {
    # Stage all changes
    Write-Host "Staging files..." -ForegroundColor Yellow
    git add .
    
    # Check if there are changes to commit
    $status = git status --porcelain
    if (-not $status) {
        Write-Host "No changes to commit." -ForegroundColor Yellow
        exit 0
    }
    
    # Commit with detailed message
    Write-Host "Creating commit..." -ForegroundColor Yellow
    git commit -F COMMIT_MESSAGE.md
    
    if ($LASTEXITCODE -ne 0) {
        throw "Git commit failed"
    }
    
    # Push to main branch
    Write-Host "Pushing to main branch..." -ForegroundColor Yellow
    git push origin main
    
    if ($LASTEXITCODE -ne 0) {
        throw "Git push failed"
    }
    
    Write-Host "Successfully committed and pushed changes!" -ForegroundColor Green
    
    # Create version tag if requested
    if ($CreateTag) {
        Write-Host "Creating version tag..." -ForegroundColor Yellow
        git tag -a v3.0.0 -m "Version 3.0.0 - Phase 3+ Enterprise Features"
        git push origin v3.0.0
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Version tag v3.0.0 created and pushed!" -ForegroundColor Green
        }
        else {
            Write-Host "Warning: Failed to create or push version tag" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "=== COMMIT SUCCESSFUL ===" -ForegroundColor Green
    Write-Host "Phase 3+ enterprise features have been committed to main branch" -ForegroundColor Green
    Write-Host ""
    Write-Host "Summary of changes:" -ForegroundColor Cyan
    Write-Host "- GUI Management Interface" -ForegroundColor White
    Write-Host "- Cross-Platform Linux Deployment (7 distributions)" -ForegroundColor White
    Write-Host "- Collection Management System" -ForegroundColor White
    Write-Host "- Enhanced Documentation and Roadmap" -ForegroundColor White
    Write-Host "- 17+ PowerShell functions across 2 modules" -ForegroundColor White
    Write-Host ""
    Write-Host "Ready for Phase 4 development!" -ForegroundColor Green
    
    # Show recent commits
    Write-Host ""
    Write-Host "Recent commits:" -ForegroundColor Cyan
    git log --oneline -5
    
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Commit process failed. Please check the error and try again." -ForegroundColor Red
    exit 1
}