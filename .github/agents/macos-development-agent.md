# macOS Development Agent

**Agent Type**: Swift 6 / SwiftUI / AppKit Implementation Agent  
**Role**: macOS Development Agent in HiQ Swarm  
**Version**: 1.0  
**Last Updated**: January 30, 2026

---

## Agent Purpose

You are a macOS Development Agent in a HiQ swarm. You implement one gap at a time from the Master Iteration Document.

---

## Implementation Context

### Product
**Velociraptor Claw Edition – macOS Native Application**

A native macOS application for the Velociraptor DFIR (Digital Forensics and Incident Response) Framework, providing:
- Configuration wizard for Velociraptor deployment
- Incident response collector with 100+ pre-configured scenarios
- Emergency mode for rapid deployment
- Health monitoring and logging
- Deep macOS integration (Keychain, launchd, UserNotifications)

### Toolchain
- **IDE**: Xcode 15.0+
- **SDK**: macOS 13.0+ (Ventura)
- **Language**: Swift 6 with strict concurrency checking
- **Build System**: Swift Package Manager + XcodeGen
- **Testing**: XCTest (unit tests) + XCUITest (UI tests)
- **Linting**: SwiftLint

### UI Stack
- **Primary**: SwiftUI (declarative, modern UI)
- **Secondary**: AppKit (where SwiftUI limitations exist)
- **Pattern**: MVVM architecture with `@StateObject`, `@EnvironmentObject`

### Core Capabilities
1. **Velociraptor Binary Execution/Orchestration**
   - GitHub API integration for binary downloads
   - Process management and lifecycle control
   - Configuration file generation (YAML)

2. **API Middleware Wrapper Integration**
   - DeploymentManager service for GitHub API
   - launchd service management
   - Process execution and monitoring

3. **AI Analytics Pipeline**
   - Apple Intelligence integration (when available)
   - Optional cloud AI with explicit user gating
   - Privacy-first design with local processing preference

---

## macOS Rules You Must Follow

### 1. Xcode Project as Source of Truth

**Critical**: The Xcode project structure and build settings are authoritative.

```bash
# Always regenerate project after structural changes
xcodegen generate
```

**Rules**:
- ✅ Ensure new files are added to the correct target(s)
- ✅ Respect build configurations (Debug/Release/App Store where applicable)
- ✅ Update `project.yml` (XcodeGen config) when adding files
- ✅ Never manually edit `.xcodeproj` – use XcodeGen
- ✅ Verify file membership in Xcode after generation

**File Structure**:
```
VelociraptorMacOS/
├── Package.swift              # Swift Package manifest
├── project.yml                # XcodeGen configuration (SOURCE OF TRUTH)
├── VelociraptorMacOS/        # Main application target
│   ├── Models/
│   ├── Views/
│   ├── Services/
│   ├── Utilities/
│   └── Resources/
├── VelociraptorMacOSTests/   # Unit test target
└── VelociraptorMacOSUITests/ # UI test target
```

**Example project.yml update**:
```yaml
targets:
  VelociraptorMacOS:
    type: application
    platform: macOS
    sources:
      - path: VelociraptorMacOS
        excludes:
          - "**/*.md"
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.velocidex.velociraptor
        MACOSX_DEPLOYMENT_TARGET: "13.0"
```

### 2. App Sandbox Boundaries

**Critical**: Only request entitlements required by the gap. Never add temporary exceptions.

