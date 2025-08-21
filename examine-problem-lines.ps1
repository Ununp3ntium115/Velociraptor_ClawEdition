$content = Get-Content IncidentResponseGUI-Installation.ps1 -Raw
$lines = $content -split "`r`n|`n"

Write-Host "Examining line 248 (closing brace):"
Write-Host "[$($lines[247])]"
for ($i = 0; $i -lt $lines[247].Length; $i++) {
    $char = $lines[247][$i]
    $code = [int][char]$char
    Write-Host "$i`: '$char' (U+$($code.ToString('X4')))"
}

Write-Host "`nExamining line 262 (closing brace):"
Write-Host "[$($lines[261])]"
for ($i = 0; $i -lt $lines[261].Length; $i++) {
    $char = $lines[261][$i]
    $code = [int][char]$char
    Write-Host "$i`: '$char' (U+$($code.ToString('X4')))"
}

Write-Host "`nChecking context around these lines..."
Write-Host "Lines 246-250:"
for ($i = 245; $i -le 249; $i++) {
    Write-Host "Line $($i+1): [$($lines[$i])]"
}

Write-Host "`nLines 260-264:"
for ($i = 259; $i -le 263; $i++) {
    Write-Host "Line $($i+1): [$($lines[$i])]"
}