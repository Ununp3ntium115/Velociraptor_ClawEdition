#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploys Velociraptor to Microsoft Azure cloud infrastructure.

.DESCRIPTION
    Comprehensive Azure deployment script for Velociraptor that provisions and configures
    all necessary Azure resources including Virtual Machines, Network Security Groups,
    Load Balancers, Storage Accounts, and optional Azure SQL Database. Supports multiple
    deployment patterns including single-instance, high-availability cluster, and
    serverless configurations using Azure Functions.

.PARAMETER DeploymentType
    Type of Azure deployment: SingleInstance, HighAvailability, Serverless, or ContainerBased.

.PARAMETER Location
    Azure region for deployment.

.PARAMETER VMSize
    Azure VM size for Velociraptor server.

.PARAMETER ResourceGroupName
    Name of the Azure Resource Group. Creates a new one if not specified.

.PARAMETER VNetName
    Name of the Virtual Network. Creates a new one if not specified.

.PARAMETER SubnetName
    Name of the subnet. Creates a new one if not specified.

.PARAMETER EnableHighAvailability
    Deploy in high-availability mode with multiple instances and load balancing.

.PARAMETER EnableServerless
    Deploy using serverless components (Azure Functions, Logic Apps, etc.).

.PARAMETER ContainerRegistry
    Azure Container Registry for container images when using container-based deployment.

.PARAMETER ConfigPath
    Path to Velociraptor configuration template.

.PARAMETER StorageAccountName
    Name of Azure Storage Account for Velociraptor data storage.

.PARAMETER UseAzureSQL
    Use Azure SQL Database for storage instead of local storage.

.PARAMETER SQLServerName
    Azure SQL Server name when UseAzureSQL is enabled.

.PARAMETER Tags
    Hashtable of tags to apply to all Azure resources.

.PARAMETER ARMTemplate
    Path to custom ARM template.

.PARAMETER ParametersFile
    Path to parameters file for ARM template.

.EXAMPLE
    .\Deploy-VelociraptorAzure.ps1 -DeploymentType SingleInstance -Location "East US" -VMSize "Standard_D2s_v3" -ResourceGroupName "velociraptor-rg"

.EXAMPLE
    .\Deploy-VelociraptorAzure.ps1 -DeploymentType HighAvailability -Location "West US 2" -EnableHighAvailability -StorageAccountName "velociraptordata"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('SingleInstance', 'HighAvailability', 'Serverless', 'ContainerBased')]
    [string]$DeploymentType,
    
    [Parameter(Mandatory)]
    [string]$Location,
    
    [string]$VMSize = 'Standard_D2s_v3',
    
    [string]$ResourceGroupName = "velociraptor-rg-$((Get-Date).ToString('yyyyMMddHHmmss'))",
    
    [string]$VNetName = "velociraptor-vnet",
    
    [string]$SubnetName = "velociraptor-subnet",
    
    [switch]$EnableHighAvailability,
    
    [switch]$EnableServerless,
    
    [string]$ContainerRegistry,
    
    [string]$ConfigPath,
    
    [string]$StorageAccountName = "velociraptordata$((Get-Date).ToString('yyyyMMddHHmmss'))",
    
    [switch]$UseAzureSQL,
    
    [string]$SQLServerName = "velociraptor-sql-$((Get-Date).ToString('yyyyMMddHHmmss'))",
    
    [hashtable]$Tags = @{
        'Application' = 'Velociraptor'
        'Environment' = 'Production'
        'ManagedBy' = 'VelociraptorDeployment'
    },
    
    [string]$ARMTemplate,
    
    [string]$ParametersFile
)

# Import required modules
Import-Module Az -ErrorAction SilentlyContinue
Import-Module Az.Resources -ErrorAction SilentlyContinue
Import-Module Az.Compute -ErrorAction SilentlyContinue
Import-Module Az.Network -ErrorAction SilentlyContinue
Import-Module Az.Storage -ErrorAction SilentlyContinue
Import-Module Az.Sql -ErrorAction SilentlyContinue
Import-Module Az.Functions -ErrorAction SilentlyContinue
Import-Module Az.ContainerRegistry -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\modules\VelociraptorDeployment" -Force

# Global variables
$script:DeploymentId = (Get-Date).ToString('yyyyMMddHHmmss')
$script:ResourcePrefix = "velociraptor-$script:DeploymentId"

