#Requires -Version 5.1

<#
.SYNOPSIS
    VelociraptorML PowerShell Module

.DESCRIPTION
    This module provides comprehensive machine learning integration for Velociraptor DFIR operations.
    It includes automated threat detection, behavioral analysis, anomaly detection, and threat intelligence
    correlation while maintaining forensic integrity and providing explainable AI decisions.

.NOTES
    Author: Velociraptor Community
    Version: 1.0.0
    Requires: PowerShell 5.1 or higher, VelociraptorDeployment module
    
    IMPORTANT: All ML models and decisions maintain forensic integrity and provide
    explainable AI outputs suitable for legal proceedings.
#>

# Set strict mode for better error handling
Set-StrictMode -Version Latest

# Module variables
$script:ModuleRoot = $PSScriptRoot
$script:MLModelsPath = Join-Path $PSScriptRoot 'models'
$script:ThreatIntelPath = Join-Path $PSScriptRoot 'threat-intel'
$script:ConfigPath = Join-Path $PSScriptRoot 'config'
$script:LogPath = $null
$script:VerboseLogging = $false

# Create necessary directories
$directories = @($script:MLModelsPath, $script:ThreatIntelPath, $script:ConfigPath)
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
}

# Import VelociraptorDeployment module for shared functions
try {
    Import-Module VelociraptorDeployment -Force
    Write-Verbose "VelociraptorDeployment module imported successfully"
} catch {
    Write-Error "Failed to import VelociraptorDeployment module: $($_.Exception.Message)"
    throw "VelociraptorML module requires VelociraptorDeployment module"
}

# Import all function files
$functionPath = Join-Path $script:ModuleRoot 'functions'
if (Test-Path $functionPath) {
    $functionFiles = Get-ChildItem -Path $functionPath -Filter '*.ps1' -Recurse
    foreach ($file in $functionFiles) {
        try {
            . $file.FullName
            Write-Verbose "Imported ML function file: $($file.Name)"
        }
        catch {
            Write-Error "Failed to import ML function file $($file.Name): $($_.Exception.Message)"
        }
    }
} else {
    Write-Warning "Functions directory not found: $functionPath"
}

# Create backward compatibility aliases for ML operations
$aliases = @{
    'Start-MLThreatHunt' = 'Start-AutomatedThreatHunt'
    'Get-AIThreatScore' = 'Get-ThreatScore'
    'Start-BehaviorAnalysis' = 'Start-BehavioralAnalysis'
    'Get-MLAnomalies' = 'Get-AnomalyDetection'
    'Get-ThreatCorrelation' = 'Get-ThreatIntelligenceCorrelation'
}

foreach ($alias in $aliases.GetEnumerator()) {
    try {
        New-Alias -Name $alias.Key -Value $alias.Value -Force -Scope Global
        Write-Verbose "Created ML alias: $($alias.Key) -> $($alias.Value)"
    }
    catch {
        Write-Warning "Failed to create alias $($alias.Key): $($_.Exception.Message)"
    }
}

# Initialize ML configuration
Initialize-VelociraptorMLConfiguration

# Module initialization function
function Initialize-VelociraptorMLConfiguration {
    <#
    .SYNOPSIS
        Initializes the VelociraptorML module configuration
    
    .DESCRIPTION
        Sets up default ML model configurations, threat intelligence feeds,
        and forensic audit settings for the VelociraptorML module.
    #>
    
    try {
        # Create default ML configuration
        $mlConfig = @{
            ModelSettings = @{
                AnomalyDetectionThreshold = 0.7
                ClassificationConfidence = 0.8
                ClusteringMinSamples = 5
                TimeSeriesWindowSize = 100
            }
            ForensicSettings = @{
                EnableAuditLogging = $true
                MaintainChainOfCustody = $true
                GenerateExplainableReports = $true
                PreserveRawData = $true
            }
            ThreatIntelligence = @{
                MitreAttackVersion = "12.1"
                UpdateInterval = "24h"
                CorrelationThreshold = 0.6
                EnableExternalFeeds = $true
            }
            Performance = @{
                MaxMemoryUsage = "2GB"
                ParallelProcessing = $true
                CacheSize = "500MB"
                OptimizedForAccuracy = $true
            }
        }
        
        $configFile = Join-Path $script:ConfigPath 'ml-config.json'
        if (-not (Test-Path $configFile)) {
            $mlConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configFile -Encoding UTF8
            Write-Verbose "Created default ML configuration: $configFile"
        }
        
        # Initialize threat intelligence mappings
        Initialize-MitreAttackMapping
        
        Write-VelociraptorLog -Message "VelociraptorML module initialized successfully" -Level "Information"
        
    } catch {
        Write-Error "Failed to initialize VelociraptorML configuration: $($_.Exception.Message)"
        throw
    }
}

# MITRE ATT&CK initialization function
function Initialize-MitreAttackMapping {
    <#
    .SYNOPSIS
        Initializes MITRE ATT&CK framework mappings
    #>
    
    $mitreMapping = @{
        Techniques = @{
            "T1055" = @{
                Name = "Process Injection"
                Tactics = @("Defense Evasion", "Privilege Escalation")
                MLIndicators = @("memory_pattern_anomaly", "process_hollowing", "dll_injection")
            }
            "T1071" = @{
                Name = "Application Layer Protocol"
                Tactics = @("Command and Control")
                MLIndicators = @("c2_communication_pattern", "dns_tunneling", "http_anomaly")
            }
            "T1083" = @{
                Name = "File and Directory Discovery"
                Tactics = @("Discovery")
                MLIndicators = @("file_enumeration_pattern", "directory_traversal", "discovery_burst")
            }
            "T1112" = @{
                Name = "Modify Registry"
                Tactics = @("Defense Evasion")
                MLIndicators = @("registry_modification_pattern", "persistence_registry_keys", "security_bypass")
            }
            "T1057" = @{
                Name = "Process Discovery"
                Tactics = @("Discovery")
                MLIndicators = @("process_enumeration", "suspicious_tasklist", "discovery_tools")
            }
        }
    }
    
    $mitreFile = Join-Path $script:ThreatIntelPath 'mitre-attack-mapping.json'
    if (-not (Test-Path $mitreFile)) {
        $mitreMapping | ConvertTo-Json -Depth 10 | Set-Content -Path $mitreFile -Encoding UTF8
        Write-Verbose "Created MITRE ATT&CK mapping: $mitreFile"
    }
}

# Export module members
Export-ModuleMember -Function @(
    'Initialize-VelociraptorMLEngine',
    'Start-BehavioralAnalysis',
    'Start-NetworkTrafficAnalysis', 
    'Start-FileSystemAnalysis',
    'Start-RegistryAnalysis',
    'Start-MemoryAnalysis',
    'New-ThreatModel',
    'Get-ThreatScore',
    'Get-AnomalyDetection',
    'Get-ThreatIntelligenceCorrelation',
    'Get-MitreAttackMapping',
    'Export-MLModel',
    'Import-MLModel',
    'Test-ModelAccuracy',
    'Get-ExplainableAIReport',
    'Start-AutomatedThreatHunt',
    'Get-ThreatActorProfile',
    'Start-ContinuousLearning'
) -Alias @(
    'Start-MLThreatHunt',
    'Get-AIThreatScore',
    'Start-BehaviorAnalysis'
)

Write-Verbose "VelociraptorML module loaded successfully"