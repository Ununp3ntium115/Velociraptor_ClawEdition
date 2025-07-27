#
# PYRO Tool Integration Module
# 🔥 Critical DFIR tool integration for PYRO platform
# Version: 6.0.0-ignition
#

# Module initialization
Write-Verbose "🔥 Loading PYRO Tool Integration Module..."

# Global PYRO tool paths and registry
$script:PyroTools = @{
    Hayabusa = @{
        Path = $null
        Version = $null
        Installed = $false
        InstallPath = "C:\PYRO\tools\hayabusa"
        Repository = "https://github.com/Yamato-Security/hayabusa"
    }
    UAC = @{
        Path = $null
        Version = $null
        Installed = $false
        InstallPath = "C:\PYRO\tools\uac"
        Repository = "https://github.com/tclahr/uac"
    }
    Chainsaw = @{
        Path = $null
        Version = $null
        Installed = $false
        InstallPath = "C:\PYRO\tools\chainsaw"
        Repository = "https://github.com/countercept/chainsaw"
    }
    YARA = @{
        Path = $null
        Version = $null
        Installed = $false
        InstallPath = "C:\PYRO\tools\yara"
        Repository = "https://github.com/VirusTotal/yara"
    }
    Sigma = @{
        Path = $null
        Version = $null
        Installed = $false
        InstallPath = "C:\PYRO\tools\sigma"
        Repository = "https://github.com/SigmaHQ/sigma"
    }
    Volatility = @{
        Path = $null
        Version = $null
        Installed = $false
        InstallPath = "C:\PYRO\tools\volatility"
        Repository = "https://github.com/volatilityfoundation/volatility3"
    }
    CAPA = @{
        Path = $null
        Version = $null
        Installed = $false
        InstallPath = "C:\PYRO\tools\capa"
        Repository = "https://github.com/mandiant/capa"
    }
}

# ===== TIER 1 CRITICAL TOOLS =====

function Install-PyroHayabusa {
    <#
    .SYNOPSIS
        🔥 Install Hayabusa Windows Event Timeline Generator for PYRO
    .DESCRIPTION
        Downloads and installs Yamato Security's Hayabusa tool for fast Windows event log timeline generation
    .PARAMETER InstallPath
        Custom installation path (default: C:\PYRO\tools\hayabusa)
    .PARAMETER Version
        Specific version to install (default: latest)
    #>
    [CmdletBinding()]
    param(
        [string]$InstallPath = $script:PyroTools.Hayabusa.InstallPath,
        [string]$Version = "latest"
    )
    
    Write-Host "🔥 Installing Hayabusa for PYRO..." -ForegroundColor Red
    
    try {
        # Create installation directory
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        
        # Get latest release from GitHub API
        Write-Host "   Fetching Hayabusa release information..." -ForegroundColor Yellow
        $releaseUrl = "https://api.github.com/repos/Yamato-Security/hayabusa/releases/latest"
        $release = Invoke-RestMethod -Uri $releaseUrl -UseBasicParsing
        
        # Find Windows binary
        $asset = $release.assets | Where-Object { $_.name -like "*windows*" -or $_.name -like "*win*" } | Select-Object -First 1
        if (-not $asset) {
            throw "Windows binary not found in Hayabusa releases"
        }
        
        # Download binary
        Write-Host "   Downloading Hayabusa from: $($asset.browser_download_url)" -ForegroundColor Yellow
        $zipPath = Join-Path $env:TEMP "hayabusa_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing
        
        # Extract binary
        Write-Host "   Extracting Hayabusa to: $InstallPath" -ForegroundColor Yellow
        Expand-Archive -Path $zipPath -DestinationPath $InstallPath -Force
        
        # Find executable
        $hayabusaExe = Get-ChildItem -Path $InstallPath -Name "hayabusa*.exe" -Recurse | Select-Object -First 1
        if ($hayabusaExe) {
            $fullPath = Get-ChildItem -Path $InstallPath -Name "hayabusa*.exe" -Recurse | Select-Object -First 1 -ExpandProperty FullName
            $script:PyroTools.Hayabusa.Path = $fullPath
            $script:PyroTools.Hayabusa.Version = $release.tag_name
            $script:PyroTools.Hayabusa.Installed = $true
            
            Write-Host "✅ Hayabusa integrated successfully!" -ForegroundColor Green
            Write-Host "   Path: $fullPath" -ForegroundColor Cyan
            Write-Host "   Version: $($release.tag_name)" -ForegroundColor Cyan
            
            # Cleanup
            Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
            
            return $fullPath
        } else {
            throw "Hayabusa executable not found after extraction"
        }
    }
    catch {
        Write-Error "❌ Failed to install Hayabusa: $($_.Exception.Message)"
        throw
    }
}

