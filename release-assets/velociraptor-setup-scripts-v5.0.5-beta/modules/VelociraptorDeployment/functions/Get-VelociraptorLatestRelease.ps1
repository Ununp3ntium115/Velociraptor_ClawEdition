function Get-VelociraptorLatestRelease {
    <#
    .SYNOPSIS
        Retrieves information about the latest Velociraptor release from GitHub.

    .DESCRIPTION
        Queries the GitHub API to get information about the latest Velociraptor release,
        including download URLs for different platforms and architectures.

    .PARAMETER Platform
        The target platform (Windows, Linux, Darwin). Defaults to Windows.

    .PARAMETER Architecture
        The target architecture (amd64, arm64). Defaults to amd64.

    .PARAMETER IncludePrerelease
        Include pre-release versions in the search.

    .PARAMETER Version
        Get information for a specific version instead of latest.

    .EXAMPLE
        Get-VelociraptorLatestRelease
        # Gets latest Windows AMD64 release

    .EXAMPLE
        Get-VelociraptorLatestRelease -Platform Linux -Architecture arm64

    .EXAMPLE
        Get-VelociraptorLatestRelease -Version "0.7.0"

    .OUTPUTS
        PSCustomObject with release information including download URL, version, and metadata.

    .NOTES
        This function replaces the legacy Latest-WindowsAsset function with enhanced capabilities.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [ValidateSet('Windows', 'Linux', 'Darwin')]
        [string]$Platform = 'Windows',
        
        [Parameter()]
        [ValidateSet('amd64', 'arm64')]
        [string]$Architecture = 'amd64',
        
        [Parameter()]
        [switch]$IncludePrerelease,
        
        [Parameter()]
        [string]$Version
    )
    
    try {
        Write-VelociraptorLog "Querying GitHub for Velociraptor release information..." -Level Debug
        
        # Determine API endpoint
        if ($Version) {
            $apiUrl = "https://api.github.com/repos/Velocidex/velociraptor/releases/tags/v$Version"
            Write-VelociraptorLog "Fetching specific version: $Version" -Level Debug
        } else {
            if ($IncludePrerelease) {
                $apiUrl = "https://api.github.com/repos/Velocidex/velociraptor/releases"
            } else {
                $apiUrl = "https://api.github.com/repos/Velocidex/velociraptor/releases/latest"
            }
            Write-VelociraptorLog "Fetching latest release information" -Level Debug
        }
        
        # Set up web request headers with PowerShell 7+ optimizations
        $headers = @{
            'User-Agent' = 'VelociraptorDeployment-PowerShell-Module/1.0'
            'Accept' = 'application/vnd.github.v3+json'
        }
        
        # Add compression and connection optimization for PowerShell 7+
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $headers['Accept-Encoding'] = 'gzip, deflate'
            $requestParams = @{
                Uri = $apiUrl
                Headers = $headers
                ErrorAction = 'Stop'
                TimeoutSec = 30
                MaximumRetryCount = 3
                RetryIntervalSec = 2
            }
        } else {
            # PowerShell 5.1 fallback
            $requestParams = @{
                Uri = $apiUrl
                Headers = $headers
                ErrorAction = 'Stop'
                TimeoutSec = 30
            }
        }
        
        # Make API request with optimized parameters
        $response = Invoke-RestMethod @requestParams
        
        # Handle multiple releases (for prerelease scenario)
        if ($IncludePrerelease -and -not $Version) {
            $release = $response | Where-Object { -not $_.draft } | Select-Object -First 1
        } else {
            $release = $response
        }
        
        if (-not $release) {
            throw "No suitable release found"
        }
        
        # Build asset filter pattern
        $platformMap = @{
            'Windows' = 'windows'
            'Linux' = 'linux'
            'Darwin' = 'darwin'
        }
        
        $platformName = $platformMap[$Platform]
        $assetPattern = "*$platformName-$Architecture*"
        
        # Find matching asset with platform-specific filtering
        Write-VelociraptorLog "Searching for asset with pattern: $assetPattern" -Level Debug
        
        # Platform-specific asset filtering
        $candidateAssets = $release.assets | Where-Object { 
            $_.name -like $assetPattern -and
            $_.name -notlike "*.sig" -and
            $_.name -notlike "*.sha256"
        }
        
        Write-VelociraptorLog "Found $($candidateAssets.Count) candidate assets matching pattern" -Level Debug
        foreach ($candidate in $candidateAssets) {
            Write-VelociraptorLog "  - $($candidate.name)" -Level Debug
        }
        
        # Apply platform-specific filtering
        switch ($Platform) {
            'Windows' {
                $asset = $candidateAssets | Where-Object { 
                    $_.name -like "*.exe" -or $_.name -like "*.zip" 
                } | Select-Object -First 1
            }
            'Linux' {
                # For Linux, prefer glibc over musl variant if both exist
                $asset = $candidateAssets | Where-Object { 
                    $_.name -notlike "*-musl*" -and
                    $_.name -notlike "*.exe" -and
                    $_.name -notlike "*.zip"
                } | Select-Object -First 1
                
                # Fallback to musl if glibc not found
                if (-not $asset) {
                    $asset = $candidateAssets | Where-Object { 
                        $_.name -like "*-musl*" -and
                        $_.name -notlike "*.exe" -and
                        $_.name -notlike "*.zip"
                    } | Select-Object -First 1
                }
            }
            'Darwin' {
                # macOS binaries have no extension
                $asset = $candidateAssets | Where-Object { 
                    $_.name -notlike "*.exe" -and
                    $_.name -notlike "*.zip" -and
                    $_.name -notlike "*-musl*"
                } | Select-Object -First 1
            }
        }
        
        if (-not $asset) {
            $availableAssets = ($release.assets | ForEach-Object { $_.name }) -join ', '
            $errorMsg = "Could not locate a $Platform $Architecture asset in the release. Available assets: $availableAssets"
            Write-VelociraptorLog $errorMsg -Level Error
            throw $errorMsg
        }
        
        Write-VelociraptorLog "Selected asset: $($asset.name)" -Level Debug
        
        # Create result object
        $result = [PSCustomObject]@{
            Version = $release.tag_name.TrimStart('v')
            TagName = $release.tag_name
            Name = $release.name
            PublishedAt = [DateTime]$release.published_at
            IsPrerelease = $release.prerelease
            IsDraft = $release.draft
            Asset = [PSCustomObject]@{
                Name = $asset.name
                Size = $asset.size
                DownloadUrl = $asset.browser_download_url
                ContentType = $asset.content_type
            }
            Platform = $Platform
            Architecture = $Architecture
            ReleaseUrl = $release.html_url
            ApiUrl = $release.url
        }
        
        Write-VelociraptorLog "Found release: $($result.Version) for $Platform $Architecture" -Level Success
        Write-VelociraptorLog "Asset: $($result.Asset.Name) ($([math]::Round($result.Asset.Size / 1MB, 2)) MB)" -Level Debug
        
        return $result
    }
    catch {
        $errorMessage = "Failed to retrieve Velociraptor release information: $($_.Exception.Message)"
        Write-VelociraptorLog $errorMessage -Level Error
        throw $errorMessage
    }
}