# 🖥️ GUI Comprehensive Guide

## 📋 **Complete GUI Documentation for Velociraptor Setup Scripts**

**Version**: v5.0.1-beta Enhanced GUI  
**Status**: Production Ready  
**Last Updated**: $(date)  

This guide provides complete documentation for the enhanced Velociraptor GUI wizard with encryption options and professional interface.

---

## 🎯 **GUI Overview**

### **Enhanced Features**
- **Professional Interface**: Dark theme with Velociraptor branding
- **9-Step Wizard**: Complete configuration workflow
- **Encryption Options**: Self-signed, custom certificates, Let's Encrypt
- **Real-time Validation**: Input validation with helpful error messages
- **Configuration Generation**: Professional YAML output
- **Cross-Platform Ready**: Windows Forms with future cross-platform support

### **Key Improvements from Previous Versions**
- ✅ **Eliminated BackColor Errors**: Fixed persistent null conversion issues
- ✅ **Professional Branding**: Replaced ASCII art with clean banner
- ✅ **Enhanced Navigation**: Smooth wizard step transitions
- ✅ **Better Error Handling**: Comprehensive try-catch blocks
- ✅ **Improved UX**: Real-time feedback and validation

---

## 🚀 **Quick Start Guide**

### **Launch GUI**
```powershell
# Standard launch
.\gui\VelociraptorGUI.ps1

# Launch minimized (for testing)
.\gui\VelociraptorGUI.ps1 -StartMinimized
```

### **System Requirements**
- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1+ or PowerShell Core 7+
- .NET Framework 4.7.2+ or .NET Core 3.1+
- Administrator privileges (for deployment)
- 2GB+ available RAM
- 1GB+ available disk space

---

## 📝 **Step-by-Step Wizard Guide**

### **Step 1: Welcome Screen**
**Purpose**: Introduction and overview

**Features**:
- Professional welcome message
- Velociraptor branding and version info
- Configuration steps overview
- Navigation controls introduction

**User Actions**:
- Review welcome information
- Click "Next" to begin configuration
- Click "Cancel" to exit (with confirmation)

**Validation**: None required

---

### **Step 2: Deployment Type Selection**
**Purpose**: Choose deployment architecture

**Options**:
1. **🖥️ Server Deployment**
   - Multi-client server architecture
   - Centralized management
   - Enterprise-grade features
   - Recommended for organizations

2. **💻 Standalone Deployment**
   - Single-node setup
   - Self-contained operation
   - Ideal for individual analysts
   - Quick setup and deployment

3. **📱 Client Configuration**
   - Client-only setup
   - Connects to existing server
   - Lightweight deployment
   - Remote endpoint management

**Features**:
- Dynamic descriptions update with selection
- Detailed use case information
- Visual icons for each option
- Configuration data persistence

**User Actions**:
- Select deployment type via radio buttons
- Review detailed descriptions
- Navigate with Back/Next buttons

**Validation**: One option must be selected

---

### **Step 3: Storage Configuration**
**Purpose**: Configure data storage locations

**Configuration Options**:

#### **Datastore Directory**
- **Purpose**: Primary data storage location
- **Default**: `C:\VelociraptorData`
- **Features**: Browse button for directory selection
- **Validation**: Directory must be accessible and writable

#### **Logs Directory**
- **Purpose**: Log file storage location
- **Default**: `C:\VelociraptorLogs`
- **Features**: Browse button for directory selection
- **Validation**: Directory must be accessible and writable

#### **Certificate Expiration**
- **Purpose**: SSL certificate validity period
- **Options**: 1 year, 2 years, 5 years, 10 years
- **Default**: 2 years
- **Recommendation**: 2 years for production, 1 year for testing

#### **Registry Usage**
- **Purpose**: Windows registry integration
- **Options**: Enable/Disable checkbox
- **Registry Path**: Configurable when enabled
- **Default Path**: `HKLM:\SOFTWARE\Velociraptor`
- **Validation**: Registry path format validation

