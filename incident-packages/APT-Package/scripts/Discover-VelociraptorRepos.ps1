#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Discover additional Velociraptor-related GitHub repositories

.DESCRIPTION
    This script uses GitHub's search API to find all Velociraptor-related repositories
    that might not be in the standard artifact exchange, including custom implementations,
    forks, and community projects.

.PARAMETER GitHubToken
    GitHub Personal Access Token for API access

.PARAMETER OutputFile
    File to save discovered repositories

.EXAMPLE
    .\Discover-VelociraptorRepos.ps1 -GitHubToken $env:GITHUB_TOKEN -OutputFile "discovered_repos.json"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$GitHubToken,

    [string]$OutputFile = "discovered_velociraptor_repos.json"
)

# GitHub API search queries to find Velociraptor-related repositories
$SearchQueries = @(
    "velociraptor in:name,description,readme",
    "velociraptor artifact in:name,description,readme",
    "velociraptor vql in:name,description,readme",
    "velociraptor dfir in:name,description,readme",
    "velociraptor forensics in:name,description,readme",
    "velociraptor incident response in:name,description,readme",
    "velociraptor hunting in:name,description,readme",
    "velociraptor detection in:name,description,readme",
    "velociraptor collection in:name,description,readme",
    "vql query language in:name,description,readme",
    "filename:*.yaml velociraptor",
    "filename:artifact.yaml",
    "extension:yaml Windows.EventLogs",
    "extension:yaml Linux.Collection",
    "extension:yaml MacOS.Applications"
)

# Headers for GitHub API
$Headers = @{
    "Authorization" = "token $GitHubToken"
    "Accept" = "application/vnd.github.v3+json"
    "User-Agent" = "Velociraptor-Repo-Discovery"
}

function Find-GitHubRepositories {
    param([string]$Query)

    $encodedQuery = [System.Web.HttpUtility]::UrlEncode($Query)
    $url = "https://api.github.com/search/repositories?q=$encodedQuery&sort=stars&order=desc&per_page=100"

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $Headers -Method Get
        return $response.items
    } catch {
        Write-Warning "Failed to search for: $Query - $($_.Exception.Message)"
        return @()
    }
}

function Get-RepositoryDetails {
    param([string]$FullName)

    $url = "https://api.github.com/repos/$FullName"

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $Headers -Method Get
        return $response
    } catch {
        Write-Warning "Failed to get details for: $FullName - $($_.Exception.Message)"
        return $null
    }
}

function Find-RepositoryContents {
    param([string]$FullName, [string]$SearchTerm)

    $encodedQuery = [System.Web.HttpUtility]::UrlEncode("$SearchTerm repo:$FullName")
    $url = "https://api.github.com/search/code?q=$encodedQuery"

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $Headers -Method Get
        return $response.items
    } catch {
        Write-Warning "Failed to search contents in: $FullName - $($_.Exception.Message)"
        return @()
    }
}

Write-Host "🔍 Discovering Velociraptor-related GitHub repositories..." -ForegroundColor Cyan

$allRepositories = @{}
$totalFound = 0

foreach ($query in $SearchQueries) {
    Write-Host "Searching: $query" -ForegroundColor Yellow

    $repos = Search-GitHubRepositories -Query $query

    foreach ($repo in $repos) {
        if (-not $allRepositories.ContainsKey($repo.full_name)) {
            $allRepositories[$repo.full_name] = @{
                Name = $repo.name
                FullName = $repo.full_name
                Description = $repo.description
                Url = $repo.html_url
                CloneUrl = $repo.clone_url
                Stars = $repo.stargazers_count
                Forks = $repo.forks_count
                Language = $repo.language
                CreatedAt = $repo.created_at
                UpdatedAt = $repo.updated_at
                Topics = $repo.topics
                License = $repo.license.name
                SearchQuery = $query
                HasArtifacts = $false
                HasVQL = $false
                HasTools = $false
                ArtifactCount = 0
                VQLCount = 0
                ToolCount = 0
            }
            $totalFound++
        }
    }

    # Rate limiting
    Start-Sleep -Seconds 2
}

Write-Host "📊 Found $totalFound unique repositories. Analyzing contents..." -ForegroundColor Green

# Analyze repository contents for Velociraptor artifacts and tools
$analyzed = 0
foreach ($repoName in $allRepositories.Keys) {
    $analyzed++
    Write-Progress -Activity "Analyzing repositories" -Status "Processing $repoName" -PercentComplete (($analyzed / $allRepositories.Count) * 100)

    $repo = $allRepositories[$repoName]

    # Search for YAML artifacts
    $yamlFiles = Search-RepositoryContents -FullName $repoName -SearchTerm "extension:yaml"
    $artifactFiles = $yamlFiles | Where-Object { $_.name -match "\.yaml$" -and ($_.path -match "artifact" -or $_.name -match "Windows\.|Linux\.|MacOS\.") }

    if ($artifactFiles) {
        $repo.HasArtifacts = $true
        $repo.ArtifactCount = $artifactFiles.Count
    }

    # Search for VQL content
    $vqlContent = Search-RepositoryContents -FullName $repoName -SearchTerm "SELECT FROM"
    if ($vqlContent) {
        $repo.HasVQL = $true
        $repo.VQLCount = $vqlContent.Count
    }

    # Search for tools
    $toolContent = Search-RepositoryContents -FullName $repoName -SearchTerm "tools:"
    if ($toolContent) {
        $repo.HasTools = $true
        $repo.ToolCount = $toolContent.Count
    }

    # Rate limiting for content searches
    Start-Sleep -Seconds 1
}

