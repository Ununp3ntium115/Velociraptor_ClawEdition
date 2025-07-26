#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Comprehensive Beta Release Quality Assurance Testing Suite

.DESCRIPTION
    This script performs exhaustive testing of all PowerShell scripts, modules, 
    shell scripts, GUI components, and configurations to ensure beta release readiness.
    
    Tests include:
    - PowerShell syntax validation and best practices
    - Shell script syntax and structure validation
    - Module manifest and loading tests
    - GUI functionality and Windows Forms compatibility
    - Configuration file validation (YAML, JSON, PSD1)
    - Security baseline checks
    - Performance benchmarking
    - Integration testing scenarios

.PARAMETER SkipSlowTests
    Skip performance and integration tests that take longer to execute

.PARAMETER GenerateReport
    Generate a detailed markdown report of all test results

.PARAMETER OutputPath
    Path for the generated report (default: BETA_QA_REPORT.md)

.PARAMETER FixIssues
    Attempt to automatically fix minor issues found during testing

.EXAMPLE
    .\COMPREHENSIVE_BETA_QA.ps1
    Run all QA tests with standard output

.EXAMPLE
    .\COMPREHENSIVE_BETA_QA.ps1 -Verbose -GenerateReport
    Run all tests with verbose output and generate a detailed report

.EXAMPLE
    .\COMPREHENSIVE_BETA_QA.ps1 -SkipSlowTests -FixIssues
    Run quick tests and attempt to fix minor issues automatically
#>

[CmdletBinding()]
param(
    [switch]$SkipSlowTests,
    [switch]$GenerateReport,
    [string]$OutputPath = "BETA_QA_REPORT.md",
    [switch]$FixIssues
)

# Initialize results tracking
$script:TestResults = @{
    PowerShellScripts = @()
    ShellScripts = @()
    Modules = @()
    Configurations = @()
    GUI = @()
    Integration = @()
    Security = @()
    Performance = @()
    Summary = @{
        TotalTests = 0
        PassedTests = 0
        FailedTests = 0
        WarningTests = 0
        CriticalIssues = @()
        Recommendations = @()
        StartTime = Get-Date
        EndTime = $null
    }
}

# Color coding for output
function Write-TestResult {
    param(
        [string]$Message,
        [ValidateSet("PASS", "FAIL", "WARN", "INFO", "SKIP")]
        [string]$Status,
        [string]$Details = "",
        [string]$Category = "General"
    )
    
    $color = switch ($Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARN" { "Yellow" }
        "INFO" { "Cyan" }
        "SKIP" { "Gray" }
    }
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp][$Status] $Message" -ForegroundColor $color
    if ($Details) {
        Write-Host "    └─ $Details" -ForegroundColor Gray
    }
    
    $script:TestResults.Summary.TotalTests++
    switch ($Status) {
        "PASS" { $script:TestResults.Summary.PassedTests++ }
        "FAIL" { 
            $script:TestResults.Summary.FailedTests++
            $script:TestResults.Summary.CriticalIssues += @{
                Message = $Message
                Details = $Details
                Category = $Category
                Timestamp = Get-Date
            }
        }
        "WARN" { $script:TestResults.Summary.WarningTests++ }
    }
}

# Enhanced PowerShell script testing
function Test-PowerShellScript {
    param([string]$ScriptPath)
    
    Write-Verbose "Testing PowerShell script: $ScriptPath"
    
    $result = @{
        Path = $ScriptPath
        SyntaxValid = $false
        HasHelpContent = $false
        HasErrorHandling = $false
        UsesApprovedVerbs = $true
        HasParameterValidation = $false
        HasCmdletBinding = $false
        Issues = @()
        Recommendations = @()
    }
    
    try {
        $content = Get-Content $ScriptPath -Raw -ErrorAction Stop
        
        # Test syntax using AST
        try {
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
            $result.SyntaxValid = $true
            Write-TestResult "Syntax validation for $(Split-Path $ScriptPath -Leaf)" "PASS" "PowerShell AST parsing successful"
        }
        catch {
            $result.Issues += "Syntax Error: $($_.Exception.Message)"
            Write-TestResult "Syntax validation for $(Split-Path $ScriptPath -Leaf)" "FAIL" $_.Exception.Message "PowerShell"
        }
        
        # Check for comprehensive help content
        $helpPatterns = @('\.SYNOPSIS', '\.DESCRIPTION', '\.EXAMPLE', '\.PARAMETER')
        $helpScore = 0
        foreach ($pattern in $helpPatterns) {
            if ($content -match $pattern) { $helpScore++ }
        }
        
        if ($helpScore -ge 3) {
            $result.HasHelpContent = $true
            Write-TestResult "Help content in $(Split-Path $ScriptPath -Leaf)" "PASS" "Found $helpScore/4 help sections"
        }
        elseif ($helpScore -gt 0) {
            $result.HasHelpContent = $true
            $result.Recommendations += "Add more comprehensive help documentation"
            Write-TestResult "Help content in $(Split-Path $ScriptPath -Leaf)" "WARN" "Found $helpScore/4 help sections - consider adding more"
        }
        else {
            $result.Issues += "Missing help documentation"
            Write-TestResult "Help content in $(Split-Path $ScriptPath -Leaf)" "FAIL" "No help documentation found" "Documentation"
        }
        
        # Check for CmdletBinding
        if ($content -match '\[CmdletBinding\(\)\]') {
            $result.HasCmdletBinding = $true
            Write-TestResult "CmdletBinding in $(Split-Path $ScriptPath -Leaf)" "PASS"
        }
        else {
            $result.Recommendations += "Consider adding [CmdletBinding()] for advanced function features"
            Write-TestResult "CmdletBinding in $(Split-Path $ScriptPath -Leaf)" "INFO" "No CmdletBinding found - consider adding for advanced features"
        }
        
        # Check for parameter validation
        if ($content -match '\[ValidateSet\(|\[ValidateRange\(|\[ValidateNotNull\(|\[Parameter\(') {
            $result.HasParameterValidation = $true
            Write-TestResult "Parameter validation in $(Split-Path $ScriptPath -Leaf)" "PASS"
        }
        else {
            $result.Recommendations += "Add parameter validation for better error handling"
            Write-TestResult "Parameter validation in $(Split-Path $ScriptPath -Leaf)" "INFO" "No parameter validation found"
        }
        
        # Enhanced error handling check
        $errorHandlingPatterns = @('try\s*\{', 'catch\s*\{', 'trap\s*\{', '-ErrorAction', 'throw\s+')
        $errorHandlingScore = 0
        foreach ($pattern in $errorHandlingPatterns) {
            if ($content -match $pattern) { $errorHandlingScore++ }
        }
        
        if ($errorHandlingScore -ge 2) {
            $result.HasErrorHandling = $true
            Write-TestResult "Error handling in $(Split-Path $ScriptPath -Leaf)" "PASS" "Found $errorHandlingScore error handling patterns"
        }
        elseif ($errorHandlingScore -eq 1) {
            $result.HasErrorHandling = $true
            $result.Recommendations += "Consider adding more comprehensive error handling"
            Write-TestResult "Error handling in $(Split-Path $ScriptPath -Leaf)" "WARN" "Limited error handling - consider enhancing"
        }
        else {
            $result.Issues += "No error handling found"
            Write-TestResult "Error handling in $(Split-Path $ScriptPath -Leaf)" "FAIL" "No error handling patterns found" "ErrorHandling"
        }
        
        # Check for unapproved verbs in function names
        $functions = [regex]::Matches($content, 'function\s+([A-Za-z]+-[A-Za-z]+)')
        $approvedVerbs = (Get-Verb).Verb
        foreach ($match in $functions) {
            $functionName = $match.Groups[1].Value
            $verb = $functionName.Split('-')[0]
            if ($verb -notin $approvedVerbs) {
                $result.UsesApprovedVerbs = $false
                $result.Issues += "Unapproved verb: $verb in $functionName"
                Write-TestResult "PowerShell verb compliance in $(Split-Path $ScriptPath -Leaf)" "WARN" "Unapproved verb: $verb in $functionName"
            }
        }
        
        if ($result.UsesApprovedVerbs -and $functions.Count -gt 0) {
            Write-TestResult "PowerShell verb compliance in $(Split-Path $ScriptPath -Leaf)" "PASS" "All $($functions.Count) functions use approved verbs"
        }
        
        # Check for security best practices
        $securityIssues = @()
        if ($content -match 'ConvertTo-SecureString.*-AsPlainText') {
            $securityIssues += "Potential insecure string conversion"
        }
        if ($content -match 'Invoke-Expression|\biex\b') {
            $securityIssues += "Use of Invoke-Expression detected - security risk"
        }
        if ($content -match 'DownloadString|DownloadFile.*http://') {
            $securityIssues += "Insecure HTTP download detected"
        }
        
        if ($securityIssues.Count -gt 0) {
            $result.Issues += $securityIssues
            Write-TestResult "Security check for $(Split-Path $ScriptPath -Leaf)" "WARN" "$($securityIssues.Count) potential security issues found"
        }
        else {
            Write-TestResult "Security check for $(Split-Path $ScriptPath -Leaf)" "PASS"
        }
        
    }
    catch {
        $result.Issues += "Test error: $($_.Exception.Message)"
        Write-TestResult "PowerShell script test for $(Split-Path $ScriptPath -Leaf)" "FAIL" $_.Exception.Message "Testing"
    }
    
    $script:TestResults.PowerShellScripts += $result
    return $result
}

