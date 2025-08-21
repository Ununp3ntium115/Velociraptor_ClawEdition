@{
    # Module Information
    RootModule = 'VelociraptorML.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a4c5f2e8-9b3d-4e7f-8a2c-1d6e9f7a5b4c'
    
    # Author and Company Information
    Author = 'Velociraptor Community'
    CompanyName = 'Velociraptor DFIR Platform'
    Copyright = '(c) Velociraptor Community. All rights reserved.'
    
    # Module Description
    Description = 'Machine Learning integration module for Velociraptor DFIR operations providing automated threat detection, behavioral analysis, and intelligent forensic insights.'
    
    # PowerShell Version Requirements
    PowerShellVersion = '5.1'
    
    # Required Assemblies
    RequiredAssemblies = @()
    
    # Required Modules
    RequiredModules = @(
        @{
            ModuleName = 'VelociraptorDeployment'
            ModuleVersion = '1.0.0'
        }
    )
    
    # Functions to Export
    FunctionsToExport = @(
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
    )
    
    # Cmdlets to Export
    CmdletsToExport = @()
    
    # Variables to Export
    VariablesToExport = @()
    
    # Aliases to Export
    AliasesToExport = @(
        'Start-MLThreatHunt',
        'Get-AIThreatScore',
        'Start-BehaviorAnalysis'
    )
    
    # Private Data
    PrivateData = @{
        PSData = @{
            Tags = @('Velociraptor', 'DFIR', 'MachineLearning', 'ThreatDetection', 'Forensics', 'AI', 'SecurityAnalysis')
            LicenseUri = 'https://github.com/Velocidex/velociraptor/blob/master/LICENSE'
            ProjectUri = 'https://github.com/Velocidex/velociraptor'
            ReleaseNotes = @"
# VelociraptorML Module v1.0.0
## Features
- ML-powered threat detection and behavioral analysis
- Real-time anomaly detection with explainable AI
- MITRE ATT&CK framework integration
- Threat intelligence correlation
- Forensically sound ML model implementations
- Integration with existing Velociraptor infrastructure

## ML Techniques
- Behavioral anomaly detection using isolation forests
- Network traffic classification with supervised learning
- File system pattern recognition using clustering
- Registry change analysis with time-series models
- Memory injection detection using neural networks

## Supported Platforms
- Windows (PowerShell 5.1+)
- Linux (PowerShell Core 7.0+)
- Cross-platform VQL artifact support
"@
        }
    }
}