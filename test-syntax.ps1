# Test syntax parsing
try {
    . "D:\GitRepos\Velociraptor_scripts\Velociraptor_Setup_Scripts\IncidentResponseGUI-Installation.ps1"
    Write-Host "Syntax is valid" -ForegroundColor Green
}
catch {
    Write-Host "Syntax Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "At line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Yellow
    Write-Host "Character: $($_.InvocationInfo.OffsetInLine)" -ForegroundColor Yellow
}