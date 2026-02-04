# Velociraptor Claw Edition - Enterprise DFIR Deployment Platform

**Version**: v1.0.0-beta.2
**Status**: Beta Released
**Platforms**: Windows, macOS, Linux | PowerShell 5.1+ | Node.js 18+
**License**: See LICENSE file

---

## Downloads

### Latest Beta Release (v1.0.0-beta.2)

| Platform | Download | Architecture |
|----------|----------|--------------|
| **macOS** | [DMG (Intel)](https://github.com/Ununp3ntium115/Velociraptor_scripts/releases/download/v1.0.0-beta.2/Velociraptor.Platform-1.0.0-beta.2-mac-x64.dmg) | x64 |
| **macOS** | [DMG (Apple Silicon)](https://github.com/Ununp3ntium115/Velociraptor_scripts/releases/download/v1.0.0-beta.2/Velociraptor.Platform-1.0.0-beta.2-mac-arm64.dmg) | arm64 |
| **Windows** | [Installer (64-bit)](https://github.com/Ununp3ntium115/Velociraptor_scripts/releases/download/v1.0.0-beta.2/Velociraptor.Platform-1.0.0-beta.2-win-x64.exe) | x64 |
| **Windows** | [Installer (ARM64)](https://github.com/Ununp3ntium115/Velociraptor_scripts/releases/download/v1.0.0-beta.2/Velociraptor.Platform-1.0.0-beta.2-win-arm64.exe) | arm64 |
| **Linux** | [AppImage](https://github.com/Ununp3ntium115/Velociraptor_scripts/releases/download/v1.0.0-beta.2/Velociraptor.Platform-1.0.0-beta.2-linux-x86_64.AppImage) | x64 |
| **Linux** | [AppImage (ARM64)](https://github.com/Ununp3ntium115/Velociraptor_scripts/releases/download/v1.0.0-beta.2/Velociraptor.Platform-1.0.0-beta.2-linux-arm64.AppImage) | arm64 |
| **Linux** | [DEB](https://github.com/Ununp3ntium115/Velociraptor_scripts/releases/download/v1.0.0-beta.2/Velociraptor.Platform-1.0.0-beta.2-linux-amd64.deb) | x64 |
| **Linux** | [RPM](https://github.com/Ununp3ntium115/Velociraptor_scripts/releases/download/v1.0.0-beta.2/Velociraptor.Platform-1.0.0-beta.2-linux-x86_64.rpm) | x64 |

[View all downloads](https://github.com/Ununp3ntium115/Velociraptor_scripts/releases/tag/v1.0.0-beta.2)

---

## What is This?

A comprehensive, cross-platform DFIR deployment framework featuring:

- **Cross-Platform Electron GUI** - Modern desktop app for Windows, macOS, and Linux
- **31+ Deployment Modes** - Standalone, Server, Cloud (AWS/Azure/GCP), Containers, HPC
- **25+ DFIR Tools Integration** - Volatility3, YARA, Chainsaw, WinPmem, and more
- **8 Training Scenarios** - Ransomware, APT, lateral movement, credential theft simulations
- **Offline Worker Deployment** - USB/ISO packages for air-gapped environments
- **Complete Package Repository** - 1.03 GB self-hosted Velociraptor binaries

---

## Quick Start

### Option 1: Download Desktop App (Recommended)
Download the appropriate installer for your platform from the [Downloads](#downloads) section above.

### Option 2: PowerShell Deployment (Windows)
```powershell
# Clone repository
git clone https://github.com/Ununp3ntium115/Velociraptor_scripts.git
cd Velociraptor_scripts

# Deploy Velociraptor standalone
.\Velociraptor_Setup_Scripts\Deploy_Velociraptor_Standalone.ps1

# Or launch the deployment center GUI
.\Velociraptor-Deployment-Center.ps1
```

### Option 3: Run Electron App from Source
```bash
cd VelociraptorPlatform-Electron
npm install
npm start
```

---

## Key Features

### Cross-Platform Desktop Application
- **Electron-based GUI** for Windows, macOS, and Linux
- Modern dark theme with responsive design
- Native PowerShell bridge for Windows integration
- One-click tool deployment and management

### Cybersecurity Training Framework
- **8 incident simulation scenarios** for hands-on training
- Ransomware, persistence, lateral movement, exfiltration
- Credential theft, LOLBins, web shells, cryptominers
- YARA rule generation for each scenario

### DFIR Tool Integration
- **25+ forensic tools** with automated installation
- Volatility3, WinPmem, Chainsaw, YARA, Hayabusa
- PEStudio, Wireshark, BloodHound, NetworkMiner
- Tool-artifact mapping for Velociraptor integration

### Deployment Options
- **Standalone**: Single-server deployment
- **Server**: Multi-component enterprise deployment
- **Cloud**: AWS/Azure/GCP frameworks
- **Containers**: Docker/Kubernetes support
- **Offline**: USB/ISO packages for air-gapped networks

---

## Documentation

- **Quick Start**: This file
- **Developer Guide**: [CLAUDE.md](CLAUDE.md)
- **Server Deployment**: [SERVER-DEPLOYMENT-PRODUCTION-GUIDE.md](SERVER-DEPLOYMENT-PRODUCTION-GUIDE.md)
- **Package Selection**: [velociraptor-packages/PACKAGE-SELECTION-GUIDE.md](velociraptor-packages/PACKAGE-SELECTION-GUIDE.md)
- **Electron Platform**: [VelociraptorPlatform-Electron/README.md](VelociraptorPlatform-Electron/README.md)

---

## System Requirements

### Desktop Application
| Platform | Minimum | Recommended |
|----------|---------|-------------|
| **macOS** | 10.15 (Catalina) | 12.0+ (Monterey) |
| **Windows** | Windows 10 | Windows 11 |
| **Linux** | Ubuntu 20.04 | Ubuntu 22.04+ |
| **RAM** | 4 GB | 8 GB |
| **Disk** | 500 MB | 2 GB |

### PowerShell Scripts
- Windows PowerShell 5.1 or PowerShell Core 7+
- Administrator privileges for deployment operations

---

## Project Structure

```
Velociraptor_scripts/
├── VelociraptorPlatform-Electron/     # Cross-platform Electron GUI
│   ├── electron.js                    # Main entry point
│   ├── backend/                       # PowerShell bridges
│   └── test/                          # Test suites
├── Velociraptor_Setup_Scripts/        # Core deployment scripts
├── velociraptor-packages/             # 1.03 GB package repository
├── lib/                               # Core PowerShell modules
└── agents/                            # Specialized automation agents
```

---

## Known Issues

1. **macOS/Windows**: Applications are not code-signed (security warnings on first run)
   - macOS: Right-click > Open, then click "Open"
   - Windows: Click "More info" > "Run anyway"

2. **Linux AppImage**: May require `--no-sandbox` flag on some distributions

---

## Contributing

We welcome contributions!

- **Bug Reports**: [GitHub Issues](https://github.com/Ununp3ntium115/Velociraptor_scripts/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/Ununp3ntium115/Velociraptor_scripts/discussions)
- **Pull Requests**: Welcome for improvements

---

## License

See LICENSE file for details.

---

## Acknowledgments

- **Velociraptor**: [Velocidex](https://www.velocidex.com/) for the DFIR platform
- **Electron**: Cross-platform desktop framework
- **Community**: All contributors and testers
- **Community Tools**: All open-source DFIR tool maintainers
