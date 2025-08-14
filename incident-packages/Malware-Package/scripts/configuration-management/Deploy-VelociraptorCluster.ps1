#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploys and manages Velociraptor in high-availability cluster configuration.

.DESCRIPTION
    This script provides comprehensive cluster management capabilities for Velociraptor
    deployments including:
    - Multi-node cluster deployment
    - Load balancing configuration
    - Geographic distribution support
    - Cluster health monitoring
    - Automated failover and recovery
    - Centralized configuration management

.PARAMETER ClusterConfig
    Path to cluster configuration file.

.PARAMETER Action
    Action to perform: Deploy, Scale, Update, Remove, Status, Failover.

.PARAMETER NodeCount
    Number of nodes in the cluster.

.PARAMETER LoadBalancerType
    Type of load balancer: HAProxy, NGINX, AWS_ALB, Azure_LB.

.PARAMETER GeographicDistribution
    Enable geographic distribution across regions.

.PARAMETER HealthCheckInterval
    Health check interval in seconds.

.PARAMETER AutoFailover
    Enable automatic failover on node failure.

.EXAMPLE
    .\Deploy-VelociraptorCluster.ps1 -ClusterConfig "cluster.json" -Action Deploy -NodeCount 3

.EXAMPLE
    .\Deploy-VelociraptorCluster.ps1 -ClusterConfig "cluster.json" -Action Scale -NodeCount 5 -AutoFailover
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$ClusterConfig,

    [Parameter(Mandatory)]
    [ValidateSet('Deploy', 'Scale', 'Update', 'Remove', 'Status', 'Failover', 'Backup', 'Restore')]
    [string]$Action,

    [ValidateRange(1, 50)]
    [int]$NodeCount = 3,

    [ValidateSet('HAProxy', 'NGINX', 'AWS_ALB', 'Azure_LB', 'GCP_LB')]
    [string]$LoadBalancerType = 'HAProxy',

    [switch]$GeographicDistribution,

    [ValidateRange(10, 300)]
    [int]$HealthCheckInterval = 30,

    [switch]$AutoFailover
)

# Import required modules
Import-Module "$PSScriptRoot\..\..\modules\VelociraptorDeployment" -Force

