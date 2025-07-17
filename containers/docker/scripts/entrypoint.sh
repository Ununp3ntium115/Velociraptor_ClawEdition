#!/bin/bash
set -euo pipefail

# Velociraptor Docker Container Entrypoint Script
# Handles initialization, configuration, and startup

# Configuration
VELOCIRAPTOR_CONFIG_DIR="/opt/velociraptor/config"
VELOCIRAPTOR_DATA_DIR="/opt/velociraptor/data"
VELOCIRAPTOR_LOG_DIR="/opt/velociraptor/logs"
VELOCIRAPTOR_BIN_DIR="/opt/velociraptor/bin"
VELOCIRAPTOR_BINARY="$VELOCIRAPTOR_BIN_DIR/velociraptor"
CONFIG_FILE="$VELOCIRAPTOR_CONFIG_DIR/server.config.yaml"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Error handling
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Signal handlers for graceful shutdown
shutdown_handler() {
    log "Received shutdown signal, stopping Velociraptor..."
    if [[ -n "${VELOCIRAPTOR_PID:-}" ]]; then
        kill -TERM "$VELOCIRAPTOR_PID" 2>/dev/null || true
        wait "$VELOCIRAPTOR_PID" 2>/dev/null || true
    fi
    log "Velociraptor stopped gracefully"
    exit 0
}

trap shutdown_handler SIGTERM SIGINT

# Initialize container environment
initialize_container() {
    log "Initializing Velociraptor container..."
    
    # Create necessary directories
    mkdir -p "$VELOCIRAPTOR_CONFIG_DIR" "$VELOCIRAPTOR_DATA_DIR" "$VELOCIRAPTOR_LOG_DIR" "$VELOCIRAPTOR_BIN_DIR"
    
    # Download Velociraptor binary if not present
    if [[ ! -f "$VELOCIRAPTOR_BINARY" ]]; then
        log "Downloading Velociraptor binary..."
        download_velociraptor
    fi
    
    # Make binary executable
    chmod +x "$VELOCIRAPTOR_BINARY"
    
    # Generate configuration if not present
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "Generating Velociraptor configuration..."
        generate_configuration
    fi
    
    # Validate configuration
    log "Validating configuration..."
    validate_configuration
    
    log "Container initialization completed"
}

# Download Velociraptor binary
download_velociraptor() {
    local download_url
    local temp_file="/tmp/velociraptor.zip"
    
    # Get latest release URL
    download_url=$(curl -s https://api.github.com/repos/Velocidex/velociraptor/releases/latest | \
                   jq -r '.assets[] | select(.name | contains("linux-amd64")) | .browser_download_url')
    
    if [[ -z "$download_url" || "$download_url" == "null" ]]; then
        error_exit "Failed to get Velociraptor download URL"
    fi
    
    log "Downloading from: $download_url"
    
    # Download with retry logic
    local retry_count=0
    local max_retries=3
    
    while [[ $retry_count -lt $max_retries ]]; do
        if curl -L -o "$temp_file" "$download_url"; then
            break
        fi
        
        retry_count=$((retry_count + 1))
        log "Download attempt $retry_count failed, retrying..."
        sleep 5
    done
    
    if [[ $retry_count -eq $max_retries ]]; then
        error_exit "Failed to download Velociraptor after $max_retries attempts"
    fi
    
    # Extract binary
    unzip -j "$temp_file" -d "$VELOCIRAPTOR_BIN_DIR"
    rm -f "$temp_file"
    
    log "Velociraptor binary downloaded successfully"
}

# Generate Velociraptor configuration
generate_configuration() {
    local temp_config="/tmp/temp_config.yaml"
    
    # Use PowerShell script to generate configuration
    pwsh -Command "
        Import-Module '/opt/velociraptor/scripts/modules/VelociraptorDeployment' -Force
        New-VelociraptorConfigurationTemplate -TemplateType Server -OutputPath '$temp_config' -Environment Container
    " || error_exit "Failed to generate configuration template"
    
    # Customize configuration for container environment
    customize_container_config "$temp_config"
    
    # Move to final location
    mv "$temp_config" "$CONFIG_FILE"
    
    log "Configuration generated: $CONFIG_FILE"
}