function Install-PyroUAC {
    <#
    .SYNOPSIS
        🔥 Install UAC (Unix-like Artifacts Collector) for PYRO
    .DESCRIPTION
        Downloads and installs UAC for comprehensive Unix/Linux artifact collection
    .PARAMETER InstallPath
        Custom installation path (default: C:\PYRO\tools\uac)
    #>
    [CmdletBinding()]
    param(
        [string]$InstallPath = $script:PyroTools.UAC.InstallPath
    )
    
    Write-Host "🔥 Installing UAC for PYRO..." -ForegroundColor Red
    
    try {
        # Check if git is available
        $gitCmd = Get-Command git -ErrorAction SilentlyContinue
        if (-not $gitCmd) {
            throw "Git is required to install UAC. Please install Git first."
        }
        
        # Clone UAC repository
        Write-Host "   Cloning UAC repository..." -ForegroundColor Yellow
        $repoUrl = "https://github.com/tclahr/uac.git"
        
        # Remove existing directory if it exists
        if (Test-Path $InstallPath) {
            Remove-Item $InstallPath -Recurse -Force
        }
        
        & git clone $repoUrl $InstallPath
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to clone UAC repository"
        }
        
        # Verify installation
        $uacScript = Join-Path $InstallPath "uac"
        if (Test-Path $uacScript) {
            $script:PyroTools.UAC.Path = $uacScript
            $script:PyroTools.UAC.Version = "latest"
            $script:PyroTools.UAC.Installed = $true
            
            # Make script executable on Unix-like systems
            if ($IsLinux -or $IsMacOS) {
                chmod +x $uacScript
            }
            
            Write-Host "✅ UAC integrated successfully!" -ForegroundColor Green
            Write-Host "   Path: $uacScript" -ForegroundColor Cyan
            
            return $uacScript
        } else {
            throw "UAC script not found after cloning"
        }
    }
    catch {
        Write-Error "❌ Failed to install UAC: $($_.Exception.Message)"
        throw
    }
}

function Install-PyroChainsaw {
    <#
    .SYNOPSIS
        🔥 Install Chainsaw Windows Event Log Hunter for PYRO
    .DESCRIPTION
        Downloads and installs Chainsaw for rapid Windows event log hunting and analysis
    .PARAMETER InstallPath
        Custom installation path (default: C:\PYRO\tools\chainsaw)
    .PARAMETER Version
        Specific version to install (default: latest)
    #>
    [CmdletBinding()]
    param(
        [string]$InstallPath = $script:PyroTools.Chainsaw.InstallPath,
        [string]$Version = "latest"
    )
    
    Write-Host "🔥 Installing Chainsaw for PYRO..." -ForegroundColor Red
    
    try {
        # Create installation directory
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        
        # Get latest release from GitHub API
        Write-Host "   Fetching Chainsaw release information..." -ForegroundColor Yellow
        $releaseUrl = "https://api.github.com/repos/countercept/chainsaw/releases/latest"
        $release = Invoke-RestMethod -Uri $releaseUrl -UseBasicParsing
        
        # Find Windows binary
        $asset = $release.assets | Where-Object { $_.name -like "*windows*" -or $_.name -like "*win*" } | Select-Object -First 1
        if (-not $asset) {
            throw "Windows binary not found in Chainsaw releases"
        }
        
        # Download binary
        Write-Host "   Downloading Chainsaw from: $($asset.browser_download_url)" -ForegroundColor Yellow
        $zipPath = Join-Path $env:TEMP "chainsaw_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing
        
        # Extract binary
        Write-Host "   Extracting Chainsaw to: $InstallPath" -ForegroundColor Yellow
        Expand-Archive -Path $zipPath -DestinationPath $InstallPath -Force
        
        # Find executable
        $chainsawExe = Get-ChildItem -Path $InstallPath -Name "chainsaw*.exe" -Recurse | Select-Object -First 1
        if ($chainsawExe) {
            $fullPath = Get-ChildItem -Path $InstallPath -Name "chainsaw*.exe" -Recurse | Select-Object -First 1 -ExpandProperty FullName
            $script:PyroTools.Chainsaw.Path = $fullPath
            $script:PyroTools.Chainsaw.Version = $release.tag_name
            $script:PyroTools.Chainsaw.Installed = $true
            
            Write-Host "✅ Chainsaw integrated successfully!" -ForegroundColor Green
            Write-Host "   Path: $fullPath" -ForegroundColor Cyan
            Write-Host "   Version: $($release.tag_name)" -ForegroundColor Cyan
            
            # Cleanup
            Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
            
            return $fullPath
        } else {
            throw "Chainsaw executable not found after extraction"
        }
    }
    catch {
        Write-Error "❌ Failed to install Chainsaw: $($_.Exception.Message)"
        throw
    }
}

