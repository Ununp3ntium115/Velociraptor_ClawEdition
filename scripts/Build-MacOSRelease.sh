#!/bin/bash
#
# Build-MacOSRelease.sh
# Velociraptor macOS Release Build Script
#
# This script handles:
# - Building the release binary
# - Code signing with Developer ID
# - Notarization with Apple
# - Stapling the notarization ticket
# - Creating DMG installer
#
# Requirements:
# - Xcode 15.0+
# - Apple Developer ID certificate
# - App-specific password for notarization
#
# Usage:
#   ./Build-MacOSRelease.sh [--skip-notarize] [--skip-dmg]
#

set -e

# Configuration
APP_NAME="Velociraptor"
BUNDLE_ID="com.velocidex.velociraptor"
VERSION="5.0.5"
BUILD_DIR="$(pwd)/build"
RELEASE_DIR="$(pwd)/release"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

# Developer ID (set via environment or replace)
DEVELOPER_ID="${DEVELOPER_ID:-Developer ID Application: Your Name (TEAMID)}"
NOTARIZE_APPLE_ID="${NOTARIZE_APPLE_ID:-your@email.com}"
NOTARIZE_TEAM_ID="${NOTARIZE_TEAM_ID:-TEAMID}"
NOTARIZE_PASSWORD="${NOTARIZE_PASSWORD:-@keychain:AC_PASSWORD}"

# Flags
SKIP_NOTARIZE=false
SKIP_DMG=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-notarize)
            SKIP_NOTARIZE=true
            shift
            ;;
        --skip-dmg)
            SKIP_DMG=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Header
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     VELOCIRAPTOR macOS RELEASE BUILD                         ║"
echo "║     Version: ${VERSION}                                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Clean and prepare
log_info "Cleaning build directories..."
rm -rf "$BUILD_DIR"
rm -rf "$RELEASE_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$RELEASE_DIR"

# Step 2: Build with Swift Package Manager
log_info "Building release binary..."
cd VelociraptorMacOS

swift build -c release \
    -Xswiftc -O \
    -Xswiftc -whole-module-optimization

log_success "Build completed"

# Step 3: Create app bundle structure
log_info "Creating app bundle..."
APP_BUNDLE="$BUILD_DIR/${APP_NAME}.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp ".build/release/VelociraptorMacOS" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Velocidex. All rights reserved.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
</dict>
</plist>
EOF

# Copy entitlements
cp "VelociraptorMacOS/VelociraptorMacOS.entitlements" "$BUILD_DIR/entitlements.plist"

log_success "App bundle created"

# Step 4: Code signing
log_info "Signing app bundle..."

# Check if we have a valid signing identity
if security find-identity -v -p codesigning | grep -q "Developer ID"; then
    log_info "Developer ID certificate found"
    
    # Sign with hardened runtime
    codesign --force --deep --sign "$DEVELOPER_ID" \
        --options runtime \
        --entitlements "$BUILD_DIR/entitlements.plist" \
        --timestamp \
        "$APP_BUNDLE"
    
    # Verify signature
    codesign --verify --verbose=2 "$APP_BUNDLE"
    
    log_success "Code signing completed"
else
    log_warn "No Developer ID certificate found - skipping code signing"
    log_warn "App will not be notarized and may not run on other Macs"
fi

# Step 5: Notarization
if [ "$SKIP_NOTARIZE" = false ]; then
    log_info "Preparing for notarization..."
    
    # Create ZIP for notarization
    ZIP_PATH="$BUILD_DIR/${APP_NAME}.zip"
    ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"
    
    if [ -n "$NOTARIZE_APPLE_ID" ] && [ "$NOTARIZE_APPLE_ID" != "your@email.com" ]; then
        log_info "Submitting for notarization..."
        
        # Submit for notarization
        xcrun notarytool submit "$ZIP_PATH" \
            --apple-id "$NOTARIZE_APPLE_ID" \
            --team-id "$NOTARIZE_TEAM_ID" \
            --password "$NOTARIZE_PASSWORD" \
            --wait
        
        # Staple the ticket
        log_info "Stapling notarization ticket..."
        xcrun stapler staple "$APP_BUNDLE"
        
        # Verify stapling
        xcrun stapler validate "$APP_BUNDLE"
        
        log_success "Notarization completed and stapled"
    else
        log_warn "Notarization credentials not configured - skipping"
        log_warn "Set NOTARIZE_APPLE_ID, NOTARIZE_TEAM_ID, and NOTARIZE_PASSWORD"
    fi
else
    log_info "Skipping notarization (--skip-notarize flag)"
fi

# Step 6: Create DMG
if [ "$SKIP_DMG" = false ]; then
    log_info "Creating DMG installer..."
    
    DMG_PATH="$RELEASE_DIR/$DMG_NAME"
    DMG_STAGING="$BUILD_DIR/dmg_staging"
    
    mkdir -p "$DMG_STAGING"
    cp -R "$APP_BUNDLE" "$DMG_STAGING/"
    
    # Create Applications symlink
    ln -s /Applications "$DMG_STAGING/Applications"
    
    # Create DMG
    hdiutil create -volname "$APP_NAME" \
        -srcfolder "$DMG_STAGING" \
        -ov -format UDZO \
        "$DMG_PATH"
    
    # Sign DMG
    if security find-identity -v -p codesigning | grep -q "Developer ID"; then
        codesign --force --sign "$DEVELOPER_ID" "$DMG_PATH"
        log_success "DMG signed"
    fi
    
    log_success "DMG created: $DMG_PATH"
else
    log_info "Skipping DMG creation (--skip-dmg flag)"
    
    # Just copy app to release
    cp -R "$APP_BUNDLE" "$RELEASE_DIR/"
fi

# Step 7: Generate checksums
log_info "Generating checksums..."
cd "$RELEASE_DIR"

if [ -f "$DMG_NAME" ]; then
    shasum -a 256 "$DMG_NAME" > "${DMG_NAME}.sha256"
    log_info "SHA256: $(cat ${DMG_NAME}.sha256)"
fi

if [ -d "${APP_NAME}.app" ]; then
    # Create zip for checksum
    zip -r "${APP_NAME}.app.zip" "${APP_NAME}.app"
    shasum -a 256 "${APP_NAME}.app.zip" > "${APP_NAME}.app.zip.sha256"
fi

# Step 8: Summary
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     BUILD COMPLETE                                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
log_success "Release artifacts in: $RELEASE_DIR"
ls -la "$RELEASE_DIR"
echo ""

# Verification commands
echo "To verify the build:"
echo "  codesign -dv --verbose=4 $APP_BUNDLE"
echo "  spctl -a -vvv -t install $APP_BUNDLE"
echo ""
