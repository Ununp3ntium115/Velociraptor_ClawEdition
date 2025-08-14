#
# VelociraptorSetupScripts PowerShell Module
# Enterprise-grade Velociraptor DFIR platform deployment automation
# Version: 5.0.1-alpha
#

# Module initialization
Write-Host "Loading Velociraptor Setup Scripts v5.0.1-alpha..." -ForegroundColor Cyan

# Import core deployment module
$ModulePath = Join-Path $PSScriptRoot "modules\VelociraptorDeployment\VelociraptorDeployment.psm1"
if (Test-Path $ModulePath) {
    Import-Module $ModulePath -Force -Global
    Write-Verbose "Imported VelociraptorDeployment module"
} else {
    Write-Warning "VelociraptorDeployment module not found at: $ModulePath"
}

# Define module variables
$script:ModuleVersion = "5.0.1"
$script:ModuleName = "VelociraptorSetupScripts"
$script:Phase = 5
$script:PhaseName = "Cloud-Native & Scalability"

# Export module information
$VelociraptorSetupInfo = @{
    Version = $script:ModuleVersion
    Phase = $script:Phase
    PhaseName = $script:PhaseName
    ReleaseDate = "2025-01-17"
    Stability = "alpha"
    Features = @{
        MultiCloud = $true
        Serverless = $true
        HPC = $true
        EdgeComputing = $true
        ContainerOrchestration = $true
        AIIntegration = $true
        AutoScaling = $true
        Monitoring = $true
        Security = $true
        Compliance = $true
    }
    SupportedCloudProviders = @('AWS', 'Azure', 'GCP', 'Multi-Cloud')
    SupportedDeploymentTypes = @('Standalone', 'Server', 'Cluster', 'Cloud', 'Serverless', 'HPC', 'Edge')
    Requirements = @{
        MinPowerShell = "5.1"
        RecommendedPowerShell = "7.4"
        MinMemory = "4GB"
        RecommendedMemory = "16GB"
        MinDisk = "50GB"
        RecommendedDisk = "500GB"
    }
}

# Core deployment functions
function Deploy-Velociraptor {
    <#
    .SYNOPSIS
        Universal Velociraptor deployment function with intelligent deployment type detection.
    
    .DESCRIPTION
        This is the main entry point for Velociraptor deployments. It automatically detects
        the best deployment strategy based on the environment and parameters provided.
    
    .PARAMETER DeploymentType
        Type of deployment: Standalone, Server, Cluster, Cloud, Serverless, HPC, or Edge.
    
    .PARAMETER CloudProvider
        Target cloud provider: AWS, Azure, GCP, or MultiCloud.
    
    .PARAMETER AutoDetect
        Automatically detect the best deployment type based on environment.
    
    .EXAMPLE
        Deploy-Velociraptor -DeploymentType Standalone
    
    .EXAMPLE
        Deploy-Velociraptor -DeploymentType Cloud -CloudProvider AWS
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('Standalone', 'Server', 'Cluster', 'Cloud', 'Serverless', 'HPC', 'Edge', 'Auto')]
        [string]$DeploymentType = 'Auto',
        
        [ValidateSet('AWS', 'Azure', 'GCP', 'MultiCloud')]
        [string]$CloudProvider,
        
        [switch]$AutoDetect
    )
    
    Write-Host "🚀 Velociraptor Setup Scripts v$script:ModuleVersion" -ForegroundColor Cyan
    Write-Host "Phase $script:Phase: $script:PhaseName" -ForegroundColor Green
    Write-Host ""
    
    if ($DeploymentType -eq 'Auto' -or $AutoDetect) {
        $DeploymentType = Get-RecommendedDeploymentType
        Write-Host "🎯 Auto-detected deployment type: $DeploymentType" -ForegroundColor Yellow
    }
    
    switch ($DeploymentType) {
        'Standalone' {
            & "$PSScriptRoot\Deploy_Velociraptor_Standalone.ps1"
        }
        'Server' {
            & "$PSScriptRoot\Deploy_Velociraptor_Server.ps1"
        }
        'Cloud' {
            if (-not $CloudProvider) {
                $CloudProvider = Get-RecommendedCloudProvider
            }
            Deploy-CloudVelociraptor -CloudProvider $CloudProvider
        }
        'Serverless' {
            Deploy-VelociraptorServerless -CloudProvider $CloudProvider
        }
        'HPC' {
            Enable-VelociraptorHPC
        }
        'Edge' {
            Deploy-VelociraptorEdge
        }
        default {
            Write-Error "Unknown deployment type: $DeploymentType"
        }
    }
}

function Get-VelociraptorSetupInfo {
    <#
    .SYNOPSIS
        Gets information about the Velociraptor Setup Scripts module.
    
    .DESCRIPTION
        Returns detailed information about the current module version, features, and capabilities.
    
    .EXAMPLE
        Get-VelociraptorSetupInfo
    #>
    return $VelociraptorSetupInfo
}

