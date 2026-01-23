# macOS QA/UA Testing Plan

**Document Version**: 1.0  
**Creation Date**: January 23, 2026  
**Purpose**: Comprehensive QA and User Acceptance Testing for macOS Production Readiness

---

## 1. Testing Strategy Overview

### 1.1 Testing Levels

```
┌─────────────────────────────────────────────────────────────┐
│                    TESTING PYRAMID                          │
│                                                             │
│                    ┌─────────┐                              │
│                    │   E2E   │  ← UI/Acceptance Tests       │
│                   ┌┴─────────┴┐                             │
│                   │Integration│  ← Component Integration    │
│                  ┌┴───────────┴┐                            │
│                  │  Unit Tests  │  ← Individual Functions   │
│                 └───────────────┘                           │
│                                                             │
│  Target Coverage: 80% Unit | 60% Integration | 40% E2E     │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Testing Frameworks

| Test Type | Framework | Platform |
|-----------|-----------|----------|
| Unit Tests | XCTest | macOS |
| UI Tests | XCUITest | macOS |
| Integration Tests | XCTest + Pester | macOS + PowerShell |
| Performance Tests | XCTest Performance | macOS |
| Accessibility Tests | XCUITest + Accessibility Inspector | macOS |
| Security Tests | Custom + SAST | macOS |

---

## 2. Test Case Inventory

### 2.1 Functional Test Cases

#### Configuration Wizard Tests

| Test ID | Test Name | Priority | Preconditions | Steps | Expected Result | Status |
|---------|-----------|----------|---------------|-------|-----------------|--------|
| TC_CW_001 | Wizard Window Launch | P0 | App installed | Launch app | Wizard window displays | NOT RUN |
| TC_CW_002 | Welcome Step Display | P0 | Wizard open | View welcome | Welcome text visible | NOT RUN |
| TC_CW_003 | Navigate Forward | P0 | On welcome step | Click Next | Moves to step 2 | NOT RUN |
| TC_CW_004 | Navigate Backward | P0 | On step 2+ | Click Back | Moves to previous step | NOT RUN |
| TC_CW_005 | Cancel Confirmation | P1 | Wizard open | Click Cancel | Confirmation dialog | NOT RUN |
| TC_CW_006 | Deployment Type Server | P0 | On deployment step | Select Server | Server option selected | NOT RUN |
| TC_CW_007 | Deployment Type Standalone | P0 | On deployment step | Select Standalone | Standalone selected | NOT RUN |
| TC_CW_008 | Deployment Type Client | P0 | On deployment step | Select Client | Client selected | NOT RUN |
| TC_CW_009 | Certificate Self-Signed | P0 | On cert step | Select Self-Signed | Option selected | NOT RUN |
| TC_CW_010 | Certificate Custom | P1 | On cert step | Select Custom | File picker enabled | NOT RUN |
| TC_CW_011 | Certificate LetsEncrypt | P1 | On cert step | Select LetsEncrypt | Domain field enabled | NOT RUN |
| TC_CW_012 | Environment Selection | P1 | On security step | Select environment | Option saved | NOT RUN |
| TC_CW_013 | Log Level Selection | P1 | On security step | Select log level | Option saved | NOT RUN |
| TC_CW_014 | TLS 1.2 Toggle | P1 | On security step | Toggle TLS | State changes | NOT RUN |
| TC_CW_015 | Datastore Path Entry | P0 | On storage step | Enter path | Path validated | NOT RUN |
| TC_CW_016 | Datastore Path Browse | P1 | On storage step | Click Browse | File picker opens | NOT RUN |
| TC_CW_017 | Logs Path Entry | P1 | On storage step | Enter path | Path validated | NOT RUN |
| TC_CW_018 | Bind Address Entry | P0 | On network step | Enter IP | IP validated | NOT RUN |
| TC_CW_019 | Port Entry Valid | P0 | On network step | Enter 8000 | Port accepted | NOT RUN |
| TC_CW_020 | Port Entry Invalid | P0 | On network step | Enter 99999 | Error shown | NOT RUN |
| TC_CW_021 | Username Entry | P0 | On auth step | Enter username | Username saved | NOT RUN |
| TC_CW_022 | Password Entry | P0 | On auth step | Enter password | Password masked | NOT RUN |
| TC_CW_023 | Password Strength | P1 | On auth step | Enter weak | Warning shown | NOT RUN |
| TC_CW_024 | Review Step Display | P0 | Navigate to review | View review | Config displayed | NOT RUN |
| TC_CW_025 | Config Generation | P0 | On review step | Click Generate | Config file created | NOT RUN |
| TC_CW_026 | Complete Step Display | P0 | Config generated | View complete | Success message | NOT RUN |
| TC_CW_027 | Launch Velociraptor | P1 | On complete step | Click Launch | Process starts | NOT RUN |
| TC_CW_028 | Finish Wizard | P0 | On complete step | Click Finish | Wizard closes | NOT RUN |

#### Incident Response Tests

| Test ID | Test Name | Priority | Preconditions | Steps | Expected Result | Status |
|---------|-----------|----------|---------------|-------|-----------------|--------|
| TC_IR_001 | IR Window Launch | P0 | App installed | Open IR view | IR window displays | NOT RUN |
| TC_IR_002 | Category Selection | P0 | IR window open | Select category | Incidents filter | NOT RUN |
| TC_IR_003 | Incident Selection | P0 | Category selected | Select incident | Details populate | NOT RUN |
| TC_IR_004 | Deployment Path Entry | P0 | Incident selected | Enter path | Path validated | NOT RUN |
| TC_IR_005 | Offline Mode Toggle | P1 | Config visible | Toggle offline | State changes | NOT RUN |
| TC_IR_006 | Portable Mode Toggle | P1 | Config visible | Toggle portable | State changes | NOT RUN |
| TC_IR_007 | Encrypt Mode Toggle | P1 | Config visible | Toggle encrypt | State changes | NOT RUN |
| TC_IR_008 | Priority Selection | P1 | Config visible | Select priority | Option saved | NOT RUN |
| TC_IR_009 | Urgency Selection | P1 | Config visible | Select urgency | Option saved | NOT RUN |
| TC_IR_010 | Deploy Collector | P0 | Config complete | Click Deploy | Collector built | NOT RUN |
| TC_IR_011 | Preview Config | P1 | Config complete | Click Preview | Preview shown | NOT RUN |
| TC_IR_012 | Save Config | P1 | Config complete | Click Save | Config saved | NOT RUN |
| TC_IR_013 | Load Config | P1 | Saved config exists | Click Load | Config loaded | NOT RUN |
| TC_IR_014 | Help Display | P2 | IR window open | Click Help | Help shown | NOT RUN |
| TC_IR_015 | Exit IR Window | P1 | IR window open | Click Exit | Window closes | NOT RUN |

#### Emergency Mode Tests

| Test ID | Test Name | Priority | Preconditions | Steps | Expected Result | Status |
|---------|-----------|----------|---------------|-------|-----------------|--------|
| TC_EM_001 | Emergency Button Visible | P0 | Wizard open | View wizard | Button visible | NOT RUN |
| TC_EM_002 | Emergency Click | P0 | Button visible | Click Emergency | Confirmation dialog | NOT RUN |
| TC_EM_003 | Emergency Confirm | P0 | Dialog shown | Click Confirm | Deployment starts | NOT RUN |
| TC_EM_004 | Emergency Cancel | P1 | Dialog shown | Click Cancel | Dialog closes | NOT RUN |
| TC_EM_005 | Emergency Progress | P0 | Deployment active | View progress | Progress updates | NOT RUN |
| TC_EM_006 | Emergency Complete | P0 | Deployment done | View result | Success message | NOT RUN |
| TC_EM_007 | Emergency Default Path | P1 | Emergency mode | Check path | Default path used | NOT RUN |

### 2.2 Integration Test Cases

#### Deployment Integration Tests

| Test ID | Test Name | Priority | Preconditions | Steps | Expected Result | Status |
|---------|-----------|----------|---------------|-------|-----------------|--------|
| TC_DI_001 | Download Binary | P0 | Network available | Trigger download | Binary downloaded | NOT RUN |
| TC_DI_002 | Directory Creation | P0 | Paths configured | Trigger setup | Directories created | NOT RUN |
| TC_DI_003 | Config Generation | P0 | Binary present | Generate config | YAML file created | NOT RUN |
| TC_DI_004 | Service Installation | P0 | Config present | Install service | Plist created | NOT RUN |
| TC_DI_005 | Service Start | P0 | Service installed | Start service | Process running | NOT RUN |
| TC_DI_006 | Health Check | P0 | Service running | Run health check | Status returned | NOT RUN |
| TC_DI_007 | Service Stop | P1 | Service running | Stop service | Process stopped | NOT RUN |
| TC_DI_008 | Full Deployment Flow | P0 | Clean system | Deploy all | Full deployment success | NOT RUN |

#### Keychain Integration Tests

| Test ID | Test Name | Priority | Preconditions | Steps | Expected Result | Status |
|---------|-----------|----------|---------------|-------|-----------------|--------|
| TC_KC_001 | Save Password | P0 | Keychain access | Save password | Password stored | NOT RUN |
| TC_KC_002 | Retrieve Password | P0 | Password saved | Get password | Password returned | NOT RUN |
| TC_KC_003 | Update Password | P1 | Password saved | Update password | Password updated | NOT RUN |
| TC_KC_004 | Delete Password | P1 | Password saved | Delete password | Password removed | NOT RUN |
| TC_KC_005 | Save API Key | P1 | Keychain access | Save API key | Key stored | NOT RUN |
| TC_KC_006 | Certificate Storage | P2 | Keychain access | Save cert | Cert stored | NOT RUN |

### 2.3 Performance Test Cases

| Test ID | Test Name | Priority | Metric | Threshold | Status |
|---------|-----------|----------|--------|-----------|--------|
| TC_PF_001 | App Launch Time | P0 | Time to interactive | < 2 seconds | NOT RUN |
| TC_PF_002 | Wizard Step Navigation | P1 | Step transition | < 100ms | NOT RUN |
| TC_PF_003 | Binary Download | P0 | Download speed | > 1 MB/s | NOT RUN |
| TC_PF_004 | Config Generation | P0 | Generation time | < 5 seconds | NOT RUN |
| TC_PF_005 | Memory Usage Idle | P1 | Memory | < 100 MB | NOT RUN |
| TC_PF_006 | Memory Usage Active | P1 | Memory | < 200 MB | NOT RUN |
| TC_PF_007 | CPU Usage Idle | P1 | CPU | < 5% | NOT RUN |

### 2.4 Security Test Cases

| Test ID | Test Name | Priority | Preconditions | Steps | Expected Result | Status |
|---------|-----------|----------|---------------|-------|-----------------|--------|
| TC_SC_001 | Keychain Encryption | P0 | Password stored | Inspect keychain | Data encrypted | NOT RUN |
| TC_SC_002 | Password Not in Memory | P0 | Password entered | Memory dump | Password not found | NOT RUN |
| TC_SC_003 | Config File Permissions | P0 | Config generated | Check permissions | 0640 or stricter | NOT RUN |
| TC_SC_004 | TLS Certificate Valid | P0 | Service running | Check cert | Valid certificate | NOT RUN |
| TC_SC_005 | Code Signature Valid | P0 | App installed | Verify signature | Valid signature | NOT RUN |
| TC_SC_006 | Notarization Valid | P0 | App distributed | Check notarization | Notarized | NOT RUN |
| TC_SC_007 | Hardened Runtime | P0 | App built | Check entitlements | Hardened runtime | NOT RUN |

### 2.5 Accessibility Test Cases

| Test ID | Test Name | Priority | Preconditions | Steps | Expected Result | Status |
|---------|-----------|----------|---------------|-------|-----------------|--------|
| TC_AC_001 | VoiceOver Main Window | P0 | VoiceOver enabled | Navigate app | All elements announced | NOT RUN |
| TC_AC_002 | VoiceOver Buttons | P0 | VoiceOver enabled | Focus buttons | Proper labels announced | NOT RUN |
| TC_AC_003 | Keyboard Navigation | P0 | App open | Use Tab key | Focus moves logically | NOT RUN |
| TC_AC_004 | Focus Indicators | P0 | Keyboard nav | Focus elements | Clear focus ring | NOT RUN |
| TC_AC_005 | Color Contrast | P1 | App open | Check contrast | WCAG 2.1 AA compliant | NOT RUN |
| TC_AC_006 | Text Scaling | P1 | System scaled | View app | Text scales properly | NOT RUN |
| TC_AC_007 | Reduce Motion | P2 | Reduce motion on | Use app | No animations | NOT RUN |

---

## 3. User Acceptance Test Scenarios

### 3.1 Scenario-Based UA Tests

#### Scenario 1: First-Time User Installation

**Persona**: Security Analyst, first time using Velociraptor  
**Goal**: Install and configure Velociraptor on macOS laptop

| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Download app from GitHub | DMG file downloads | |
| 2 | Open DMG and drag to Applications | App installed | |
| 3 | Launch app (Gatekeeper prompt) | App opens after approval | |
| 4 | Read welcome screen | Clear instructions visible | |
| 5 | Select Standalone deployment | Option selects smoothly | |
| 6 | Accept default certificate settings | Self-signed selected | |
| 7 | Accept default storage paths | macOS paths auto-populated | |
| 8 | Enter admin credentials | Password strength indicator works | |
| 9 | Review configuration | All settings displayed | |
| 10 | Generate configuration | Config file created | |
| 11 | Launch Velociraptor | Web interface accessible | |

**Success Criteria**: User completes setup in < 10 minutes

---

#### Scenario 2: Incident Response Rapid Deployment

**Persona**: Incident Responder, active security incident  
**Goal**: Deploy emergency collector within 3 minutes

| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Launch app | App opens immediately | |
| 2 | Click Emergency Mode button | Confirmation dialog appears | |
| 3 | Confirm emergency deployment | Deployment starts | |
| 4 | Wait for deployment | Progress indicator updates | |
| 5 | Deployment completes | Success message shown | |
| 6 | Verify collector runs | Process visible in Activity Monitor | |
| 7 | Access web interface | GUI loads at localhost:8889 | |

**Success Criteria**: Emergency deployment in < 3 minutes

---

#### Scenario 3: Incident Response Collector Creation

**Persona**: SOC Analyst, creating ransomware response package  
**Goal**: Build offline collector for field deployment

| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Open Incident Response view | IR interface displays | |
| 2 | Select "Malware & Ransomware" category | Category selected | |
| 3 | Select "WannaCry-style Worm Ransomware" | Incident details populate | |
| 4 | Enable Offline Mode | Toggle enabled | |
| 5 | Enable Portable Package | Toggle enabled | |
| 6 | Set Priority to Critical | Priority set | |
| 7 | Set Response Time to Immediate | Urgency set | |
| 8 | Click Deploy Collector | Collector built | |
| 9 | Locate output files | Files at specified path | |
| 10 | Verify package is self-contained | All tools bundled | |

**Success Criteria**: Collector package created with all artifacts

---

#### Scenario 4: Configuration Update

**Persona**: System Administrator, updating existing deployment  
**Goal**: Modify network settings without reinstallation

| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Open Preferences | Settings window opens | |
| 2 | Navigate to Network settings | Network tab displays | |
| 3 | Change GUI port from 8889 to 8890 | Port updates | |
| 4 | Save changes | Changes saved | |
| 5 | Restart service | Service restarts | |
| 6 | Access new port | GUI loads at :8890 | |

**Success Criteria**: Configuration updated without data loss

---

#### Scenario 5: macOS-Specific Features

**Persona**: macOS Power User  
**Goal**: Verify macOS integration features work correctly

| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Check ~/Library/Application Support | Data directory exists | |
| 2 | Check ~/Library/Logs/Velociraptor | Log files present | |
| 3 | Open Keychain Access | Velociraptor items visible | |
| 4 | Enable "Launch at Login" | Login item created | |
| 5 | Restart Mac | Velociraptor auto-starts | |
| 6 | Check Activity Monitor | Process runs with low resources | |
| 7 | Use Spotlight to search configs | Config files indexed | |
| 8 | Right-click menu bar icon | Quick actions available | |

**Success Criteria**: All macOS integrations function correctly

---

## 4. Test Execution Commands

### 4.1 Running Unit Tests

```bash
# Run all unit tests
xcodebuild test \
    -project VelociraptorMacOS/VelociraptorMacOS.xcodeproj \
    -scheme VelociraptorMacOS \
    -destination 'platform=macOS' \
    -resultBundlePath TestResults/UnitTests.xcresult

