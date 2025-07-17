# Velociraptor Setup Scripts

A comprehensive collection of PowerShell scripts for deploying, managing, and maintaining Velociraptor digital forensics and incident response platform on Windows systems.

## 🚀 Quick Start

### Prerequisites
- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or higher
- Administrator privileges
- Internet connectivity for downloads

### Basic Deployment

**Standalone Mode (Single Machine)**
```powershell
# Download and run the standalone deployment
.\Deploy_Velociraptor_Standalone.ps1
```

**Server Mode (Multi-Client Environment)**
```powershell
# Deploy full server with client MSI generation
.\Deploy_Velociraptor_Server.ps1
```

## 📁 Script Overview

| Script | Purpose | Use Case |
|--------|---------|----------|
| `Deploy_Velociraptor_Standalone.ps1` | Single-machine GUI deployment | Testing, small environments |
| `Deploy_Velociraptor_Standalone_Improved.ps1` | Enhanced standalone with parameters | Production single-machine |
| `Deploy_Velociraptor_Server.ps1` | Full server deployment | Multi-client environments |
| `Deploy_Velociraptor_Server_Improved.ps1` | Enhanced server with modern practices | Enterprise deployments |
| `Cleanup_Velociraptor.ps1` | Complete removal tool | Uninstallation, cleanup |
| `Prepare_OfflineCollector_Env.ps1` | Offline collection environment | Air-gapped networks |

## 🔧 Detailed Usage

### Standalone Deployment

#### Basic Version
```powershell
# Simple deployment with defaults
.\Deploy_Velociraptor_Standalone.ps1
```

#### Enhanced Version
```powershell
# Custom configuration
.\Deploy_Velociraptor_Standalone_Improved.ps1 -InstallDir "D:\Velociraptor" -GuiPort 9999

# Skip firewall configuration
.\Deploy_Velociraptor_Standalone_Improved.ps1 -SkipFirewall

# Force re-download
.\Deploy_Velociraptor_Standalone_Improved.ps1 -Force
```

**Default Configuration:**
- Installation: `C:\tools\velociraptor.exe`
- Data Store: `C:\VelociraptorData`
- GUI Port: `8889`
- Access: `https://127.0.0.1:8889`
- Credentials: `admin / password`

### Server Deployment

#### Basic Server Setup
```powershell
# Interactive deployment with prompts
.\Deploy_Velociraptor_Server.ps1
```

#### Enhanced Server Setup
```powershell
# Automated deployment
.\Deploy_Velociraptor_Server_Improved.ps1 -PublicHostname "velo.company.com" -Force

# Custom ports
.\Deploy_Velociraptor_Server_Improved.ps1 -FrontendPort 8443 -GuiPort 8444

# Skip MSI creation
.\Deploy_Velociraptor_Server_Improved.ps1 -SkipMSI
```

**Default Server Configuration:**
- Installation: `C:\tools\velociraptor.exe`
- Data Store: `C:\VelociraptorServerData`
- Frontend Port: `8000` (agent connections)
- GUI Port: `8889` (web interface)
- Service: Windows Service (auto-start)
- Client MSI: Generated for agent deployment

#### SSO Integration
The server scripts support Single Sign-On with:
- **Google OAuth2**
- **Microsoft Azure AD**
- **GitHub OAuth**
- **Okta**
- **Generic OIDC**

### Cleanup and Removal

```powershell
# Interactive cleanup with confirmation
.\Cleanup_Velociraptor.ps1

# Force cleanup without prompts
.\Cleanup_Velociraptor.ps1 -Force

# Skip firewall rule removal
.\Cleanup_Velociraptor.ps1 -SkipFirewallRuleRemoval

# Preview changes without executing
.\Cleanup_Velociraptor.ps1 -WhatIf
```

**Cleanup Removes:**
- All Velociraptor services
- Running processes
- Scheduled tasks
- Firewall rules
- Registry entries
- Installation directories
- Data stores
- Event logs

### Offline Collection Environment

```powershell
# Build offline environment with latest version
.\Prepare_OfflineCollector_Env.ps1

# Build for specific version
.\Prepare_OfflineCollector_Env.ps1 -Version "0.74.1"
```

**Creates:**
- Multi-platform binaries (Windows/Linux/macOS)
- Complete artifact definitions
- External tool dependencies
- Compressed deployment package

## 🛡️ Security Features

### Network Security
- **TLS 1.2 Enforcement**: All HTTPS connections use modern TLS
- **Certificate Validation**: Proper SSL/TLS certificate handling
- **Firewall Integration**: Automatic Windows Firewall rule creation
- **Port Validation**: Pre-flight port availability checks

