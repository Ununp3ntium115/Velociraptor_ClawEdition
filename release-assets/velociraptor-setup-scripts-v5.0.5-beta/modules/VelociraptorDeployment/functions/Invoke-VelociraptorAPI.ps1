function Invoke-VelociraptorAPI {
    <#
    .SYNOPSIS
        PowerShell wrapper for Velociraptor REST API operations.
    
    .DESCRIPTION
        Provides a comprehensive PowerShell interface for interacting with the Velociraptor
        REST API, including authentication, request handling, and response processing.
    
    .PARAMETER BaseUrl
        Base URL of the Velociraptor server API endpoint.
    
    .PARAMETER Endpoint
        API endpoint path (e.g., '/api/v1/GetVersion').
    
    .PARAMETER Method
        HTTP method (GET, POST, PUT, DELETE).
    
    .PARAMETER Body
        Request body for POST/PUT operations.
    
    .PARAMETER Headers
        Additional HTTP headers.
    
    .PARAMETER Credential
        Authentication credentials.
    
    .PARAMETER ApiKey
        API key for authentication.
    
    .PARAMETER TimeoutSeconds
        Request timeout in seconds.
    
    .PARAMETER RetryCount
        Number of retry attempts for failed requests.
    
    .PARAMETER OutputFormat
        Output format (JSON, PSObject, Raw).
    
    .EXAMPLE
        Invoke-VelociraptorAPI -BaseUrl "https://velociraptor.company.com" -Endpoint "/api/v1/GetVersion"
    
    .EXAMPLE
        Invoke-VelociraptorAPI -BaseUrl "https://localhost:8889" -Endpoint "/api/v1/CreateHunt" -Method POST -Body $huntConfig -Credential $creds
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({[System.Uri]::IsWellFormedUriString($_, [System.UriKind]::Absolute)})]
        [string]$BaseUrl,
        
        [Parameter(Mandatory)]
        [ValidatePattern('^/')]
        [string]$Endpoint,
        
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE', 'PATCH')]
        [string]$Method = 'GET',
        
        [object]$Body,
        
        [hashtable]$Headers = @{},
        
        [System.Management.Automation.PSCredential]$Credential,
        
        [string]$ApiKey,
        
        [ValidateRange(1, 300)]
        [int]$TimeoutSeconds = 30,
        
        [ValidateRange(0, 5)]
        [int]$RetryCount = 3,
        
        [ValidateSet('JSON', 'PSObject', 'Raw')]
        [string]$OutputFormat = 'PSObject'
    )
    
    Write-VelociraptorLog -Message "Invoking Velociraptor API: $Method $Endpoint" -Level Info
    
    try {
        # Construct full URL
        $uri = "$($BaseUrl.TrimEnd('/'))$Endpoint"
        
        # Prepare headers
        $requestHeaders = $Headers.Clone()
        $requestHeaders['User-Agent'] = 'VelociraptorDeployment-PowerShell/1.0'
        $requestHeaders['Accept'] = 'application/json'
        
        # Handle authentication
        if ($ApiKey) {
            $requestHeaders['Authorization'] = "Bearer $ApiKey"
        }
        elseif ($Credential) {
            $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Credential.UserName):$($Credential.GetNetworkCredential().Password)"))
            $requestHeaders['Authorization'] = "Basic $auth"
        }
        
        # Prepare request parameters
        $requestParams = @{
            Uri = $uri
            Method = $Method
            Headers = $requestHeaders
            TimeoutSec = $TimeoutSeconds
            UseBasicParsing = $true
        }
        
        # Add body for POST/PUT requests
        if ($Body -and $Method -in @('POST', 'PUT', 'PATCH')) {
            if ($Body -is [string]) {
                $requestParams.Body = $Body
                $requestHeaders['Content-Type'] = 'application/json'
            }
            else {
                $requestParams.Body = $Body | ConvertTo-Json -Depth 10
                $requestHeaders['Content-Type'] = 'application/json'
            }
        }
        
        # Execute request with retry logic
        $response = $null
        $lastError = $null
        
        for ($attempt = 1; $attempt -le ($RetryCount + 1); $attempt++) {
            try {
                Write-VelociraptorLog -Message "API request attempt $attempt/$($RetryCount + 1)" -Level Debug
                
                $response = Invoke-RestMethod @requestParams
                break
            }
            catch {
                $lastError = $_
                
                if ($attempt -le $RetryCount) {
                    $waitTime = [Math]::Pow(2, $attempt - 1)  # Exponential backoff
                    Write-VelociraptorLog -Message "API request failed, retrying in $waitTime seconds: $($_.Exception.Message)" -Level Warning
                    Start-Sleep -Seconds $waitTime
                }
                else {
                    Write-VelociraptorLog -Message "API request failed after $($RetryCount + 1) attempts: $($_.Exception.Message)" -Level Error
                    throw
                }
            }
        }
        
        # Process response based on output format
        switch ($OutputFormat) {
            'JSON' {
                return $response | ConvertTo-Json -Depth 10
            }
            'Raw' {
                return $response
            }
            default {
                return $response
            }
        }
    }
    catch {
        $errorMsg = "Velociraptor API call failed: $($_.Exception.Message)"
        Write-VelociraptorLog -Message $errorMsg -Level Error
        throw $errorMsg
    }
}

