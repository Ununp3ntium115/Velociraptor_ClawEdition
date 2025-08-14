#!/bin/bash
#
# velociraptor-health.sh
# Health check script for Velociraptor macOS installation
#
# This script performs comprehensive health checks on the Velociraptor installation

set -euo pipefail

# macOS-specific paths
readonly VELOCIRAPTOR_HOME="${HOME}/Library/Application Support/Velociraptor"
readonly VELOCIRAPTOR_LOGS="${HOME}/Library/Logs/Velociraptor"
readonly INSTALL_DIR="/usr/local/bin"
readonly GUI_PORT=8889

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Health check results (using simple approach for compatibility)
health_results=""

# Add result to health_results
add_result() {
    local key="$1"
    local value="$2"
    health_results="${health_results}${key}:${value};"
}

# Get result from health_results
get_result() {
    local key="$1"
    echo "$health_results" | grep -o "${key}:[^;]*" | cut -d: -f2
}

# Get all result keys
get_all_keys() {
    echo "$health_results" | tr ';' '\n' | cut -d: -f1 | grep -v '^$'
}

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
        "PASS")  echo -e "${GREEN}[PASS]${NC} ${message}" ;;
        "FAIL")  echo -e "${RED}[FAIL]${NC} ${message}" ;;
        *)       echo "[${level}] ${message}" ;;
    esac
}

# Check if Velociraptor binary exists
check_binary() {
    local test_name="Binary Installation"
    local velociraptor_path="${INSTALL_DIR}/velociraptor"
    
    if [[ -f "$velociraptor_path" && -x "$velociraptor_path" ]]; then
        log "PASS" "$test_name: Found at $velociraptor_path"
        add_result "binary" "PASS"
        
        # Check version
        local version
        if version=$("$velociraptor_path" version 2>/dev/null | head -1); then
            log "INFO" "Version: $version"
        fi
    else
        log "FAIL" "$test_name: Not found or not executable at $velociraptor_path"
        add_result "binary" "FAIL"
    fi
}

# Check directory structure
check_directories() {
    local test_name="Directory Structure"
    local all_good=true
    
    # Check required directories
    local dirs=("$VELOCIRAPTOR_HOME" "$VELOCIRAPTOR_LOGS")
    
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log "PASS" "Directory exists: $dir"
        else
            log "FAIL" "Directory missing: $dir"
            all_good=false
        fi
    done
    
    # Check permissions
    if [[ -d "$VELOCIRAPTOR_HOME" ]]; then
        if [[ -w "$VELOCIRAPTOR_HOME" ]]; then
            log "PASS" "Data directory is writable"
        else
            log "FAIL" "Data directory is not writable"
            all_good=false
        fi
    fi
    
    add_result "directories" $([ "$all_good" = true ] && echo "PASS" || echo "FAIL")
}

# Check if Velociraptor process is running
check_process() {
    local test_name="Process Status"
    local pid_file="${VELOCIRAPTOR_HOME}/velociraptor.pid"
    
    if [[ -f "$pid_file" ]]; then
        local pid
        pid=$(cat "$pid_file")
        
        if kill -0 "$pid" 2>/dev/null; then
            log "PASS" "$test_name: Running (PID: $pid)"
            add_result "process" "PASS"
        else
            log "FAIL" "$test_name: PID file exists but process not running"
            add_result "process" "FAIL"
        fi
    else
        # Check for any velociraptor processes
        if pgrep -f "velociraptor" > /dev/null; then
            local pids
            pids=$(pgrep -f "velociraptor" | tr '\n' ' ')
            log "WARN" "$test_name: Running but no PID file (PIDs: $pids)"
            add_result "process" "WARN"
        else
            log "FAIL" "$test_name: Not running"
            add_result "process" "FAIL"
        fi
    fi
}

# Check network connectivity
check_network() {
    local test_name="Network Connectivity"
    
    # Check if GUI port is listening
    if nc -z localhost "$GUI_PORT" 2>/dev/null; then
        log "PASS" "$test_name: GUI port $GUI_PORT is accessible"
        add_result "network" "PASS"
        
        # Try to connect to the web interface
        if curl -k -s "https://localhost:$GUI_PORT" > /dev/null 2>&1; then
            log "PASS" "Web interface is responding"
        else
            log "WARN" "Port is open but web interface may not be ready"
        fi
    else
        log "FAIL" "$test_name: GUI port $GUI_PORT is not accessible"
        add_result "network" "FAIL"
    fi
}

