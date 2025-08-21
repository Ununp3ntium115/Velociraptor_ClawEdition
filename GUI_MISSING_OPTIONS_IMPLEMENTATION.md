# Velociraptor GUI Missing Options - Implementation Guide

## Immediate Implementation Requirements

Based on analysis of the current `VelociraptorGUI-InstallClean.ps1`, here are the specific missing options that need to be added to achieve 100% coverage of `velociraptor.exe config generate -i` functionality:

---

## 1. AUTHENTICATION CONFIGURATION PANEL

### Current Status: MISSING COMPLETELY
### Priority: HIGH - Critical for security

```powershell
# Add Authentication Configuration Panel
function Add-AuthenticationPanel {
    param($ParentPanel)
    
    # Create authentication group box
    $AuthGroupBox = New-Object System.Windows.Forms.GroupBox
    $AuthGroupBox.Text = "Authentication Configuration"
    $AuthGroupBox.Size = New-Object System.Drawing.Size(840, 200)
    $AuthGroupBox.Location = New-Object System.Drawing.Point(20, 100)
    $AuthGroupBox.BackColor = $Colors.DarkSurface
    $AuthGroupBox.ForeColor = $Colors.WhiteText
    
    # Authentication type selection
    $AuthTypeLabel = New-Object System.Windows.Forms.Label
    $AuthTypeLabel.Text = "Authentication Method:"
    $AuthTypeLabel.Location = New-Object System.Drawing.Point(20, 30)
    $AuthTypeLabel.Size = New-Object System.Drawing.Size(150, 20)
    $AuthTypeLabel.ForeColor = $Colors.WhiteText
    
    $Script:AuthTypeComboBox = New-Object System.Windows.Forms.ComboBox
    $Script:AuthTypeComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $Script:AuthTypeComboBox.Items.AddRange(@(
        "Basic Authentication (Username/Password)",
        "Google OAuth2 (Single Sign-On)",
        "Azure/Microsoft OAuth2", 
        "GitHub OAuth2",
        "SAML Authentication",
        "OpenID Connect (OIDC)",
        "Multiple Authentication Methods"
    ))
    $Script:AuthTypeComboBox.SelectedIndex = 0  # Default to Basic
    $Script:AuthTypeComboBox.Location = New-Object System.Drawing.Point(180, 28)
    $Script:AuthTypeComboBox.Size = New-Object System.Drawing.Size(300, 25)
    $Script:AuthTypeComboBox.BackColor = $Colors.DarkBackground
    $Script:AuthTypeComboBox.ForeColor = $Colors.WhiteText
    
    # Admin username field
    $AdminUserLabel = New-Object System.Windows.Forms.Label
    $AdminUserLabel.Text = "Admin Username:"
    $AdminUserLabel.Location = New-Object System.Drawing.Point(20, 70)
    $AdminUserLabel.Size = New-Object System.Drawing.Size(150, 20)
    $AdminUserLabel.ForeColor = $Colors.WhiteText
    
    $Script:AdminUserTextBox = New-Object System.Windows.Forms.TextBox
    $Script:AdminUserTextBox.Text = "admin"
    $Script:AdminUserTextBox.Location = New-Object System.Drawing.Point(180, 68)
    $Script:AdminUserTextBox.Size = New-Object System.Drawing.Size(200, 25)
    $Script:AdminUserTextBox.BackColor = $Colors.DarkBackground
    $Script:AdminUserTextBox.ForeColor = $Colors.WhiteText
    
    # Admin password field
    $AdminPasswordLabel = New-Object System.Windows.Forms.Label
    $AdminPasswordLabel.Text = "Admin Password:"
    $AdminPasswordLabel.Location = New-Object System.Drawing.Point(20, 110)
    $AdminPasswordLabel.Size = New-Object System.Drawing.Size(150, 20)
    $AdminPasswordLabel.ForeColor = $Colors.WhiteText
    
    $Script:AdminPasswordTextBox = New-Object System.Windows.Forms.TextBox
    $Script:AdminPasswordTextBox.UseSystemPasswordChar = $true
    $Script:AdminPasswordTextBox.Location = New-Object System.Drawing.Point(180, 108)
    $Script:AdminPasswordTextBox.Size = New-Object System.Drawing.Size(200, 25)
    $Script:AdminPasswordTextBox.BackColor = $Colors.DarkBackground
    $Script:AdminPasswordTextBox.ForeColor = $Colors.WhiteText
    
    # Generate password button
    $GeneratePasswordButton = New-Object System.Windows.Forms.Button
    $GeneratePasswordButton.Text = "Generate Secure Password"
    $GeneratePasswordButton.Location = New-Object System.Drawing.Point(400, 108)
    $GeneratePasswordButton.Size = New-Object System.Drawing.Size(180, 25)
    $GeneratePasswordButton.BackColor = $Colors.PrimaryTeal
    $GeneratePasswordButton.ForeColor = $Colors.WhiteText
    $GeneratePasswordButton.Add_Click({
        $securePassword = Generate-SecurePassword
        $Script:AdminPasswordTextBox.Text = $securePassword
        [System.Windows.Forms.MessageBox]::Show(
            "Secure password generated!`n`nPassword: $securePassword`n`nPlease save this password securely.",
            "Password Generated",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    })
    
    # OAuth configuration panel (initially hidden)
    $Script:OAuthPanel = New-Object System.Windows.Forms.Panel
    $Script:OAuthPanel.Size = New-Object System.Drawing.Size(800, 80)
    $Script:OAuthPanel.Location = New-Object System.Drawing.Point(20, 150)
    $Script:OAuthPanel.BackColor = $Colors.DarkBackground
    $Script:OAuthPanel.Visible = $false
    
    # Add OAuth fields
    Add-OAuthFields $Script:OAuthPanel
    
    # Authentication type change handler
    $Script:AuthTypeComboBox.Add_SelectedIndexChanged({
        $isOAuth = $Script:AuthTypeComboBox.SelectedIndex -gt 0
        $Script:OAuthPanel.Visible = $isOAuth
        $Script:AdminPasswordTextBox.Enabled = -not $isOAuth
        $GeneratePasswordButton.Enabled = -not $isOAuth
    })
    
    $AuthGroupBox.Controls.AddRange(@(
        $AuthTypeLabel, $Script:AuthTypeComboBox,
        $AdminUserLabel, $Script:AdminUserTextBox,
        $AdminPasswordLabel, $Script:AdminPasswordTextBox,
        $GeneratePasswordButton, $Script:OAuthPanel
    ))
    
    $ParentPanel.Controls.Add($AuthGroupBox)
}

function Generate-SecurePassword {
    $charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
    $password = ""
    for ($i = 0; $i -lt 16; $i++) {
        $password += $charset[(Get-Random -Maximum $charset.Length)]
    }
    return $password
}
```

