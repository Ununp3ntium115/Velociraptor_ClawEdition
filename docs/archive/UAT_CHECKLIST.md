# 🦖 User Acceptance Testing (UAT) Checklist

## Pre-Testing Setup

### Environment Preparation
- [ ] **Clean test environments prepared**
  - [ ] Windows Server 2019 VM
  - [ ] Windows Server 2022 VM  
  - [ ] Windows 10/11 Pro VM
  - [ ] Ubuntu 20.04 LTS VM
  - [ ] Ubuntu 22.04 LTS VM
- [ ] **Network access validated**
  - [ ] Internet connectivity confirmed
  - [ ] GitHub access verified
  - [ ] DNS resolution working
- [ ] **Test data prepared**
  - [ ] Test certificate files created
  - [ ] Test domain names configured
  - [ ] Various user accounts set up

---

## 🧪 Test Scenario 1: Fresh Installation

### Windows Server Testing
- [ ] **1.1.1** Download scripts to clean Windows Server 2019
- [ ] **1.1.2** Run `Deploy_Velociraptor_Server.ps1` as Administrator
- [ ] **1.1.3** Verify PowerShell execution policy handling
- [ ] **1.1.4** Confirm automatic dependency downloads
- [ ] **1.1.5** Validate Velociraptor binary download
- [ ] **1.1.6** Check service installation and startup
- [ ] **1.1.7** Test web interface on port 8889
- [ ] **1.1.8** Verify log file creation in expected location
- [ ] **1.1.9** Confirm configuration file generation

### Windows Desktop Testing  
- [ ] **1.2.1** Test on Windows 10 Professional
- [ ] **1.2.2** Test on Windows 11 Professional
- [ ] **1.2.3** Verify UAC prompt handling
- [ ] **1.2.4** Test with different user privilege levels

### Linux Testing
- [ ] **1.3.1** Test PowerShell Core installation on Ubuntu
- [ ] **1.3.2** Run deployment scripts with pwsh
- [ ] **1.3.3** Verify systemd service creation
- [ ] **1.3.4** Test file permissions and ownership

### Results Documentation
- [ ] **1.4.1** Document installation times per platform
- [ ] **1.4.2** Record any error messages encountered
- [ ] **1.4.3** Note performance differences between platforms
- [ ] **1.4.4** Capture screenshots of successful installations

---

## 🔧 Test Scenario 2: Module Import Testing

### PowerShell Module Testing
- [ ] **2.1.1** Test individual script imports
  ```powershell
  . .\Deploy_Velociraptor_Server.ps1 -WhatIf
  ```
- [ ] **2.1.2** Verify function availability
  ```powershell
  Get-Command Write-Log, Get-UserInput, Test-Administrator
  ```
- [ ] **2.1.3** Test parameter validation
- [ ] **2.1.4** Verify error handling in functions

### Cross-Script Dependencies
- [ ] **2.2.1** Test helper function imports
- [ ] **2.2.2** Verify shared variable access
- [ ] **2.2.3** Test configuration data sharing
- [ ] **2.2.4** Validate logging consistency

### PowerShell Version Compatibility
- [ ] **2.3.1** Test with PowerShell 5.1 (Windows)
- [ ] **2.3.2** Test with PowerShell 7.x (Cross-platform)
- [ ] **2.3.3** Verify cmdlet compatibility
- [ ] **2.3.4** Test .NET Framework dependencies

---

## 🖥️ Test Scenario 3: GUI Workflow Testing

### GUI Launch and Navigation
- [ ] **3.1.1** Launch GUI without errors
  ```powershell
  pwsh gui/VelociraptorGUI.ps1
  ```
- [ ] **3.1.2** Verify velociraptor branding displays correctly
- [ ] **3.1.3** Test window resizing and responsiveness
- [ ] **3.1.4** Navigate through all wizard steps

### Encryption Options Testing
- [ ] **3.2.1** Test Self-Signed Certificate (Default)
  - [ ] Select self-signed option
  - [ ] Verify default settings applied
  - [ ] Generate configuration
  - [ ] Validate YAML output
  
- [ ] **3.2.2** Test Custom Certificate Configuration
  - [ ] Select custom certificate option
  - [ ] Enter certificate file paths
  - [ ] Enter private key file paths
  - [ ] Test file path validation
  - [ ] Generate configuration with custom certs
  
- [ ] **3.2.3** Test Let's Encrypt (AutoCert)
  - [ ] Select Let's Encrypt option
  - [ ] Enter valid domain name
  - [ ] Configure cache directory
  - [ ] Generate configuration
  - [ ] Verify AutoCert settings in YAML

### Security Settings Testing
- [ ] **3.3.1** Environment Selection
  - [ ] Test Production environment
  - [ ] Test Development environment
  - [ ] Test Testing environment
  - [ ] Test Staging environment
  
- [ ] **3.3.2** Log Level Configuration
  - [ ] Test ERROR level
  - [ ] Test WARN level
  - [ ] Test INFO level
  - [ ] Test DEBUG level
  
- [ ] **3.3.3** Security Options
  - [ ] Toggle debug logging
  - [ ] Toggle TLS 1.2+ enforcement
  - [ ] Toggle certificate validation
  - [ ] Test datastore size options

### Configuration Generation
- [ ] **3.4.1** Complete wizard with all combinations
- [ ] **3.4.2** Verify YAML syntax validation
- [ ] **3.4.3** Test generated config with Velociraptor
- [ ] **3.4.4** Validate all settings applied correctly

---

## 🌐 Test Scenario 4: Cross-Platform Testing

### Windows Platform Testing
- [ ] **4.1.1** Windows Server 2019
  - [ ] PowerShell 5.1 compatibility
  - [ ] Service management functionality
  - [ ] Windows Firewall integration
  - [ ] Event log integration
  
