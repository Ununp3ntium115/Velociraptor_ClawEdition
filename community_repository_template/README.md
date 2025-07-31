# Velociraptor Setup Scripts (Community Edition)

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B%20%7C%20Core%207.0%2B-blue?logo=powershell)](https://github.com/PowerShell/PowerShell)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-green?logo=microsoft)](README.md)
[![License](https://img.shields.io/badge/License-MIT-yellow?logo=opensource)](LICENSE)

**🆓 Free community edition for individual incident responders and educational use.**

Simplified PowerShell automation for basic [Velociraptor](https://docs.velociraptor.app/) DFIR platform deployment. This community edition provides essential deployment capabilities for learning and individual use.

## 🚀 **Quick Start**

### Standalone Deployment (GUI Mode)
```powershell
# Download and run standalone deployment
.\Deploy_Velociraptor_Standalone.ps1
```

### Server Deployment  
```powershell
# Deploy Velociraptor server
.\Deploy_Velociraptor_Server.ps1 -OrganizationName "YourOrg"
```

## 📋 **Features (Community Edition)**

### ✅ **Included**
- **Basic Standalone Deployment**: Simple GUI setup
- **Basic Server Configuration**: Essential server deployment
- **Cross-Platform Support**: Windows and Linux
- **PowerShell Module**: Core deployment functions
- **Simple GUI**: Basic configuration wizard
- **Community Support**: GitHub issues and discussions

### ❌ **Not Included** 
- Advanced DFIR toolsuite integration
- Enterprise security hardening
- Cloud deployment automation
- Advanced AI/ML capabilities
- Professional support
- Moonshot technologies

## ⬆️ **Enterprise Features Available**

For enterprise features, advanced toolsuite integration, and professional support, consider commercial DFIR platforms.

### Commercial Features:
- **Complete DFIR Toolsuite**: 87+ integrated tools (Hayabusa, UAC, Chainsaw, YARA, Sigma)
- **Enterprise Security**: Advanced hardening and compliance
- **Cloud Native**: AWS, Azure, GCP deployment automation  
- **AI Integration**: Autonomous threat hunting and analytics
- **Professional Support**: 24/7 enterprise support
- **Moonshot Technologies**: ServiceNow & Stellar Cyber integration

| Feature | Community | Commercial |
|---------|-----------|------------|
| Basic Deployment | ✅ | ✅ |
| DFIR Toolsuite | ❌ | ✅ |
| Enterprise Security | ❌ | ✅ |
| Cloud Automation | ❌ | ✅ |
| Professional Support | ❌ | ✅ |
| Price | Free | Starting $2,999/year |

## 🛠️ **Installation**

### Prerequisites
- PowerShell 5.1+ (Windows) or PowerShell Core 7.0+ (Linux/macOS)
- Administrator/root privileges
- Internet connection

### Method 1: Direct Download
```powershell
# Clone repository
git clone https://github.com/Community/velociraptor_setup_scripts.git
cd velociraptor_setup_scripts

# Run deployment  
.\Deploy_Velociraptor_Standalone.ps1
```

### Method 2: PowerShell Gallery
```powershell
# Install from PowerShell Gallery
Install-Module VelociraptorSetupScripts
Import-Module VelociraptorSetupScripts

# Deploy Velociraptor
Deploy-Velociraptor
```

## 📚 **Documentation**

- [Installation Guide](docs/installation.md)
- [Configuration Options](docs/configuration.md) 
- [Troubleshooting](docs/troubleshooting.md)
- [Community Guidelines](docs/community.md)

## 🤝 **Community Support**

### Getting Help
- **GitHub Issues**: Bug reports and feature requests
- **Discussions**: Community Q&A and best practices
- **Wiki**: Community-maintained documentation

### Contributing
We welcome community contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Community License Summary:
- ✅ Free for personal and educational use
- ✅ Modify and distribute
- ✅ Commercial use permitted
- ❌ No warranty or liability
- ❌ No professional support

## 🔄 **Version Information**

- **Current Version**: v5.0.1-beta (frozen)
- **Maintenance**: Security updates only
- **Development**: Community-driven
- **Support**: Community-driven

## 🚨 **Important Notice**

This community edition is **stable at v5.0.1-beta** and receives community-driven updates and security patches.

## 🙏 **Acknowledgments**

- **Velociraptor Team**: For creating an amazing DFIR platform
- **PowerShell Community**: For excellent modules and best practices  
- **Contributors**: All community members who made this possible
- **Community Contributors**: For continued development and support

---

**Made with ❤️ by the Incident Response Community**

*Last Updated: July 2025 | Version: 5.0.1-beta | Status: Community Maintenance*