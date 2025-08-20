#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Force GUI test with specific positioning and focus
#>

Write-Host "🎯 Force GUI Test - Specific Positioning" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

try {
    # Load assemblies
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
    
    Write-Host "✅ Assemblies loaded" -ForegroundColor Green
    
    # Create form with VERY specific positioning
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "🦖 VELOCIRAPTOR - FORCED POSITION"
    $form.Size = New-Object System.Drawing.Size(600, 400)
    
    # Force specific screen position (top-left corner)
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
    $form.Location = New-Object System.Drawing.Point(100, 100)
    
    # Force window to stay on top and be visible
    $form.TopMost = $true
    $form.ShowInTaskbar = $true
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Normal
    
    # Bright colors to make it obvious
    $form.BackColor = [System.Drawing.Color]::Red
    $form.ForeColor = [System.Drawing.Color]::White
    
    # Large, obvious text
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "🚨 EMERGENCY GUI TEST 🚨`n`nIf you can see this RED window,`nthe GUI is working!`n`nClick the button below!"
    $label.Size = New-Object System.Drawing.Size(550, 200)
    $label.Location = New-Object System.Drawing.Point(25, 50)
    $label.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $label.BackColor = [System.Drawing.Color]::Red
    $label.ForeColor = [System.Drawing.Color]::White
    
    # Large, obvious button
    $button = New-Object System.Windows.Forms.Button
    $button.Text = "✅ I CAN SEE THIS!"
    $button.Size = New-Object System.Drawing.Size(200, 50)
    $button.Location = New-Object System.Drawing.Point(200, 280)
    $button.BackColor = [System.Drawing.Color]::Lime
    $button.ForeColor = [System.Drawing.Color]::Black
    $button.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $button.Add_Click({ 
        [System.Windows.Forms.MessageBox]::Show("SUCCESS! The GUI is working perfectly!", "🎉 Success", "OK", "Information")
        $form.Close() 
    })
    
    $form.Controls.Add($label)
    $form.Controls.Add($button)
    
    Write-Host "🚨 SHOWING BRIGHT RED WINDOW AT POSITION 100,100" -ForegroundColor Red
    Write-Host "👀 Look for a BRIGHT RED window with white text!" -ForegroundColor Yellow
    Write-Host "📍 It should appear at the top-left area of your screen" -ForegroundColor Cyan
    
    # Force the window to show and activate
    $form.Show()
    $form.Activate()
    $form.BringToFront()
    $form.Focus()
    
    # Give it a moment to appear, then convert to modal
    Start-Sleep -Milliseconds 500
    $form.Hide()
    $result = $form.ShowDialog()
    
    Write-Host "✅ Form closed with result: $result" -ForegroundColor Green
}
catch {
    Write-Host "❌ Force GUI test failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
}

Write-Host "🏁 Force GUI test completed" -ForegroundColor Green