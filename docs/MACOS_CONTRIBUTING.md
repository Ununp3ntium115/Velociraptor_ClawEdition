# Contributing to Velociraptor macOS

This guide covers how to set up your development environment and contribute to the Velociraptor macOS native application.

## Prerequisites

- **macOS 13.0 (Ventura)** or later
- **Xcode 15.0** or later
- **Swift 5.9** or later
- **Homebrew** (for tool installation)

## Development Setup

### 1. Install Dependencies

```bash
# Install XcodeGen for project file generation
brew install xcodegen

# Install SwiftLint for code quality
brew install swiftlint

# Optional: Install xcpretty for prettier test output
gem install xcpretty
```

### 2. Clone and Build

```bash
# Clone the repository
git clone https://github.com/Ununp3ntium115/Velociraptor_ClawEdition.git
cd Velociraptor_ClawEdition/VelociraptorMacOS

# Generate Xcode project
xcodegen generate

# Open in Xcode
open VelociraptorMacOS.xcodeproj
```

### 3. Build from Command Line

```bash
# Build debug
swift build

# Build release
swift build -c release

# Run tests
swift test
```

## Project Structure

```
VelociraptorMacOS/
├── Package.swift           # Swift Package Manager manifest
├── project.yml            # XcodeGen configuration
├── VelociraptorMacOS/     # Main application source
│   ├── Models/            # Data models and view models
│   ├── Views/             # SwiftUI views
│   │   └── Steps/         # Wizard step views
│   ├── Services/          # System integrations
│   ├── Utilities/         # Helper classes
│   └── Resources/         # Assets and strings
├── VelociraptorMacOSTests/     # Unit tests
└── VelociraptorMacOSUITests/   # UI tests
```

## Coding Standards

### Swift Style Guide

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftLint (configuration in `.swiftlint.yml`)
- Maximum line length: 120 characters
- Use 4 spaces for indentation (no tabs)

### Naming Conventions

```swift
// Types: UpperCamelCase
struct ConfigurationData { }
class DeploymentManager { }

// Properties and methods: lowerCamelCase
var datastorePath: String
func validateConfiguration() -> Bool

// Constants: lowerCamelCase
let defaultPort = 8443

// Accessibility IDs: dot.notation
static let nextButton = "navigation.button.next"
```

### SwiftUI Best Practices

```swift
// Extract views into components
struct WizardStepHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.title)
            Text(subtitle).font(.subheadline)
        }
    }
}

// Use environment objects for shared state
@EnvironmentObject var appState: AppState

// Apply accessibility identifiers
Button("Next") { ... }
    .accessibilityIdentifier(AccessibilityIdentifiers.Navigation.nextButton)
```

### Localization

All user-visible strings must be localized:

```swift
// Use type-safe Strings enum
Text(Strings.Welcome.title)

// For dynamic strings
Text(String.localized("key"))
```

Add new strings to:
- `VelociraptorMacOS/Resources/en.lproj/Localizable.strings`
- `VelociraptorMacOS/Utilities/Strings.swift`

### Accessibility

All interactive elements need accessibility identifiers:

1. Add identifier to `Utilities/AccessibilityIdentifiers.swift`
2. Apply to view: `.accessibilityIdentifier(AccessibilityIdentifiers.Category.id)`
3. Add matching entry to `VelociraptorMacOSUITests/TestAccessibilityIdentifiers.swift`

## Testing

### Running Tests

```bash
# Unit tests only
swift test --filter VelociraptorMacOSTests

# UI tests (requires Xcode project)
xcodegen generate
xcodebuild test -project VelociraptorMacOS.xcodeproj \
  -scheme VelociraptorMacOS \
  -destination 'platform=macOS' \
  -only-testing:VelociraptorMacOSUITests

# With code coverage
swift test --enable-code-coverage
```

### Writing Tests

#### Unit Tests

```swift
import XCTest
@testable import VelociraptorMacOS

final class MyServiceTests: XCTestCase {
    
    var sut: MyService!  // System Under Test
    
    override func setUpWithError() throws {
        sut = MyService()
    }
    
    override func tearDownWithError() throws {
        sut = nil
    }
    
    func testSomething() throws {
        // Given
        let input = "test"
        
        // When
        let result = sut.process(input)
        
        // Then
        XCTAssertEqual(result, "expected")
    }
}
```

#### UI Tests

```swift
import XCTest

final class MyUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testButtonClick() throws {
        let button = app.buttons[TestIDs.Navigation.nextButton]
        XCTAssertTrue(button.exists)
        button.tap()
        
        // Verify navigation occurred
        XCTAssertTrue(app.staticTexts["Step 2 Title"].exists)
    }
}
```

## Making Changes

### Workflow

1. Create a feature branch: `git checkout -b feature/my-feature`
2. Make your changes
3. Run linting: `swiftlint`
4. Run tests: `swift test`
5. Commit with descriptive message
6. Push and create PR

### Commit Messages

Follow conventional commits:

```
feat: add dark mode support to settings view
fix: correct port validation in network config
docs: update README with build instructions
test: add UI tests for emergency mode
refactor: extract common button styles
```

### Pull Request Checklist

- [ ] Code follows style guidelines
- [ ] SwiftLint passes
- [ ] All unit tests pass
- [ ] UI tests pass
- [ ] Accessibility identifiers added for new UI elements
- [ ] Localization strings added
- [ ] Documentation updated if needed

## Release Process

### Creating a Release

```bash
# Use the automated release script
./scripts/create-release.sh --version 5.0.6

# This will:
# 1. Run tests
# 2. Build release binary
# 3. Create app bundle
# 4. Sign app (if credentials available)
# 5. Create DMG
# 6. Generate checksums
```

### Manual Release Steps

1. Update version in `Package.swift`
2. Update version in `project.yml`
3. Run `xcodegen generate`
4. Build: `swift build -c release`
5. Create app bundle
6. Sign with Developer ID
7. Notarize with Apple
8. Create DMG
9. Upload to GitHub Releases

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/Ununp3ntium115/Velociraptor_ClawEdition/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Ununp3ntium115/Velociraptor_ClawEdition/discussions)
- **Documentation**: [docs.velociraptor.app](https://docs.velociraptor.app)

## License

This project is free for all first responders. See the main repository LICENSE file for details.
