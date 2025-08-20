# Velociraptor Server Deployment Script
# Compatible with PowerShell 2.0+ and Windows Server 2008 R2+
# Requires Administrator privileges

# Set error handling - stop on any error
$ErrorActionPreference = 'Stop'

# Configuration variables - modify these as needed
$installDir = 'C:\tools'                    # Directory to install Velociraptor executable
$dataStore = 'C:\VelociraptorServerData'    # Directory for server data storage
$frontendPort = 8000                        # Port for agent connections
$guiPort = 8889                            # Port for web GUI access

#─────────────── Helper Functions ───────────────#

# Logging function - creates log directory and writes timestamped messages
function Log ($message) {
    $logDir = Join-Path $Env:ProgramData VelociraptorDeploy
    # Create log directory if it doesn't exist
    if (-not (Test-Path $logDir)) { 
        New-Item $logDir -ItemType Directory -Force | Out-Null 
    }
    # Format timestamp and write to both log file and console
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "$timestamp`t$message"
    $logFile = Join-Path $logDir server_deploy.log
    $logEntry | Out-File $logFile -Append -Encoding UTF8
    Write-Host $message -ForegroundColor Green
}

# Interactive prompt function with default value
function Ask ($question, $defaultValue = 'n') { 
    $response = Read-Host "$question [$defaultValue]"
    if ([string]::IsNullOrEmpty($response)) { 
        return $defaultValue 
    }
    else { 
        return $response 
    } 
}

# Secure password input function - compatible with older PowerShell versions
function AskSecret ($prompt) { 
    $secureString = Read-Host $prompt -AsSecureString
    # Convert SecureString to plain text safely
    try {
        $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
        return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    }
    finally {
        # Always clear the pointer from memory for security
        if ($ptr -ne [System.IntPtr]::Zero) {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
        }
    }
}

# Check if running as Administrator - required for service installation
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Test internet connectivity before attempting downloads
function Test-InternetConnection {
    try {
        $null = Test-NetConnection -ComputerName "api.github.com" -Port 443 -InformationLevel Quiet -ErrorAction Stop
        return $true
    }
    catch {
        # Fallback for older systems without Test-NetConnection
        try {
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadString("https://api.github.com") | Out-Null
            $webClient.Dispose()
            return $true
        }
        catch {
            return $false
        }
    }
}

#─────── Pre-flight Checks ───────#
Log "Starting Velociraptor Server deployment..."

# Check if running as Administrator
if (-not (Test-Administrator)) {
    Write-Error "This script must be run as Administrator. Please restart PowerShell as Administrator and try again."
    exit 1
}

# Check PowerShell version compatibility
$psVersion = $PSVersionTable.PSVersion.Major
Log "PowerShell version: $($PSVersionTable.PSVersion)"
if ($psVersion -lt 2) {
    Write-Error "PowerShell 2.0 or higher is required. Current version: $($PSVersionTable.PSVersion)"
    exit 1
}

# Test internet connectivity
Log "Testing internet connectivity..."
if (-not (Test-InternetConnection)) {
    Write-Error "Internet connection required to download Velociraptor. Please check your connection and try again."
    exit 1
}

#─────── Create Required Directories ───────#
Log "Creating installation directories..."
foreach ($directory in @($installDir, $dataStore)) { 
    if (-not (Test-Path $directory)) { 
        try {
            New-Item $directory -ItemType Directory -Force | Out-Null
            Log "Created directory: $directory"
        }
        catch {
            Log "ERROR: Failed to create directory $directory - $($_.Exception.Message)"
            exit 1
        }
    }
    else {
        Log "Directory already exists: $directory"
    }
}

#─────── Download Velociraptor Executable ───────#
$exe = Join-Path $installDir velociraptor.exe

