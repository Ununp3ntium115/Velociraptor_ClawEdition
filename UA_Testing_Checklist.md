# Velociraptor GUI - User Acceptance Testing Checklist

## 🎯 **UA Testing Phase - Complete Feature Validation**

### **Test Environment Setup**
- [ ] PowerShell 7+ available
- [ ] Windows Forms assemblies load correctly
- [ ] GUI launches without errors
- [ ] All visual elements render properly

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
1. Launch GUI: `pwsh gui/VelociraptorGUI.ps1`
2. Verify welcome content is readable and professional
3. Test Next button navigation
4. Test Cancel button (should prompt for confirmation)

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
1. Select Server deployment
2. Configure custom datastore and logs directories
3. Set 2-year certificate expiration
4. Enable registry storage
5. Configure network settings (API: 8000, GUI: 8889)
6. Set strong admin credentials
7. Generate configuration file

### **Scenario 2: Standalone Deployment (Minimal Configuration)**
1. Select Standalone deployment
2. Use default directories
3. Set 1-year certificate expiration
4. Disable registry storage
5. Use localhost binding
6. Set basic admin credentials
7. Generate configuration file

### **Scenario 3: Client Configuration**
1. Select Client deployment
2. Configure minimal storage
3. Set network settings for server connection
4. Set client credentials
5. Generate configuration file

### **Scenario 4: Error Handling & Validation**
1. Leave required fields empty
2. Enter invalid IP addresses
3. Use conflicting port numbers
4. Set weak passwords
5. Verify validation messages appear
6. Test error recovery

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
- [ ] PowerShell compatibility maintained
- [ ] Windows Forms integration stable
- [ ] File I/O operations work correctly
- [ ] Memory usage reasonable
- [ ] Performance acceptable for wizard workflow

---

## **🚀 UA TESTING STATUS**

**Current Phase:** Ready for User Acceptance Testing
**Test Environment:** macOS with PowerShell 7+
**GUI Version:** v5.0.1 Enhanced

**Ready to begin comprehensive UA testing!**