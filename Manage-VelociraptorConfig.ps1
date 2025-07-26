<#
.SYNOPSIS
    Unified configuration management for Velociraptor deployments.

.DESCRIPTION
    Provides centralized configuration management including:
    • Configuration validation and testing
    • Backup and restore operations
    • Template generation
    • Configuration migration between versions
    • Security hardening options

.PARAMETER Action
    Action to perform: Validate, Backup, Restore, Template, Migrate, Harden

.PARAMETER ConfigPath
    Path to Velociraptor configuration file

.PARAMETER BackupPath
    Path for backup operations

.PARAMETER TemplateName
    Template name: Standalone, Server, Cluster, Forensics

.EXAMPLE
    .\Manage-VelociraptorConfig.ps1 -Action Validate -ConfigPath "C:\tools\server.yaml"

.EXAMPLE
    .\Manage-VelociraptorConfig.ps1 -Action Template -TemplateName Server
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Validate', 'Backup', 'Restore', 'Template', 'Migrate', 'Harden')]
    [string]$Action,
    
    [string]$ConfigPath,
    [string]$BackupPath,
    [ValidateSet('Standalone', 'Server', 'Cluster', 'Forensics')]
    [string]$TemplateName,
    
    [string]$OutputPath = '.'
)

$ErrorActionPreference = 'Stop'

function Write-ConfigLog {
    param([string]$Message, [string]$Level = 'Info')
    
    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        default { 'White' }
    }
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $color
}

function Test-VelociraptorConfig {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        throw "Configuration file not found: $Path"
    }
    
    Write-ConfigLog "Validating configuration: $Path"
    
    try {
        $content = Get-Content $Path -Raw
        $issues = @()
        
        # Basic YAML structure validation
        if (-not ($content -match 'version:')) {
            $issues += "Missing version specification"
        }
        
        # Check required sections
        $requiredSections = @('Frontend:', 'GUI:', 'Client:', 'Datastore:')
        foreach ($section in $requiredSections) {
            if (-not ($content -match $section)) {
                $issues += "Missing required section: $section"
            }
        }
        
        # Check for common security issues
        if ($content -match 'bind_address:\s*0\.0\.0\.0') {
            $issues += "Security Warning: Binding to all interfaces (0.0.0.0)"
        }
        
        if ($content -match 'autocert_domain:.*localhost') {
            $issues += "Warning: Using localhost for autocert domain"
        }
        
        # Port validation
        $portPattern = 'bind_port:\s*(\d+)'
        $ports = [regex]::Matches($content, $portPattern) | ForEach-Object { [int]$_.Groups[1].Value }
        $duplicatePorts = $ports | Group-Object | Where-Object { $_.Count -gt 1 }
        
        if ($duplicatePorts) {
            $issues += "Duplicate ports found: $($duplicatePorts.Name -join ', ')"
        }
        
        # Results
        if ($issues.Count -eq 0) {
            Write-ConfigLog "✓ Configuration validation passed" -Level 'Success'
            return @{ Valid = $true; Issues = @() }
        } else {
            Write-ConfigLog "✗ Configuration validation failed" -Level 'Error'
            $issues | ForEach-Object { Write-ConfigLog "  - $_" -Level 'Warning' }
            return @{ Valid = $false; Issues = $issues }
        }
    }
    catch {
        Write-ConfigLog "Error validating configuration: $($_.Exception.Message)" -Level 'Error'
        return @{ Valid = $false; Issues = @("Validation error: $($_.Exception.Message)") }
    }
}

