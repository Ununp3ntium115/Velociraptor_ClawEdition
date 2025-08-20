# Project Structure & Organization

## Root Level Structure
- **Core Scripts**: Main deployment scripts at root level (`Deploy_Velociraptor_*.ps1`)
- **Module Definition**: PowerShell module files (`VelociraptorSetupScripts.psd1`, `.psm1`)
- **Package Configuration**: `package.json` for npm-style metadata and scripts
- **Documentation**: Comprehensive markdown files for guides and roadmaps

## Key Directories

### `/modules/`
PowerShell modules with nested structure:
- `VelociraptorDeployment/` - Core deployment functionality
- `VelociraptorGovernance/` - Compliance and governance features

### `/scripts/`
Utility and automation scripts organized by function:
- `configuration-management/` - Environment and cluster management
- `cross-platform/` - Linux/macOS deployment scripts
- `monitoring/` - Health checks and performance monitoring
- `security/` - Security hardening and compliance testing

### `/gui/`
Desktop GUI applications:
- `VelociraptorGUI.ps1` - Main configuration wizard
- `IncidentResponseGUI.ps1` - Incident response interface

### `/cloud/`
Cloud provider specific deployments:
- `aws/` - Amazon Web Services templates
- `azure/` - Microsoft Azure templates

### `/containers/`
Container orchestration:
- `docker/` - Docker configurations and scripts
- `kubernetes/` - Kubernetes manifests and Helm charts

### `/tests/`
Testing framework:
- `unit/` - Unit tests for individual functions
- `integration/` - End-to-end deployment tests
- `security/` - Security and compliance validation
- `Run-Tests.ps1` - Main test runner

### `/templates/`
Configuration templates:
- `configurations/` - YAML templates for different deployment scenarios

### `/examples/`
Demonstration scripts:
- Phase-specific demo scripts showing advanced features

### `/incident-packages/`
Pre-built incident response packages:
- Scenario-specific artifact collections (APT, Ransomware, etc.)
- Each package includes artifacts, tools, and documentation

## File Naming Conventions
- **Scripts**: `Verb-Noun.ps1` (PowerShell approved verbs)
- **Modules**: `ModuleName.psm1` with matching `.psd1` manifest
- **Tests**: `Test-ComponentName.ps1` or `ComponentName.Tests.ps1`
- **Documentation**: `UPPERCASE_WITH_UNDERSCORES.md` for major docs
- **Configurations**: `lowercase-with-hyphens.yaml`

## Configuration Management
- **Environment Configs**: Stored in `/templates/configurations/`
- **User Settings**: `.kiro/settings/` for workspace-specific configuration
- **Steering Rules**: `.kiro/steering/` for AI assistant guidance
- **Runtime Data**: Temporary files in `/temp_*` directories (gitignored)

## Deployment Patterns
- **Standalone**: Single-file deployments at root level
- **Modular**: Complex deployments use `/modules/` and `/scripts/`
- **Cloud**: Provider-specific scripts in `/cloud/[provider]/`
- **Container**: Orchestration files in `/containers/[platform]/`

## Documentation Structure
- **README.md**: Comprehensive feature overview and quick start
- **ROADMAP.md**: Development phases and future plans
- **CONTRIBUTING.md**: Development guidelines and processes
- **Phase Documentation**: `PHASE[N]_*.md` for major release documentation