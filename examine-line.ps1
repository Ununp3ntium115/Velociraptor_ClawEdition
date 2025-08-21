$content = Get-Content IncidentResponseGUI-Installation.ps1 -Raw
$lines = $content -split "`r`n|`n"
Write-Host "Line 101 content:"
Write-Host "[$($lines[100])]"
Write-Host "Character analysis:"
for ($i = 0; $i -lt $lines[100].Length; $i++) {
    $char = $lines[100][$i]
    $code = [int][char]$char
    Write-Host "$i`: '$char' (U+$($code.ToString('X4')))"
}