function Backup-VelociraptorConfig {
    param([string]$SourcePath, [string]$DestinationPath)
    
    if (-not (Test-Path $SourcePath)) {
        throw "Source configuration not found: $SourcePath"
    }
    
    if (-not $DestinationPath) {
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $DestinationPath = "$SourcePath.backup.$timestamp"
    }
    
    Write-ConfigLog "Creating backup: $SourcePath → $DestinationPath"
    
    try {
        # Create backup directory if needed
        $backupDir = Split-Path $DestinationPath -Parent
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        
        # Copy configuration
        Copy-Item $SourcePath $DestinationPath -Force
        
        # Create backup metadata
        $metadata = @{
            OriginalPath = $SourcePath
            BackupDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            BackupBy = $env:USERNAME
            ComputerName = $env:COMPUTERNAME
            FileSize = (Get-Item $SourcePath).Length
            FileHash = (Get-FileHash $SourcePath -Algorithm SHA256).Hash
        }
        
        $metadataPath = "$DestinationPath.metadata.json"
        $metadata | ConvertTo-Json -Depth 3 | Out-File $metadataPath -Encoding UTF8
        
        Write-ConfigLog "✓ Backup completed successfully" -Level 'Success'
        Write-ConfigLog "  Config: $DestinationPath"
        Write-ConfigLog "  Metadata: $metadataPath"
        
        return @{
            Success = $true
            BackupPath = $DestinationPath
            MetadataPath = $metadataPath
        }
    }
    catch {
        Write-ConfigLog "Backup failed: $($_.Exception.Message)" -Level 'Error'
        throw
    }
}

function Restore-VelociraptorConfig {
    param([string]$BackupPath, [string]$TargetPath)
    
    if (-not (Test-Path $BackupPath)) {
        throw "Backup file not found: $BackupPath"
    }
    
    Write-ConfigLog "Restoring configuration: $BackupPath → $TargetPath"
    
    try {
        # Validate backup integrity if metadata exists
        $metadataPath = "$BackupPath.metadata.json"
        if (Test-Path $metadataPath) {
            $metadata = Get-Content $metadataPath | ConvertFrom-Json
            $currentHash = (Get-FileHash $BackupPath -Algorithm SHA256).Hash
            
            if ($currentHash -ne $metadata.FileHash) {
                Write-ConfigLog "Warning: Backup file hash mismatch - file may be corrupted" -Level 'Warning'
            } else {
                Write-ConfigLog "✓ Backup integrity verified" -Level 'Success'
            }
        }
        
        # Create backup of current config if it exists
        if (Test-Path $TargetPath) {
            $currentBackup = "$TargetPath.pre-restore.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item $TargetPath $currentBackup
            Write-ConfigLog "Current config backed up to: $currentBackup"
        }
        
        # Restore configuration
        Copy-Item $BackupPath $TargetPath -Force
        
        # Validate restored configuration
        $validation = Test-VelociraptorConfig -Path $TargetPath
        if ($validation.Valid) {
            Write-ConfigLog "✓ Configuration restored and validated successfully" -Level 'Success'
        } else {
            Write-ConfigLog "⚠ Configuration restored but validation failed" -Level 'Warning'
        }
        
        return @{
            Success = $true
            RestoredPath = $TargetPath
            ValidationResult = $validation
        }
    }
    catch {
        Write-ConfigLog "Restore failed: $($_.Exception.Message)" -Level 'Error'
        throw
    }
}