---

## 2. CERTIFICATE MANAGEMENT PANEL

### Current Status: MISSING COMPLETELY  
### Priority: HIGH - Essential for SSL/TLS configuration

```powershell
# Add Certificate Configuration Panel
function Add-CertificatePanel {
    param($ParentPanel)
    
    $CertGroupBox = New-Object System.Windows.Forms.GroupBox
    $CertGroupBox.Text = "Certificate Configuration"
    $CertGroupBox.Size = New-Object System.Drawing.Size(840, 180)
    $CertGroupBox.Location = New-Object System.Drawing.Point(20, 320)
    $CertGroupBox.BackColor = $Colors.DarkSurface
    $CertGroupBox.ForeColor = $Colors.WhiteText
    
    # Certificate type selection
    $CertTypeLabel = New-Object System.Windows.Forms.Label
    $CertTypeLabel.Text = "Certificate Type:"
    $CertTypeLabel.Location = New-Object System.Drawing.Point(20, 30)
    $CertTypeLabel.Size = New-Object System.Drawing.Size(150, 20)
    $CertTypeLabel.ForeColor = $Colors.WhiteText
    
    $Script:CertTypeComboBox = New-Object System.Windows.Forms.ComboBox
    $Script:CertTypeComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $Script:CertTypeComboBox.Items.AddRange(@(
        "Self-Signed SSL (Testing/Incident Response)",
        "Let's Encrypt (Automatic Production Certificates)",
        "Custom/Corporate Certificates"
    ))
    $Script:CertTypeComboBox.SelectedIndex = 0  # Default to Self-Signed
    $Script:CertTypeComboBox.Location = New-Object System.Drawing.Point(180, 28)
    $Script:CertTypeComboBox.Size = New-Object System.Drawing.Size(350, 25)
    $Script:CertTypeComboBox.BackColor = $Colors.DarkBackground
    $Script:CertTypeComboBox.ForeColor = $Colors.WhiteText
    
    # Certificate duration selection
    $CertDurationLabel = New-Object System.Windows.Forms.Label
    $CertDurationLabel.Text = "Certificate Duration:"
    $CertDurationLabel.Location = New-Object System.Drawing.Point(20, 70)
    $CertDurationLabel.Size = New-Object System.Drawing.Size(150, 20)
    $CertDurationLabel.ForeColor = $Colors.WhiteText
    
    $Script:CertDurationComboBox = New-Object System.Windows.Forms.ComboBox
    $Script:CertDurationComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $Script:CertDurationComboBox.Items.AddRange(@(
        "1 Year (Recommended for Testing)",
        "5 Years (Medium-term Deployment)", 
        "10 Years (Long-term Deployment)",
        "Custom Duration"
    ))
    $Script:CertDurationComboBox.SelectedIndex = 0  # Default to 1 year
    $Script:CertDurationComboBox.Location = New-Object System.Drawing.Point(180, 68)
    $Script:CertDurationComboBox.Size = New-Object System.Drawing.Size(250, 25)
    $Script:CertDurationComboBox.BackColor = $Colors.DarkBackground
    $Script:CertDurationComboBox.ForeColor = $Colors.WhiteText
    
    # Let's Encrypt domain field (initially hidden)
    $Script:DomainLabel = New-Object System.Windows.Forms.Label
    $Script:DomainLabel.Text = "Domain Name:"
    $Script:DomainLabel.Location = New-Object System.Drawing.Point(20, 110)
    $Script:DomainLabel.Size = New-Object System.Drawing.Size(150, 20)
    $Script:DomainLabel.ForeColor = $Colors.WhiteText
    $Script:DomainLabel.Visible = $false
    
    $Script:DomainTextBox = New-Object System.Windows.Forms.TextBox
    $Script:DomainTextBox.PlaceholderText = "your-server.domain.com"
    $Script:DomainTextBox.Location = New-Object System.Drawing.Point(180, 108)
    $Script:DomainTextBox.Size = New-Object System.Drawing.Size(300, 25)
    $Script:DomainTextBox.BackColor = $Colors.DarkBackground
    $Script:DomainTextBox.ForeColor = $Colors.WhiteText
    $Script:DomainTextBox.Visible = $false
    
    # Custom certificate upload (initially hidden)
    $Script:CustomCertPanel = New-Object System.Windows.Forms.Panel
    $Script:CustomCertPanel.Size = New-Object System.Drawing.Size(800, 40)
    $Script:CustomCertPanel.Location = New-Object System.Drawing.Point(20, 110)
    $Script:CustomCertPanel.BackColor = $Colors.DarkBackground
    $Script:CustomCertPanel.Visible = $false
    
    Add-CustomCertificateFields $Script:CustomCertPanel
    
    # Certificate type change handler
    $Script:CertTypeComboBox.Add_SelectedIndexChanged({
        $certType = $Script:CertTypeComboBox.SelectedIndex
        
        # Show/hide fields based on certificate type
        $Script:DomainLabel.Visible = ($certType -eq 1)  # Let's Encrypt
        $Script:DomainTextBox.Visible = ($certType -eq 1)
        $Script:CustomCertPanel.Visible = ($certType -eq 2)  # Custom
        
        # Update certificate duration options
        if ($certType -eq 1) {  # Let's Encrypt
            $Script:CertDurationComboBox.Items.Clear()
            $Script:CertDurationComboBox.Items.Add("90 Days (Let's Encrypt Auto-Renewal)")
            $Script:CertDurationComboBox.SelectedIndex = 0
            $Script:CertDurationComboBox.Enabled = $false
        } else {
            $Script:CertDurationComboBox.Enabled = $true
        }
    })
    
    $CertGroupBox.Controls.AddRange(@(
        $CertTypeLabel, $Script:CertTypeComboBox,
        $CertDurationLabel, $Script:CertDurationComboBox,
        $Script:DomainLabel, $Script:DomainTextBox,
        $Script:CustomCertPanel
    ))
    
    $ParentPanel.Controls.Add($CertGroupBox)
}
```

