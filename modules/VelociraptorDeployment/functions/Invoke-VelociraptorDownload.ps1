function Invoke-VelociraptorDownload {
    <#
    .SYNOPSIS
        Downloads files with progress tracking and validation for Velociraptor deployments.

    .DESCRIPTION
        Provides secure file download capabilities with progress tracking, resume support,
        hash validation, and comprehensive error handling. Designed specifically for
        downloading Velociraptor binaries and related files.

    .PARAMETER Url
        The URL to download from.

    .PARAMETER DestinationPath
        The local path where the file should be saved.

    .PARAMETER ExpectedHash
        Optional SHA256 hash to validate the downloaded file.

    .PARAMETER MaxRetries
        Maximum number of retry attempts on failure. Default is 3.

    .PARAMETER TimeoutSeconds
        Download timeout in seconds. Default is 300 (5 minutes).

    .PARAMETER ShowProgress
        Display download progress bar.

    .PARAMETER Force
        Overwrite existing files without prompting.

    .EXAMPLE
        Invoke-VelociraptorDownload -Url "https://github.com/..." -DestinationPath "C:\tools\velociraptor.exe"

    .EXAMPLE
        Invoke-VelociraptorDownload -Url $url -DestinationPath $path -ExpectedHash $hash -ShowProgress

    .OUTPUTS
        PSCustomObject with download results including file path, size, and validation status.

    .NOTES
        This function replaces the legacy Download-EXE function with enhanced capabilities.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Url,
        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationPath,
        
        [Parameter()]
        [string]$ExpectedHash,
        
        [Parameter()]
        [ValidateRange(1, 10)]
        [int]$MaxRetries = 3,
        
        [Parameter()]
        [ValidateRange(30, 3600)]
        [int]$TimeoutSeconds = 300,
        
        [Parameter()]
        [switch]$ShowProgress,
        
        [Parameter()]
        [switch]$Force
    )
    
    try {
        Write-VelociraptorLog "Starting download: $($Url.Split('/')[-1])" -Level Info
        
        # Validate destination directory
        $destinationDir = Split-Path $DestinationPath -Parent
        if (-not (Test-Path $destinationDir)) {
            Write-VelociraptorLog "Creating destination directory: $destinationDir" -Level Debug
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }
        
        # Check if file exists and handle accordingly
        if (Test-Path $DestinationPath) {
            if (-not $Force) {
                $choice = Read-Host "File already exists at $DestinationPath. Overwrite? (y/N)"
                if ($choice -notmatch '^[Yy]') {
                    Write-VelociraptorLog "Download cancelled by user" -Level Warning
                    return [PSCustomObject]@{
                        Success = $false
                        FilePath = $DestinationPath
                        Reason = "Cancelled by user"
                    }
                }
            }
            Write-VelociraptorLog "Removing existing file" -Level Debug
            Remove-Item $DestinationPath -Force
        }
        
        # Set up security protocol
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        # Set up web client with proper headers
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add('User-Agent', 'VelociraptorDeployment-PowerShell-Module/1.0')
        $webClient.Timeout = $TimeoutSeconds * 1000
        
        # Set up progress tracking if requested
        if ($ShowProgress) {
            $webClient.add_DownloadProgressChanged({
                param($sender, $e)
                $progressParams = @{
                    Activity = "Downloading $($Url.Split('/')[-1])"
                    Status = "Downloaded $([math]::Round($e.BytesReceived / 1MB, 2)) MB of $([math]::Round($e.TotalBytesToReceive / 1MB, 2)) MB"
                    PercentComplete = $e.ProgressPercentage
                }
                Write-Progress @progressParams
            })
        }
        
        # Attempt download with retries
        $attempt = 1
        $downloadSuccess = $false
        $tempPath = "$DestinationPath.download"
        
        while ($attempt -le $MaxRetries -and -not $downloadSuccess) {
            try {
                Write-VelociraptorLog "Download attempt $attempt of $MaxRetries" -Level Debug
                
                # Perform download
                $webClient.DownloadFile($Url, $tempPath)
                
                # Verify file was downloaded and has content
                if (Test-Path $tempPath) {
                    $fileInfo = Get-Item $tempPath
                    if ($fileInfo.Length -gt 0) {
                        $downloadSuccess = $true
                        Write-VelociraptorLog "Download completed: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -Level Success
                    } else {
                        throw "Downloaded file is empty"
                    }
                } else {
                    throw "Downloaded file not found"
                }
            }
            catch {
                Write-VelociraptorLog "Download attempt $attempt failed: $($_.Exception.Message)" -Level Warning
                
                if (Test-Path $tempPath) {
                    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
                }
                
                if ($attempt -eq $MaxRetries) {
                    throw "Download failed after $MaxRetries attempts: $($_.Exception.Message)"
                }
                
                $attempt++
                Start-Sleep -Seconds (2 * $attempt)  # Exponential backoff
            }
        }
        
        # Clear progress bar
        if ($ShowProgress) {
            Write-Progress -Activity "Download" -Completed
        }
        
        # Validate hash if provided
        if ($ExpectedHash) {
            Write-VelociraptorLog "Validating file hash..." -Level Debug
            $actualHash = (Get-FileHash $tempPath -Algorithm SHA256).Hash
            
            if ($actualHash -ne $ExpectedHash) {
                Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
                throw "Hash validation failed. Expected: $ExpectedHash, Actual: $actualHash"
            }
            
            Write-VelociraptorLog "Hash validation successful" -Level Success
        }
        
        # Move file to final destination
        Move-Item $tempPath $DestinationPath -Force
        
        # Get final file information
        $finalFile = Get-Item $DestinationPath
        
        # Create result object
        $result = [PSCustomObject]@{
            Success = $true
            FilePath = $DestinationPath
            FileName = $finalFile.Name
            SizeBytes = $finalFile.Length
            SizeMB = [math]::Round($finalFile.Length / 1MB, 2)
            DownloadUrl = $Url
            HashValidated = [bool]$ExpectedHash
            Attempts = $attempt
        }
        
        Write-VelociraptorLog "Download completed successfully: $($result.FileName) ($($result.SizeMB) MB)" -Level Success
        return $result
    }
    catch {
        $errorMessage = "Download failed: $($_.Exception.Message)"
        Write-VelociraptorLog $errorMessage -Level Error
        
        # Cleanup on failure
        if (Test-Path "$DestinationPath.download") {
            Remove-Item "$DestinationPath.download" -Force -ErrorAction SilentlyContinue
        }
        
        return [PSCustomObject]@{
            Success = $false
            FilePath = $DestinationPath
            Reason = $_.Exception.Message
            Attempts = $attempt
        }
    }
    finally {
        # Cleanup web client
        if ($webClient) {
            $webClient.Dispose()
        }
        
        # Clear progress bar if it was shown
        if ($ShowProgress) {
            Write-Progress -Activity "Download" -Completed
        }
    }
}