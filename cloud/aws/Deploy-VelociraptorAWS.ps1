#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploys Velociraptor to AWS cloud infrastructure.

.DESCRIPTION
    Comprehensive AWS deployment script for Velociraptor that provisions and configures
    all necessary AWS resources including EC2 instances, security groups, load balancers,
    S3 storage, and optional RDS database. Supports multiple deployment patterns including
    single-instance, high-availability cluster, and serverless configurations.

.PARAMETER DeploymentType
    Type of AWS deployment: SingleInstance, HighAvailability, Serverless, or ContainerBased.

.PARAMETER Region
    AWS region for deployment.

.PARAMETER InstanceType
    EC2 instance type for Velociraptor server.

.PARAMETER KeyPairName
    Name of the EC2 key pair for SSH access.

.PARAMETER VpcId
    ID of the VPC to deploy into. Creates a new VPC if not specified.

.PARAMETER SubnetIds
    Subnet IDs for deployment. Creates new subnets if not specified.

.PARAMETER EnableHighAvailability
    Deploy in high-availability mode with multiple instances and load balancing.

.PARAMETER EnableServerless
    Deploy using serverless components (Lambda, API Gateway, etc.).

.PARAMETER ContainerRepository
    ECR repository for container images when using container-based deployment.

.PARAMETER ConfigPath
    Path to Velociraptor configuration template.

.PARAMETER StorageBucketName
    Name of S3 bucket for Velociraptor data storage.

.PARAMETER UseRDS
    Use RDS for database storage instead of local storage.

.PARAMETER RDSInstanceType
    RDS instance type when UseRDS is enabled.

.PARAMETER Tags
    Hashtable of tags to apply to all AWS resources.

.PARAMETER CloudFormationTemplate
    Path to custom CloudFormation template.

.PARAMETER ParametersFile
    Path to parameters file for CloudFormation template.

.EXAMPLE
    .\Deploy-VelociraptorAWS.ps1 -DeploymentType SingleInstance -Region us-west-2 -InstanceType t3.large -KeyPairName velociraptor-key

.EXAMPLE
    .\Deploy-VelociraptorAWS.ps1 -DeploymentType HighAvailability -Region us-east-1 -EnableHighAvailability -StorageBucketName velociraptor-data
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('SingleInstance', 'HighAvailability', 'Serverless', 'ContainerBased')]
    [string]$DeploymentType,
    
    [Parameter(Mandatory)]
    [string]$Region,
    
    [string]$InstanceType = 't3.large',
    
    [string]$KeyPairName,
    
    [string]$VpcId,
    
    [string[]]$SubnetIds,
    
    [switch]$EnableHighAvailability,
    
    [switch]$EnableServerless,
    
    [string]$ContainerRepository,
    
    [string]$ConfigPath,
    
    [string]$StorageBucketName = "velociraptor-data-$((Get-Date).ToString('yyyyMMddHHmmss'))",
    
    [switch]$UseRDS,
    
    [string]$RDSInstanceType = 'db.t3.medium',
    
    [hashtable]$Tags = @{
        'Application' = 'Velociraptor'
        'Environment' = 'Production'
        'ManagedBy' = 'VelociraptorDeployment'
    },
    
    [string]$CloudFormationTemplate,
    
    [string]$ParametersFile
)

# Import required modules
Import-Module AWSPowerShell.NetCore -ErrorAction SilentlyContinue
Import-Module AWS.Tools.CloudFormation -ErrorAction SilentlyContinue
Import-Module AWS.Tools.EC2 -ErrorAction SilentlyContinue
Import-Module AWS.Tools.S3 -ErrorAction SilentlyContinue
Import-Module AWS.Tools.ElasticLoadBalancingV2 -ErrorAction SilentlyContinue
Import-Module AWS.Tools.RDS -ErrorAction SilentlyContinue
Import-Module AWS.Tools.Lambda -ErrorAction SilentlyContinue
Import-Module AWS.Tools.ECR -ErrorAction SilentlyContinue
Import-Module "$PSScriptRoot\..\..\modules\VelociraptorDeployment" -Force

# Global variables
$script:StackName = "velociraptor-$DeploymentType-$(Get-Random -Minimum 10000 -Maximum 99999)"
$script:DeploymentId = (Get-Date).ToString('yyyyMMddHHmmss')
$script:ResourcePrefix = "velociraptor-$script:DeploymentId"
$script:TemplatesPath = "$PSScriptRoot\templates"