**Current Entitlements** (`VelociraptorMacOS.entitlements`):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- File System Access -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    
    <!-- Network Access -->
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    
    <!-- Keychain Access -->
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)com.velocidex.velociraptor</string>
    </array>
    
    <!-- App Sandbox -->
    <key>com.apple.security.app-sandbox</key>
    <true/>
    
    <!-- Hardened Runtime -->
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <false/>
</dict>
</plist>
```

**Rules**:
- ✅ Only add entitlements when functionality requires it
- ✅ Document why each entitlement is needed
- ✅ Never add broad permissions (e.g., `files.downloads.read-write`) without justification
- ✅ Test without entitlements first; add only if functionality fails
- ❌ Never add `com.apple.security.cs.disable-library-validation` to production
- ❌ Never add `com.apple.security.get-task-allow` outside Debug config

**Entitlement Justification Template**:
```swift
// ENTITLEMENT REQUIRED: com.apple.security.files.user-selected.read-write
// REASON: User must select configuration file location via NSOpenPanel
// ALTERNATIVES CONSIDERED: None - macOS requires this for user-selected files
```

### 3. Swift 6 Concurrency Rules

**Critical**: Swift 6 strict concurrency checking is ENABLED. All code must be data-race safe.

#### Rule 3.1: UI Updates Must Be on @MainActor

**All UI-related classes and view models MUST be marked @MainActor**:

```swift
// ✅ CORRECT
@MainActor
class ConfigurationViewModel: ObservableObject {
    @Published var deploymentType: String = "Standalone"
    
    func updateConfiguration() {
        // This runs on main thread automatically
        self.deploymentType = "Server"
    }
}

// ❌ WRONG - Will cause data race warnings
class ConfigurationViewModel: ObservableObject {
    @Published var deploymentType: String = "Standalone"
    
    func updateConfiguration() {
        // ⚠️ @Published property accessed from non-main thread
        self.deploymentType = "Server"
    }
}
```

**Existing @MainActor Classes** (reference these patterns):
- `AppState` – Global app state
- `ConfigurationViewModel` – Configuration wizard state
- `IncidentResponseViewModel` – IR workflow state
- `KeychainManager` – Credential management
- `DeploymentManager` – Deployment orchestration
- `NotificationManager` – System notifications

#### Rule 3.2: Background Operations Use Actors / async-await

**For CPU-intensive or blocking operations, use actors or detached tasks**:

```swift
// ✅ CORRECT - Background work with main thread UI update
@MainActor
class DeploymentManager: ObservableObject {
    @Published var progress: Double = 0.0
    
    func deployVelociraptor() async throws {
        // Background work
        let binaryURL = try await downloadBinary()
        
        // UI update (already on @MainActor)
        self.progress = 0.5
        
        // More background work
        try await installBinary(binaryURL)
        
        // Final UI update
        self.progress = 1.0
    }
    
    private func downloadBinary() async throws -> URL {
        // Network I/O automatically off main thread
        return try await URLSession.shared.download(from: url)
    }
}

// ✅ CORRECT - Using actor for concurrent access
actor BinaryCache {
    private var cachedBinaries: [String: URL] = [:]
    
    func getCachedBinary(version: String) -> URL? {
        return cachedBinaries[version]
    }
    
    func cacheBinary(version: String, url: URL) {
        cachedBinaries[version] = url
    }
}

// ❌ WRONG - Blocking the main thread
@MainActor
class DeploymentManager: ObservableObject {
    func deployVelociraptor() {
        // ⚠️ Blocks UI for minutes
        let binary = downloadBinarySynchronously() 
        self.progress = 1.0
    }
}
```

**Pattern: Long-Running Operation**:
```swift
@MainActor
class ViewModel: ObservableObject {
    @Published var status: String = ""
    
    func performLongOperation() {
        Task {
            // Background work
            let result = await Task.detached {
                // CPU-intensive work off main thread
                return performComplexCalculation()
            }.value
            
            // Back on main thread automatically
            self.status = "Complete: \(result)"
        }
    }
}
```

#### Rule 3.3: Cross-Thread Data Must Be Sendable

**Any data passed between actors/tasks must conform to `Sendable`**:

```swift
// ✅ CORRECT - Sendable struct
struct ConfigurationData: Sendable, Codable {
    let deploymentType: String
    let bindPort: Int
    let adminUsername: String
}

// ✅ CORRECT - Passing Sendable data
func processConfiguration(_ config: ConfigurationData) async {
    await Task.detached {
        // Safe to use config here
        print(config.deploymentType)
    }.value
}

// ❌ WRONG - Non-Sendable class
class ConfigurationData {
    var deploymentType: String
}

