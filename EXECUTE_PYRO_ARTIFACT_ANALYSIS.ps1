#!/usr/bin/env pwsh
<#
.SYNOPSIS
    🔥 PYRO Artifact Pack Analysis Execution Script
    
.DESCRIPTION
    Comprehensive analysis of artifact_pack.zip and artifact_pack_v2.zip files
    to identify all repositories and tools that need to be forked for PYRO independence.
    
    This script will:
    1. Download artifact packs if missing
    2. Extract and analyze all artifacts
    3. Identify GitHub repositories and tools
    4. Generate comprehensive fork plan
    5. Create priority matrix for implementation
    
.PARAMETER ArtifactPacksDirectory
    Directory containing artifact pack zip files
    
.PARAMETER OutputDirectory
    Directory to store analysis results
    
.PARAMETER DownloadPacks
    Download artifact packs if not present
    
.PARAMETER SkipGitHubAPI
    Skip GitHub API enrichment (faster but less detailed)
    
.EXAMPLE
    .\EXECUTE_PYRO_ARTIFACT_ANALYSIS.ps1 -DownloadPacks
    
.EXAMPLE
    .\EXECUTE_PYRO_ARTIFACT_ANALYSIS.ps1 -ArtifactPacksDirectory "C:\artifacts" -OutputDirectory "C:\analysis"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ArtifactPacksDirectory = ".\artifact_packs",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDirectory = ".\pyro_analysis_results",
    
    [Parameter(Mandatory=$false)]
    [switch]$DownloadPacks,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipGitHubAPI,
    
    [Parameter(Mandatory=$false)]
    [switch]$GenerateForkScript
)

# PYRO Analysis Configuration
$PyroConfig = @{
    ArtifactPacks = @(
        @{
            Name = "artifact_pack.zip"
            URL = "https://github.com/Velocidx/velociraptor/releases/latest/download/artifact_pack.zip"
            Description = "Core Velociraptor artifact collection"
        },
        @{
            Name = "artifact_pack_v2.zip"
            URL = "https://github.com/Velocidx/velociraptor/releases/latest/download/artifact_pack_v2.zip"
            Description = "Extended Velociraptor artifact collection"
        }
    )
    
    KnownCriticalTools = @{
        "hayabusa" = "https://github.com/Yamato-Security/hayabusa"
        "uac" = "https://github.com/tclahr/uac"
        "chainsaw" = "https://github.com/countercept/chainsaw"
        "sigma" = "https://github.com/SigmaHQ/sigma"
        "yara" = "https://github.com/VirusTotal/yara"
        "volatility" = "https://github.com/volatilityfoundation/volatility3"
        "plaso" = "https://github.com/log2timeline/plaso"
        "capa" = "https://github.com/mandiant/capa"
        "osquery" = "https://github.com/osquery/osquery"
        "winpmem" = "https://github.com/Velocidx/WinPmem"
        "linpmem" = "https://github.com/Velocidx/Linpmem"
    }
}

function Write-PyroLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success", "Header")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "Info" { "Cyan" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
        "Header" { "Magenta" }
    }
    
    $prefix = switch ($Level) {
        "Header" { "🔥🔥🔥" }
        "Success" { "✅" }
        "Error" { "❌" }
        "Warning" { "⚠️" }
        default { "🔥" }
    }
    
    Write-Host "[$timestamp] $prefix $Message" -ForegroundColor $color
}

function Initialize-PyroEnvironment {
    Write-PyroLog "Initializing PYRO Analysis Environment..." -Level "Header"
    
    # Create directories
    @($ArtifactPacksDirectory, $OutputDirectory) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
            Write-PyroLog "Created directory: $_" -Level "Success"
        }
    }
    
    # Check Python
    try {
        $pythonVersion = python --version 2>&1
        Write-PyroLog "Python available: $pythonVersion" -Level "Success"
    }
    catch {
        Write-PyroLog "Python not found! Please install Python 3.7+" -Level "Error"
        return $false
    }
    
    # Install Python packages
    Write-PyroLog "Installing required Python packages..." -Level "Info"
    $packages = @("pyyaml", "requests", "pathlib")
    foreach ($package in $packages) {
        try {
            pip install $package --quiet --disable-pip-version-check
            Write-PyroLog "Installed: $package" -Level "Success"
        }
        catch {
            Write-PyroLog "Failed to install: $package" -Level "Warning"
        }
    }
    
    return $true
}

