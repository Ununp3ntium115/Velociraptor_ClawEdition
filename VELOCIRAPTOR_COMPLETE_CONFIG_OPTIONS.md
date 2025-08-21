# Velociraptor Complete Configuration Options Reference

## Overview
This document provides a comprehensive reference of ALL configuration options available in the `velociraptor.exe config generate -i` interactive setup wizard. Use this to ensure your GUI covers 100% of the interactive setup functionality.

---

## 1. DEPLOYMENT TYPE SELECTION

### Available Deployment Types:
1. **Self-Signed SSL** (default for testing/incident response)
2. **Automatically provision certificates with Let's Encrypt**
3. **Authenticate users with SSO** (SAML/OAuth integration)

---

## 2. AUTHENTICATION METHODS

### Authenticator Types:
- `basic` - Traditional username/password authentication
- `google` - Google OAuth2 provider
- `azure` - Microsoft Azure OAuth2 provider  
- `github` - GitHub OAuth2 provider
- `oidc` - OpenID Connect (generic OIDC provider)
- `oidc-cognito` - Amazon Cognito OIDC
- `saml` - SAML authentication
- `multi` - Multiple authentication methods combined

### Authentication Configuration Parameters:
- **Basic Auth**: Username and password creation for admin user
- **OAuth2 Config**: Client ID, Client Secret, OAuth endpoint URLs
- **OIDC Config**: OIDC issuer URL, discovery endpoint configuration
- **SAML Config**: Identity Provider metadata, certificate configuration
- **Multi-Factor**: Additional security layer configuration

---

## 3. CERTIFICATE MANAGEMENT

### Certificate Types:
1. **Self-Signed Certificates**
   - Internal CA generation
   - Certificate expiration periods (1, 5, 10 years, or custom)
   - X.509 certificate configuration

2. **Let's Encrypt Certificates**
   - Automatic certificate provisioning
   - Domain validation configuration
   - Auto-renewal settings (90-day cycle)

3. **Custom/Corporate Certificates**
   - Upload existing certificates
   - Certificate chain configuration
   - Private key management

### Certificate Configuration Options:
- **Internal PKI Certificate Expiration**: 1 year (default), 5 years, 10 years, custom duration
- **CA Certificate Configuration**: Root CA setup for internal PKI
- **Certificate Rotation**: Key rotation scheduling and policies
- **TLS Configuration**: Cipher suites, protocol versions

---

## 4. NETWORK CONFIGURATION

### Frontend Configuration:
- **Public DNS Name/IP**: External hostname for client connections
- **Frontend Port**: Default 8000, customizable
- **Bind Address**: 127.0.0.1 (localhost) or 0.0.0.0 (all interfaces)
- **Client Connection Limits**: Max concurrent connections
- **Proxy Configuration**: Reverse proxy support settings

### GUI Configuration:
- **GUI Port**: Default 8889, customizable
- **GUI Bind Address**: 
  - 127.0.0.1 (localhost only) for self-signed SSL
  - 0.0.0.0 (all interfaces) for Let's Encrypt deployments
- **GUI Access Controls**: IP CIDR restrictions (`GUI.allowed_cidr`)

### Advanced Network Options:
- **Resource Limitations**: Connection throttling, enrollment rate limits
- **Dynamic DNS Support**: Automatic DNS updates
- **Network Polling Parameters**: Client check-in intervals

---

## 5. STORAGE AND DATA CONFIGURATION

### Datastore Options:
- **Datastore Path**: Directory for Velociraptor file storage
- **File-based Storage**: Default storage backend
- **Memcache Implementation**: Caching strategies
- **Disk Space Monitoring**: Storage usage alerts
- **Write Caching**: Performance optimization settings

### Backup and Recovery:
- **Data Backup Configuration**: Automatic backup scheduling
- **Recovery Options**: Disaster recovery settings
- **Retention Policies**: Data retention and archival

---

## 6. SECURITY CONFIGURATION

### Access Control:
- **Role-Based Access Control (RBAC)**: User role definitions
- **Permission Levels**: Read, Write, Execute permissions
- **Artifact-Level Permissions**: Granular access control
- **VQL Plugin Restrictions**: (`defaults.allowed_plugins`)

### Encryption Settings:
- **Two-Layer Encryption**: TLS + internal message encryption
- **Mutual TLS (mTLS)**: Client certificate authentication (`Frontend.require_client_certificates`)
- **Custom CA Certificates**: Additional root certificates (`Client.Crypto.root_certs`)

### Security Policies:
- **Lockdown Mode**: Prevent modification permissions (`lockdown`)
- **Audit Configuration**: User action logging
- **Password Policies**: Complexity requirements, expiration
- **Session Management**: Timeout settings, concurrent sessions

---

## 7. SSO INTEGRATION OPTIONS

### OAuth2 Configuration:
- **Google OAuth2**:
  - Client ID and Secret
  - Authorized domains
  - User attribute mapping

- **Azure/Microsoft OAuth2**:
  - Application ID
  - Tenant configuration
  - Directory integration

- **GitHub OAuth2**:
  - Application credentials
  - Organization restrictions