### Authentication & Authorization
- **SSO Integration**: Enterprise identity provider support
- **Secure Credential Handling**: Protected password input and storage
- **Admin Privilege Validation**: Ensures proper elevation

### Data Protection
- **Download Verification**: File integrity checks
- **Secure Cleanup**: Complete data removal capabilities
- **Audit Logging**: Comprehensive operation logging

## 📊 Monitoring and Logging

### Log Locations
- **Standalone**: `%ProgramData%\VelociraptorDeploy\standalone_deploy.log`
- **Server**: `%ProgramData%\VelociraptorDeploy\server_deploy.log`
- **Cleanup**: `%ProgramData%\VelociraptorCleanup\cleanup.log`

### Service Management
```powershell
# Check service status
Get-Service Velociraptor

# View service logs
Get-WinEvent -LogName Application -Source Velociraptor

# Manual service control
net start Velociraptor
net stop Velociraptor
```

## 🔍 Troubleshooting

### Common Issues

#### Port Already in Use
```powershell
# Check what's using the port
netstat -ano | findstr :8889

# Use different port
.\Deploy_Velociraptor_Standalone_Improved.ps1 -GuiPort 9999
```

#### Download Failures
```powershell
# Check internet connectivity
Test-NetConnection api.github.com -Port 443

# Manual download and placement
# Place velociraptor.exe in C:\tools\ and re-run script
```

#### Service Won't Start
```powershell
# Check service status
Get-Service Velociraptor | Format-List *

# View detailed service logs
Get-WinEvent -LogName System | Where-Object {$_.ProviderName -eq "Service Control Manager"}
```

#### Firewall Issues
```powershell
# Check firewall rules
Get-NetFirewallRule -DisplayName "*Velociraptor*"

# Manual rule creation
New-NetFirewallRule -DisplayName "Velociraptor GUI" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8889
```

### Performance Optimization

#### Large Environments
- Use dedicated data drive for `DataStore`
- Increase system resources (RAM/CPU)
- Configure log rotation
- Monitor disk space usage

#### Network Optimization
- Use dedicated network interfaces
- Configure QoS policies
- Monitor bandwidth usage
- Implement load balancing for large deployments

## 🏗️ Architecture

### Standalone Mode
```
┌─────────────────┐
│   Single Host   │
├─────────────────┤
│ Velociraptor    │
│ GUI Process     │
│ (Port 8889)     │
└─────────────────┘
```

### Server Mode
```
┌─────────────────┐    ┌─────────────────┐
│ Velociraptor    │    │   Client        │
│ Server          │◄───┤   Agents        │
├─────────────────┤    │   (MSI)         │
│ Frontend:8000   │    └─────────────────┘
│ GUI:8889        │    
│ Windows Service │    ┌─────────────────┐
└─────────────────┘    │   Admin         │
                       │   Web GUI       │
                       └─────────────────┘
```

## 🤝 Contributing

### Development Setup
1. Fork the repository
2. Create feature branch: `git checkout -b feature/improvement-name`
3. Make changes following PowerShell best practices
4. Test on clean Windows systems
5. Submit pull request

### Coding Standards
- Use approved PowerShell verbs
- Include comprehensive error handling
- Add parameter validation
- Write detailed help documentation
- Follow consistent naming conventions

### Testing Checklist
- [ ] Administrator privilege validation
- [ ] Network connectivity handling
- [ ] Port availability checks
- [ ] Service installation/removal
- [ ] Firewall rule management
- [ ] Clean uninstallation
- [ ] Cross-Windows version compatibility

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Resources

- [Velociraptor Official Documentation](https://docs.velociraptor.app/)
- [Velociraptor GitHub Repository](https://github.com/Velocidex/velociraptor)
- [Digital Forensics Community](https://www.reddit.com/r/computerforensics/)
- [SANS DFIR Resources](https://www.sans.org/cyber-security-courses/digital-forensics-incident-response/)

## 📞 Support

For issues related to these scripts:
1. Check the troubleshooting section above
2. Review the log files for detailed error information
3. Open an issue on GitHub with:
   - Windows version and PowerShell version
   - Complete error messages
   - Relevant log file contents
   - Steps to reproduce

For Velociraptor-specific issues, please refer to the [official Velociraptor documentation](https://docs.velociraptor.app/) and [community resources](https://github.com/Velocidex/velociraptor/discussions).

---

**⚠️ Important Security Note**: These scripts download and execute software from the internet. Always review scripts before execution and ensure you're running them in appropriate environments with proper security controls.