**User Actions**:
- Configure datastore and logs directories
- Select certificate expiration period
- Enable/disable registry usage
- Customize registry path if needed

**Validation**:
- Directory paths must be valid
- Registry path must follow Windows format
- Sufficient disk space verification

---

### **Step 4: Network Configuration**
**Purpose**: Configure network settings and ports

**Configuration Options**:

#### **API Server Settings**
- **Bind Address**: IP address for API server
- **Default**: `0.0.0.0` (all interfaces)
- **Port**: TCP port for API communication
- **Default**: `8000`
- **Range**: 1024-65535

#### **GUI Server Settings**
- **Bind Address**: IP address for web GUI
- **Default**: `127.0.0.1` (localhost only)
- **Port**: TCP port for web interface
- **Default**: `8889`
- **Range**: 1024-65535

#### **Network Validation**
- **Port Conflict Detection**: Prevents same port usage
- **IP Address Validation**: Ensures valid IP format
- **Network Settings Test**: Optional connectivity validation

**User Actions**:
- Configure API server bind address and port
- Configure GUI server bind address and port
- Click "Validate Network Settings" for testing
- Review network configuration notes

**Validation**:
- IP addresses must be valid format
- Ports must be in valid range (1024-65535)
- Ports must not conflict with each other
- Network accessibility verification

---

### **Step 5: Authentication Configuration**
**Purpose**: Set up admin credentials and security

**Configuration Options**:

#### **Organization Settings**
- **Organization Name**: Company/organization identifier
- **Purpose**: Branding and identification
- **Validation**: Required field, alphanumeric characters

#### **Admin Credentials**
- **Username**: Administrator account name
- **Default**: `admin`
- **Password**: Administrator password
- **Confirmation**: Password confirmation field
- **Validation**: Password strength requirements

#### **Password Features**
- **Strength Indicator**: Real-time password strength display
- **Generate Secure Password**: Automatic secure password creation
- **Password Requirements**: Minimum 8 characters, complexity rules
- **Confirmation Matching**: Real-time password match validation

#### **Security Options**
- **VQL Restrictions**: Enable/disable VQL query restrictions
- **Purpose**: Additional security layer for query execution
- **Recommendation**: Enable for production environments

**User Actions**:
- Enter organization name
- Configure admin username
- Set strong password or generate secure password
- Confirm password matches
- Configure VQL restrictions

**Validation**:
- Organization name required
- Username required and valid format
- Password meets strength requirements
- Password confirmation matches
- All required fields completed

---

### **Step 6: Review & Generate Configuration**
**Purpose**: Review settings and generate configuration

**Features**:

#### **Configuration Summary**
- **Comprehensive Review**: All settings displayed in tree structure
- **Scrollable Display**: Easy navigation through all options
- **Professional Formatting**: Clean, organized presentation
- **Validation Status**: Real-time configuration validation

#### **Configuration Actions**
- **Generate Configuration File**: Create YAML configuration
- **Export Settings**: Save configuration to file
- **Validation Check**: Comprehensive settings validation
- **Issue Reporting**: Highlight any configuration problems

#### **File Operations**
- **Save Dialog**: Professional file save interface
- **YAML Generation**: Clean, properly formatted output
- **File Validation**: Ensure generated file is valid
- **Backup Options**: Optional configuration backup

**User Actions**:
- Review complete configuration summary
- Validate all settings are correct
- Generate configuration file
- Save configuration to desired location
- Export settings for backup

**Validation**:
- All required settings configured
- No validation errors present
- Configuration file generation successful
- File save operation completed

---

### **Step 7: Completion**
**Purpose**: Confirm successful configuration

**Features**:
- **Success Confirmation**: Configuration completed successfully
- **Next Steps Information**: Guidance for deployment
- **File Location**: Generated configuration file location
- **Deployment Options**: Links to deployment scripts