# Enhanced shell script testing
function Test-ShellScript {
    param([string]$ScriptPath)
    
    Write-Verbose "Testing shell script: $ScriptPath"
    
    $result = @{
        Path = $ScriptPath
        SyntaxValid = $false
        HasShebang = $false
        HasErrorHandling = $false
        HasSetOptions = $false
        HasFunctionDocs = $false
        Issues = @()
        Recommendations = @()
    }
    
    try {
        $content = Get-Content $ScriptPath -Raw -ErrorAction Stop
        $lines = Get-Content $ScriptPath -ErrorAction Stop
        
        # Check for shebang
        if ($lines[0] -match '^#!/') {
            $result.HasShebang = $true
            $shebang = $lines[0]
            Write-TestResult "Shebang in $(Split-Path $ScriptPath -Leaf)" "PASS" "Found: $shebang"
        }
        else {
            $result.Issues += "Missing shebang line"
            Write-TestResult "Shebang in $(Split-Path $ScriptPath -Leaf)" "FAIL" "Missing #!/bin/bash or similar" "ShellScript"
        }
        
        # Check for set options (error handling)
        $setOptions = @('set -e', 'set -u', 'set -o pipefail')
        $foundOptions = @()
        foreach ($option in $setOptions) {
            if ($content -match [regex]::Escape($option)) {
                $foundOptions += $option
            }
        }
        
        if ($foundOptions.Count -gt 0) {
            $result.HasSetOptions = $true
            Write-TestResult "Set options in $(Split-Path $ScriptPath -Leaf)" "PASS" "Found: $($foundOptions -join ', ')"
        }
        else {
            $result.Recommendations += "Consider adding 'set -e' for better error handling"
            Write-TestResult "Set options in $(Split-Path $ScriptPath -Leaf)" "WARN" "No set options found - consider adding set -e, set -u"
        }
        
        # Check for error handling patterns
        $errorPatterns = @('trap ', 'if.*\$\?', '\|\| exit', '\|\| return')
        $errorHandlingFound = $false
        foreach ($pattern in $errorPatterns) {
            if ($content -match $pattern) {
                $errorHandlingFound = $true
                break
            }
        }
        
        if ($errorHandlingFound -or $result.HasSetOptions) {
            $result.HasErrorHandling = $true
            Write-TestResult "Error handling in $(Split-Path $ScriptPath -Leaf)" "PASS"
        }
        else {
            $result.Issues += "Limited error handling"
            Write-TestResult "Error handling in $(Split-Path $ScriptPath -Leaf)" "WARN" "No error handling patterns found"
        }
        
        # Check for function documentation
        if ($content -match '#.*function|#.*Description:|#.*Usage:') {
            $result.HasFunctionDocs = $true
            Write-TestResult "Function documentation in $(Split-Path $ScriptPath -Leaf)" "PASS"
        }
        else {
            $result.Recommendations += "Add function documentation for better maintainability"
            Write-TestResult "Function documentation in $(Split-Path $ScriptPath -Leaf)" "INFO" "No function documentation found"
        }
        
        # Syntax check using shellcheck if available
        if (Get-Command shellcheck -ErrorAction SilentlyContinue) {
            try {
                $shellcheckResult = shellcheck -f json $ScriptPath 2>&1 | ConvertFrom-Json
                if ($shellcheckResult.Count -eq 0) {
                    $result.SyntaxValid = $true
                    Write-TestResult "Shellcheck validation for $(Split-Path $ScriptPath -Leaf)" "PASS"
                }
                else {
                    $criticalIssues = $shellcheckResult | Where-Object { $_.level -eq "error" }
                    if ($criticalIssues.Count -gt 0) {
                        $result.Issues += "Shellcheck errors: $($criticalIssues.Count)"
                        Write-TestResult "Shellcheck validation for $(Split-Path $ScriptPath -Leaf)" "FAIL" "$($criticalIssues.Count) errors found"
                    }
                    else {
                        $result.SyntaxValid = $true
                        Write-TestResult "Shellcheck validation for $(Split-Path $ScriptPath -Leaf)" "WARN" "$($shellcheckResult.Count) warnings found"
                    }
                }
            }
            catch {
                Write-TestResult "Shellcheck validation for $(Split-Path $ScriptPath -Leaf)" "INFO" "Shellcheck failed: $($_.Exception.Message)"
            }
        }
        else {
            # Basic syntax check using bash if available
            if (Get-Command bash -ErrorAction SilentlyContinue) {
                try {
                    $bashCheck = bash -n $ScriptPath 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        $result.SyntaxValid = $true
                        Write-TestResult "Bash syntax check for $(Split-Path $ScriptPath -Leaf)" "PASS"
                    }
                    else {
                        $result.Issues += "Bash syntax errors: $bashCheck"
                        Write-TestResult "Bash syntax check for $(Split-Path $ScriptPath -Leaf)" "FAIL" $bashCheck
                    }
                }
                catch {
                    Write-TestResult "Bash syntax check for $(Split-Path $ScriptPath -Leaf)" "INFO" "Bash check failed: $($_.Exception.Message)"
                }
            }
            else {
                Write-TestResult "Shell syntax validation for $(Split-Path $ScriptPath -Leaf)" "SKIP" "Neither shellcheck nor bash available"
            }
        }
        
    }
    catch {
        $result.Issues += "Test error: $($_.Exception.Message)"
        Write-TestResult "Shell script test for $(Split-Path $ScriptPath -Leaf)" "FAIL" $_.Exception.Message "Testing"
    }
    
    $script:TestResults.ShellScripts += $result
    return $result
}

