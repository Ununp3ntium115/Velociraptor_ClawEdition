# Velociraptor Setup Scripts v5.0.3-beta - Quick Start Guide

## 🚀 Get Velociraptor Running in 5 Minutes

This guide gets you from zero to a fully functional Velociraptor DFIR platform in minutes.

## 📋 Prerequisites

- **Windows System** (Windows 10/11, Server 2016+)
- **PowerShell 5.1+** (Windows PowerShell or PowerShell Core)
- **Administrator Privileges** (for service installation and firewall rules)
- **Internet Connection** (to download Velociraptor from GitHub)

## 🎯 Choose Your Installation Method

### Option 1: GUI Installation (Recommended for New Users)

**Easy point-and-click installation with real-time progress tracking**

```powershell
# Run the GUI installer
.\VelociraptorGUI-InstallClean.ps1
```

**What it does:**
- Downloads latest Velociraptor v0.74.1 (64.3 MB)
- Provides real-time installation progress
- Configurable installation and data directories
- One-click launch after installation
- Live installation logs

### Option 2: Console Installation (Fast & Automated)

**Quick command-line installation for experienced users**

```powershell
# Basic standalone installation
.\Deploy_Velociraptor_Standalone.ps1

# Custom paths and port
.\Deploy_Velociraptor_Standalone.ps1 -InstallDir "C:\MyTools" -DataStore "D:\VelociraptorData" -GuiPort 9999
```

**What it does:**
- Downloads and installs Velociraptor automatically
- Configures firewall rules
- Launches Velociraptor GUI service
- Opens web browser to interface

### Option 3: Full Server Installation (Enterprise)

**Complete server deployment with Windows service and MSI generation**

```powershell
# Run as Administrator
.\Deploy_Velociraptor_Server.ps1
```

**What it does:**
- Downloads latest Velociraptor
- Generates server configuration with SSL
- Creates Windows service (auto-start)
- Builds MSI package for client deployment
- Configures firewall for multi-client access

### Option 4: Incident Response Deployment

**Specialized deployment for active incident response**

```powershell
# Launch the incident response platform
.\IncidentResponseGUI-Installation.ps1
```

**What it does:**
- Incident-specific artifact collections
- Pre-configured for different threat types (APT, Ransomware, etc.)
- Rapid deployment for emergency response
- Specialized logging and reporting

## 🔧 Installation Examples

### Example 1: Basic GUI Installation

```powershell
# 1. Open PowerShell as Administrator
# 2. Navigate to the scripts directory
cd "C:\Path\To\Velociraptor_Setup_Scripts"

# 3. Run the GUI installer
.\VelociraptorGUI-InstallClean.ps1

# 4. Configure paths in the GUI (or use defaults)
# 5. Click "Install Velociraptor"
# 6. Watch real-time progress
# 7. Click "Launch Velociraptor" when complete
```

### Example 2: Quick Console Installation

```powershell
# Single command installation
.\Deploy_Velociraptor_Standalone.ps1

# Output:
# [Info] Starting Velociraptor Standalone deployment...
# [Success] Found Velociraptor v0.74 (64.3 MB)
# [Success] Download completed: 64.3 MB
# [Success] Velociraptor process started (PID: 12345)
# [Success] Velociraptor GUI is ready at: https://127.0.0.1:8889
```

### Example 3: Enterprise Server Setup

```powershell
# Full server deployment
.\Deploy_Velociraptor_Server.ps1

# Interactive prompts:
# - Public hostname/FQDN
# - SSO configuration (optional)
# - Firewall configuration
# - Service installation
# - MSI package generation
```

## 🌐 Accessing Velociraptor

After installation, access the web interface:

```
URL: https://127.0.0.1:8889
Default Credentials: admin / password
```

**First Time Setup:**
1. Browser will warn about self-signed certificate (this is normal)
2. Click "Advanced" → "Proceed to 127.0.0.1"
3. Login with admin/password
4. Change default password immediately
5. Create additional user accounts as needed

## 📁 Default Installation Paths

### Standalone Installation
```
Executable: C:\tools\velociraptor.exe
Data Store: C:\VelociraptorData\
Logs: %ProgramData%\VelociraptorDeploy\
```

### Server Installation
```
Executable: C:\tools\velociraptor.exe
Data Store: C:\VelociraptorServerData\
Configuration: C:\tools\server.yaml
Client MSI: C:\tools\velociraptor_client_[hostname].msi
Service: Velociraptor (Windows Service)
```

## 🔧 Common Commands

### Check Installation Status
```powershell
# Check if Velociraptor is running
Get-Process velociraptor

# Check Windows service (server installation)
Get-Service Velociraptor

# Check web interface connectivity
Test-NetConnection 127.0.0.1 -Port 8889
```

### Manual Operations
```powershell
# Start Velociraptor manually
C:\tools\velociraptor.exe gui --datastore "C:\VelociraptorData"

# Check version
C:\tools\velociraptor.exe version

# Generate configuration
C:\tools\velociraptor.exe config generate
```

## 🚨 Troubleshooting

### Common Issues

**Issue: Download fails**
```
Solution: Check internet connectivity and firewall settings
Test: Test-NetConnection api.github.com -Port 443
```

**Issue: GUI doesn't load**
```
Solution: Check if process is running and port is available
Commands: 
- Get-Process velociraptor
- Test-NetConnection 127.0.0.1 -Port 8889
```

**Issue: Permission errors**
```
Solution: Run PowerShell as Administrator
Right-click PowerShell → "Run as Administrator"
```

**Issue: Firewall blocking access**
```
Solution: Add firewall rules manually
Command: New-NetFirewallRule -DisplayName "Velociraptor" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8889
```

### Getting Help

**Installation Logs**
```
GUI Logs: Displayed in real-time within installation GUI
Console Logs: %ProgramData%\VelociraptorDeploy\
Server Logs: Windows Event Viewer → Application Logs
```

**Module Testing**
```powershell
# Test module functionality
Import-Module .\modules\VelociraptorDeployment\VelociraptorDeployment.psd1
Test-VelociraptorInternetConnection
Get-VelociraptorLatestRelease
```

## 🎯 Next Steps

After successful installation:

1. **Change Default Password**: Login and update admin credentials
2. **Configure Users**: Create user accounts for your team
3. **Deploy Agents**: Use generated MSI (server) or configure agents manually
4. **Create Collections**: Set up artifact collections for your environment
5. **Configure Monitoring**: Set up alerting and monitoring as needed

## 🔗 Additional Resources

- **Documentation**: See `CLAUDE.md` for developer guidance
- **Release Notes**: `RELEASE-NOTES-v5.0.3-beta.md` for detailed changes
- **Module Reference**: PowerShell module documentation in `modules/`
- **Configuration Examples**: Sample configurations in deployment scripts

---

**Status**: Production Ready Beta v5.0.3  
**Mission**: Free enterprise-grade DFIR for all incident responders worldwide  
**Support**: Community-driven, open-source project