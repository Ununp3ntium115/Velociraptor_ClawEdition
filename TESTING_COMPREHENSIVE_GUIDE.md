# 🧪 Comprehensive Testing Guide

## 📋 **Complete Testing Framework for Velociraptor Setup Scripts**

**Version**: v5.0.1-beta  
**Status**: Production Ready  
**Last Updated**: $(date)  

This guide consolidates all testing procedures, from basic user acceptance testing to advanced moonshot validation.

---

## 🎯 **Testing Overview**

### **Testing Levels**
1. **Basic UA Testing** - Core functionality validation
2. **Advanced Feature Testing** - Enhanced capabilities validation  
3. **Cross-Platform Testing** - Multi-OS compatibility
4. **Performance Testing** - Benchmarks and optimization
5. **Moonshot Testing** - Future technology validation

### **Testing Philosophy**
- **User-Centric**: Test from user perspective
- **Comprehensive**: Cover all use cases and edge cases
- **Automated**: Repeatable and consistent testing
- **Documentation-Driven**: Clear procedures and expectations

---

## 🚀 **Quick Start Testing (15 minutes)**

### **Prerequisites**
```powershell
# Verify environment
$PSVersionTable.PSVersion  # 5.1+ or 7+
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  # Must be true
```

### **Essential Tests**
```powershell
# 1. Repository setup
git clone https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts.git
cd Velociraptor_Setup_Scripts
git checkout main

# 2. GUI test
.\gui\VelociraptorGUI.ps1

# 3. Deployment test
.\Deploy_Velociraptor_Standalone.ps1 -Force

# 4. Cleanup
Get-Process velociraptor -ErrorAction SilentlyContinue | Stop-Process -Force
```

---

## 📝 **Detailed Testing Procedures**

### **Phase 1: Environment Setup & Verification**

#### **1.1 Repository Verification**
```powershell
# Verify branch and updates
git status
git pull origin main

# Verify required files
Test-Path "gui\VelociraptorGUI.ps1"
Test-Path "Deploy_Velociraptor_Standalone.ps1"
Test-Path "Deploy_Velociraptor_Server.ps1"
```

#### **1.2 PowerShell Environment**
```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Check execution policy
Get-ExecutionPolicy

# Set if needed (as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Test Windows Forms (Windows only)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
```

#### **1.3 Network Connectivity**
```powershell
# Test GitHub connectivity
Test-NetConnection -ComputerName github.com -Port 443
Test-NetConnection -ComputerName api.github.com -Port 443
```

### **Phase 2: GUI Wizard Testing**

#### **2.1 Basic GUI Launch**
```powershell
# Normal launch
.\gui\VelociraptorGUI.ps1

# Minimized launch for testing
.\gui\VelociraptorGUI.ps1 -StartMinimized
```

#### **2.2 Complete Workflow Tests**

**Server Deployment Configuration:**
1. Launch GUI: `.\gui\VelociraptorGUI.ps1`
2. Select "Server Deployment"
3. Configure storage: `C:\VelociraptorData\Server`, `C:\VelociraptorLogs\Server`
4. Set certificate: 2 years
5. Enable registry: `HKLM:\SOFTWARE\Velociraptor`
6. Network: API=0.0.0.0:8000, GUI=127.0.0.1:8889
7. Credentials: Org="Test Organization", User="admin"
8. Generate secure password
9. Save as "server-config.yaml"

**Standalone Deployment Configuration:**
1. Launch GUI: `.\gui\VelociraptorGUI.ps1`
2. Select "Standalone Deployment"
3. Use default directories
4. Set certificate: 1 year
5. Disable registry
6. Network: localhost binding
7. Basic credentials
8. Save as "standalone-config.yaml"

#### **2.3 Error Handling Validation**
Test these scenarios:
- Empty required fields
- Invalid IP addresses (999.999.999.999)
- Invalid ports (0, 99999)
- Conflicting ports (same API and GUI)
- Weak passwords ("123", "password")
- Verify validation messages and recovery

### **Phase 3: Deployment Script Testing**

#### **3.1 Standalone Deployment**
```powershell
# Basic test
.\Deploy_Velociraptor_Standalone.ps1 -Force

# Advanced test with custom parameters
.\Deploy_Velociraptor_Standalone.ps1 -InstallDir "C:\TestVelo" -GuiPort 9999 -Force

# Custom datastore test
.\Deploy_Velociraptor_Standalone.ps1 -DataStore "C:\CustomData" -SkipFirewall -Force

# Verification
Get-Process velociraptor -ErrorAction SilentlyContinue
Test-NetConnection -ComputerName localhost -Port 8889
```

#### **3.2 Server Deployment**
```powershell
# Basic server test
.\Deploy_Velociraptor_Server.ps1 -Force

# Custom directory test
.\Deploy_Velociraptor_Server.ps1 -InstallDir "C:\VeloServer" -Force

# Verification
Get-Process velociraptor -ErrorAction SilentlyContinue
Test-Path "C:\VeloServer\velociraptor.exe"
```

