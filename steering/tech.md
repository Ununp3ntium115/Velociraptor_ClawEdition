# Technology Stack & Build System

## Core Technologies
- **Primary Language**: PowerShell 5.1+ and PowerShell Core 7.0+
- **Module System**: PowerShell modules with manifest files (.psd1) and script modules (.psm1)
- **GUI Framework**: Windows Forms for desktop interfaces
- **Configuration**: YAML and JSON for configuration management
- **Testing**: Pester framework for unit and integration testing
- **Code Quality**: PSScriptAnalyzer for static analysis

## Architecture Patterns
- **Modular Design**: Core functionality in VelociraptorDeployment module with nested modules
- **Cross-Platform**: Platform-specific implementations with auto-detection
- **Cloud-Native**: Multi-cloud deployment templates and serverless architectures
- **Container-First**: Docker and Kubernetes support with Helm charts

## Build & Development Commands

### Testing
```powershell
# Run all tests
.\tests\Run-Tests.ps1

# Run specific test types
.\tests\Run-Tests.ps1 -TestType Unit
.\tests\Run-Tests.ps1 -TestType Integration -OutputFormat NUnitXml

# Code quality checks
.\scripts\Test-CodeQuality.ps1
.\scripts\Test-CodeQuality.ps1 -Path "scripts" -Fix
```

### Package Management
```powershell
# Install from PowerShell Gallery
Install-Module VelociraptorSetupScripts -AllowPrerelease

# Local development setup
Import-Module .\VelociraptorSetupScripts.psm1 -Force
```

### Deployment Testing
```powershell
# Quick deployment test
.\Deploy_Velociraptor_Standalone.ps1

# GUI configuration wizard
.\gui\VelociraptorGUI.ps1

# Health checks
Test-VelociraptorHealth -ConfigPath "server.yaml"
```

## Cloud & Container Commands

### Container Deployment
```bash
# Kubernetes with Helm
helm install velociraptor ./containers/kubernetes/helm

# Docker deployment
docker build -f containers/docker/Dockerfile .
```

### Cloud Deployment
```powershell
# Multi-cloud deployment
.\cloud\aws\Deploy-VelociraptorAWS.ps1 -DeploymentType HighAvailability
.\cloud\azure\Deploy-VelociraptorAzure.ps1 -DeploymentType HighAvailability
```

## Dependencies
- **Required**: PowerShell 5.1+, .NET Framework 4.7.2+ (Windows) or .NET Core (cross-platform)
- **Testing**: Pester 5.0+, PSScriptAnalyzer
- **Optional**: Docker, Kubernetes, Helm, AWS CLI, Azure CLI, Google Cloud SDK
- **GUI**: Windows Forms assemblies (System.Windows.Forms, System.Drawing)