function Install-PyroYARA {
    <#
    .SYNOPSIS
        🔥 Install YARA Pattern Matching Engine for PYRO
    .DESCRIPTION
        Downloads and installs YARA for malware pattern matching and detection
    .PARAMETER InstallPath
        Custom installation path (default: C:\PYRO\tools\yara)
    .PARAMETER Version
        Specific version to install (default: latest)
    #>
    [CmdletBinding()]
    param(
        [string]$InstallPath = $script:PyroTools.YARA.InstallPath,
        [string]$Version = "latest"
    )
    
    Write-Host "🔥 Installing YARA for PYRO..." -ForegroundColor Red
    
    try {
        # Create installation directory
        New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
        
        # Get latest release from GitHub API
        Write-Host "   Fetching YARA release information..." -ForegroundColor Yellow
        $releaseUrl = "https://api.github.com/repos/VirusTotal/yara/releases/latest"
        $release = Invoke-RestMethod -Uri $releaseUrl -UseBasicParsing
        
        # Find Windows binary
        $asset = $release.assets | Where-Object { $_.name -like "*win64*" -or ($_.name -like "*windows*" -and $_.name -like "*64*") } | Select-Object -First 1
        if (-not $asset) {
            throw "Windows binary not found in YARA releases"
        }
        
        # Download binary
        Write-Host "   Downloading YARA from: $($asset.browser_download_url)" -ForegroundColor Yellow
        $zipPath = Join-Path $env:TEMP "yara_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -UseBasicParsing
        
        # Extract binary
        Write-Host "   Extracting YARA to: $InstallPath" -ForegroundColor Yellow
        Expand-Archive -Path $zipPath -DestinationPath $InstallPath -Force
        
        # Find executable (prefer yara64.exe, fallback to yara.exe)
        $yaraExe = Get-ChildItem -Path $InstallPath -Name "yara64.exe" -Recurse | Select-Object -First 1
        if (-not $yaraExe) {
            $yaraExe = Get-ChildItem -Path $InstallPath -Name "yara.exe" -Recurse | Select-Object -First 1
        }
        
        if ($yaraExe) {
            $fullPath = Get-ChildItem -Path $InstallPath -Name $yaraExe.Name -Recurse | Select-Object -First 1 -ExpandProperty FullName
            $script:PyroTools.YARA.Path = $fullPath
            $script:PyroTools.YARA.Version = $release.tag_name
            $script:PyroTools.YARA.Installed = $true
            
            Write-Host "✅ YARA integrated successfully!" -ForegroundColor Green
            Write-Host "   Path: $fullPath" -ForegroundColor Cyan
            Write-Host "   Version: $($release.tag_name)" -ForegroundColor Cyan
            
            # Cleanup
            Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
            
            return $fullPath
        } else {
            throw "YARA executable not found after extraction"
        }
    }
    catch {
        Write-Error "❌ Failed to install YARA: $($_.Exception.Message)"
        throw
    }
}