**User Actions**:
- Review success message
- Note configuration file location
- Click "Finish" to close wizard
- Optionally launch deployment scripts

**Validation**: None required

---

## 🔧 **Advanced Configuration Options**

### **Custom Certificate Configuration**
When selecting custom certificates in Step 3:

#### **Certificate File Selection**
- **Certificate File**: Browse for .crt, .pem, or .cer files
- **Private Key File**: Browse for .key or .pem files
- **Certificate Chain**: Optional intermediate certificates
- **Validation**: Certificate format and validity checking

#### **Certificate Requirements**
- **Format**: PEM or DER encoded
- **Key Length**: Minimum 2048-bit RSA or 256-bit ECC
- **Validity**: Must not be expired
- **Purpose**: Must include server authentication

### **Let's Encrypt Configuration**
For automatic certificate generation:

#### **Domain Requirements**
- **Public Domain**: Must be publicly accessible
- **DNS Resolution**: Domain must resolve to server IP
- **Port 80 Access**: Required for domain validation
- **Firewall**: Must allow inbound HTTP/HTTPS traffic

#### **Automatic Renewal**
- **Renewal Schedule**: Automatic renewal before expiration
- **Monitoring**: Certificate expiration monitoring
- **Notifications**: Renewal status notifications
- **Backup**: Automatic certificate backup

---

## 🎨 **User Interface Design**

### **Visual Design Elements**