function Deploy-VelociraptorCluster {
    Write-Host "=== VELOCIRAPTOR CLUSTER DEPLOYMENT ===" -ForegroundColor Cyan
    Write-Host "Cluster Configuration: $ClusterConfig" -ForegroundColor Green
    Write-Host "Action: $Action" -ForegroundColor Green
    Write-Host "Node Count: $NodeCount" -ForegroundColor Green
    Write-Host "Load Balancer: $LoadBalancerType" -ForegroundColor Green
    Write-Host "Geographic Distribution: $GeographicDistribution" -ForegroundColor Green
    Write-Information "" -InformationAction Continue

    try {
        # Load cluster configuration
        $config = Get-Content $ClusterConfig | ConvertFrom-Json

        # Validate cluster configuration
        Test-ClusterConfiguration -Config $config

        # Execute requested action
        switch ($Action) {
            'Deploy' {
                Deploy-ClusterNodes -Config $config -NodeCount $NodeCount
                Configure-LoadBalancer -Config $config -LoadBalancerType $LoadBalancerType
                if ($GeographicDistribution) {
                    Configure-GeographicDistribution -Config $config
                }
                Start-ClusterHealthMonitoring -Config $config -Interval $HealthCheckInterval -AutoFailover:$AutoFailover
            }
            'Scale' {
                Scale-ClusterNodes -Config $config -TargetNodeCount $NodeCount
                Update-LoadBalancerConfiguration -Config $config
            }
            'Update' {
                Update-ClusterNodes -Config $config
            }
            'Remove' {
                Remove-VelociraptorCluster -Config $config
            }
            'Status' {
                Get-ClusterStatus -Config $config
            }
            'Failover' {
                Invoke-ClusterFailover -Config $config
            }
            'Backup' {
                Backup-ClusterConfiguration -Config $config
            }
            'Restore' {
                Restore-ClusterConfiguration -Config $config
            }
        }

        Write-Host "Cluster operation completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "Cluster operation failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-VelociraptorLog -Message "Cluster operation error: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Test-ClusterConfiguration {
    param($Config)

    Write-Host "Validating cluster configuration..." -ForegroundColor Cyan

    # Validate required configuration sections
    $requiredSections = @('cluster', 'nodes', 'load_balancer', 'storage', 'networking')
    foreach ($section in $requiredSections) {
        if (-not $Config.$section) {
            throw "Missing required configuration section: $section"
        }
    }

    # Validate node configurations
    if ($Config.nodes.Count -lt 1) {
        throw "At least one node must be configured"
    }

    foreach ($node in $Config.nodes) {
        if (-not $node.hostname -or -not $node.ip_address) {
            throw "Node configuration missing hostname or IP address"
        }

        # Test node connectivity
        if (-not (Test-Connection -ComputerName $node.ip_address -Count 1 -Quiet)) {
            Write-Warning "Node $($node.hostname) ($($node.ip_address)) is not reachable"
        }
    }

    # Validate storage configuration
    if ($Config.storage.type -eq 'shared' -and -not $Config.storage.path) {
        throw "Shared storage path not specified"
    }

    Write-Host "Configuration validation passed" -ForegroundColor Green
}

function Deploy-ClusterNodes {
    param($Config, $NodeCount)

    Write-Host "Deploying cluster nodes..." -ForegroundColor Cyan

    $deployedNodes = @()
    $nodesToDeploy = $Config.nodes | Select-Object -First $NodeCount

    foreach ($node in $nodesToDeploy) {
        Write-Host "Deploying node: $($node.hostname)" -ForegroundColor Yellow

        try {
            # Generate node-specific configuration
            $nodeConfig = Generate-NodeConfiguration -Config $Config -Node $node

            # Deploy Velociraptor to node
            $deployResult = Deploy-NodeVelociraptor -Node $node -NodeConfig $nodeConfig

            if ($deployResult.Success) {
                $deployedNodes += $node
                Write-Host "  Node $($node.hostname) deployed successfully" -ForegroundColor Green
            }
            else {
                Write-Host "  Node $($node.hostname) deployment failed: $($deployResult.Error)" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "  Node $($node.hostname) deployment error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host "Deployed $($deployedNodes.Count) of $($nodesToDeploy.Count) nodes" -ForegroundColor Green

    # Update cluster state
    $Config.cluster.deployed_nodes = $deployedNodes
    $Config.cluster.deployment_time = Get-Date

    return $deployedNodes
}

function New-NodeConfiguration {
    param($Config, $Node)

    # Create node-specific configuration based on cluster template
    $nodeConfig = $Config.velociraptor_config.PSObject.Copy()

    # Update node-specific settings
    $nodeConfig.GUI.bind_address = $Node.ip_address
    $nodeConfig.API.bind_address = $Node.ip_address
    $nodeConfig.Frontend.bind_address = $Node.ip_address

    # Configure cluster-specific settings
    if ($Config.storage.type -eq 'shared') {
        $nodeConfig.Datastore.location = $Config.storage.path
    }
    else {
        $nodeConfig.Datastore.location = "$($Config.storage.base_path)/$($Node.hostname)"
    }

    # Set cluster identification
    $nodeConfig.cluster = @{
        node_id = $Node.hostname
        cluster_id = $Config.cluster.id
        role = $Node.role
    }

    return $nodeConfig
}

function Deploy-NodeVelociraptor {
    param($Node, $NodeConfig)

    $result = @{
        Success = $false
        Error = $null
    }

    try {
        # Create remote session
        $session = New-PSSession -ComputerName $Node.ip_address -Credential $Node.credential -ErrorAction Stop

        # Copy deployment scripts to remote node
        Copy-Item -Path "$PSScriptRoot\..\..\modules" -Destination "C:\temp\velociraptor-deployment" -ToSession $session -Recurse -Force

        # Execute deployment on remote node
        $deploymentResult = Invoke-Command -Session $session -ScriptBlock {
            param($NodeConfig, $NodeHostname)

            # Import deployment module
            Import-Module "C:\temp\velociraptor-deployment\VelociraptorDeployment" -Force

            try {
                # Create configuration file
                $configPath = "C:\Program Files\Velociraptor\server.config.yaml"
                $configDir = Split-Path $configPath -Parent

                if (-not (Test-Path $configDir)) {
                    New-Item -Path $configDir -ItemType Directory -Force
                }

                $NodeConfig | ConvertTo-Yaml | Set-Content -Path $configPath

                # Download and install Velociraptor
                $latestRelease = Get-VelociraptorLatestRelease
                $downloadResult = Invoke-VelociraptorDownload -Url $latestRelease.WindowsUrl -OutputPath "C:\Program Files\Velociraptor\velociraptor.exe"

                if (-not $downloadResult.Success) {
                    throw "Failed to download Velociraptor: $($downloadResult.Error)"
                }

                # Install as service
                $serviceResult = & "C:\Program Files\Velociraptor\velociraptor.exe" --config $configPath service install

                # Start service
                Start-Service -Name "Velociraptor" -ErrorAction Stop

                return @{
                    Success = $true
                    Message = "Node $NodeHostname deployed successfully"
                }
            }
            catch {
                return @{
                    Success = $false
                    Error = $_.Exception.Message
                }
            }
        } -ArgumentList $NodeConfig, $Node.hostname

        # Clean up session
        Remove-PSSession -Session $session

        $result.Success = $deploymentResult.Success
        if (-not $deploymentResult.Success) {
            $result.Error = $deploymentResult.Error
        }
    }
    catch {
        $result.Error = $_.Exception.Message
    }

    return $result
}

function Set-LoadBalancer {
    param($Config, $LoadBalancerType)

    Write-Host "Configuring load balancer: $LoadBalancerType" -ForegroundColor Cyan

    switch ($LoadBalancerType) {
        'HAProxy' {
            Configure-HAProxyLoadBalancer -Config $Config
        }
        'NGINX' {
            Configure-NGINXLoadBalancer -Config $Config
        }
        'AWS_ALB' {
            Configure-AWSLoadBalancer -Config $Config
        }
        'Azure_LB' {
            Configure-AzureLoadBalancer -Config $Config
        }
        'GCP_LB' {
            Configure-GCPLoadBalancer -Config $Config
        }
    }

    Write-Host "Load balancer configuration completed" -ForegroundColor Green
}

function Set-HAProxyLoadBalancer {
    param($Config)

    $haproxyConfig = @"
global
    daemon
    maxconn 4096
    log stdout local0

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
    option httplog

frontend velociraptor_gui
    bind *:8889
    default_backend velociraptor_gui_servers

frontend velociraptor_api
    bind *:8000
    default_backend velociraptor_api_servers

frontend velociraptor_frontend
    bind *:8080
    default_backend velociraptor_frontend_servers

backend velociraptor_gui_servers
    balance roundrobin
    option httpchk GET /api/v1/GetVersion
"@

    foreach ($node in $Config.cluster.deployed_nodes) {
        $haproxyConfig += "`n    server $($node.hostname) $($node.ip_address):8889 check"
    }

    $haproxyConfig += @"

backend velociraptor_api_servers
    balance roundrobin
    option httpchk GET /api/v1/GetVersion
"@

    foreach ($node in $Config.cluster.deployed_nodes) {
        $haproxyConfig += "`n    server $($node.hostname) $($node.ip_address):8000 check"
    }

    $haproxyConfig += @"

backend velociraptor_frontend_servers
    balance roundrobin
    option httpchk GET /server.pem
"@

    foreach ($node in $Config.cluster.deployed_nodes) {
        $haproxyConfig += "`n    server $($node.hostname) $($node.ip_address):8080 check"
    }

    # Save HAProxy configuration
    $haproxyConfigPath = "$PSScriptRoot\haproxy.cfg"
    $haproxyConfig | Set-Content -Path $haproxyConfigPath

    Write-Host "HAProxy configuration saved to: $haproxyConfigPath" -ForegroundColor Yellow
}

function Set-NGINXLoadBalancer {
    param($Config)

    $nginxConfig = @"
upstream velociraptor_gui {
"@

    foreach ($node in $Config.cluster.deployed_nodes) {
        $nginxConfig += "`n    server $($node.ip_address):8889;"
    }

    $nginxConfig += @"
}

upstream velociraptor_api {
"@

    foreach ($node in $Config.cluster.deployed_nodes) {
        $nginxConfig += "`n    server $($node.ip_address):8000;"
    }

    $nginxConfig += @"
}

upstream velociraptor_frontend {
"@

    foreach ($node in $Config.cluster.deployed_nodes) {
        $nginxConfig += "`n    server $($node.ip_address):8080;"
    }

    $nginxConfig += @"
}

server {
    listen 8889;
    location / {
        proxy_pass http://velociraptor_gui;
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
    }
}

server {
    listen 8000;
    location / {
        proxy_pass http://velociraptor_api;
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
    }
}

server {
    listen 8080;
    location / {
        proxy_pass http://velociraptor_frontend;
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
    }
}
"@

    # Save NGINX configuration
    $nginxConfigPath = "$PSScriptRoot\nginx.conf"
    $nginxConfig | Set-Content -Path $nginxConfigPath

    Write-Host "NGINX configuration saved to: $nginxConfigPath" -ForegroundColor Yellow
}

function Start-ClusterHealthMonitoring {
    param($Config, $Interval, $AutoFailover)

    Write-Host "Starting cluster health monitoring..." -ForegroundColor Cyan
    Write-Host "Health check interval: $Interval seconds" -ForegroundColor Yellow
    Write-Host "Auto-failover enabled: $AutoFailover" -ForegroundColor Yellow

    # Create monitoring job
    $monitoringJob = Start-Job -ScriptBlock {
        param($Config, $Interval, $AutoFailover)

        while ($true) {
            try {
                # Check each node health
                foreach ($node in $Config.cluster.deployed_nodes) {
                    $healthResult = Test-NodeHealth -Node $node

                    if (-not $healthResult.Healthy) {
                        Write-Warning "Node $($node.hostname) health check failed: $($healthResult.Error)"

                        if ($AutoFailover) {
                            # Trigger failover logic
                            Invoke-NodeFailover -Config $Config -FailedNode $node
                        }
                    }
                }

                Start-Sleep -Seconds $Interval
            }
            catch {
                Write-Error "Health monitoring error: $($_.Exception.Message)"
                Start-Sleep -Seconds $Interval
            }
        }
    } -ArgumentList $Config, $Interval, $AutoFailover

    Write-Host "Health monitoring job started (Job ID: $($monitoringJob.Id))" -ForegroundColor Green
    return $monitoringJob
}

function Test-NodeHealth {
    param($Node)

    $result = @{
        Healthy = $false
        Error = $null
        ResponseTime = $null
    }

    try {
        $startTime = Get-Date

        # Test GUI endpoint
        $response = Invoke-RestMethod -Uri "http://$($Node.ip_address):8889/api/v1/GetVersion" -TimeoutSec 10 -ErrorAction Stop

        $result.ResponseTime = (Get-Date) - $startTime
        $result.Healthy = $true
    }
    catch {
        $result.Error = $_.Exception.Message
    }

    return $result
}

function Get-ClusterStatus {
    param($Config)

    Write-Host "=== CLUSTER STATUS ===" -ForegroundColor Cyan
    Write-Host "Cluster ID: $($Config.cluster.id)" -ForegroundColor Green
    Write-Host "Deployment Time: $($Config.cluster.deployment_time)" -ForegroundColor Green
    Write-Host "Total Nodes: $($Config.cluster.deployed_nodes.Count)" -ForegroundColor Green
    Write-Information "" -InformationAction Continue

    Write-Host "Node Status:" -ForegroundColor Yellow
    foreach ($node in $Config.cluster.deployed_nodes) {
        $health = Test-NodeHealth -Node $node
        $status = if ($health.Healthy) { "HEALTHY" } else { "UNHEALTHY" }
        $color = if ($health.Healthy) { "Green" } else { "Red" }

        Write-Host "  $($node.hostname) ($($node.ip_address)): $status" -ForegroundColor $color
        if ($health.ResponseTime) {
            Write-Host "    Response Time: $($health.ResponseTime.TotalMilliseconds)ms" -ForegroundColor Gray
        }
        if ($health.Error) {
            Write-Host "    Error: $($health.Error)" -ForegroundColor Red
        }
    }
}

# Execute cluster deployment
Deploy-VelociraptorCluster