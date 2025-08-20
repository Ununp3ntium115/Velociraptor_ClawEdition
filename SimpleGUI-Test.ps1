#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Ultra-simple GUI test to verify Windows Forms is working
#>

Write-Host "🧪 Ultra-Simple GUI Test" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan

try {
    # Load assemblies using reflection method
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
    
    Write-Host "✅ Assemblies loaded" -ForegroundColor Green
    
    # Create a simple form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "🦖 Velociraptor GUI Test - SUCCESS!"
    $form.Size = New-Object System.Drawing.Size(500, 300)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::DarkBlue
    $form.ForeColor = [System.Drawing.Color]::White
    
    # Add a label
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "✅ SUCCESS! The GUI is working!`n`nIf you can see this window, then Windows Forms is functional.`n`nClick OK to close."
    $label.Size = New-Object System.Drawing.Size(450, 150)
    $label.Location = New-Object System.Drawing.Point(25, 50)
    $label.Font = New-Object System.Drawing.Font("Arial", 12)
    $label.TextAlign = "MiddleCenter"
    
    # Add a button
    $button = New-Object System.Windows.Forms.Button
    $button.Text = "OK - Close Window"
    $button.Size = New-Object System.Drawing.Size(150, 40)
    $button.Location = New-Object System.Drawing.Point(175, 200)
    $button.BackColor = [System.Drawing.Color]::Green
    $button.ForeColor = [System.Drawing.Color]::White
    $button.Add_Click({ $form.Close() })
    
    $form.Controls.Add($label)
    $form.Controls.Add($button)
    
    Write-Host "🚀 Showing GUI window..." -ForegroundColor Yellow
    Write-Host "👀 Look for a blue window with white text!" -ForegroundColor Cyan
    
    # Show as modal dialog (this will block until closed)
    $form.TopMost = $true
    Write-Host "📱 Opening modal dialog window..." -ForegroundColor Green
    $result = $form.ShowDialog()
    
    Write-Host "✅ GUI test completed!" -ForegroundColor Green
}
catch {
    Write-Host "❌ GUI test failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
}

Write-Host "🏁 Test finished" -ForegroundColor Cyan