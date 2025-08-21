# Final comprehensive fix
$lines = Get-Content IncidentResponseGUI-Installation.ps1

Write-Host "Applying final fixes..."

# Fix line by line with exact replacements
for ($i = 0; $i -lt $lines.Count; $i++) {
    $original = $lines[$i]
    
    # Line 28 - Fix initialization message
    if ($lines[$i] -match 'Write-Host "dY.*" Initializing') {
        $lines[$i] = 'Write-Host "🔧 Initializing Windows Forms..." -ForegroundColor Yellow'
        Write-Host "Fixed line $($i+1): Initialization message"
    }
    
    # Line 80 - APT Attack icon
    if ($lines[$i] -match 'Icon = "dYZ_"') {
        $lines[$i] = '        Icon = "🎯"'
        Write-Host "Fixed line $($i+1): APT Attack icon"
    }
    
    # Line 87 - Ransomware icon (already fixed)
    
    # Line 94 - Malware Analysis icon (already fixed) 
    
    # Line 101 - Data Breach icon (already fixed)
    
    # Line 108 - Network Intrusion icon
    if ($lines[$i] -match 'Icon = "dYO.*"') {
        $lines[$i] = '        Icon = "🌐"'
        Write-Host "Fixed line $($i+1): Network Intrusion icon"
    }
    
    # Line 115 - Insider Threat icon
    if ($lines[$i] -match 'Icon = "dY`.*"') {
        $lines[$i] = '        Icon = "👤"'
        Write-Host "Fixed line $($i+1): Insider Threat icon"
    }
    
    # Fix corrupted Write-Host messages
    if ($lines[$i] -match 'Write-Host ".*" SetCompatibleTextRenderingDefault successful') {
        $lines[$i] = '        Write-Host "✅ SetCompatibleTextRenderingDefault successful" -ForegroundColor Green'
        Write-Host "Fixed line $($i+1): Success message"
    }
    
    if ($lines[$i] -match 'Write-Host ".*" Windows Forms initialized successfully') {
        $lines[$i] = '    Write-Host "✅ Windows Forms initialized successfully" -ForegroundColor Green'
        Write-Host "Fixed line $($i+1): Success message"
    }
    
    # Fix corrupted deployment messages
    if ($lines[$i] -match 'Text = "dYs.*" Deploying') {
        $lines[$i] = '                $Script:DeployButton.Text = "🚀 Deploying..."'
        Write-Host "Fixed line $($i+1): Deploy button text"
    }
    
    # Fix corrupted GUI creation messages
    if ($lines[$i] -match 'Write-Host "dY.*" Creating main form') {
        $lines[$i] = 'Write-Host "🏗️ Creating main form..." -ForegroundColor Yellow'
        Write-Host "Fixed line $($i+1): Main form message"
    }
    
    if ($lines[$i] -match 'Write-Host "dY.*" Creating header') {
        $lines[$i] = 'Write-Host "📋 Creating header..." -ForegroundColor Yellow'
        Write-Host "Fixed line $($i+1): Header message"
    }
    
    if ($lines[$i] -match 'Write-Host "dY.*" Creating incident') {
        $lines[$i] = 'Write-Host "📝 Creating incident selection..." -ForegroundColor Yellow'
        Write-Host "Fixed line $($i+1): Incident selection message"
    }
    
    if ($lines[$i] -match 'Write-Host "dY.*" Creating deployment') {
        $lines[$i] = 'Write-Host "📊 Creating deployment panel..." -ForegroundColor Yellow'
        Write-Host "Fixed line $($i+1): Deployment panel message"
    }
    
    if ($lines[$i] -match 'Write-Host "dY.*" Creating buttons') {
        $lines[$i] = 'Write-Host "🔘 Creating buttons..." -ForegroundColor Yellow'
        Write-Host "Fixed line $($i+1): Buttons message"
    }
    
    if ($lines[$i] -match 'Text = "dY.*" Velociraptor') {
        $lines[$i] = '    $MainForm.Text = "🦖 Velociraptor Incident Response Collector - Installation & Deployment"'
        Write-Host "Fixed line $($i+1): Main form title"
    }
    
    if ($lines[$i] -match 'Text = "dY.*" INCIDENT') {
        $lines[$i] = '    $TitleLabel.Text = "🚨 INCIDENT RESPONSE COLLECTOR - DEPLOYMENT PLATFORM"'
        Write-Host "Fixed line $($i+1): Title label"
    }
    
    if ($lines[$i] -match 'Text = "dY.*" Deploy IR') {
        $lines[$i] = '    $Script:DeployButton.Text = "🚀 Deploy IR Collector"'
        Write-Host "Fixed line $($i+1): Deploy button"
    }
    
    if ($lines[$i] -match 'Write-Host "dY.*" Launching') {
        $lines[$i] = 'Write-Host "🚀 Launching Incident Response GUI..." -ForegroundColor Green'
        Write-Host "Fixed line $($i+1): Launch message"
    }
}

# Write the corrected file
$lines | Out-File IncidentResponseGUI-Installation.ps1 -Encoding UTF8

Write-Host "Final fixes applied. Testing syntax..."