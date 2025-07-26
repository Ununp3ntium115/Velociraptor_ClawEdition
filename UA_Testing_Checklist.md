# Velociraptor GUI - User Acceptance Testing Checklist

## 🎯 **UA Testing Phase - Complete Feature Validation**

### **Test Environment Setup**
- [ ] **Git Repository**: Ensure you're on the `main` branch with latest changes
- [ ] **PowerShell**: Version 7+ recommended (5.1+ minimum for Windows)
- [ ] **Windows OS**: Required for Windows Forms GUI testing
- [ ] **Permissions**: Administrator privileges for deployment script testing
- [ ] **Network**: Internet access for Velociraptor binary downloads
- [ ] **Storage**: At least 1GB free space for testing directories

### **Pre-Testing Verification**
```powershell
# Verify you're on main branch with latest updates
git status
git pull origin main

# Verify PowerShell version
$PSVersionTable.PSVersion

# Test PowerShell execution policy
Get-ExecutionPolicy

# If needed, set execution policy for testing
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## **📝 STEP-BY-STEP UA TESTING**

### **Step 1: Welcome Screen**
**Expected Behavior:**
- [ ] Professional welcome message displays
- [ ] Velociraptor branding and version info visible
- [ ] Configuration steps overview shown
- [ ] Next button enabled, Back button disabled
- [ ] Cancel button functional

**Test Actions:**
```powershell
# From repository root directory
.\gui\VelociraptorGUI.ps1

# Alternative: Launch minimized for testing
.\gui\VelociraptorGUI.ps1 -StartMinimized
```
1. Verify welcome content is readable and professional
2. Test Next button navigation
3. Test Cancel button (should prompt for confirmation)
4. Check window sizing and positioning
5. Verify all text is properly formatted and visible

---

### **Step 2: Deployment Type Selection**
**Expected Behavior:**
- [ ] Three deployment options: Server, Standalone, Client
- [ ] Radio button selection works correctly
- [ ] Dynamic descriptions update when selection changes
- [ ] Detailed information panel shows use cases
- [ ] Configuration data updates properly

**Test Actions:**
1. Select each deployment type
2. Verify descriptions change dynamically
3. Confirm only one option can be selected
4. Test navigation (Back/Next buttons)

---

### **Step 3: Storage Configuration**
**Expected Behavior:**
- [ ] Datastore directory field with browse button
- [ ] Logs directory field with browse button
- [ ] Certificate expiration dropdown (1, 2, 5, 10 years)
- [ ] Registry usage checkbox
- [ ] Registry path field (enabled/disabled based on checkbox)
- [ ] Browse dialogs work correctly

**Test Actions:**
1. Test datastore directory input and browse button
2. Test logs directory input and browse button
3. Test certificate expiration dropdown
4. Toggle registry checkbox and verify path field state
5. Enter custom registry path
6. Verify all fields save data correctly

---

### **Step 4: Network Configuration**
**Expected Behavior:**
- [ ] API server bind address and port fields
- [ ] GUI server bind address and port fields
- [ ] Network configuration notes panel
- [ ] Validate network settings button
- [ ] Port conflict detection
- [ ] IP address format validation

**Test Actions:**
1. Enter various IP addresses (valid/invalid)
2. Test port numbers (valid range 1024-65535)
3. Test port conflict detection (same ports)
4. Click "Validate Network Settings" button
5. Verify validation messages appear correctly

---

### **Step 5: Authentication Configuration**
**Expected Behavior:**
- [ ] Organization name field
- [ ] Admin username field
- [ ] Password field with masking
- [ ] Password confirmation field
- [ ] Real-time password strength indicator
- [ ] Password match validation
- [ ] VQL restriction checkbox
- [ ] Generate secure password button

**Test Actions:**
1. Enter organization name
2. Enter admin username
3. Test password field (should be masked)
4. Enter different passwords and verify strength indicator
5. Test password confirmation matching
6. Click "Generate Secure Password" button
7. Toggle VQL restriction checkbox

---

### **Step 6: Review & Generate Configuration**
**Expected Behavior:**
- [ ] Comprehensive configuration summary
- [ ] Scrollable review text box
- [ ] Configuration validation with issue reporting
- [ ] Generate configuration file button
- [ ] Export settings button
- [ ] Professional tree-structured display
- [ ] Validation status indicators

**Test Actions:**
1. Review all configuration settings in summary
2. Verify validation issues are highlighted (if any)
3. Test "Generate Configuration File" button
4. Test "Export Settings" button
5. Verify file save dialogs work
6. Check generated YAML file content

---

### **Step 7: Completion**
**Expected Behavior:**
- [ ] Success message displays
- [ ] Next steps information shown
- [ ] Finish button closes application cleanly

**Test Actions:**
1. Verify completion message
2. Click Finish button
3. Confirm application closes properly

---

## **🔍 CRITICAL UA TEST SCENARIOS**

### **Scenario 1: Server Deployment (Full Configuration)**
```powershell
# Test complete server setup workflow
.\gui\VelociraptorGUI.ps1
```
1. Select **Server deployment**
2. Configure custom datastore: `C:\VelociraptorData\Server`
3. Configure logs directory: `C:\VelociraptorLogs\Server`
4. Set **2-year certificate expiration**
5. **Enable registry storage** with path: `HKLM:\SOFTWARE\Velociraptor`
6. Configure network settings:
   - API Server: `0.0.0.0:8000`
   - GUI Server: `127.0.0.1:8889`
7. Set strong admin credentials:
   - Organization: `Test Organization`
   - Username: `admin`
   - Password: Use generated secure password
8. **Generate configuration file** and save as `server-config.yaml`
9. **Test deployment script** with generated config

### **Scenario 2: Standalone Deployment (Minimal Configuration)**
```powershell
# Test standalone deployment workflow
.\gui\VelociraptorGUI.ps1
```
1. Select **Standalone deployment**
2. Use default directories (verify they're reasonable)
3. Set **1-year certificate expiration**
4. **Disable registry storage**
5. Use localhost binding (`127.0.0.1`)
6. Set basic admin credentials
7. Generate configuration file as `standalone-config.yaml`
8. **Test with deployment script**:
   ```powershell
   .\Deploy_Velociraptor_Standalone.ps1 -Force
   ```

### **Scenario 3: Client Configuration**
```powershell
# Test client configuration workflow
.\gui\VelociraptorGUI.ps1
```
1. Select **Client deployment**
2. Configure minimal storage requirements
3. Set network settings for server connection
4. Configure client authentication
5. Generate client configuration file
6. Verify client config is valid YAML

### **Scenario 4: Integration Testing with Deployment Scripts**
```powershell
# Test GUI + Deployment Script Integration
# 1. Generate config with GUI
.\gui\VelociraptorGUI.ps1

