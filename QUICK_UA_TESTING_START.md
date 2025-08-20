# 🚀 Quick Start: UA Testing on Main Branch

## **Ready to Test? Start Here!**

### **0. First Time Setup (1 minute)**
```powershell
# Clone repository (first time users only)
git clone https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts.git
cd Velociraptor_Setup_Scripts

# For existing users, just update
git checkout main && git pull origin main
```

### **1. Environment Check (30 seconds)**
```powershell
# Verify you're on main with latest changes
git status && git pull origin main

# Check PowerShell version
$PSVersionTable.PSVersion

# Verify Windows and admin privileges
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
```

### **2. Quick Component Test (2 minutes)**
```powershell
# Test GUI launches
.\gui\VelociraptorGUI.ps1

# Test deployment scripts
.\Deploy_Velociraptor_Standalone.ps1 -WhatIf
.\Deploy_Velociraptor_Server.ps1 -WhatIf
```

### **3. Full Testing Resources**
- 📋 **[UA_Testing_Checklist.md](UA_Testing_Checklist.md)** - Complete step-by-step testing
- 📊 **[UA_Testing_Results.md](UA_Testing_Results.md)** - Expected results and setup
- 🔧 **[BRANCH_CONSOLIDATION_ANALYSIS.md](BRANCH_CONSOLIDATION_ANALYSIS.md)** - Technical details

### **4. Critical Test Scenarios (15 minutes each)**

#### **Scenario A: GUI Wizard Test**
```powershell
.\gui\VelociraptorGUI.ps1
# Follow wizard → Generate config → Save file
```

#### **Scenario B: Standalone Deployment**
```powershell
.\Deploy_Velociraptor_Standalone.ps1 -Force -GuiPort 8888
# Should download, configure, and start Velociraptor
```

#### **Scenario C: Server Deployment**
```powershell
.\Deploy_Velociraptor_Server.ps1 -Force -InstallDir "C:\TestVelo"
# Should setup server configuration
```

### **5. Success Indicators**
- ✅ GUI launches and all steps work
- ✅ Deployment scripts complete without errors
- ✅ Generated configs are valid YAML
- ✅ No critical issues found

### **6. Issue Reporting**
If you find issues, document using the template in [UA_Testing_Checklist.md](UA_Testing_Checklist.md#issue-documentation-template)

---

**🎯 Everything is consolidated on main branch and ready for comprehensive testing!**