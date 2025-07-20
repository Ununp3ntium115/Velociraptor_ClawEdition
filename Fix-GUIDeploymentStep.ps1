#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Fix the GUI deployment type step by removing all BackColor assignments.
#>

Write-Host "=== Fixing GUI Deployment Type Step ===" -ForegroundColor Green

try {
    # Read the current GUI file
    $guiContent = Get-Content "gui/VelociraptorGUI.ps1" -Raw
    
    # Create a new deployment type step function without any BackColor assignments
    $newDeploymentFunction = @'
function Show-DeploymentTypeStep {
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Select Deployment Type"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = $script:Colors.Primary
    $titleLabel.Location = New-Object System.Drawing.Point(40, 30)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 35)
    $script:ContentPanel.Controls.Add($titleLabel)
    
    # Server option
    $script:ServerRadio = New-Object System.Windows.Forms.RadioButton
    $script:ServerRadio.Text = "🖥️ Server Deployment"
    $script:ServerRadio.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $script:ServerRadio.ForeColor = $script:Colors.Text
    $script:ServerRadio.Location = New-Object System.Drawing.Point(60, 100)
    $script:ServerRadio.Size = New-Object System.Drawing.Size(300, 25)
    $script:ServerRadio.Checked = ($script:ConfigData.DeploymentType -eq "Server")
    $script:ServerRadio.Add_CheckedChanged({ 
            if ($script:ServerRadio.Checked) { $script:ConfigData.DeploymentType = "Server" }
        })
    $script:ContentPanel.Controls.Add($script:ServerRadio)
    
    $serverDesc = New-Object System.Windows.Forms.Label
    $serverDesc.Text = "Full enterprise server with web GUI, client management, and multi-user capabilities"
    $serverDesc.Location = New-Object System.Drawing.Point(80, 130)
    $serverDesc.Size = New-Object System.Drawing.Size(700, 20)
    $serverDesc.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $serverDesc.ForeColor = $script:Colors.TextSecondary
    $script:ContentPanel.Controls.Add($serverDesc)
    
    # Standalone option
    $script:StandaloneRadio = New-Object System.Windows.Forms.RadioButton
    $script:StandaloneRadio.Text = "💻 Standalone Deployment"
    $script:StandaloneRadio.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $script:StandaloneRadio.ForeColor = $script:Colors.Text
    $script:StandaloneRadio.Location = New-Object System.Drawing.Point(60, 180)
    $script:StandaloneRadio.Size = New-Object System.Drawing.Size(300, 25)
    $script:StandaloneRadio.Checked = ($script:ConfigData.DeploymentType -eq "Standalone")
    $script:StandaloneRadio.Add_CheckedChanged({ 
            if ($script:StandaloneRadio.Checked) { $script:ConfigData.DeploymentType = "Standalone" }
        })
    $script:ContentPanel.Controls.Add($script:StandaloneRadio)
    
    $standaloneDesc = New-Object System.Windows.Forms.Label
    $standaloneDesc.Text = "Single-user forensic workstation with local GUI access and simplified management"
    $standaloneDesc.Location = New-Object System.Drawing.Point(80, 210)
    $standaloneDesc.Size = New-Object System.Drawing.Size(700, 20)
    $standaloneDesc.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $standaloneDesc.ForeColor = $script:Colors.TextSecondary
    $script:ContentPanel.Controls.Add($standaloneDesc)
    
    # Client option
    $script:ClientRadio = New-Object System.Windows.Forms.RadioButton
    $script:ClientRadio.Text = "📱 Client Configuration"
    $script:ClientRadio.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $script:ClientRadio.ForeColor = $script:Colors.Text
    $script:ClientRadio.Location = New-Object System.Drawing.Point(60, 260)
    $script:ClientRadio.Size = New-Object System.Drawing.Size(300, 25)
    $script:ClientRadio.Checked = ($script:ConfigData.DeploymentType -eq "Client")
    $script:ClientRadio.Add_CheckedChanged({ 
            if ($script:ClientRadio.Checked) { $script:ConfigData.DeploymentType = "Client" }
        })
    $script:ContentPanel.Controls.Add($script:ClientRadio)
    
    $clientDesc = New-Object System.Windows.Forms.Label
    $clientDesc.Text = "Client agent configuration for connecting to a centralized Velociraptor server"
    $clientDesc.Location = New-Object System.Drawing.Point(80, 290)
    $clientDesc.Size = New-Object System.Drawing.Size(700, 20)
    $clientDesc.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $clientDesc.ForeColor = $script:Colors.TextSecondary
    $script:ContentPanel.Controls.Add($clientDesc)
}
'@
    
    # Find the current function and replace it
    $pattern = 'function Show-DeploymentTypeStep \{[\s\S]*?\n\}(?=\s*\n# Authentication Step)'
    $newContent = $guiContent -replace $pattern, $newDeploymentFunction
    
    # Write the fixed content back
    Set-Content "gui/VelociraptorGUI.ps1" -Value $newContent -Encoding UTF8
    
    Write-Host "✅ Successfully fixed the deployment type step function" -ForegroundColor Green
    Write-Host "• Removed all BackColor assignments that were causing null conversion errors" -ForegroundColor Cyan
    Write-Host "• Controls will now inherit background color from their parent panel" -ForegroundColor Cyan
    Write-Host "• This should eliminate the BackColor conversion exception" -ForegroundColor Cyan
    
    Write-Host "`n🚀 Ready to test - the GUI should now work without BackColor errors!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Error fixing GUI: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Fix Complete ===" -ForegroundColor Green