function Get-VelociraptorVersion {
    <#
    .SYNOPSIS
        Gets Velociraptor server version information.
    
    .PARAMETER BaseUrl
        Base URL of the Velociraptor server.
    
    .PARAMETER Credential
        Authentication credentials.
    
    .EXAMPLE
        Get-VelociraptorVersion -BaseUrl "https://velociraptor.company.com" -Credential $creds
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BaseUrl,
        
        [System.Management.Automation.PSCredential]$Credential
    )
    
    return Invoke-VelociraptorAPI -BaseUrl $BaseUrl -Endpoint "/api/v1/GetVersion" -Credential $Credential
}

function Get-VelociraptorClients {
    <#
    .SYNOPSIS
        Retrieves list of Velociraptor clients.
    
    .PARAMETER BaseUrl
        Base URL of the Velociraptor server.
    
    .PARAMETER Credential
        Authentication credentials.
    
    .PARAMETER Count
        Maximum number of clients to retrieve.
    
    .PARAMETER Offset
        Offset for pagination.
    
    .EXAMPLE
        Get-VelociraptorClients -BaseUrl "https://velociraptor.company.com" -Credential $creds -Count 100
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BaseUrl,
        
        [System.Management.Automation.PSCredential]$Credential,
        
        [int]$Count = 50,
        
        [int]$Offset = 0
    )
    
    $body = @{
        count = $Count
        offset = $Offset
    }
    
    return Invoke-VelociraptorAPI -BaseUrl $BaseUrl -Endpoint "/api/v1/SearchClients" -Method POST -Body $body -Credential $Credential
}

function Start-VelociraptorHunt {
    <#
    .SYNOPSIS
        Creates and starts a new Velociraptor hunt.
    
    .PARAMETER BaseUrl
        Base URL of the Velociraptor server.
    
    .PARAMETER Credential
        Authentication credentials.
    
    .PARAMETER HuntName
        Name of the hunt.
    
    .PARAMETER Description
        Hunt description.
    
    .PARAMETER Artifacts
        Array of artifacts to collect.
    
    .PARAMETER ClientLimit
        Maximum number of clients to target.
    
    .PARAMETER ExpiryHours
        Hunt expiry time in hours.
    
    .EXAMPLE
        Start-VelociraptorHunt -BaseUrl "https://velociraptor.company.com" -Credential $creds -HuntName "System Info Collection" -Artifacts @("Windows.System.Info")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BaseUrl,
        
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Credential,
        
        [Parameter(Mandatory)]
        [string]$HuntName,
        
        [string]$Description = "",
        
        [Parameter(Mandatory)]
        [string[]]$Artifacts,
        
        [int]$ClientLimit = 1000,
        
        [int]$ExpiryHours = 168  # 7 days
    )
    
    $huntConfig = @{
        hunt_description = $Description
        start_request = @{
            artifacts = $Artifacts
            specs = @()
            expires = (Get-Date).AddHours($ExpiryHours).ToString("yyyy-MM-ddTHH:mm:ssZ")
            client_limit = $ClientLimit
        }
    }
    
    return Invoke-VelociraptorAPI -BaseUrl $BaseUrl -Endpoint "/api/v1/CreateHunt" -Method POST -Body $huntConfig -Credential $Credential
}

function Get-VelociraptorHunts {
    <#
    .SYNOPSIS
        Retrieves list of Velociraptor hunts.
    
    .PARAMETER BaseUrl
        Base URL of the Velociraptor server.
    
    .PARAMETER Credential
        Authentication credentials.
    
    .PARAMETER Count
        Maximum number of hunts to retrieve.
    
    .PARAMETER Offset
        Offset for pagination.
    
    .EXAMPLE
        Get-VelociraptorHunts -BaseUrl "https://velociraptor.company.com" -Credential $creds
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BaseUrl,
        
        [System.Management.Automation.PSCredential]$Credential,
        
        [int]$Count = 50,
        
        [int]$Offset = 0
    )
    
    $body = @{
        count = $Count
        offset = $Offset
    }
    
    return Invoke-VelociraptorAPI -BaseUrl $BaseUrl -Endpoint "/api/v1/ListHunts" -Method POST -Body $body -Credential $Credential
}

function Stop-VelociraptorHunt {
    <#
    .SYNOPSIS
        Stops a running Velociraptor hunt.
    
    .PARAMETER BaseUrl
        Base URL of the Velociraptor server.
    
    .PARAMETER Credential
        Authentication credentials.
    
    .PARAMETER HuntId
        Hunt ID to stop.
    
    .EXAMPLE
        Stop-VelociraptorHunt -BaseUrl "https://velociraptor.company.com" -Credential $creds -HuntId "H.12345"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BaseUrl,
        
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Credential,
        
        [Parameter(Mandatory)]
        [string]$HuntId
    )
    
    $body = @{
        hunt_id = $HuntId
        state = "STOPPED"
    }
    
    return Invoke-VelociraptorAPI -BaseUrl $BaseUrl -Endpoint "/api/v1/ModifyHunt" -Method POST -Body $body -Credential $Credential
}

