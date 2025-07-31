# Velociraptor GUI User Guide

## 🎯 **Overview**

The Velociraptor Configuration Wizard provides a professional, step-by-step interface for creating Velociraptor configurations. The GUI has been completely rebuilt with modern, safe patterns to ensure reliable operation.

## 🚀 **Getting Started**

### **Launch the GUI**
```powershell
# Windows
powershell.exe -ExecutionPolicy Bypass -File "gui\VelociraptorGUI-Fixed.ps1"

# Cross-platform
pwsh -ExecutionPolicy Bypass -File "gui/VelociraptorGUI-Fixed.ps1"
```

### **System Requirements**
- **Windows**: Windows 10/11 with PowerShell 5.1+ or PowerShell Core 7.0+
- **Cross-platform**: PowerShell Core 7.0+ on Linux/macOS
- **.NET Framework**: Required for Windows Forms support

## 📋 **Wizard Steps**

### **Step 1: Welcome**
- Introduction to the configuration wizard
- Overview of features and capabilities
- Professional branding with "Free For All First Responders"

### **Step 2: Deployment Type**
Choose from three deployment options:
- **Server Deployment**: Full enterprise server with web GUI and client management
- **Standalone Deployment**: Single-user forensic workstation with local GUI
- **Client Configuration**: Client agent for connecting to centralized server

### **Step 3: Storage Configuration**
Configure data storage locations:
- **Datastore Directory**: Primary data storage location
- **Logs Directory**: Log file storage location
- **Browse Button**: File system browser for easy path selection

### **Step 4: Network Configuration**
Set up network bindings:
- **Bind Address**: IP address to bind services (default: 0.0.0.0)
- **Bind Port**: Port for main service (default: 8000)
- **GUI Address**: Web GUI bind address (default: 127.0.0.1)
- **GUI Port**: Web GUI port (default: 8889)

### **Step 5: Authentication**
Configure administrative access:
- **Admin Username**: Administrator account name (default: admin)
- **Admin Password**: Secure password (minimum 8 characters)
- **Password Masking**: Secure input with hidden characters

### **Step 6: Review & Generate**
Review all configuration settings:
- **Configuration Summary**: Complete overview of all settings
- **Validation**: Automatic validation of required fields
- **Generation**: Create the final YAML configuration file

### **Step 7: Complete**
Configuration completion:
- **Success Confirmation**: Verification of successful generation
- **File Location**: Path to generated configuration file
- **Next Steps**: Guidance for deployment and usage

## 🎨 **User Interface Features**

### **Professional Design**
- **Dark Theme**: Modern dark interface with teal accents
- **Clean Layout**: Organized, professional appearance
- **Responsive Design**: Adapts to window resizing
- **Error-Free Operation**: No BackColor conversion errors

### **Navigation**
- **Next/Back Buttons**: Easy step-by-step navigation
- **Progress Tracking**: Visual progress indicator
- **Step Counter**: Current step and total steps display
- **Cancel Option**: Safe exit with confirmation dialog

### **Input Validation**
- **Real-time Validation**: Immediate feedback on input
- **Required Field Checking**: Prevents incomplete configurations
- **Error Messages**: Clear, helpful error descriptions
- **Graceful Error Handling**: No crashes or unexpected behavior

## 🔧 **Technical Features**

### **Reliability**
- **Safe Control Creation**: Robust control initialization
- **Error Handling**: Comprehensive try-catch blocks
- **Memory Management**: Proper resource cleanup
- **Cross-platform Compatibility**: Works on Windows, Linux, macOS

### **Performance**
- **Fast Startup**: Quick initialization and loading
- **Responsive Interface**: Smooth user interactions
- **Efficient Memory Usage**: Optimized resource consumption
- **Clean Shutdown**: Proper application termination

## 🛠️ **Troubleshooting**

### **Common Issues**

#### **GUI Won't Start**
```powershell
# Check PowerShell execution policy
Get-ExecutionPolicy

# Set execution policy if needed
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
```

#### **Missing Windows Forms**
```powershell
# Verify .NET Framework installation
[System.Environment]::Version

# Install PowerShell Core if needed
winget install Microsoft.PowerShell
```

#### **Permission Errors**
```powershell
# Run as Administrator if needed
Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File 'gui\VelociraptorGUI-Fixed.ps1'"
```

### **Error Messages**

#### **"Failed to initialize Windows Forms"**
- **Cause**: Missing .NET Framework or Windows Forms support
- **Solution**: Install .NET Framework 4.7.2+ or PowerShell Core 7.0+

#### **"Cannot create main form"**
- **Cause**: Insufficient system resources or permissions
- **Solution**: Close other applications, run as Administrator

#### **"Color assignment failed"**
- **Cause**: Graphics driver or display issues
- **Solution**: Update graphics drivers, check display settings

## 📊 **Configuration Output**

### **Generated Files**
- **velociraptor-config.yaml**: Main configuration file
- **Backup Files**: Timestamped configuration backups
- **Log Files**: Detailed generation logs

### **Configuration Format**
The wizard generates standard Velociraptor YAML configuration files compatible with:
- Velociraptor Server deployments
- Standalone installations
- Client configurations
- Cloud deployments

## 🔄 **Updates and Maintenance**

### **Version Information**
- **Current Version**: v5.0.1
- **Edition**: Free For All First Responders
- **Last Updated**: 2025-07-20
- **Compatibility**: Velociraptor 0.6.0+

### **Update Process**
```bash
# Update from Git
git pull origin main

# Update from PowerShell Gallery
Update-Module VelociraptorSetupScripts -AllowPrerelease
```

## 📞 **Support**

### **Getting Help**
- **Documentation**: Complete guides in repository
- **Issues**: Report bugs via GitHub Issues
- **Community**: Join discussions and get help
- **Testing**: Help test new features

### **Feedback**
We welcome feedback on:
- User experience improvements
- Feature requests
- Bug reports
- Performance suggestions

---

**The Velociraptor Configuration Wizard provides a professional, reliable interface for creating Velociraptor configurations with zero BackColor errors and comprehensive functionality.**

*User Guide created: 2025-07-20*  
*Version: 5.0.1 - Free For All First Responders*