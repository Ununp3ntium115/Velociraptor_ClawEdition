# Velociraptor macOS

Native macOS application for Velociraptor DFIR Framework deployment and configuration.

## Overview

This is the native macOS (Swift/SwiftUI) implementation of the Velociraptor configuration wizard and incident response collector. It provides a fully native macOS experience with proper integration of:

- **macOS Keychain** - Secure credential storage
- **launchd** - Service management
- **Notarization** - Code signing for Gatekeeper
- **SwiftUI** - Modern declarative UI

## Installation

### Homebrew (Recommended)

```bash
# Install the GUI application
brew install --cask velociraptor-gui

# Or build from source
brew install velociraptor-setup --with-gui
```

### Direct Download

Download the latest DMG from [GitHub Releases](https://github.com/Ununp3ntium115/Velociraptor_ClawEdition/releases).

### Build from Source

See [Building](#building) section below.

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later (for development)
- Swift 5.9 or later
- XcodeGen (for project generation): `brew install xcodegen`

## Features

### Configuration Wizard
- **8-step guided configuration** - Walk through all Velociraptor settings
- **Deployment Type Selection** - Server, Standalone, or Client modes
- **Certificate Management** - Self-signed, custom, or Let's Encrypt
- **Security Settings** - TLS, logging, and environment configuration
- **Storage Configuration** - macOS-native paths (~/Library/...)
- **Network Configuration** - Port and binding settings
- **Authentication** - Admin credential setup with Keychain storage
- **Review & Deploy** - Configuration preview and deployment

### Incident Response Collector
- **7 Incident Categories** - 100+ pre-configured scenarios
- **Artifact Selection** - Pre-selected artifacts per incident type
- **Offline Collector Generation** - Portable package creation
- **Priority Classification** - Critical/High/Medium/Low

### Emergency Mode
- **Rapid Deployment** - Under 3 minutes to operational
- **Default Configuration** - Sensible defaults for immediate use
- **Auto-generated Credentials** - Secure password generation

## Project Structure

```
VelociraptorMacOS/
├── Package.swift                       # Swift Package manifest
├── project.yml                         # XcodeGen configuration
├── VelociraptorMacOS/
│   ├── VelociraptorMacOSApp.swift      # Main app entry
│   ├── Info.plist                      # App configuration
│   ├── VelociraptorMacOS.entitlements  # App entitlements
│   ├── Models/
│   │   ├── AppState.swift              # Global app state
│   │   ├── ConfigurationData.swift     # Configuration model
│   │   ├── ConfigurationViewModel.swift
│   │   └── IncidentResponseViewModel.swift
│   ├── Views/
│   │   ├── ContentView.swift           # Main content view
│   │   ├── EmergencyModeView.swift
│   │   ├── SettingsView.swift
│   │   ├── HealthMonitorView.swift     # Service health dashboard
│   │   ├── LogsView.swift              # Log viewer
│   │   ├── Steps/                      # Wizard step views (9 files)
│   │   └── IncidentResponse/
│   │       └── IncidentResponseView.swift
│   ├── Services/
│   │   ├── KeychainManager.swift       # Keychain integration
│   │   ├── DeploymentManager.swift     # Deployment operations
│   │   └── NotificationManager.swift   # System notifications
│   ├── Utilities/
│   │   ├── Logger.swift                # Unified logging
│   │   ├── Strings.swift               # Localization keys
│   │   ├── AccessibilityIdentifiers.swift  # UI test IDs
│   │   └── ConfigurationExporter.swift # Config import/export
│   └── Resources/
│       ├── Assets.xcassets/            # App icons & colors
│       └── en.lproj/Localizable.strings # English strings
├── VelociraptorMacOSTests/             # Unit tests (7 files)
├── VelociraptorMacOSUITests/           # UI tests (5 files)
└── scripts/
    ├── create-release.sh               # Release automation
    └── generate-icons.sh               # App icon generation
```

**Code Statistics:**
- ~12,000 lines of Swift code
- 119 accessibility identifiers
- 327 localization strings
- 80+ unit tests
- 40+ UI tests

## Building

### Quick Start

```bash
cd VelociraptorMacOS

# Install XcodeGen (one-time setup)
brew install xcodegen

# Generate Xcode project
xcodegen generate

# Build release
swift build -c release
```

### Using XcodeGen (Recommended)

The project uses XcodeGen for Xcode project generation:

```bash
# Generate project.xcodeproj from project.yml
xcodegen generate

# Open in Xcode
open VelociraptorMacOS.xcodeproj
```

### Using Swift Package Manager

```bash
cd VelociraptorMacOS
swift build
swift test
```

### Using Command Line

```bash
xcodebuild -project VelociraptorMacOS.xcodeproj \
  -scheme VelociraptorMacOS \
  -configuration Release \
  build
```

### Release Build

Use the automated release script for production builds:

```bash
./scripts/create-release.sh [options]

Options:
  --version VERSION    Set version number
  --skip-tests         Skip running tests
  --skip-sign          Skip code signing
  --skip-notarize      Skip notarization
  --clean              Clean build first
```

This script handles:
1. Environment validation
2. Xcode project generation
3. Running tests
4. Building release binary
5. Creating app bundle
6. Code signing
7. Notarization
8. DMG creation
9. Checksum generation

## Testing

### Run Unit Tests

```bash
swift test
```

Unit test coverage includes:
- `AppStateTests` - Navigation, state management
- `ConfigurationDataTests` - Validation, encoding
- `KeychainManagerTests` - Credential storage
- `DeploymentManagerTests` - Deployment operations
- `IncidentResponseViewModelTests` - IR workflow
- `ConfigurationExporterTests` - Import/export
- `HealthMonitorTests` - Health monitoring

### Run UI Tests

```bash
# Generate Xcode project first
xcodegen generate

# Run UI tests
xcodebuild test -project VelociraptorMacOS.xcodeproj \
  -scheme VelociraptorMacOS \
  -destination 'platform=macOS' \
  -only-testing:VelociraptorMacOSUITests
```

UI test coverage includes:
- Complete wizard navigation (8 steps)
- All form fields and controls
- Emergency mode workflow
- Incident Response interface
- Settings preferences
- Accessibility verification

### Test Coverage

```bash
swift test --enable-code-coverage

# Generate HTML report
xcrun llvm-cov show \
  .build/debug/VelociraptorMacOSPackageTests.xctest/Contents/MacOS/VelociraptorMacOSPackageTests \
  -instr-profile .build/debug/codecov/default.profdata \
  -format html > coverage.html
```

### Accessibility Testing

All UI elements have accessibility identifiers for:
- XCUITest automation
- VoiceOver navigation
- UI testing frameworks

See `Utilities/AccessibilityIdentifiers.swift` for the complete list.

## Code Signing

For distribution, the app must be signed and notarized:

```bash
# Sign the app
codesign --force --deep --sign "Developer ID Application: Your Name" \
  VelociraptorMacOS.app

# Create notarization request
xcrun notarytool submit VelociraptorMacOS.app \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "app-specific-password" \
  --wait

# Staple the ticket
xcrun stapler staple VelociraptorMacOS.app
```

## Configuration Storage

The app follows macOS conventions for data storage:

| Data Type | Location |
|-----------|----------|
| Datastore | `~/Library/Application Support/Velociraptor/` |
| Logs | `~/Library/Logs/Velociraptor/` |
| Cache | `~/Library/Caches/Velociraptor/` |
| Credentials | macOS Keychain |
| Service | `~/Library/LaunchAgents/com.velocidex.velociraptor.plist` |

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘N | New Configuration |
| ⌘O | Open Configuration |
| ⌘S | Save Configuration |
| ⇧⌘E | Emergency Deployment |
| ⌘, | Preferences |
| ⌘? | Help |

## Architecture

The app uses a clean MVVM architecture:

- **Models** - Data structures and business logic
- **ViewModels** - Observable state management
- **Views** - SwiftUI declarative UI
- **Services** - System integration (Keychain, Deployment)

Key patterns:
- `@StateObject` for view model ownership
- `@EnvironmentObject` for dependency injection
- `async/await` for asynchronous operations
- `Combine` for reactive data flow

## Dependencies

The app uses only Apple frameworks with no third-party dependencies:

- SwiftUI
- Foundation
- Security (Keychain)
- os.log (Unified Logging)
- Network

## License

Free for all first responders. See main repository LICENSE file.

## Support

- Documentation: https://docs.velociraptor.app/
- Issues: https://github.com/Velocidex/velociraptor/issues
- Community: https://www.velocidex.com/community/
