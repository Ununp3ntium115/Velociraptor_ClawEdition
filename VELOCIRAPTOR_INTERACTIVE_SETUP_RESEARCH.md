# Velociraptor Interactive Setup Process - Comprehensive Research

## Overview

This document provides comprehensive research on Velociraptor's built-in interactive setup process (`velociraptor.exe -i`) to support the development of a comprehensive GUI wrapper that covers ALL Velociraptor configuration options.

## Table of Contents

1. [Interactive Setup Process](#interactive-setup-process)
2. [Configuration Parameters](#configuration-parameters)
3. [Command Structure](#command-structure)
4. [YAML Configuration](#yaml-configuration)
5. [Current GUI Implementation Analysis](#current-gui-implementation-analysis)
6. [Recommendations for Comprehensive GUI](#recommendations-for-comprehensive-gui)

## Interactive Setup Process

### What happens when you run `velociraptor.exe -i`

The interactive setup is launched using:
```bash
./velociraptor config generate -i
```

This launches an interactive configuration generator wizard that follows a question/answer dialogue-style process to gather the most important details needed to produce a complete configuration.

### Interactive Configuration Wizard Steps

The wizard presents the following configuration options in sequence:

1. **Operating System Selection**
   - Prompts: "What OS will the server be deployed on?"
   - Options: linux, windows, etc.
   - Default: Detected automatically

2. **Datastore Directory Configuration**
   - Prompts: "Path to the datastore directory"
   - Example: `/opt/velociraptor`
   - Purpose: Where Velociraptor stores its data files

3. **SSL Configuration**
   - Prompts: "Deployment Type Selection"
   - Default recommended: "Self Signed SSL"
   - Options: Self-signed, Let's Encrypt, Custom certificates

4. **Public DNS/IP Configuration**
   - Prompts: "What is the public DNS name of the Master Frontend?"
   - Purpose: IP address or DNS name that clients will use to connect
   - Critical for client-server communication

5. **Network Port Configuration**
   - Frontend Port: Default 8000 (client connections)
   - GUI Port: Default 8889 (web interface)
   - Customizable based on network requirements

6. **Admin User Creation**
   - Prompts: "Adding Admin User Number 0"
   - Username input (e.g., "admin")
   - Password input
   - Note: Additional users can be added post-installation

7. **Logs Directory**
   - Prompts: "Path to the logs directory"
   - Example: `/opt/velociraptor/logs`
   - Purpose: Where log files are stored

8. **Configuration File Location**
   - Prompts: "Where to write the server config file"
   - Example: `/root/server.config.yaml`
   - Output location for generated configuration

### Encryption and Certificate Handling

The interactive setup handles:
- **CA Certificate Generation**: Creates internal Velociraptor CA
- **Client-Server Encryption**: Establishes cryptographic material
- **Certificate Management**: Self-signed or custom certificate configuration
- **Crypto Options**: Specifies cryptographic options in configuration

### Network Configuration Options

The wizard configures:
- **Frontend Binding**: Default `127.0.0.1` (localhost)
- **GUI Binding**: Default `127.0.0.1` (localhost)
- **Production Recommendation**: Change to `0.0.0.0` for network accessibility
- **Port Configuration**: Frontend (8000), GUI (8889), API ports
- **Proxy Support**: Client proxy configurations

## Configuration Parameters

### Server Settings (Addresses, Ports, Protocols)

**Frontend Configuration:**
- `Frontend.bind_address`: Server binding address (default: 127.0.0.1)
- `Frontend.bind_port`: Client connection port (default: 8000)
- `Frontend.max_upload_size`: Maximum file upload size
- `Frontend.concurrency`: Number of concurrent client connections
- `Frontend.resources.connections`: gRPC connection pool size
- `Frontend.proxy_header`: Proxy forwarding headers

**GUI Configuration:**
- `GUI.bind_address`: Web interface binding address (default: 127.0.0.1)
- `GUI.bind_port`: Web interface port (default: 8889)
- `GUI.public_url`: Public URL for GUI access
- `GUI.use_plain_http`: HTTP vs HTTPS configuration

### Security Settings (Encryption, Certificates, Authentication)

**Authentication Methods:**
- `GUI.authenticator.type`: Authentication type
  - Options: basic, google, azure, oidc-cognito, github, saml, oidc, multi
- `GUI.authenticator.basic_auth_users`: User credentials for basic auth
- `GUI.authenticator.google_oauth_client_id`: Google OAuth configuration
- `GUI.authenticator.azure_tenant`: Azure AD configuration
- `GUI.authenticator.saml_*`: SAML configuration options

**Certificate Management:**
- `Client.ca_certificate`: CA certificate for client validation
- `CA.private_key`: Internal CA private key
- `Frontend.certificate`: Server certificate path
- `Frontend.private_key`: Server private key path
- `Frontend.dyn_dns`: Dynamic DNS configuration

**Encryption Options:**
- `Client.crypto_type`: Client encryption type
- `Client.server_urls`: List of server URLs for client connections
- `Client.server_name`: Server name for certificate validation
- `Client.writeback_darwin`: Client writeback file locations

### Database Settings

**Datastore Configuration:**
- `Datastore.implementation`: Storage engine type (FileBaseDataStore)
- `Datastore.location`: Primary datastore directory
- `Datastore.filestore_directory`: Large file storage location
- `Datastore.memcache_size`: Memory cache size before disk flush

**Performance Settings:**
- `Datastore.mysql_*`: MySQL configuration options
- `Datastore.postgres_*`: PostgreSQL configuration options
- `Datastore.cache_*`: Caching configuration

### Logging Configuration

**Log Management:**
- `Logging.output_directory`: Log file directory
- `Logging.separate_logs_per_component`: Component-specific log files
- `Logging.max_age`: Log retention period
- `Logging.rotation_time`: Log rotation interval

**Remote Logging:**
- `Logging.remote_syslog_address`: Syslog server address
- `Logging.remote_syslog_protocol`: Protocol (udp/tcp)
- `Logging.remote_syslog_components`: Components to forward

### Client Settings and Enrollment

**Client Configuration:**
- `Client.server_urls`: List of server endpoints
- `Client.ca_certificate`: Server CA certificate
- `Client.nonce`: Client authentication nonce
- `Client.writeback_*`: Platform-specific writeback files
- `Client.max_poll`: Maximum polling interval
- `Client.max_poll_std`: Polling standard deviation

**Enrollment Settings:**
- `Client.use_self_signed_ssl`: Self-signed certificate acceptance
- `Client.pinned_server_name`: Certificate pinning
- `Client.proxy`: Proxy configuration for clients

### Web Interface Configuration

**GUI Customization:**
- `GUI.links`: Custom navigation links
- `GUI.artifacts.max_download_size`: Artifact download limits
- `GUI.session_timeout`: User session timeout
- `GUI.auth_redirect_template`: Authentication redirect page

**Resource Limits:**
- `GUI.max_upload_size`: Upload size limits
- `GUI.concurrent_uploads`: Concurrent upload limits
- `GUI.hunt_manager.max_table_size`: GUI table size limits

### Package Management Integration

**Artifact Management:**
- `autoexec`: Commands to run at startup
- `Server.default_server_config`: Default server configurations
- `Server.default_client_config`: Default client configurations

**Tool Integration:**
- Built-in support for artifact pack processing
- Tool dependency management
- Offline collector packaging

## Command Structure

### Complete Command-Line Options for Velociraptor Configuration

**Basic Help:**
```bash
./velociraptor -h                    # Basic help
./velociraptor --help-long          # Extended help
./velociraptor [command] -h         # Command-specific help
```

### `config generate` Options and Parameters

**Interactive Mode:**
```bash
./velociraptor config generate -i   # Interactive configuration wizard
```

**Non-Interactive Mode:**
```bash
./velociraptor config generate      # Generate with defaults
```

**JSON Merge Configuration:**
```bash
./velociraptor config generate --merge '{"autocert_domain": "domain.com"}' > server.config.yaml
```

### `user add` Options for Creating Admin Accounts

**Add User Command:**
```bash
./velociraptor --config server.config.yaml user add [username] --role=[role]
```

**Examples:**
```bash
./velociraptor --config server.config.yaml user add jose --role=administrator
./velociraptor --config server.config.yaml user add analyst --role=reader
```

**ACL Management:**
```bash
./velociraptor acl grant [username] [permission]
./velociraptor acl show [username]
```

### `package` Commands for Artifact Management

**Client Package Generation:**
```bash
# Windows MSI Generation
./velociraptor config repack --msi velociraptor-v0.73.1-windows-amd64.msi client.config.yaml output.msi

# Windows EXE Repacking
./velociraptor config repack --exe velociraptor-v0.73.1-windows-amd64.exe client.config.yaml output.exe

# Linux Debian Package
./velociraptor --config server.config.yaml debian server --binary velociraptor-v0.6.0-linux-amd64
./velociraptor -c /etc/velociraptor/client.config.yaml debian client

# Service Package Generation
./velociraptor --config server.config.yaml service install --name VelociraptorServer
```

### Service Installation Options

**Windows Service Installation:**
```bash
# Install as Windows Service
./velociraptor.exe service install --config client.config.yaml

# Service Management
./velociraptor.exe service start
./velociraptor.exe service stop
./velociraptor.exe service remove
```

**Linux Service Management:**
```bash
# SystemD service installation
./velociraptor --config server.config.yaml debian server
systemctl enable velociraptor
systemctl start velociraptor
```

**macOS Service Installation:**
```bash
./velociraptor service install --config client.config.yaml
```

## YAML Configuration

### Complete server.config.yaml Structure

The Velociraptor configuration file follows this hierarchical structure:

```yaml
# Version Information
version:
  name: velociraptor
  version: "0.73.1"
  built_time: "2024-01-01T00:00:00Z"

# Client Configuration Block
Client:
  server_urls:
    - https://velociraptor.example.com:8000/
  ca_certificate: |
    -----BEGIN CERTIFICATE-----
    [CA Certificate Content]
    -----END CERTIFICATE-----
  nonce: "random_nonce_string"
  writeback_darwin: /etc/velociraptor.writeback.yaml
  writeback_linux: /etc/velociraptor.writeback.yaml
  writeback_windows: $ProgramFiles\\Velociraptor\\velociraptor.writeback.yaml
  max_poll: 600
  max_poll_std: 30
  use_self_signed_ssl: true
  crypto_type: "OpenSSL"

# API Server Configuration
API:
  bind_address: 127.0.0.1
  bind_port: 8001
  bind_scheme: tcp
  pinned_gw_name: "GRPC_GW"

# GUI Web Interface Configuration
GUI:
  bind_address: 127.0.0.1
  bind_port: 8889
  use_plain_http: false
  
  # Authentication Configuration
  authenticator:
    type: basic
    basic_auth_users:
      - name: admin
        password_hash: "$2a$10$..."
        role: administrator
    
    # OAuth Configurations
    google_oauth_client_id: ""
    google_oauth_client_secret: ""
    
    # Azure AD Configuration
    azure_tenant: ""
    azure_app_id: ""
    azure_app_secret: ""
    
    # SAML Configuration
    saml_certificate: ""
    saml_private_key: ""
    saml_idp_metadata_url: ""
    saml_root_url: ""
    saml_user_attribute: "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
    saml_roles_attribute: "http://schemas.microsoft.com/ws/2008/06/identity/claims/groups"

  # Session Management
  session_timeout: 600
  
  # Custom Links
  links:
    - text: "Documentation"
      url: "https://docs.velociraptor.app/"
    - text: "GitHub"
      url: "https://github.com/Velocidex/velociraptor"

# Frontend Server Configuration
Frontend:
  bind_address: 127.0.0.1
  bind_port: 8000
  certificate: /etc/velociraptor/server.pem
  private_key: /etc/velociraptor/server.key
  
  # Resource Management
  resources:
    max_upload_size: 104857600  # 100MB
    connections: 2
    max_concurrent_uploads: 10
  
  # Performance Settings
  concurrency: 2
  
  # Dynamic DNS Configuration
  dyn_dns:
    type: "noip"
    hostname: "myserver.ddns.net"
    username: "ddns_user"
    password: "ddns_password"
    
  # Client Certificate Verification
  tls_certificate_verification: REQUIRE_AND_VERIFY_CLIENT_CERT

# Datastore Configuration
Datastore:
  implementation: FileBaseDataStore
  location: /opt/velociraptor
  filestore_directory: /opt/velociraptor
  
  # Memory Management
  memcache_size: 100000000  # 100MB
  
  # MySQL Configuration (alternative)
  mysql_connection_string: ""
  mysql_database: ""
  mysql_username: ""
  mysql_password: ""
  
  # Performance Tuning
  vacuum_frequency: 86400  # 24 hours
  
# Logging Configuration
Logging:
  output_directory: /var/log/velociraptor
  separate_logs_per_component: true
  max_age: 168h  # 7 days
  rotation_time: 24h
  
  # Remote Syslog
  remote_syslog_address: "syslog.example.com:514"
  remote_syslog_protocol: udp
  remote_syslog_components:
    - VelociraptorAudit
    - VelociraptorLogs

# Monitoring Configuration
Monitoring:
  bind_address: 127.0.0.1
  bind_port: 8003

# Server Defaults
defaults:
  hunt_manager:
    max_hunt_results: 1000000
  notebook:
    default_timeout: 600
  event_max_wait: 120
  
# AutoExec Commands
autoexec:
  argv:
    - "frontend"
    - "-v"

# Organization Configuration (Multi-tenant)
Organizations:
  - name: "DefaultOrg"
    id: "O123456789"

# CA Configuration (Internal - Do Not Edit)
CA:
  private_key: |
    -----BEGIN RSA PRIVATE KEY-----
    [Private Key Content]
    -----END RSA PRIVATE KEY-----
```

### Required vs Optional Parameters

**Required Parameters:**
- `Client.server_urls`: Essential for client communication
- `Client.ca_certificate`: Required for SSL verification
- `Frontend.bind_address` and `Frontend.bind_port`: Server connectivity
- `GUI.bind_address` and `GUI.bind_port`: Web interface access
- `Datastore.implementation` and `Datastore.location`: Data storage
- `GUI.authenticator`: User authentication configuration

**Optional Parameters:**
- `Logging.*`: Can use default logging if not specified
- `Monitoring.*`: Performance monitoring (optional)
- `Organizations.*`: Only needed for multi-tenant deployments
- `Frontend.dyn_dns.*`: Only for dynamic DNS environments
- OAuth configurations: Only if using external authentication

### Security Best Practices for Configuration

1. **Certificate Management:**
   - Use strong CA certificates
   - Regularly rotate certificates
   - Implement certificate pinning for clients

2. **Authentication Security:**
   - Use strong password hashes
   - Implement multi-factor authentication where possible
   - Use OAuth/SAML for enterprise environments

3. **Network Security:**
   - Bind to specific interfaces, not 0.0.0.0 unless necessary
   - Use non-default ports for additional security
   - Implement proper firewall rules

4. **Data Protection:**
   - Secure datastore location with appropriate permissions
   - Implement regular backups
   - Use disk encryption for sensitive data

5. **Logging Security:**
   - Secure log directories
   - Implement log forwarding to SIEM
   - Regular log rotation and archival

## Current GUI Implementation Analysis

### Existing GUI Coverage

Based on analysis of `VelociraptorGUI-InstallClean.ps1`, the current GUI implementation covers:

**Current Features:**
- Basic installation directory configuration
- Data directory configuration
- Real-time path validation with visual feedback
- Download and installation of Velociraptor binary
- Launch functionality with default parameters
- Emergency deployment mode
- Comprehensive logging and error handling

**Current Limitations:**
- No interactive configuration wizard equivalent
- Limited to basic installation paths
- No SSL/certificate configuration
- No authentication setup
- No network port configuration
- No advanced datastore options
- No logging configuration
- No client configuration generation
- No service installation options
- No user management
- No multi-tenant organization setup

### Missing Comprehensive Configuration Options

The current GUI lacks coverage for:

1. **Interactive Configuration Wizard**
2. **SSL and Certificate Management**
3. **Authentication Configuration**
4. **Network and Port Settings**
5. **Advanced Datastore Options**
6. **Logging Configuration**
7. **Client Configuration Generation**
8. **Service Installation and Management**
9. **User and Role Management**
10. **Multi-tenant Organization Setup**
11. **Package Creation and Management**
12. **Monitoring and Performance Settings**

## Recommendations for Comprehensive GUI

### Proposed GUI Architecture

Create a multi-tab or wizard-based interface that covers all configuration aspects:

#### Tab 1: Basic Configuration
- Installation directories (current functionality)
- Operating system detection
- Basic server information

#### Tab 2: Network Configuration
- Server addresses and ports
- Frontend configuration
- GUI configuration
- DNS and proxy settings

#### Tab 3: Security & Authentication
- SSL certificate configuration (self-signed vs custom)
- Authentication method selection
- User account creation
- Role and permission management

#### Tab 4: Storage & Database
- Datastore configuration
- Memory cache settings
- Database options (MySQL, PostgreSQL)
- File storage locations

#### Tab 5: Logging & Monitoring
- Log directory configuration
- Remote syslog settings
- Monitoring configuration
- Performance settings

#### Tab 6: Client Configuration
- Client configuration generation
- Package creation (MSI, EXE, DEB, RPM)
- Service installation options
- Deployment strategies

#### Tab 7: Advanced Settings
- Multi-tenant organization setup
- Custom artifact configuration
- Performance tuning
- Advanced security options

### Implementation Strategy

1. **Modular Design:** Each configuration section as separate PowerShell functions
2. **Real-time Validation:** Immediate feedback for configuration changes
3. **Configuration Preview:** Show generated YAML before applying
4. **Guided Wizards:** Step-by-step guidance for complex configurations
5. **Import/Export:** Load and save configuration templates
6. **Integration Testing:** Built-in configuration validation
7. **Documentation Links:** Context-sensitive help for each option

### Technical Requirements

**PowerShell Modules Needed:**
- Enhanced Windows Forms components
- YAML processing capabilities
- Certificate management functions
- Network validation utilities
- Service management functions
- Package creation utilities

**External Dependencies:**
- OpenSSL for certificate operations
- WiX Toolset for MSI creation
- Platform-specific package managers

### Security Considerations

**Configuration Security:**
- Secure storage of sensitive configuration data
- Encryption of configuration files containing secrets
- Validation of user inputs to prevent injection attacks
- Secure default configurations

**Deployment Security:**
- Code signing for generated packages
- Secure distribution of client packages
- Certificate validation and management
- Audit logging of configuration changes

This comprehensive research provides the foundation for creating a full-featured GUI that replaces Velociraptor's command-line interactive process with a complete Windows Forms interface covering ALL configuration options.

---

*Research completed: 2025-08-21*
*Source: Official Velociraptor documentation and community resources*