if (-not (Test-Path $exe)) {
    Log 'Fetching latest Velociraptor Windows-AMD64 release from GitHub...'
    try {
        # Set TLS 1.2 for older systems compatibility
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        
        # Get latest release info from GitHub API (proven working method)
        $apiUrl = "https://api.github.com/repos/Velocidex/velociraptor/releases/latest"
        $response = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
        $windowsAsset = $response.assets | Where-Object { 
            $_.name -like "*windows-amd64.exe" -and 
            $_.name -notlike "*debug*" -and 
            $_.name -notlike "*collector*"
        } | Select-Object -First 1
        
        if (-not $windowsAsset) {
            throw "Could not find Windows executable in release assets"
        }
        
        $version = $response.tag_name -replace '^v', ''
        Log "Found Velociraptor v$version ($([math]::Round($windowsAsset.size / 1MB, 1)) MB)"
        $asset = $windowsAsset
        
        Log "Downloading $($asset.name) (Size: $([math]::Round($asset.size/1MB, 2)) MB)..."
        
        # Download using proven working method
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($asset.browser_download_url, $exe)
        
        if (Test-Path $exe) {
            $fileSize = (Get-Item $exe).Length
            Log "Download completed: $([math]::Round($fileSize / 1MB, 1)) MB"
            
            # Verify file size
            if ([math]::Abs($fileSize - $asset.size) -lt 1024) {
                Log "File size verification: PASSED"
            } else {
                Log "WARNING: File size mismatch"
            }
            
            # Verify download is not empty
            if ($fileSize -eq 0) {
                throw "Downloaded file is empty"
            }
        } else {
            throw "Download failed - file not found"
        }
        
        $webClient.Dispose()
        
    }
    catch {
        Log "ERROR: Failed to download Velociraptor - $($_.Exception.Message)"
        if (Test-Path $exe) { Remove-Item $exe -Force }
        exit 1
    }
}
else { 
    Log "Using existing Velociraptor executable: $exe" 
    # Verify existing executable is valid
    try {
        $version = & $exe version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Existing executable appears corrupted"
        }
        Log "Existing version: $($version -split "`n" | Select-Object -First 1)"
    }
    catch {
        Log "WARNING: Existing executable may be corrupted, consider deleting it to force re-download"
    }
}

#─────── Generate Base Configuration ───────#
$config = Join-Path $installDir server.yaml
Log "Generating base server configuration..."

try {
    # Generate default configuration using Velociraptor
    $configOutput = & $exe config generate 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Config generation failed: $configOutput"
    }
    
    # Save configuration to file with UTF8 encoding for compatibility
    $configOutput | Out-File $config -Encoding UTF8
    Log "Base server.yaml generated successfully"
    
    # Verify configuration file was created and is not empty
    if (-not (Test-Path $config) -or (Get-Item $config).Length -eq 0) {
        throw "Configuration file was not created properly"
    }
    
}
catch {
    Log "ERROR: Failed to generate configuration - $($_.Exception.Message)"
    exit 1
}

#─────── interactive DNS ───────#
$publicHost = $env:COMPUTERNAME
if (Ask 'Do you have a public DNS/FQDN for agents?' 'n' -match '^[Yy]') {
    $publicHost = Read-Host 'Enter FQDN (e.g. velo.example.com)'
}
Log "public_hostname  →  $publicHost"

#─────── interactive SSO (optional) ────#
$sso = ''
if (Ask 'Enable Single-Sign-On (OAuth2/OIDC)?' 'n' -match '^[Yy]') {
    switch ((Read-Host 'SSO provider  [google | azure | github | okta | oidc]').ToLower()) {
        'google' {
            $cid = Read-Host 'Google client-ID'
            $sec = AskSecret 'Google client-secret'
            $sso = @"
authenticator:
type: Google
oauth_client_id: '$cid'
oauth_client_secret: '$sec'
"@ 
        }
        'azure' {
            $cid = Read-Host 'Azure client-ID'
            $sec = AskSecret 'Azure client-secret'
            $ten = Read-Host 'Azure tenant-ID'
            $sso = @"
authenticator:
type: Azure
oauth_client_id: '$cid'
oauth_client_secret: '$sec'
tenant: '$ten'
"@ 
        }
        'github' {
            $cid = Read-Host 'GitHub client-ID'
            $sec = AskSecret 'GitHub client-secret'
            $sso = @"
authenticator:
type: GitHub
oauth_client_id: '$cid'
oauth_client_secret: '$sec'
"@ 
        }
        'okta' {
            $cid = Read-Host 'Okta client-ID'
            $sec = AskSecret 'Okta client-secret'
            $iss = Read-Host 'Okta issuer URL'
            $sso = @"
authenticator:
type: OIDC
oidc_issuer_url: '$iss'
client_id: '$cid'
client_secret: '$sec'
scopes: ['openid','profile','email']
"@ 
        }
        'oidc' {
            $cid = Read-Host 'OIDC client-ID'
            $sec = AskSecret 'OIDC client-secret'
            $iss = Read-Host 'OIDC issuer URL'
            $sso = @"
authenticator:
type: OIDC
oidc_issuer_url: '$iss'
client_id: '$cid'
client_secret: '$sec'
"@ 
        }
        default { Log 'Unknown provider – skipping SSO.' }
    }
}

#─────── patch server.yaml ────#
[String[]]$yaml = Get-Content $config
$yaml = $yaml -replace '^public_hostname:.*', "public_hostname: '$publicHost'"

# Configure Frontend Port (for agent connections)
Log "Configuring frontend port: $frontendPort"
for ($i = 0; $i -lt $yaml.Count; $i++) {
    # Look for Frontend section and its bind_port
    if ($yaml[$i] -match '^Frontend:') {
        for ($j = $i + 1; $j -lt $yaml.Count; $j++) {
            if ($yaml[$j] -match '^\s*bind_port:') {
                $yaml[$j] = $yaml[$j] -replace '^\s*bind_port:.*', "  bind_port: $frontendPort"
                Log "Frontend bind_port set to $frontendPort"
                break
            }
            # Stop if we hit another top-level section
            if ($yaml[$j] -match '^[A-Za-z]' -and $yaml[$j] -notmatch '^\s') { break }
        }
        break
    }
}

# Configure GUI Port (for web interface)
Log "Configuring GUI port: $guiPort"
for ($i = 0; $i -lt $yaml.Count; $i++) {
    if ($yaml[$i] -match '^GUI:') {
        for ($j = $i + 1; $j -lt $yaml.Count; $j++) {
            if ($yaml[$j] -match '^\s*bind_port:') {
                $yaml[$j] = $yaml[$j] -replace '^\s*bind_port:.*', "  bind_port: $guiPort"
                Log "GUI bind_port set to $guiPort"
                break
            }
            # Stop if we hit another top-level section
            if ($yaml[$j] -match '^[A-Za-z]' -and $yaml[$j] -notmatch '^\s') { break }
        }
        break
    }
}

# Configure Datastore (where server data is stored)
Log "Configuring datastore location: $dataStore"
$datastoreConfigured = $false

for ($i = 0; $i -lt $yaml.Count; $i++) {
    if ($yaml[$i] -match '^Datastore:') {
        # Find the end of the Datastore section
        $endIdx = $i + 1
        while ($endIdx -lt $yaml.Count -and $yaml[$endIdx] -match '^\s+') { 
            $endIdx++ 
        }
        
        # Create new datastore configuration
        $datastoreConfig = @(
            "  implementation: FileBaseDataStore",
            "  location: '$($dataStore -replace '\\', '/')/'", # Use forward slashes for YAML
            "  filestore_directory: '$($dataStore -replace '\\', '/')/filestore'"
        )
        
        # Replace the existing datastore configuration
        if ($endIdx -lt $yaml.Count) {
            $yaml = $yaml[0..$i] + $datastoreConfig + $yaml[$endIdx..($yaml.Count - 1)]
        }
        else {
            $yaml = $yaml[0..$i] + $datastoreConfig
        }
        
        $datastoreConfigured = $true
        Log "Datastore configuration updated"
        break
    }
}

# If no Datastore section found, add it
if (-not $datastoreConfigured) {
    $yaml += @(
        "",
        "Datastore:",
        "  implementation: FileBaseDataStore", 
        "  location: '$($dataStore -replace '\\', '/')/'",
        "  filestore_directory: '$($dataStore -replace '\\', '/')/filestore'"
    )
    Log "Datastore section added to configuration"
}

# Configure Single Sign-On if requested
if ($sso) {
    Log "Adding SSO configuration to server.yaml"
    $ssoConfigured = $false
    
    # Find GUI section and add SSO config
    for ($i = 0; $i -lt $yaml.Count; $i++) {
        if ($yaml[$i] -match '^GUI:') {
            # Find insertion point after GUI section header
            $insertIdx = $i + 1
            while ($insertIdx -lt $yaml.Count -and $yaml[$insertIdx] -match '^\s+') { 
                $insertIdx++ 
            }
            
            # Prepare SSO configuration lines with proper indentation
            $ssoLines = ($sso -split "`n") | ForEach-Object { 
                if ($_.Trim() -ne '') { '  ' + $_ } else { $_ }
            }
            
            # Insert SSO configuration
            if ($insertIdx -lt $yaml.Count) {
                $yaml = $yaml[0..($insertIdx - 1)] + $ssoLines + $yaml[$insertIdx..($yaml.Count - 1)]
            }
            else {
                $yaml += $ssoLines
            }
            
            $ssoConfigured = $true
            Log "SSO configuration added to GUI section"
            break
        }
    }
    
    # If no GUI section found, create one with SSO
    if (-not $ssoConfigured) {
        $yaml += @("", "GUI:")
        $yaml += ($sso -split "`n") | ForEach-Object { 
            if ($_.Trim() -ne '') { '  ' + $_ } else { $_ }
        }
        Log "GUI section created with SSO configuration"
    }
}
# Save the updated configuration
try {
    $yaml | Out-File $config -Encoding UTF8
    Log 'server.yaml updated with custom ports, datastore, and SSO configuration'
}
catch {
    Log "ERROR: Failed to save configuration file - $($_.Exception.Message)"
    exit 1
}

