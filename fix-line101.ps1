# Read the file line by line
$lines = Get-Content IncidentResponseGUI-Installation.ps1

# Fix line 101 (index 100) specifically
$lines[100] = '        Icon = "📊"'

# Write back the corrected content
$lines | Out-File IncidentResponseGUI-Installation.ps1 -Encoding UTF8

Write-Host "Fixed line 101 specifically"