function Install-PyroSigma {
    <#
    .SYNOPSIS
        🔥 Install Sigma SIEM Detection Rules for PYRO
    .DESCRIPTION
        Downloads and installs Sigma rules and tools for SIEM detection
    .PARAMETER InstallPath
        Custom installation path (default: C:\PYRO\tools\sigma)
    #>
    [CmdletBinding()]
    param(
        [string]$InstallPath = $script:PyroTools.Sigma.InstallPath
    )
    
    Write-Host "🔥 Installing Sigma for PYRO..." -ForegroundColor Red
    
    try {
        # Check if git is available
        $gitCmd = Get-Command git -ErrorAction SilentlyContinue
        if (-not $gitCmd) {
            throw "Git is required to install Sigma. Please install Git first."
        }
        
        # Clone Sigma repository
        Write-Host "   Cloning Sigma repository..." -ForegroundColor Yellow
        $repoUrl = "https://github.com/SigmaHQ/sigma.git"
        
        # Remove existing directory if it exists
        if (Test-Path $InstallPath) {
            Remove-Item $InstallPath -Recurse -Force
        }
        
        & git clone $repoUrl $InstallPath
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to clone Sigma repository"
        }
        
        # Check if Python is available for sigma-cli
        $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
        if (-not $pythonCmd) {
            $pythonCmd = Get-Command python3 -ErrorAction SilentlyContinue
        }
        
        if ($pythonCmd) {
            try {
                Write-Host "   Installing sigma-cli Python package..." -ForegroundColor Yellow
                & $pythonCmd.Source -m pip install sigma-cli sigmatools --quiet
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "   ✅ sigma-cli installed successfully" -ForegroundColor Green
                }
            }
            catch {
                Write-Warning "Failed to install sigma-cli: $($_.Exception.Message)"
            }
        } else {
            Write-Warning "Python not found. Sigma rules installed but sigma-cli not available."
        }
        
        # Verify installation
        $sigmaRules = Join-Path $InstallPath "rules"
        if (Test-Path $sigmaRules) {
            $script:PyroTools.Sigma.Path = $InstallPath
            $script:PyroTools.Sigma.Version = "latest"
            $script:PyroTools.Sigma.Installed = $true
            
            Write-Host "✅ Sigma integrated successfully!" -ForegroundColor Green
            Write-Host "   Path: $InstallPath" -ForegroundColor Cyan
            Write-Host "   Rules: $sigmaRules" -ForegroundColor Cyan
            
            return $InstallPath
        } else {
            throw "Sigma rules directory not found after cloning"
        }
    }
    catch {
        Write-Error "❌ Failed to install Sigma: $($_.Exception.Message)"
        throw
    }
}

# ===== TOOL USAGE FUNCTIONS =====

function Invoke-PyroHayabusaAnalysis {
    <#
    .SYNOPSIS
        🔥 Run Hayabusa Windows event log timeline analysis
    .PARAMETER EventLogPath
        Path to Windows event log file or directory
    .PARAMETER OutputPath
        Output file path for CSV timeline
    .PARAMETER Rules
        Rule set to use (default: all)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EventLogPath,
        [Parameter(Mandatory)]
        [string]$OutputPath,
        [string]$Rules = "all"
    )
    
    if (-not $script:PyroTools.Hayabusa.Installed) {
        Write-Host "🔥 Hayabusa not installed, installing now..." -ForegroundColor Yellow
        Install-PyroHayabusa
    }
    
    Write-Host "🔥 Running Hayabusa analysis..." -ForegroundColor Red
    Write-Host "   Input: $EventLogPath" -ForegroundColor Cyan
    Write-Host "   Output: $OutputPath" -ForegroundColor Cyan
    
    try {
        $args = @("csv-timeline", "-d", $EventLogPath, "-o", $OutputPath)
        if ($Rules -ne "all") {
            $args += @("--rules", $Rules)
        }
        
        & $script:PyroTools.Hayabusa.Path $args
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Hayabusa analysis completed successfully!" -ForegroundColor Green
            return $OutputPath
        } else {
            throw "Hayabusa analysis failed with exit code: $LASTEXITCODE"
        }
    }
    catch {
        Write-Error "❌ Hayabusa analysis failed: $($_.Exception.Message)"
        throw
    }
}