# 2. Test standalone deployment
.\Deploy_Velociraptor_Standalone.ps1 -InstallDir "C:\TestVelo" -GuiPort 9999

# 3. Test server deployment  
.\Deploy_Velociraptor_Server.ps1 -InstallDir "C:\TestVeloServer"

# 4. Verify deployments work with GUI-generated configs
```

### **Scenario 5: Error Handling & Validation**
1. **Empty Field Testing**:
   - Leave organization name empty
   - Skip password fields
   - Leave network fields blank
2. **Invalid Input Testing**:
   - Enter invalid IP addresses (`999.999.999.999`)
   - Use invalid port numbers (`0`, `99999`)
   - Enter conflicting port numbers
3. **Password Testing**:
   - Test weak passwords (`123`, `password`)
   - Test password mismatch scenarios
   - Verify strength indicator accuracy
4. **Network Validation**:
   - Test port conflicts (same API and GUI ports)
   - Test invalid IP formats
   - Test reserved port numbers
5. **Recovery Testing**:
   - Fix validation errors and re-test
   - Verify error messages are helpful
   - Test navigation with validation errors

---

## **✅ ACCEPTANCE CRITERIA**

### **Functional Requirements**
- [ ] All wizard steps navigate correctly
- [ ] All form fields save and retrieve data properly
- [ ] Configuration validation works accurately
- [ ] File generation produces valid YAML
- [ ] Error handling is user-friendly
- [ ] UI is responsive and professional

### **Usability Requirements**
- [ ] Interface is intuitive and easy to navigate
- [ ] Help text and descriptions are clear
- [ ] Validation messages are helpful
- [ ] Professional appearance maintained throughout
- [ ] No crashes or unexpected behavior

### **Technical Requirements**
- [ ] PowerShell compatibility maintained (5.1+ and 7+)
- [ ] Windows Forms integration stable
- [ ] File I/O operations work correctly
- [ ] Memory usage reasonable (< 100MB)
- [ ] Performance acceptable for wizard workflow (< 5s startup)
- [ ] Integration with deployment scripts seamless
- [ ] Generated configurations are valid YAML
- [ ] Error handling is robust and user-friendly

---

## **📋 COMPREHENSIVE UA TESTING GUIDELINES**

### **Pre-Testing Setup Checklist**
```powershell
# 1. Environment Verification
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion
$PSVersionTable.PSVersion
Get-ExecutionPolicy

