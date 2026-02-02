# GitHub Issue Close-Out Todo List

**Document**: `steering/ISSUE_CLOSEOUT_TODO.md`  
**Created**: January 23, 2026  
**Status**: Ready for Execution  
**Total Issues**: 18 (all verified as implemented)

---

## A) Master Close-Out Checklist

Complete these steps before closing any issues:

- [ ] **Confirm linked evidence** in `steering/GITHUB_ISSUES_STATUS.md`
- [ ] **Confirm no uncommitted changes**: `git status` shows clean working tree
- [ ] **Run relevant test suites** mapped to issue type:
  - UI Tests: `tests/ui/`
  - Unit Tests: `tests/unit/`
  - Integration Tests: `tests/integration/`
  - Security Tests: `tests/security/`
  - QA Tests: `tests/qa/`
- [ ] **Confirm macOS build** via Xcode scheme under `Velociraptor_macOS_App/`
- [ ] **Confirm docs updates** under `docs/` and/or `steering/`
- [ ] **Add close-out note** in tracking doc for each issue: `[YYYY-MM-DD] Ready to close`

### Pre-Close Verification Commands

```bash
# Verify clean git state
git status

# Run unit tests (if available)
cd Velociraptor_macOS_App && swift test

# Verify build
cd Velociraptor_macOS_App && swift build -c release

# Check evidence document exists
cat steering/GITHUB_ISSUES_STATUS.md | head -50
```

---

## B) Per-Issue Todo Blocks

### GAP Issues (#33–40) — Code Improvements

---

#### Issue #33 — Consolidated DeploymentType Enum