function Invoke-PyroChainsawHunt {
    <#
    .SYNOPSIS
        🔥 Run Chainsaw Windows event log hunting
    .PARAMETER EventLogPath
        Path to Windows event log file or directory
    .PARAMETER OutputPath
        Output file path for results
    .PARAMETER Rules
        Rule set to use (default: sigma)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EventLogPath,
        [Parameter(Mandatory)]
        [string]$OutputPath,
        [string]$Rules = "sigma"
    )
    
    if (-not $script:PyroTools.Chainsaw.Installed) {
        Write-Host "🔥 Chainsaw not installed, installing now..." -ForegroundColor Yellow
        Install-PyroChainsaw
    }
    
    Write-Host "🔥 Running Chainsaw hunt..." -ForegroundColor Red
    Write-Host "   Input: $EventLogPath" -ForegroundColor Cyan
    Write-Host "   Output: $OutputPath" -ForegroundColor Cyan
    
    try {
        $args = @("hunt", $EventLogPath, "--output", $OutputPath)
        if ($Rules -ne "sigma") {
            $args += @("--rules", $Rules)
        }
        
        & $script:PyroTools.Chainsaw.Path $args
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Chainsaw hunt completed successfully!" -ForegroundColor Green
            return $OutputPath
        } else {
            throw "Chainsaw hunt failed with exit code: $LASTEXITCODE"
        }
    }
    catch {
        Write-Error "❌ Chainsaw hunt failed: $($_.Exception.Message)"
        throw
    }
}

function Invoke-PyroYARAScan {
    <#
    .SYNOPSIS
        🔥 Run YARA pattern matching scan
    .PARAMETER RulesPath
        Path to YARA rules file
    .PARAMETER TargetPath
        Path to target file or directory to scan
    .PARAMETER OutputPath
        Output file path for results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RulesPath,
        [Parameter(Mandatory)]
        [string]$TargetPath,
        [string]$OutputPath
    )
    
    if (-not $script:PyroTools.YARA.Installed) {
        Write-Host "🔥 YARA not installed, installing now..." -ForegroundColor Yellow
        Install-PyroYARA
    }
    
    Write-Host "🔥 Running YARA scan..." -ForegroundColor Red
    Write-Host "   Rules: $RulesPath" -ForegroundColor Cyan
    Write-Host "   Target: $TargetPath" -ForegroundColor Cyan
    
    try {
        $args = @($RulesPath, $TargetPath)
        
        if ($OutputPath) {
            $result = & $script:PyroTools.YARA.Path $args
            $result | Out-File $OutputPath -Encoding UTF8
            Write-Host "   Output: $OutputPath" -ForegroundColor Cyan
        } else {
            & $script:PyroTools.YARA.Path $args
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ YARA scan completed successfully!" -ForegroundColor Green
            return $OutputPath
        } else {
            throw "YARA scan failed with exit code: $LASTEXITCODE"
        }
    }
    catch {
        Write-Error "❌ YARA scan failed: $($_.Exception.Message)"
        throw
    }
}

# ===== TOOLSUITE MANAGEMENT =====

