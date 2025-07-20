#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Safe version of Velociraptor GUI with improved Windows Forms initialization
#>

[CmdletBinding()]
param(
    [switch]$StartMinimized
)

# Safe Windows Forms initialization function
function Initialize-SafeWindowsForms {
    try {
        Write-Host "Initializing Windows Forms..." -ForegroundColor Yellow
        
        # Load assemblies first
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        
        # Check if we can safely call SetCompatibleTextRenderingDefault
        $canSetRendering = $true
        try {
            # Test if any forms exist
            $existingForms = [System.Windows.Forms.Application]::OpenForms
            if ($existingForms.Count -gt 0) {
                Write-Warning "Existing Windows Forms detected. Skipping SetCompatibleTextRenderingDefault."
                $canSetRendering = $false
            }
        }
        catch {
            # If we can't check, assume it's safe
        }
        
        # Only call if safe to do so
        if ($canSetRendering) {
            [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
            Write-Host "✓ SetCompatibleTextRenderingDefault applied" -ForegroundColor Green
        }
        
        # EnableVisualStyles is usually safe to call multiple times
        [System.Windows.Forms.Application]::EnableVisualStyles()
        Write-Host "✓ Visual styles enabled" -ForegroundColor Green
        
        return $true
    }
    catch {
        Write-Error "Windows Forms initialization failed: $($_.Exception.Message)"
        return $false
    }
}

# Initialize Windows Forms
if (-not (Initialize-SafeWindowsForms)) {
    Write-Error "Cannot initialize Windows Forms. Exiting."
    exit 1
}

# Professional banner
$VelociraptorBanner = @"
╔══════════════════════════════════════════════════════════════╗
║                🦖 VELOCIRAPTOR DFIR FRAMEWORK 🦖              ║
║                   Configuration Wizard v5.0.1                ║
║                  Free For All First Responders               ║
╚══════════════════════════════════════════════════════════════╝
"@

# Simple test form
try {
    Write-Host $VelociraptorBanner -ForegroundColor Cyan
    Write-Host "Creating test form..." -ForegroundColor White
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "🦖 Velociraptor Configuration Wizard"
    $form.Size = New-Object System.Drawing.Size(800, 600)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::FromArgb(32, 32, 32)
    $form.ForeColor = [System.Drawing.Color]::White
    
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Velociraptor GUI Test - If you see this, Windows Forms is working!"
    $label.Location = New-Object System.Drawing.Point(50, 50)
    $label.Size = New-Object System.Drawing.Size(700, 100)
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $label.ForeColor = [System.Drawing.Color]::White
    $label.BackColor = [System.Drawing.Color]::Transparent
    
    $form.Controls.Add($label)
    
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = "Close"
    $closeButton.Location = New-Object System.Drawing.Point(350, 200)
    $closeButton.Size = New-Object System.Drawing.Size(100, 30)
    $closeButton.Add_Click({ $form.Close() })
    
    $form.Controls.Add($closeButton)
    
    Write-Host "✓ Form created successfully. Showing GUI..." -ForegroundColor Green
    [System.Windows.Forms.Application]::Run($form)
    
} catch {
    Write-Error "Error creating form: $($_.Exception.Message)"
    Write-Host "Stack trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
}