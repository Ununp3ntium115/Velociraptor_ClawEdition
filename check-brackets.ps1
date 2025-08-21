# Check for bracket mismatches around problematic lines
$content = Get-Content IncidentResponseGUI-Installation.ps1 -Raw
$lines = $content -split "`r`n|`n"

Write-Host "Checking bracket balance around line 248:"
$openBraces = 0
$openParens = 0
for ($i = 180; $i -lt 260; $i++) {
    $line = $lines[$i]
    $openBraces += ($line.ToCharArray() | Where-Object { $_ -eq '{' }).Count
    $openBraces -= ($line.ToCharArray() | Where-Object { $_ -eq '}' }).Count
    $openParens += ($line.ToCharArray() | Where-Object { $_ -eq '(' }).Count
    $openParens -= ($line.ToCharArray() | Where-Object { $_ -eq ')' }).Count
    
    Write-Host "Line $($i+1): Braces: $openBraces, Parens: $openParens - [$line]"
}