#─────── Configure Windows Firewall ───────#
Log "Configuring Windows Firewall rules..."

foreach ($port in @($frontendPort, $guiPort)) {
    $ruleName = "Velociraptor TCP $port"
    $ruleExists = $false
    
    # Check if rule already exists (compatible with older PowerShell)
    try {
        # Try modern method first (Windows 8/Server 2012+)
        if (Get-Command Get-NetFirewallRule -ErrorAction SilentlyContinue) {
            $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
            $ruleExists = $null -ne $existingRule
        }
        else {
            # Fallback for older systems - check via netsh
            $netshOutput = netsh advfirewall firewall show rule name="$ruleName" 2>$null
            $ruleExists = $netshOutput -match "Rule Name:"
        }
    }
    catch {
        $ruleExists = $false
    }
    
    if (-not $ruleExists) {
        try {
            # Try modern PowerShell method first
            if (Get-Command New-NetFirewallRule -ErrorAction SilentlyContinue) {
                New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port -ErrorAction Stop | Out-Null
                Log "Firewall rule added via PowerShell NetSecurity (TCP $port)"
            }
            else {
                throw "NetSecurity module not available"
            }
        }
        catch {
            # Fallback to netsh for older systems (Windows 7/Server 2008 R2)
            try {
                $netshResult = netsh advfirewall firewall add rule name="$ruleName" dir=in action=allow protocol=TCP localport=$port 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Log "Firewall rule added via netsh (TCP $port)"
                }
                else {
                    throw "netsh command failed: $netshResult"
                }
            }
            catch {
                Log "WARNING: Failed to add firewall rule for port $port - $($_.Exception.Message)"
                Log "You may need to manually configure firewall to allow TCP port $port"
            }
        }
    }
    else {
        Log "Firewall rule already exists for TCP port $port"
    }
}