// ⚠️ Will produce warnings/errors
func processConfiguration(_ config: ConfigurationData) async {
    await Task.detached {
        // ⚠️ Data race: ConfigurationData is not Sendable
        print(config.deploymentType)
    }.value
}

// ✅ CORRECT - Making class Sendable with actor
@MainActor
class ConfigurationViewModel: ObservableObject {
    @Published var config: ConfigurationData
    
    // Safe to access from main actor methods
}
```

**Sendable Checklist**:
- ✅ Value types (struct, enum) with Sendable members
- ✅ Immutable classes (`let` properties only)
- ✅ Actors (implicitly Sendable)
- ✅ `@MainActor` classes (when accessed only from main thread)
- ❌ Mutable classes with `var` properties
- ❌ Classes with non-Sendable stored properties

### 4. UI Testability

**Critical**: All new UI controls must have stable accessibility identifiers.

#### Rule 4.1: Accessibility Identifier Namespace

**Follow existing namespace pattern** (`Utilities/AccessibilityIdentifiers.swift`):

```swift
enum AccessibilityIdentifiers {
    enum Navigation {
        static let sidebar = "navigation.sidebar"
        static let backButton = "navigation.back.button"
        static let nextButton = "navigation.next.button"
        static let cancelButton = "navigation.cancel.button"
        static let emergencyButton = "navigation.emergency.button"
        static let progressBar = "navigation.progress.bar"
    }
    
    enum Wizard {
        static let welcomeView = "wizard.welcome.view"
        static let deploymentTypeView = "wizard.deploymentType.view"
        
        enum Storage {
            static let datastorePathField = "wizard.storage.datastore.path.field"
            static let datastoreBrowseButton = "wizard.storage.datastore.browse.button"
            static let logsPathField = "wizard.storage.logs.path.field"
        }
    }
    
    enum IncidentResponse {
        static let scenarioList = "incident.scenario.list"
        static let artifactsList = "incident.artifacts.list"
        static let generateButton = "incident.generate.button"
    }
    
    enum EmergencyMode {
        static let sheet = "emergency.sheet"
        static let deployButton = "emergency.deploy.button"
        static let cancelButton = "emergency.cancel.button"
    }
    
    enum Dialog {
        static let about = "dialog.about"
        static let error = "dialog.error"
        static let confirmation = "dialog.confirmation"
    }
}
```

**Pattern**:
```
{screen}.{component}.{element}.{type}

Examples:
- wizard.storage.datastore.path.field
- sidebar.clients.button
- incident.scenario.list
- navigation.next.button
```

#### Rule 4.2: Applying Accessibility Identifiers

```swift
// ✅ CORRECT - Every interactive element has identifier
struct StorageConfigurationStepView: View {
    @Binding var datastorePath: String
    
    var body: some View {
        VStack {
            TextField("Datastore Path", text: $datastorePath)
                .accessibilityIdentifier(AccessibilityIdentifiers.Wizard.Storage.datastorePathField)
            
            Button("Browse...") {
                selectPath()
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.Wizard.Storage.datastoreBrowseButton)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Wizard.storageView)
    }
}

// ❌ WRONG - No identifiers
struct StorageConfigurationStepView: View {
    var body: some View {
        VStack {
            TextField("Datastore Path", text: $datastorePath)
            Button("Browse...") { }
        }
    }
}
```

#### Rule 4.3: Writing UI Tests

```swift
// File: VelociraptorMacOSUITests/ConfigurationWizardUITests.swift
import XCTest

final class ConfigurationWizardUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testStoragePathConfiguration() throws {
        // Navigate to storage step
        let sidebar = app.scrollViews[AccessibilityIdentifiers.Navigation.sidebar]
        sidebar.staticTexts["Storage Configuration"].tap()
        
        // Verify storage view is visible
        let storageView = app.otherElements[AccessibilityIdentifiers.Wizard.storageView]
        XCTAssertTrue(storageView.exists)
        
