#!/bin/bash
#
# deploy-velociraptor-standalone.sh
# Homebrew-compatible Velociraptor deployment for macOS
#
# This script:
# ▸ Downloads latest Velociraptor binary for macOS
# ▸ Creates ~/Library/Application Support/Velociraptor as datastore
# ▸ Configures macOS firewall rules (if needed)
# ▸ Launches velociraptor gui --datastore ~/Library/Application Support/Velociraptor
# ▸ Waits until the port is listening, then exits
#
# Logs → ~/Library/Logs/Velociraptor/standalone_deploy.log

set -euo pipefail

# macOS-specific paths following Apple guidelines
readonly VELOCIRAPTOR_HOME="${HOME}/Library/Application Support/Velociraptor"
readonly VELOCIRAPTOR_LOGS="${HOME}/Library/Logs/Velociraptor"
readonly VELOCIRAPTOR_CACHE="${HOME}/Library/Caches/Velociraptor"
readonly INSTALL_DIR="/usr/local/bin"
readonly GUI_PORT=8889

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure log directory exists
    mkdir -p "$VELOCIRAPTOR_LOGS"
    
    # Log to file
    echo "${timestamp} [${level}] ${message}" >> "${VELOCIRAPTOR_LOGS}/standalone_deploy.log"
    
    # Log to console with colors
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} ${message}" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} ${message}" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} ${message}" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} ${message}" ;;
        *)       echo "[${level}] ${message}" ;;
    esac
}

# Check if running on macOS
check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        log "ERROR" "This script is designed for macOS only"
        exit 1
    fi
    
    local macos_version=$(sw_vers -productVersion)
    log "INFO" "Running on macOS ${macos_version}"
}

# Check for required tools
check_dependencies() {
    local missing_deps=()
    
    # Check for curl
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    # Check for jq (for JSON parsing)
    if ! command -v jq &> /dev/null; then
        log "WARN" "jq not found. Installing via Homebrew..."
        if command -v brew &> /dev/null; then
            brew install jq
        else
            log "ERROR" "Homebrew not found. Please install Homebrew first: https://brew.sh"
            exit 1
        fi
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log "ERROR" "Missing dependencies: ${missing_deps[*]}"
        log "INFO" "Please install missing dependencies and try again"
        exit 1
    fi
}

# Get latest Velociraptor release for macOS
get_latest_macos_release() {
    log "INFO" "Querying GitHub for latest Velociraptor release..."
    
    local api_url="https://api.github.com/repos/Velocidex/velociraptor/releases/latest"
    local release_info
    
    if ! release_info=$(curl -s -H "User-Agent: VelociraptorMacOS" "$api_url"); then
        log "ERROR" "Failed to fetch release information from GitHub"
        exit 1
    fi
    
    # Look for macOS AMD64 binary
    local download_url
    download_url=$(echo "$release_info" | jq -r '.assets[] | select(.name | contains("darwin-amd64")) | .browser_download_url' | head -1)
    
    if [[ -z "$download_url" || "$download_url" == "null" ]]; then
        log "ERROR" "Could not find macOS AMD64 binary in latest release"
        exit 1
    fi
    
    echo "$download_url"
}

# Download Velociraptor binary
download_velociraptor() {
    local download_url="$1"
    local binary_name="velociraptor"
    local temp_file="/tmp/${binary_name}.download"
    
    log "INFO" "Downloading Velociraptor binary..."
    
    if ! curl -L -o "$temp_file" "$download_url"; then
        log "ERROR" "Failed to download Velociraptor binary"
        exit 1
    fi
    
    # Make executable
    chmod +x "$temp_file"
    
    # Move to install directory (requires sudo for /usr/local/bin)
    if [[ -w "$INSTALL_DIR" ]]; then
        mv "$temp_file" "${INSTALL_DIR}/${binary_name}"
    else
        log "INFO" "Installing to ${INSTALL_DIR} (requires sudo)..."
        sudo mv "$temp_file" "${INSTALL_DIR}/${binary_name}"
    fi
    
    log "INFO" "Velociraptor installed to ${INSTALL_DIR}/${binary_name}"
}

# Setup directories
setup_directories() {
    log "INFO" "Setting up Velociraptor directories..."
    
    # Create required directories
    mkdir -p "$VELOCIRAPTOR_HOME"
    mkdir -p "$VELOCIRAPTOR_LOGS"
    mkdir -p "$VELOCIRAPTOR_CACHE"
    
    log "INFO" "Created directories:"
    log "INFO" "  Data: $VELOCIRAPTOR_HOME"
    log "INFO" "  Logs: $VELOCIRAPTOR_LOGS"
    log "INFO" "  Cache: $VELOCIRAPTOR_CACHE"
}