---

## 3. NETWORK CONFIGURATION ENHANCEMENT

### Current Status: BASIC (only paths configured)
### Priority: MEDIUM - Add port and DNS configuration

```powershell
# Enhance existing network configuration
function Add-NetworkConfigurationPanel {
    param($ParentPanel)
    
    $NetworkGroupBox = New-Object System.Windows.Forms.GroupBox
    $NetworkGroupBox.Text = "Network Configuration"
    $NetworkGroupBox.Size = New-Object System.Drawing.Size(840, 160)
    $NetworkGroupBox.Location = New-Object System.Drawing.Point(20, 520)
    $NetworkGroupBox.BackColor = $Colors.DarkSurface
    $NetworkGroupBox.ForeColor = $Colors.WhiteText
    
    # Public DNS/IP field
    $PublicDNSLabel = New-Object System.Windows.Forms.Label
    $PublicDNSLabel.Text = "Public DNS/IP:"
    $PublicDNSLabel.Location = New-Object System.Drawing.Point(20, 30)
    $PublicDNSLabel.Size = New-Object System.Drawing.Size(120, 20)
    $PublicDNSLabel.ForeColor = $Colors.WhiteText
    
    $Script:PublicDNSTextBox = New-Object System.Windows.Forms.TextBox
    $Script:PublicDNSTextBox.Text = "127.0.0.1"
    $Script:PublicDNSTextBox.Location = New-Object System.Drawing.Point(150, 28)
    $Script:PublicDNSTextBox.Size = New-Object System.Drawing.Size(200, 25)
    $Script:PublicDNSTextBox.BackColor = $Colors.DarkBackground
    $Script:PublicDNSTextBox.ForeColor = $Colors.WhiteText
    
    # Frontend port
    $FrontendPortLabel = New-Object System.Windows.Forms.Label
    $FrontendPortLabel.Text = "Frontend Port:"
    $FrontendPortLabel.Location = New-Object System.Drawing.Point(380, 30)
    $FrontendPortLabel.Size = New-Object System.Drawing.Size(100, 20)
    $FrontendPortLabel.ForeColor = $Colors.WhiteText
    
    $Script:FrontendPortTextBox = New-Object System.Windows.Forms.TextBox
    $Script:FrontendPortTextBox.Text = "8000"
    $Script:FrontendPortTextBox.Location = New-Object System.Drawing.Point(490, 28)
    $Script:FrontendPortTextBox.Size = New-Object System.Drawing.Size(80, 25)
    $Script:FrontendPortTextBox.BackColor = $Colors.DarkBackground
    $Script:FrontendPortTextBox.ForeColor = $Colors.WhiteText
    
    # GUI port  
    $GUIPortLabel = New-Object System.Windows.Forms.Label
    $GUIPortLabel.Text = "GUI Port:"
    $GUIPortLabel.Location = New-Object System.Drawing.Point(600, 30)
    $GUIPortLabel.Size = New-Object System.Drawing.Size(80, 20)
    $GUIPortLabel.ForeColor = $Colors.WhiteText
    
    $Script:GUIPortTextBox = New-Object System.Windows.Forms.TextBox
    $Script:GUIPortTextBox.Text = "8889"
    $Script:GUIPortTextBox.Location = New-Object System.Drawing.Point(690, 28)
    $Script:GUIPortTextBox.Size = New-Object System.Drawing.Size(80, 25)
    $Script:GUIPortTextBox.BackColor = $Colors.DarkBackground
    $Script:GUIPortTextBox.ForeColor = $Colors.WhiteText
    
    # DNS server selection
    $DNSServerLabel = New-Object System.Windows.Forms.Label
    $DNSServerLabel.Text = "DNS Servers:"
    $DNSServerLabel.Location = New-Object System.Drawing.Point(20, 70)
    $DNSServerLabel.Size = New-Object System.Drawing.Size(120, 20)
    $DNSServerLabel.ForeColor = $Colors.WhiteText
    
    $Script:DNSServerComboBox = New-Object System.Windows.Forms.ComboBox
    $Script:DNSServerComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $Script:DNSServerComboBox.Items.AddRange(@(
        "System Default",
        "Cloudflare (1.1.1.1, 1.0.0.1)",
        "Google (8.8.8.8, 8.8.4.4)",
        "Quad9 (9.9.9.9, 149.112.112.112)",
        "Custom DNS Servers"
    ))
    $Script:DNSServerComboBox.SelectedIndex = 0
    $Script:DNSServerComboBox.Location = New-Object System.Drawing.Point(150, 68)
    $Script:DNSServerComboBox.Size = New-Object System.Drawing.Size(250, 25)
    $Script:DNSServerComboBox.BackColor = $Colors.DarkBackground
    $Script:DNSServerComboBox.ForeColor = $Colors.WhiteText
    
    # Custom DNS field (initially hidden)
    $Script:CustomDNSTextBox = New-Object System.Windows.Forms.TextBox
    $Script:CustomDNSTextBox.PlaceholderText = "1.1.1.1,8.8.8.8"
    $Script:CustomDNSTextBox.Location = New-Object System.Drawing.Point(420, 68)
    $Script:CustomDNSTextBox.Size = New-Object System.Drawing.Size(200, 25)
    $Script:CustomDNSTextBox.BackColor = $Colors.DarkBackground
    $Script:CustomDNSTextBox.ForeColor = $Colors.WhiteText
    $Script:CustomDNSTextBox.Visible = $false
    
    # DNS selection handler
    $Script:DNSServerComboBox.Add_SelectedIndexChanged({
        $Script:CustomDNSTextBox.Visible = ($Script:DNSServerComboBox.SelectedIndex -eq 4)
    })
    
    # Bind address selection
    $BindAddressLabel = New-Object System.Windows.Forms.Label
    $BindAddressLabel.Text = "Bind Address:"
    $BindAddressLabel.Location = New-Object System.Drawing.Point(20, 110)
    $BindAddressLabel.Size = New-Object System.Drawing.Size(120, 20)
    $BindAddressLabel.ForeColor = $Colors.WhiteText
    
    $Script:BindAddressComboBox = New-Object System.Windows.Forms.ComboBox
    $Script:BindAddressComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $Script:BindAddressComboBox.Items.AddRange(@(
        "127.0.0.1 (Localhost Only)",
        "0.0.0.0 (All Interfaces)"
    ))
    $Script:BindAddressComboBox.SelectedIndex = 0
    $Script:BindAddressComboBox.Location = New-Object System.Drawing.Point(150, 108)
    $Script:BindAddressComboBox.Size = New-Object System.Drawing.Size(200, 25)
    $Script:BindAddressComboBox.BackColor = $Colors.DarkBackground
    $Script:BindAddressComboBox.ForeColor = $Colors.WhiteText
    
    $NetworkGroupBox.Controls.AddRange(@(
        $PublicDNSLabel, $Script:PublicDNSTextBox,
        $FrontendPortLabel, $Script:FrontendPortTextBox,
        $GUIPortLabel, $Script:GUIPortTextBox,
        $DNSServerLabel, $Script:DNSServerComboBox, $Script:CustomDNSTextBox,
        $BindAddressLabel, $Script:BindAddressComboBox
    ))
    
    $ParentPanel.Controls.Add($NetworkGroupBox)
}
```

