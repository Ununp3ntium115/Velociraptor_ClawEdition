#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Automated script to fork the entire Velociraptor ecosystem and update artifact references

.DESCRIPTION
    This script automates the process of:
    1. Forking all identified GitHub repositories used by Velociraptor artifacts
    2. Updating artifact files to reference the forked repositories
    3. Creating a self-contained ecosystem for Velociraptor deployment

.PARAMETER TargetOrganization
    The GitHub organization where repositories should be forked

.PARAMETER GitHubToken
    GitHub Personal Access Token with repo and org permissions

.PARAMETER UpdateArtifacts
    Switch to update artifact files with new repository references

.PARAMETER DryRun
    Perform a dry run without making actual changes

.EXAMPLE
    .\Fork-VelociraptorEcosystem.ps1 -TargetOrganization "YourOrg" -GitHubToken $env:GITHUB_TOKEN -UpdateArtifacts

.NOTES
    Author: Velociraptor Setup Scripts Team
    Requires: GitHub CLI (gh) or PowerShell GitHub module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TargetOrganization,

    [Parameter(Mandatory)]
    [string]$GitHubToken,

    [switch]$UpdateArtifacts,

    [switch]$DryRun
)

# Repository mapping for forking
$RepositoriesToFork = @{
    # Core Velociraptor
    "Velocidx/velociraptor" = @{
        NewName = "velociraptor"
        Priority = 1
        Description = "Main Velociraptor DFIR platform"
    }
    "Velocidx/Tools" = @{
        NewName = "velociraptor-tools"
        Priority = 1
        Description = "Velociraptor additional tools"
    }

    # Event Log Analysis
    "Yamato-Security/hayabusa" = @{
        NewName = "hayabusa"
        Priority = 2
        Description = "Windows event log timeline generator"
    }
    "Yamato-Security/takajo" = @{
        NewName = "takajo"
        Priority = 2
        Description = "Hayabusa companion tool"
    }
    "WithSecureLabs/chainsaw" = @{
        NewName = "chainsaw"
        Priority = 2
        Description = "Event log analysis tool"
    }
    "yarox24/EvtxHussar" = @{
        NewName = "evtxhussar"
        Priority = 2
        Description = "EVTX log parser"
    }
    "wagga40/Zircolite" = @{
        NewName = "zircolite"
        Priority = 2
        Description = "SIGMA rule detection engine"
    }
    "sans-blue-team/DeepBlueCLI" = @{
        NewName = "deepbluecli"
        Priority = 2
        Description = "PowerShell event log analysis"
    }

    # Malware Analysis
    "mandiant/capa" = @{
        NewName = "capa"
        Priority = 2
        Description = "Malware capability detection"
    }
    "VirusTotal/yara" = @{
        NewName = "yara"
        Priority = 2
        Description = "Malware pattern matching"
    }
    "horsicq/DIE-engine" = @{
        NewName = "die-engine"
        Priority = 3
        Description = "File type detection"
    }
    "volatilityfoundation/volatility" = @{
        NewName = "volatility"
        Priority = 2
        Description = "Memory analysis framework"
    }
    "target/strelka" = @{
        NewName = "strelka"
        Priority = 3
        Description = "File scanning platform"
    }

    # Persistence Detection
    "last-byte/PersistenceSniper" = @{
        NewName = "persistencesniper"
        Priority = 2
        Description = "Windows persistence detection"
    }
    "joeavanzato/Trawler" = @{
        NewName = "trawler"
        Priority = 2
        Description = "PowerShell persistence hunter"
    }
    "0xe7/WonkaVision" = @{
        NewName = "wonkavision"
        Priority = 3
        Description = "Process monitoring tool"
    }

    # macOS Tools
    "jamf/aftermath" = @{
        NewName = "aftermath"
        Priority = 2
        Description = "macOS incident response"
    }
    "objective-see/KnockKnock" = @{
        NewName = "knockknock"
        Priority = 3
        Description = "macOS persistence detection"
    }
    "mandiant/macos-UnifiedLogs" = @{
        NewName = "macos-unifiedlogs"
        Priority = 3
        Description = "macOS log analysis"
    }

    # Linux Tools
    "M00NLIG7/ChopChopGo" = @{
        NewName = "chopchopgo"
        Priority = 3
        Description = "Linux log analysis"
    }
    "RCarras/linforce" = @{
        NewName = "linforce"
        Priority = 3
        Description = "Linux brute force detection"
    }
    "FSecureLABS/LinuxCatScale" = @{
        NewName = "linuxcatscale"
        Priority = 3
        Description = "Linux collection script"
    }

    # Detection & Rules
    "magicsword-io/LOLDrivers" = @{
        NewName = "loldrivers"
        Priority = 2
        Description = "Malicious driver detection"
    }
    "SigmaHQ/sigma" = @{
        NewName = "sigma"
        Priority = 2
        Description = "Detection rule format"
    }
    "Neo23x0/signature-base" = @{
        NewName = "signature-base"
        Priority = 2
        Description = "YARA rule collection"
    }

    # Threat Intelligence
    "dfir-iris/iris-web" = @{
        NewName = "iris-web"
        Priority = 3
        Description = "Incident response platform"
    }
    "zeronetworks/rpcfirewall" = @{
        NewName = "rpcfirewall"
        Priority = 3
        Description = "RPC monitoring"
    }

    # Utility Tools
    "mattifestation/TCGLogTools" = @{
        NewName = "tcglogtools"
        Priority = 3
        Description = "TPM log analysis"
    }
    "Cybereason/Invoke-WMILM" = @{
        NewName = "invoke-wmilm"
        Priority = 3
        Description = "WMI persistence testing"
    }

    # Community Contributions
    "4ltern4te/velociraptor-contrib" = @{
        NewName = "velociraptor-contrib"
        Priority = 2
        Description = "Community contributions"
    }
    "svch0stz/velociraptor-detections" = @{
        NewName = "velociraptor-detections"
        Priority = 2
        Description = "Detection artifacts"
    }
    "mgreen27/DetectRaptor" = @{
        NewName = "detectraptor"
        Priority = 2
        Description = "Detection framework"
    }
    "mgreen27/velociraptor-docs" = @{
        NewName = "velociraptor-docs"
        Priority = 2
        Description = "Community documentation"
    }

    # Forensics Tools
    "jklepsercyber/defender-detectionhistory-parser" = @{
        NewName = "defender-detectionhistory-parser"
        Priority = 3
        Description = "Windows Defender analysis"
    }
    "volexity/threat-intel" = @{
        NewName = "threat-intel"
        Priority = 3
        Description = "Threat intelligence tools"
    }
    "NextronSystems/gimphash" = @{
        NewName = "gimphash"
        Priority = 3
        Description = "File hashing utility"
    }
}