- [ ] **4.1.2** Windows Server 2022
  - [ ] Latest PowerShell features
  - [ ] Enhanced security features
  - [ ] Container compatibility
  
- [ ] **4.1.3** Windows 10/11 Desktop
  - [ ] UAC handling
  - [ ] Desktop GUI functionality
  - [ ] User profile integration

### Linux Platform Testing
- [ ] **4.2.1** Ubuntu 20.04 LTS
  - [ ] PowerShell Core 7.x installation
  - [ ] Systemd service integration
  - [ ] File permission handling
  - [ ] Package manager integration
  
- [ ] **4.2.2** Ubuntu 22.04 LTS
  - [ ] Latest PowerShell compatibility
  - [ ] Modern systemd features
  - [ ] Security enhancements

### macOS Testing (If Applicable)
- [ ] **4.3.1** PowerShell Core functionality
- [ ] **4.3.2** macOS service integration
- [ ] **4.3.3** File system compatibility

---

## ⚠️ Test Scenario 5: Error Handling Testing

### Network Error Testing
- [ ] **5.1.1** Simulate network disconnection during download
- [ ] **5.1.2** Test with slow network connections
- [ ] **5.1.3** Test with proxy configurations
- [ ] **5.1.4** Verify timeout handling

### System Resource Testing
- [ ] **5.2.1** Test with insufficient disk space
- [ ] **5.2.2** Test with limited memory
- [ ] **5.2.3** Test with high CPU usage
- [ ] **5.2.4** Test with locked files

### Permission Testing
- [ ] **5.3.1** Run without administrator privileges
- [ ] **5.3.2** Test with read-only directories
- [ ] **5.3.3** Test with restricted user accounts
- [ ] **5.3.4** Verify permission elevation prompts

### Configuration Error Testing
- [ ] **5.4.1** Invalid port numbers
- [ ] **5.4.2** Invalid file paths
- [ ] **5.4.3** Invalid domain names
- [ ] **5.4.4** Missing certificate files
- [ ] **5.4.5** Corrupted configuration files

### Service Error Testing
- [ ] **5.5.1** Port conflicts (8000, 8889 already in use)
- [ ] **5.5.2** Service startup failures
- [ ] **5.5.3** Database connection issues
- [ ] **5.5.4** Certificate validation failures

---

## 📚 Test Scenario 6: Documentation Testing

### README Validation
- [ ] **6.1.1** Follow installation instructions exactly
- [ ] **6.1.2** Test all provided command examples
- [ ] **6.1.3** Verify system requirements accuracy
- [ ] **6.1.4** Check prerequisite installation steps

### Configuration Examples
- [ ] **6.2.1** Test basic server configuration example
- [ ] **6.2.2** Test standalone configuration example
- [ ] **6.2.3** Test custom certificate example
- [ ] **6.2.4** Test Let's Encrypt example

### Troubleshooting Guide
- [ ] **6.3.1** Test common issue solutions
- [ ] **6.3.2** Verify error message explanations
- [ ] **6.3.3** Test recovery procedures
- [ ] **6.3.4** Validate log analysis guidance

### FAQ Testing
- [ ] **6.4.1** Test FAQ solutions
- [ ] **6.4.2** Verify compatibility information
- [ ] **6.4.3** Test performance tuning tips
- [ ] **6.4.4** Validate security recommendations

---

## 📊 Test Results Summary

### Overall Test Progress
- [ ] **Fresh Installation Tests:** ___/10 Passed
- [ ] **Module Import Tests:** ___/8 Passed  
- [ ] **GUI Workflow Tests:** ___/15 Passed
- [ ] **Cross-Platform Tests:** ___/12 Passed
- [ ] **Error Handling Tests:** ___/20 Passed
- [ ] **Documentation Tests:** ___/10 Passed

### Critical Issues Found
- [ ] **Issue #1:** [Description] - Severity: [Critical/High/Medium/Low]
- [ ] **Issue #2:** [Description] - Severity: [Critical/High/Medium/Low]
- [ ] **Issue #3:** [Description] - Severity: [Critical/High/Medium/Low]

### Performance Metrics
- [ ] **Average Installation Time:** ___ minutes
- [ ] **GUI Response Time:** ___ seconds per step
- [ ] **Configuration Generation Time:** ___ seconds
- [ ] **Service Startup Time:** ___ seconds

### Tester Sign-off
- [ ] **Lead Tester:** [Name] - Date: [Date] - Status: [Pass/Fail]
- [ ] **Windows Tester:** [Name] - Date: [Date] - Status: [Pass/Fail]
- [ ] **Linux Tester:** [Name] - Date: [Date] - Status: [Pass/Fail]
- [ ] **GUI Tester:** [Name] - Date: [Date] - Status: [Pass/Fail]
- [ ] **Documentation Tester:** [Name] - Date: [Date] - Status: [Pass/Fail]

---

## ✅ Beta Release Approval

### Final Checklist
- [ ] **All critical bugs resolved**
- [ ] **95%+ test pass rate achieved**
- [ ] **Documentation updated**
- [ ] **Performance benchmarks met**
- [ ] **Cross-platform compatibility confirmed**
- [ ] **Security review completed**

### Approval Signatures
- [ ] **Technical Lead:** [Name] - Date: [Date]
- [ ] **QA Lead:** [Name] - Date: [Date]  
- [ ] **Product Owner:** [Name] - Date: [Date]

---

**🦖 Ready to hunt down those bugs and make this release perfect!**

*This comprehensive UAT checklist ensures thorough testing of all enhanced Velociraptor setup script features.*