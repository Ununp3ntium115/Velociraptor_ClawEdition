#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Minimal test version of VelociraptorGUI to identify the issue
#>

# Initialize Windows Forms
try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
    [System.Windows.Forms.Application]::EnableVisualStyles()
    Write-Host "✅ Windows Forms initialized successfully" -ForegroundColor Green
}
catch {
    Write-Error "❌ Failed to initialize Windows Forms: $($_.Exception.Message)"
    exit 1
}

# Test basic form creation
try {
    Write-Host "🔧 Creating test form..." -ForegroundColor Yellow
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Velociraptor GUI Test"
    $form.Size = New-Object System.Drawing.Size(600, 400)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::FromArgb(32, 32, 32)
    $form.ForeColor = [System.Drawing.Color]::White
    
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "✅ GUI Test Successful!`n`nIf you see this, the basic GUI works.`nThe issue is in the complex functions."
    $label.Size = New-Object System.Drawing.Size(500, 200)
    $label.Location = New-Object System.Drawing.Point(50, 100)
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 12)
    $label.ForeColor = [System.Drawing.Color]::White
    
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = "Close"
    $closeButton.Size = New-Object System.Drawing.Size(100, 30)
    $closeButton.Location = New-Object System.Drawing.Point(250, 300)
    $closeButton.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $closeButton.ForeColor = [System.Drawing.Color]::White
    $closeButton.FlatStyle = "Flat"
    $closeButton.Add_Click({ $form.Close() })
    
    $form.Controls.Add($label)
    $form.Controls.Add($closeButton)
    
    Write-Host "✅ Test form created successfully" -ForegroundColor Green
    Write-Host "🚀 Launching test GUI..." -ForegroundColor Cyan
    
    [System.Windows.Forms.Application]::Run($form)
    
    Write-Host "✅ Test GUI completed successfully" -ForegroundColor Green
}
catch {
    Write-Host "❌ Test GUI failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
    exit 1
}