# Run specific test class
xcodebuild test \
    -project VelociraptorMacOS/VelociraptorMacOS.xcodeproj \
    -scheme VelociraptorMacOS \
    -destination 'platform=macOS' \
    -only-testing:VelociraptorMacOSTests/KeychainManagerTests

# Generate code coverage
xcrun xccov view --report TestResults/UnitTests.xcresult
```

### 4.2 Running UI Tests

```bash
# Run all UI tests
xcodebuild test \
    -project VelociraptorMacOS/VelociraptorMacOS.xcodeproj \
    -scheme VelociraptorMacOS \
    -destination 'platform=macOS' \
    -only-testing:VelociraptorMacOSUITests

# Run specific UI test
xcodebuild test \
    -project VelociraptorMacOS/VelociraptorMacOS.xcodeproj \
    -scheme VelociraptorMacOS \
    -destination 'platform=macOS' \
    -only-testing:VelociraptorMacOSUITests/ConfigurationWizardUITests/testWizardNavigation
```

### 4.3 Running PowerShell Integration Tests

```powershell
# Run macOS-specific tests
./tests/Run-Tests.ps1 -TestType Integration

# Run with output
./tests/Run-Tests.ps1 -TestType Integration -OutputFormat NUnitXml -OutputPath TestResults/macos-integration.xml
```

### 4.4 Running Accessibility Audit

```bash
# Use Accessibility Inspector from Xcode
# Xcode > Open Developer Tool > Accessibility Inspector