### SAML Configuration:
- **Identity Provider (IdP) Settings**:
  - IdP metadata URL/file
  - Certificate configuration
  - Attribute mapping

- **Service Provider (SP) Settings**:
  - SP metadata generation
  - ACS URL configuration
  - NameID format

### OIDC Configuration:
- **OIDC Issuer URL**: Discovery endpoint
- **Client Configuration**: Client ID, secret, scopes
- **User Claims**: Email, groups, custom attributes

---

## 8. DNS SERVER CONFIGURATION

### DNS Options:
- **Custom DNS Servers**: Override system DNS
- **Cloudflare DNS**: Use 1.1.1.1, 1.0.0.1
- **Google DNS**: Use 8.8.8.8, 8.8.4.4
- **Corporate DNS**: Internal DNS server configuration
- **DNS-over-HTTPS**: Secure DNS resolution

---

## 9. MONITORING AND LOGGING

### Monitoring Configuration:
- **Prometheus Metrics**: Metrics endpoint configuration
- **Health Checks**: Server health monitoring
- **Performance Metrics**: Resource usage tracking

### Logging Options:
- **Log Levels**: Debug, Info, Warning, Error
- **Log Rotation**: File size and retention policies
- **Remote Logging**: Syslog forwarding, centralized logging
- **Component-Specific Logging**: Frontend, GUI, client logging

---

## 10. OPERATING SYSTEM SPECIFIC SETTINGS

### Platform Configuration:
- **Windows Deployment**:
  - Service installation options
  - Windows-specific paths
  - Registry configuration

- **Linux Deployment**:
  - Systemd service configuration
  - Linux-specific paths
  - User/group settings

- **Cross-Platform Settings**:
  - Path normalization
  - File permissions
  - Process management

---

## 11. ADVANCED CONFIGURATION OPTIONS

### Multi-Organization Support:
- **Organization Isolation**: Data separation
- **Cross-Organization Policies**: Shared resources
- **Organization-Specific Authentication**: Separate auth methods

### High Availability:
- **Load Balancing**: Multiple server instances
- **Failover Configuration**: Automatic failover
- **Clustering**: Distributed deployment

### Performance Tuning:
- **Resource Throttling**: CPU, memory, network limits
- **Cache Configuration**: Memory and disk caching
- **Connection Pooling**: Database and network connections

---

## 12. COMPLIANCE AND REGULATORY SETTINGS

### Compliance Frameworks:
- **SOX Compliance**: Financial regulations
- **HIPAA Compliance**: Healthcare data protection
- **PCI-DSS Compliance**: Payment card security
- **GDPR Compliance**: EU data protection

### Audit Requirements:
- **Audit Trail Configuration**: Complete action logging
- **Data Retention**: Compliance-based retention policies
- **Access Logging**: User access monitoring
- **Change Management**: Configuration change tracking

---

## 13. CLIENT CONFIGURATION OPTIONS

### Client Deployment:
- **Client Certificate Management**: Automatic enrollment
- **Client Configuration Templates**: Standardized configs
- **Client Update Policies**: Automatic updates
- **Client Resource Limits**: CPU, memory, network usage

### Client Communication:
- **Polling Intervals**: Check-in frequency
- **Communication Protocols**: HTTP/HTTPS options
- **Proxy Configuration**: Client proxy settings
- **Offline Capabilities**: Disconnected operation

---

## GUI IMPLEMENTATION RECOMMENDATIONS

### Missing Options in Current GUI:
1. **Password Configuration**: Admin password setup during initial configuration
2. **Certificate Duration Selection**: 1, 5, 10 years, or custom duration options
3. **SSL/Encryption Type Selection**: Self-signed, Let's Encrypt, custom certificates
4. **SSO Integration Wizard**: Step-by-step SAML/OAuth configuration
5. **DNS Server Selection**: Cloudflare, Google, custom DNS options
6. **Security Policy Configuration**: Lockdown mode, access restrictions
7. **Performance Tuning**: Resource limits, caching options
8. **Compliance Mode Selection**: SOX, HIPAA, PCI-DSS, GDPR preset configurations

### Recommended GUI Workflow:
1. **Deployment Type Selection** (radio buttons)
2. **Authentication Method Configuration** (wizard-style)
3. **Certificate Management** (upload/generate options)
4. **Network Configuration** (IP/port settings)
5. **Security Settings** (access control, encryption)
6. **Storage Configuration** (paths, backup options)
7. **Advanced Options** (collapsible sections)
8. **Review and Generate** (configuration summary)

---

## VALIDATION REQUIREMENTS

### Real-time Validation:
- **Path Validation**: Directory existence and permissions
- **Network Validation**: Port availability, DNS resolution
- **Certificate Validation**: Certificate format and validity
- **Authentication Validation**: SSO endpoint connectivity

### Security Validation:
- **Password Strength**: Complexity requirements
- **Certificate Security**: Key strength, expiration dates
- **Network Security**: Secure port configuration
- **Access Control**: Proper permission setup

---

This comprehensive reference ensures your GUI can cover 100% of the `velociraptor.exe config generate -i` functionality with enterprise-grade configuration capabilities.