function Deploy-VelociraptorAWS {
    Write-Host "=== VELOCIRAPTOR AWS DEPLOYMENT ===" -ForegroundColor Cyan
    Write-Host "Deployment Type: $DeploymentType" -ForegroundColor Green
    Write-Host "Region: $Region" -ForegroundColor Green
    Write-Host "Instance Type: $InstanceType" -ForegroundColor Green
    Write-Host "High Availability: $EnableHighAvailability" -ForegroundColor Green
    Write-Host "Serverless: $EnableServerless" -ForegroundColor Green
    Write-Host ""
    
    try {
        # Set AWS region
        Set-DefaultAWSRegion -Region $Region
        
        # Validate AWS credentials
        $identity = Get-STSCallerIdentity
        Write-Host "Using AWS Account: $($identity.Account)" -ForegroundColor Yellow
        
        # Select deployment strategy based on type
        switch ($DeploymentType) {
            'SingleInstance' {
                Deploy-SingleInstanceAWS
            }
            'HighAvailability' {
                Deploy-HighAvailabilityAWS
            }
            'Serverless' {
                Deploy-ServerlessAWS
            }
            'ContainerBased' {
                Deploy-ContainerBasedAWS
            }
        }
        
        Write-Host "Velociraptor AWS deployment completed successfully!" -ForegroundColor Green
        Show-DeploymentSummary
    }
    catch {
        Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-VelociraptorLog -Message "AWS deployment failed: $($_.Exception.Message)" -Level Error
        throw
    }
}

function Deploy-SingleInstanceAWS {
    Write-Host "Deploying Velociraptor Single Instance to AWS..." -ForegroundColor Cyan
    
    # Create S3 bucket for data storage
    New-S3Bucket -BucketName $StorageBucketName -Region $Region
    Write-Host "Created S3 bucket: $StorageBucketName" -ForegroundColor Green
    
    # Create security group
    $securityGroupId = New-EC2SecurityGroup -GroupName "$script:ResourcePrefix-sg" -Description "Velociraptor Security Group"
    
    # Add security group rules
    Grant-EC2SecurityGroupIngress -GroupId $securityGroupId -IpPermission @(
        @{ IpProtocol = 'tcp'; FromPort = 8000; ToPort = 8000; IpRanges = @('0.0.0.0/0') },
        @{ IpProtocol = 'tcp'; FromPort = 8889; ToPort = 8889; IpRanges = @('0.0.0.0/0') },
        @{ IpProtocol = 'tcp'; FromPort = 22; ToPort = 22; IpRanges = @('0.0.0.0/0') }
    )
    
    # Launch EC2 instance
    $userData = Get-UserDataScript -DeploymentType SingleInstance
    $instance = New-EC2Instance -ImageId (Get-LatestAmazonLinuxAMI) -InstanceType $InstanceType -KeyName $KeyPairName -SecurityGroupId $securityGroupId -UserData $userData
    
    $instanceId = $instance.Instances[0].InstanceId
    Write-Host "Launched EC2 instance: $instanceId" -ForegroundColor Green
    
    # Wait for instance to be running
    Wait-EC2Instance -InstanceId $instanceId -DesiredState running
    
    # Get instance details
    $instanceInfo = Get-EC2Instance -InstanceId $instanceId
    $publicIp = $instanceInfo.Instances[0].PublicIpAddress
    
    Write-Host "Instance is running at: $publicIp" -ForegroundColor Green
    
    # Store deployment information
    $script:DeploymentInfo = @{
        InstanceId = $instanceId
        PublicIp = $publicIp
        BucketName = $StorageBucketName
        SecurityGroupId = $securityGroupId
    }
}

function Deploy-HighAvailabilityAWS {
    Write-Host "Deploying Velociraptor High Availability Cluster to AWS..." -ForegroundColor Cyan
    
    # Create Application Load Balancer
    $loadBalancer = New-ELB2LoadBalancer -Name "$script:ResourcePrefix-alb" -Scheme internet-facing -Type application
    
    # Create target group
    $targetGroup = New-ELB2TargetGroup -Name "$script:ResourcePrefix-tg" -Protocol HTTP -Port 8000 -VpcId $VpcId
    
    # Create multiple instances for HA
    $instances = @()
    for ($i = 1; $i -le 3; $i++) {
        $userData = Get-UserDataScript -DeploymentType HighAvailability -NodeNumber $i
        $instance = New-EC2Instance -ImageId (Get-LatestAmazonLinuxAMI) -InstanceType $InstanceType -KeyName $KeyPairName -UserData $userData
        $instances += $instance.Instances[0].InstanceId
        
        # Register instance with target group
        Register-ELB2Target -TargetGroupArn $targetGroup.TargetGroupArn -Target @{ Id = $instance.Instances[0].InstanceId; Port = 8000 }
    }
    
    Write-Host "Deployed $($instances.Count) instances for high availability" -ForegroundColor Green
    
    $script:DeploymentInfo = @{
        LoadBalancerArn = $loadBalancer.LoadBalancerArn
        TargetGroupArn = $targetGroup.TargetGroupArn
        InstanceIds = $instances
        BucketName = $StorageBucketName
    }
}

