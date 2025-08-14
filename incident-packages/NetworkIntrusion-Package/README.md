# Network-based attack investigation Package

## Overview
This package contains a specialized Velociraptor deployment for network-based attack investigation scenarios.

## Contents
- **Velociraptor Core**: Main DFIR platform
- **Specialized Artifacts**: 13 artifacts optimized for this scenario
- **Required Tools**: 4 integrated tools
- **Configuration**: Pre-configured for optimal performance

## Quick Start
```powershell
# Deploy the package
.\Deploy-NetworkIntrusion.ps1 -InstallDir "C:\Velociraptor" -Offline

# Or use the GUI
.\gui\VelociraptorGUI.ps1
```

## Included Artifacts
- Windows.Network.NetstatEnriched
- Windows.EventLogs.Hayabusa
- Windows.System.Services
- Windows.Registry.NTUser
- Windows.EventLogs.Authentication
- Windows.EventLogs.RDPAuth
- Windows.System.LoggedInUsers
- Windows.Network.ArpCache
- Windows.Network.DNSCache
- Windows.System.Handles
- Windows.Forensics.PersistenceSniper
- Windows.Detection.Yara.Yara64
- Windows.System.Powershell.PSReadline


## Included Tools
- Hayabusa
- PersistenceSniper
- YARA
- Wireshark


## Requirements
- PowerShell 5.1 or later
- Windows 10 or later
- 4GB RAM minimum
- 10GB disk space

## Support
For support and documentation, visit the main repository.