# Artifact file mappings for URL updates
$ArtifactUrlMappings = @{
    "github.com/Velocidx/velociraptor" = "github.com/$TargetOrganization/velociraptor"
    "github.com/Velocidx/Tools" = "github.com/$TargetOrganization/velociraptor-tools"
    "github.com/Yamato-Security/hayabusa" = "github.com/$TargetOrganization/hayabusa"
    "github.com/Yamato-Security/takajo" = "github.com/$TargetOrganization/takajo"
    "github.com/WithSecureLabs/chainsaw" = "github.com/$TargetOrganization/chainsaw"
    "github.com/yarox24/EvtxHussar" = "github.com/$TargetOrganization/evtxhussar"
    "github.com/wagga40/Zircolite" = "github.com/$TargetOrganization/zircolite"
    "github.com/sans-blue-team/DeepBlueCLI" = "github.com/$TargetOrganization/deepbluecli"
    "github.com/mandiant/capa" = "github.com/$TargetOrganization/capa"
    "github.com/VirusTotal/yara" = "github.com/$TargetOrganization/yara"
    "github.com/horsicq/DIE-engine" = "github.com/$TargetOrganization/die-engine"
    "github.com/volatilityfoundation/volatility" = "github.com/$TargetOrganization/volatility"
    "github.com/target/strelka" = "github.com/$TargetOrganization/strelka"
    "github.com/last-byte/PersistenceSniper" = "github.com/$TargetOrganization/persistencesniper"
    "github.com/joeavanzato/Trawler" = "github.com/$TargetOrganization/trawler"
    "github.com/0xe7/WonkaVision" = "github.com/$TargetOrganization/wonkavision"
    "github.com/jamf/aftermath" = "github.com/$TargetOrganization/aftermath"
    "github.com/objective-see/KnockKnock" = "github.com/$TargetOrganization/knockknock"
    "github.com/mandiant/macos-UnifiedLogs" = "github.com/$TargetOrganization/macos-unifiedlogs"
    "github.com/M00NLIG7/ChopChopGo" = "github.com/$TargetOrganization/chopchopgo"
    "github.com/RCarras/linforce" = "github.com/$TargetOrganization/linforce"
    "github.com/FSecureLABS/LinuxCatScale" = "github.com/$TargetOrganization/linuxcatscale"
    "github.com/magicsword-io/LOLDrivers" = "github.com/$TargetOrganization/loldrivers"
    "github.com/SigmaHQ/sigma" = "github.com/$TargetOrganization/sigma"
    "github.com/Neo23x0/signature-base" = "github.com/$TargetOrganization/signature-base"
    "github.com/dfir-iris/iris-web" = "github.com/$TargetOrganization/iris-web"
    "github.com/zeronetworks/rpcfirewall" = "github.com/$TargetOrganization/rpcfirewall"
    "github.com/mattifestation/TCGLogTools" = "github.com/$TargetOrganization/tcglogtools"
    "github.com/Cybereason/Invoke-WMILM" = "github.com/$TargetOrganization/invoke-wmilm"
    "github.com/4ltern4te/velociraptor-contrib" = "github.com/$TargetOrganization/velociraptor-contrib"
    "github.com/svch0stz/velociraptor-detections" = "github.com/$TargetOrganization/velociraptor-detections"
    "github.com/mgreen27/DetectRaptor" = "github.com/$TargetOrganization/detectraptor"
    "github.com/mgreen27/velociraptor-docs" = "github.com/$TargetOrganization/velociraptor-docs"
    "github.com/jklepsercyber/defender-detectionhistory-parser" = "github.com/$TargetOrganization/defender-detectionhistory-parser"
    "github.com/volexity/threat-intel" = "github.com/$TargetOrganization/threat-intel"
    "github.com/NextronSystems/gimphash" = "github.com/$TargetOrganization/gimphash"
}

