# 🦖 Velociraptor Setup Scripts - Beta Testing Plan

## Overview
This document outlines the comprehensive User Acceptance Testing (UAT) plan for the enhanced Velociraptor Setup Scripts with new GUI encryption options and deployment features.

## 🎯 Testing Objectives

1. **Validate Enhanced GUI Features** - Ensure all new encryption options work correctly
2. **Cross-Platform Compatibility** - Verify functionality across Windows, macOS, and Linux
3. **Real-World Deployment Testing** - Test actual Velociraptor deployments
4. **Error Handling Validation** - Ensure graceful error handling and recovery
5. **Documentation Accuracy** - Verify all instructions are clear and complete

## 📋 UAT Scenarios Checklist

### Scenario 1: Fresh Installation Test
**Objective:** New user installs and runs Velociraptor from scratch

#### Test Steps:
- [ ] **1.1** Download scripts to clean system
- [ ] **1.2** Run `Deploy_Velociraptor_Server.ps1` without prior setup
- [ ] **1.3** Verify automatic dependency installation
- [ ] **1.4** Confirm successful Velociraptor download and installation
- [ ] **1.5** Validate service creation and startup
- [ ] **1.6** Test web interface accessibility
- [ ] **1.7** Verify log file creation and content

#### Expected Results:
- ✅ Clean installation completes without errors
- ✅ All dependencies installed automatically
- ✅ Velociraptor service starts successfully
- ✅ Web interface accessible on configured ports
- ✅ Logs show successful startup

#### Test Data Required:
- Clean Windows Server 2019/2022 system
- Clean Ubuntu 20.04/22.04 system
- Clean macOS system (if applicable)

---

### Scenario 2: Module Import Test
**Objective:** Verify all PowerShell modules and functions load correctly

#### Test Steps:
- [ ] **2.1** Import all PowerShell scripts individually
- [ ] **2.2** Test `Import-Module` functionality
- [ ] **2.3** Verify all functions are available
- [ ] **2.4** Test function parameter validation
- [ ] **2.5** Validate error handling in module imports
- [ ] **2.6** Test cross-script dependencies

#### Expected Results:
- ✅ All modules import without errors
- ✅ All functions accessible and working
- ✅ Parameter validation works correctly
- ✅ Dependencies resolve properly

#### Test Commands:
```powershell
# Test individual script imports
. .\Deploy_Velociraptor_Server.ps1 -WhatIf
. .\Deploy_Velociraptor_Standalone.ps1 -WhatIf
. .\gui\VelociraptorGUI.ps1 -StartMinimized

# Test function availability
Get-Command -Module VelociraptorDeploy*
```

---

### Scenario 3: GUI Workflow Test
**Objective:** Complete configuration wizard with all new encryption options

#### Test Steps:
- [ ] **3.1** Launch enhanced GUI wizard
- [ ] **3.2** Navigate through all wizard steps
- [ ] **3.3** Test Self-Signed certificate option (default)
- [ ] **3.4** Test Custom certificate file configuration
- [ ] **3.5** Test Let's Encrypt (AutoCert) setup
- [ ] **3.6** Validate security settings configuration
- [ ] **3.7** Test environment selection options
- [ ] **3.8** Verify configuration file generation
- [ ] **3.9** Validate generated YAML syntax
- [ ] **3.10** Test configuration with actual Velociraptor

#### Expected Results:
- ✅ GUI launches without errors
- ✅ All wizard steps navigate correctly
- ✅ Encryption options work as expected
- ✅ Configuration file generates properly
- ✅ Generated config works with Velociraptor

#### Test Matrix:
| Encryption Type | Environment | Log Level | Expected Result |
|----------------|-------------|-----------|-----------------|
| Self-Signed    | Production  | INFO      | ✅ Success      |
| Self-Signed    | Development | DEBUG     | ✅ Success      |
| Custom Cert    | Production  | WARN      | ✅ Success      |
| Let's Encrypt  | Production  | ERROR     | ✅ Success      |

---

### Scenario 4: Cross-Platform Test
**Objective:** Test functionality across different operating systems

#### Test Platforms:
- [ ] **4.1** Windows Server 2019
- [ ] **4.2** Windows Server 2022
- [ ] **4.3** Windows 10/11 Professional
- [ ] **4.4** Ubuntu 20.04 LTS
- [ ] **4.5** Ubuntu 22.04 LTS
- [ ] **4.6** macOS (if PowerShell Core available)

#### Test Steps per Platform:
- [ ] **4.1.1** PowerShell version compatibility check
- [ ] **4.1.2** Script execution policy validation
- [ ] **4.1.3** Network connectivity tests
- [ ] **4.1.4** File system permissions validation
- [ ] **4.1.5** Service management functionality
- [ ] **4.1.6** GUI functionality (Windows only)

