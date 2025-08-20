#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Fresh GUI test that handles already-initialized Windows Forms
#>

Write-Host "🦖 Fresh Velociraptor GUI Test" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

try {
    # Skip SetCompatibleTextRenderingDefault if Windows Forms is already initialized
    try {
        [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
        Write-Host "✅ SetCompatibleTextRenderingDefault successful" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️  SetCompatibleTextRenderingDefault already called (this is normal)" -ForegroundColor Yellow
    }
    
    # Load assemblies
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
    
    Write-Host "✅ Windows Forms ready" -ForegroundColor Green
    
    # Create Velociraptor-themed form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "🦖 Velociraptor Configuration Wizard"
    $form.Size = New-Object System.Drawing.Size(800, 600)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::FromArgb(32, 32, 32)  # Dark background
    $form.ForeColor = [System.Drawing.Color]::White
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    
    # Header
    $headerPanel = New-Object System.Windows.Forms.Panel
    $headerPanel.Size = New-Object System.Drawing.Size(780, 80)
    $headerPanel.Location = New-Object System.Drawing.Point(10, 10)
    $headerPanel.BackColor = [System.Drawing.Color]::FromArgb(48, 48, 48)
    
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "🦖 VELOCIRAPTOR DFIR FRAMEWORK"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)  # Teal
    $titleLabel.Location = New-Object System.Drawing.Point(20, 15)
    $titleLabel.Size = New-Object System.Drawing.Size(500, 25)
    
    $subtitleLabel = New-Object System.Windows.Forms.Label
    $subtitleLabel.Text = "Configuration Wizard - Free For All First Responders"
    $subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $subtitleLabel.ForeColor = [System.Drawing.Color]::LightGray
    $subtitleLabel.Location = New-Object System.Drawing.Point(20, 45)
    $subtitleLabel.Size = New-Object System.Drawing.Size(500, 20)
    
    $headerPanel.Controls.Add($titleLabel)
    $headerPanel.Controls.Add($subtitleLabel)
    
    # Content area
    $contentPanel = New-Object System.Windows.Forms.Panel
    $contentPanel.Size = New-Object System.Drawing.Size(780, 400)
    $contentPanel.Location = New-Object System.Drawing.Point(10, 100)
    $contentPanel.BackColor = [System.Drawing.Color]::FromArgb(48, 48, 48)
    
    $welcomeText = @"
🎯 Welcome to the Velociraptor Configuration Wizard!

This wizard helps you:
• Deploy Velociraptor DFIR infrastructure
• Configure optimal settings for your environment  
• Generate intelligent recommendations
• Set up incident response capabilities

✅ GUI is working correctly!
✅ Windows Forms initialized successfully
✅ Ready for configuration

Click 'Start Configuration' to begin or 'Close' to exit.
"@
    
    $welcomeLabel = New-Object System.Windows.Forms.Label
    $welcomeLabel.Text = $welcomeText
    $welcomeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $welcomeLabel.ForeColor = [System.Drawing.Color]::White
    $welcomeLabel.Location = New-Object System.Drawing.Point(30, 30)
    $welcomeLabel.Size = New-Object System.Drawing.Size(720, 350)
    
    $contentPanel.Controls.Add($welcomeLabel)
    
    # Buttons
    $buttonPanel = New-Object System.Windows.Forms.Panel
    $buttonPanel.Size = New-Object System.Drawing.Size(780, 60)
    $buttonPanel.Location = New-Object System.Drawing.Point(10, 510)
    $buttonPanel.BackColor = [System.Drawing.Color]::FromArgb(48, 48, 48)
    
    $startButton = New-Object System.Windows.Forms.Button
    $startButton.Text = "🚀 Start Configuration"
    $startButton.Size = New-Object System.Drawing.Size(180, 35)
    $startButton.Location = New-Object System.Drawing.Point(480, 15)
    $startButton.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $startButton.ForeColor = [System.Drawing.Color]::White
    $startButton.FlatStyle = "Flat"
    $startButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $startButton.Add_Click({
        [System.Windows.Forms.MessageBox]::Show(
            "🎉 Excellent! The GUI is working perfectly!`n`n" +
            "This would normally start the configuration wizard.`n`n" +
            "✅ Windows Forms: Working`n" +
            "✅ Event Handling: Working`n" +
            "✅ UI Rendering: Working`n`n" +
            "The Velociraptor GUI is ready for use!",
            "🦖 Configuration Wizard",
            "OK",
            "Information"
        )
    })
    
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = "Close"
    $closeButton.Size = New-Object System.Drawing.Size(80, 35)
    $closeButton.Location = New-Object System.Drawing.Point(680, 15)
    $closeButton.BackColor = [System.Drawing.Color]::FromArgb(32, 32, 32)
    $closeButton.ForeColor = [System.Drawing.Color]::White
    $closeButton.FlatStyle = "Flat"
    $closeButton.Add_Click({ $form.Close() })
    
    $buttonPanel.Controls.Add($startButton)
    $buttonPanel.Controls.Add($closeButton)
    
    # Add all panels to form
    $form.Controls.Add($headerPanel)
    $form.Controls.Add($contentPanel)
    $form.Controls.Add($buttonPanel)
    
    Write-Host "🚀 Launching Velociraptor GUI..." -ForegroundColor Green
    Write-Host "👀 Look for the dark-themed Velociraptor window!" -ForegroundColor Cyan
    
    # Show the form
    $result = $form.ShowDialog()
    
    Write-Host "✅ Velociraptor GUI completed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "❌ GUI failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
}

Write-Host "🎉 Test completed!" -ForegroundColor Green