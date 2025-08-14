#!/bin/bash
#
# velociraptor-cleanup.sh
# Cleanup script for Velociraptor macOS installation
#
# This script safely removes Velociraptor installation while preserving user data

set -euo pipefail

# macOS-specific paths
readonly VELOCIRAPTOR_HOME="${HOME}/Library/Application Support/Velociraptor"
readonly VELOCIRAPTOR_LOGS="${HOME}/Library/Logs/Velociraptor"
readonly VELOCIRAPTOR_CACHE="${HOME}/Library/Caches/Velociraptor"
readonly INSTALL_DIR="/usr/local/bin"
readonly LAUNCHD_PLIST="${HOME}/Library/LaunchAgents/com.velocidex.velociraptor.plist"

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
    
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} ${message}" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} ${message}" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} ${message}" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} ${message}" ;;
        *)       echo "[${level}] ${message}" ;;
    esac
}

# Confirm action with user
confirm() {
    local message="$1"
    local response
    
    echo -e "${YELLOW}${message}${NC}"
    read -p "Continue? (y/N): " response
    
    case "$response" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

# Stop Velociraptor service
stop_velociraptor() {
    log "INFO" "Stopping Velociraptor service..."
    
    # Stop launchd service if it exists
    if [[ -f "$LAUNCHD_PLIST" ]]; then
        launchctl unload "$LAUNCHD_PLIST" 2>/dev/null || true
        log "INFO" "Stopped launchd service"
    fi
    
    # Kill any running Velociraptor processes
    local pid_file="${VELOCIRAPTOR_HOME}/velociraptor.pid"
    if [[ -f "$pid_file" ]]; then
        local pid
        pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            log "INFO" "Stopped Velociraptor process (PID: $pid)"
        fi
        rm -f "$pid_file"
    fi
    
    # Kill any remaining processes
    pkill -f "velociraptor" 2>/dev/null || true
}

# Remove binary
remove_binary() {
    local velociraptor_path="${INSTALL_DIR}/velociraptor"
    
    if [[ -f "$velociraptor_path" ]]; then
        log "INFO" "Removing Velociraptor binary..."
        
        if [[ -w "$INSTALL_DIR" ]]; then
            rm -f "$velociraptor_path"
        else
            sudo rm -f "$velociraptor_path"
        fi
        
        log "INFO" "Removed binary from $velociraptor_path"
    else
        log "INFO" "Velociraptor binary not found at $velociraptor_path"
    fi
}

# Remove launchd plist
remove_launchd_plist() {
    if [[ -f "$LAUNCHD_PLIST" ]]; then
        log "INFO" "Removing launchd plist..."
        rm -f "$LAUNCHD_PLIST"
        log "INFO" "Removed $LAUNCHD_PLIST"
    fi
}

# Remove firewall rules
remove_firewall_rules() {
    log "INFO" "Removing firewall rules..."
    
    local velociraptor_path="${INSTALL_DIR}/velociraptor"
    if command -v /usr/libexec/ApplicationFirewall/socketfilterfw &> /dev/null; then
        sudo /usr/libexec/ApplicationFirewall/socketfilterfw --remove "$velociraptor_path" 2>/dev/null || true
        log "INFO" "Removed firewall rules"
    fi
}

# Remove cache and temporary files
remove_cache() {
    if [[ -d "$VELOCIRAPTOR_CACHE" ]]; then
        log "INFO" "Removing cache directory..."
        rm -rf "$VELOCIRAPTOR_CACHE"
        log "INFO" "Removed $VELOCIRAPTOR_CACHE"
    fi
}

# Remove logs (optional)
remove_logs() {
    if [[ -d "$VELOCIRAPTOR_LOGS" ]]; then
        if confirm "Remove log files at $VELOCIRAPTOR_LOGS?"; then
            rm -rf "$VELOCIRAPTOR_LOGS"
            log "INFO" "Removed log directory"
        else
            log "INFO" "Keeping log files"
        fi
    fi
}

# Remove data (optional)
remove_data() {
    if [[ -d "$VELOCIRAPTOR_HOME" ]]; then
        if confirm "Remove all Velociraptor data at $VELOCIRAPTOR_HOME? This cannot be undone!"; then
            rm -rf "$VELOCIRAPTOR_HOME"
            log "INFO" "Removed data directory"
        else
            log "INFO" "Keeping data directory"
        fi
    fi
}

# Show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Cleanup Velociraptor macOS installation

OPTIONS:
    --complete      Remove everything including data and logs
    --preserve-data Remove installation but keep data and logs
    --help          Show this help message

EXAMPLES:
    $0                    # Interactive cleanup (default)
    $0 --complete         # Remove everything
    $0 --preserve-data    # Keep data and logs
EOF
}

# Main cleanup function
main() {
    local preserve_data=false
    local complete_removal=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --complete)
                complete_removal=true
                shift
                ;;
            --preserve-data)
                preserve_data=true
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
    
    log "INFO" "==== Velociraptor macOS Cleanup Started ===="
    
    # Confirm action unless in complete removal mode
    if [[ "$complete_removal" != true ]]; then
        if ! confirm "This will remove Velociraptor installation from your system."; then
            log "INFO" "Cleanup cancelled"
            exit 0
        fi
    fi
    
    # Stop services
    stop_velociraptor
    
    # Remove components
    remove_binary
    remove_launchd_plist
    remove_firewall_rules
    remove_cache
    
    # Handle data and logs based on options
    if [[ "$complete_removal" == true ]]; then
        # Remove everything
        [[ -d "$VELOCIRAPTOR_LOGS" ]] && rm -rf "$VELOCIRAPTOR_LOGS"
        [[ -d "$VELOCIRAPTOR_HOME" ]] && rm -rf "$VELOCIRAPTOR_HOME"
        log "INFO" "Complete removal performed"
    elif [[ "$preserve_data" == true ]]; then
        # Keep data and logs
        log "INFO" "Data and logs preserved"
    else
        # Interactive mode
        remove_logs
        remove_data
    fi
    
    log "INFO" "==== Cleanup Complete ===="
    log "INFO" "Velociraptor has been removed from your system"
    
    if [[ -d "$VELOCIRAPTOR_HOME" ]]; then
        log "INFO" "Data preserved at: $VELOCIRAPTOR_HOME"
    fi
    
    if [[ -d "$VELOCIRAPTOR_LOGS" ]]; then
        log "INFO" "Logs preserved at: $VELOCIRAPTOR_LOGS"
    fi
}

# Run main function
main "$@"