#### **Color Scheme**
- **Background**: Dark gray (#202020) for professional appearance
- **Surface**: Medium gray (#303030) for panels and controls
- **Primary**: Teal (#009688) for branding and highlights
- **Text**: White (#FFFFFF) for primary text
- **Secondary Text**: Light gray (#C8C8C8) for secondary information
- **Success**: Green (#4CAF50) for positive feedback
- **Error**: Red (#F44336) for error messages

#### **Typography**
- **Primary Font**: Segoe UI (Windows standard)
- **Fallback Fonts**: Tahoma, Arial, sans-serif
- **Sizes**: 9pt for body text, 12pt for headers
- **Weight**: Regular for body, bold for emphasis

#### **Layout Principles**
- **Consistent Spacing**: 8px grid system
- **Logical Grouping**: Related controls grouped together
- **Clear Hierarchy**: Visual hierarchy guides user attention
- **Responsive Design**: Adapts to different screen sizes

### **Control Standards**

#### **Buttons**
- **Primary Buttons**: Teal background, white text
- **Secondary Buttons**: Gray background, white text
- **Disabled Buttons**: Darker gray, reduced opacity
- **Hover Effects**: Subtle color changes on mouse over

#### **Input Fields**
- **Text Boxes**: Dark background, white text, teal border focus
- **Dropdowns**: Consistent styling with text boxes
- **Checkboxes**: Custom styling matching theme
- **Radio Buttons**: Grouped with clear selection indicators

#### **Validation Feedback**
- **Success**: Green checkmark icons
- **Error**: Red X icons with descriptive messages
- **Warning**: Yellow warning icons
- **Info**: Blue information icons

---

## 🔍 **Troubleshooting Guide**

### **Common Issues and Solutions**

#### **GUI Won't Launch**
**Symptoms**: Error when starting GUI, immediate crash
**Causes**: 
- PowerShell execution policy restrictions
- Missing .NET Framework components
- Windows Forms not available
- Insufficient permissions

**Solutions**:
```powershell
# Check execution policy
Get-ExecutionPolicy

# Set execution policy if needed
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Test Windows Forms availability
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Run as Administrator if needed
```

#### **BackColor Conversion Errors**
**Symptoms**: "Cannot convert null to type 'System.Drawing.Color'" error
**Status**: ✅ **FIXED** in current version
**Previous Solution**: Used constants instead of variables for colors

#### **Navigation Issues**
**Symptoms**: Can't move between wizard steps, buttons not responding
**Causes**:
- Form focus issues
- Event handler problems
- Validation blocking navigation

**Solutions**:
- Click directly on form background to restore focus
- Use Tab key to navigate between controls
- Check validation messages for blocking issues
- Restart GUI if navigation completely fails

#### **Configuration Generation Fails**
**Symptoms**: Error when generating YAML configuration
**Causes**:
- Invalid input data
- File permission issues
- Disk space problems
- Path access restrictions

**Solutions**:
```powershell
# Check disk space
Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, FreeSpace

# Test file write permissions
Test-Path "C:\temp" -PathType Container
New-Item -Path "C:\temp\test.txt" -ItemType File -Force
Remove-Item "C:\temp\test.txt" -Force

# Validate input data
# Review all configuration fields for invalid characters or formats
```

#### **Performance Issues**
**Symptoms**: Slow GUI response, high memory usage
**Causes**:
- Insufficient system resources
- Background processes interfering
- Large configuration data
- Memory leaks (rare)

**Solutions**:
- Close unnecessary applications
- Restart PowerShell session
- Monitor memory usage during operation
- Use minimized mode for testing

### **Error Message Reference**

#### **Validation Errors**
- **"Organization name is required"**: Enter organization name in Step 5
- **"Invalid IP address format"**: Use valid IP format (e.g., 192.168.1.1)
- **"Port must be between 1024 and 65535"**: Use valid port range
- **"Ports cannot be the same"**: Use different ports for API and GUI
- **"Password too weak"**: Use stronger password meeting requirements
- **"Passwords do not match"**: Ensure password confirmation matches

#### **System Errors**
- **"Access denied"**: Run as Administrator
- **"Path not found"**: Verify directory paths exist and are accessible
- **"Network unreachable"**: Check network connectivity
- **"File in use"**: Close applications using configuration files

---

## 📊 **Performance Optimization**

### **GUI Performance Tips**

#### **Startup Optimization**
- **Minimize Background Processes**: Close unnecessary applications
- **Use SSD Storage**: Faster disk access improves loading
- **Adequate RAM**: Minimum 4GB, recommended 8GB+
- **Updated .NET Framework**: Latest version for best performance

#### **Runtime Optimization**
- **Efficient Navigation**: Use Next/Back buttons instead of clicking around
- **Batch Configuration**: Complete all settings before validation
- **Minimize Window Operations**: Avoid frequent minimize/restore
- **Clean Shutdown**: Always use Finish button to close properly

### **Memory Management**
- **Typical Usage**: 50-100MB during normal operation
- **Peak Usage**: Up to 200MB during configuration generation
- **Memory Leaks**: Rare, restart if memory usage grows continuously
- **Cleanup**: Automatic cleanup on exit

### **Performance Monitoring**
```powershell
# Monitor GUI process
Get-Process powershell | Where-Object {$_.MainWindowTitle -like "*Velociraptor*"} | Select-Object ProcessName, WorkingSet, CPU

# Monitor system resources
Get-Counter "\Memory\Available MBytes"
Get-Counter "\Processor(_Total)\% Processor Time"
```

---

## 🔒 **Security Considerations**

### **GUI Security Features**

#### **Input Validation**
- **SQL Injection Prevention**: All inputs sanitized
- **Path Traversal Protection**: Directory paths validated
- **Command Injection Prevention**: No direct command execution
- **XSS Protection**: Output encoding for display

#### **Configuration Security**
- **Password Handling**: Passwords never stored in plain text
- **Secure Generation**: Cryptographically secure password generation
- **File Permissions**: Generated files have appropriate permissions
- **Temporary Files**: Secure cleanup of temporary data

#### **Network Security**
- **Local Operation**: GUI runs locally, no network exposure
- **Secure Defaults**: Conservative default settings
- **Validation**: Network settings validated for security
- **Encryption**: All generated configurations use encryption

### **Best Practices**
- **Run as Administrator**: Only when necessary for deployment
- **Secure Passwords**: Use generated passwords or strong custom passwords
- **File Protection**: Protect generated configuration files
- **Regular Updates**: Keep GUI updated to latest version
- **Audit Trail**: Review generated configurations before deployment

---

## 🧪 **Testing and Validation**

### **GUI Testing Procedures**

#### **Functional Testing**
```powershell
# Test GUI launch
.\gui\VelociraptorGUI.ps1

# Test each wizard step
# 1. Welcome screen navigation
# 2. Deployment type selection
# 3. Storage configuration
# 4. Network configuration  
# 5. Authentication setup
# 6. Configuration review
# 7. Completion confirmation

# Test error handling
# - Invalid inputs
# - Network validation
# - File operations
# - Configuration generation
```

#### **Performance Testing**
```powershell
# Measure startup time
Measure-Command { .\gui\VelociraptorGUI.ps1 -StartMinimized }

# Monitor resource usage
Get-Process powershell | Select-Object WorkingSet, CPU

# Test with large configurations
# Test with multiple instances (not recommended for production)
```

#### **Compatibility Testing**
- **Windows Versions**: Test on Windows 10, 11, Server 2016, 2019, 2022
- **PowerShell Versions**: Test with PowerShell 5.1 and 7.x
- **Screen Resolutions**: Test on different screen sizes
- **User Privileges**: Test with different user account types

### **Validation Checklist**
- [ ] GUI launches without errors
- [ ] All wizard steps navigate correctly
- [ ] Input validation works properly
- [ ] Configuration generation succeeds
- [ ] Generated YAML is valid
- [ ] File operations complete successfully
- [ ] Error handling is graceful
- [ ] Performance meets benchmarks
- [ ] Security requirements satisfied
- [ ] Documentation is accurate

---

## 🚀 **Future Enhancements**

### **Planned Improvements**

#### **Cross-Platform Support**
- **Linux GUI**: GTK-based interface for Linux systems
- **macOS GUI**: Native macOS interface using Cocoa
- **Web Interface**: Browser-based configuration wizard
- **Mobile Support**: Responsive design for tablets

#### **Advanced Features**
- **Configuration Templates**: Pre-built configuration templates
- **Bulk Configuration**: Configure multiple deployments
- **Import/Export**: Configuration import and export
- **Version Control**: Configuration versioning and history

#### **Integration Enhancements**
- **Active Directory**: AD integration for authentication
- **Certificate Management**: Advanced certificate handling
- **Cloud Integration**: Cloud provider integration
- **Monitoring**: Built-in monitoring and alerting

#### **User Experience**
- **Themes**: Multiple UI themes and customization
- **Accessibility**: Enhanced accessibility features
- **Localization**: Multi-language support
- **Help System**: Integrated help and documentation

### **Community Contributions**
- **Feature Requests**: Submit via GitHub Issues
- **Bug Reports**: Detailed bug reporting process
- **Code Contributions**: Pull request guidelines
- **Documentation**: Help improve documentation
- **Testing**: Community testing and feedback

---

## 📞 **Support and Resources**

### **Getting Help**
- **GitHub Issues**: Report bugs and request features
- **Documentation**: Comprehensive guides and references
- **Community**: Active community support and discussions
- **Examples**: Real-world configuration examples

### **Additional Resources**
- **Velociraptor Documentation**: Official Velociraptor docs
- **PowerShell Resources**: PowerShell learning materials
- **Security Guides**: Security best practices
- **Deployment Examples**: Sample deployment scenarios

---

**🖥️ The enhanced GUI wizard makes Velociraptor deployment accessible to users of all skill levels while maintaining enterprise-grade capabilities!**

*This comprehensive guide ensures users can successfully configure and deploy Velociraptor with confidence and professional results.*