# Check disk space
check_disk_space() {
    local test_name="Disk Space"
    local min_space_gb=1
    
    # Get available space for Velociraptor home directory
    local available_space
    available_space=$(df -g "$VELOCIRAPTOR_HOME" 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")
    
    if [[ "$available_space" -gt "$min_space_gb" ]]; then
        log "PASS" "$test_name: ${available_space}GB available"
        add_result "disk_space" "PASS"
    else
        log "WARN" "$test_name: Only ${available_space}GB available (recommended: >${min_space_gb}GB)"
        add_result "disk_space" "WARN"
    fi
}

# Check system resources
check_system_resources() {
    local test_name="System Resources"
    
    # Check memory usage
    local memory_pressure
    memory_pressure=$(memory_pressure 2>/dev/null | grep "System-wide memory free percentage" | awk '{print $5}' | tr -d '%' || echo "50")
    
    if [[ -n "$memory_pressure" && "$memory_pressure" -gt 10 ]]; then
        log "PASS" "Memory: ${memory_pressure}% free"
    else
        log "WARN" "Memory: Low available memory (${memory_pressure}% free)"
    fi
    
    # Check CPU load
    local load_avg
    load_avg=$(uptime | awk -F'load averages:' '{print $2}' | awk '{print $1}')
    
    if [[ -n "$load_avg" ]]; then
        log "INFO" "CPU Load: $load_avg"
    fi
    
    add_result "system_resources" "PASS"
}

# Check log files
check_logs() {
    local test_name="Log Files"
    local log_file="${VELOCIRAPTOR_LOGS}/velociraptor.log"
    local error_log="${VELOCIRAPTOR_LOGS}/velociraptor.error.log"
    
    if [[ -f "$log_file" ]]; then
        local log_size
        log_size=$(stat -f%z "$log_file" 2>/dev/null || echo "0")
        log "PASS" "Main log exists (${log_size} bytes)"
        
        # Check for recent errors
        if [[ -f "$error_log" ]]; then
            local error_count
            error_count=$(wc -l < "$error_log" 2>/dev/null || echo "0")
            if [[ "$error_count" -gt 0 ]]; then
                log "WARN" "Error log has $error_count entries"
            else
                log "PASS" "No errors in error log"
            fi
        fi
        
        add_result "logs" "PASS"
    else
        log "WARN" "$test_name: Log file not found at $log_file"
        add_result "logs" "WARN"
    fi
}

# Check configuration
check_configuration() {
    local test_name="Configuration"
    local found_config=false
    
    # Check for YAML config files
    for config_file in "$VELOCIRAPTOR_HOME"/*.yaml "$VELOCIRAPTOR_HOME"/*.yml; do
        if [[ -f "$config_file" ]]; then
            log "PASS" "Configuration found: $(basename "$config_file")"
            found_config=true
            
            # Basic syntax check if python3 is available
            if command -v python3 &> /dev/null; then
                if python3 -c "import yaml; yaml.safe_load(open('$config_file'))" 2>/dev/null; then
                    log "PASS" "Configuration syntax is valid"
                else
                    log "WARN" "Configuration syntax may have issues"
                fi
            fi
        fi
    done
    
    if [[ "$found_config" == true ]]; then
        add_result "configuration" "PASS"
    else
        log "WARN" "$test_name: No configuration files found"
        add_result "configuration" "WARN"
    fi
}

# Generate health report
generate_report() {
    echo
    log "INFO" "==== Health Check Summary ===="
    
    local total_checks=0
    local passed_checks=0
    local failed_checks=0
    local warning_checks=0
    
    # Process all results
    for key in $(get_all_keys); do
        local status=$(get_result "$key")
        local check_name=$(echo "$key" | tr '_' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
        
        case "$status" in
            "PASS")
                log "PASS" "$check_name"
                ((passed_checks++))
                ;;
            "FAIL")
                log "FAIL" "$check_name"
                ((failed_checks++))
                ;;
            "WARN")
                log "WARN" "$check_name"
                ((warning_checks++))
                ;;
        esac
        ((total_checks++))
    done
    
    echo
    log "INFO" "Results: $passed_checks passed, $warning_checks warnings, $failed_checks failed"
    
    # Overall status
    if [[ "$failed_checks" -eq 0 ]]; then
        if [[ "$warning_checks" -eq 0 ]]; then
            log "PASS" "Overall Status: HEALTHY"
            return 0
        else
            log "WARN" "Overall Status: HEALTHY (with warnings)"
            return 1
        fi
    else
        log "FAIL" "Overall Status: UNHEALTHY"
        return 2
    fi
}

# Show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Perform health checks on Velociraptor macOS installation

OPTIONS:
    --verbose       Show detailed output
    --json          Output results in JSON format
    --help          Show this help message

EXAMPLES:
    $0              # Run standard health checks
    $0 --verbose    # Run with detailed output
    $0 --json       # Output JSON results
EOF
}

# Main function
main() {
    local verbose=false
    local json_output=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose)
                verbose=true
                shift
                ;;
            --json)
                json_output=true
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
    
    if [[ "$json_output" != true ]]; then
        log "INFO" "==== Velociraptor macOS Health Check ===="
    fi
    
    # Run health checks
    check_binary
    check_directories
    check_process
    check_network
    check_disk_space
    check_system_resources
    check_logs
    check_configuration
    
    # Generate output
    if [[ "$json_output" == true ]]; then
        # Output JSON
        echo "{"
        echo "  \"timestamp\": \"$(date -Iseconds)\","
        echo "  \"checks\": {"
        local first=true
        for key in $(get_all_keys); do
            [[ "$first" == false ]] && echo ","
            echo -n "    \"$key\": \"$(get_result "$key")\""
            first=false
        done
        echo
        echo "  }"
        echo "}"
    else
        # Generate standard report
        generate_report
    fi
}

# Run main function
main "$@"