# Automated audit via command line
xcrun accessibility-inspector -app VelociraptorMacOS -audit
```

---

## 5. Test Reporting

### 5.1 Report Structure

```
test-reports/
├── {YYYYMMDD}/
│   ├── unit/
│   │   ├── VelociraptorMacOSTests.xcresult
│   │   └── coverage.html
│   ├── ui/
│   │   ├── VelociraptorMacOSUITests.xcresult
│   │   └── screenshots/
│   ├── integration/
│   │   ├── macos-integration.xml
│   │   └── logs/
│   ├── performance/
│   │   ├── performance-baseline.json
│   │   └── performance-results.json
│   ├── accessibility/
│   │   ├── voiceover-audit.json
│   │   └── contrast-report.html
│   ├── security/
│   │   ├── sast-results.sarif
│   │   └── signature-verification.txt
│   └── summary/
│       ├── test-summary.html
│       ├── test-summary.json
│       └── coverage-matrix.html
```

### 5.2 Summary Report Template

```json
{
  "reportDate": "2026-01-23",
  "version": "5.0.5-beta",
  "platform": "macOS 14.0 (Sonoma)",
  "testSummary": {
    "total": 94,
    "passed": 0,
    "failed": 0,
    "skipped": 94,
    "coverage": 0
  },
  "categories": {
    "unit": { "total": 25, "passed": 0, "failed": 0 },
    "integration": { "total": 14, "passed": 0, "failed": 0 },
    "ui": { "total": 35, "passed": 0, "failed": 0 },
    "accessibility": { "total": 7, "passed": 0, "failed": 0 },
    "security": { "total": 7, "passed": 0, "failed": 0 },
    "performance": { "total": 7, "passed": 0, "failed": 0 }
  },
  "criticalGaps": [
    "No native macOS GUI implemented",
    "No code signing configured",
    "No Keychain integration"
  ]
}
```

---

## 6. Failure Triage Guide

### 6.1 Common Failure Categories

| Category | Symptoms | Investigation Steps | Common Causes |
|----------|----------|---------------------|---------------|
| Build Failure | Xcode build fails | Check build logs, verify SDK | Missing dependencies |
| UI Not Rendering | Controls not visible | Check view hierarchy | Layout constraints |
| Keychain Access | Permission denied | Check entitlements | Missing keychain-access-groups |
| Network Failure | Download fails | Check connectivity, firewall | Network restrictions |
| Service Failure | launchd won't start | Check plist syntax, permissions | Invalid plist format |
| Code Signing | Signature invalid | Verify certificates | Expired certificate |
| Notarization | Rejected by Apple | Check notarization log | Entitlement issues |

### 6.2 Log Locations

| Log Type | Location |
|----------|----------|
| App Logs | ~/Library/Logs/Velociraptor/ |
| System Logs | Console.app → Filter by "Velociraptor" |
| Crash Reports | ~/Library/Logs/DiagnosticReports/ |
| Test Results | TestResults/*.xcresult |
| Build Logs | ~/Library/Developer/Xcode/DerivedData/ |

### 6.3 Debugging Commands

```bash
# Check app signature
codesign -dv --verbose=4 /Applications/VelociraptorMacOS.app

