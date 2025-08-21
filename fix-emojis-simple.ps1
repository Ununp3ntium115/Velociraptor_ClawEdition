# Simple emoji fix script
$lines = Get-Content IncidentResponseGUI-Installation.ps1

Write-Host "Fixing corrupted emojis line by line..."

for ($i = 0; $i -lt $lines.Count; $i++) {
    $originalLine = $lines[$i]
    $line = $lines[$i]
    
    # Fix common corrupted patterns
    $line = $line -replace 'Write-Host "dY[^"]*" Velociraptor', 'Write-Host "🚨 Velociraptor'
    $line = $line -replace 'Write-Host "dY[^"]*" Initializing', 'Write-Host "🔧 Initializing'
    $line = $line -replace 'Icon = "dY[^"]*"', 'Icon = "🎯"'
    $line = $line -replace 'Text = "dY[^"]*" Deploying', 'Text = "🚀 Deploying'
    $line = $line -replace 'Text = "dY[^"]*" Deploy IR', 'Text = "🚀 Deploy IR'
    $line = $line -replace 'Write-Host "dY[^"]*" Creating main', 'Write-Host "🏗️ Creating main'
    $line = $line -replace 'Write-Host "dY[^"]*" Creating header', 'Write-Host "📋 Creating header'
    $line = $line -replace 'Write-Host "dY[^"]*" Creating incident', 'Write-Host "📝 Creating incident'
    $line = $line -replace 'Write-Host "dY[^"]*" Creating deployment', 'Write-Host "📊 Creating deployment'
    $line = $line -replace 'Write-Host "dY[^"]*" Creating buttons', 'Write-Host "🔘 Creating buttons'
    $line = $line -replace 'Write-Host "dY[^"]*" Launching', 'Write-Host "🚀 Launching'
    $line = $line -replace 'Text = "dY[^"]*" Velociraptor', 'Text = "🦖 Velociraptor'
    $line = $line -replace 'Text = "dY[^"]*" INCIDENT', 'Text = "🚨 INCIDENT'
    $line = $line -replace 'Text = "[^"]*" Deployment Complete"', 'Text = "✅ Deployment Complete"'
    $line = $line -replace 'Text = "[^"]*" Deploy Failed', 'Text = "❌ Deploy Failed'
    $line = $line -replace 'Write-Host "[^"]*" SetCompatibleTextRenderingDefault successful', 'Write-Host "✅ SetCompatibleTextRenderingDefault successful'
    $line = $line -replace 'Write-Host "[^"]*"  SetCompatibleTextRenderingDefault already', 'Write-Host "⚠️  SetCompatibleTextRenderingDefault already'
    $line = $line -replace 'Write-Host "[^"]*" Windows Forms initialized', 'Write-Host "✅ Windows Forms initialized'
    $line = $line -replace 'Write-Host "[^"]*" Windows Forms initialization failed', 'Write-Host "❌ Windows Forms initialization failed'
    $line = $line -replace 'Write-Host "[^"]*" Main form created', 'Write-Host "✅ Main form created'
    $line = $line -replace 'Write-Host "[^"]*" Failed to create main form', 'Write-Host "❌ Failed to create main form'
    $line = $line -replace 'Write-Host "[^"]*" Header created', 'Write-Host "✅ Header created'
    $line = $line -replace 'Write-Host "[^"]*" Failed to create header', 'Write-Host "❌ Failed to create header'
    $line = $line -replace 'Write-Host "[^"]*" Incident selection created', 'Write-Host "✅ Incident selection created'
    $line = $line -replace 'Write-Host "[^"]*" Failed to create incident', 'Write-Host "❌ Failed to create incident'
    $line = $line -replace 'Write-Host "[^"]*" Deployment panel created', 'Write-Host "✅ Deployment panel created'
    $line = $line -replace 'Write-Host "[^"]*" Failed to create deployment', 'Write-Host "❌ Failed to create deployment'
    $line = $line -replace 'Write-Host "[^"]*" Buttons created', 'Write-Host "✅ Buttons created'
    $line = $line -replace 'Write-Host "[^"]*" Failed to create buttons', 'Write-Host "❌ Failed to create buttons'
    $line = $line -replace 'Write-Host "[^"]*" Incident Response GUI launched', 'Write-Host "✅ Incident Response GUI launched'
    $line = $line -replace 'Write-Host "[^"]*" Select an incident', 'Write-Host "💡 Select an incident'
    $line = $line -replace 'Write-Host "[^"]*" Incident Response GUI completed', 'Write-Host "✅ Incident Response GUI completed'
    $line = $line -replace 'Write-Host "[^"]*" Failed to show GUI', 'Write-Host "❌ Failed to show GUI'
    
    # Fix Icon fields specifically by incident type based on position
    if ($line -match 'Name = "APT Attack"') {
        $i++; $lines[$i] = $lines[$i] -replace 'Icon = ".*"', 'Icon = "🎯"'
    }
    elseif ($line -match 'Name = "Ransomware"') {
        $i++; $lines[$i] = $lines[$i] -replace 'Icon = ".*"', 'Icon = "🔒"'
    }
    elseif ($line -match 'Name = "Malware Analysis"') {
        $i++; $lines[$i] = $lines[$i] -replace 'Icon = ".*"', 'Icon = "🦠"'
    }
    elseif ($line -match 'Name = "Data Breach"') {
        $i++; $lines[$i] = $lines[$i] -replace 'Icon = ".*"', 'Icon = "📊"'
    }
    elseif ($line -match 'Name = "Network Intrusion"') {
        $i++; $lines[$i] = $lines[$i] -replace 'Icon = ".*"', 'Icon = "🌐"'
    }
    elseif ($line -match 'Name = "Insider Threat"') {
        $i++; $lines[$i] = $lines[$i] -replace 'Icon = ".*"', 'Icon = "👤"'
    }
    
    $lines[$i] = $line
    
    if ($line -ne $originalLine) {
        Write-Host "Fixed line $($i+1): $originalLine -> $line"
    }
}

# Write back the corrected content
$lines | Out-File IncidentResponseGUI-Installation.ps1 -Encoding UTF8

Write-Host "Emoji fixes completed!"