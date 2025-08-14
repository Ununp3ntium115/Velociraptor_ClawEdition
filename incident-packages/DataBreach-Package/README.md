# Data breach investigation and forensics Package

## Overview
This package contains a specialized Velociraptor deployment for data breach investigation and forensics scenarios.

## Contents
- **Velociraptor Core**: Main DFIR platform
- **Specialized Artifacts**: 14 artifacts optimized for this scenario
- **Required Tools**: 5 integrated tools
- **Configuration**: Pre-configured for optimal performance

## Quick Start
```powershell
# Deploy the package
.\Deploy-DataBreach.ps1 -InstallDir "C:\Velociraptor" -Offline

# Or use the GUI
.\gui\VelociraptorGUI.ps1
```

## Included Artifacts
- Windows.EventLogs.Hayabusa
- Windows.Forensics.UserAccessLogs
- Windows.Registry.RecentDocs
- Windows.Applications.Chrome.History
- Windows.Applications.Edge.History
- Windows.System.LoggedInUsers
- Windows.EventLogs.Authentication
- Windows.Forensics.NTFS.MFT
- Windows.Forensics.USN
- Windows.Network.NetstatEnriched
- Windows.System.Handles
- Windows.Forensics.Jumplists
- Windows.System.Powershell.PSReadline
- Windows.Forensics.FileCopy


## Included Tools
- Hayabusa
- LECmd
- JLECmd
- FTKImager
- LastActivityView


## Requirements
- PowerShell 5.1 or later
- Windows 10 or later
- 4GB RAM minimum
- 10GB disk space

## Support
For support and documentation, visit the main repository.
