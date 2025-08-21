# Comprehensive emoji fix script
$content = Get-Content IncidentResponseGUI-Installation.ps1 -Raw

Write-Host "Fixing all corrupted emojis..."

# Fix all corrupted emojis with proper ones
$replacements = @{
    'Write-Host "dYs" Velociraptor' = 'Write-Host "🚨 Velociraptor'
    'Write-Host "dY" Initializing' = 'Write-Host "🔧 Initializing'
    'Icon = "dYZ_"' = 'Icon = "🎯"'
    'Icon = "dY��"' = 'Icon = "🦠"'
    'Icon = "dYO\?"' = 'Icon = "🌐"'
    'Icon = "dY`"' = 'Icon = "👤"'
    'Text = "dYs? Deploying' = 'Text = "🚀 Deploying'
    'Text = "�o\. Deployment Complete"' = 'Text = "✅ Deployment Complete"'
    'Text = "�\?O Deploy Failed' = 'Text = "❌ Deploy Failed'
    'Write-Host "dY\?-�,\? Creating main form' = 'Write-Host "🏗️ Creating main form'
    'Text = "dY�- Velociraptor' = 'Text = "🦖 Velociraptor'
    'Write-Host "dY"< Creating header' = 'Write-Host "📋 Creating header'
    'Text = "dYs" INCIDENT RESPONSE' = 'Text = "🚨 INCIDENT RESPONSE'
    'Write-Host "dY"\? Creating incident' = 'Write-Host "📝 Creating incident'
    'Write-Host "dY"S Creating deployment' = 'Write-Host "📊 Creating deployment'
    'Write-Host "dY"~ Creating buttons' = 'Write-Host "🔘 Creating buttons'
    'Text = "dYs? Deploy IR Collector"' = 'Text = "🚀 Deploy IR Collector"'
    'Write-Host "dYs? Launching' = 'Write-Host "🚀 Launching'
    'Write-Host "�o\. SetCompatibleTextRenderingDefault' = 'Write-Host "✅ SetCompatibleTextRenderingDefault'
    'Write-Host "�s��,\?  SetCompatibleTextRenderingDefault' = 'Write-Host "⚠️  SetCompatibleTextRenderingDefault'
    'Write-Host "�o\. Windows Forms' = 'Write-Host "✅ Windows Forms'
    'Write-Host "�\?O Windows Forms' = 'Write-Host "❌ Windows Forms'
    'Write-Host "�o\. Main form' = 'Write-Host "✅ Main form'
    'Write-Host "�\?O Failed to create main form' = 'Write-Host "❌ Failed to create main form'
    'Write-Host "�o\. Header' = 'Write-Host "✅ Header'
    'Write-Host "�\?O Failed to create header' = 'Write-Host "❌ Failed to create header'
    'Write-Host "�o\. Incident selection' = 'Write-Host "✅ Incident selection'
    'Write-Host "�\?O Failed to create incident' = 'Write-Host "❌ Failed to create incident'
    'Write-Host "�o\. Deployment panel' = 'Write-Host "✅ Deployment panel'
    'Write-Host "�\?O Failed to create deployment' = 'Write-Host "❌ Failed to create deployment'
    'Write-Host "�o\. Buttons' = 'Write-Host "✅ Buttons'
    'Write-Host "�\?O Failed to create buttons' = 'Write-Host "❌ Failed to create buttons'
    'Write-Host "�o\. Incident Response' = 'Write-Host "✅ Incident Response'
    'Write-Host "�\?O Failed to show GUI' = 'Write-Host "❌ Failed to show GUI'
    'Write-Host "dY\?¡ Select an incident' = 'Write-Host "💡 Select an incident'
}

foreach ($pattern in $replacements.Keys) {
    $replacement = $replacements[$pattern]
    $content = $content -replace [regex]::Escape($pattern), $replacement
    Write-Host "Fixed: $pattern -> $replacement"
}

# Additional general fixes for remaining corrupted characters
$content = $content -replace 'Icon = "\?\?"', 'Icon = "📊"'
$content = $content -replace 'dY[^\s"]*"[^\s"]*', '🔒'

# Write back the corrected content
$content | Out-File IncidentResponseGUI-Installation.ps1 -Encoding UTF8 -NoNewline

Write-Host "All emoji corruption fixes applied!"