function Send-VelociraptorWebhook {
    <#
    .SYNOPSIS
        Sends webhook notifications for Velociraptor events.
    
    .PARAMETER WebhookUrl
        Webhook destination URL.
    
    .PARAMETER Event
        Event data to send.
    
    .PARAMETER EventType
        Type of event (Hunt, Client, Alert, etc.).
    
    .PARAMETER Headers
        Additional HTTP headers.
    
    .EXAMPLE
        Send-VelociraptorWebhook -WebhookUrl "https://hooks.slack.com/..." -Event $huntData -EventType "Hunt"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({[System.Uri]::IsWellFormedUriString($_, [System.UriKind]::Absolute)})]
        [string]$WebhookUrl,
        
        [Parameter(Mandatory)]
        [object]$Event,
        
        [Parameter(Mandatory)]
        [string]$EventType,
        
        [hashtable]$Headers = @{}
    )
    
    try {
        $payload = @{
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            event_type = $EventType
            source = "VelociraptorDeployment"
            data = $Event
        }
        
        $requestHeaders = $Headers.Clone()
        $requestHeaders['Content-Type'] = 'application/json'
        $requestHeaders['User-Agent'] = 'VelociraptorDeployment-Webhook/1.0'
        
        $response = Invoke-RestMethod -Uri $WebhookUrl -Method POST -Body ($payload | ConvertTo-Json -Depth 10) -Headers $requestHeaders -TimeoutSec 30
        
        Write-VelociraptorLog -Message "Webhook sent successfully to $WebhookUrl" -Level Info
        return $response
    }
    catch {
        Write-VelociraptorLog -Message "Failed to send webhook: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Connect-VelociraptorSIEM {
    <#
    .SYNOPSIS
        Configures SIEM integration for Velociraptor log forwarding.
    
    .PARAMETER SIEMType
        Type of SIEM system (Splunk, QRadar, ArcSight, Elastic).
    
    .PARAMETER SIEMEndpoint
        SIEM endpoint URL or address.
    
    .PARAMETER Credential
        SIEM authentication credentials.
    
    .PARAMETER LogSources
        Array of log sources to forward.
    
    .PARAMETER ConfigPath
        Path to Velociraptor configuration file.
    
    .EXAMPLE
        Connect-VelociraptorSIEM -SIEMType Splunk -SIEMEndpoint "https://splunk.company.com:8088" -Credential $creds -LogSources @("hunts", "clients", "alerts")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Splunk', 'QRadar', 'ArcSight', 'Elastic', 'Generic')]
        [string]$SIEMType,
        
        [Parameter(Mandatory)]
        [string]$SIEMEndpoint,
        
        [System.Management.Automation.PSCredential]$Credential,
        
        [string[]]$LogSources = @('hunts', 'clients', 'alerts', 'flows'),
        
        [string]$ConfigPath
    )
    
    Write-VelociraptorLog -Message "Configuring SIEM integration: $SIEMType" -Level Info
    
    try {
        # Create SIEM configuration
        $siemConfig = @{
            type = $SIEMType.ToLower()
            endpoint = $SIEMEndpoint
            log_sources = $LogSources
            enabled = $true
            batch_size = 100
            flush_interval = 30
        }
        
        if ($Credential) {
            $siemConfig.username = $Credential.UserName
            $siemConfig.password = $Credential.GetNetworkCredential().Password
        }
        
        # SIEM-specific configuration
        switch ($SIEMType) {
            'Splunk' {
                $siemConfig.index = 'velociraptor'
                $siemConfig.source_type = 'velociraptor:json'
            }
            'Elastic' {
                $siemConfig.index_pattern = 'velociraptor-*'
                $siemConfig.document_type = 'velociraptor_event'
            }
            'QRadar' {
                $siemConfig.log_source_identifier = 'Velociraptor'
            }
        }
        
        # Update Velociraptor configuration if path provided
        if ($ConfigPath -and (Test-Path $ConfigPath)) {
            $config = Get-Content $ConfigPath | ConvertFrom-Yaml
            
            if (-not $config.Logging) {
                $config.Logging = @{}
            }
            
            $config.Logging.siem_integration = $siemConfig
            
            # Backup and save configuration
            Backup-VelociraptorConfiguration -ConfigPath $ConfigPath
            $config | ConvertTo-Yaml | Set-Content -Path $ConfigPath
            
            Write-VelociraptorLog -Message "SIEM integration configuration saved to $ConfigPath" -Level Info
        }
        
        return $siemConfig
    }
    catch {
        Write-VelociraptorLog -Message "Failed to configure SIEM integration: $($_.Exception.Message)" -Level Error
        throw
    }
}