#### **3.3 What-If Testing (Safe)**
```powershell
# Dry run tests
.\Deploy_Velociraptor_Standalone.ps1 -WhatIf
.\Deploy_Velociraptor_Server.ps1 -WhatIf
```

### **Phase 4: Integration Testing**

#### **4.1 GUI + Deployment Integration**
```powershell
# Generate config with GUI
.\gui\VelociraptorGUI.ps1
# Save as "integration-test.yaml"

# Test deployment with custom config
.\Deploy_Velociraptor_Standalone.ps1 -GuiPort 8888 -Force

# Verify integration
Start-Process "http://localhost:8888"
```

#### **4.2 Multiple Deployment Testing**
```powershell
# Test different types (clean between tests)
.\Deploy_Velociraptor_Standalone.ps1 -InstallDir "C:\Test1" -GuiPort 8881 -Force
.\Deploy_Velociraptor_Server.ps1 -InstallDir "C:\Test2" -Force

# Verify coexistence
Get-Process velociraptor -ErrorAction SilentlyContinue
netstat -an | findstr ":888"
```

### **Phase 5: Performance & Validation**

#### **5.1 Performance Benchmarks**
```powershell
# GUI startup time (target: <5 seconds)
Measure-Command { .\gui\VelociraptorGUI.ps1 -StartMinimized }

# Deployment time (target: <30 seconds)
Measure-Command { .\Deploy_Velociraptor_Standalone.ps1 -Force }
```

#### **5.2 Resource Monitoring**
```powershell
# Memory usage during operation
Get-Process powershell | Select-Object ProcessName, WorkingSet, CPU
Get-Process | Where-Object {$_.ProcessName -like "*velociraptor*"} | Select-Object ProcessName, WorkingSet, CPU
```

#### **5.3 Configuration Validation**
```powershell
# Validate generated YAML files
Get-Content "server-config.yaml" | Select-String -Pattern "version|bind_address|gui_bind_address"
Get-Content "standalone-config.yaml" | Select-String -Pattern "version|bind_address|gui_bind_address"
```

---

## 🌟 **Advanced Testing Scenarios**

### **Cross-Platform Testing**

#### **Windows Testing Matrix**
- Windows Server 2019/2022
- Windows 10/11 Professional
- PowerShell 5.1 and 7.x
- Different user privilege levels

#### **Linux Testing (Future)**
- Ubuntu 20.04/22.04 LTS
- CentOS/RHEL 8+
- PowerShell Core 7.x
- systemd service integration

#### **macOS Testing (Moonshot)**
- macOS 12+ (Monterey and later)
- PowerShell Core 7.x
- Homebrew integration
- launchd service management

### **Error Handling Scenarios**

#### **Network Failures**
- Simulate network disconnection during download
- Test with limited bandwidth
- Validate offline operation capabilities
- Test proxy and firewall scenarios

#### **Resource Constraints**
- Test with limited disk space
- Test with limited memory
- Test with high CPU usage
- Test with permission restrictions

#### **Configuration Errors**
- Invalid YAML syntax
- Missing required fields
- Conflicting settings
- Malformed certificates

---

## 🚀 **Moonshot Testing Framework**

### **Tier 1: High-Priority Moonshots**

#### **ServiceNow Integration Testing**
```powershell
# Test ServiceNow API connectivity
Test-ServiceNowConnection -Instance "dev-instance.service-now.com"

# Test incident creation workflow
New-ServiceNowIncident -Type "Security" -Priority "High"

# Test real-time investigation launch
Start-VelociraptorInvestigation -FromServiceNow -IncidentID "INC0000123"
```

#### **Stellar Cyber IDS Integration Testing**
```powershell
# Test IDS notification processing
Test-StellarCyberNotification -IDSEndpoint "https://ids.stellarcyber.com"

# Test threat intelligence package creation
New-ThreatIntelligencePackage -FromIDSAlert $mockAlert

# Test real-time pairing
Test-NotificationPairing -Alert $realTimeAlert
```

#### **macOS Homebrew Testing**
```bash
# Test Homebrew tap creation
brew tap velociraptor/forensics

# Test package installation
brew install velociraptor-server --dry-run

# Test service management
brew services list | grep velociraptor

# Test security integration
security find-identity -v | grep "Velociraptor"
```

### **Tier 2: Advanced AI/ML Testing**

#### **Autonomous Threat Hunter Testing**
```powershell
# Test AI artifact generation
$aiArtifacts = New-AIGeneratedArtifacts -ThreatIntel $threatIntel -Model "gpt-4o"

# Test autonomous decision making
$aiDecisions = Get-AIThreatAssessment -Threat $testThreats -Model "gpt-4o"

# Test learning and adaptation
Provide-AnalystFeedback -Model "gpt-4o" -FeedbackData $trainingData
```

#### **Natural Language Interface Testing**
```powershell
# Test natural language queries
$queries = @(
    "Show me all suspicious PowerShell activity in the last 24 hours",
    "Find processes that accessed sensitive files",
    "What network connections were made by malicious processes?"
)

foreach ($query in $queries) {
    $result = Invoke-NaturalLanguageQuery -Query $query
    Test-ResultRelevance -Results $result.Results -Query $query
}
```