# Check entitlements
codesign -d --entitlements :- /Applications/VelociraptorMacOS.app

# Check notarization status
spctl -a -vv /Applications/VelociraptorMacOS.app

# Check launchd service status
launchctl list | grep velociraptor
launchctl print gui/$(id -u)/com.velocidex.velociraptor

# View system logs
log stream --predicate 'processImagePath contains "velociraptor"' --level debug

# Check keychain items
security find-generic-password -s "com.velocidex.velociraptor" -g
```

---

## 7. Test Coverage Requirements

### 7.1 Minimum Coverage by Category

| Category | Minimum Coverage | Current | Status |
|----------|-----------------|---------|--------|
| Unit Tests | 80% | 0% | NOT MET |
| Integration Tests | 60% | 0% | NOT MET |
| UI Tests | 40% | 0% | NOT MET |
| Critical Path | 100% | 0% | NOT MET |
| Accessibility | 100% | 0% | NOT MET |

### 7.2 Critical Path Tests (Must Pass)

- [ ] TC_CW_001 - Wizard Window Launch
- [ ] TC_CW_025 - Config Generation
- [ ] TC_DI_008 - Full Deployment Flow
- [ ] TC_EM_003 - Emergency Confirm
- [ ] TC_KC_001 - Save Password
- [ ] TC_SC_005 - Code Signature Valid
- [ ] TC_AC_001 - VoiceOver Main Window

---

## 8. CI/CD Integration

### 8.1 GitHub Actions Workflow

```yaml
name: macOS Tests

on:
  push:
    branches: [main, cursor/mac-os-production-readiness*]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: macos-14
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode_15.2.app
    
    - name: Build
      run: |
        xcodebuild build \
          -project VelociraptorMacOS/VelociraptorMacOS.xcodeproj \
          -scheme VelociraptorMacOS \
          -destination 'platform=macOS'
    
    - name: Unit Tests
      run: |
        xcodebuild test \
          -project VelociraptorMacOS/VelociraptorMacOS.xcodeproj \
          -scheme VelociraptorMacOS \
          -destination 'platform=macOS' \
          -resultBundlePath TestResults/UnitTests.xcresult
    
    - name: Upload Results
      uses: actions/upload-artifact@v4
      with:
        name: test-results
        path: TestResults/
```

---

**Document Maintainer**: Velociraptor QA Team  
**Review Cycle**: Per iteration  
**Test Tracking**: See GitHub Issues with `qa-macos` label
