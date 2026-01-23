# Velociraptor macOS

Native macOS application for Velociraptor DFIR Framework deployment and configuration.

## Overview

This is the native macOS (Swift/SwiftUI) implementation of the Velociraptor configuration wizard and incident response collector. It provides a fully native macOS experience with proper integration of:

- **macOS Keychain** - Secure credential storage
- **launchd** - Service management
- **Notarization** - Code signing for Gatekeeper
- **SwiftUI** - Modern declarative UI

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later (for development)
- Swift 5.9 or later

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
├── VelociraptorMacOS/
│   ├── VelociraptorMacOSApp.swift    # Main app entry
│   ├── Models/
│   │   ├── AppState.swift             # Global app state
│   │   ├── ConfigurationData.swift    # Configuration model
│   │   ├── ConfigurationViewModel.swift
│   │   └── IncidentResponseViewModel.swift
│   ├── Views/
│   │   ├── ContentView.swift          # Main content view
│   │   ├── EmergencyModeView.swift
│   │   ├── SettingsView.swift
│   │   ├── Steps/                     # Wizard step views
│   │   │   ├── WelcomeStepView.swift
│   │   │   ├── DeploymentTypeStepView.swift
│   │   │   ├── CertificateSettingsStepView.swift
│   │   │   ├── SecuritySettingsStepView.swift
│   │   │   ├── StorageConfigurationStepView.swift
│   │   │   ├── NetworkConfigurationStepView.swift
│   │   │   ├── AuthenticationStepView.swift
│   │   │   ├── ReviewStepView.swift
│   │   │   └── CompleteStepView.swift
│   │   └── IncidentResponse/
│   │       └── IncidentResponseView.swift
│   ├── Services/
│   │   ├── KeychainManager.swift      # Keychain integration
│   │   └── DeploymentManager.swift    # Deployment operations
│   ├── Utilities/
│   │   └── Logger.swift               # Unified logging
│   └── Resources/
├── VelociraptorMacOSTests/            # Unit tests
└── VelociraptorMacOSUITests/          # UI tests
```

## Building

### Using Xcode

1. Open `VelociraptorMacOS.xcodeproj` in Xcode
2. Select the `VelociraptorMacOS` scheme
3. Build (⌘B) or Run (⌘R)

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

## Testing

### Run Unit Tests

```bash
swift test
```

### Run UI Tests

```bash
xcodebuild test -project VelociraptorMacOS.xcodeproj \
  -scheme VelociraptorMacOS \
  -destination 'platform=macOS'
```

### Test Coverage

```bash
swift test --enable-code-coverage
xcov report
```

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