# 2. Repository Status Check
git status
git log --oneline -5
ls gui/, Deploy_Velociraptor_*.ps1

# 3. Permissions Check
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

# 4. Network Connectivity Test
Test-NetConnection -ComputerName github.com -Port 443
Test-NetConnection -ComputerName api.github.com -Port 443
```

### **Testing Methodology**

#### **1. Systematic Testing Approach**
- **Sequential Testing**: Complete each step before moving to next
- **Documentation**: Record all observations and issues
- **Screenshots**: Capture key screens and error messages
- **Timing**: Note performance metrics for each operation
- **Recovery**: Test error recovery and user guidance

#### **2. Test Data Standards**
```powershell
# Standard Test Data for Consistency
$TestData = @{
    Organization = "UA Test Organization"
    AdminUser = "testadmin"
    StrongPassword = "UATest2025!@#$"
    WeakPassword = "123"
    ValidIP = "192.168.1.100"
    InvalidIP = "999.999.999.999"
    ValidPort = "8889"
    InvalidPort = "99999"
    TestDatastore = "C:\UATest\VelociraptorData"
    TestLogs = "C:\UATest\VelociraptorLogs"
}
```

#### **3. Issue Documentation Template**
For each issue found, document:
```
**Issue ID**: UA-001
**Component**: GUI Wizard - Step 3
**Severity**: High/Medium/Low
**Description**: Brief description of the issue
**Steps to Reproduce**: 
1. Step 1
2. Step 2
3. Step 3
**Expected Result**: What should happen
**Actual Result**: What actually happened
**Workaround**: If any workaround exists
**Status**: Open/Fixed/Verified
```

### **Performance Benchmarks**
- **GUI Startup**: < 5 seconds
- **Step Navigation**: < 1 second per step
- **File Generation**: < 3 seconds for YAML
- **Deployment Script**: < 30 seconds for download and setup
- **Memory Usage**: < 100MB during GUI operation
- **CPU Usage**: < 10% during normal operation

### **Success Criteria**
- ✅ **All test scenarios complete successfully**
- ✅ **No critical or high-severity issues remain**
- ✅ **Performance meets or exceeds benchmarks**
- ✅ **User experience is intuitive and professional**
- ✅ **Integration between GUI and deployment scripts works seamlessly**
- ✅ **Error handling provides clear guidance to users**
- ✅ **Generated configurations are valid and functional**

---

## **🚀 UA TESTING STATUS**

**Current Phase:** ✅ Ready for Comprehensive User Acceptance Testing
**Branch:** `main` (consolidated with all improvements)
**Test Environment:** Windows with PowerShell 5.1+ or 7+
**GUI Version:** v5.0.1 Enhanced with Deployment Integration
**Deployment Scripts:** Enhanced with parameter support and better error handling

### **Testing Components Available:**
- ✅ **GUI Wizard**: `gui/VelociraptorGUI.ps1`
- ✅ **Standalone Deployment**: `Deploy_Velociraptor_Standalone.ps1`
- ✅ **Server Deployment**: `Deploy_Velociraptor_Server.ps1`
- ✅ **Testing Documentation**: This checklist and results file
- ✅ **Branch Consolidation**: All improvements merged to main

### **Quick Start Testing Commands:**
```powershell
# Clone and setup (if needed)
git clone <repository-url>
cd Velociraptor_Setup_Scripts
git checkout main
git pull origin main

# Start GUI testing
.\gui\VelociraptorGUI.ps1

# Test standalone deployment
.\Deploy_Velociraptor_Standalone.ps1 -Force

# Test server deployment
.\Deploy_Velociraptor_Server.ps1 -Force
```

**🎯 Ready to begin comprehensive UA testing on main branch!**