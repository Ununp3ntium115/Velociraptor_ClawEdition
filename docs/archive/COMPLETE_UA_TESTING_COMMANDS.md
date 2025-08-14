# 🚀 Complete UA Testing Command Guide

## **Phase 0: Repository Setup (First Time Users)**

### **0.1 Clone Repository**
```powershell
# Clone the Velociraptor Setup Scripts repository
git clone https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts.git

# Navigate to repository directory
cd Velociraptor_Setup_Scripts

# Verify you're on main branch
git status
git branch
```

### **0.2 For Existing Users**
```powershell
# Navigate to existing repository
cd Velociraptor_Setup_Scripts

# Update to latest changes
git checkout main
git pull origin main
```

---

## **Phase 1: Environment Setup & Verification (2 minutes)**

### **1.1 Repository & Branch Verification**
```powershell
# Verify you're on main branch with latest changes
git status
git pull origin main

# Verify all testing components are present
ls gui/VelociraptorGUI.ps1
ls Deploy_Velociraptor_Standalone.ps1
ls Deploy_Velociraptor_Server.ps1
ls UA_Testing_Checklist.md
ls UA_Testing_Results.md
```

### **1.2 PowerShell Environment Check**
```powershell
# Check PowerShell version (5.1+ or 7+ required)
$PSVersionTable.PSVersion

# Check execution policy
Get-ExecutionPolicy

# Set execution policy if needed (run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verify Windows Forms availability (Windows only)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
```

### **1.3 Administrator Privileges Check**
```powershell
# Verify admin privileges (required for deployment testing)
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

# If false, restart PowerShell as Administrator
```

### **1.4 Network Connectivity Test**
```powershell
# Test GitHub connectivity for Velociraptor downloads
Test-NetConnection -ComputerName github.com -Port 443
Test-NetConnection -ComputerName api.github.com -Port 443
```

---

## **Phase 2: GUI Wizard Testing (15 minutes)**

### **2.1 Basic GUI Launch Test**
```powershell
# Launch GUI wizard (normal mode)
.\gui\VelociraptorGUI.ps1

# Alternative: Launch minimized for testing
.\gui\VelociraptorGUI.ps1 -StartMinimized
```

### **2.2 Complete Workflow Tests**

#### **Test Scenario A: Server Deployment Configuration**
```powershell
# Launch GUI and configure:
.\gui\VelociraptorGUI.ps1

# Follow these steps in the GUI:
# 1. Select "Server Deployment"
# 2. Datastore: C:\VelociraptorData\Server
# 3. Logs: C:\VelociraptorLogs\Server  
# 4. Certificate: 2 years
# 5. Registry: Enable with HKLM:\SOFTWARE\Velociraptor
# 6. Network: API=0.0.0.0:8000, GUI=127.0.0.1:8889
# 7. Org: "Test Organization", User: "admin"
# 8. Generate secure password
# 9. Save config as "server-config.yaml"
```

#### **Test Scenario B: Standalone Deployment Configuration**
```powershell
# Launch GUI for standalone test
.\gui\VelociraptorGUI.ps1

# Follow these steps in the GUI:
# 1. Select "Standalone Deployment"
# 2. Use default directories
# 3. Certificate: 1 year
# 4. Registry: Disable
# 5. Network: localhost binding
# 6. Basic credentials
# 7. Save config as "standalone-config.yaml"
```

#### **Test Scenario C: Error Handling Validation**
```powershell
# Launch GUI for error testing
.\gui\VelociraptorGUI.ps1

# Test these error scenarios:
# 1. Leave required fields empty
# 2. Enter invalid IP: 999.999.999.999
# 3. Use invalid ports: 0, 99999
# 4. Set conflicting ports (same API and GUI)
# 5. Use weak passwords: "123", "password"
# 6. Verify validation messages appear
# 7. Fix errors and verify recovery
```

---

## **Phase 3: Deployment Script Testing (20 minutes)**

### **3.1 Standalone Deployment Tests**

#### **Basic Standalone Test**
```powershell
# Test with default parameters
.\Deploy_Velociraptor_Standalone.ps1 -Force

# Check if Velociraptor is running
Get-Process velociraptor -ErrorAction SilentlyContinue

# Check if GUI is accessible (should open browser to localhost:8889)
Start-Process "http://localhost:8889"
```

#### **Advanced Standalone Test**
```powershell
# Test with custom parameters
.\Deploy_Velociraptor_Standalone.ps1 -InstallDir "C:\TestVelo" -GuiPort 9999 -Force

# Test with custom datastore
.\Deploy_Velociraptor_Standalone.ps1 -DataStore "C:\CustomData" -SkipFirewall -Force

# Verify custom installation
ls "C:\TestVelo\velociraptor.exe"
Test-NetConnection -ComputerName localhost -Port 9999
```

### **3.2 Server Deployment Tests**

#### **Basic Server Test**
```powershell
# Test server deployment
.\Deploy_Velociraptor_Server.ps1 -Force

# Verify server installation
Get-Process velociraptor -ErrorAction SilentlyContinue
```

#### **Advanced Server Test**
```powershell
# Test with custom directory
.\Deploy_Velociraptor_Server.ps1 -InstallDir "C:\VeloServer" -Force

# Verify custom server installation
ls "C:\VeloServer\velociraptor.exe"
```

### **3.3 What-If Testing (Safe Dry Run)**
```powershell
# Test deployment scripts without actually deploying
.\Deploy_Velociraptor_Standalone.ps1 -WhatIf
.\Deploy_Velociraptor_Server.ps1 -WhatIf
```

