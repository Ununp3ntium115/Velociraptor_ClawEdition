#!/bin/bash
#
# create-release.sh
# Complete release automation for Velociraptor macOS application
#
# This script handles:
# 1. Environment validation
# 2. Xcode project generation
# 3. Building release binary
# 4. Running tests
# 5. Creating app bundle
# 6. Code signing (optional)
# 7. Notarization (optional)
# 8. DMG creation
# 9. Checksum generation
#
# Usage:
#   ./scripts/create-release.sh [options]
#
# Options:
#   --version VERSION    Set the version number (default: from Info.plist)
#   --skip-tests         Skip running tests
#   --skip-sign          Skip code signing
#   --skip-notarize      Skip notarization
#   --skip-dmg           Skip DMG creation
#   --clean              Clean build directory first
#   --verbose            Verbose output
#   --help               Show this help
#

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
RELEASE_DIR="$PROJECT_DIR/release"
APP_NAME="Velociraptor"
BUNDLE_ID="com.velocidex.velociraptor"

# Default options
SKIP_TESTS=false
SKIP_SIGN=false
SKIP_NOTARIZE=false
SKIP_DMG=false
CLEAN_BUILD=false
VERBOSE=false
VERSION=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# log_info prints an informational message prefixed with a blue "[INFO]" tag to stdout.
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# log_success prints a message prefixed with a green [SUCCESS] label to stdout.
log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# log_warn prints a warning message prefixed with [WARN] in yellow to stdout.
# It takes one argument: the message to display.
log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# log_error prints an error message prefixed with a red "[ERROR]" tag to stdout.
log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# log_step prints a boxed cyan header for a release step using the given title.
log_step() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            VERSION="$2"
            shift 2
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --skip-sign)
            SKIP_SIGN=true
            shift
            ;;
        --skip-notarize)
            SKIP_NOTARIZE=true
            shift
            ;;
        --skip-dmg)
            SKIP_DMG=true
            shift
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            head -35 "$0" | tail -30
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Get version from Info.plist if not specified
if [ -z "$VERSION" ]; then
    VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PROJECT_DIR/VelociraptorMacOS/Info.plist" 2>/dev/null || echo "5.0.5")
fi

# Print banner
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           VELOCIRAPTOR macOS RELEASE BUILD                    ║"
echo "║           Version: $VERSION                                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Validate environment
log_step "Step 1: Validating Environment"

# Check for required tools
REQUIRED_TOOLS=("swift" "xcodebuild" "codesign" "hdiutil")
MISSING_TOOLS=()

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    log_error "Missing required tools: ${MISSING_TOOLS[*]}"
    log_error "Please install Xcode and Command Line Tools"
    exit 1
fi

# Check for optional tools
if command -v xcodegen &> /dev/null; then
    log_info "XcodeGen: $(xcodegen --version)"
else
    log_warn "XcodeGen not found. Install with: brew install xcodegen"
fi

if command -v create-dmg &> /dev/null; then
    log_info "create-dmg: available"
else
    log_warn "create-dmg not found. Install with: brew install create-dmg"
fi

log_info "Swift: $(swift --version | head -1)"
log_info "Xcode: $(xcodebuild -version | head -1)"
log_success "Environment validated"

# Step 2: Clean and prepare
log_step "Step 2: Preparing Build Directory"

if [ "$CLEAN_BUILD" = true ]; then
    log_info "Cleaning build directories..."
    rm -rf "$BUILD_DIR"
    rm -rf "$PROJECT_DIR/.build"
fi

mkdir -p "$BUILD_DIR"
mkdir -p "$RELEASE_DIR"

log_success "Build directories ready"

# Step 3: Generate Xcode project (if XcodeGen available)
log_step "Step 3: Generating Xcode Project"

cd "$PROJECT_DIR"

if command -v xcodegen &> /dev/null && [ -f "project.yml" ]; then
    log_info "Generating Xcode project from project.yml..."
    xcodegen generate
    log_success "Xcode project generated"