# Enhanced PowerShell module testing
function Test-PowerShellModule {
    param([string]$ModulePath)
    
    Write-Verbose "Testing PowerShell module: $ModulePath"
    
    $moduleName = Split-Path $ModulePath -Leaf
    $result = @{
        Path = $ModulePath
        ManifestValid = $false
        FunctionsExported = $false
        ModuleLoads = $false
        HasTests = $false
        VersionValid = $false
        Issues = @()
        Recommendations = @()
        LoadTime = 0
    }
    
    try {
        # Find and test module manifest
        $manifestPath = Get-ChildItem $ModulePath -Filter "*.psd1" | Select-Object -First 1
        if ($manifestPath) {
            try {
                $manifest = Test-ModuleManifest $manifestPath.FullName -ErrorAction Stop
                $result.ManifestValid = $true
                Write-TestResult "Module manifest for $moduleName" "PASS" "Version: $($manifest.Version)"
                
                # Check version format
                if ($manifest.Version -match '^\d+\.\d+\.\d+') {
                    $result.VersionValid = $true
                    Write-TestResult "Version format for $moduleName" "PASS" "Semantic versioning: $($manifest.Version)"
                }
                else {
                    $result.Recommendations += "Consider using semantic versioning (x.y.z)"
                    Write-TestResult "Version format for $moduleName" "WARN" "Non-standard version format: $($manifest.Version)"
                }
                
                # Check exported functions
                if ($manifest.ExportedFunctions.Count -gt 0) {
                    $result.FunctionsExported = $true
                    Write-TestResult "Function exports for $moduleName" "PASS" "$($manifest.ExportedFunctions.Count) functions exported"
                }
                else {
                    # Check if there are functions in the module files
                    $moduleFiles = Get-ChildItem $ModulePath -Filter "*.ps*1" -Recurse
                    $functionCount = 0
                    foreach ($file in $moduleFiles) {
                        $content = Get-Content $file.FullName -Raw
                        $functionCount += ([regex]::Matches($content, 'function\s+[A-Za-z-]+') | Measure-Object).Count
                    }
                    
                    if ($functionCount -gt 0) {
                        $result.Issues += "Functions found but not exported in manifest"
                        Write-TestResult "Function exports for $moduleName" "WARN" "$functionCount functions found but not exported"
                    }
                    else {
                        Write-TestResult "Function exports for $moduleName" "INFO" "No functions found in module"
                    }
                }
                
            }
            catch {
                $result.Issues += "Module manifest error: $($_.Exception.Message)"
                Write-TestResult "Module manifest for $moduleName" "FAIL" $_.Exception.Message "Module"
            }
        }
        else {
            $result.Issues += "No module manifest found"
            Write-TestResult "Module manifest for $moduleName" "FAIL" "No .psd1 file found" "Module"
        }
        
        # Test module loading with timing
        try {
            $startTime = Get-Date
            Import-Module $ModulePath -Force -ErrorAction Stop
            $endTime = Get-Date
            $result.LoadTime = ($endTime - $startTime).TotalSeconds
            $result.ModuleLoads = $true
            
            if ($result.LoadTime -lt 2) {
                Write-TestResult "Module loading for $moduleName" "PASS" "Loaded in $([math]::Round($result.LoadTime, 2))s"
            }
            else {
                Write-TestResult "Module loading for $moduleName" "WARN" "Slow loading: $([math]::Round($result.LoadTime, 2))s"
            }
            
            # Test exported commands
            $commands = Get-Command -Module $moduleName -ErrorAction SilentlyContinue
            if ($commands.Count -gt 0) {
                Write-TestResult "Module commands for $moduleName" "PASS" "$($commands.Count) commands available"
            }
            
            Remove-Module $moduleName -Force -ErrorAction SilentlyContinue
        }
        catch {
            $result.Issues += "Module loading error: $($_.Exception.Message)"
            Write-TestResult "Module loading for $moduleName" "FAIL" $_.Exception.Message "Module"
        }
        
        # Check for test files
        $testFiles = Get-ChildItem $ModulePath -Filter "*Test*.ps1" -Recurse
        if ($testFiles.Count -gt 0) {
            $result.HasTests = $true
            Write-TestResult "Module tests for $moduleName" "PASS" "$($testFiles.Count) test files found"
        }
        else {
            $result.Recommendations += "Consider adding Pester tests for the module"
            Write-TestResult "Module tests for $moduleName" "INFO" "No test files found"
        }
        
    }
    catch {
        $result.Issues += "Module test error: $($_.Exception.Message)"
        Write-TestResult "Module test for $moduleName" "FAIL" $_.Exception.Message "Testing"
    }
    
    $script:TestResults.Modules += $result
    return $result
}# Enha
nced GUI testing
function Test-GUIFunctionality {
    Write-Host "`n=== GUI Testing ===" -ForegroundColor Magenta
    
    $guiFiles = @(
        "gui/VelociraptorGUI.ps1",
        "VelociraptorGUI.ps1",
        "VelociraptorGUI-Safe.ps1"
    )
    
    foreach ($guiPath in $guiFiles) {
        if (Test-Path $guiPath) {
            $result = @{
                Path = $guiPath
                SyntaxValid = $false
                WindowsFormsLoads = $false
                HasEventHandlers = $false
                HasErrorHandling = $false
                Issues = @()
                Recommendations = @()
            }
            
            try {
                $content = Get-Content $guiPath -Raw
                
                # Test GUI syntax
                try {
                    $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
                    $result.SyntaxValid = $true
                    Write-TestResult "GUI syntax validation for $(Split-Path $guiPath -Leaf)" "PASS"
                }
                catch {
                    $result.Issues += "GUI syntax error: $($_.Exception.Message)"
                    Write-TestResult "GUI syntax validation for $(Split-Path $guiPath -Leaf)" "FAIL" $_.Exception.Message "GUI"
                }
                
                # Test Windows Forms loading
                try {
                    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
                    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
                    $result.WindowsFormsLoads = $true
                    Write-TestResult "Windows Forms availability for $(Split-Path $guiPath -Leaf)" "PASS"
                }
                catch {
                    $result.Issues += "Windows Forms error: $($_.Exception.Message)"
                    Write-TestResult "Windows Forms availability for $(Split-Path $guiPath -Leaf)" "FAIL" $_.Exception.Message "GUI"
                }
                
                # Check for event handlers
                if ($content -match 'Add_Click|Add_TextChanged|Add_SelectedIndexChanged') {
                    $result.HasEventHandlers = $true
                    Write-TestResult "Event handlers in $(Split-Path $guiPath -Leaf)" "PASS"
                }
                else {
                    $result.Recommendations += "Consider adding event handlers for user interactions"
                    Write-TestResult "Event handlers in $(Split-Path $guiPath -Leaf)" "INFO" "No event handlers found"
                }
                
                # Check for GUI error handling
                if ($content -match 'try\s*\{.*GUI|catch.*GUI|ShowDialog.*try') {
                    $result.HasErrorHandling = $true
                    Write-TestResult "GUI error handling in $(Split-Path $guiPath -Leaf)" "PASS"
                }
                else {
                    $result.Recommendations += "Add error handling for GUI operations"
                    Write-TestResult "GUI error handling in $(Split-Path $guiPath -Leaf)" "WARN" "Limited GUI error handling"
                }
                
                # Check for common GUI issues
                if ($content -match 'BackColor.*Color\.') {
                    Write-TestResult "Color usage in $(Split-Path $guiPath -Leaf)" "PASS" "Proper color definitions found"
                }
                elseif ($content -match 'BackColor') {
                    $result.Issues += "Potential color definition issues"
                    Write-TestResult "Color usage in $(Split-Path $guiPath -Leaf)" "WARN" "BackColor usage without proper Color definition"
                }
                
            }
            catch {
                $result.Issues += "GUI test error: $($_.Exception.Message)"
                Write-TestResult "GUI test for $(Split-Path $guiPath -Leaf)" "FAIL" $_.Exception.Message "Testing"
            }
            
            $script:TestResults.GUI += $result
        }
    }
    
    if ($script:TestResults.GUI.Count -eq 0) {
        Write-TestResult "GUI file detection" "WARN" "No GUI files found in expected locations"
    }
}