function Get-ArtifactPacks {
    Write-PyroLog "Checking artifact packs..." -Level "Info"
    
    $packsFound = 0
    $packsTotal = $PyroConfig.ArtifactPacks.Count
    
    foreach ($pack in $PyroConfig.ArtifactPacks) {
        $packPath = Join-Path $ArtifactPacksDirectory $pack.Name
        
        if (Test-Path $packPath) {
            $packSize = (Get-Item $packPath).Length / 1MB
            Write-PyroLog "Found: $($pack.Name) ($([math]::Round($packSize, 2)) MB)" -Level "Success"
            $packsFound++
        }
        else {
            if ($DownloadPacks) {
                Write-PyroLog "Downloading: $($pack.Name)..." -Level "Info"
                try {
                    $progressPreference = 'SilentlyContinue'
                    Invoke-WebRequest -Uri $pack.URL -OutFile $packPath -UseBasicParsing
                    $packSize = (Get-Item $packPath).Length / 1MB
                    Write-PyroLog "Downloaded: $($pack.Name) ($([math]::Round($packSize, 2)) MB)" -Level "Success"
                    $packsFound++
                }
                catch {
                    Write-PyroLog "Failed to download $($pack.Name): $($_.Exception.Message)" -Level "Error"
                }
            }
            else {
                Write-PyroLog "Missing: $($pack.Name)" -Level "Warning"
                Write-PyroLog "Use -DownloadPacks to download missing files" -Level "Info"
            }
        }
    }
    
    Write-PyroLog "Artifact packs ready: $packsFound/$packsTotal" -Level "Info"
    return $packsFound -gt 0
}

function Invoke-PyroAnalysis {
    Write-PyroLog "Starting PYRO Artifact Pack Analysis..." -Level "Header"
    
    # Create Python execution script
    $pythonScript = @"
import sys
import os
import json
from pathlib import Path

# Add current directory to path
sys.path.append('.')

try:
    from PYRO_ARTIFACT_PACK_ANALYSIS import PyroArtifactPackAnalyzer
    
    def main():
        print("🔥 Initializing PYRO Artifact Pack Analyzer...")
        
        analyzer = PyroArtifactPackAnalyzer(
            artifact_packs_dir='$($ArtifactPacksDirectory.Replace('\', '/'))',
            output_dir='$($OutputDirectory.Replace('\', '/'))'
        )
        
        print("🔍 Starting comprehensive analysis...")
        results = analyzer.analyze_all_packs()
        
        print(f"\\n🔥 PYRO Analysis Results:")
        print(f"   Artifact Packs: {len(results['artifact_packs_analyzed'])}")
        print(f"   Total Artifacts: {results['total_artifacts']}")
        print(f"   Repositories Found: {len(results['repositories_found'])}")
        print(f"   Tools Found: {len(results['tools_found'])}")
        print(f"   Organizations: {len(results['organizations_found'])}")
        
        if results['fork_candidates']:
            print(f"\\n🎯 Fork Priorities:")
            print(f"   Critical: {len(results['fork_candidates']['high_priority'])}")
            print(f"   High: {len(results['fork_candidates']['medium_priority'])}")
            print(f"   Medium: {len(results['fork_candidates']['low_priority'])}")
        
        return results
    
    if __name__ == "__main__":
        results = main()
        
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("Make sure PYRO_ARTIFACT_PACK_ANALYSIS.py is in the current directory")
    sys.exit(1)
except Exception as e:
    print(f"❌ Analysis error: {e}")
    sys.exit(1)
"@
    
    # Save and execute Python script
    $scriptPath = Join-Path $OutputDirectory "run_pyro_analysis.py"
    $pythonScript | Out-File -FilePath $scriptPath -Encoding UTF8
    
    try {
        Write-PyroLog "Executing Python analysis..." -Level "Info"
        python $scriptPath
        Write-PyroLog "Analysis completed successfully!" -Level "Success"
        return $true
    }
    catch {
        Write-PyroLog "Analysis failed: $($_.Exception.Message)" -Level "Error"
        return $false
    }
}

