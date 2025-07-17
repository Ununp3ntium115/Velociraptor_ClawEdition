#!/bin/bash
# Velociraptor Docker Health Check Script

set -euo pipefail

# Configuration
VELOCIRAPTOR_CONFIG_DIR="/opt/velociraptor/config"
CONFIG_FILE="$VELOCIRAPTOR_CONFIG_DIR/server.config.yaml"
TIMEOUT=10

# Logging function
log() {
    echo "[HEALTHCHECK] $*" >&2
}

# Main health check function
perform_health_check() {
    local exit_code=0
    
    # Check if configuration file exists
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "ERROR: Configuration file not found: $CONFIG_FILE"
        return 1
    fi
    
    # Get GUI port from configuration
    local gui_port
    gui_port=$(pwsh -Command "
        try {
            \$config = Get-Content '$CONFIG_FILE' | ConvertFrom-Yaml
            Write-Output \$config.GUI.bind_port
        } catch {
            Write-Output '8889'
        }
    " 2>/dev/null || echo "8889")
    
    # Check GUI endpoint
    if ! curl -f -s --max-time "$TIMEOUT" "http://localhost:$gui_port/api/v1/GetVersion" >/dev/null 2>&1; then
        log "ERROR: GUI endpoint not responding on port $gui_port"
        exit_code=1
    else
        log "GUI endpoint healthy on port $gui_port"
    fi
    
    # Check API endpoint if different from GUI
    local api_port
    api_port=$(pwsh -Command "
        try {
            \$config = Get-Content '$CONFIG_FILE' | ConvertFrom-Yaml
            if (\$config.API -and \$config.API.bind_port -ne \$config.GUI.bind_port) {
                Write-Output \$config.API.bind_port
            }
        } catch {
            # Ignore errors
        }
    " 2>/dev/null || echo "")
    
    if [[ -n "$api_port" ]]; then
        if ! curl -f -s --max-time "$TIMEOUT" "http://localhost:$api_port/api/v1/GetVersion" >/dev/null 2>&1; then
            log "WARNING: API endpoint not responding on port $api_port"
            # Don't fail health check for API endpoint issues
        else
            log "API endpoint healthy on port $api_port"
        fi
    fi
    
    # Check data directory accessibility
    local data_dir="/opt/velociraptor/data"
    if [[ ! -d "$data_dir" ]] || [[ ! -w "$data_dir" ]]; then
        log "ERROR: Data directory not accessible: $data_dir"
        exit_code=1
    else
        log "Data directory accessible: $data_dir"
    fi
    
    # Check log directory accessibility
    local log_dir="/opt/velociraptor/logs"
    if [[ ! -d "$log_dir" ]] || [[ ! -w "$log_dir" ]]; then
        log "ERROR: Log directory not accessible: $log_dir"
        exit_code=1
    else
        log "Log directory accessible: $log_dir"
    fi
    
    # Overall health status
    if [[ $exit_code -eq 0 ]]; then
        log "Health check PASSED"
    else
        log "Health check FAILED"
    fi
    
    return $exit_code
}

# Execute health check
perform_health_check