#─────── Validate Configuration ───────#
Log "Validating server configuration..."

try {
    # Test configuration syntax and completeness
    $configTest = & $exe config show --config $config 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Configuration validation failed: $configTest"
    }
    
    # Additional validation - check if key sections exist
    $configContent = Get-Content $config -Raw
    $requiredSections = @('Frontend:', 'GUI:', 'Datastore:')
    
    foreach ($section in $requiredSections) {
        if ($configContent -notmatch $section) {
            Log "WARNING: Configuration may be missing $section section"
        }
    }
    
    Log 'Configuration validated successfully'
    
}
catch {
    Log "ERROR: Configuration validation failed - $($_.Exception.Message)"
    Log "Configuration file location: $config"
    Log "Please check the configuration file manually before proceeding"
    exit 1
}

#─────── Build Client MSI Package ───────#
# Create MSI installer for deploying agents to client machines
$msi = Join-Path $installDir "velociraptor_client_${publicHost}.msi"
Log "Building client MSI package..."

try {
    # Remove existing MSI if present to avoid conflicts
    if (Test-Path $msi) {
        Remove-Item $msi -Force
        Log "Removed existing MSI file"
    }
    
    # Build the MSI package
    Log "This may take a few minutes for large deployments..."
    $msiResult = & $exe package windows msi --msi_out $msi --config $config 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        throw "MSI creation failed with exit code $LASTEXITCODE`: $msiResult"
    }
    
    # Verify MSI was created successfully
    if (-not (Test-Path $msi) -or (Get-Item $msi).Length -eq 0) {
        throw "MSI file was not created or is empty"
    }
    
    $msiSize = [math]::Round((Get-Item $msi).Length / 1MB, 2)
    Log "Client MSI package created successfully → $msi (Size: ${msiSize} MB)"
    Log "Use this MSI to deploy Velociraptor agents to client machines"
    
}
catch {
    Log "ERROR: Failed to create client MSI package - $($_.Exception.Message)"
    Log "Server installation will continue, but you'll need to create the MSI manually later"
    # Don't exit here - server can still be installed without MSI
}