function Write-Status {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-GitHubCLI {
    try {
        $null = Get-Command gh -ErrorAction Stop
        $authStatus = gh auth status 2>&1
        if ($authStatus -match "Logged in") {
            Write-Status "GitHub CLI is authenticated and ready" "SUCCESS"
            return $true
        } else {
            Write-Status "GitHub CLI is not authenticated. Please run 'gh auth login'" "ERROR"
            return $false
        }
    } catch {
        Write-Status "GitHub CLI (gh) is not installed. Please install it first." "ERROR"
        return $false
    }
}

function Copy-Repository {
    param(
        [string]$SourceRepo,
        [string]$NewName,
        [string]$Description
    )

    Write-Status "Forking $SourceRepo to $TargetOrganization/$NewName"

    if ($DryRun) {
        Write-Status "[DRY RUN] Would fork $SourceRepo to $TargetOrganization/$NewName" "WARNING"
        return $true
    }

    try {
        # Fork the repository
        $forkResult = gh repo fork $SourceRepo --org $TargetOrganization --remote=false 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Status "Successfully forked $SourceRepo" "SUCCESS"

            # Update repository description if different from default name
            if ($NewName -ne $SourceRepo.Split('/')[1]) {
                gh repo edit "$TargetOrganization/$($SourceRepo.Split('/')[1])" --description $Description
            }

            return $true
        } else {
            Write-Status "Failed to fork $SourceRepo`: $forkResult" "ERROR"
            return $false
        }
    } catch {
        Write-Status "Error forking $SourceRepo`: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Update-ArtifactFiles {
    param([hashtable]$UrlMappings)

    Write-Status "Updating artifact files with new repository references"

    # Find all artifact files
    $artifactFiles = Get-ChildItem -Path "." -Filter "*.yaml" -Recurse | Where-Object {
        $_.FullName -match "artifacts" -or $_.FullName -match "exchange"
    }

    $updatedFiles = 0
    $totalReplacements = 0

    foreach ($file in $artifactFiles) {
        $content = Get-Content $file.FullName -Raw
        $originalContent = $content
        $fileReplacements = 0

        foreach ($oldUrl in $UrlMappings.Keys) {
            $newUrl = $UrlMappings[$oldUrl]
            if ($content -match [regex]::Escape($oldUrl)) {
                $content = $content -replace [regex]::Escape($oldUrl), $newUrl
                $fileReplacements++
                $totalReplacements++
            }
        }

        if ($fileReplacements -gt 0) {
            if (-not $DryRun) {
                Set-Content -Path $file.FullName -Value $content -NoNewline
            }
            Write-Status "Updated $($file.Name) with $fileReplacements URL replacements" "SUCCESS"
            $updatedFiles++
        }
    }

    Write-Status "Updated $updatedFiles files with $totalReplacements total URL replacements" "SUCCESS"
}

function New-ToolMirrorScript {
    $scriptContent = @'
#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Mirror external tools to internal hosting

.DESCRIPTION
    This script downloads and mirrors all external tools referenced in artifacts
    to create a self-contained deployment environment.
#>

# External tool URLs that need to be mirrored
$ExternalTools = @{
    "Sysinternals" = @{
        BaseUrl = "https://live.sysinternals.com/tools/"
        Tools = @("psshutdown64.exe", "psexec.exe", "procdump.exe")
    }
    "NirSoft" = @{
        BaseUrl = "https://www.nirsoft.net/utils/"
        Tools = @("lastactivityview.zip")
    }
    "EricZimmerman" = @{
        BaseUrl = "https://download.mikestammer.com/net6/"
        Tools = @("LECmd.zip", "JLECmd.zip")
    }
    "ESET" = @{
        BaseUrl = "https://download.eset.com/com/eset/tools/diagnosis/log_collector/latest/"
        Tools = @("esetlogcollector.exe")
    }
    "CIS" = @{
        BaseUrl = "https://workbench.cisecurity.org/api/vendor/v1/cis-cat/lite/"
        Tools = @("latest")
    }
    "FTKImager" = @{
        BaseUrl = "https://ad-zip.s3.amazonaws.com/"
        Tools = @("FTKImager.3.1.1_win32.zip")
    }
}

function Copy-ExternalTools {
    param([string]$MirrorDirectory = "./tools-mirror")

    New-Item -ItemType Directory -Path $MirrorDirectory -Force

    foreach ($category in $ExternalTools.Keys) {
        $categoryPath = Join-Path $MirrorDirectory $category
        New-Item -ItemType Directory -Path $categoryPath -Force

        foreach ($tool in $ExternalTools[$category].Tools) {
            $url = $ExternalTools[$category].BaseUrl + $tool
            $destination = Join-Path $categoryPath $tool

            Write-Information "Downloading $tool from $category..." -InformationAction Continue
            try {
                Invoke-WebRequest -Uri $url -OutFile $destination
                Write-Host "Successfully downloaded $tool" -ForegroundColor Green
            } catch {
                Write-Host "Failed to download $tool`: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

# Run the mirroring process
Mirror-ExternalTools
'@

    Set-Content -Path "scripts/Mirror-ExternalTools.ps1" -Value $scriptContent
    Write-Status "Created tool mirroring script at scripts/Mirror-ExternalTools.ps1" "SUCCESS"
}

# Main execution
function Main {
    Write-Status "Starting Velociraptor Ecosystem Forking Process"
    Write-Status "Target Organization: $TargetOrganization"
    Write-Status "Dry Run Mode: $DryRun"

    # Verify prerequisites
    if (-not (Test-GitHubCLI)) {
        exit 1
    }

    # Sort repositories by priority
    $sortedRepos = $RepositoriesToFork.GetEnumerator() | Sort-Object { $_.Value.Priority }

    $successCount = 0
    $failCount = 0

    # Fork repositories
    Write-Status "Forking $($sortedRepos.Count) repositories..."

    foreach ($repo in $sortedRepos) {
        $sourceRepo = $repo.Key
        $repoInfo = $repo.Value

        if (Fork-Repository -SourceRepo $sourceRepo -NewName $repoInfo.NewName -Description $repoInfo.Description) {
            $successCount++
        } else {
            $failCount++
        }

        # Add delay to avoid rate limiting
        Start-Sleep -Seconds 2
    }

    Write-Status "Forking completed: $successCount successful, $failCount failed"

    # Update artifact files if requested
    if ($UpdateArtifacts) {
        Update-ArtifactFiles -UrlMappings $ArtifactUrlMappings
    }

    # Create tool mirroring script
    New-ToolMirrorScript

    Write-Status "Velociraptor Ecosystem Forking Process Completed!" "SUCCESS"
    Write-Status "Next steps:"
    Write-Status "1. Review forked repositories in your organization"
    Write-Status "2. Run scripts/Mirror-ExternalTools.ps1 to mirror external tools"
    Write-Status "3. Test artifact functionality with new references"
    Write-Status "4. Set up automated sync with upstream repositories"
}

# Execute main function
Main