function New-PyroForkScript {
    if (-not $GenerateForkScript) {
        return
    }
    
    Write-PyroLog "Generating PYRO fork automation script..." -Level "Info"
    
    $resultsFile = Join-Path $OutputDirectory "pyro_artifact_pack_analysis.json"
    if (-not (Test-Path $resultsFile)) {
        Write-PyroLog "Analysis results not found. Run analysis first." -Level "Error"
        return
    }
    
    try {
        $results = Get-Content $resultsFile | ConvertFrom-Json
        
        # Generate fork script
        $forkScript = @"
#!/bin/bash
# 🔥 PYRO Automated Repository Forking Script
# Generated from artifact pack analysis

set -e

echo "🔥🔥🔥 PYRO AUTOMATED FORKING SCRIPT 🔥🔥🔥"
echo "Setting fire to DFIR framework dependencies!"
echo ""

# Configuration
PYRO_ORG="PyroOrg"
WORK_DIR="./pyro_forks"
FORK_LOG="./pyro_fork_log.txt"

# Create working directory
mkdir -p `$WORK_DIR
cd `$WORK_DIR

echo "📁 Working directory: `$(pwd)"
echo "📝 Fork log: `$FORK_LOG"
echo ""

# Function to fork and setup repository
fork_repository() {
    local repo_url=`$1
    local repo_name=`$2
    local priority=`$3
    
    echo "🔥 Forking: `$repo_name (Priority: `$priority)"
    echo "`$(date): Starting fork of `$repo_url" >> `$FORK_LOG
    
    # Clone original repository
    if git clone `$repo_url.git pyro-`$repo_name; then
        cd pyro-`$repo_name
        
        # Setup remotes
        git remote rename origin upstream
        git remote add origin https://github.com/`$PYRO_ORG/pyro-`$repo_name.git
        
        # Create PYRO integration branch
        git checkout -b pyro-integration
        
        # Apply basic PYRO branding (placeholder)
        echo "# 🔥 PYRO Integration" > PYRO_INTEGRATION.md
        echo "This repository has been forked for PYRO DFIR platform integration." >> PYRO_INTEGRATION.md
        echo "Original repository: `$repo_url" >> PYRO_INTEGRATION.md
        git add PYRO_INTEGRATION.md
        git commit -m "🔥 Initial PYRO integration setup"
        
        echo "✅ Successfully forked: `$repo_name"
        echo "`$(date): Successfully forked `$repo_name" >> `$FORK_LOG
        
        cd ..
    else
        echo "❌ Failed to fork: `$repo_name"
        echo "`$(date): Failed to fork `$repo_name" >> `$FORK_LOG
    fi
    
    echo ""
}

echo "🎯 Starting high priority repository forks..."
echo ""

"@
        
        # Add high priority repositories
        if ($results.fork_candidates -and $results.fork_candidates.high_priority) {
            foreach ($repo in $results.fork_candidates.high_priority) {
                $repoName = $repo.repository_name
                $repoUrl = $repo.repository_url
                $forkScript += "fork_repository `"$repoUrl`" `"$repoName`" `"HIGH`"`n"
            }
        }
        
        $forkScript += @"

echo "🔥 PYRO forking complete!"
echo "📊 Check `$FORK_LOG for detailed results"
echo ""
echo "Next steps:"
echo "1. Create repositories on GitHub under PyroOrg organization"
echo "2. Push forked repositories: git push -u origin pyro-integration"
echo "3. Apply PYRO branding and integration"
echo "4. Set up CI/CD pipelines"
echo ""
echo "🔥 PYRO: Setting fire to DFIR frameworks! 🔥"
"@
        
        # Save fork script
        $forkScriptPath = Join-Path $OutputDirectory "PYRO_AUTOMATED_FORK.sh"
        $forkScript | Out-File -FilePath $forkScriptPath -Encoding UTF8
        
        # Make executable on Unix systems
        if ($IsLinux -or $IsMacOS) {
            chmod +x $forkScriptPath
        }
        
        Write-PyroLog "Fork script generated: $forkScriptPath" -Level "Success"
        Write-PyroLog "Run this script to automatically fork all high-priority repositories" -Level "Info"
    }
    catch {
        Write-PyroLog "Failed to generate fork script: $($_.Exception.Message)" -Level "Error"
    }
}

