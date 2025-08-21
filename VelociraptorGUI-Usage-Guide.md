# VelociraptorGUI-Actually-Working.ps1 - Usage Guide

## Overview

**VelociraptorGUI-Actually-Working.ps1** is a completely functional GUI that properly installs and configures a working Velociraptor DFIR server. Unlike previous GUI attempts, this version follows proper Velociraptor deployment practices and provides a real working installation.

## Key Features

### ✅ Actually Works
- **Real Installation**: Downloads genuine Velociraptor executable from GitHub
- **Proper Configuration**: Uses `velociraptor config generate` to create valid server configuration
- **Admin User Creation**: Creates secure administrator accounts with random passwords
- **Server Startup**: Actually starts the Velociraptor server with proper configuration
- **Web Interface Verification**: Confirms the web interface is accessible before completion

### 🎨 Professional UI/UX
- **Modern Design**: Dark theme with professional color scheme
- **Real-time Progress**: Progress bar and status updates throughout installation
- **Comprehensive Logging**: Detailed log output with timestamps and status indicators
- **Error Handling**: User-friendly error messages with actionable suggestions
- **Visual Feedback**: Color-coded status indicators and validation

### 🔧 Technical Excellence
- **Proper Windows Forms**: Correct assembly loading and initialization
- **Background Processing**: Non-blocking installation that keeps UI responsive
- **Configuration Validation**: Real-time path validation with visual feedback
- **Process Management**: Proper server process lifecycle management
- **Memory Management**: Clean resource disposal and error handling

## Installation Process

The GUI follows these 7 steps to ensure a complete, working Velociraptor installation:

1. **Prerequisites Check**: Validates administrator privileges and port availability
2. **Download Executable**: Downloads latest Velociraptor from GitHub with progress tracking
3. **Generate Configuration**: Creates server configuration using `velociraptor config generate`
4. **Create Admin User**: Sets up administrator account with secure random password
5. **Start Server**: Launches Velociraptor server with proper configuration
6. **Verify Web Interface**: Confirms web interface is accessible on specified port
7. **Final Validation**: Complete installation verification and user notification

## Usage Instructions

### Basic Usage

1. **Run as Administrator** (recommended for optimal functionality):
   ```powershell
   # Right-click PowerShell -> "Run as Administrator"
   .\VelociraptorGUI-Actually-Working.ps1
   ```

2. **Configure Installation Paths**:
   - **Installation Directory**: Where Velociraptor executable will be installed (default: C:\tools)
   - **Data Directory**: Where Velociraptor data will be stored (default: C:\VelociraptorData)
   - **GUI Port**: Web interface port (default: 8889)

3. **Click "Install Velociraptor"**: Watch the real-time progress and log output

4. **Access Web Interface**: Use the "Open Web Interface" button after installation

### Advanced Usage

```powershell
# Custom installation directories
.\VelociraptorGUI-Actually-Working.ps1 -InstallDir "D:\SecurityTools" -DataStore "D:\VelociraptorData" -GuiPort 9999

# View available parameters
Get-Help .\VelociraptorGUI-Actually-Working.ps1 -Full
```

## What Makes This GUI Different

### Previous GUIs vs. Actually-Working Version

| Aspect | Previous GUIs | Actually-Working Version |
|--------|---------------|---------------------------|
| **Installation** | Fake/demo installation | Real Velociraptor download and installation |
| **Configuration** | No proper config generation | Uses `velociraptor config generate` |
| **Server Startup** | GUI mode only | Proper server configuration and startup |
| **User Accounts** | Default admin/password | Secure random password generation |
| **Verification** | No verification | Web interface accessibility testing |
| **Error Handling** | Basic error messages | Professional error dialogs with suggestions |
| **Progress Tracking** | Static progress bars | Real-time progress with status updates |
| **Process Management** | No process management | Proper server lifecycle management |

### Key Technical Improvements

1. **Proper Velociraptor Configuration**:
   ```powershell
   velociraptor.exe config generate --config "server.config.yaml"
   ```

2. **Admin User Creation**:
   ```powershell
   velociraptor.exe --config "server.config.yaml" user add admin --role administrator --password [SecurePassword]
   ```

3. **Server Startup**:
   ```powershell
   velociraptor.exe --config "server.config.yaml" frontend -v
   ```

4. **Web Interface Verification**:
   - Waits for server to initialize
   - Tests HTTPS connectivity to web interface
   - Confirms server is responding before completion

## GUI Features

### Main Interface

- **Header**: Professional branding and title
- **Configuration Panel**: Installation paths and port settings with real-time validation
- **Progress Panel**: Live progress bar and status updates
- **Log Panel**: Comprehensive installation log with timestamps
- **Button Panel**: Install, Open Web Interface, Stop Server, and Exit controls

### Visual Feedback

- **Path Validation**: Text boxes change color to indicate valid/invalid paths
- **Progress Tracking**: Progress bar shows actual installation progress
- **Status Updates**: Real-time status messages during each step
- **Button States**: Buttons enable/disable based on installation state

### Error Handling

Professional error dialogs include:
- Clear error description
- Suggested troubleshooting actions
- Links to documentation
- Context-specific guidance

## Credentials and Access

After successful installation:

- **Web Interface**: `https://127.0.0.1:[port]` (default: 8889)
- **Username**: `admin`
- **Password**: Randomly generated secure password (displayed in log and success dialog)
- **Credentials**: Automatically copied to clipboard

## Troubleshooting

### Common Issues

1. **Port Already in Use**:
   - Change GUI port in configuration
   - Check for existing Velociraptor processes
   - Use `netstat -an | findstr :8889` to identify port usage

2. **Download Failures**:
   - Check internet connectivity
   - Verify Windows Defender/antivirus settings
   - Ensure adequate disk space (500MB minimum)

3. **Web Interface Not Accessible**:
   - Check Windows Firewall settings
   - Verify server process is running
   - Try accessing directly: `https://127.0.0.1:8889`

4. **Administrator Privileges**:
   - Run PowerShell as Administrator
   - Some features require elevated privileges
   - Firewall rule creation needs admin rights

### Log Analysis

The GUI provides comprehensive logging with indicators:
- `[--]` - Information
- `[OK]` - Success
- `[!!]` - Warning
- `[XX]` - Error
- `[>>]` - Step progression

## Security Considerations

- **Secure Passwords**: Randomly generated 12-character passwords with mixed case, numbers, and symbols
- **HTTPS Only**: Web interface uses HTTPS with self-signed certificates
- **Local Access**: Default configuration allows local access only
- **Process Isolation**: Server runs as separate process with proper lifecycle management

## File Locations

After installation:
- **Executable**: `[InstallDir]\velociraptor.exe`
- **Configuration**: `[InstallDir]\server.config.yaml`
- **Data Storage**: `[DataStore]\` (databases, artifacts, etc.)
- **Logs**: GUI log in application, server logs in datastore

## Support

For issues with the GUI:
1. Check the installation log for specific error messages
2. Review the troubleshooting section above
3. Verify all prerequisites are met
4. Run as Administrator if permission issues occur
5. Check GitHub repository for updates and known issues

## Version Information

- **Version**: 1.0.0 - Actually Working Edition
- **Created**: 2025-08-21
- **Compatibility**: Windows 10/11, PowerShell 5.1+, .NET Framework 4.7.2+
- **Dependencies**: System.Windows.Forms, System.Drawing

---

*This GUI represents a complete rewrite focusing on functionality, reliability, and professional user experience. Unlike previous versions, it results in a fully operational Velociraptor DFIR server ready for immediate use.*