---

## 📊 **Testing Metrics & Success Criteria**

### **Performance Benchmarks**
- **GUI Startup**: <5 seconds
- **Deployment Time**: <30 seconds for download and setup
- **Memory Usage**: <100MB during GUI operation
- **CPU Usage**: <10% during normal operation
- **Network Efficiency**: Minimal bandwidth usage

### **Reliability Metrics**
- **Deployment Success Rate**: >95%
- **GUI Stability**: Zero crashes during testing
- **Error Recovery**: 100% graceful error handling
- **Cross-Platform Compatibility**: 95%+ feature parity
- **Documentation Accuracy**: 100% instruction success rate

### **User Experience Metrics**
- **Time to First Success**: <10 minutes for new users
- **Error Message Clarity**: User can resolve 90% of issues
- **Documentation Completeness**: No missing critical steps
- **Interface Intuitiveness**: 90% task completion without help
- **Professional Appearance**: Consistent branding and design

---

## 🔧 **Testing Tools & Environment**

### **Required Software**
```powershell
# Core requirements
- PowerShell 5.1+ or PowerShell Core 7+
- Git for repository management
- Windows Forms support (Windows)
- Administrator privileges for deployment testing

# Optional tools
- Docker Desktop (container testing)
- Virtual machines (clean environment testing)
- Network simulation tools
- Performance monitoring tools
```

### **Test Data Requirements**
- Clean virtual machines for fresh installation testing
- Valid domain names for certificate testing
- Test certificate files for custom certificate scenarios
- Mock data for integration testing
- Performance baseline data

---

## 📋 **Test Execution Checklist**

### **Pre-Testing Setup**
- [ ] Environment meets minimum requirements
- [ ] Repository is up to date (main branch)
- [ ] Administrator privileges confirmed
- [ ] Network connectivity verified
- [ ] Test data prepared

### **Core Testing Execution**
- [ ] GUI wizard complete workflow test
- [ ] Standalone deployment test
- [ ] Server deployment test
- [ ] Integration testing
- [ ] Performance benchmarking
- [ ] Error handling validation

### **Advanced Testing Execution**
- [ ] Cross-platform compatibility testing
- [ ] Resource constraint testing
- [ ] Network failure simulation
- [ ] Configuration error testing
- [ ] Security validation

### **Moonshot Testing Execution**
- [ ] ServiceNow integration testing
- [ ] Stellar Cyber integration testing
- [ ] macOS Homebrew testing
- [ ] AI/ML feature testing
- [ ] Future technology validation

### **Post-Testing Validation**
- [ ] All test results documented
- [ ] Performance metrics recorded
- [ ] Issues logged and categorized
- [ ] Success criteria evaluated
- [ ] Cleanup completed

---

## 🐛 **Issue Reporting & Resolution**

### **Bug Report Template**
```
**Issue ID**: TEST-XXX
**Severity**: Critical/High/Medium/Low
**Component**: GUI/Deployment/Integration/Performance
**Platform**: Windows/Linux/macOS
**PowerShell Version**: X.X.X

**Description**: Brief description of the issue

**Steps to Reproduce**:
1. Step 1
2. Step 2
3. Step 3

**Expected Result**: What should happen
**Actual Result**: What actually happened
**Screenshots**: If applicable
**Logs**: Relevant log entries
**Workaround**: If available
**Status**: Open/In Progress/Resolved/Verified
```

### **Issue Categories**
- **Critical**: Prevents core functionality
- **High**: Significant impact on user experience
- **Medium**: Minor functionality issues
- **Low**: Cosmetic or documentation issues

---

## 🎯 **Testing Success Criteria**

### **Ready for Production When**
- [ ] All critical and high severity issues resolved
- [ ] 95%+ test case pass rate achieved
- [ ] Performance benchmarks met or exceeded
- [ ] Cross-platform compatibility confirmed
- [ ] Documentation validated and updated
- [ ] User acceptance criteria satisfied

### **Quality Gates**
- **Code Quality**: 100% PowerShell syntax validation
- **Security**: Zero critical vulnerabilities
- **Performance**: All benchmarks met
- **Reliability**: 99%+ deployment success rate
- **Usability**: 90%+ user task completion rate

---

## 🚀 **Next Steps After Testing**

### **Immediate Actions**
1. Document all test results
2. Create issue tracking for any problems found
3. Update documentation based on testing feedback
4. Prepare release notes with testing summary

### **Continuous Improvement**
1. Automate repetitive test procedures
2. Expand test coverage for edge cases
3. Integrate testing into CI/CD pipeline
4. Establish regular testing schedule

### **Future Testing Evolution**
1. Implement automated testing framework
2. Add performance regression testing
3. Expand moonshot testing capabilities
4. Integrate community testing feedback

---

**🧪 Comprehensive testing ensures Velociraptor Setup Scripts deliver exceptional user experience and rock-solid reliability!**

*This guide consolidates all testing procedures from basic validation to advanced moonshot testing, ensuring no valuable testing knowledge is lost.*
