# Ransomware incident response and recovery Package

## Overview
This package contains a specialized Velociraptor deployment for ransomware incident response and recovery scenarios.

## Contents
- **Velociraptor Core**: Main DFIR platform
- **Specialized Artifacts**: 15 artifacts optimized for this scenario
- **Required Tools**: 5 integrated tools
- **Configuration**: Pre-configured for optimal performance

## Quick Start
```powershell
# Deploy the package
.\Deploy-Ransomware.ps1 -InstallDir "C:\Velociraptor" -Offline

# Or use the GUI
.\gui\VelociraptorGUI.ps1
```

## Included Artifacts
- Windows.EventLogs.Hayabusa
- Windows.Forensics.PersistenceSniper
- Windows.Detection.Yara.Yara64
- Windows.System.Services
- Windows.Registry.NTUser
- Windows.Forensics.Jumplists
- Windows.Timeline.Prefetch
- Windows.System.TaskScheduler
- Windows.EventLogs.RDPAuth
- Windows.Network.NetstatEnriched
- Windows.Sys.StartupItems
- Windows.Registry.BackupRestore
- Windows.Forensics.VSS
- Windows.System.Powershell.PSReadline
- Windows.Detection.BinaryRename


## Included Tools
- Hayabusa
- PersistenceSniper
- YARA
- Volatility
- FTKImager


## Requirements
- PowerShell 5.1 or later
- Windows 10 or later
- 4GB RAM minimum
- 10GB disk space

## Support
For support and documentation, visit the main repository.