else
    log_warn "Skipping Xcode project generation (XcodeGen not available or no project.yml)"
fi

# Step 4: Run tests
if [ "$SKIP_TESTS" = false ]; then
    log_step "Step 4: Running Tests"
    
    log_info "Running unit tests..."
    swift test --parallel 2>&1 | tee "$BUILD_DIR/test-output.log" || {
        log_error "Unit tests failed! Check $BUILD_DIR/test-output.log"
        exit 1
    }
    log_success "All tests passed"
else
    log_step "Step 4: Skipping Tests (--skip-tests)"
fi

# Step 5: Build release binary
log_step "Step 5: Building Release Binary"

log_info "Building with Swift Package Manager..."
swift build -c release \
    -Xswiftc -O \
    -Xswiftc -whole-module-optimization

BINARY_PATH="$PROJECT_DIR/.build/release/VelociraptorMacOS"

if [ ! -f "$BINARY_PATH" ]; then
    log_error "Build failed - binary not found at $BINARY_PATH"
    exit 1
fi

log_success "Build completed: $(ls -lh "$BINARY_PATH" | awk '{print $5}')"

# Step 6: Create app bundle
log_step "Step 6: Creating App Bundle"

APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
rm -rf "$APP_BUNDLE"

mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy Info.plist
cp "$PROJECT_DIR/VelociraptorMacOS/Info.plist" "$APP_BUNDLE/Contents/"

# Update version in Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $(date +%Y%m%d)" "$APP_BUNDLE/Contents/Info.plist"

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Compile assets if available
if [ -d "$PROJECT_DIR/VelociraptorMacOS/Resources/Assets.xcassets" ]; then
    log_info "Compiling asset catalog..."
    xcrun actool "$PROJECT_DIR/VelociraptorMacOS/Resources/Assets.xcassets" \
        --compile "$APP_BUNDLE/Contents/Resources" \
        --platform macosx \
        --minimum-deployment-target 13.0 \
        --app-icon AppIcon \
        --accent-color AccentColor \
        --output-partial-info-plist "$APP_BUNDLE/Contents/Resources/Assets.plist" 2>/dev/null || {
            log_warn "Asset compilation failed (icons may be missing)"
        }
fi

# Copy localization files
if [ -d "$PROJECT_DIR/VelociraptorMacOS/Resources/en.lproj" ]; then
    cp -r "$PROJECT_DIR/VelociraptorMacOS/Resources/en.lproj" "$APP_BUNDLE/Contents/Resources/"
fi

log_success "App bundle created: $APP_BUNDLE"

# Step 7: Code signing
log_step "Step 7: Code Signing"

ENTITLEMENTS="$PROJECT_DIR/VelociraptorMacOS/VelociraptorMacOS.entitlements"

if [ "$SKIP_SIGN" = true ]; then
    log_info "Skipping code signing (--skip-sign)"
    # Ad-hoc sign for local testing
    codesign --force --deep --sign - "$APP_BUNDLE"
    log_info "Ad-hoc signed for local testing"
else
    # Check for Developer ID
    DEVELOPER_ID="${DEVELOPER_ID:-}"
    
    if [ -z "$DEVELOPER_ID" ]; then
        # Try to find a Developer ID certificate
        DEVELOPER_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)".*/\1/' || true)
    fi
    
    if [ -n "$DEVELOPER_ID" ]; then
        log_info "Signing with: $DEVELOPER_ID"
        
        codesign --force --deep --sign "$DEVELOPER_ID" \
            --options runtime \
            --entitlements "$ENTITLEMENTS" \
            --timestamp \
            "$APP_BUNDLE"
        
        # Verify signature
        codesign --verify --verbose=2 "$APP_BUNDLE"
        log_success "Code signing complete"
    else
        log_warn "No Developer ID certificate found - using ad-hoc signing"
        codesign --force --deep --sign - \
            --entitlements "$ENTITLEMENTS" \
            "$APP_BUNDLE"
    fi
fi

# Step 8: Notarization
log_step "Step 8: Notarization"