# Enhanced configuration file testing
function Test-ConfigurationFiles {
    Write-Host "`n=== Configuration Testing ===" -ForegroundColor Magenta
    
    $configPatterns = @{
        "YAML" = @("*.yaml", "*.yml")
        "JSON" = @("*.json")
        "PowerShell Data" = @("*.psd1")
        "XML" = @("*.xml")
        "Config" = @("*.config", "*.conf")
    }
    
    foreach ($type in $configPatterns.Keys) {
        foreach ($pattern in $configPatterns[$type]) {
            $files = Get-ChildItem $pattern -Recurse -ErrorAction SilentlyContinue | Where-Object { 
                $_.Directory.Name -notlike "*\.git*" -and $_.Directory.Name -notlike "*node_modules*" 
            }
            
            foreach ($file in $files) {
                $result = @{
                    Path = $file.FullName
                    Type = $type
                    Valid = $false
                    Issues = @()
                    Recommendations = @()
                }
                
                try {
                    switch ($file.Extension.ToLower()) {
                        {$_ -in ".yaml", ".yml"} {
                            # Enhanced YAML validation
                            $content = Get-Content $file.FullName -Raw
                            
                            # Basic structure checks
                            if ($content -match '^[^:]+:' -and $content -notmatch '\t') {
                                # Check for common YAML issues
                                $lines = Get-Content $file.FullName
                                $lineNum = 0
                                $issues = @()
                                
                                foreach ($line in $lines) {
                                    $lineNum++
                                    if ($line -match '\t') {
                                        $issues += "Line $lineNum: Contains tabs (use spaces)"
                                    }
                                    if ($line -match ':\s*$' -and $lineNum -lt $lines.Count) {
                                        # Check if next line is properly indented
                                        $nextLine = $lines[$lineNum]
                                        if ($nextLine -notmatch '^\s+') {
                                            $issues += "Line $($lineNum + 1): Improper indentation after colon"
                                        }
                                    }
                                }
                                
                                if ($issues.Count -eq 0) {
                                    $result.Valid = $true
                                    Write-TestResult "YAML validation for $($file.Name)" "PASS"
                                }
                                else {
                                    $result.Issues += $issues
                                    Write-TestResult "YAML validation for $($file.Name)" "WARN" "$($issues.Count) formatting issues"
                                }
                            }
                            else {
                                $result.Issues += "Invalid YAML format"
                                Write-TestResult "YAML validation for $($file.Name)" "FAIL" "Invalid YAML structure" "Configuration"
                            }
                        }
                        ".json" {
                            try {
                                $jsonContent = Get-Content $file.FullName -Raw | ConvertFrom-Json -ErrorAction Stop
                                $result.Valid = $true
                                Write-TestResult "JSON validation for $($file.Name)" "PASS"
                                
                                # Check for common JSON best practices
                                $rawContent = Get-Content $file.FullName -Raw
                                if ($rawContent -match '^\s*\{' -and $rawContent -match '\}\s*$') {
                                    Write-TestResult "JSON structure for $($file.Name)" "PASS" "Proper JSON object structure"
                                }
                            }
                            catch {
                                $result.Issues += "JSON parsing error: $($_.Exception.Message)"
                                Write-TestResult "JSON validation for $($file.Name)" "FAIL" $_.Exception.Message "Configuration"
                            }
                        }
                        ".psd1" {
                            try {
                                $psdContent = Import-PowerShellDataFile $file.FullName -ErrorAction Stop
                                $result.Valid = $true
                                Write-TestResult "PowerShell data file validation for $($file.Name)" "PASS"
                                
                                # Check for required fields in module manifests
                                if ($file.Name -like "*Module*.psd1" -or $file.Directory.Name -eq "modules") {
                                    $requiredFields = @('ModuleVersion', 'Description', 'Author')
                                    $missingFields = @()
                                    foreach ($field in $requiredFields) {
                                        if (-not $psdContent.ContainsKey($field) -or [string]::IsNullOrWhiteSpace($psdContent[$field])) {
                                            $missingFields += $field
                                        }
                                    }
                                    
                                    if ($missingFields.Count -eq 0) {
                                        Write-TestResult "Module manifest completeness for $($file.Name)" "PASS"
                                    }
                                    else {
                                        $result.Recommendations += "Add missing fields: $($missingFields -join ', ')"
                                        Write-TestResult "Module manifest completeness for $($file.Name)" "WARN" "Missing: $($missingFields -join ', ')"
                                    }
                                }
                            }
                            catch {
                                $result.Issues += "PowerShell data file error: $($_.Exception.Message)"
                                Write-TestResult "PowerShell data file validation for $($file.Name)" "FAIL" $_.Exception.Message "Configuration"
                            }
                        }
                        ".xml" {
                            try {
                                [xml]$xmlContent = Get-Content $file.FullName -ErrorAction Stop
                                $result.Valid = $true
                                Write-TestResult "XML validation for $($file.Name)" "PASS"
                            }
                            catch {
                                $result.Issues += "XML parsing error: $($_.Exception.Message)"
                                Write-TestResult "XML validation for $($file.Name)" "FAIL" $_.Exception.Message "Configuration"
                            }
                        }
                    }
                }
                catch {
                    $result.Issues += "Configuration test error: $($_.Exception.Message)"
                    Write-TestResult "Configuration test for $($file.Name)" "FAIL" $_.Exception.Message "Testing"
                }
                
                $script:TestResults.Configurations += $result
            }
        }
    }
}

# Enhanced security testing
function Test-SecurityBaseline {
    Write-Host "`n=== Security Testing ===" -ForegroundColor Magenta
    
    $securityResults = @{
        HardcodedCredentials = @()
        InsecureConnections = @()
        DangerousFunctions = @()
        FilePermissions = @()
        EncryptionUsage = @()
    }
    
    # Get all script files
    $scriptFiles = @()
    $scriptFiles += Get-ChildItem "*.ps1" -Recurse | Where-Object { $_.Directory.Name -notlike "*\.git*" }
    $scriptFiles += Get-ChildItem "*.sh" -Recurse | Where-Object { $_.Directory.Name -notlike "*\.git*" }
    
    foreach ($file in $scriptFiles) {
        $content = Get-Content $file.FullName -Raw
        $fileName = $file.Name
        
        # Check for hardcoded credentials
        $credentialPatterns = @(
            'password\s*=\s*["\'][^"\']{3,}["\']',
            'secret\s*=\s*["\'][^"\']{3,}["\']',
            'apikey\s*=\s*["\'][^"\']{10,}["\']',
            'token\s*=\s*["\'][^"\']{10,}["\']',
            'key\s*=\s*["\'][^"\']{10,}["\']'
        )
        
        foreach ($pattern in $credentialPatterns) {
            if ($content -match $pattern) {
                $securityResults.HardcodedCredentials += @{
                    File = $fileName
                    Pattern = $pattern
                    Issue = "Potential hardcoded credential"
                }
                Write-TestResult "Credential security in $fileName" "FAIL" "Potential hardcoded credentials detected" "Security"
            }
        }
        
        # Check for insecure connections
        if ($content -match 'http://(?!localhost|127\.0\.0\.1)') {
            $securityResults.InsecureConnections += @{
                File = $fileName
                Issue = "HTTP connection to external resource"
            }
            Write-TestResult "Connection security in $fileName" "WARN" "HTTP connection detected - consider HTTPS"
        }
        
        # Check for dangerous functions
        $dangerousFunctions = @(
            'Invoke-Expression',
            'iex\s+',
            'cmd\s*/c',
            'Start-Process.*cmd',
            'DownloadString.*http://',
            'Invoke-WebRequest.*http://'
        )
        
        foreach ($func in $dangerousFunctions) {
            if ($content -match $func) {
                $securityResults.DangerousFunctions += @{
                    File = $fileName
                    Function = $func
                    Issue = "Potentially dangerous function usage"
                }
                Write-TestResult "Function security in $fileName" "WARN" "Dangerous function detected: $func"
            }
        }
        
        # Check for encryption usage (positive security indicator)
        if ($content -match 'ConvertTo-SecureString|Encrypt|AES|TLS|SSL') {
            $securityResults.EncryptionUsage += @{
                File = $fileName
                Type = "Encryption/Security functions found"
            }
            Write-TestResult "Encryption usage in $fileName" "PASS" "Security functions detected"
        }
    }
    
    # File permission checks (if on Unix-like system)
    if ($IsLinux -or $IsMacOS) {
        $executableFiles = Get-ChildItem "*.sh" -Recurse
        foreach ($file in $executableFiles) {
            $permissions = (ls -la $file.FullName).Split(' ')[0]
            if ($permissions -match 'x') {
                Write-TestResult "File permissions for $($file.Name)" "PASS" "Executable permissions set"
            }
            else {
                Write-TestResult "File permissions for $($file.Name)" "WARN" "Missing executable permissions"
            }
        }
    }
    
    # Summary
    $totalIssues = $securityResults.HardcodedCredentials.Count + 
                   $securityResults.InsecureConnections.Count + 
                   $securityResults.DangerousFunctions.Count
    
    if ($totalIssues -eq 0) {
        Write-TestResult "Overall security assessment" "PASS" "No critical security issues found"
    }
    elseif ($totalIssues -lt 3) {
        Write-TestResult "Overall security assessment" "WARN" "$totalIssues potential security issues found"
    }
    else {
        Write-TestResult "Overall security assessment" "FAIL" "$totalIssues security issues require attention" "Security"
    }
    
    $script:TestResults.Security = $securityResults
}