---

## 4. CONFIGURATION GENERATION FUNCTION

### Current Status: MISSING - Need to integrate configuration building

```powershell
# Enhanced configuration generation
function Build-VelociraptorConfiguration {
    [CmdletBinding()]
    param()
    
    try {
        Write-LogToGUI "Building Velociraptor configuration..." -Level 'Info'
        
        # Gather all configuration parameters
        $config = @{
            Authentication = @{
                Type = $Script:AuthTypeComboBox.SelectedItem.ToString()
                Username = $Script:AdminUserTextBox.Text
                Password = $Script:AdminPasswordTextBox.Text
            }
            Certificates = @{
                Type = $Script:CertTypeComboBox.SelectedItem.ToString()
                Duration = $Script:CertDurationComboBox.SelectedItem.ToString()
                Domain = $Script:DomainTextBox.Text
            }
            Network = @{
                PublicDNS = $Script:PublicDNSTextBox.Text
                FrontendPort = $Script:FrontendPortTextBox.Text
                GUIPort = $Script:GUIPortTextBox.Text
                DNSServers = $Script:DNSServerComboBox.SelectedItem.ToString()
                BindAddress = $Script:BindAddressComboBox.SelectedItem.ToString()
            }
            Paths = @{
                InstallDir = $Script:InstallDir
                DataStore = $Script:DataStore
            }
        }
        
        # Validate configuration
        $validation = Test-ConfigurationValid $config
        if (-not $validation.IsValid) {
            throw "Configuration validation failed: $($validation.Errors -join ', ')"
        }
        
        # Generate configuration file
        $configPath = Join-Path $Script:DataStore "server.config.yaml"
        Generate-ConfigurationFile -Config $config -OutputPath $configPath
        
        Write-LogToGUI "Configuration generated successfully: $configPath" -Level 'Success'
        return $configPath
        
    } catch {
        Write-LogToGUI "Configuration generation failed: $($_.Exception.Message)" -Level 'Error'
        throw
    }
}

function Test-ConfigurationValid {
    param([hashtable]$Config)
    
    $errors = @()
    $warnings = @()
    
    # Validate authentication
    if ([string]::IsNullOrWhiteSpace($Config.Authentication.Username)) {
        $errors += "Admin username is required"
    }
    
    if ($Config.Authentication.Type -eq "Basic Authentication (Username/Password)" -and 
        [string]::IsNullOrWhiteSpace($Config.Authentication.Password)) {
        $errors += "Admin password is required for basic authentication"
    }
    
    # Validate network settings
    try {
        [int]$frontendPort = $Config.Network.FrontendPort
        if ($frontendPort -lt 1 -or $frontendPort -gt 65535) {
            $errors += "Frontend port must be between 1 and 65535"
        }
    } catch {
        $errors += "Frontend port must be a valid number"
    }
    
    try {
        [int]$guiPort = $Config.Network.GUIPort
        if ($guiPort -lt 1 -or $guiPort -gt 65535) {
            $errors += "GUI port must be between 1 and 65535"
        }
    } catch {
        $errors += "GUI port must be a valid number"
    }
    
    # Validate Let's Encrypt domain
    if ($Config.Certificates.Type -eq "Let's Encrypt (Automatic Production Certificates)" -and
        [string]::IsNullOrWhiteSpace($Config.Certificates.Domain)) {
        $errors += "Domain name is required for Let's Encrypt certificates"
    }
    
    return @{
        IsValid = ($errors.Count -eq 0)
        Errors = $errors
        Warnings = $warnings
    }
}
```

