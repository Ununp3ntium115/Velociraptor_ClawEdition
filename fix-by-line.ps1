# Fix specific lines by number
$lines = Get-Content IncidentResponseGUI-Installation.ps1

Write-Host "Fixing specific lines..."

# Line 108 - Network Intrusion icon
$lines[107] = '        Icon = "🌐"'
Write-Host "Fixed line 108: Network Intrusion icon"

# Line 115 - Insider Threat icon 
$lines[114] = '        Icon = "👤"'
Write-Host "Fixed line 115: Insider Threat icon"

# Write back
$lines | Out-File IncidentResponseGUI-Installation.ps1 -Encoding UTF8
Write-Host "Line fixes completed!"