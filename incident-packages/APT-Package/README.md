# Advanced Persistent Threat investigation Package

## Overview
This package contains a specialized Velociraptor deployment for advanced persistent threat investigation scenarios.

## Contents
- **Velociraptor Core**: Main DFIR platform
- **Specialized Artifacts**: 15 artifacts optimized for this scenario
- **Required Tools**: 6 integrated tools
- **Configuration**: Pre-configured for optimal performance

## Quick Start
```powershell
# Deploy the package
.\Deploy-APT.ps1 -InstallDir "C:\Velociraptor" -Offline

# Or use the GUI
.\gui\VelociraptorGUI.ps1
```

## Included Artifacts
- Windows.EventLogs.Hayabusa
- Windows.Forensics.PersistenceSniper
- Windows.Detection.Yara.Yara64
- Windows.System.Services
- Windows.Registry.NTUser
- Windows.Network.NetstatEnriched
- Windows.System.Powershell.PSReadline
- Windows.EventLogs.PowershellScriptblock
- Windows.Registry.Sysinternals.Eulacheck
- Windows.System.Handles
- Windows.Memory.ProcessInfo
- Windows.Detection.Malfind
- Windows.System.CertificateAuthorities
- Windows.Registry.RecentDocs
- Windows.Forensics.Lnk


## Included Tools
- Hayabusa
- PersistenceSniper
- YARA
- Volatility
- Capa
- DetectRaptor


## Requirements
- PowerShell 5.1 or later
- Windows 10 or later
- 4GB RAM minimum
- 10GB disk space

## Support
For support and documentation, visit the main repository.
