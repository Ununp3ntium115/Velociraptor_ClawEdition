function New-VelociraptorConfigurationTemplate {
    <#
    .SYNOPSIS
        Generates Velociraptor configuration templates for different deployment scenarios.

    .DESCRIPTION
        Creates pre-configured YAML templates for various Velociraptor deployment
        scenarios including standalone, server, cluster, and specialized configurations.

    .PARAMETER TemplateName
        Template type: Standalone, Server, Cluster, Forensics, or Enterprise.

    .PARAMETER OutputPath
        Directory where the template file will be created.

    .PARAMETER CustomSettings
        Hashtable of custom settings to override template defaults.

    .PARAMETER IncludeComments
        Include detailed comments in the generated template.

    .PARAMETER Force
        Overwrite existing template files without prompting.

    .EXAMPLE
        New-VelociraptorConfigurationTemplate -TemplateName Server -OutputPath "C:\configs"

    .EXAMPLE
        New-VelociraptorConfigurationTemplate -TemplateName Standalone -CustomSettings @{GuiPort=9999} -IncludeComments

    .OUTPUTS
        PSCustomObject with template generation results including file path and settings.

    .NOTES
        Generated templates should be customized before use in production environments.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Standalone', 'Server', 'Cluster', 'Forensics', 'Enterprise')]
        [string]$TemplateName,

        [Parameter()]
        [string]$OutputPath = '.',

        [Parameter()]
        [hashtable]$CustomSettings = @{},

        [Parameter()]
        [switch]$IncludeComments = $true,

        [Parameter()]
        [switch]$Force
    )

    try {
        Write-VelociraptorLog "Generating $TemplateName configuration template" -Level Info

        # Ensure output directory exists
        if (-not (Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }

        # Generate template filename
        $templateFileName = "$($TemplateName.ToLower())_template.yaml"
        $templatePath = Join-Path $OutputPath $templateFileName

        # Check if file exists
        if (Test-Path $templatePath -and -not $Force) {
            $overwrite = Read-VelociraptorUserInput -Prompt "Template file exists. Overwrite?" -DefaultValue "N" -ValidValues @("Y", "N")
            if ($overwrite -eq "N") {
                throw "Template generation cancelled by user"
            }
        }

        # Get template content based on type
        $templateContent = switch ($TemplateName) {
            'Standalone' { Get-StandaloneTemplate $CustomSettings $IncludeComments }
            'Server' { Get-ServerTemplate $CustomSettings $IncludeComments }
            'Cluster' { Get-ClusterTemplate $CustomSettings $IncludeComments }
            'Forensics' { Get-ForensicsTemplate $CustomSettings $IncludeComments }
            'Enterprise' { Get-EnterpriseTemplate $CustomSettings $IncludeComments }
        }

        # Write template to file
        $templateContent | Out-File -FilePath $templatePath -Encoding UTF8

        # Validate generated template
        $validation = Test-VelociraptorConfiguration -ConfigPath $templatePath -ValidationLevel Basic -OutputFormat Object

        # Create result object
        $result = [PSCustomObject]@{
            Success = $true
            TemplateName = $TemplateName
            TemplatePath = $templatePath
            TemplateSize = (Get-Item $templatePath).Length
            ValidationResult = $validation
            CustomSettings = $CustomSettings
            GenerationDate = Get-Date
        }

        Write-VelociraptorLog "Template generated successfully: $templatePath" -Level Success

        if (-not $validation.IsValid) {
            Write-VelociraptorLog "Warning: Generated template has validation issues" -Level Warning
        }

        return $result
    }
    catch {
        $errorMessage = "Template generation failed: $($_.Exception.Message)"
        Write-VelociraptorLog $errorMessage -Level Error

        return [PSCustomObject]@{
            Success = $false
            TemplateName = $TemplateName
            Error = $_.Exception.Message
            GenerationDate = Get-Date
        }
    }
}

# Helper method for Standalone template
function Get-StandaloneTemplate {
    param($customSettings, $includeComments)

    $guiPort = $customSettings.GuiPort ?? 8889
    $datastore = $customSettings.Datastore ?? 'C:\VelociraptorData'

    $comments = if ($includeComments) {
        @"
# Velociraptor Standalone Configuration Template
# This template creates a simple standalone Velociraptor instance
# suitable for single-user forensic analysis and testing.
#
# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# Template Type: Standalone
#
# IMPORTANT: Customize the settings below before use!

"@
    } else { "" }

    return @"
$comments
version:
  name: VelociraptorStandalone
  version: "0.7.0"
  built_time: "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# GUI Configuration - Web interface for analysis
GUI:
  bind_address: 127.0.0.1
  bind_port: $guiPort
  gw_certificate: ""
  gw_private_key: ""

# Client Configuration - Not used in standalone mode
Client:
  server_urls: []

# Datastore Configuration - Local storage
Datastore:
  implementation: FileBaseDataStore
  location: "$datastore"
  filestore_directory: "$datastore\filestore"

# Logging Configuration
Logging:
  output_directory: "$datastore\logs"
  separate_logs_per_component: true

# Default user (change password immediately!)
GUI:
  initial_users:
  - name: admin
    password_hash: ""  # Will be generated on first run

# Security Settings
autocert_domain: localhost
"@
}

# Helper method for Server template
function Get-ServerTemplate {
    param($customSettings, $includeComments)

    $frontendPort = $customSettings.FrontendPort ?? 8000
    $guiPort = $customSettings.GuiPort ?? 8889
    $datastore = $customSettings.Datastore ?? 'C:\VelociraptorServerData'

    $comments = if ($includeComments) {
        @"
# Velociraptor Server Configuration Template
# This template creates a full Velociraptor server deployment
# suitable for enterprise environments with multiple clients.
#
# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# Template Type: Server
#
# IMPORTANT: Customize the settings below before use!

"@
    } else { "" }

    return @"
$comments
version:
  name: VelociraptorServer
  version: "0.7.0"
  built_time: "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Frontend Configuration - Client connections
Frontend:
  bind_address: 0.0.0.0
  bind_port: $frontendPort
  certificate: ""
  private_key: ""

# GUI Configuration - Web interface
GUI:
  bind_address: 0.0.0.0
  bind_port: $guiPort
  gw_certificate: ""
  gw_private_key: ""

# Client Configuration
Client:
  server_urls:
  - "https://localhost:$frontendPort/"

# Datastore Configuration
Datastore:
  implementation: FileBaseDataStore
  location: "$datastore"
  filestore_directory: "$datastore\filestore"

# Logging Configuration
Logging:
  output_directory: "$datastore\logs"
  separate_logs_per_component: true

# Security Settings
autocert_domain: ""  # Set to your domain
autocert_cert_cache: "$datastore\acme"

# Default admin user
GUI:
  initial_users:
  - name: admin
    password_hash: ""  # Will be generated on first run
"@
}

# Helper method for other templates (simplified for space)
function Get-ClusterTemplate { param($customSettings, $includeComments); return "# Cluster template - Implementation needed" }
function Get-ForensicsTemplate { param($customSettings, $includeComments); return "# Forensics template - Implementation needed" }
function Get-EnterpriseTemplate { param($customSettings, $includeComments); return "# Enterprise template - Implementation needed" }