---

## **Phase 4: Integration Testing (10 minutes)**

### **4.1 GUI + Deployment Integration**
```powershell
# Step 1: Generate config with GUI
.\gui\VelociraptorGUI.ps1
# Save configuration as "integration-test.yaml"

# Step 2: Use generated config with deployment (if supported)
# Note: Current scripts don't directly use GUI configs, but verify compatibility

# Step 3: Test both components work together
.\Deploy_Velociraptor_Standalone.ps1 -GuiPort 8888 -Force
# Then launch GUI to verify it can connect/work with deployed instance
```

### **4.2 Multiple Deployment Type Testing**
```powershell
# Test different deployment types in sequence
# (Clean up between tests)

# Test 1: Standalone
.\Deploy_Velociraptor_Standalone.ps1 -InstallDir "C:\Test1" -GuiPort 8881 -Force

# Test 2: Server  
.\Deploy_Velociraptor_Server.ps1 -InstallDir "C:\Test2" -Force

# Verify both can coexist or identify conflicts
Get-Process velociraptor -ErrorAction SilentlyContinue
netstat -an | findstr ":888"
```

---

## **Phase 5: Performance & Validation Testing (5 minutes)**

### **5.1 Performance Benchmarks**
```powershell
# Measure GUI startup time
Measure-Command { .\gui\VelociraptorGUI.ps1 -StartMinimized }
# Target: < 5 seconds

# Measure deployment time
Measure-Command { .\Deploy_Velociraptor_Standalone.ps1 -Force }
# Target: < 30 seconds for download and setup
```

### **5.2 Resource Usage Monitoring**
```powershell
# Monitor memory usage during GUI operation
Get-Process powershell | Select-Object ProcessName, WorkingSet, CPU

# Monitor during deployment
Get-Process | Where-Object {$_.ProcessName -like "*velociraptor*" -or $_.ProcessName -like "*powershell*"} | Select-Object ProcessName, WorkingSet, CPU
```

### **5.3 Configuration Validation**
```powershell
# If you generated YAML configs, validate them
Get-Content "server-config.yaml" | Select-String -Pattern "version|bind_address|gui_bind_address"
Get-Content "standalone-config.yaml" | Select-String -Pattern "version|bind_address|gui_bind_address"
```

---

## **Phase 6: Cleanup & Documentation (3 minutes)**

### **6.1 Service Cleanup**
```powershell
# Stop any running Velociraptor processes
Get-Process velociraptor -ErrorAction SilentlyContinue | Stop-Process -Force

# Check for any remaining processes
Get-Process | Where-Object {$_.ProcessName -like "*velociraptor*"}
```

### **6.2 Test Results Documentation**
```powershell
# Create test results summary
$TestResults = @"
UA Testing Results - $(Get-Date)
================================
Environment: $($PSVersionTable.PSVersion)
Admin Rights: $(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))

GUI Tests:
- Launch: [PASS/FAIL]
- Server Config: [PASS/FAIL] 
- Standalone Config: [PASS/FAIL]
- Error Handling: [PASS/FAIL]

Deployment Tests:
- Standalone Basic: [PASS/FAIL]
- Standalone Advanced: [PASS/FAIL]
- Server Basic: [PASS/FAIL]
- Server Advanced: [PASS/FAIL]

Integration Tests:
- GUI + Deployment: [PASS/FAIL]
- Multiple Types: [PASS/FAIL]

Performance:
- GUI Startup: [X] seconds
- Deployment Time: [X] seconds
- Memory Usage: [X] MB

Issues Found:
- [List any issues]

Overall Status: [PASS/FAIL]
"@

$TestResults | Out-File "UA_Testing_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
```

---

## **Quick Reference: Essential Commands for New Users**

### **Complete First-Time Setup**
```powershell
# 1. Clone repository
git clone https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts.git
cd Velociraptor_Setup_Scripts

# 2. Environment check
$PSVersionTable.PSVersion
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

# 3. Set execution policy if needed
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 4. Test GUI
.\gui\VelociraptorGUI.ps1

# 5. Test deployment
.\Deploy_Velociraptor_Standalone.ps1 -Force

# 6. Cleanup
Get-Process velociraptor -ErrorAction SilentlyContinue | Stop-Process -Force
```

### **Quick Update for Existing Users**
```powershell
# 1. Update repository
cd Velociraptor_Setup_Scripts
git pull origin main

# 2. Quick test
.\gui\VelociraptorGUI.ps1
.\Deploy_Velociraptor_Standalone.ps1 -Force
```

---

## **Success Criteria Checklist**

After running all commands, verify:
- [ ] Repository cloned successfully
- [ ] GUI launches without errors
- [ ] All wizard steps navigate correctly
- [ ] Configuration files generate successfully
- [ ] Deployment scripts complete without errors
- [ ] Velociraptor processes start correctly
- [ ] Network ports are accessible
- [ ] No critical issues found
- [ ] Performance meets benchmarks (< 5s GUI, < 30s deployment)

---

## **Repository Information**

- **Repository URL**: https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts.git
- **Main Branch**: `main` (all improvements consolidated)
- **Requirements**: Windows OS, PowerShell 5.1+, Administrator privileges
- **Components**: GUI Wizard, Enhanced Deployment Scripts, Comprehensive Documentation

**🎯 Follow these commands in sequence for complete UA testing from repository clone to final validation!**