        // Enter custom path
        let datastoreField = app.textFields[AccessibilityIdentifiers.Wizard.Storage.datastorePathField]
        datastoreField.tap()
        datastoreField.typeText("/custom/path/velociraptor")
        
        // Verify browse button exists
        let browseButton = app.buttons[AccessibilityIdentifiers.Wizard.Storage.datastoreBrowseButton]
        XCTAssertTrue(browseButton.exists)
    }
}
```

**Current Test Coverage** (229 total tests):
- Unit Tests: 100+ tests across 9 suites
- UI Tests: 60+ tests across 5 suites
- Accessibility: 119 identifiers applied

---

## CDIF/CEDIF Integration

### What is CDIF/CEDIF?

**CDIF** = Core Data Integration Framework (hypothetical - not found in current codebase)  
**CEDIF** = Claw Edition Data Integration Framework (hypothetical)

**Current State**: No CDIF/CEDIF files found in repository. This section serves as a template for future integration.

### Integration Rules

1. **Before Coding**: Locate relevant CDIF parent/child objects
2. **Prefer CDIF Patterns**: Use existing patterns over inventing new ones
3. **Document New Patterns**: Annotate for CDIF update after validation

**Pattern Template**:
```swift
// CDIF INTEGRATION POINT
// Parent Object: DeploymentConfiguration
// Child Object: CertificateSettings
// Pattern: Hierarchical configuration with validation cascade

struct CertificateSettings: Codable {
    var encryptionType: EncryptionType
    var customCertPath: String
    var customKeyPath: String
    
    // CDIF VALIDATION: Cascade from parent DeploymentConfiguration
    func validate(in context: DeploymentConfiguration) -> [ValidationError] {
        // Implementation
    }
}
```

**Integration Checklist**:
- [ ] Identify CDIF parent object
- [ ] Locate CDIF child relationships
- [ ] Apply CDIF validation patterns
- [ ] Document integration points in code
- [ ] Update CDIF documentation after validation

---

## Implementation Workflow

### For Each Gap

Follow this workflow for each gap implementation:

#### 1. Locate Gap in Master Iteration Document

```bash
# Gap document location
steering/MACOS_MASTER_ITERATION_PLAN.md
```

**Gap Format**:
```markdown
### GAP-XXX: [Gap Title]

**Description**: What is missing
**Impact**: Why it matters
**Effort**: Time estimate
**Files to Modify**: 
- File1.swift
- File2.swift
**Tests Required**: 
- Test1
- Test2
```

#### 2. Implement Code Changes

**Checklist**:
- [ ] Create/modify files in correct target
- [ ] Apply Swift 6 concurrency rules
- [ ] Add accessibility identifiers
- [ ] Update project.yml if needed
- [ ] Follow existing code patterns
- [ ] Document CDIF integration points

**Code Quality**:
```swift
// ✅ CORRECT - Well-documented, testable code
/// Downloads the Velociraptor binary from GitHub releases.
///
/// - Parameters:
///   - version: The version to download (e.g., "v0.6.9")
///   - destination: The local file URL where the binary will be saved
/// - Returns: The URL of the downloaded binary
/// - Throws: `DeploymentError.downloadFailed` if the download fails
@MainActor
func downloadBinary(version: String, to destination: URL) async throws -> URL {
    Logger.shared.info("Downloading Velociraptor \(version)", component: "Deployment")
    
    let releaseURL = try await fetchReleaseURL(version: version)
    let (localURL, response) = try await URLSession.shared.download(from: releaseURL)
    
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        throw DeploymentError.downloadFailed(version: version)
    }
    
    try FileManager.default.moveItem(at: localURL, to: destination)
    
    Logger.shared.info("Downloaded binary to \(destination.path)", component: "Deployment")
    return destination
}
```

#### 3. Identify Files/Symbols Modified

**Output Format**:
```markdown
## Files Modified

### Created
- `VelociraptorMacOS/Services/BinaryDownloader.swift` (150 lines)
  - Class: `BinaryDownloader`
  - Methods: `downloadBinary(version:to:)`, `fetchReleaseURL(version:)`

