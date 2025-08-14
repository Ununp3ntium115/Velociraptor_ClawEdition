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

        # Set up web request headers
        $headers = @{
            'User-Agent' = 'VelociraptorDeployment-PowerShell-Module/1.0'
            'Accept' = 'application/vnd.github.v3+json'
        }

        # Make API request
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop

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

        # Find matching asset
        $asset = $release.assets | Where-Object {
            $_.name -like $assetPattern -and
            $_.name -like "*.exe" -or
            $_.name -like "*.zip" -or
            $_.name -notlike "*.sig"
        } | Select-Object -First 1

        if (-not $asset) {
            throw "Could not locate a $Platform $Architecture asset in the release"
        }

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