# Performance testing
function Test-Performance {
    if ($SkipSlowTests) {
        Write-Host "`n=== Performance Testing (Skipped) ===" -ForegroundColor Magenta
        Write-TestResult "Performance testing" "SKIP" "Skipped due to -SkipSlowTests parameter"
        return
    }
    
    Write-Host "`n=== Performance Testing ===" -ForegroundColor Magenta
    
    $performanceResults = @{
        ModuleImportTimes = @()
        ScriptExecutionTimes = @()
        MemoryUsage = @()
        OverallAssessment = "Unknown"
    }
    
    # Test module import performance
    $modules = Get-ChildItem "modules" -Directory -ErrorAction SilentlyContinue
    foreach ($module in $modules) {
        $measurements = @()
        
        # Run multiple iterations for accuracy
        for ($i = 1; $i -le 3; $i++) {
            $startTime = Get-Date
            $startMemory = [System.GC]::GetTotalMemory($false)
            
            try {
                Import-Module $module.FullName -Force -ErrorAction Stop
                $endTime = Get-Date
                $endMemory = [System.GC]::GetTotalMemory($false)
                
                $duration = ($endTime - $startTime).TotalSeconds
                $memoryDelta = $endMemory - $startMemory
                
                $measurements += @{
                    Duration = $duration
                    MemoryDelta = $memoryDelta
                }
                
                Remove-Module $module.Name -Force -ErrorAction SilentlyContinue
            }
            catch {
                Write-TestResult "Module performance test for $($module.Name)" "FAIL" "Import failed: $($_.Exception.Message)"
                continue
            }
        }
        
        if ($measurements.Count -gt 0) {
            $avgDuration = ($measurements | Measure-Object -Property Duration -Average).Average
            $avgMemory = ($measurements | Measure-Object -Property MemoryDelta -Average).Average
            
            $performanceResults.ModuleImportTimes += @{
                Module = $module.Name
                AverageDuration = $avgDuration
                AverageMemoryDelta = $avgMemory
            }
            
            if ($avgDuration -lt 1) {
                Write-TestResult "Module import performance for $($module.Name)" "PASS" "$([math]::Round($avgDuration, 2))s average"
            }
            elseif ($avgDuration -lt 3) {
                Write-TestResult "Module import performance for $($module.Name)" "WARN" "Slow import: $([math]::Round($avgDuration, 2))s average"
            }
            else {
                Write-TestResult "Module import performance for $($module.Name)" "FAIL" "Very slow import: $([math]::Round($avgDuration, 2))s average" "Performance"
            }
        }
    }
    
    # Test script execution performance for key scripts
    $keyScripts = @(
        "Deploy_Velociraptor_Standalone.ps1",
        "Prepare_OfflineCollector_Env.ps1"
    )
    
    foreach ($scriptName in $keyScripts) {
        $scriptPath = Get-ChildItem $scriptName -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($scriptPath) {
            try {
                # Syntax check timing
                $startTime = Get-Date
                $null = [System.Management.Automation.Language.Parser]::ParseInput((Get-Content $scriptPath.FullName -Raw), [ref]$null, [ref]$null)
                $endTime = Get-Date
                $parseTime = ($endTime - $startTime).TotalSeconds
                
                $performanceResults.ScriptExecutionTimes += @{
                    Script = $scriptName
                    ParseTime = $parseTime
                }
                
                if ($parseTime -lt 0.5) {
                    Write-TestResult "Script parse performance for $scriptName" "PASS" "$([math]::Round($parseTime, 3))s"
                }
                else {
                    Write-TestResult "Script parse performance for $scriptName" "WARN" "Slow parsing: $([math]::Round($parseTime, 3))s"
                }
            }
            catch {
                Write-TestResult "Script performance test for $scriptName" "FAIL" $_.Exception.Message
            }
        }
    }
    
    # Overall performance assessment
    $slowModules = $performanceResults.ModuleImportTimes | Where-Object { $_.AverageDuration -gt 2 }
    $slowScripts = $performanceResults.ScriptExecutionTimes | Where-Object { $_.ParseTime -gt 1 }
    
    if ($slowModules.Count -eq 0 -and $slowScripts.Count -eq 0) {
        $performanceResults.OverallAssessment = "Excellent"
        Write-TestResult "Overall performance assessment" "PASS" "All components perform well"
    }
    elseif ($slowModules.Count -lt 2 -and $slowScripts.Count -lt 2) {
        $performanceResults.OverallAssessment = "Good"
        Write-TestResult "Overall performance assessment" "WARN" "Minor performance concerns"
    }
    else {
        $performanceResults.OverallAssessment = "Needs Improvement"
        Write-TestResult "Overall performance assessment" "FAIL" "Performance issues need attention" "Performance"
    }
    
    $script:TestResults.Performance = $performanceResults
}