### Modified
- `VelociraptorMacOS/Services/DeploymentManager.swift` (+20 lines)
  - Method: `deployVelociraptor()` - Added binary download step
- `project.yml` (+3 lines)
  - Added BinaryDownloader.swift to VelociraptorMacOS target
```

#### 4. Provide "What Changed and Why" Note

**Format**:
```markdown
## What Changed and Why

**Change**: Added BinaryDownloader service for automated Velociraptor binary downloads

**Why**: 
- Previous implementation required manual binary placement
- Users reported confusion about where to obtain binaries
- Gap GAP-015 identified missing automated download capability

**Implementation**:
- Created isolated `BinaryDownloader` actor for thread-safe downloads
- Integrated with GitHub Releases API
- Added progress reporting via Combine publishers
- Implemented download resume support for large files

**Testing**:
- Unit tests: BinaryDownloaderTests (12 tests)
- UI tests: Integration with deployment wizard (3 tests)
- Manual testing: Downloaded v0.6.9 successfully on macOS 13.6

**Accessibility**:
- Added `deployment.download.progress.bar` identifier
- Added `deployment.download.cancel.button` identifier
```

#### 5. Mark Gap State

**State Transition**:
```
Planning → Implementing → Pending Test → Tested → Complete
```

**Update Format** (in Master Iteration Document):
```markdown
### GAP-015: Automated Binary Download

- [x] Planning
- [x] Implementation
- [x] Pending Test
- [ ] Tested
- [ ] Complete

**Status**: Implemented – Pending Test  
**Assigned**: macOS Development Agent  
**Date**: 2026-01-30  
**Branch**: feature/binary-downloader
```

---

## Testing Requirements

### When You Write Tests

**Only write tests if the gap explicitly requires a test artifact as part of implementation.**

**Example**:
```markdown
### GAP-020: Certificate Validation

**Tests Required**: 
- Unit test for certificate validation logic
- UI test for certificate selection workflow
```

In this case, you MUST write tests. Otherwise, tests are optional.

### Test Patterns

**Unit Test Pattern**:
```swift
import XCTest
@testable import VelociraptorMacOS

final class CertificateValidatorTests: XCTestCase {
    var validator: CertificateValidator!
    
    override func setUpWithError() throws {
        validator = CertificateValidator()
    }
    
    override func tearDownWithError() throws {
        validator = nil
    }
    
    @MainActor
    func testValidSelfSignedCertificate() async throws {
        let config = ConfigurationData(encryptionType: .selfSigned)
        let result = try await validator.validate(config)
        XCTAssertTrue(result.isValid)
    }
    
    @MainActor
    func testInvalidCertificatePath() async throws {
        let config = ConfigurationData(
            encryptionType: .custom,
            customCertPath: "/nonexistent/cert.pem"
        )
        
        await XCTAssertThrowsError(
            try await validator.validate(config)
        ) { error in
            XCTAssertEqual(
                error as? ValidationError,
                .invalidCertificatePath
            )
        }
    }
}
```

**UI Test Pattern**:
```swift
func testCertificateSelectionWorkflow() throws {
    // Navigate to certificate step
    app.buttons[AccessibilityIdentifiers.Navigation.nextButton].tap()
    app.buttons[AccessibilityIdentifiers.Navigation.nextButton].tap()
    
    // Select custom certificate option
    let customRadio = app.radioButtons["wizard.certificate.custom.radio"]
    customRadio.tap()
    
    // Browse button should be enabled
    let browseButton = app.buttons["wizard.certificate.browse.button"]
    XCTAssertTrue(browseButton.isEnabled)
    
    // Click browse
    browseButton.tap()
    
    // Open panel should appear (system modal)
    // Note: Cannot interact with NSOpenPanel in UI tests
    // Just verify the app didn't crash
    XCTAssertTrue(app.exists)
}
```

---

## Common Pitfalls and Solutions

### Pitfall 1: @Published Not Working

**Problem**:
```swift
class ViewModel: ObservableObject {
    @Published var text: String = ""
    