function Install-PyroToolsuite {
    <#
    .SYNOPSIS
        🔥 Install complete PYRO DFIR toolsuite
    .DESCRIPTION
        Installs all critical DFIR tools for PYRO platform
    .PARAMETER ToolsPath
        Base directory for all tools (default: C:\PYRO\tools)
    .PARAMETER ToolList
        Array of tools to install (default: all Tier 1 tools)
    #>
    [CmdletBinding()]
    param(
        [string]$ToolsPath = "C:\PYRO\tools",
        [string[]]$ToolList = @("Hayabusa", "UAC", "Chainsaw", "YARA", "Sigma")
    )
    
    Write-Host "🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥" -ForegroundColor Red
    Write-Host "🔥                                                   🔥" -ForegroundColor Red
    Write-Host "🔥        PYRO DFIR TOOLSUITE INSTALLATION          🔥" -ForegroundColor Red
    Write-Host "🔥           Setting Fire to DFIR Frameworks        🔥" -ForegroundColor Red
    Write-Host "🔥                                                   🔥" -ForegroundColor Red
    Write-Host "🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥" -ForegroundColor Red
    Write-Host ""
    
    # Create tools directory
    New-Item -ItemType Directory -Path $ToolsPath -Force | Out-Null
    Write-Host "📁 Tools directory: $ToolsPath" -ForegroundColor Cyan
    Write-Host ""
    
    $installResults = @{}
    $totalTools = $ToolList.Count
    $currentTool = 0
    
    foreach ($tool in $ToolList) {
        $currentTool++
        Write-Host "[$currentTool/$totalTools] Installing $tool..." -ForegroundColor Yellow
        
        try {
            switch ($tool) {
                "Hayabusa" { 
                    $script:PyroTools.Hayabusa.InstallPath = Join-Path $ToolsPath "hayabusa"
                    Install-PyroHayabusa 
                    $installResults[$tool] = "✅ SUCCESS"
                }
                "UAC" { 
                    $script:PyroTools.UAC.InstallPath = Join-Path $ToolsPath "uac"
                    Install-PyroUAC 
                    $installResults[$tool] = "✅ SUCCESS"
                }
                "Chainsaw" { 
                    $script:PyroTools.Chainsaw.InstallPath = Join-Path $ToolsPath "chainsaw"
                    Install-PyroChainsaw 
                    $installResults[$tool] = "✅ SUCCESS"
                }
                "YARA" { 
                    $script:PyroTools.YARA.InstallPath = Join-Path $ToolsPath "yara"
                    Install-PyroYARA 
                    $installResults[$tool] = "✅ SUCCESS"
                }
                "Sigma" { 
                    $script:PyroTools.Sigma.InstallPath = Join-Path $ToolsPath "sigma"
                    Install-PyroSigma 
                    $installResults[$tool] = "✅ SUCCESS"
                }
                default { 
                    Write-Warning "Unknown tool: $tool"
                    $installResults[$tool] = "⚠️ UNKNOWN"
                }
            }
        }
        catch {
            Write-Error "❌ Failed to install $tool`: $($_.Exception.Message)"
            $installResults[$tool] = "❌ FAILED"
        }
        
        Write-Host ""
    }
    
    # Installation summary
    Write-Host "🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥" -ForegroundColor Red
    Write-Host "🔥           INSTALLATION SUMMARY                    🔥" -ForegroundColor Red
    Write-Host "🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥" -ForegroundColor Red
    
    foreach ($tool in $installResults.Keys) {
        $status = $installResults[$tool]
        $color = if ($status -like "*SUCCESS*") { "Green" } elseif ($status -like "*FAILED*") { "Red" } else { "Yellow" }
        Write-Host "   $tool`: $status" -ForegroundColor $color
    }
    
    $successCount = ($installResults.Values | Where-Object { $_ -like "*SUCCESS*" }).Count
    $failCount = ($installResults.Values | Where-Object { $_ -like "*FAILED*" }).Count
    
    Write-Host ""
    Write-Host "📊 Results: $successCount successful, $failCount failed" -ForegroundColor Cyan
    
    if ($failCount -eq 0) {
        Write-Host "🔥 PYRO Toolsuite installation COMPLETE!" -ForegroundColor Red
        Write-Host "   All tools ignited and ready for action!" -ForegroundColor Green
    } else {
        Write-Warning "Some tools failed to install. Check error messages above."
    }
    
    return $installResults
}