# Configure macOS firewall (if needed)
configure_firewall() {
    log "INFO" "Checking macOS firewall configuration..."
    
    # Check if firewall is enabled
    local firewall_status
    firewall_status=$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate)
    
    if [[ "$firewall_status" == *"enabled"* ]]; then
        log "INFO" "Firewall is enabled, checking Velociraptor access..."
        
        # Add firewall rule for Velociraptor if needed
        local velociraptor_path="${INSTALL_DIR}/velociraptor"
        if [[ -f "$velociraptor_path" ]]; then
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add "$velociraptor_path"
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblock "$velociraptor_path"
            log "INFO" "Added firewall exception for Velociraptor"
        fi
    else
        log "INFO" "Firewall is disabled, no configuration needed"
    fi
}

# Wait for TCP port to be available
wait_for_port() {
    local port="$1"
    local timeout="${2:-30}"
    local count=0
    
    log "INFO" "Waiting for port $port to be available..."
    
    while [[ $count -lt $timeout ]]; do
        if nc -z localhost "$port" 2>/dev/null; then
            log "INFO" "Port $port is now available"
            return 0
        fi
        
        sleep 1
        ((count++))
    done
    
    log "WARN" "Port $port did not become available within $timeout seconds"
    return 1
}

# Launch Velociraptor GUI
launch_velociraptor() {
    local velociraptor_path="${INSTALL_DIR}/velociraptor"
    
    if [[ ! -f "$velociraptor_path" ]]; then
        log "ERROR" "Velociraptor binary not found at $velociraptor_path"
        exit 1
    fi
    
    log "INFO" "Launching Velociraptor GUI..."
    
    # Launch in background
    nohup "$velociraptor_path" gui --datastore "$VELOCIRAPTOR_HOME" \
        > "${VELOCIRAPTOR_LOGS}/velociraptor.log" 2>&1 &
    
    local pid=$!
    echo $pid > "${VELOCIRAPTOR_HOME}/velociraptor.pid"
    
    log "INFO" "Velociraptor started with PID: $pid"
    
    # Wait for port to be available
    if wait_for_port "$GUI_PORT" 30; then
        log "INFO" "Velociraptor GUI is ready!"
        log "INFO" "Access at: https://127.0.0.1:${GUI_PORT}"
        log "INFO" "Default credentials: admin / password"
        
        # Open in default browser (optional)
        if command -v open &> /dev/null; then
            log "INFO" "Opening in default browser..."
            sleep 2
            open "https://127.0.0.1:${GUI_PORT}" 2>/dev/null || true
        fi
    else
        log "ERROR" "Velociraptor GUI failed to start properly"
        log "INFO" "Check logs at: ${VELOCIRAPTOR_LOGS}/velociraptor.log"
        exit 1
    fi
}

# Create launchd plist for auto-start (optional)
create_launchd_plist() {
    local plist_dir="${HOME}/Library/LaunchAgents"
    local plist_file="${plist_dir}/com.velocidex.velociraptor.plist"
    
    mkdir -p "$plist_dir"
    
    cat > "$plist_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.velocidex.velociraptor</string>
    <key>ProgramArguments</key>
    <array>
        <string>${INSTALL_DIR}/velociraptor</string>
        <string>gui</string>
        <string>--datastore</string>
        <string>${VELOCIRAPTOR_HOME}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${VELOCIRAPTOR_LOGS}/velociraptor.log</string>
    <key>StandardErrorPath</key>
    <string>${VELOCIRAPTOR_LOGS}/velociraptor.error.log</string>
    <key>WorkingDirectory</key>
    <string>${VELOCIRAPTOR_HOME}</string>
</dict>
</plist>
EOF
    
    log "INFO" "Created launchd plist at: $plist_file"
    log "INFO" "To enable auto-start: launchctl load $plist_file"
}

# Show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy Velociraptor DFIR framework on macOS

OPTIONS:
    --service-mode  Run in service mode (for Homebrew service)
    --help          Show this help message

EXAMPLES:
    $0              # Standard deployment
    $0 --service-mode  # Service mode deployment
EOF
}

# Main execution
main() {
    local service_mode=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --service-mode)
                service_mode=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    log "INFO" "==== Velociraptor macOS Standalone Deployment Started ===="
    
    # Pre-flight checks
    check_macos
    check_dependencies
    
    # Setup
    setup_directories
    
    # Download and install if not already present
    local velociraptor_path="${INSTALL_DIR}/velociraptor"
    if [[ ! -f "$velociraptor_path" ]]; then
        local download_url
        download_url=$(get_latest_macos_release)
        download_velociraptor "$download_url"
    else
        log "INFO" "Using existing Velociraptor binary at $velociraptor_path"
    fi
    
    # Configure system
    configure_firewall
    
    # Launch application
    launch_velociraptor
    
    # Create auto-start configuration
    create_launchd_plist
    
    log "INFO" "==== Deployment Complete ===="
    log "INFO" "Velociraptor is now running and accessible at https://127.0.0.1:${GUI_PORT}"
    log "INFO" "Logs are available at: ${VELOCIRAPTOR_LOGS}/"
    log "INFO" "To stop: kill \$(cat ${VELOCIRAPTOR_HOME}/velociraptor.pid)"
}

# Run main function
main "$@"