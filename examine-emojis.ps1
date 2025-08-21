$content = Get-Content IncidentResponseGUI-Installation.ps1 -Raw
$lines = $content -split "`r`n|`n"

Write-Host "Line 87 (lock emoji):"
Write-Host "[$($lines[86])]"
for ($i = 0; $i -lt $lines[86].Length; $i++) {
    $char = $lines[86][$i]
    $code = [int][char]$char
    if ($code -gt 127 -or $code -lt 32) {
        Write-Host "$i`: '$char' (U+$($code.ToString('X4')))"
    }
}

Write-Host "`nLine 94 (virus emoji):"
Write-Host "[$($lines[93])]"
for ($i = 0; $i -lt $lines[93].Length; $i++) {
    $char = $lines[93][$i]
    $code = [int][char]$char
    if ($code -gt 127 -or $code -lt 32) {
        Write-Host "$i`: '$char' (U+$($code.ToString('X4')))"
    }
}