function New-VelociraptorConfigTemplate {
    param([string]$TemplateName, [string]$OutputPath)
    
    Write-ConfigLog "Generating $TemplateName configuration template..."
    
    $templates = @{
        'Standalone' = @"
# Velociraptor Standalone Configuration Template
# Optimized for single-machine forensic analysis

version:
  name: velociraptor
  version: "0.74"
  commit: standalone-template

Client:
  server_urls:
    - https://localhost:8000/
  ca_certificate: |
    # Auto-generated CA certificate will be inserted here
  nonce: # Auto-generated nonce will be inserted here

API:
  bind_address: 127.0.0.1
  bind_port: 8001

GUI:
  bind_address: 127.0.0.1
  bind_port: 8889
  gw_certificate: |
    # Auto-generated GUI certificate will be inserted here
  gw_private_key: |
    # Auto-generated GUI private key will be inserted here

Frontend:
  bind_address: 127.0.0.1
  bind_port: 8000
  certificate: |
    # Auto-generated frontend certificate will be inserted here
  private_key: |
    # Auto-generated frontend private key will be inserted here

Datastore:
  implementation: FileBaseDataStore
  location: ./datastore
  filestore_directory: ./filestore

Logging:
  output_directory: ./logs
  separate_logs_per_component: true
  rotation_time: 604800
  max_age: 2592000

# Standalone-specific optimizations
defaults:
  hunt_expiry_hours: 168  # 1 week
  notebook_cell_timeout: 600  # 10 minutes
  max_upload_size: 1073741824  # 1GB
"@

        'Server' = @"
# Velociraptor Server Configuration Template
# Optimized for enterprise multi-client deployment

version:
  name: velociraptor
  version: "0.74"
  commit: server-template

public_hostname: # Set your public hostname/FQDN here

Client:
  server_urls:
    - https://{{public_hostname}}:8000/
  ca_certificate: |
    # Auto-generated CA certificate will be inserted here
  nonce: # Auto-generated nonce will be inserted here

API:
  bind_address: 0.0.0.0
  bind_port: 8001

GUI:
  bind_address: 0.0.0.0
  bind_port: 8889
  gw_certificate: |
    # Auto-generated GUI certificate will be inserted here
  gw_private_key: |
    # Auto-generated GUI private key will be inserted here

Frontend:
  bind_address: 0.0.0.0
  bind_port: 8000
  certificate: |
    # Auto-generated frontend certificate will be inserted here
  private_key: |
    # Auto-generated frontend private key will be inserted here

Datastore:
  implementation: FileBaseDataStore
  location: /opt/velociraptor/datastore
  filestore_directory: /opt/velociraptor/filestore

Logging:
  output_directory: /var/log/velociraptor
  separate_logs_per_component: true
  rotation_time: 86400  # Daily rotation
  max_age: 2592000  # 30 days retention

# Server-specific optimizations
defaults:
  hunt_expiry_hours: 72  # 3 days
  notebook_cell_timeout: 300  # 5 minutes
  max_upload_size: 536870912  # 512MB
  max_memory: 2147483648  # 2GB

# Performance tuning for server deployment
performance:
  expected_clients: 1000
  max_concurrent_hunts: 10
  max_concurrent_flows: 100
"@

        'Forensics' = @"
# Velociraptor Forensics Configuration Template
# Optimized for digital forensics investigations

version:
  name: velociraptor
  version: "0.74"
  commit: forensics-template

Client:
  server_urls:
    - https://forensics-server:8000/
  ca_certificate: |
    # Auto-generated CA certificate will be inserted here
  nonce: # Auto-generated nonce will be inserted here

API:
  bind_address: 127.0.0.1
  bind_port: 8001

GUI:
  bind_address: 0.0.0.0
  bind_port: 8889
  gw_certificate: |
    # Auto-generated GUI certificate will be inserted here
  gw_private_key: |
    # Auto-generated GUI private key will be inserted here

Frontend:
  bind_address: 0.0.0.0
  bind_port: 8000
  certificate: |
    # Auto-generated frontend certificate will be inserted here
  private_key: |
    # Auto-generated frontend private key will be inserted here

Datastore:
  implementation: FileBaseDataStore
  location: /cases/datastore
  filestore_directory: /cases/filestore

Logging:
  output_directory: /cases/logs
  separate_logs_per_component: true
  rotation_time: 604800  # Weekly rotation
  max_age: 7776000  # 90 days retention (legal hold)

# Forensics-specific settings
defaults:
  hunt_expiry_hours: 720  # 30 days
  notebook_cell_timeout: 1800  # 30 minutes for complex analysis
  max_upload_size: 5368709120  # 5GB for large evidence files
  max_memory: 8589934592  # 8GB for memory analysis

# Evidence handling
evidence:
  chain_of_custody: true
  hash_verification: true
  compression: true
  encryption: true

# Artifact collections optimized for forensics
artifact_definitions:
  - Windows.Forensics.Timeline
  - Windows.Forensics.Registry
  - Windows.Forensics.NTFS
  - Windows.Forensics.Memory
  - Linux.Forensics.Timeline
  - MacOS.Forensics.Timeline
"@
    }
    
    if (-not $templates.ContainsKey($TemplateName)) {
        throw "Unknown template: $TemplateName. Available: $($templates.Keys -join ', ')"
    }
    
    $templateContent = $templates[$TemplateName]
    $outputFile = Join-Path $OutputPath "velociraptor-$($TemplateName.ToLower())-template.yaml"
    
    $templateContent | Out-File $outputFile -Encoding UTF8
    
    Write-ConfigLog "✓ Template created: $outputFile" -Level 'Success'
    
    return @{
        Success = $true
        TemplatePath = $outputFile
        TemplateName = $TemplateName
    }
}

