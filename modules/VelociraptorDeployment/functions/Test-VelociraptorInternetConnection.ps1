function Test-VelociraptorInternetConnection {
    <#
    .SYNOPSIS
        Tests internet connectivity for Velociraptor deployment operations.

    .DESCRIPTION
        Verifies internet connectivity by testing connections to GitHub and other
        required endpoints for Velociraptor downloads and updates.

    .PARAMETER TestEndpoints
        Array of endpoints to test. Default includes GitHub API and download servers.

    .PARAMETER TimeoutSeconds
        Connection timeout in seconds. Default is 10 seconds.

    .PARAMETER RequireAll
        Require all endpoints to be reachable. Default is false (any endpoint success).

    .PARAMETER Quiet
        Suppress verbose output and only return boolean result.

    .EXAMPLE
        Test-VelociraptorInternetConnection
        # Tests default endpoints

    .EXAMPLE
        Test-VelociraptorInternetConnection -TestEndpoints @("github.com", "google.com") -RequireAll

    .OUTPUTS
        System.Boolean or PSCustomObject with detailed results.

    .NOTES
        Uses multiple fallback methods for compatibility with different PowerShell versions.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$TestEndpoints = @(
            'api.github.com',
            'github.com',
            'objects.githubusercontent.com'
        ),
        
        [Parameter()]
        [ValidateRange(1, 120)]
        [int]$TimeoutSeconds = 10,
        
        [Parameter()]
        [switch]$RequireAll,
        
        [Parameter()]
        [switch]$Quiet
    )
    
    try {
        if (-not $Quiet) {
            Write-VelociraptorLog "Testing internet connectivity..." -Level Info
        }
        
        $results = @()
        $successCount = 0
        
        foreach ($endpoint in $TestEndpoints) {
            $endpointResult = [PSCustomObject]@{
                Endpoint = $endpoint
                Success = $false
                Method = ""
                ResponseTime = 0
                Error = ""
            }
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            try {
                # Method 1: Test-NetConnection (Windows 8/Server 2012+)
                if (Get-Command Test-NetConnection -ErrorAction SilentlyContinue) {
                    try {
                        $testResult = Test-NetConnection -ComputerName $endpoint -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction Stop
                        if ($testResult) {
                            $endpointResult.Success = $true
                            $endpointResult.Method = "Test-NetConnection"
                        }
                    }
                    catch {
                        # Continue to next method
                    }
                }
                
                # Method 2: System.Net.WebClient (fallback)
                if (-not $endpointResult.Success) {
                    try {
                        $webClient = New-Object System.Net.WebClient
                        $webClient.Headers.Add('User-Agent', 'VelociraptorDeployment-ConnectivityTest/1.0')
                        $webClient.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
                        
                        # Set timeout
                        $webClient.Timeout = $TimeoutSeconds * 1000
                        
                        # Test HTTPS connection
                        $testUrl = "https://$endpoint"
                        $response = $webClient.DownloadString($testUrl)
                        
                        $endpointResult.Success = $true
                        $endpointResult.Method = "WebClient"
                    }
                    catch {
                        # Check if it's just a 404 or similar (connection successful)
                        if ($_.Exception.Message -match "404|403|401") {
                            $endpointResult.Success = $true
                            $endpointResult.Method = "WebClient (HTTP Error OK)"
                        } else {
                            $endpointResult.Error = $_.Exception.Message
                        }
                    }
                    finally {
                        if ($webClient) {
                            $webClient.Dispose()
                        }
                    }
                }
                
                # Method 3: System.Net.Sockets.TcpClient (final fallback)
                if (-not $endpointResult.Success) {
                    try {
                        $tcpClient = New-Object System.Net.Sockets.TcpClient
                        $asyncResult = $tcpClient.BeginConnect($endpoint, 443, $null, $null)
                        $waitResult = $asyncResult.AsyncWaitHandle.WaitOne($TimeoutSeconds * 1000, $false)
                        
                        if ($waitResult -and $tcpClient.Connected) {
                            $endpointResult.Success = $true
                            $endpointResult.Method = "TcpClient"
                        } else {
                            $endpointResult.Error = "Connection timeout or failed"
                        }
                    }
                    catch {
                        $endpointResult.Error = $_.Exception.Message
                    }
                    finally {
                        if ($tcpClient) {
                            $tcpClient.Close()
                            $tcpClient.Dispose()
                        }
                    }
                }
            }
            catch {
                $endpointResult.Error = $_.Exception.Message
            }
            finally {
                $stopwatch.Stop()
                $endpointResult.ResponseTime = $stopwatch.ElapsedMilliseconds
            }
            
            $results += $endpointResult
            
            if ($endpointResult.Success) {
                $successCount++
                if (-not $Quiet) {
                    Write-VelociraptorLog "OK $endpoint reachable ($($endpointResult.Method), $($endpointResult.ResponseTime)ms)" -Level Success
                }
            } else {
                if (-not $Quiet) {
                    Write-VelociraptorLog "FAIL $endpoint unreachable: $($endpointResult.Error)" -Level Warning
                }
            }
        }
        
        # Determine overall success
        $overallSuccess = if ($RequireAll) {
            $successCount -eq $TestEndpoints.Count
        } else {
            $successCount -gt 0
        }
        
        if (-not $Quiet) {
            if ($overallSuccess) {
                Write-VelociraptorLog "Internet connectivity test passed ($successCount/$($TestEndpoints.Count) endpoints)" -Level Success
            } else {
                $requirement = if ($RequireAll) { "all" } else { "any" }
                Write-VelociraptorLog "Internet connectivity test failed (required $requirement, got $successCount/$($TestEndpoints.Count))" -Level Error
            }
        }
        
        # Return results
        if ($Quiet) {
            return $overallSuccess
        } else {
            return [PSCustomObject]@{
                Success = $overallSuccess
                SuccessCount = $successCount
                TotalEndpoints = $TestEndpoints.Count
                RequiredAll = $RequireAll
                Results = $results
                TestDate = Get-Date
            }
        }
    }
    catch {
        $errorMessage = "Internet connectivity test failed: $($_.Exception.Message)"
        Write-VelociraptorLog $errorMessage -Level Error
        
        if ($Quiet) {
            return $false
        } else {
            return [PSCustomObject]@{
                Success = $false
                Error = $_.Exception.Message
                TestDate = Get-Date
            }
        }
    }
}