---

## 5. INTEGRATION WITH EXISTING INSTALLATION

### Modify existing installation function to use configuration

```powershell
# Enhanced installation function
function Start-VelociraptorInstallationWithConfig {
    try {
        Write-LogToGUI "=== STARTING CONFIGURED VELOCIRAPTOR INSTALLATION ===" -Level 'Success'
        
        # Step 1: Generate configuration
        $configPath = Build-VelociraptorConfiguration
        
        # Step 2: Download and install executable (existing logic)
        $executablePath = Join-Path $Script:InstallDir 'velociraptor.exe'
        $assetInfo = Get-LatestVelociraptorAsset
        $success = Install-VelociraptorExecutable -AssetInfo $assetInfo -DestinationPath $executablePath
        
        if ($success) {
            # Step 3: Run configuration generation with Velociraptor
            Write-LogToGUI "Generating Velociraptor configuration with selected options..." -Level 'Info'
            
            $configArgs = Build-ConfigurationArguments
            $configProcess = Start-Process $executablePath -ArgumentList $configArgs -Wait -PassThru -NoNewWindow
            
            if ($configProcess.ExitCode -eq 0) {
                Write-LogToGUI "=== INSTALLATION AND CONFIGURATION COMPLETED SUCCESSFULLY ===" -Level 'Success'
                
                # Show configuration summary
                Show-ConfigurationSummary $configPath
                
            } else {
                throw "Velociraptor configuration generation failed with exit code: $($configProcess.ExitCode)"
            }
        }
        
    } catch {
        Write-LogToGUI "Installation failed - $($_.Exception.Message)" -Level 'Error'
        throw
    }
}

function Build-ConfigurationArguments {
    # Build command line arguments for velociraptor config generate
    $args = @("config", "generate")
    
    # Add authentication parameters
    $authType = $Script:AuthTypeComboBox.SelectedIndex
    switch ($authType) {
        0 { $args += @("--auth", "basic") }
        1 { $args += @("--auth", "google") }
        2 { $args += @("--auth", "azure") }
        3 { $args += @("--auth", "github") }
        4 { $args += @("--auth", "saml") }
        5 { $args += @("--auth", "oidc") }
    }
    
    # Add certificate parameters
    $certType = $Script:CertTypeComboBox.SelectedIndex
    switch ($certType) {
        0 { $args += @("--cert-type", "self-signed") }
        1 { 
            $args += @("--cert-type", "letsencrypt")
            $args += @("--domain", $Script:DomainTextBox.Text)
        }
        2 { $args += @("--cert-type", "custom") }
    }
    
    # Add network parameters
    $args += @("--frontend-port", $Script:FrontendPortTextBox.Text)
    $args += @("--gui-port", $Script:GUIPortTextBox.Text)
    $args += @("--public-dns", $Script:PublicDNSTextBox.Text)
    
    # Output path
    $configPath = Join-Path $Script:DataStore "server.config.yaml"
    $args += @("--output", $configPath)
    
    return $args
}
```

---

## Implementation Priority

1. **IMMEDIATE** (This Week):
   - Add Authentication Panel with password configuration
   - Add Certificate Type selection (self-signed, Let's Encrypt, custom)
   - Add Certificate Duration options (1, 5, 10 years)

2. **SHORT-TERM** (Next Week):
   - Add Network Configuration enhancement (ports, DNS)
   - Integrate configuration building with installation
   - Add real-time validation

3. **MEDIUM-TERM** (Following Weeks):
   - Add full SSO configuration wizard
   - Add advanced security options
   - Add configuration preview and editing

This implementation guide provides the specific code and structure needed to enhance your current GUI to cover the missing configuration options from `velociraptor.exe config generate -i`.