function Test-VelociraptorSetupEnvironment {
    <#
    .SYNOPSIS
        Tests the environment for Velociraptor deployment readiness.
    
    .DESCRIPTION
        Performs comprehensive environment validation including PowerShell version,
        required modules, cloud CLI tools, and system resources.
    
    .EXAMPLE
        Test-VelociraptorSetupEnvironment
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "🔍 Testing Velociraptor Setup Environment..." -ForegroundColor Cyan
    
    $results = @{
        PowerShellVersion = $true
        RequiredModules = $true
        CloudCLIs = $true
        SystemResources = $true
        NetworkConnectivity = $true
        Overall = $true
    }
    
    # Test PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -lt 5 -or ($psVersion.Major -eq 5 -and $psVersion.Minor -lt 1)) {
        Write-Warning "PowerShell version $psVersion is below minimum requirement (5.1)"
        $results.PowerShellVersion = $false
        $results.Overall = $false
    } else {
        Write-Host "✅ PowerShell version: $psVersion" -ForegroundColor Green
    }
    
    # Test system resources
    $memory = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty TotalPhysicalMemory
    $memoryGB = [Math]::Round($memory / 1GB, 2)
    
    if ($memoryGB -lt 4) {
        Write-Warning "System memory ($memoryGB GB) is below minimum requirement (4GB)"
        $results.SystemResources = $false
        $results.Overall = $false
    } else {
        Write-Host "✅ System memory: $memoryGB GB" -ForegroundColor Green
    }
    
    # Test network connectivity
    try {
        $null = Test-NetConnection -ComputerName "github.com" -Port 443 -InformationLevel Quiet
        Write-Host "✅ Network connectivity: Available" -ForegroundColor Green
    } catch {
        Write-Warning "Network connectivity test failed"
        $results.NetworkConnectivity = $false
        $results.Overall = $false
    }
    
    return $results
}

function Get-RecommendedDeploymentType {
    <#
    .SYNOPSIS
        Analyzes the environment and recommends the best deployment type.
    #>
    # Simple logic for demonstration - can be enhanced with more sophisticated detection
    $memory = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty TotalPhysicalMemory
    $memoryGB = [Math]::Round($memory / 1GB, 2)
    
    if ($memoryGB -ge 32) {
        return 'HPC'
    } elseif ($memoryGB -ge 16) {
        return 'Server'
    } elseif (Get-Command docker -ErrorAction SilentlyContinue) {
        return 'Cloud'
    } else {
        return 'Standalone'
    }
}

function Get-RecommendedCloudProvider {
    <#
    .SYNOPSIS
        Recommends a cloud provider based on available CLI tools.
    #>
    if (Get-Command aws -ErrorAction SilentlyContinue) {
        return 'AWS'
    } elseif (Get-Command az -ErrorAction SilentlyContinue) {
        return 'Azure'
    } elseif (Get-Command gcloud -ErrorAction SilentlyContinue) {
        return 'GCP'
    } else {
        return 'AWS'  # Default recommendation
    }
}

function Deploy-CloudVelociraptor {
    <#
    .SYNOPSIS
        Deploys Velociraptor to cloud infrastructure.
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet('AWS', 'Azure', 'GCP')]
        [string]$CloudProvider
    )
    
    switch ($CloudProvider) {
        'AWS' {
            & "$PSScriptRoot\cloud\aws\Deploy-VelociraptorAWS.ps1"
        }
        'Azure' {
            & "$PSScriptRoot\cloud\azure\Deploy-VelociraptorAzure.ps1"
        }
        'GCP' {
            Write-Host "GCP deployment coming in future release" -ForegroundColor Yellow
        }
    }
}

# Aliases for convenience
Set-Alias -Name vr-deploy -Value Deploy-Velociraptor
Set-Alias -Name vr-info -Value Get-VelociraptorSetupInfo
Set-Alias -Name vr-test -Value Test-VelociraptorSetupEnvironment

# Module startup message
Write-Host "✅ Velociraptor Setup Scripts v$script:ModuleVersion loaded successfully!" -ForegroundColor Green
Write-Host "📚 Use 'Get-VelociraptorSetupInfo' for module information" -ForegroundColor Cyan
Write-Host "🚀 Use 'Deploy-Velociraptor' to start deployment" -ForegroundColor Cyan
Write-Host ""

# Export functions and aliases
Export-ModuleMember -Function @(
    'Deploy-Velociraptor',
    'Get-VelociraptorSetupInfo', 
    'Test-VelociraptorSetupEnvironment',
    'Deploy-CloudVelociraptor'
) -Alias @(
    'vr-deploy',
    'vr-info', 
    'vr-test'
)

