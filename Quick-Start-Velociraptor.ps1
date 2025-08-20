#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick Start Velociraptor - Sets up and launches Velociraptor properly

.DESCRIPTION
    This script ensures Velociraptor is configured and started correctly
#>

Write-Host @"

================================================================
                    QUICK START VELOCIRAPTOR
================================================================
Setting up and launching Velociraptor with proper configuration
================================================================

"@ -ForegroundColor Cyan

$installPath = "C:\VelociraptorFresh"
$exePath = "$installPath\bin\velociraptor.exe"

Write-Host "Checking Velociraptor installation..." -ForegroundColor Yellow

if (-not (Test-Path $exePath)) {
    Write-Host "ERROR: Velociraptor not found at $exePath" -ForegroundColor Red
    exit 1
}

Write-Host "Found Velociraptor executable" -ForegroundColor Green

# Try to use Velociraptor's own deployment method
Write-Host "Using Velociraptor's deployment wizard..." -ForegroundColor Yellow

try {
    Set-Location $installPath
    
    Write-Host "Starting Velociraptor deployment wizard..." -ForegroundColor Cyan
    
    # Use Velociraptor's built-in deployment
    $process = Start-Process -FilePath $exePath -ArgumentList "gui", "--datastore", "datastore" -WorkingDirectory $installPath -PassThru
    
    Write-Host "Velociraptor started with PID: $($process.Id)" -ForegroundColor Green
    Write-Host "Waiting for server to initialize..." -ForegroundColor Yellow
    
    Start-Sleep -Seconds 10
    
    Write-Host "Opening web interface..." -ForegroundColor Cyan
    Start-Process "http://127.0.0.1:8889"
    
    Write-Host ""
    Write-Host "=== VELOCIRAPTOR IS RUNNING ===" -ForegroundColor Green
    Write-Host "Web Interface: http://127.0.0.1:8889" -ForegroundColor Cyan
    Write-Host "Process ID: $($process.Id)" -ForegroundColor White
    Write-Host ""
    Write-Host "If the web interface doesn't load, check the console window for errors." -ForegroundColor Yellow
    
}
catch {
    Write-Host "Error starting Velociraptor: $($_.Exception.Message)" -ForegroundColor Red
    
    Write-Host ""
    Write-Host "Trying alternative method..." -ForegroundColor Yellow
    
    # Try without config file
    try {
        $process2 = Start-Process -FilePath $exePath -ArgumentList "gui" -WorkingDirectory $installPath -PassThru
        Write-Host "Alternative start successful with PID: $($process2.Id)" -ForegroundColor Green
        Start-Sleep -Seconds 10
        Start-Process "http://127.0.0.1:8889"
    }
    catch {
        Write-Host "Alternative method also failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")