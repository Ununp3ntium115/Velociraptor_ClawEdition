#!/bin/bash
#
# generate-icons.sh
# Generates all required macOS app icon sizes from a source image
#
# Usage: ./generate-icons.sh <source-image.png>
#
# Requirements:
# - Source image should be at least 1024x1024 pixels
# - sips (built into macOS) or ImageMagick
#
# Output:
# - All icon sizes in VelociraptorMacOS/Resources/Assets.xcassets/AppIcon.appiconset/
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ICON_DIR="$PROJECT_DIR/VelociraptorMacOS/Resources/Assets.xcassets/AppIcon.appiconset"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check for source image
if [ -z "$1" ]; then
    log_warn "No source image provided. Creating placeholder icons."
    CREATE_PLACEHOLDERS=true
else
    SOURCE_IMAGE="$1"
    if [ ! -f "$SOURCE_IMAGE" ]; then
        log_error "Source image not found: $SOURCE_IMAGE"
        exit 1
    fi
    CREATE_PLACEHOLDERS=false
fi

# Icon sizes for macOS (size@scale)
declare -a ICON_SIZES=(
    "16:1:icon_16x16.png"
    "16:2:icon_16x16@2x.png"
    "32:1:icon_32x32.png"
    "32:2:icon_32x32@2x.png"
    "128:1:icon_128x128.png"
    "128:2:icon_128x128@2x.png"
    "256:1:icon_256x256.png"
    "256:2:icon_256x256@2x.png"
    "512:1:icon_512x512.png"
    "512:2:icon_512x512@2x.png"
)

mkdir -p "$ICON_DIR"

if [ "$CREATE_PLACEHOLDERS" = true ]; then
    log_info "Creating placeholder icons with sips..."
    
    # Check if we have ImageMagick
    if command -v convert &> /dev/null; then
        log_info "Using ImageMagick to generate placeholders"
        
        for ICON_SPEC in "${ICON_SIZES[@]}"; do
            IFS=':' read -r SIZE SCALE FILENAME <<< "$ICON_SPEC"
            ACTUAL_SIZE=$((SIZE * SCALE))
            OUTPUT_PATH="$ICON_DIR/$FILENAME"
            
            # Create a simple green placeholder with "V" for Velociraptor
            convert -size "${ACTUAL_SIZE}x${ACTUAL_SIZE}" \
                xc:"#1a7f37" \
                -fill white \
                -gravity center \
                -pointsize $((ACTUAL_SIZE / 2)) \
                -annotate +0+0 "V" \
                "$OUTPUT_PATH"
            
            log_info "Created: $FILENAME (${ACTUAL_SIZE}x${ACTUAL_SIZE})"
        done
    else
        log_warn "ImageMagick not found. Creating empty placeholder files."
        log_warn "Install ImageMagick: brew install imagemagick"
        log_warn "Or provide a source image: ./generate-icons.sh source.png"
        
        # Create Contents.json pointing to files that will be created
        cat > "$ICON_DIR/PLACEHOLDER_README.txt" << 'EOF'
App Icon Placeholders

This directory needs actual PNG icon files. To generate them:

Option 1: Provide a source image (1024x1024 or larger)
    ./scripts/generate-icons.sh path/to/velociraptor-logo.png

Option 2: Install ImageMagick for auto-generated placeholders
    brew install imagemagick
    ./scripts/generate-icons.sh

Option 3: Manually create the following files:
    - icon_16x16.png (16x16)
    - icon_16x16@2x.png (32x32)
    - icon_32x32.png (32x32)
    - icon_32x32@2x.png (64x64)
    - icon_128x128.png (128x128)
    - icon_128x128@2x.png (256x256)
    - icon_256x256.png (256x256)
    - icon_256x256@2x.png (512x512)
    - icon_512x512.png (512x512)
    - icon_512x512@2x.png (1024x1024)
EOF
        exit 0
    fi
else
    log_info "Generating icons from: $SOURCE_IMAGE"
    
    # Check if sips is available (macOS)
    if command -v sips &> /dev/null; then
        log_info "Using sips (macOS native)"
        
        for ICON_SPEC in "${ICON_SIZES[@]}"; do
            IFS=':' read -r SIZE SCALE FILENAME <<< "$ICON_SPEC"
            ACTUAL_SIZE=$((SIZE * SCALE))
            OUTPUT_PATH="$ICON_DIR/$FILENAME"
            
            sips -z "$ACTUAL_SIZE" "$ACTUAL_SIZE" "$SOURCE_IMAGE" --out "$OUTPUT_PATH" > /dev/null
            log_info "Created: $FILENAME (${ACTUAL_SIZE}x${ACTUAL_SIZE})"
        done
        
    elif command -v convert &> /dev/null; then
        log_info "Using ImageMagick"
        
        for ICON_SPEC in "${ICON_SIZES[@]}"; do
            IFS=':' read -r SIZE SCALE FILENAME <<< "$ICON_SPEC"
            ACTUAL_SIZE=$((SIZE * SCALE))
            OUTPUT_PATH="$ICON_DIR/$FILENAME"
            
            convert "$SOURCE_IMAGE" -resize "${ACTUAL_SIZE}x${ACTUAL_SIZE}" "$OUTPUT_PATH"
            log_info "Created: $FILENAME (${ACTUAL_SIZE}x${ACTUAL_SIZE})"
        done
    else
        log_error "Neither sips nor ImageMagick found. Cannot resize images."
        exit 1
    fi
fi

# Update Contents.json
log_info "Updating Contents.json..."

cat > "$ICON_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcodegen",
    "version" : 1
  }
}
EOF

log_info "App icons generated successfully!"
log_info "Location: $ICON_DIR"
