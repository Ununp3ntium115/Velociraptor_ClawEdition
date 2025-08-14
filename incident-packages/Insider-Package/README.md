# Insider threat investigation Package

## Overview
This package contains a specialized Velociraptor deployment for insider threat investigation scenarios.

## Contents
- **Velociraptor Core**: Main DFIR platform
- **Specialized Artifacts**: 15 artifacts optimized for this scenario
- **Required Tools**: 4 integrated tools
- **Configuration**: Pre-configured for optimal performance

## Quick Start
```powershell
# Deploy the package
.\Deploy-Insider.ps1 -InstallDir "C:\Velociraptor" -Offline

# Or use the GUI
.\gui\VelociraptorGUI.ps1
```

## Included Artifacts
- Windows.EventLogs.Hayabusa
- Windows.Forensics.UserAccessLogs
- Windows.Registry.RecentDocs
- Windows.Forensics.Jumplists
- Windows.System.Powershell.PSReadline
- Windows.Applications.Chrome.History
- Windows.Applications.Edge.History
- Windows.System.LoggedInUsers
- Windows.EventLogs.Authentication
- Windows.Registry.UserAssist
- Windows.Forensics.Clipboard
- Windows.System.Handles
- Windows.Network.NetstatEnriched
- Windows.Forensics.NTFS.MFT
- Windows.Forensics.USN


## Included Tools
- Hayabusa
- LECmd
- JLECmd
- LastActivityView


## Requirements
- PowerShell 5.1 or later
- Windows 10 or later
- 4GB RAM minimum
- 10GB disk space

## Support
For support and documentation, visit the main repository.
