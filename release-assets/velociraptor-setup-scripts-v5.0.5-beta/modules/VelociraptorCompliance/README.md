# Velociraptor Compliance Framework

## Overview

The Velociraptor Compliance Framework is an enterprise-grade compliance automation system designed specifically for Velociraptor DFIR (Digital Forensics and Incident Response) infrastructure. This framework provides comprehensive compliance capabilities for multiple regulatory standards while maintaining the project's mission of democratizing professional-grade DFIR tools.

## Supported Compliance Frameworks

### Primary Frameworks
- **FedRAMP** (Federal Risk and Authorization Management Program)
  - Low, Moderate, and High authorization levels
  - 800+ security controls from NIST SP 800-53
  - Continuous monitoring and annual assessments

- **SOC 2** (System and Organization Controls 2)
  - All Trust Service Categories (Security, Availability, Processing Integrity, Confidentiality, Privacy)
  - Type I and Type II examination support
  - Quarterly compliance reviews

- **ISO 27001:2013** (Information Security Management System)
  - Complete Annex A control set (114 controls)
  - ISMS scope definition and management review
  - Continual improvement processes

### Additional Frameworks
- **NIST Cybersecurity Framework** (Identify, Protect, Detect, Respond, Recover)
- **HIPAA Security Rule** (Administrative, Physical, Technical safeguards)
- **PCI-DSS** (Payment Card Industry Data Security Standard)
- **GDPR** (General Data Protection Regulation)

## Key Features

### 🛡️ Automated Compliance Assessment
- Comprehensive control testing across all supported frameworks
- Real-time compliance scoring with detailed gap analysis
- Evidence collection with forensic integrity
- Multiple report formats (HTML, JSON, XML, CSV)

### 📊 Continuous Monitoring
- Real-time compliance monitoring with configurable intervals
- Automated alerting for compliance violations
- Trend analysis and compliance score tracking
- Integration with existing SIEM and monitoring systems

### 🔍 Forensic-Grade Audit Trails
- Tamper-evident audit logging with cryptographic integrity
- Chain of custody tracking for evidence admissibility
- Non-repudiation through digital signatures
- Comprehensive audit log analysis and reporting

### 📋 Evidence Management
- Automated evidence collection and packaging
- Cryptographic integrity verification (SHA-256)
- Evidence export/import for external auditors
- Chain of custody documentation

### 🎯 Risk Management
- Automated risk assessment and gap analysis
- Prioritized remediation recommendations
- Risk register management and tracking
- Mitigation strategy development

## Installation

### Prerequisites
- PowerShell 5.1 or later (Windows PowerShell or PowerShell Core)
- Administrator privileges for system-level compliance controls
- VelociraptorDeployment module (automatically installed)

### Installation Steps

1. **Import the Module**
   ```powershell
   Import-Module .\modules\VelociraptorCompliance\VelociraptorCompliance.psm1
   ```

2. **Verify Installation**
   ```powershell
   Get-Module VelociraptorCompliance
   ```

## Quick Start Guide

### 1. Initialize Compliance Framework

```powershell
# Initialize FedRAMP Moderate compliance
$orgInfo = @{
    Name = "Your Organization"
    Industry = "Technology"
    ComplianceOfficer = "Jane Doe"
    Contact = "compliance@example.com"
}

Initialize-VelociraptorCompliance -Framework "FedRAMP" -ComplianceLevel "Moderate" -OrganizationInfo $orgInfo
```

### 2. Run Compliance Assessment

```powershell
# Comprehensive compliance assessment
$assessment = Test-VelociraptorCompliance -Framework "FedRAMP" -ConfigPath "server.config.yaml" -GenerateEvidence

# Display results
Write-Host "Compliance Score: $($assessment.ComplianceScore)%"
Write-Host "Passed Controls: $($assessment.PassedControls)/$($assessment.TotalControls)"
```

### 3. Enable Continuous Monitoring

```powershell
# Enable continuous monitoring with 30-minute intervals
Enable-VelociraptorComplianceMonitoring -Framework "FedRAMP" -MonitoringInterval 30 -AlertThreshold 95
```

### 4. Generate Compliance Report

```powershell
# Generate HTML compliance report
Export-ComplianceReport -AssessmentResults $assessment -OutputPath "compliance-report.html" -Format "HTML"
```

## Advanced Usage

### Framework-Specific Testing

```powershell
# FedRAMP High authorization level
Test-VelociraptorFedRAMP -AuthorizationLevel "High" -ConfigPath "server.config.yaml"

# SOC 2 with specific Trust Service Categories
Test-VelociraptorSOC2 -TrustServiceCategories @("Security", "Availability") -GenerateEvidence

# ISO 27001 with specific control objectives
Test-VelociraptorISO27001 -ControlObjectives @("A.5", "A.9", "A.12") -GenerateEvidence
```

### Continuous Monitoring Management

```powershell
# Set custom thresholds
Set-VelociraptorComplianceThresholds -Framework "FedRAMP" -AlertThreshold 98 -CriticalThreshold 85

# Check monitoring status
Get-VelociraptorComplianceStatus -Framework "FedRAMP"

# Get recent alerts
Get-VelociraptorComplianceAlerts -Framework "FedRAMP" -AlertLevel "Critical" -DateRange 7
```

### Evidence Management

```powershell
# Export evidence for external audit
$evidence = $assessment.Evidence
Export-VelociraptorComplianceEvidence -Evidence $evidence -OutputPath ".\evidence-export" -IncludeSystemInfo

# Import evidence package
$importedEvidence = Import-VelociraptorComplianceEvidence -EvidencePackagePath "evidence.json" -VerifyIntegrity
```

## Integration with Velociraptor Deployment

### Compliance-Integrated Deployment

