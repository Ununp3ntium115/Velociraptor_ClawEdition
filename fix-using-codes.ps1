# Fix using unicode codes
$lines = Get-Content IncidentResponseGUI-Installation.ps1

Write-Host "Fixing using unicode codes..."

# Line 108 - Network Intrusion icon (globe)
$globe = [char]0xD83C + [char]0xDF10
$lines[107] = "        Icon = `"$globe`""
Write-Host "Fixed line 108: Network Intrusion icon"

# Line 115 - Insider Threat icon (person) 
$person = [char]0xD83D + [char]0xDC64
$lines[114] = "        Icon = `"$person`""
Write-Host "Fixed line 115: Insider Threat icon"

# Write back
$lines | Out-File IncidentResponseGUI-Installation.ps1 -Encoding UTF8
Write-Host "Unicode fixes completed!"