# 🦖 Velociraptor Setup Scripts v5.0.5-beta

## Professional Enterprise-Grade DFIR Automation Platform

**Complete Professional GUI Edition** - Comprehensive overhaul with fully functional, enterprise-ready interfaces.

---

## 🚀 Quick Start

### **Main Professional GUI** (Recommended)
```powershell
.\VelociraptorGUI-Enhanced-Working.ps1
```

### **Incident Response Platform**
```powershell
.\IncidentResponseGUI-Enhanced-Working.ps1
```

### **Manual Deployment** (If needed)
```powershell
.\Deploy-Velociraptor-Working.ps1
```

---

## ✨ What's New in v5.0.5-beta

### 🎯 **Complete Professional GUIs**
- **8 Configuration Tabs**: Complete `velociraptor.exe -i` replacement
- **Interactive Controls**: All buttons, fields, and dropdowns fully functional
- **Professional Theme**: Enterprise dark theme with Velociraptor branding
- **Real-time Validation**: Live feedback on configuration changes

### 🔧 **Critical Bug Fixes**
- ✅ Fixed Windows Forms initialization errors
- ✅ Resolved non-clickable controls (password fields, buttons)
- ✅ Eliminated character encoding issues
- ✅ Corrected deployment scripts to create working servers

### 🛡️ **Enterprise Security Features**
- **Admin Password Management**: Custom/generated with complexity options
- **Certificate Options**: Self-signed, Let's Encrypt, custom (1-10 year duration)
- **SSO Integration**: SAML, OAuth, Active Directory support
- **DNS Configuration**: Cloudflare, custom DNS servers
- **Compliance Frameworks**: NIST, ISO27001, SOX, HIPAA, PCI-DSS, GDPR

### 🚨 **Professional Incident Response**
- **6 Specialized Incident Types**: APT, Ransomware, Malware, Data Breach, Network Intrusion, Insider Threats
- **Comprehensive Artifact Collections**: 8+ specialized artifacts per incident type
- **Offline Collector Generation**: Enhanced offline worker capabilities
- **Threat Level Assessment**: Professional categorization and investigation timeframes

---

## 📋 **Main Features**

### **VelociraptorGUI-Enhanced-Working.ps1**
- **Basic Configuration**: Installation paths, data directories
- **Authentication**: Admin passwords, user management
- **Certificates**: Multiple types with custom durations
- **Network Settings**: Ports, SSL/TLS, DNS configuration
- **Security Options**: Encryption, compliance frameworks
- **Advanced Settings**: Custom configurations, performance tuning
- **Compliance**: Multi-framework support (NIST, ISO27001, etc.)
- **Artifact Management**: Tool dependencies and artifact packs

### **IncidentResponseGUI-Enhanced-Working.ps1**
- **Incident Response Tab**: Specialized threat scenario selection
- **Configuration Tab**: Enhanced IR platform settings
- **Deployment Status**: Real-time monitoring and logging
- **Specialized Collections**: Tailored artifacts per incident type
- **Offline Tools**: Recommended tools for each investigation
- **Professional Categorization**: Priority and threat level assessment

---

## 🛠️ **Requirements**

### **System Requirements**
- **OS**: Windows 10/11, Windows Server 2016+
- **PowerShell**: 5.1+ or PowerShell 7.x
- **Privileges**: Administrator access required for deployment
- **RAM**: 4GB minimum (8GB recommended)
- **Disk**: 2GB free space minimum

### **Dependencies**
- **.NET Framework**: 4.7.2+ (for Windows Forms)
- **TLS 1.2**: For GitHub API access and downloads
- **Internet Access**: For Velociraptor downloads and updates

---

## 🎯 **Usage Scenarios**

### **Enterprise Deployment**
1. Run `VelociraptorGUI-Enhanced-Working.ps1`
2. Configure across 8 professional tabs
3. Set admin passwords and certificates
4. Deploy with enterprise compliance settings

### **Incident Response**
1. Run `IncidentResponseGUI-Enhanced-Working.ps1`
2. Select incident type (APT, Ransomware, etc.)
3. Configure specialized artifact collections
4. Deploy IR platform with offline collectors

### **Quick Manual Deployment**
1. Run `Deploy-Velociraptor-Working.ps1`
2. Follow prompts for basic setup
3. Access web interface at https://localhost:8889

---

## 📁 **File Structure**

```
velociraptor-setup-scripts-v5.0.5-beta/
├── VelociraptorGUI-Enhanced-Working.ps1      # Main professional GUI
├── IncidentResponseGUI-Enhanced-Working.ps1  # IR platform GUI  
├── Deploy-Velociraptor-Working.ps1           # Manual deployment
├── gui/
│   └── VelociraptorGUI.ps1                   # Core GUI functions
├── modules/
│   └── VelociraptorDeployment/               # PowerShell modules
│       ├── VelociraptorDeployment.psm1
│       └── functions/                        # Helper functions
├── RELEASE-NOTES-v5.0.5-beta.md             # Detailed release notes
└── README.md                                 # This file
```

---

## 🔧 **Troubleshooting**

### **Common Issues**

**Windows Forms Error**
```
Solution: Ensure .NET Framework 4.7.2+ is installed
```

**Permission Denied**
```
Solution: Run PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Download Failures**
```
Solution: Check internet connectivity and TLS 1.2 support
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

**GUI Not Responding**
```
Solution: Close and restart. All GUIs tested and verified working in v5.0.5-beta
```

---

## 🏆 **Quality Assurance**

### **Testing Completed**
- ✅ **Windows Forms Initialization**: All GUI files verified working
- ✅ **Control Interactivity**: All buttons, fields, dropdowns functional  
- ✅ **Password Generation**: All complexity levels tested
- ✅ **Deployment Process**: End-to-end testing creating working servers
- ✅ **Incident Response**: All specialized collections verified
- ✅ **Cross-Platform**: Windows PowerShell 5.1 and 7.x tested

### **Zero Critical Bugs**
This release has undergone comprehensive testing with all major functionality verified working as designed.

---

## 📞 **Support**

### **Getting Help**
- 📋 **Issues**: Report on GitHub repository
- 📖 **Documentation**: See RELEASE-NOTES-v5.0.5-beta.md
- 🧪 **Testing**: Comprehensive QA completed

### **Professional Features**
- 🎯 **Enterprise-Grade**: Professional GUI interfaces
- 🛡️ **Security-First**: Comprehensive compliance and authentication
- 🚨 **Incident Response**: Specialized tools for different threats
- 📊 **Real-time Monitoring**: Progress tracking and status logging

---

## 🎖️ **About**

**Mission**: Democratize enterprise-grade DFIR capabilities by providing professional automation tools that are completely free for all incident responders worldwide.

**Status**: Production Ready Beta - Complete Professional Enhancement Release

**Compatibility**: Windows PowerShell 5.1+, PowerShell 7.x, Windows 10/11/Server 2016+

---

*🦖 Velociraptor Setup Scripts - Professional Enterprise DFIR Automation Platform*

**Version**: v5.0.5-beta  
**Release Date**: August 2025  
**Type**: Complete Professional GUI Enhancement Release