```powershell
# Deploy Velociraptor with integrated compliance
.\Deploy_Velociraptor_WithCompliance.ps1 -ComplianceFramework "FedRAMP" -ComplianceLevel "Moderate" -EnableContinuousMonitoring -GenerateComplianceReport
```

### Existing Deployment Enhancement

```powershell
# Add compliance to existing deployment
Initialize-VelociraptorCompliance -Framework "SOC2" -OrganizationInfo $orgInfo
Test-VelociraptorCompliance -Framework "SOC2" -ConfigPath "existing-config.yaml"
```

## Configuration

### Compliance Configuration Template

The framework includes a comprehensive configuration template (`compliance-configuration.yaml`) covering:

- General compliance settings
- Access control and authentication
- Network security and communications
- System monitoring and logging
- Incident response and recovery
- Configuration management
- Risk management
- Business continuity
- Data protection and privacy
- Vulnerability management

### Framework-Specific Controls

Each framework includes detailed control mappings:

- **FedRAMP**: Complete NIST SP 800-53 control set with authorization level mapping
- **SOC 2**: Trust Service Criteria with control objectives
- **ISO 27001**: Annex A controls with implementation guidance

## Monitoring and Alerting

### Alert Levels
- **Critical**: Compliance score < 70%
- **High**: Compliance score 70-84%
- **Medium**: Compliance score 85-94%
- **Low**: Compliance score 95-99%

### Monitoring Features
- Configurable monitoring intervals (1-1440 minutes)
- Real-time compliance scoring
- Automated alert generation
- Email notification support
- Dashboard integration

## Reporting

### Report Formats
- **HTML**: Executive-friendly dashboard with visualizations
- **JSON**: Machine-readable format for integration
- **XML**: Structured data for enterprise systems
- **CSV**: Tabular format for analysis

### Report Contents
- Executive summary with compliance score
- Detailed control assessment results
- Failed controls with findings
- Evidence collection summary
- Prioritized remediation recommendations

## Security and Forensic Integrity

### Audit Trail Features
- Tamper-evident logging with cryptographic hashes
- Chain of custody tracking
- Non-repudiation through digital signatures
- Comprehensive audit log retention

### Evidence Management
- Forensic-grade evidence collection
- SHA-256 integrity verification
- Encrypted evidence packages
- Chain of custody documentation

## API Reference

### Core Functions

#### `Initialize-VelociraptorCompliance`
Initializes compliance framework with organization information and baseline configuration.

#### `Test-VelociraptorCompliance`
Performs comprehensive compliance assessment against specified framework requirements.

#### `Enable-VelociraptorComplianceMonitoring`
Enables continuous compliance monitoring with configurable intervals and thresholds.

### Framework-Specific Functions
- `Test-VelociraptorFedRAMP`
- `Test-VelociraptorSOC2`
- `Test-VelociraptorISO27001`
- `Test-VelociraptorNIST`
- `Test-VelociraptorHIPAA`
- `Test-VelociraptorPCIDSS`
- `Test-VelociraptorGDPR`

### Monitoring Functions
- `Start-VelociraptorComplianceMonitor`
- `Stop-VelociraptorComplianceMonitor`
- `Get-VelociraptorComplianceAlerts`
- `Get-VelociraptorComplianceStatus`
- `Set-VelociraptorComplianceThresholds`

### Evidence Functions
- `New-ComplianceEvidence`
- `Export-VelociraptorComplianceEvidence`
- `Import-VelociraptorComplianceEvidence`

## Best Practices

### 1. Initial Setup
- Complete organization information during initialization
- Review and customize compliance configuration template
- Establish baseline compliance score before production

### 2. Ongoing Operations
- Schedule regular compliance assessments (monthly minimum)
- Monitor compliance dashboard daily
- Address failed controls promptly
- Maintain evidence packages for audits

### 3. Audit Preparation
- Export comprehensive evidence packages
- Generate executive compliance reports
- Review chain of custody documentation
- Prepare remediation plans for gaps

### 4. Continuous Improvement
- Analyze compliance trends over time
- Implement automated remediation where possible
- Regular review of compliance thresholds
- Update controls based on framework changes

## Troubleshooting

### Common Issues

#### Module Import Errors
```powershell
# Ensure VelociraptorDeployment module is available
Import-Module VelociraptorDeployment -Force
Import-Module VelociraptorCompliance -Force
```

#### Permission Issues
```powershell
# Verify administrator privileges
Test-VelociraptorAdminPrivileges
```

#### Configuration Path Issues
```powershell
# Verify configuration file exists
Test-Path "server.config.yaml"
```

### Debug Mode
```powershell
# Enable verbose logging
$VerbosePreference = "Continue"
$DebugPreference = "Continue"
```

## Support and Contributing

### Support
- GitHub Issues: [Velociraptor Setup Scripts Issues](https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts/issues)
- Documentation: [Project Wiki](https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts/wiki)
- Community: [Velociraptor Community](https://www.velocidex.com/)

### Contributing
1. Fork the repository
2. Create feature branch
3. Implement compliance enhancements
4. Add comprehensive tests
5. Submit pull request

### Compliance Framework Extensions
The framework is designed for extensibility. To add new compliance frameworks:

1. Create control templates in `templates/` directory
2. Implement framework-specific test functions
3. Add control mappings for Velociraptor components
4. Update module exports and documentation

## License

This project is licensed under the same terms as the main Velociraptor Setup Scripts project. See [LICENSE](../../LICENSE) for details.

## Disclaimer

This compliance framework is provided as-is for assistance with compliance efforts. Organizations are responsible for ensuring their specific compliance requirements are met. Professional compliance consulting may be required for formal compliance certification.

---

**Velociraptor Compliance Framework v1.0.0**  
*Democratizing enterprise-grade DFIR compliance for all incident responders worldwide*