# Read the file content
$content = Get-Content IncidentResponseGUI-Installation.ps1 -Raw

# Replace the corrupted emojis with proper ones
# Line 101: "dY"S" should be 📊
$content = $content -replace 'Icon = "d[ÐðＹŸ]"["""]S["""]', 'Icon = "📊"'

# Write back the corrected content
$content | Out-File IncidentResponseGUI-Installation.ps1 -Encoding UTF8 -NoNewline

Write-Host "Fixed corrupted emoji on line 101"