#### Expected Results:
- ✅ Scripts run on all supported platforms
- ✅ Platform-specific features work correctly
- ✅ Error messages are platform-appropriate
- ✅ File paths resolve correctly per platform

---

### Scenario 5: Error Handling Test
**Objective:** Verify graceful error handling and recovery

#### Test Cases:
- [ ] **5.1** Network connectivity failure during download
- [ ] **5.2** Insufficient disk space
- [ ] **5.3** Permission denied scenarios
- [ ] **5.4** Invalid configuration parameters
- [ ] **5.5** Service startup failures
- [ ] **5.6** Port conflicts
- [ ] **5.7** Certificate file not found
- [ ] **5.8** Invalid domain for Let's Encrypt

#### Test Steps:
- [ ] **5.1.1** Simulate network failures
- [ ] **5.1.2** Test with limited disk space
- [ ] **5.1.3** Run without administrator privileges
- [ ] **5.1.4** Provide invalid input parameters
- [ ] **5.1.5** Test with ports already in use
- [ ] **5.1.6** Test with missing certificate files

#### Expected Results:
- ✅ Clear error messages displayed
- ✅ Graceful failure without system damage
- ✅ Helpful troubleshooting guidance provided
- ✅ Logs contain detailed error information
- ✅ Recovery options suggested where possible

---

### Scenario 6: Documentation Test
**Objective:** Verify instructions are clear and complete

#### Test Steps:
- [ ] **6.1** Follow README instructions exactly
- [ ] **6.2** Test all provided examples
- [ ] **6.3** Verify troubleshooting guides
- [ ] **6.4** Test FAQ solutions
- [ ] **6.5** Validate configuration examples
- [ ] **6.6** Check link accuracy

#### Expected Results:
- ✅ Instructions are clear and unambiguous
- ✅ All examples work as documented
- ✅ Troubleshooting guides resolve issues
- ✅ No broken links or references
- ✅ Screenshots match current interface

---

## 🧪 Testing Environment Requirements

### Minimum Test Environments:
1. **Windows Server 2019** - Primary deployment target
2. **Windows 10/11 Pro** - Desktop deployment testing
3. **Ubuntu 20.04 LTS** - Linux compatibility testing
4. **Clean Virtual Machines** - Fresh installation testing

### Required Test Data:
- Valid domain names for Let's Encrypt testing
- Test certificate files for custom cert testing
- Various network configurations
- Different user permission levels

### Testing Tools:
- PowerShell 5.1+ and PowerShell Core 7+
- Virtual machine environments
- Network simulation tools
- Log analysis tools

## 📊 Success Criteria

### Critical Success Factors:
- [ ] **100% of fresh installations succeed** on supported platforms
- [ ] **All GUI workflows complete** without errors
- [ ] **Generated configurations work** with actual Velociraptor
- [ ] **Error handling provides** clear guidance
- [ ] **Documentation enables** successful deployment

### Performance Benchmarks:
- Installation completes within 10 minutes
- GUI responds within 2 seconds per step
- Configuration generation completes within 5 seconds
- Service startup completes within 30 seconds

## 🐛 Bug Reporting Template

### Bug Report Format:
```
**Bug ID:** BETA-XXX
**Severity:** Critical/High/Medium/Low
**Platform:** Windows/Linux/macOS
**Scenario:** Which test scenario
**Steps to Reproduce:**
1. Step 1
2. Step 2
3. Step 3

**Expected Result:** What should happen
**Actual Result:** What actually happened
**Screenshots:** If applicable
**Logs:** Relevant log entries
**Workaround:** If available
```

## 📝 Test Execution Tracking

### Test Progress Tracking:
- [ ] Scenario 1: Fresh Installation Test
- [ ] Scenario 2: Module Import Test  
- [ ] Scenario 3: GUI Workflow Test
- [ ] Scenario 4: Cross-Platform Test
- [ ] Scenario 5: Error Handling Test
- [ ] Scenario 6: Documentation Test

### Tester Assignments:
- **Lead Tester:** [Name] - Overall coordination
- **Windows Tester:** [Name] - Windows platform testing
- **Linux Tester:** [Name] - Linux platform testing
- **GUI Tester:** [Name] - GUI workflow testing
- **Documentation Tester:** [Name] - Documentation validation

## 🚀 Beta Release Criteria

### Ready for Production When:
- [ ] All critical and high severity bugs resolved
- [ ] 95%+ test case pass rate achieved
- [ ] Documentation updated based on feedback
- [ ] Performance benchmarks met
- [ ] Cross-platform compatibility confirmed

---

**🦖 Let's make this beta testing as thorough as a velociraptor hunt!** 

*This comprehensive testing plan ensures our enhanced Velociraptor setup scripts are production-ready and user-friendly.*