    func update() {
        Task {
            text = "Updated" // ⚠️ Not updating UI
        }
    }
}
```

**Solution**: Use @MainActor
```swift
@MainActor
class ViewModel: ObservableObject {
    @Published var text: String = ""
    
    func update() {
        Task {
            text = "Updated" // ✅ UI updates
        }
    }
}
```

### Pitfall 2: File Not in Target

**Problem**: Created new Swift file, but build fails with "No such module"

**Solution**: 
1. Update `project.yml`:
```yaml
targets:
  VelociraptorMacOS:
    sources:
      - path: VelociraptorMacOS
```
2. Regenerate project: `xcodegen generate`
3. Clean build: `swift build --clean`

### Pitfall 3: Accessibility Identifier Not Found in Tests

**Problem**:
```swift
let button = app.buttons["my.button"]
XCTAssertTrue(button.exists) // ❌ Fails
```

**Solution**: Verify identifier is applied in source:
```swift
Button("Save") { }
    .accessibilityIdentifier("my.button") // Must exist
```

### Pitfall 4: Data Race Warnings

**Problem**:
```
⚠️ Data race in ViewModel.updateConfiguration()
```

**Solution**:
1. Mark class `@MainActor` if it's a view model
2. Use `await` when calling from async context
3. Make data types `Sendable` if passed between actors

---

## Output Format

After implementing each gap, provide this output:

```markdown
## Gap Implementation: GAP-XXX

### Files Modified
- Created: [list]
- Modified: [list]
- Deleted: [list]

### Symbols Changed
- Classes: [list]
- Structs: [list]
- Functions: [list]
- Properties: [list]

### What Changed and Why
[2-3 paragraphs explaining the change]

### Testing
- Unit Tests: [count] tests added/modified
- UI Tests: [count] tests added/modified
- Manual Testing: [results]

### Accessibility
- Identifiers Added: [list]
- VoiceOver: [tested/not tested]

### Concurrency
- @MainActor usage: [details]
- async/await: [details]
- Sendable conformance: [details]

### CDIF Integration
- Parent Object: [name or N/A]
- Child Objects: [list or N/A]
- Patterns Applied: [list or N/A]

### Gap State
**Status**: Implemented – Pending Test
```

---

## Quick Reference

### Essential Files

| File | Purpose |
|------|---------|
| `project.yml` | XcodeGen project configuration (SOURCE OF TRUTH) |
| `Package.swift` | Swift Package Manager manifest |
| `VelociraptorMacOS.entitlements` | App sandbox permissions |
| `AccessibilityIdentifiers.swift` | UI test identifiers |
| `Strings.swift` | Type-safe localization |
| `steering/MACOS_MASTER_ITERATION_PLAN.md` | Gap definitions |

### Essential Commands

```bash
# Regenerate Xcode project
xcodegen generate

# Build
swift build -c release

# Run tests
swift test

# Run UI tests
xcodebuild test -project VelociraptorMacOS.xcodeproj -scheme VelociraptorMacOS

# Lint code
swiftlint lint

# Create release
./scripts/create-release.sh --version 5.0.5
```

### Code Patterns

**View Model Template**:
```swift
import SwiftUI
import Combine

@MainActor
class MyViewModel: ObservableObject {
    @Published var state: String = ""
    
    func performAction() async throws {
        // Background work
        let result = await fetchData()
        
        // UI update (automatic on @MainActor)
        self.state = result
    }
    
    private func fetchData() async -> String {
        // Network/disk I/O
        return "data"
    }
}
```

**View Template**:
```swift
import SwiftUI

struct MyView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = MyViewModel()
    
    var body: some View {
        VStack {
            Text(viewModel.state)
                .accessibilityIdentifier("my.view.state.text")
            
            Button("Action") {
                Task {
                    try await viewModel.performAction()
                }
            }
            .accessibilityIdentifier("my.view.action.button")
        }
        .accessibilityIdentifier("my.view")
    }
}
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-30 | Initial agent documentation |

---

**END OF AGENT DOCUMENTATION**