function Get-PyroToolStatus {
    <#
    .SYNOPSIS
        🔥 Get status of all PYRO tools
    .DESCRIPTION
        Returns current installation and status information for all PYRO tools
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "🔥 PYRO Tool Status:" -ForegroundColor Red
    Write-Host ""
    
    foreach ($toolName in $script:PyroTools.Keys) {
        $tool = $script:PyroTools[$toolName]
        $status = if ($tool.Installed) { "✅ INSTALLED" } else { "❌ NOT INSTALLED" }
        $color = if ($tool.Installed) { "Green" } else { "Red" }
        
        Write-Host "   $toolName`: $status" -ForegroundColor $color
        if ($tool.Installed) {
            Write-Host "     Path: $($tool.Path)" -ForegroundColor Cyan
            Write-Host "     Version: $($tool.Version)" -ForegroundColor Cyan
        }
        Write-Host ""
    }
    
    return $script:PyroTools
}

function Test-PyroToolIntegration {
    <#
    .SYNOPSIS
        🔥 Test PYRO tool integration
    .DESCRIPTION
        Runs basic tests on all installed PYRO tools to verify functionality
    .PARAMETER TestDataPath
        Path to test data directory
    #>
    [CmdletBinding()]
    param(
        [string]$TestDataPath = "C:\PYRO\test-data"
    )
    
    Write-Host "🔥 Testing PYRO Tool Integration..." -ForegroundColor Red
    
    $testResults = @{
        Hayabusa = $false
        UAC = $false
        Chainsaw = $false
        YARA = $false
        Sigma = $false
    }
    
    # Test each tool
    foreach ($toolName in $testResults.Keys) {
        $tool = $script:PyroTools[$toolName]
        Write-Host "🧪 Testing $toolName..." -ForegroundColor Yellow
        
        try {
            if ($tool.Installed -and $tool.Path) {
                # Basic version/help test
                switch ($toolName) {
                    "Hayabusa" { 
                        $result = & $tool.Path --help 2>&1
                        $testResults[$toolName] = ($LASTEXITCODE -eq 0)
                    }
                    "Chainsaw" { 
                        $result = & $tool.Path --help 2>&1
                        $testResults[$toolName] = ($LASTEXITCODE -eq 0)
                    }
                    "YARA" { 
                        $result = & $tool.Path --help 2>&1
                        $testResults[$toolName] = ($LASTEXITCODE -eq 0)
                    }
                    "UAC" { 
                        $testResults[$toolName] = (Test-Path $tool.Path)
                    }
                    "Sigma" { 
                        $rulesPath = Join-Path $tool.Path "rules"
                        $testResults[$toolName] = (Test-Path $rulesPath)
                    }
                }
                
                if ($testResults[$toolName]) {
                    Write-Host "   ✅ $toolName test passed" -ForegroundColor Green
                } else {
                    Write-Host "   ❌ $toolName test failed" -ForegroundColor Red
                }
            } else {
                Write-Host "   ⚠️ $toolName not installed" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "   ❌ $toolName test error: $($_.Exception.Message)" -ForegroundColor Red
            $testResults[$toolName] = $false
        }
    }
    
    # Summary
    $passedTests = ($testResults.Values | Where-Object { $_ -eq $true }).Count
    $totalTests = $testResults.Count
    
    Write-Host ""
    Write-Host "📊 Integration Test Results: $passedTests/$totalTests passed" -ForegroundColor Cyan
    
    if ($passedTests -eq $totalTests) {
        Write-Host "🔥 All PYRO tools integrated successfully!" -ForegroundColor Red
    } else {
        Write-Warning "Some tools failed integration testing. Check installation and dependencies."
    }
    
    return $testResults
}

# Export functions
Export-ModuleMember -Function @(
    'Install-PyroHayabusa',
    'Install-PyroUAC',
    'Install-PyroChainsaw',
    'Install-PyroYARA',
    'Install-PyroSigma',
    'Invoke-PyroHayabusaAnalysis',
    'Invoke-PyroChainsawHunt',
    'Invoke-PyroYARAScan',
    'Install-PyroToolsuite',
    'Get-PyroToolStatus',
    'Test-PyroToolIntegration'
)

# Export variables
Export-ModuleMember -Variable 'PyroTools'

Write-Verbose "🔥 PYRO Tool Integration Module loaded successfully!"