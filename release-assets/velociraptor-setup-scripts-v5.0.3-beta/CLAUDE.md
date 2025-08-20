# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the **Velociraptor Setup Scripts** repository - a free, open-source enterprise-grade automation platform for deploying Velociraptor DFIR (Digital Forensics and Incident Response) infrastructure. 

**Mission**: Democratize enterprise-grade DFIR capabilities by providing professional automation tools that are completely free for all incident responders worldwide, regardless of budget or organization size.

**Current Phase**: Phase 5 - Production Ready Release (v5.0.3-beta) with fully functional installation capabilities, GUI interfaces, and comprehensive QA testing completed.

## Core Architecture

### Main Deployment Scripts
- `Deploy_Velociraptor_Standalone.ps1` - Single-node Velociraptor deployment with proven working installation methods
- `Deploy_Velociraptor_Server.ps1` - Multi-client server architecture with MSI generation and service installation
- `VelociraptorGUI-InstallClean.ps1` - Complete installation GUI with real download functionality
- `IncidentResponseGUI-Installation.ps1` - Specialized incident response collector deployment interface

### PowerShell Module Structure
- **Primary Module**: `VelociraptorSetupScripts.psm1` (root module)
- **Core Module**: `modules/VelociraptorDeployment/VelociraptorDeployment.psm1`
- **Functions Directory**: `modules/VelociraptorDeployment/functions/` (25+ specialized functions)

### Key Components
- **Cloud Deployments**: `cloud/aws/`, `cloud/azure/` - Multi-cloud automation
- **Container Orchestration**: `containers/kubernetes/` - Helm charts and Kubernetes configs
- **Cross-Platform Scripts**: `scripts/cross-platform/` - Linux deployment support
- **Artifact Management**: Extensive artifact pack processing and tool dependency management

## Common Commands

### Testing and Quality Assurance
```powershell
# Run all tests
.\tests\Run-Tests.ps1

# Run specific test types
.\tests\Run-Tests.ps1 -TestType Unit
.\tests\Run-Tests.ps1 -TestType Integration -OutputFormat NUnitXml

# Code quality checks and fixes
.\scripts\Test-CodeQuality.ps1
.\scripts\Test-CodeQuality.ps1 -Path "scripts" -Fix

# Beta release QA
powershell -ExecutionPolicy Bypass -File COMPREHENSIVE_BETA_QA.ps1
```

### Core Deployment Operations
```powershell
# Standalone deployment
.\Deploy_Velociraptor_Standalone.ps1

# Server deployment with options
.\Deploy_Velociraptor_Server.ps1 -GuiPort 8889 -EnableSSL

# GUI configuration wizard
.\gui\VelociraptorGUI.ps1

# Health monitoring
Test-VelociraptorHealth -ConfigPath "server.yaml" -IncludePerformance
```

### Development and Validation
```powershell
# Environment validation
powershell -ExecutionPolicy Bypass -File scripts/Validate-Environment.ps1

# Artifact tool management
New-ArtifactToolManager -Action All -ArtifactPath ".\content\exchange\artifacts"

# Configuration testing
Test-VelociraptorConfiguration -ConfigPath "server.config.yaml"

# PowerShell module development
Import-Module .\VelociraptorSetupScripts.psm1 -Force
Install-Module VelociraptorSetupScripts -AllowPrerelease
```

### Cloud and Container Deployment
```powershell
# Multi-cloud deployment
.\cloud\aws\Deploy-VelociraptorAWS.ps1 -DeploymentType HighAvailability
.\cloud\azure\Deploy-VelociraptorAzure.ps1 -DeploymentType HighAvailability
```

```bash
# Kubernetes with Helm
helm install velociraptor ./containers/kubernetes/helm

# Docker deployment
docker build -f containers/docker/Dockerfile .
```

## Project Characteristics

### Technology Stack
- **Primary Language**: PowerShell (5.1+ and 7.0+ Core support)
- **Module System**: PowerShell modules with manifest files (.psd1) and script modules (.psm1)
- **GUI Framework**: Windows Forms for desktop interfaces  
- **Configuration**: YAML and JSON for configuration management
- **Testing**: Pester framework for unit and integration testing
- **Code Quality**: PSScriptAnalyzer for static analysis
- **Platforms**: Windows, Linux, macOS
- **Dependencies**: Windows Forms (GUI), Docker/Kubernetes (containers), Cloud CLIs (AWS/Azure/GCP)

### Architecture Patterns
- **Modular Design**: Core functionality in VelociraptorDeployment module with nested modules and extensive function libraries
- **Cross-Platform**: Platform-specific implementations with auto-detection
- **Cloud-Native**: Multi-cloud deployment templates and serverless architectures  
- **Container-First**: Docker and Kubernetes support with Helm charts
- **Backward Compatibility**: Aliases and compatibility layers for legacy scripts
- **Enterprise Scale**: Supports multi-cloud, serverless, HPC, and edge computing deployments

### Key Features
- **Multi-Cloud Support**: AWS, Azure, GCP with unified management and cross-cloud synchronization
- **Serverless Architecture**: Event-driven, auto-scaling functions
- **Container Orchestration**: Production Kubernetes with Helm charts
- **AI Integration**: Intelligent configuration and predictive analytics
- **Professional GUI**: Step-by-step configuration wizard with real-time validation
- **Artifact Management**: Automated tool dependency resolution and offline collector packaging
- **Security Focus**: Multiple compliance frameworks (SOX, HIPAA, PCI-DSS, GDPR)

### Target Users
- Solo incident responders and forensic analysts
- Small to large security teams
- Enterprise organizations requiring scalable DFIR infrastructure
- Government agencies needing secure, auditable deployments
- Educational institutions training the next generation of incident responders

## Development Guidelines

### Code Quality Standards
- All PowerShell scripts should use `[CmdletBinding()]` and proper parameter validation
- Error handling with `$ErrorActionPreference = 'Stop'` where appropriate
- Comprehensive logging using the `Write-VelociraptorLog` function
- Admin privilege checks using `Test-VelociraptorAdminPrivileges`

### Module Function Patterns
- Functions follow `Verb-VelociraptorNoun` naming convention
- Use the shared functions in `modules/VelociraptorDeployment/functions/`
- Import the VelociraptorDeployment module for reusable functionality

### Testing Approach
- Test scripts are located in `tests/` directory
- Integration tests for deployment scenarios
- Security baseline testing for hardened configurations
- Pester framework used for unit tests (`devDependencies.pester >= 5.0.0`)

### GUI Development
- Windows Forms-based configuration wizard
- Dark theme with Velociraptor branding
- Step-by-step wizard pattern with validation
- Safe color handling to avoid BackColor null conversion errors

## Important Considerations

### Security Notes
- This is a **defensive security tool** for DFIR operations
- Scripts require Administrator privileges for system-level operations
- Handles sensitive configuration data and certificates
- Focus on legitimate digital forensics and incident response use cases

### Version Information
- **Current Version**: 5.0.1-beta (Phase 5 - Cloud-Native & Scalability)
- **Module Version**: 5.0.1 (PowerShell module)
- **Stability**: Production-ready beta with comprehensive testing completed

### Cross-Platform Considerations
- Primary development and testing on Windows
- Linux support through PowerShell Core
- macOS support for development scenarios
- Container and cloud deployments are platform-agnostic