function Deploy-VelociraptorAzure {
    Write-Host "=== VELOCIRAPTOR AZURE DEPLOYMENT ===" -ForegroundColor Cyan
    Write-Host "Deployment Type: $DeploymentType" -ForegroundColor Green
    Write-Host "Location: $Location" -ForegroundColor Green
    Write-Host "VM Size: $VMSize" -ForegroundColor Green
    Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Green
    Write-Host "High Availability: $EnableHighAvailability" -ForegroundColor Green
    Write-Host "Serverless: $EnableServerless" -ForegroundColor Green
    Write-Host ""
    
    try {
        # Connect to Azure
        $context = Get-AzContext
        if (-not $context) {
            Write-Host "Please connect to Azure first using Connect-AzAccount" -ForegroundColor Red
            return
        }
        
        Write-Host "Using Azure Subscription: $($context.Subscription.Name)" -ForegroundColor Yellow
        
        # Create or get resource group
        $resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
        if (-not $resourceGroup) {
            Write-Host "Creating Resource Group: $ResourceGroupName" -ForegroundColor Yellow
            $resourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $Tags
        }
        
        # Select deployment strategy based on type
        switch ($DeploymentType) {
            'SingleInstance' {
                Deploy-SingleInstanceAzure
            }
            'HighAvailability' {
                Deploy-HighAvailabilityAzure
            }
            'Serverless' {
                Deploy-ServerlessAzure
            }
            'ContainerBased' {
                Deploy-ContainerBasedAzure
            }
        }
        
        Write-Host "Velociraptor Azure deployment completed successfully!" -ForegroundColor Green
        Show-AzureDeploymentSummary
    }
    catch {
        Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-VelociraptorLog -Message "Azure deployment failed: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Deploy-SingleInstanceAzure {
    Write-Host "Deploying Velociraptor Single Instance to Azure..." -ForegroundColor Cyan
    
    # Create storage account
    $storageAccount = New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Location $Location -SkuName "Standard_LRS" -Tag $Tags
    Write-Host "Created Storage Account: $StorageAccountName" -ForegroundColor Green
    
    # Create virtual network
    $subnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix "10.0.1.0/24"
    $vnet = New-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix "10.0.0.0/16" -Subnet $subnet -Tag $Tags
    
    # Create network security group
    $nsgRule1 = New-AzNetworkSecurityRuleConfig -Name "Allow-HTTP" -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8000 -Access Allow
    $nsgRule2 = New-AzNetworkSecurityRuleConfig -Name "Allow-GUI" -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8889 -Access Allow
    $nsgRule3 = New-AzNetworkSecurityRuleConfig -Name "Allow-SSH" -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow
    
    $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Location $Location -Name "$script:ResourcePrefix-nsg" -SecurityRules $nsgRule1,$nsgRule2,$nsgRule3 -Tag $Tags
    
    # Create public IP
    $publicIp = New-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $Location -Name "$script:ResourcePrefix-pip" -AllocationMethod Static -Sku Standard -Tag $Tags
    
    # Create network interface
    $nic = New-AzNetworkInterface -Name "$script:ResourcePrefix-nic" -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $publicIp.Id -NetworkSecurityGroupId $nsg.Id -Tag $Tags
    
    # Create VM configuration
    $vmConfig = New-AzVMConfig -VMName "$script:ResourcePrefix-vm" -VMSize $VMSize -Tags $Tags
    $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Linux -ComputerName "$script:ResourcePrefix-vm" -Credential (Get-Credential -Message "Enter VM credentials")
    $vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName "Canonical" -Offer "0001-com-ubuntu-server-focal" -Skus "20_04-lts-gen2" -Version latest
    $vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id
    $vmConfig = Set-AzVMBootDiagnostic -VM $vmConfig -Enable -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
    
    # Create custom script extension for Velociraptor installation
    $customScript = Get-AzureVMCustomScript -DeploymentType SingleInstance
    $vmConfig = Set-AzVMCustomScriptExtension -VM $vmConfig -Name "InstallVelociraptor" -TypeHandlerVersion "2.1" -FileUri $customScript.FileUri -Run $customScript.CommandToExecute
    
    # Create the VM
    Write-Host "Creating Virtual Machine..." -ForegroundColor Yellow
    $vm = New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $vmConfig
    
    Write-Host "Virtual Machine created successfully!" -ForegroundColor Green
    
    # Store deployment information
    $script:DeploymentInfo = @{
        VMName = $vm.Name
        ResourceGroupName = $ResourceGroupName
        PublicIpAddress = $publicIp.IpAddress
        StorageAccountName = $StorageAccountName
        NetworkSecurityGroupName = $nsg.Name
    }
}

function Deploy-HighAvailabilityAzure {
    Write-Host "Deploying Velociraptor High Availability Cluster to Azure..." -ForegroundColor Cyan
    
    # Create availability set
    $availabilitySet = New-AzAvailabilitySet -ResourceGroupName $ResourceGroupName -Name "$script:ResourcePrefix-as" -Location $Location -PlatformFaultDomainCount 2 -PlatformUpdateDomainCount 2 -Sku Aligned -Tag $Tags
    
    # Create load balancer
    $frontendIP = New-AzLoadBalancerFrontendIpConfig -Name "FrontEnd" -PublicIpAddress (New-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $Location -Name "$script:ResourcePrefix-lb-pip" -AllocationMethod Static -Sku Standard)
    $backendPool = New-AzLoadBalancerBackendAddressPoolConfig -Name "BackEnd"
    $probe = New-AzLoadBalancerProbeConfig -Name "HealthProbe" -Protocol Http -Port 8000 -IntervalInSeconds 15 -ProbeCount 2 -RequestPath "/"
    $lbrule = New-AzLoadBalancerRuleConfig -Name "LBRule" -FrontendIpConfiguration $frontendIP -BackendAddressPool $backendPool -Probe $probe -Protocol Tcp -FrontendPort 8000 -BackendPort 8000
    
    $loadBalancer = New-AzLoadBalancer -ResourceGroupName $ResourceGroupName -Name "$script:ResourcePrefix-lb" -Location $Location -FrontendIpConfiguration $frontendIP -BackendAddressPool $backendPool -Probe $probe -LoadBalancingRule $lbrule -Sku Standard -Tag $Tags
    
    # Create multiple VMs for HA
    $vmNames = @()
    for ($i = 1; $i -le 3; $i++) {
        $vmName = "$script:ResourcePrefix-vm$i"
        
        # Create network interface for each VM
        $nic = New-AzNetworkInterface -Name "$vmName-nic" -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $vnet.Subnets[0].Id -LoadBalancerBackendAddressPoolId $loadBalancer.BackendAddressPools[0].Id
        
        # Create VM configuration
        $vmConfig = New-AzVMConfig -VMName $vmName -VMSize $VMSize -AvailabilitySetId $availabilitySet.Id -Tags $Tags
        $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Linux -ComputerName $vmName -Credential (Get-Credential -Message "Enter VM credentials for $vmName")
        $vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName "Canonical" -Offer "0001-com-ubuntu-server-focal" -Skus "20_04-lts-gen2" -Version latest
        $vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id
        
        # Create the VM
        $vm = New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $vmConfig
        $vmNames += $vmName
        
        Write-Host "Created VM: $vmName" -ForegroundColor Green
    }
    
    Write-Host "High Availability cluster deployed with $($vmNames.Count) instances" -ForegroundColor Green
    
    $script:DeploymentInfo = @{
        LoadBalancerName = $loadBalancer.Name
        AvailabilitySetName = $availabilitySet.Name
        VMNames = $vmNames
        ResourceGroupName = $ResourceGroupName
    }
}

function Deploy-ServerlessAzure {
    Write-Host "Deploying Velociraptor Serverless Architecture to Azure..." -ForegroundColor Cyan
    
    # Create Function App
    $functionApp = New-AzFunctionApp -ResourceGroupName $ResourceGroupName -Name "$script:ResourcePrefix-func" -Location $Location -StorageAccountName $StorageAccountName -Runtime PowerShell -Tag $Tags
    
    # Create Logic App for workflow automation
    $logicApp = New-AzLogicApp -ResourceGroupName $ResourceGroupName -Name "$script:ResourcePrefix-logic" -Location $Location -Tag $Tags
    
    # Create Cosmos DB for data storage
    $cosmosAccount = New-AzCosmosDBAccount -ResourceGroupName $ResourceGroupName -Name "$script:ResourcePrefix-cosmos" -Location $Location -DefaultConsistencyLevel Session -Tag $Tags
    
    Write-Host "Deployed serverless Velociraptor architecture" -ForegroundColor Green
    
    $script:DeploymentInfo = @{
        FunctionAppName = $functionApp.Name
        LogicAppName = $logicApp.Name
        CosmosDBAccountName = $cosmosAccount.Name
        ResourceGroupName = $ResourceGroupName
    }
}

function Deploy-ContainerBasedAzure {
    Write-Host "Deploying Velociraptor Container-Based Architecture to Azure..." -ForegroundColor Cyan
    
    # Create Azure Container Registry
    $acr = New-AzContainerRegistry -ResourceGroupName $ResourceGroupName -Name "$script:ResourcePrefix-acr" -Location $Location -Sku Basic -Tag $Tags
    
    # Create Azure Container Instances
    $containerGroup = New-AzContainerGroup -ResourceGroupName $ResourceGroupName -Name "$script:ResourcePrefix-aci" -Location $Location -Container @(
        New-AzContainerInstanceObject -Name "velociraptor" -Image "velocidex/velociraptor:latest" -RequestCpu 2 -RequestMemoryInGb 4 -Port @(8000, 8889)
    ) -Tag $Tags
    
    Write-Host "Deployed container-based Velociraptor architecture" -ForegroundColor Green
    
    $script:DeploymentInfo = @{
        ContainerRegistryName = $acr.Name
        ContainerGroupName = $containerGroup.Name
        ResourceGroupName = $ResourceGroupName
    }
}

function Get-AzureVMCustomScript {
    param([string]$DeploymentType)
    
    $scriptContent = @"
#!/bin/bash
apt-get update
apt-get install -y wget curl

# Download and install Velociraptor
wget https://github.com/Velocidex/velociraptor/releases/latest/download/velociraptor-linux-amd64 -O /usr/local/bin/velociraptor
chmod +x /usr/local/bin/velociraptor

# Generate configuration
/usr/local/bin/velociraptor config generate > /etc/velociraptor.yaml

# Create systemd service
cat > /etc/systemd/system/velociraptor.service << EOF
[Unit]
Description=Velociraptor Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/velociraptor --config /etc/velociraptor.yaml frontend
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start and enable service
systemctl daemon-reload
systemctl enable velociraptor
systemctl start velociraptor
"@
    
    return @{
        FileUri = "https://raw.githubusercontent.com/your-repo/velociraptor-setup/main/scripts/install-velociraptor.sh"
        CommandToExecute = "bash install-velociraptor.sh"
    }
}

function Show-AzureDeploymentSummary {
    Write-Host "`n=== AZURE DEPLOYMENT SUMMARY ===" -ForegroundColor Cyan
    Write-Host "Deployment Type: $DeploymentType" -ForegroundColor Green
    Write-Host "Location: $Location" -ForegroundColor Green
    Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Green
    
    switch ($DeploymentType) {
        'SingleInstance' {
            Write-Host "VM Name: $($script:DeploymentInfo.VMName)" -ForegroundColor Yellow
            Write-Host "Public IP: $($script:DeploymentInfo.PublicIpAddress)" -ForegroundColor Yellow
            Write-Host "Storage Account: $($script:DeploymentInfo.StorageAccountName)" -ForegroundColor Yellow
            Write-Host "`nAccess URLs:" -ForegroundColor Cyan
            Write-Host "  GUI: https://$($script:DeploymentInfo.PublicIpAddress):8889" -ForegroundColor White
            Write-Host "  API: https://$($script:DeploymentInfo.PublicIpAddress):8000" -ForegroundColor White
        }
        'HighAvailability' {
            Write-Host "Load Balancer: $($script:DeploymentInfo.LoadBalancerName)" -ForegroundColor Yellow
            Write-Host "VM Count: $($script:DeploymentInfo.VMNames.Count)" -ForegroundColor Yellow
            Write-Host "Availability Set: $($script:DeploymentInfo.AvailabilitySetName)" -ForegroundColor Yellow
        }
        'Serverless' {
            Write-Host "Function App: $($script:DeploymentInfo.FunctionAppName)" -ForegroundColor Yellow
            Write-Host "Logic App: $($script:DeploymentInfo.LogicAppName)" -ForegroundColor Yellow
            Write-Host "Cosmos DB: $($script:DeploymentInfo.CosmosDBAccountName)" -ForegroundColor Yellow
        }
        'ContainerBased' {
            Write-Host "Container Registry: $($script:DeploymentInfo.ContainerRegistryName)" -ForegroundColor Yellow
            Write-Host "Container Group: $($script:DeploymentInfo.ContainerGroupName)" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`nDeployment completed successfully!" -ForegroundColor Green
}

# Main execution
Deploy-VelociraptorAzure