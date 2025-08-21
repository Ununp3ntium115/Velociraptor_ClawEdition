# Try to isolate the syntax error by checking smaller sections
$content = Get-Content IncidentResponseGUI-Installation.ps1 -Raw
$lines = $content -split "`r`n|`n"

Write-Host "Testing syntax of the Install-VelociraptorExecutable function only..."

# Extract just the function that has issues (lines 180-262)
$functionLines = $lines[179..262]
$functionContent = $functionLines -join "`r`n"

# Save to temporary file
$functionContent | Out-File "temp-function.ps1" -Encoding UTF8

# Try to parse just this function
try {
    $parseErrors = @()
    $null = [System.Management.Automation.Language.Parser]::ParseInput($functionContent, [ref]$null, [ref]$parseErrors)
    
    if ($parseErrors) {
        Write-Host "Found $($parseErrors.Count) syntax errors in function:"
        foreach ($parseError in $parseErrors) {
            Write-Host "Line $($parseError.Extent.StartLineNumber): $($parseError.Message)"
        }
    } else {
        Write-Host 'Function syntax is OK'
    }
} catch {
    Write-Host "Parse error: $($_.Exception.Message)"
}

# Clean up
Remove-Item "temp-function.ps1" -ErrorAction SilentlyContinue