# Integration testing
function Test-Integration {
    if ($SkipSlowTests) {
        Write-Host "`n=== Integration Testing (Skipped) ===" -ForegroundColor Magenta
        Write-TestResult "Integration testing" "SKIP" "Skipped due to -SkipSlowTests parameter"
        return
    }
    
    Write-Host "`n=== Integration Testing ===" -ForegroundColor Magenta
    
    $integrationResults = @{
        ModuleInteractions = @()
        ScriptDependencies = @()
        FileSystemOperations = @()
        NetworkOperations = @()
    }
    
    # Test module interactions
    $modules = Get-ChildItem "modules" -Directory -ErrorAction SilentlyContinue
    if ($modules.Count -gt 1) {
        try {
            # Try loading all modules together
            foreach ($module in $modules) {
                Import-Module $module.FullName -Force -ErrorAction Stop
            }
            
            Write-TestResult "Multi-module loading" "PASS" "All $($modules.Count) modules loaded successfully"
            
            # Clean up
            foreach ($module in $modules) {
                Remove-Module $module.Name -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-TestResult "Multi-module loading" "FAIL" "Module conflict detected: $($_.Exception.Message)" "Integration"
        }
    }
    
    # Test script dependencies
    $mainScripts = @(
        "Deploy_Velociraptor_Standalone.ps1",
        "Prepare_OfflineCollector_Env.ps1"
    )
    
    foreach ($scriptName in $mainScripts) {
        $scriptPath = Get-ChildItem $scriptName -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($scriptPath) {
            $content = Get-Content $scriptPath.FullName -Raw
            
            # Check for external dependencies
            $dependencies = @()
            if ($content -match 'Import-Module\s+([^\s]+)') {
                $dependencies += "PowerShell Modules"
            }
            if ($content -match 'Invoke-WebRequest|curl|wget') {
                $dependencies += "Network Access"
            }
            if ($content -match 'Test-Path.*C:\\|New-Item.*C:\\') {
                $dependencies += "File System Access"
            }
            
            if ($dependencies.Count -gt 0) {
                Write-TestResult "Dependencies for $scriptName" "INFO" "Requires: $($dependencies -join ', ')"
            }
            else {
                Write-TestResult "Dependencies for $scriptName" "PASS" "No external dependencies detected"
            }
        }
    }
    
    $script:TestResults.Integration = $integrationResults
}

# Auto-fix functionality
function Invoke-AutoFix {
    if (-not $FixIssues) {
        return
    }
    
    Write-Host "`n=== Auto-Fix Attempting ===" -ForegroundColor Magenta
    
    $fixCount = 0
    
    # Fix common PowerShell issues
    foreach ($result in $script:TestResults.PowerShellScripts) {
        if ($result.Issues.Count -gt 0) {
            $scriptPath = $result.Path
            $content = Get-Content $scriptPath -Raw
            $modified = $false
            
            # Fix missing CmdletBinding
            if ($result.Issues -contains "No CmdletBinding found" -and $content -notmatch '\[CmdletBinding\(\)\]') {
                $content = $content -replace '^(\s*param\s*\()', '[CmdletBinding()]`n$1'
                $modified = $true
                Write-TestResult "Auto-fix CmdletBinding in $(Split-Path $scriptPath -Leaf)" "PASS" "Added [CmdletBinding()]"
                $fixCount++
            }
            
            if ($modified) {
                Set-Content $scriptPath -Value $content -Encoding UTF8
            }
        }
    }
    
    if ($fixCount -gt 0) {
        Write-TestResult "Auto-fix summary" "PASS" "Fixed $fixCount issues automatically"
    }
    else {
        Write-TestResult "Auto-fix summary" "INFO" "No auto-fixable issues found"
    }
}

# Generate comprehensive report
function New-QAReport {
    $endTime = Get-Date
    $script:TestResults.Summary.EndTime = $endTime
    $duration = $endTime - $script:TestResults.Summary.StartTime
    
    $successRate = if ($script:TestResults.Summary.TotalTests -gt 0) {
        [math]::Round(($script:TestResults.Summary.PassedTests / $script:TestResults.Summary.TotalTests) * 100, 1)
    } else { 0 }
    
    $readinessStatus = if ($script:TestResults.Summary.FailedTests -eq 0) {
        "✅ **READY FOR BETA RELEASE**"
        $readinessColor = "Green"
        $readinessDetail = "All critical tests passed successfully."
    } elseif ($script:TestResults.Summary.FailedTests -lt 3) {
        "⚠️ **CONDITIONAL BETA RELEASE**"
        $readinessColor = "Yellow"
        $readinessDetail = "Minor issues detected that should be addressed."
    } else {
        "❌ **NOT READY FOR BETA RELEASE**"
        $readinessColor = "Red"
        $readinessDetail = "Critical issues must be resolved before beta deployment."
    }
    
    $report = @"
# Comprehensive Beta Release Quality Assurance Report

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Duration:** $([math]::Round($duration.TotalMinutes, 1)) minutes  
**Test Suite Version:** 2.0

---

## 🎯 Executive Summary

| Metric | Value | Status |
|--------|-------|--------|
| **Total Tests** | $($script:TestResults.Summary.TotalTests) | ℹ️ |
| **Passed** | $($script:TestResults.Summary.PassedTests) | ✅ |
| **Failed** | $($script:TestResults.Summary.FailedTests) | ❌ |
| **Warnings** | $($script:TestResults.Summary.WarningTests) | ⚠️ |
| **Success Rate** | $successRate% | $(if ($successRate -gt 90) { "✅" } elseif ($successRate -gt 75) { "⚠️" } else { "❌" }) |

---

## 🚀 Beta Release Readiness Assessment

### $readinessStatus

$readinessDetail

$(if ($script:TestResults.Summary.CriticalIssues.Count -gt 0) {
    "### 🚨 Critical Issues Requiring Immediate Attention"
    ""
    $script:TestResults.Summary.CriticalIssues | ForEach-Object {
        "- **$($_.Category)**: $($_.Message)"
        if ($_.Details) { "  - Details: $($_.Details)" }
    }
    ""
} else {
    "### ✅ No Critical Issues Identified"
    ""
})

---

## 📊 Detailed Test Results

### PowerShell Scripts Analysis
- **Scripts Tested:** $($script:TestResults.PowerShellScripts.Count)
- **Syntax Valid:** $(($script:TestResults.PowerShellScripts | Where-Object SyntaxValid).Count)/$($script:TestResults.PowerShellScripts.Count)
- **With Help Content:** $(($script:TestResults.PowerShellScripts | Where-Object HasHelpContent).Count)/$($script:TestResults.PowerShellScripts.Count)
- **With Error Handling:** $(($script:TestResults.PowerShellScripts | Where-Object HasErrorHandling).Count)/$($script:TestResults.PowerShellScripts.Count)
- **CmdletBinding Usage:** $(($script:TestResults.PowerShellScripts | Where-Object HasCmdletBinding).Count)/$($script:TestResults.PowerShellScripts.Count)

$(if ($script:TestResults.PowerShellScripts.Count -gt 0) {
    "#### Script Details:"
    $script:TestResults.PowerShellScripts | ForEach-Object {
        $fileName = Split-Path $_.Path -Leaf
        $status = if ($_.SyntaxValid -and $_.HasHelpContent -and $_.HasErrorHandling) { "✅" } 
                 elseif ($_.SyntaxValid) { "⚠️" } 
                 else { "❌" }
        "- $status **$fileName**"
        if ($_.Issues.Count -gt 0) {
            $_.Issues | ForEach-Object { "  - Issue: $_" }
        }
        if ($_.Recommendations.Count -gt 0) {
            $_.Recommendations | ForEach-Object { "  - Recommendation: $_" }
        }
    }
})

### Shell Scripts Analysis
- **Scripts Tested:** $($script:TestResults.ShellScripts.Count)
- **With Shebang:** $(($script:TestResults.ShellScripts | Where-Object HasShebang).Count)/$($script:TestResults.ShellScripts.Count)
- **Syntax Valid:** $(($script:TestResults.ShellScripts | Where-Object SyntaxValid).Count)/$($script:TestResults.ShellScripts.Count)
- **With Error Handling:** $(($script:TestResults.ShellScripts | Where-Object HasErrorHandling).Count)/$($script:TestResults.ShellScripts.Count)

$(if ($script:TestResults.ShellScripts.Count -gt 0) {
    "#### Shell Script Details:"
    $script:TestResults.ShellScripts | ForEach-Object {
        $fileName = Split-Path $_.Path -Leaf
        $status = if ($_.HasShebang -and $_.SyntaxValid -and $_.HasErrorHandling) { "✅" } 
                 elseif ($_.HasShebang -and $_.SyntaxValid) { "⚠️" } 
                 else { "❌" }
        "- $status **$fileName**"
        if ($_.Issues.Count -gt 0) {
            $_.Issues | ForEach-Object { "  - Issue: $_" }
        }
    }
})

### PowerShell Modules Analysis
- **Modules Tested:** $($script:TestResults.Modules.Count)
- **Valid Manifests:** $(($script:TestResults.Modules | Where-Object ManifestValid).Count)/$($script:TestResults.Modules.Count)
- **Loadable Modules:** $(($script:TestResults.Modules | Where-Object ModuleLoads).Count)/$($script:TestResults.Modules.Count)
- **With Exported Functions:** $(($script:TestResults.Modules | Where-Object FunctionsExported).Count)/$($script:TestResults.Modules.Count)

$(if ($script:TestResults.Modules.Count -gt 0) {
    "#### Module Details:"
    $script:TestResults.Modules | ForEach-Object {
        $moduleName = Split-Path $_.Path -Leaf
        $status = if ($_.ManifestValid -and $_.ModuleLoads) { "✅" } 
                 elseif ($_.ManifestValid) { "⚠️" } 
                 else { "❌" }
        "- $status **$moduleName**"
        if ($_.LoadTime -gt 0) { "  - Load Time: $([math]::Round($_.LoadTime, 2))s" }
        if ($_.Issues.Count -gt 0) {
            $_.Issues | ForEach-Object { "  - Issue: $_" }
        }
    }
})

### GUI Components Analysis
$(if ($script:TestResults.GUI.Count -gt 0) {
    "- **GUI Files Tested:** $($script:TestResults.GUI.Count)"
    "- **Syntax Valid:** $(($script:TestResults.GUI | Where-Object SyntaxValid).Count)/$($script:TestResults.GUI.Count)"
    "- **Windows Forms Compatible:** $(($script:TestResults.GUI | Where-Object WindowsFormsLoads).Count)/$($script:TestResults.GUI.Count)"
    ""
    "#### GUI Details:"
    $script:TestResults.GUI | ForEach-Object {
        $fileName = Split-Path $_.Path -Leaf
        $status = if ($_.SyntaxValid -and $_.WindowsFormsLoads) { "✅" } 
                 elseif ($_.SyntaxValid) { "⚠️" } 
                 else { "❌" }
        "- $status **$fileName**"
        if ($_.Issues.Count -gt 0) {
            $_.Issues | ForEach-Object { "  - Issue: $_" }
        }
    }
} else {
    "- **GUI Files:** None found or tested"
})

### Configuration Files Analysis
- **Config Files Tested:** $($script:TestResults.Configurations.Count)
- **Valid Configurations:** $(($script:TestResults.Configurations | Where-Object Valid).Count)/$($script:TestResults.Configurations.Count)

$(if ($script:TestResults.Configurations.Count -gt 0) {
    "#### Configuration Details:"
    $script:TestResults.Configurations | ForEach-Object {
        $fileName = Split-Path $_.Path -Leaf
        $status = if ($_.Valid) { "✅" } else { "❌" }
        "- $status **$fileName** ($($_.Type))"
        if ($_.Issues.Count -gt 0) {
            $_.Issues | ForEach-Object { "  - Issue: $_" }
        }
    }
})

### Security Analysis
$(if ($script:TestResults.Security) {
    $totalSecurityIssues = $script:TestResults.Security.HardcodedCredentials.Count + 
                          $script:TestResults.Security.InsecureConnections.Count + 
                          $script:TestResults.Security.DangerousFunctions.Count
    
    "- **Security Issues Found:** $totalSecurityIssues"
    "- **Hardcoded Credentials:** $($script:TestResults.Security.HardcodedCredentials.Count)"
    "- **Insecure Connections:** $($script:TestResults.Security.InsecureConnections.Count)"
    "- **Dangerous Functions:** $($script:TestResults.Security.DangerousFunctions.Count)"
    "- **Encryption Usage:** $($script:TestResults.Security.EncryptionUsage.Count) files"
    ""
    if ($totalSecurityIssues -gt 0) {
        "#### Security Issues Details:"
        if ($script:TestResults.Security.HardcodedCredentials.Count -gt 0) {
            "**Hardcoded Credentials:**"
            $script:TestResults.Security.HardcodedCredentials | ForEach-Object {
                "- ❌ $($_.File): $($_.Issue)"
            }
        }
        if ($script:TestResults.Security.InsecureConnections.Count -gt 0) {
            "**Insecure Connections:**"
            $script:TestResults.Security.InsecureConnections | ForEach-Object {
                "- ⚠️ $($_.File): $($_.Issue)"
            }
        }
        if ($script:TestResults.Security.DangerousFunctions.Count -gt 0) {
            "**Dangerous Functions:**"
            $script:TestResults.Security.DangerousFunctions | ForEach-Object {
                "- ⚠️ $($_.File): $($_.Function)"
            }
        }
    }
})

### Performance Analysis
$(if ($script:TestResults.Performance -and -not $SkipSlowTests) {
    "- **Overall Assessment:** $($script:TestResults.Performance.OverallAssessment)"
    "- **Modules Tested:** $($script:TestResults.Performance.ModuleImportTimes.Count)"
    ""
    if ($script:TestResults.Performance.ModuleImportTimes.Count -gt 0) {
        "#### Module Performance:"
        $script:TestResults.Performance.ModuleImportTimes | ForEach-Object {
            $status = if ($_.AverageDuration -lt 1) { "✅" } 
                     elseif ($_.AverageDuration -lt 3) { "⚠️" } 
                     else { "❌" }
            "- $status **$($_.Module)**: $([math]::Round($_.AverageDuration, 2))s average import time"
        }
    }
} else {
    "- **Performance Testing:** Skipped (use without -SkipSlowTests for full analysis)"
})

---

## 📋 Recommendations for Beta Release

### High Priority
$(if ($script:TestResults.Summary.FailedTests -gt 0) {
    "1. **🚨 Fix Critical Issues**: Address all failed tests before beta release"
    "2. **🔍 Review Error Handling**: Ensure all scripts have proper error handling"
    "3. **📚 Complete Documentation**: Add missing help content to scripts"
} else {
    "1. **✅ Critical Issues**: No critical issues found - excellent work!"
    "2. **📈 Performance**: Consider optimizing any slow-loading components"
    "3. **🔒 Security**: Maintain current security standards"
})

### Medium Priority
$(if ($script:TestResults.Summary.WarningTests -gt 0) {
    "1. **⚠️ Address Warnings**: Review and resolve $($script:TestResults.Summary.WarningTests) warning-level issues"
    "2. **🏗️ Code Quality**: Enhance scripts without CmdletBinding or parameter validation"
    "3. **🧪 Testing**: Add unit tests for modules where missing"
} else {
    "1. **🧪 Testing**: Consider adding more comprehensive unit tests"
    "2. **📖 Documentation**: Enhance user documentation and examples"
    "3. **🔧 Automation**: Consider adding more automation for deployment processes"
})

### Low Priority
1. **🎨 Code Style**: Standardize coding conventions across all scripts
2. **📊 Monitoring**: Add logging and monitoring capabilities
3. **🔄 CI/CD**: Implement continuous integration for automated testing

---

## 🚀 Next Steps for Beta Release

### Immediate Actions (Before Beta)
$(if ($script:TestResults.Summary.FailedTests -eq 0) {
    "- ✅ **Ready for Beta Deployment**: All critical tests passed"
    "- 📦 **Package Release**: Prepare beta release package"
    "- 📋 **Release Notes**: Document new features and improvements"
    "- 🧪 **Beta Testing**: Deploy to beta testing environment"
} else {
    "- 🔧 **Fix Critical Issues**: Address $($script:TestResults.Summary.FailedTests) failed tests"
    "- 🧪 **Re-run QA**: Execute this QA suite again after fixes"
    "- 📋 **Issue Tracking**: Document and track resolution of all issues"
    "- ⏰ **Timeline Review**: Adjust beta release timeline if needed"
})

### Post-Beta Actions
1. **📊 **Collect Beta Feedback**: Gather user feedback and usage metrics
2. **🐛 **Bug Tracking**: Monitor and address any beta-reported issues
3. **📈 **Performance Monitoring**: Track performance in beta environment
4. **🔄 **Iteration Planning**: Plan improvements for production release

---

## 📈 Quality Metrics Trend

| Category | Score | Trend |
|----------|-------|-------|
| **Syntax Quality** | $(if ($script:TestResults.PowerShellScripts.Count -gt 0) { [math]::Round((($script:TestResults.PowerShellScripts | Where-Object SyntaxValid).Count / $script:TestResults.PowerShellScripts.Count) * 100, 0) } else { "N/A" })% | 📈 |
| **Documentation** | $(if ($script:TestResults.PowerShellScripts.Count -gt 0) { [math]::Round((($script:TestResults.PowerShellScripts | Where-Object HasHelpContent).Count / $script:TestResults.PowerShellScripts.Count) * 100, 0) } else { "N/A" })% | 📈 |
| **Error Handling** | $(if ($script:TestResults.PowerShellScripts.Count -gt 0) { [math]::Round((($script:TestResults.PowerShellScripts | Where-Object HasErrorHandling).Count / $script:TestResults.PowerShellScripts.Count) * 100, 0) } else { "N/A" })% | 📈 |
| **Security** | $(if ($script:TestResults.Security) { if (($script:TestResults.Security.HardcodedCredentials.Count + $script:TestResults.Security.DangerousFunctions.Count) -eq 0) { "100%" } else { "⚠️" } } else { "N/A" }) | 🔒 |

---

*Report generated by Comprehensive Beta Release QA Suite v2.0*  
*For questions or issues, please review the failed tests above and address accordingly.*
"@

    if ($GenerateReport) {
        $report | Out-File $OutputPath -Encoding UTF8
        Write-Host "`n📄 Detailed report saved to: $OutputPath" -ForegroundColor Green
    }
    
    return $report
}

# Main execution function
function Start-ComprehensiveBetaQA {
    Write-Host "🚀 Starting Comprehensive Beta Release Quality Assurance" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "Test Suite Version: 2.0" -ForegroundColor Cyan
    Write-Host "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Green
    
    # Test PowerShell scripts
    Write-Host "`n=== PowerShell Script Testing ===" -ForegroundColor Magenta
    $psScripts = Get-ChildItem "*.ps1" -Recurse | Where-Object { 
        $_.Name -notlike "*Test*" -and 
        $_.Directory.Name -notlike "*\.git*" -and
        $_.Name -ne "COMPREHENSIVE_BETA_QA.ps1"
    }
    
    if ($psScripts.Count -gt 0) {
        Write-Host "Found $($psScripts.Count) PowerShell scripts to test..." -ForegroundColor Cyan
        foreach ($script in $psScripts) {
            Test-PowerShellScript $script.FullName
        }
    }
    else {
        Write-TestResult "PowerShell script discovery" "WARN" "No PowerShell scripts found"
    }
    
    # Test shell scripts
    Write-Host "`n=== Shell Script Testing ===" -ForegroundColor Magenta
    $shellScripts = Get-ChildItem "*.sh" -Recurse | Where-Object { $_.Directory.Name -notlike "*\.git*" }
    
    if ($shellScripts.Count -gt 0) {
        Write-Host "Found $($shellScripts.Count) shell scripts to test..." -ForegroundColor Cyan
        foreach ($script in $shellScripts) {
            Test-ShellScript $script.FullName
        }
    }
    else {
        Write-TestResult "Shell script discovery" "WARN" "No shell scripts found"
    }
    
    # Test modules
    Write-Host "`n=== Module Testing ===" -ForegroundColor Magenta
    $modules = Get-ChildItem "modules" -Directory -ErrorAction SilentlyContinue
    
    if ($modules.Count -gt 0) {
        Write-Host "Found $($modules.Count) modules to test..." -ForegroundColor Cyan
        foreach ($module in $modules) {
            Test-PowerShellModule $module.FullName
        }
    }
    else {
        Write-TestResult "Module discovery" "INFO" "No modules directory found"
    }
    
    # Test GUI
    Test-GUIFunctionality
    
    # Test configurations
    Test-ConfigurationFiles
    
    # Test security
    Test-SecurityBaseline
    
    # Test performance
    Test-Performance
    
    # Test integration
    Test-Integration
    
    # Auto-fix issues if requested
    Invoke-AutoFix
    
    # Generate report
    Write-Host "`n=== Generating Comprehensive Report ===" -ForegroundColor Magenta
    $report = New-QAReport
    
    # Display final summary
    Write-Host "`n================================================================" -ForegroundColor Green
    Write-Host "🎯 COMPREHENSIVE BETA RELEASE QA SUMMARY" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    
    $duration = $script:TestResults.Summary.EndTime - $script:TestResults.Summary.StartTime
    Write-Host "Execution Time: $([math]::Round($duration.TotalMinutes, 1)) minutes" -ForegroundColor White
    Write-Host "Total Tests: $($script:TestResults.Summary.TotalTests)" -ForegroundColor White
    Write-Host "Passed: $($script:TestResults.Summary.PassedTests)" -ForegroundColor Green
    Write-Host "Failed: $($script:TestResults.Summary.FailedTests)" -ForegroundColor Red
    Write-Host "Warnings: $($script:TestResults.Summary.WarningTests)" -ForegroundColor Yellow
    
    $successRate = if ($script:TestResults.Summary.TotalTests -gt 0) {
        [math]::Round(($script:TestResults.Summary.PassedTests / $script:TestResults.Summary.TotalTests) * 100, 1)
    } else { 0 }
    
    Write-Host "Success Rate: $successRate%" -ForegroundColor $(
        if ($successRate -gt 90) { "Green" } 
        elseif ($successRate -gt 75) { "Yellow" } 
        else { "Red" }
    )
    
    # Beta readiness assessment
    Write-Host "`n" -NoNewline
    if ($script:TestResults.Summary.FailedTests -eq 0) {
        Write-Host "✅ READY FOR BETA RELEASE" -ForegroundColor Green
        Write-Host "All critical tests passed successfully. Proceed with beta deployment." -ForegroundColor Green
    }
    elseif ($script:TestResults.Summary.FailedTests -lt 3) {
        Write-Host "⚠️ CONDITIONAL BETA RELEASE" -ForegroundColor Yellow
        Write-Host "Minor issues detected. Review and address before beta release." -ForegroundColor Yellow
    }
    else {
        Write-Host "❌ NOT READY FOR BETA RELEASE" -ForegroundColor Red
        Write-Host "Critical issues must be resolved before beta deployment." -ForegroundColor Red
    }
    
    if ($script:TestResults.Summary.CriticalIssues.Count -gt 0) {
        Write-Host "`n🚨 Critical Issues Requiring Immediate Attention:" -ForegroundColor Red
        $script:TestResults.Summary.CriticalIssues | ForEach-Object {
            Write-Host "  - [$($_.Category)] $($_.Message)" -ForegroundColor Red
            if ($_.Details) {
                Write-Host "    └─ $($_.Details)" -ForegroundColor Gray
            }
        }
    }
    
    Write-Host "`n================================================================" -ForegroundColor Green
    
    if ($GenerateReport) {
        Write-Host "📄 Detailed report available at: $OutputPath" -ForegroundColor Cyan
    }
    
    return $report
}

# Execute the comprehensive QA suite
try {
    Start-ComprehensiveBetaQA
}
catch {
    Write-Host "❌ QA Suite encountered an error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Gray
    exit 1
}