function Show-PyroResults {
    Write-PyroLog "PYRO Analysis Results Summary:" -Level "Header"
    
    $resultsFile = Join-Path $OutputDirectory "pyro_artifact_pack_analysis.json"
    if (Test-Path $resultsFile) {
        try {
            $results = Get-Content $resultsFile | ConvertFrom-Json
            
            Write-Host ""
            Write-Host "🔥🔥🔥 PYRO ANALYSIS COMPLETE 🔥🔥🔥" -ForegroundColor Red
            Write-Host "=====================================" -ForegroundColor Red
            Write-Host ""
            Write-Host "📊 ANALYSIS SUMMARY:" -ForegroundColor Yellow
            Write-Host "   Artifact Packs: $($results.artifact_packs_analyzed.Count)" -ForegroundColor Cyan
            Write-Host "   Total Artifacts: $($results.total_artifacts)" -ForegroundColor Cyan
            Write-Host "   Repositories Found: $($results.repositories_found.PSObject.Properties.Count)" -ForegroundColor Cyan
            Write-Host "   Tools Found: $($results.tools_found.PSObject.Properties.Count)" -ForegroundColor Cyan
            Write-Host "   Organizations: $($results.organizations_found.Count)" -ForegroundColor Cyan
            Write-Host ""
            
            if ($results.fork_candidates) {
                Write-Host "🎯 FORK PRIORITIES:" -ForegroundColor Yellow
                Write-Host "   Critical Priority: $($results.fork_candidates.high_priority.Count)" -ForegroundColor Red
                Write-Host "   High Priority: $($results.fork_candidates.medium_priority.Count)" -ForegroundColor Yellow
                Write-Host "   Medium Priority: $($results.fork_candidates.low_priority.Count)" -ForegroundColor Green
                Write-Host ""
                
                Write-Host "🚨 TOP CRITICAL REPOSITORIES TO FORK:" -ForegroundColor Red
                $topRepos = $results.fork_candidates.high_priority | Select-Object -First 5
                foreach ($repo in $topRepos) {
                    Write-Host "   • $($repo.organization)/$($repo.repository_name)" -ForegroundColor White
                    Write-Host "     Priority Score: $($repo.priority_score), Language: $($repo.language)" -ForegroundColor Gray
                }
            }
            
            Write-Host ""
            Write-Host "📁 RESULTS LOCATION:" -ForegroundColor Yellow
            Write-Host "   Analysis Results: $resultsFile" -ForegroundColor Cyan
            Write-Host "   Summary Report: $(Join-Path $OutputDirectory 'PYRO_ANALYSIS_SUMMARY.md')" -ForegroundColor Cyan
            Write-Host "   Fork Plan: $(Join-Path $OutputDirectory 'PYRO_FORK_PLAN.md')" -ForegroundColor Cyan
            
            if ($GenerateForkScript) {
                Write-Host "   Fork Script: $(Join-Path $OutputDirectory 'PYRO_AUTOMATED_FORK.sh')" -ForegroundColor Cyan
            }
            
            Write-Host ""
            Write-Host "🔥 NEXT STEPS:" -ForegroundColor Yellow
            Write-Host "1. Review the fork plan and prioritize repositories" -ForegroundColor White
            Write-Host "2. Set up PyroOrg GitHub organization" -ForegroundColor White
            Write-Host "3. Begin forking critical repositories" -ForegroundColor White
            Write-Host "4. Apply PYRO branding and integration" -ForegroundColor White
            Write-Host "5. Set up CI/CD for forked repositories" -ForegroundColor White
            Write-Host ""
            Write-Host "🔥 PYRO: Where DFIR frameworks go to burn bright! 🔥" -ForegroundColor Red
        }
        catch {
            Write-PyroLog "Failed to display results: $($_.Exception.Message)" -Level "Error"
        }
    }
    else {
        Write-PyroLog "No analysis results found. Run the analysis first." -Level "Warning"
    }
}

# Main execution function
function Main {
    Write-Host ""
    Write-Host "🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥" -ForegroundColor Red
    Write-Host "🔥                                                   🔥" -ForegroundColor Red
    Write-Host "🔥        PYRO ARTIFACT PACK ANALYSIS SYSTEM        🔥" -ForegroundColor Red
    Write-Host "🔥           Setting Fire to DFIR Frameworks        🔥" -ForegroundColor Red
    Write-Host "🔥                                                   🔥" -ForegroundColor Red
    Write-Host "🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥" -ForegroundColor Red
    Write-Host ""
    
    # Initialize environment
    if (-not (Initialize-PyroEnvironment)) {
        Write-PyroLog "Environment initialization failed!" -Level "Error"
        return 1
    }
    
    # Get artifact packs
    if (-not (Get-ArtifactPacks)) {
        Write-PyroLog "No artifact packs available for analysis!" -Level "Error"
        Write-PyroLog "Use -DownloadPacks to download missing artifact packs" -Level "Info"
        return 1
    }
    
    # Run analysis
    if (Invoke-PyroAnalysis) {
        # Generate fork script if requested
        New-PyroForkScript
        
        # Show results
        Show-PyroResults
        
        Write-PyroLog "🔥 PYRO Artifact Pack Analysis Complete!" -Level "Success"
        Write-PyroLog "Review the results and begin forking critical repositories!" -Level "Info"
        return 0
    }
    else {
        Write-PyroLog "Analysis failed. Check the logs above for details." -Level "Error"
        return 1
    }
}

# Execute main function and exit with appropriate code
$exitCode = Main
exit $exitCode