# Categorize repositories
$categorizedRepos = @{
    CoreVelociraptor = @()
    ArtifactCollections = @()
    CustomTools = @()
    DetectionRules = @()
    GUIImplementations = @()
    DeploymentScripts = @()
    Documentation = @()
    Forks = @()
    Other = @()
}

foreach ($repoName in $allRepositories.Keys) {
    $repo = $allRepositories[$repoName]

    # Categorize based on name, description, and content
    if ($repo.FullName -match "velocidx|velociraptor/velociraptor") {
        $categorizedRepos.CoreVelociraptor += $repo
    }
    elseif ($repo.HasArtifacts -or $repo.Name -match "artifact|exchange") {
        $categorizedRepos.ArtifactCollections += $repo
    }
    elseif ($repo.HasTools -or $repo.Name -match "tool|util") {
        $categorizedRepos.CustomTools += $repo
    }
    elseif ($repo.Name -match "detection|rule|sigma|yara") {
        $categorizedRepos.DetectionRules += $repo
    }
    elseif ($repo.Name -match "gui|interface|web|dashboard") {
        $categorizedRepos.GUIImplementations += $repo
    }
    elseif ($repo.Name -match "deploy|setup|install|script") {
        $categorizedRepos.DeploymentScripts += $repo
    }
    elseif ($repo.Name -match "doc|guide|tutorial|example") {
        $categorizedRepos.Documentation += $repo
    }
    elseif ($repo.FullName -match "/.*-.*/" -and $repo.Forks -eq 0) {
        $categorizedRepos.Forks += $repo
    }
    else {
        $categorizedRepos.Other += $repo
    }
}

# Generate comprehensive report
$report = @{
    DiscoveryDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalRepositories = $totalFound
    SearchQueries = $SearchQueries
    Categories = @{}
    HighValueRepositories = @()
    RecommendedForking = @()
    AllRepositories = $allRepositories
}

foreach ($category in $categorizedRepos.Keys) {
    $repos = $categorizedRepos[$category]
    $report.Categories[$category] = @{
        Count = $repos.Count
        Repositories = $repos | Sort-Object Stars -Descending
    }
}

# Identify high-value repositories
$report.HighValueRepositories = $allRepositories.Values | Where-Object {
    $_.Stars -gt 10 -or $_.HasArtifacts -or $_.HasTools -or $_.Name -match "velociraptor"
} | Sort-Object Stars -Descending

# Recommend repositories for forking
$report.RecommendedForking = $allRepositories.Values | Where-Object {
    ($_.HasArtifacts -and $_.ArtifactCount -gt 5) -or
    ($_.HasTools -and $_.ToolCount -gt 3) -or
    ($_.Stars -gt 50) -or
    ($_.Name -match "velociraptor" -and $_.Stars -gt 5)
} | Sort-Object @{Expression={$_.Stars + $_.ArtifactCount + $_.ToolCount}; Descending=$true}

# Save results
$report | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputFile

# Display summary
Write-Host "`n🎯 Discovery Complete!" -ForegroundColor Green
Write-Host "📊 Total Repositories Found: $totalFound" -ForegroundColor Cyan
Write-Host "📁 Results saved to: $OutputFile" -ForegroundColor Yellow

Write-Host "`n📋 Category Breakdown:" -ForegroundColor Cyan
foreach ($category in $categorizedRepos.Keys) {
    $count = $categorizedRepos[$category].Count
    if ($count -gt 0) {
        Write-Host "  $category`: $count repositories" -ForegroundColor White
    }
}

Write-Host "`n⭐ High-Value Repositories (Stars > 10 or has artifacts/tools):" -ForegroundColor Green
$report.HighValueRepositories | Select-Object -First 10 | ForEach-Object {
    Write-Host "  $($_.FullName) - ⭐$($_.Stars) - 📦$($_.ArtifactCount) artifacts - 🔧$($_.ToolCount) tools" -ForegroundColor White
}

Write-Host "`n🍴 Recommended for Forking:" -ForegroundColor Yellow
$report.RecommendedForking | Select-Object -First 15 | ForEach-Object {
    Write-Host "  $($_.FullName) - ⭐$($_.Stars) - 📦$($_.ArtifactCount) artifacts - 🔧$($_.ToolCount) tools" -ForegroundColor White
}

Write-Host "`n📄 Detailed report saved to: $OutputFile" -ForegroundColor Cyan
Write-Host "🔄 Run this script periodically to discover new repositories!" -ForegroundColor Green