if [ "$SKIP_NOTARIZE" = true ] || [ "$SKIP_SIGN" = true ]; then
    log_info "Skipping notarization"
else
    NOTARIZE_APPLE_ID="${NOTARIZE_APPLE_ID:-}"
    NOTARIZE_TEAM_ID="${NOTARIZE_TEAM_ID:-}"
    NOTARIZE_PASSWORD="${NOTARIZE_PASSWORD:-}"
    
    if [ -n "$NOTARIZE_APPLE_ID" ] && [ -n "$NOTARIZE_TEAM_ID" ] && [ -n "$NOTARIZE_PASSWORD" ]; then
        log_info "Submitting for notarization..."
        
        # Create zip for notarization
        NOTARIZE_ZIP="$BUILD_DIR/$APP_NAME-notarize.zip"
        ditto -c -k --keepParent "$APP_BUNDLE" "$NOTARIZE_ZIP"
        
        # Submit for notarization
        xcrun notarytool submit "$NOTARIZE_ZIP" \
            --apple-id "$NOTARIZE_APPLE_ID" \
            --team-id "$NOTARIZE_TEAM_ID" \
            --password "$NOTARIZE_PASSWORD" \
            --wait
        
        # Staple the ticket
        xcrun stapler staple "$APP_BUNDLE"
        
        log_success "Notarization complete"
        rm -f "$NOTARIZE_ZIP"
    else
        log_warn "Notarization credentials not configured"
        log_info "Set NOTARIZE_APPLE_ID, NOTARIZE_TEAM_ID, and NOTARIZE_PASSWORD"
    fi
fi

# Step 9: Create DMG
log_step "Step 9: Creating DMG Installer"

if [ "$SKIP_DMG" = true ]; then
    log_info "Skipping DMG creation (--skip-dmg)"
else
    DMG_NAME="$APP_NAME-$VERSION.dmg"
    DMG_PATH="$RELEASE_DIR/$DMG_NAME"
    
    rm -f "$DMG_PATH"
    
    if command -v create-dmg &> /dev/null; then
        log_info "Creating DMG with create-dmg..."
        
        create-dmg \
            --volname "$APP_NAME $VERSION" \
            --window-pos 200 120 \
            --window-size 600 400 \
            --icon-size 100 \
            --icon "$APP_NAME.app" 150 190 \
            --app-drop-link 450 185 \
            --hide-extension "$APP_NAME.app" \
            "$DMG_PATH" \
            "$APP_BUNDLE" 2>/dev/null || {
                log_warn "create-dmg failed, falling back to hdiutil"
                hdiutil create -volname "$APP_NAME" \
                    -srcfolder "$APP_BUNDLE" \
                    -ov -format UDZO \
                    "$DMG_PATH"
            }
    else
        log_info "Creating DMG with hdiutil..."
        hdiutil create -volname "$APP_NAME" \
            -srcfolder "$APP_BUNDLE" \
            -ov -format UDZO \
            "$DMG_PATH"
    fi
    
    log_success "DMG created: $DMG_PATH"
fi

# Step 10: Generate checksums
log_step "Step 10: Generating Checksums"

cd "$RELEASE_DIR"

if ls *.dmg 1> /dev/null 2>&1; then
    shasum -a 256 *.dmg > checksums-sha256.txt
    shasum -a 512 *.dmg >> checksums-sha512.txt
    log_success "Checksums generated"
    cat checksums-sha256.txt
fi

# Copy app bundle to release
cp -r "$APP_BUNDLE" "$RELEASE_DIR/"

# Summary
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    BUILD COMPLETE                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
log_success "Release artifacts in: $RELEASE_DIR"
echo ""
ls -la "$RELEASE_DIR"
echo ""

# Print next steps
echo "Next steps:"
echo "  1. Test the app: open '$RELEASE_DIR/$APP_NAME.app'"
echo "  2. Upload DMG to GitHub releases"
echo "  3. Update Homebrew cask formula"
echo ""