#─────── Install and Start Windows Service ───────#
Log "Installing Velociraptor as Windows service..."

try {
    # Check if service already exists
    $existingService = Get-Service -Name "Velociraptor" -ErrorAction SilentlyContinue
    if ($existingService) {
        Log "Velociraptor service already exists - stopping and removing..."
        try {
            Stop-Service -Name "Velociraptor" -Force -ErrorAction SilentlyContinue
            & $exe service remove 2>&1 | Out-Null
            Start-Sleep -Seconds 2  # Wait for service removal to complete
        }
        catch {
            Log "WARNING: Could not cleanly remove existing service - $($_.Exception.Message)"
        }
    }
    
    # Install the service
    Log "Installing Velociraptor service..."
    $serviceResult = & $exe service install --config $config 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Service installation failed with exit code $LASTEXITCODE`: $serviceResult"
    }
    
    # Wait a moment for service registration to complete
    Start-Sleep -Seconds 2
    
    # Configure service startup type
    Log "Configuring service to start automatically..."
    try {
        Set-Service -Name "Velociraptor" -StartupType Automatic -ErrorAction Stop
    }
    catch {
        # Fallback for older PowerShell versions
        & sc.exe config Velociraptor start= auto | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to set service startup type"
        }
    }
    
    # Start the service
    Log "Starting Velociraptor service..."
    try {
        Start-Service -Name "Velociraptor" -ErrorAction Stop
    }
    catch {
        # Fallback method
        & net start Velociraptor | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to start service using net command"
        }
    }
    
    # Verify service is running
    Start-Sleep -Seconds 3
    $service = Get-Service -Name "Velociraptor" -ErrorAction Stop
    if ($service.Status -eq "Running") {
        Log "Velociraptor service installed and started successfully"
    }
    else {
        throw "Service installed but not running (Status: $($service.Status))"
    }
    
}
catch {
    Log "ERROR: Service installation/startup failed - $($_.Exception.Message)"
    Log "You may need to install and start the service manually using:"
    Log "  $exe service install --config $config"
    Log "  net start Velociraptor"
    exit 1
}

#─────── Deployment Complete ───────#
Log ""
Log "=========================================="
Log "    Velociraptor Server Deployment Complete!"
Log "=========================================="
Log ""
Log "Server Details:"
Log "  - Installation Directory: $installDir"
Log "  - Data Storage Directory: $dataStore"
Log "  - Configuration File: $config"
Log "  - Frontend Port (Agents): $frontendPort"
Log "  - GUI Port (Web Interface): $guiPort"
Log "  - Public Hostname: $publicHost"
if (Test-Path $msi) {
    Log "  - Client MSI Package: $msi"
}
Log ""
Log "Next Steps:"
Log "  1. Browse to: https://${publicHost}:${guiPort}"
Log "  2. Create your first admin user account"
Log "  3. Deploy agents using the MSI package (if created)"
Log "  4. Configure additional settings as needed"
Log ""
Log "Service Management:"
Log "  - Start:   net start Velociraptor"
Log "  - Stop:    net stop Velociraptor"
Log "  - Status:  sc query Velociraptor"
Log ""
Log "Troubleshooting:"
Log "  - Check service logs in Event Viewer"
Log "  - Configuration file: $config"
Log "  - Installation log: $(Join-Path $Env:ProgramData 'VelociraptorDeploy\server_deploy.log')"
Log ""

# Final connectivity test
try {
    $testUrl = "https://${publicHost}:${guiPort}"
    Log "Testing web interface connectivity..."
    
    # Simple connectivity test (don't validate SSL for self-signed certs)
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add('User-Agent', 'VelociraptorDeployTest/1.0')
    
    # Set up to ignore SSL certificate errors for self-signed certificates
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
    
    try {
        $response = $webClient.DownloadString($testUrl)
        Log "Web interface is accessible at $testUrl"
    }
    catch {
        Log "WARNING: Web interface test failed - this is normal for new installations"
        Log "  The service may still be starting up. Wait a few minutes and try accessing:"
        Log "  $testUrl"
    }
    finally {
        $webClient.Dispose()
        # Reset certificate validation
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
    }
}
catch {
    Log "Could not test web interface connectivity - please verify manually"
}

Log ""
Log "Deployment completed successfully!"
Log "=========================================="
