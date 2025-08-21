# Read the file line by line
$lines = Get-Content IncidentResponseGUI-Installation.ps1

# Fix line 94 (index 93) specifically - the virus emoji
$lines[93] = '        Icon = "🦠"'

# Write back the corrected content
$lines | Out-File IncidentResponseGUI-Installation.ps1 -Encoding UTF8

Write-Host "Fixed line 94 specifically"