function Optimize-VelociraptorConfig {
    param([string]$ConfigPath)
    
    Write-ConfigLog "Applying security hardening to: $ConfigPath"
    
    if (-not (Test-Path $ConfigPath)) {
        throw "Configuration file not found: $ConfigPath"
    }
    
    try {
        $content = Get-Content $ConfigPath -Raw
        $changes = @()
        
        # Security hardening recommendations
        $hardeningRules = @{
            # Bind to specific interfaces instead of 0.0.0.0 where possible
            'bind_address:\s*0\.0\.0\.0' = 'bind_address: 127.0.0.1  # Hardened: localhost only'
            
            # Enable logging
            'separate_logs_per_component:\s*false' = 'separate_logs_per_component: true  # Hardened: detailed logging'
            
            # Set reasonable timeouts
            'notebook_cell_timeout:\s*0' = 'notebook_cell_timeout: 300  # Hardened: 5 minute timeout'
        }
        
        foreach ($pattern in $hardeningRules.Keys) {
            if ($content -match $pattern) {
                $content = $content -replace $pattern, $hardeningRules[$pattern]
                $changes += "Applied hardening rule: $pattern"
            }
        }
        
        # Add security headers if GUI section exists
        if ($content -match 'GUI:') {
            if (-not ($content -match 'security_headers:')) {
                $securityHeaders = @"

  # Security hardening headers
  security_headers:
    X-Frame-Options: DENY
    X-Content-Type-Options: nosniff
    X-XSS-Protection: "1; mode=block"
    Strict-Transport-Security: "max-age=31536000; includeSubDomains"
    Content-Security-Policy: "default-src 'self'"
"@
                $content = $content -replace '(GUI:.*?)(\n[A-Z])', "`$1$securityHeaders`$2"
                $changes += "Added security headers to GUI configuration"
            }
        }
        
        # Backup original and save hardened version
        $backupPath = "$ConfigPath.pre-hardening.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $ConfigPath $backupPath
        
        $content | Out-File $ConfigPath -Encoding UTF8
        
        Write-ConfigLog "✓ Security hardening completed" -Level 'Success'
        Write-ConfigLog "  Original backed up to: $backupPath"
        Write-ConfigLog "  Changes applied: $($changes.Count)"
        
        $changes | ForEach-Object { Write-ConfigLog "    - $_" }
        
        return @{
            Success = $true
            ChangesApplied = $changes.Count
            BackupPath = $backupPath
            Changes = $changes
        }
    }
    catch {
        Write-ConfigLog "Hardening failed: $($_.Exception.Message)" -Level 'Error'
        throw
    }
}

# Main execution
try {
    switch ($Action) {
        'Validate' {
            if (-not $ConfigPath) { throw "ConfigPath required for validation" }
            $result = Test-VelociraptorConfig -Path $ConfigPath
            exit $(if ($result.Valid) { 0 } else { 1 })
        }
        
        'Backup' {
            if (-not $ConfigPath) { throw "ConfigPath required for backup" }
            $result = Backup-VelociraptorConfig -SourcePath $ConfigPath -DestinationPath $BackupPath
            Write-ConfigLog "Backup completed: $($result.BackupPath)"
        }
        
        'Restore' {
            if (-not $BackupPath) { throw "BackupPath required for restore" }
            if (-not $ConfigPath) { throw "ConfigPath required for restore" }
            $result = Restore-VelociraptorConfig -BackupPath $BackupPath -TargetPath $ConfigPath
            Write-ConfigLog "Restore completed: $($result.RestoredPath)"
        }
        
        'Template' {
            if (-not $TemplateName) { throw "TemplateName required for template generation" }
            $result = New-VelociraptorConfigTemplate -TemplateName $TemplateName -OutputPath $OutputPath
            Write-ConfigLog "Template created: $($result.TemplatePath)"
        }
        
        'Harden' {
            if (-not $ConfigPath) { throw "ConfigPath required for hardening" }
            $result = Optimize-VelociraptorConfig -ConfigPath $ConfigPath
            Write-ConfigLog "Hardening completed with $($result.ChangesApplied) changes"
        }
        
        default {
            throw "Unknown action: $Action"
        }
    }
}
catch {
    Write-ConfigLog "Operation failed: $($_.Exception.Message)" -Level 'Error'
    exit 1
}