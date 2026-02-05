# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Terminology (IMPORTANT)

| Term | Description |
|------|-------------|
| **Velociraptor** | The official [Velocidex Velociraptor](https://www.velocidex.com/) DFIR binary/tool |
| **Velociraptor binary** | The executable (`velociraptor.exe` / `velociraptor`) from Velocidex |
| **Velociraptor Claw Edition** | **THIS PROJECT** - deployment/management platform for Velociraptor |
| **Claw Edition** | Short form of "Velociraptor Claw Edition" (this project) |
| **Claw Edition GUI** | The desktop applications (Electron/SwiftUI) from this project |

> **CRITICAL**: When writing code or documentation, always distinguish between the Velociraptor binary (external dependency) and Velociraptor Claw Edition (this project).

## Repository Overview

**Velociraptor Claw Edition** - A comprehensive PowerShell and Electron framework for deploying, managing, and automating the [Velociraptor DFIR platform](https://www.velocidex.com/). Provides production-ready scripts, GUI applications (WinForms + Electron + native SwiftUI), expert agent systems, MCP server integration, and extensive testing frameworks for enterprise incident response.

This project **does not replace** the Velociraptor binary - it provides tools to deploy, configure, and manage Velociraptor installations.

**Status**: v1.0.0-alpha | **Platforms**: Windows PowerShell 5.1+, PowerShell Core 7+, Node.js 18+, macOS 14+ | **QA**: 87.5% pass rate

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        UNIFIED DFIR PLATFORM                            │
├─────────────────┬─────────────────┬─────────────────┬───────────────────┤
│   COMPONENT 1   │   COMPONENT 2   │   COMPONENT 3   │    COMPONENT 4    │
│   PowerShell    │  Electron GUI   │  Offline Worker │  Tool Integration │
│   GUIs/Scripts  │  (Cross-plat)   │  (Portable IR)  │  (25+ DFIR Tools) │
│   (WinForms)    │  (Node.js)      │  (USB/ISO/MSI)  │                   │
└─────────────────┴─────────────────┴─────────────────┴───────────────────┘
```

### Core Components
1. **PowerShell GUIs**: Windows Forms-based scripts for Velociraptor management (`Velociraptor-MASTER-Installer.ps1`)
2. **Electron Platform**: Cross-platform Node.js GUI with PowerShell bridge (`VelociraptorPlatform-Electron/`)
3. **Offline Worker**: Portable IR toolkit for air-gapped scenarios (USB/ISO/MSI/Portable)
4. **Tool Integration**: 25+ DFIR tools (Volatility3, YARA, Chainsaw, WinPmem, etc.)
5. **lib/ Modules**: Core PowerShell modules (`VelociraptorDeployment.psm1`, `ArtifactManager.psm1`, etc.)

### Key Architectural Patterns
- **Safe Dispatcher Pattern**: `Invoke-IfExists` prevents crashes when functions are missing
- **Test Mode Safety**: All scripts support `-TestMode` to prevent actual deployments
- **PowerShell Bridge**: Electron ↔ PowerShell communication via `powershell-bridge-native.js`
- **Offline-First Design**: All components work without network connectivity

## Common Development Commands

### PowerShell GUI Applications
```powershell
# Unified Platform GUI (primary entry point)
.\VelociraptorUnified-Platform\VelociraptorUltimate-UNIFIED.ps1

# Master installer with lib/ modules
.\Velociraptor-MASTER-Installer.ps1

# Launch in test mode (no admin required, no actual deployment)
.\VelociraptorUnified-Platform\VelociraptorUltimate-UNIFIED.ps1 -TestMode

# Deployment center GUI
.\Velociraptor-Deployment-Center.ps1
```

### Electron Platform (Cross-Platform GUI)
```bash
cd VelociraptorPlatform-Electron

# Install dependencies
npm install

# Run Electron app
npm start                    # Production mode
npm run dev                  # Development mode

# Lint and fix
npm run lint                 # Check for issues
npm run lint:fix             # Auto-fix issues

# Testing
npm test                     # Basic app test
npm run test:ua              # User acceptance tests
npm run test:ua:full         # Full UA suite
npm run test:tools           # Tool deployment verification
npm run test:interactions    # User interaction tests
npm run test:all             # Run all tests
npm run test:macos-complete  # macOS complete test suite

# QA Suites
npm run qa:quick             # Quick QA (lint + security + test)
npm run qa:full              # Full QA suite

# Security
npm run security:scan        # Full security audit
npm run security:deps        # npm audit dependencies

# Build packages
npm run package:mac          # macOS DMG/ZIP
npm run package:win          # Windows NSIS/MSI/Portable
npm run package:linux        # Linux AppImage/DEB/RPM
npm run package:all          # All platforms

# Cleanup
npm run cleanup              # Clean test artifacts
npm run cleanup:full         # Full cleanup with force
```

### Deployment Operations
```powershell
# Deploy Velociraptor standalone (PROVEN WORKING with admin rights)
.\Velociraptor_Setup_Scripts\Deploy_Velociraptor_Standalone.ps1

# Deploy Velociraptor server
.\Velociraptor_Setup_Scripts\Deploy_Velociraptor_Server.ps1

# Get package from local repository (smart auto-detection)
.\Get-LocalVelociraptorPackage.ps1 -Destination "C:\tools\velociraptor.exe"

# Download/update packages from GitHub
.\Download-VelociraptorPackages.ps1 -WindowsOnly
```

### PowerShell Testing
```powershell
# Run comprehensive QA suite (24 tests)
.\Run-CompleteQA-Suite.ps1

# Run UA validation suite (8 real scenarios)
.\Run-RealUA-Suite.ps1

# Test actual PowerShell GUI functionality
.\Test-ActualPowerShellGUI.ps1 -GUIScriptPath ".\path\to\script.ps1"

# Safe GUI tests with exception handling
.\Run-SafeGUITests.ps1
```

### Agent System (8 Specialized Agents)
```powershell
.\agents\Agent-QA.ps1 -AnalyzeGaps          # QA analysis
.\agents\Agent-Security.ps1 -RunAudit        # Security audit
.\agents\Agent-MSI.ps1 -BuildInstaller       # MSI build
.\agents\Agent-UA.ps1                        # User acceptance
.\agents\Agent-Electron.ps1                  # Electron platform
.\agents\Agent-Integration.ps1               # Integration tests
```

## Critical Files and Their Purpose

### Production Scripts (PowerShell)
| File | Purpose |
|------|---------|
| `VelociraptorUnified-Platform/VelociraptorUltimate-UNIFIED.ps1` | Primary unified GUI |
| `Velociraptor-MASTER-Installer.ps1` | Master installer with lib/ modules |
| `Velociraptor_Setup_Scripts/Deploy_Velociraptor_Standalone.ps1` | Standalone deployment |
| `Velociraptor-Deployment-Center.ps1` | Professional deployment GUI |
| `Get-LocalVelociraptorPackage.ps1` | Smart package selector |

### Electron Platform (Node.js)
| File | Purpose |
|------|---------|
| `VelociraptorPlatform-Electron/electron.js` | Main Electron entry point |
| `VelociraptorPlatform-Electron/backend/powershell-bridge-native.js` | PowerShell bridge (recommended) |
| `VelociraptorPlatform-Electron/test/ua-test-suite.js` | UA test suite |
| `VelociraptorPlatform-Electron/test/tool-deployment-verification.js` | Tool verification |

### lib/ Core Modules
| File | Purpose |
|------|---------|
| `lib/VelociraptorDeployment.psm1` | Core deployment functions |
| `lib/ArtifactManager.psm1` | Artifact collection management |
| `lib/ThirdPartyPackageManager.psm1` | DFIR tool management |
| `lib/ToolInstallation.psm1` | Tool installation automation |
| `lib/UltraVerboseLogger.psm1` | Comprehensive logging |

### Testing Infrastructure
| File | Purpose |
|------|---------|
| `Run-CompleteQA-Suite.ps1` | Master QA orchestrator (24 tests) |
| `Run-RealUA-Suite.ps1` | UA validation (8 scenarios) |
| `Test-ActualPowerShellGUI.ps1` | Direct GUI testing framework |
| `VelociraptorPlatform-Electron/test/` | Electron test suite |

### Steering Documentation
| File | Purpose |
|------|---------|
| `.kiro/steering/INDEX.md` | Quick navigation and current state |
| `.kiro/steering/tech.md` | Technology stack reference |
| `.kiro/steering/testing.md` | Testing approach and guidelines |

## Development Workflow

### PowerShell GUI Changes
1. Review current implementation in target script
2. Use safe dispatcher pattern: `Invoke-IfExists` for new functions
3. Test in isolation: `.\Test-ActualPowerShellGUI.ps1 -GUIScriptPath "path\to\script.ps1"`
4. Run QA suite: `.\Run-CompleteQA-Suite.ps1`

### Electron Platform Changes
1. Make changes in `VelociraptorPlatform-Electron/`
2. Run lint: `npm run lint:fix`
3. Test: `npm run test:all`
4. Security check: `npm run security:scan`

### Testing Philosophy
- **Always test in TestMode first** - prevents accidental production deployments
- **Run lint before commits** - `npm run lint:fix` for Electron, PSScriptAnalyzer for PowerShell
- **Use offline testing** when possible - faster and more reliable

## Common Parameters Across Scripts

| Parameter | Description |
|-----------|-------------|
| `-TestMode` | Run without actual deployment/changes (safety mode) |
| `-Force` | Override safety checks (use cautiously) |
| `-VelociraptorPath` | Custom path to binary (default: `C:\tools\velociraptor.exe`) |
| `-Port` | GUI port (default: 8889) |
| `-Verbose` | Detailed logging output |

## Error Handling Patterns

### Safe Function Invocation (PowerShell)
```powershell
function Invoke-IfExists {
    param($FunctionName, $Arguments = @{})
    if (Get-Command $FunctionName -ErrorAction SilentlyContinue) {
        & $FunctionName @Arguments
    } else {
        Write-Warning "Function $FunctionName not found"
    }
}
```

### PowerShell Bridge (Electron)
The Electron app uses a native child_process bridge to execute PowerShell:
- **Recommended**: `backend/powershell-bridge-native.js` (zero dependencies, best performance)
- **Alternatives**: `powershell-bridge-v5.js` (node-powershell) or `powershell-bridge-ionica.js`
- See `VelociraptorPlatform-Electron/START-HERE.md` for bridge documentation

## Velociraptor Binary Management

> **Note**: The "Velociraptor binary" refers to the official Velocidex executable, NOT Claw Edition code.

### Local Package Repository (Velociraptor Binaries)
- **Location**: `velociraptor-packages/` (1.1GB)
- **30 Windows binaries**: Official Velociraptor EXE files (v0.75.1-v0.75.4)
- **8 MSI installers**: Enterprise deployment packages
- **Package map**: `package-map-v0.75.json` with SHA-256 hashes

### Default Velociraptor Binary Locations
- **Windows**: `C:\tools\velociraptor.exe` or detected via PATH
- **macOS**: `velociraptor-v0.75.3-darwin-amd64` in project root
- **Tool repository**: `tools-repository/` for offline DFIR tool packages
- **Electron tools**: `VelociraptorPlatform-Electron/tools/`

### Claw Edition Components (This Project)
- **Electron GUI**: `VelociraptorPlatform-Electron/`
- **macOS Native App**: `apps/macos-app/` (SwiftUI)
- **PowerShell GUIs**: `VelociraptorUnified-Platform/`
- **Deployment Scripts**: `Velociraptor_Setup_Scripts/`

## Directory Structure

```
Velociraptor_scripts/
├── VelociraptorPlatform-Electron/  # Cross-platform Electron GUI
│   ├── electron.js                 # Main entry point
│   ├── backend/                    # PowerShell bridges
│   ├── test/                       # UA and integration tests
│   └── tools/                      # DFIR tools manifest
├── VelociraptorUnified-Platform/   # PowerShell unified platform
│   ├── VelociraptorUltimate-UNIFIED.ps1
│   └── installer/                  # WiX v4 MSI build
├── Velociraptor_Setup_Scripts/     # Core deployment scripts
├── lib/                            # Core PowerShell modules
├── agents/                         # 8 specialized agents
├── velociraptor-packages/          # 1.1GB package repository
├── .kiro/steering/                 # Architecture documentation
└── test-results/                   # Test outputs and reports
```

## Important Notes

- **Two GUI systems**: PowerShell WinForms (Windows-only) and Electron (cross-platform)
- **PowerShell Core**: Use `pwsh` for cross-platform, `powershell` for Windows 5.1
- **Administrator privileges**: Required for production deployments on Windows
- **Test mode**: Always use `-TestMode` during development
- **Velociraptor binary**: macOS uses `velociraptor-v0.75.3-darwin-amd64` in project root