- [ ] **Evidence**: [steering/GITHUB_ISSUES_STATUS.md#gap-001](steering/GITHUB_ISSUES_STATUS.md)
- [ ] **Files touched**:
  - `Velociraptor_macOS_App/VelociraptorMacOS/Models/ConfigurationData.swift`
  - `Velociraptor_macOS_App/VelociraptorMacOS/Models/AppState.swift`
- [ ] **Verification step**:
  ```bash
  grep -n "enum DeploymentType" Velociraptor_macOS_App/VelociraptorMacOS/Models/ConfigurationData.swift
  ```
- [ ] **Close-out comment**: `Verified as implemented`
- [ ] **Manual close command** (do not execute):
  ```bash
  gh issue close 33 -c "Verified as implemented"
  ```

---

#### Issue #34 — Localized Hardcoded Strings

- [ ] **Evidence**: [steering/GITHUB_ISSUES_STATUS.md#gap-002](steering/GITHUB_ISSUES_STATUS.md)
- [ ] **Files touched**:
  - `Velociraptor_macOS_App/VelociraptorMacOS/Utilities/Strings.swift`
  - `Velociraptor_macOS_App/VelociraptorMacOS/Views/ContentView.swift`
- [ ] **Verification step**:
  ```bash
  grep -n "nameRaw\|taglineRaw" Velociraptor_macOS_App/VelociraptorMacOS/Utilities/Strings.swift
  ```
- [ ] **Close-out comment**: `Verified as implemented`
- [ ] **Manual close command** (do not execute):
  ```bash
  gh issue close 34 -c "Verified as implemented"
  ```

---

#### Issue #35 — Reusable View Components Library

- [ ] **Evidence**: [steering/GITHUB_ISSUES_STATUS.md#gap-003](steering/GITHUB_ISSUES_STATUS.md)
- [ ] **Files touched**:
  - `Velociraptor_macOS_App/VelociraptorMacOS/Views/Components/CommonViews.swift`
- [ ] **Verification step**:
  ```bash
  grep -c "struct.*View" Velociraptor_macOS_App/VelociraptorMacOS/Views/Components/CommonViews.swift
  # Expected: 10+ view components
  ```
- [ ] **Close-out comment**: `Verified as implemented`
- [ ] **Manual close command** (do not execute):
  ```bash
  gh issue close 35 -c "Verified as implemented"
  ```

---

#### Issue #36 — System API IP Validation

- [ ] **Evidence**: [steering/GITHUB_ISSUES_STATUS.md#gap-004](steering/GITHUB_ISSUES_STATUS.md)
- [ ] **Files touched**:
  - `Velociraptor_macOS_App/VelociraptorMacOS/Models/ConfigurationData.swift`
- [ ] **Verification step**:
  ```bash
  grep -n "inet_pton" Velociraptor_macOS_App/VelociraptorMacOS/Models/ConfigurationData.swift
  ```
- [ ] **Close-out comment**: `Verified as implemented`
- [ ] **Manual close command** (do not execute):
  ```bash
  gh issue close 36 -c "Verified as implemented"
  ```

---

#### Issue #37 — Swift 6 Actor Logger

- [ ] **Evidence**: [steering/GITHUB_ISSUES_STATUS.md#gap-005](steering/GITHUB_ISSUES_STATUS.md)
- [ ] **Files touched**:
  - `Velociraptor_macOS_App/VelociraptorMacOS/Utilities/Logger.swift`
- [ ] **Verification step**:
  ```bash
  grep -n "^actor Logger" Velociraptor_macOS_App/VelociraptorMacOS/Utilities/Logger.swift
  grep -n "class SyncLogger" Velociraptor_macOS_App/VelociraptorMacOS/Utilities/Logger.swift
  ```
- [ ] **Close-out comment**: `Verified as implemented`
- [ ] **Manual close command** (do not execute):
  ```bash
  gh issue close 37 -c "Verified as implemented"
  ```

---

#### Issue #38 — Synced TestAccessibilityIdentifiers

- [ ] **Evidence**: [steering/GITHUB_ISSUES_STATUS.md#gap-006](steering/GITHUB_ISSUES_STATUS.md)
- [ ] **Files touched**:
  - `Velociraptor_macOS_App/VelociraptorMacOSUITests/TestAccessibilityIdentifiers.swift`
  - `Velociraptor_macOS_App/VelociraptorMacOS/Utilities/AccessibilityIdentifiers.swift`
- [ ] **Verification step**:
  ```bash
  # Compare enum count between files
  grep -c "static let" Velociraptor_macOS_App/VelociraptorMacOS/Utilities/AccessibilityIdentifiers.swift
  grep -c "static let" Velociraptor_macOS_App/VelociraptorMacOSUITests/TestAccessibilityIdentifiers.swift
  ```
- [ ] **Close-out comment**: `Verified as implemented`
- [ ] **Manual close command** (do not execute):
  ```bash
  gh issue close 38 -c "Verified as implemented"
  ```

---

#### Issue #39 — Offline Deployment Mode

- [ ] **Evidence**: [steering/GITHUB_ISSUES_STATUS.md#gap-007](steering/GITHUB_ISSUES_STATUS.md)
- [ ] **Files touched**:
  - `Velociraptor_macOS_App/VelociraptorMacOS/Models/ConfigurationData.swift`
  - `Velociraptor_macOS_App/VelociraptorMacOS/Services/DeploymentManager.swift`
  - `Velociraptor_macOS_App/VelociraptorMacOS/Views/Steps/WelcomeStepView.swift`
- [ ] **Verification step**:
  ```bash
  grep -n "offlineMode" Velociraptor_macOS_App/VelociraptorMacOS/Models/ConfigurationData.swift
  grep -n "handleOfflineMode" Velociraptor_macOS_App/VelociraptorMacOS/Services/DeploymentManager.swift
  ```
- [ ] **Close-out comment**: `Verified as implemented`
- [ ] **Manual close command** (do not execute):
  ```bash
  gh issue close 39 -c "Verified as implemented"
  ```

---

#### Issue #40 — Localization Format Strings

- [ ] **Evidence**: [steering/GITHUB_ISSUES_STATUS.md#gap-008](steering/GITHUB_ISSUES_STATUS.md)
- [ ] **Files touched**:
  - `Velociraptor_macOS_App/VelociraptorMacOS/Resources/en.lproj/Localizable.strings`
  - `Velociraptor_macOS_App/VelociraptorMacOS/Utilities/Strings.swift`
- [ ] **Verification step**:
  ```bash
  grep -n "format\." Velociraptor_macOS_App/VelociraptorMacOS/Resources/en.lproj/Localizable.strings
  grep -n "enum Format" Velociraptor_macOS_App/VelociraptorMacOS/Utilities/Strings.swift
  ```
- [ ] **Close-out comment**: `Verified as implemented`
- [ ] **Manual close command** (do not execute):
  ```bash
  gh issue close 40 -c "Verified as implemented"
  ```

---

### macOS Feature Issues (#23–32) — Core Features

---

#### Issue #23 — App Foundation + Xcode CI

- [ ] **Evidence**: [steering/GITHUB_ISSUES_STATUS.md#issue-23](steering/GITHUB_ISSUES_STATUS.md)
- [ ] **Files touched**:
  - `Velociraptor_macOS_App/Package.swift`
  - `Velociraptor_macOS_App/project.yml`
  - `Velociraptor_macOS_App/VelociraptorMacOS/VelociraptorMacOSApp.swift`
  - `.github/workflows/macos-build.yml`
- [ ] **Verification step**:
  ```bash
  # Verify Swift files count
  find Velociraptor_macOS_App -name "*.swift" | wc -l
  # Expected: 55+
  
  # Verify CI workflow exists
  cat .github/workflows/macos-build.yml | head -10
  ```
- [ ] **Close-out comment**: `Verified as implemented`
- [ ] **Manual close command** (do not execute):
  ```bash
  gh issue close 23 -c "Verified as implemented"
  ```

---

#### Issue #24 — Installer Workflow (download/install/launch)

- [ ] **Evidence**: [steering/GITHUB_ISSUES_STATUS.md#issue-24](steering/GITHUB_ISSUES_STATUS.md)
- [ ] **Files touched**:
  - `Velociraptor_macOS_App/VelociraptorMacOS/Services/DeploymentManager.swift`
- [ ] **Verification step**:
  ```bash
  grep -n "func deploy\|func downloadVelociraptor\|func startService" \
    Velociraptor_macOS_App/VelociraptorMacOS/Services/DeploymentManager.swift
  ```
- [ ] **Close-out comment**: `Verified as implemented`
- [ ] **Manual close command** (do not execute):
  ```bash
  gh issue close 24 -c "Verified as implemented"
  ```

---

#### Issue #25 — Configuration Wizard Parity

- [ ] **Evidence**: [steering/GITHUB_ISSUES_STATUS.md#issue-25](steering/GITHUB_ISSUES_STATUS.md)
- [ ] **Files touched**:
  - `Velociraptor_macOS_App/VelociraptorMacOS/Views/Steps/WelcomeStepView.swift`
  - `Velociraptor_macOS_App/VelociraptorMacOS/Views/Steps/DeploymentTypeStepView.swift`
  - `Velociraptor_macOS_App/VelociraptorMacOS/Views/Steps/CertificateSettingsStepView.swift`
  - `Velociraptor_macOS_App/VelociraptorMacOS/Views/Steps/SecuritySettingsStepView.swift`
  - `Velociraptor_macOS_App/VelociraptorMacOS/Views/Steps/StorageConfigurationStepView.swift`
  - `Velociraptor_macOS_App/VelociraptorMacOS/Views/Steps/NetworkConfigurationStepView.swift`
  - `Velociraptor_macOS_App/VelociraptorMacOS/Views/Steps/AuthenticationStepView.swift`
  - `Velociraptor_macOS_App/VelociraptorMacOS/Views/Steps/ReviewStepView.swift`
  - `Velociraptor_macOS_App/VelociraptorMacOS/Views/Steps/CompleteStepView.swift`
- [ ] **Verification step**:
  ```bash
  ls -1 Velociraptor_macOS_App/VelociraptorMacOS/Views/Steps/*.swift | wc -l
  # Expected: 9 wizard step files
  ```
- [ ] **Close-out comment**: `Verified as implemented`
- [ ] **Manual close command** (do not execute):
  ```bash
  gh issue close 25 -c "Verified as implemented"
  ```

---

#### Issue #26 — Incident Response UI Parity

- [ ] **Evidence**: [steering/GITHUB_ISSUES_STATUS.md#issue-26](steering/GITHUB_ISSUES_STATUS.md)
- [ ] **Files touched**:
  - `Velociraptor_macOS_App/VelociraptorMacOS/Views/IncidentResponse/IncidentResponseView.swift`
  - `Velociraptor_macOS_App/VelociraptorMacOSUITests/IncidentResponseUITests.swift`
- [ ] **Verification step**:
  ```bash
  grep -c "func test" Velociraptor_macOS_App/VelociraptorMacOSUITests/IncidentResponseUITests.swift
  # Expected: 14 UI tests
  ```
- [ ] **Close-out comment**: `Verified as implemented`
- [ ] **Manual close command** (do not execute):
  ```bash
  gh issue close 26 -c "Verified as implemented"
  ```

---

#### Issue #27 — launchd Service Integration

- [ ] **Evidence**: [steering/GITHUB_ISSUES_STATUS.md#issue-27](steering/GITHUB_ISSUES_STATUS.md)
- [ ] **Files touched**:
  - `Velociraptor_macOS_App/VelociraptorMacOS/Services/DeploymentManager.swift`
- [ ] **Verification step**:
  ```bash
  grep -n "generateLaunchdPlist\|startService\|stopService\|isRunning" \
    Velociraptor_macOS_App/VelociraptorMacOS/Services/DeploymentManager.swift
  ```
- [ ] **Close-out comment**: `Verified as implemented`
- [ ] **Manual close command** (do not execute):
  ```bash
  gh issue close 27 -c "Verified as implemented"
  ```

---

#### Issue #28 — Firewall and Permissions Guidance

- [ ] **Evidence**: [steering/GITHUB_ISSUES_STATUS.md#issue-28](steering/GITHUB_ISSUES_STATUS.md)
- [ ] **Files touched**:
  - `Velociraptor_macOS_App/VelociraptorMacOS/Services/DeploymentManager.swift`
  - `Velociraptor_macOS_App/VelociraptorMacOS/Services/NotificationManager.swift`
- [ ] **Verification step**:
  ```bash
  grep -n "requestPermission\|checkPermissions" \
    Velociraptor_macOS_App/VelociraptorMacOS/Services/NotificationManager.swift
  ```
- [ ] **Close-out comment**: `Verified as implemented`
- [ ] **Manual close command** (do not execute):
  ```bash
  gh issue close 28 -c "Verified as implemented"
  ```

---

#### Issue #29 — System Detection and Telemetry

- [ ] **Evidence**: [steering/GITHUB_ISSUES_STATUS.md#issue-29](steering/GITHUB_ISSUES_STATUS.md)
- [ ] **Files touched**:
  - `modules/VelociraptorDeployment/functions/Get-MacOSSystemSpecs.ps1`
  - `Velociraptor_macOS_App/VelociraptorMacOS/Services/DeploymentManager.swift`
- [ ] **Verification step**:
  ```bash
  grep -n "getSystemArchitecture\|installedVersion" \
    Velociraptor_macOS_App/VelociraptorMacOS/Services/DeploymentManager.swift
  cat modules/VelociraptorDeployment/functions/Get-MacOSSystemSpecs.ps1 | head -20
  ```
- [ ] **Close-out comment**: `Verified as implemented`
- [ ] **Manual close command** (do not execute):
  ```bash
  gh issue close 29 -c "Verified as implemented"
  ```

---

#### Issue #30 — Packaging, Signing, Notarization

- [ ] **Evidence**: [steering/GITHUB_ISSUES_STATUS.md#issue-30](steering/GITHUB_ISSUES_STATUS.md)
- [ ] **Files touched**:
  - `Velociraptor_macOS_App/scripts/create-release.sh`
  - `.github/workflows/macos-build.yml`
  - `Formula/velociraptor-gui.rb`
- [ ] **Verification step**:
  ```bash
  # Verify release script exists
  head -20 Velociraptor_macOS_App/scripts/create-release.sh
  
  # Verify CI has signed-release job
  grep -n "signed-release\|notarize" .github/workflows/macos-build.yml
  
  # Verify Homebrew formula exists
  cat Formula/velociraptor-gui.rb | head -10
  ```
- [ ] **Close-out comment**: `Verified as implemented`
- [ ] **Manual close command** (do not execute):
  ```bash
  gh issue close 30 -c "Verified as implemented"
  ```

---

#### Issue #31 — QA and UA Automation with Reporting

- [ ] **Evidence**: [steering/GITHUB_ISSUES_STATUS.md#issue-31](steering/GITHUB_ISSUES_STATUS.md)
- [ ] **Files touched**:
  - `Velociraptor_macOS_App/VelociraptorMacOS/TestingAgent/TestingAgent.swift`
  - `Velociraptor_macOS_App/VelociraptorMacOS/TestingAgent/GapValidator.swift`
  - `Velociraptor_macOS_App/VelociraptorMacOS/TestingAgent/TestReporter.swift`
  - `Velociraptor_macOS_App/VelociraptorMacOS/TestingAgent/XcodeTestRunner.swift`
  - `Velociraptor_macOS_App/VelociraptorMacOS/TestingAgent/DeterminismChecker.swift`
  - `Velociraptor_macOS_App/VelociraptorMacOS/TestingAgent/TestingAgentCLI.swift`
- [ ] **Verification step**:
  ```bash
  # Count test files
  find Velociraptor_macOS_App -name "*Tests.swift" | wc -l
  # Expected: 19+ test files
  
  # Count test functions
  grep -r "func test" Velociraptor_macOS_App/VelociraptorMacOSTests/ \
    Velociraptor_macOS_App/VelociraptorMacOSUITests/ | wc -l
  # Expected: 230+ tests
  ```
- [ ] **Close-out comment**: `Verified as implemented`
- [ ] **Manual close command** (do not execute):
  ```bash
  gh issue close 31 -c "Verified as implemented"
  ```

---

#### Issue #32 — Docs: macOS Usage, UAT, Troubleshooting

- [ ] **Evidence**: [steering/GITHUB_ISSUES_STATUS.md#issue-32](steering/GITHUB_ISSUES_STATUS.md)
- [ ] **Files touched**:
  - `Velociraptor_macOS_App/README.md`
  - `docs/MACOS_CONTRIBUTING.md`
  - `docs/PARALLELS_MCP_SETUP.md`
  - `docs/QA_QUALITY_GATE.md`
  - `docs/QA_QUICK_REFERENCE.md`
  - `steering/MACOS_CODE_REVIEW_ANALYSIS.md`
  - `steering/MACOS_PRODUCTION_COMPLETE.md`
  - `steering/GITHUB_ISSUES_STATUS.md`
- [ ] **Verification step**:
  ```bash
  # Count documentation files
  find docs steering Velociraptor_macOS_App -name "*.md" | wc -l
  # Expected: 30+ documentation files
  ```
- [ ] **Close-out comment**: `Verified as implemented`
- [ ] **Manual close command** (do not execute):
  ```bash
  gh issue close 32 -c "Verified as implemented"
  ```

---

## C) Batch Close Section

### Manual Batch Close Command

> **Note**: The current GitHub token lacks write permissions for issues. This command must be run by a maintainer with appropriate repository rights.

```bash
# Batch close all 18 verified issues
for i in {33..40} {23..32}; do
  gh issue close $i -c "Verified as implemented"
  echo "Closed issue #$i"
  sleep 1  # Rate limiting
done
```

### Alternative: Individual Close Commands

```bash
# GAP Issues (#33-40)
gh issue close 33 -c "Verified as implemented"
gh issue close 34 -c "Verified as implemented"
gh issue close 35 -c "Verified as implemented"
gh issue close 36 -c "Verified as implemented"
gh issue close 37 -c "Verified as implemented"
gh issue close 38 -c "Verified as implemented"
gh issue close 39 -c "Verified as implemented"
gh issue close 40 -c "Verified as implemented"

# macOS Feature Issues (#23-32)
gh issue close 23 -c "Verified as implemented"
gh issue close 24 -c "Verified as implemented"
gh issue close 25 -c "Verified as implemented"
gh issue close 26 -c "Verified as implemented"
gh issue close 27 -c "Verified as implemented"
gh issue close 28 -c "Verified as implemented"
gh issue close 29 -c "Verified as implemented"
gh issue close 30 -c "Verified as implemented"
gh issue close 31 -c "Verified as implemented"
gh issue close 32 -c "Verified as implemented"
```

---

## D) Post-Close Hygiene

After all issues are closed, complete these final checks:

- [ ] **Ensure no follow-up issues needed**
  - Review each closed issue for any unaddressed acceptance criteria
  - Check for any regression reports
  
- [ ] **Ensure CI green on default branch**
  ```bash
  gh run list --branch main --limit 5
  # All runs should show ✓ (success)
  ```

- [ ] **Confirm no doc drift vs `steering/GITHUB_ISSUES_STATUS.md`**
  - Verify all evidence links still valid
  - Update "Last Updated" timestamp
  
- [ ] **Archive tracking documents**
  - Move to `steering/archive/` if needed for historical reference
  
- [ ] **Update main README if needed**
  - Reflect completed macOS support
  - Update feature list

---

## Summary

| Category | Issues | Status |
|----------|--------|--------|
| GAP Issues (Code Improvements) | #33-40 (8 issues) | ✅ All verified |
| macOS Feature Issues | #23-32 (10 issues) | ✅ All verified |
| **Total** | **18 issues** | **Ready to close** |

---

**Document maintained by**: SDLC Close-Out Coordinator  
**Last verified**: January 23, 2026  
**Evidence document**: `steering/GITHUB_ISSUES_STATUS.md`
