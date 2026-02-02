# Project Structure & Organization

**Path index**: See `docs/WORKSPACE_PATH_INDEX.md` for canonical paths (post-reorganization). Root holds only entry docs and config; no loose scripts or modules at root.

**CDIF/Steering KB index**: `steering/CDIF_KB_INDEX.md` (entrypoints + exclusions like `node_modules/` and `tests/results/`)

## Root Level Structure
- **Package Configuration**: `package.json`, `VERSION`, `.gitignore` at root
- **Entry Documentation**: `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `CLAUDE.md`
- **Top-level directories only**: `apps/`, `build/`, `cloud/`, `containers/`, `docs/`, `examples/`, `lib/`, `scripts/`, `steering/`, `tests/`, `tools/`, `archive/`

## Key Directories

### `/lib/`
PowerShell root module and nested modules:
- `VelociraptorSetupScripts.psd1`, `.psm1` - Root module
- `modules/VelociraptorDeployment/` - Core deployment functionality
- `modules/VelociraptorGovernance/` - Compliance and governance features

### `/scripts/`
Deployment and utility scripts (canonical location for Deploy_*, GUI helpers, automation):
- `Deploy_Velociraptor_Standalone.ps1`, `Deploy_Velociraptor_Server.ps1` - Main deployment
- `VelociraptorGUI-InstallClean.ps1`, `IncidentResponseGUI-*.ps1` - GUI scripts
- `configuration-management/`, `cross-platform/`, `monitoring/`, `security/` - By function

### `/apps/gui/`
Desktop GUI applications (canonical GUI source):
- `VelociraptorGUI.ps1` - Main configuration wizard
- Incident response and other GUIs also under `scripts/` (e.g. `IncidentResponseGUI-*.ps1`)

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

### `/tools/incident-packages/`
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
- **Standalone**: Run `scripts/Deploy_Velociraptor_Standalone.ps1` from repo root
- **Modular**: Complex deployments use `lib/modules/` and `scripts/`
- **Cloud**: Provider-specific scripts in `/cloud/[provider]/`
- **Container**: Orchestration files in `/containers/[platform]/`

## Documentation Structure
- **Root**: `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `CLAUDE.md`
- **docs/**: All other project docs (roadmaps, guides, gap analysis, release notes)
- **steering/**: Iteration plans, macOS implementation, gap analysis references
- **Phase Documentation**: `docs/` (e.g. PHASE[N]_*.md, ROADMAP.md)