# Customize configuration for container environment
customize_container_config() {
    local config_file="$1"
    
    # Use environment variables to customize configuration
    local gui_bind_address="${VELOCIRAPTOR_GUI_BIND_ADDRESS:-0.0.0.0}"
    local gui_bind_port="${VELOCIRAPTOR_GUI_BIND_PORT:-8889}"
    local api_bind_address="${VELOCIRAPTOR_API_BIND_ADDRESS:-0.0.0.0}"
    local api_bind_port="${VELOCIRAPTOR_API_BIND_PORT:-8000}"
    local frontend_bind_port="${VELOCIRAPTOR_FRONTEND_BIND_PORT:-8080}"
    
    # Update configuration using PowerShell
    pwsh -Command "
        \$config = Get-Content '$config_file' | ConvertFrom-Yaml
        \$config.GUI.bind_address = '$gui_bind_address'
        \$config.GUI.bind_port = $gui_bind_port
        \$config.API.bind_address = '$api_bind_address'
        \$config.API.bind_port = $api_bind_port
        \$config.Frontend.bind_port = $frontend_bind_port
        \$config.Datastore.location = '$VELOCIRAPTOR_DATA_DIR'
        \$config.Logging.output_directory = '$VELOCIRAPTOR_LOG_DIR'
        \$config | ConvertTo-Yaml | Set-Content '$config_file'
    " || error_exit "Failed to customize configuration"
    
    log "Configuration customized for container environment"
}

# Validate configuration
validate_configuration() {
    if ! pwsh -Command "
        Import-Module '/opt/velociraptor/scripts/modules/VelociraptorDeployment' -Force
        Test-VelociraptorConfiguration -ConfigPath '$CONFIG_FILE'
    "; then
        error_exit "Configuration validation failed"
    fi
    
    log "Configuration validation passed"
}

# Start Velociraptor server
start_velociraptor() {
    log "Starting Velociraptor server..."
    log "Configuration: $CONFIG_FILE"
    log "Data directory: $VELOCIRAPTOR_DATA_DIR"
    log "Log directory: $VELOCIRAPTOR_LOG_DIR"
    
    # Start Velociraptor in background
    "$VELOCIRAPTOR_BINARY" --config "$CONFIG_FILE" frontend &
    VELOCIRAPTOR_PID=$!
    
    log "Velociraptor server started with PID: $VELOCIRAPTOR_PID"
    
    # Wait for process to exit
    wait "$VELOCIRAPTOR_PID"
    local exit_code=$?
    
    log "Velociraptor server exited with code: $exit_code"
    exit $exit_code
}

# Health check function
health_check() {
    local config_file="${1:-$CONFIG_FILE}"
    
    if [[ ! -f "$config_file" ]]; then
        return 1
    fi
    
    # Check if Velociraptor process is running
    if [[ -n "${VELOCIRAPTOR_PID:-}" ]] && kill -0 "$VELOCIRAPTOR_PID" 2>/dev/null; then
        # Check if GUI port is responding
        local gui_port
        gui_port=$(pwsh -Command "
            \$config = Get-Content '$config_file' | ConvertFrom-Yaml
            Write-Output \$config.GUI.bind_port
        " 2>/dev/null)
        
        if [[ -n "$gui_port" ]]; then
            if curl -f -s "http://localhost:$gui_port/api/v1/GetVersion" >/dev/null 2>&1; then
                return 0
            fi
        fi
    fi
    
    return 1
}

# Main execution
main() {
    log "Starting Velociraptor Docker container..."
    
    # Handle special commands
    case "${1:-}" in
        "health-check")
            if health_check; then
                log "Health check passed"
                exit 0
            else
                log "Health check failed"
                exit 1
            fi
            ;;
        "config-only")
            initialize_container
            log "Configuration generated, exiting"
            exit 0
            ;;
        "shell")
            log "Starting interactive shell"
            exec /bin/bash
            ;;
        *)
            # Normal startup
            initialize_container
            start_velociraptor
            ;;
    esac
}

# Execute main function
main "$@"