function Deploy-ServerlessAWS {
    Write-Host "Deploying Velociraptor Serverless Architecture to AWS..." -ForegroundColor Cyan
    
    # Create Lambda function for API handling
    $lambdaCode = Get-LambdaFunctionCode
    $lambdaFunction = Publish-LMFunction -FunctionName "$script:ResourcePrefix-api" -Runtime "python3.9" -Handler "lambda_function.lambda_handler" -ZipFile $lambdaCode
    
    # Create API Gateway
    $apiGateway = New-AGRestApi -Name "$script:ResourcePrefix-api"
    
    # Create DynamoDB table for data storage
    $dynamoTable = New-DDBTable -TableName "$script:ResourcePrefix-data" -AttributeDefinition @(
        @{ AttributeName = "id"; AttributeType = "S" }
    ) -KeySchema @(
        @{ AttributeName = "id"; KeyType = "HASH" }
    ) -BillingMode PAY_PER_REQUEST
    
    Write-Host "Deployed serverless Velociraptor architecture" -ForegroundColor Green
    
    $script:DeploymentInfo = @{
        LambdaFunctionArn = $lambdaFunction.FunctionArn
        ApiGatewayId = $apiGateway.Id
        DynamoTableName = $dynamoTable.TableName
    }
}

function Deploy-ContainerBasedAWS {
    Write-Host "Deploying Velociraptor Container-Based Architecture to AWS..." -ForegroundColor Cyan
    
    # Create ECS cluster
    $cluster = New-ECSCluster -ClusterName "$script:ResourcePrefix-cluster"
    
    # Create task definition
    $taskDefinition = Register-ECSTaskDefinition -Family "$script:ResourcePrefix-task" -ContainerDefinition @(
        @{
            name = "velociraptor"
            image = "$ContainerRepository:latest"
            memory = 2048
            cpu = 1024
            portMappings = @(
                @{ containerPort = 8000; hostPort = 8000; protocol = "tcp" },
                @{ containerPort = 8889; hostPort = 8889; protocol = "tcp" }
            )
        }
    )
    
    # Create ECS service
    $service = New-ECSService -ServiceName "$script:ResourcePrefix-service" -Cluster $cluster.ClusterArn -TaskDefinition $taskDefinition.TaskDefinitionArn -DesiredCount 2
    
    Write-Host "Deployed container-based Velociraptor architecture" -ForegroundColor Green
    
    $script:DeploymentInfo = @{
        ClusterArn = $cluster.ClusterArn
        ServiceArn = $service.ServiceArn
        TaskDefinitionArn = $taskDefinition.TaskDefinitionArn
    }
}

function Get-UserDataScript {
    param(
        [string]$DeploymentType,
        [int]$NodeNumber = 1
    )
    
    return @"
#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker

# Download and install Velociraptor
wget https://github.com/Velocidex/velociraptor/releases/latest/download/velociraptor-linux-amd64 -O /usr/local/bin/velociraptor
chmod +x /usr/local/bin/velociraptor

# Generate configuration
/usr/local/bin/velociraptor config generate > /etc/velociraptor.yaml

# Start Velociraptor service
/usr/local/bin/velociraptor --config /etc/velociraptor.yaml frontend &
"@
}

function Get-LatestAmazonLinuxAMI {
    $images = Get-EC2Image -Owner amazon -Filter @(
        @{ Name = "name"; Values = @("amzn2-ami-hvm-*-x86_64-gp2") },
        @{ Name = "state"; Values = @("available") }
    )
    return ($images | Sort-Object CreationDate -Descending)[0].ImageId
}

function Show-DeploymentSummary {
    Write-Host "`n=== DEPLOYMENT SUMMARY ===" -ForegroundColor Cyan
    Write-Host "Deployment Type: $DeploymentType" -ForegroundColor Green
    Write-Host "Region: $Region" -ForegroundColor Green
    
    switch ($DeploymentType) {
        'SingleInstance' {
            Write-Host "Instance ID: $($script:DeploymentInfo.InstanceId)" -ForegroundColor Yellow
            Write-Host "Public IP: $($script:DeploymentInfo.PublicIp)" -ForegroundColor Yellow
            Write-Host "S3 Bucket: $($script:DeploymentInfo.BucketName)" -ForegroundColor Yellow
            Write-Host "`nAccess URLs:" -ForegroundColor Cyan
            Write-Host "  GUI: https://$($script:DeploymentInfo.PublicIp):8889" -ForegroundColor White
            Write-Host "  API: https://$($script:DeploymentInfo.PublicIp):8000" -ForegroundColor White
        }
        'HighAvailability' {
            Write-Host "Load Balancer: $($script:DeploymentInfo.LoadBalancerArn)" -ForegroundColor Yellow
            Write-Host "Instance Count: $($script:DeploymentInfo.InstanceIds.Count)" -ForegroundColor Yellow
        }
        'Serverless' {
            Write-Host "Lambda Function: $($script:DeploymentInfo.LambdaFunctionArn)" -ForegroundColor Yellow
            Write-Host "API Gateway: $($script:DeploymentInfo.ApiGatewayId)" -ForegroundColor Yellow
        }
        'ContainerBased' {
            Write-Host "ECS Cluster: $($script:DeploymentInfo.ClusterArn)" -ForegroundColor Yellow
            Write-Host "ECS Service: $($script:DeploymentInfo.ServiceArn)" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`nDeployment completed successfully!" -ForegroundColor Green
}

# Main execution
Deploy-VelociraptorAWS