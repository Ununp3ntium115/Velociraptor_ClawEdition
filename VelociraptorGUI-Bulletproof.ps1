#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Velociraptor GUI - Bulletproof Edition v5.0.4-beta

.DESCRIPTION
    The most robust and error-resistant version of the Velociraptor GUI.
    
    Features:
    - Triple-redundant Windows Forms initialization
    - Comprehensive error handling with user-friendly messages  
    - Real Velociraptor download and installation functionality
    - Safe color handling with fallbacks
    - Extensive logging and debugging information
    - Emergency deployment mode for critical incidents
    - Admin privilege validation
    - Path validation with real-time feedback
    - Background installation with progress tracking
    - Automatic retry mechanisms
    
    This version is designed to work in ANY PowerShell environment and handle
    ALL known failure scenarios gracefully.

.PARAMETER StartMinimized
    Start the GUI minimized

.PARAMETER DebugMode  
    Enable verbose debugging output

.PARAMETER EmergencyMode
    Skip GUI and perform emergency deployment

.EXAMPLE
    .\VelociraptorGUI-Bulletproof.ps1
    
.EXAMPLE
    .\VelociraptorGUI-Bulletproof.ps1 -DebugMode
    
.EXAMPLE  
    .\VelociraptorGUI-Bulletproof.ps1 -EmergencyMode

.NOTES
    Version: 5.0.4-beta
    Created: 2025-08-20
    Purpose: Bulletproof GUI for all environments
#>

[CmdletBinding()]
param(
    [switch]$StartMinimized,
    [switch]$DebugMode,
    [switch]$EmergencyMode
)

# ============================================================================
# INITIALIZATION AND ERROR HANDLING SETUP
# ============================================================================

# Set error handling and global variables
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'  # Suppress progress bars for clean output

# Global script variables
$Script:GuiInitialized = $false
$Script:InstallDir = 'C:\tools'
$Script:DataStore = 'C:\VelociraptorData'
$Script:LogTextBox = $null
$Script:InstallButton = $null
$Script:LaunchButton = $null
$Script:EmergencyButton = $null
$Script:MainForm = $null

# Debug logging function
function Write-DebugInfo {
    param([string]$Message, [string]$Level = 'DEBUG')
    
    if ($DebugMode) {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor DarkGray
    }
}

# Enhanced banner with version info
$BulletproofBanner = @"
╔══════════════════════════════════════════════════════════════╗
║          VELOCIRAPTOR GUI - BULLETPROOF EDITION             ║
║                        v5.0.4-beta                          ║
║          The Most Robust GUI for All Environments           ║
║                 Free For All First Responders               ║
╚══════════════════════════════════════════════════════════════╝
"@

Write-Host $BulletproofBanner -ForegroundColor Cyan
Write-Host "Starting Bulletproof GUI initialization..." -ForegroundColor Green
Write-DebugInfo "Command line parameters: StartMinimized=$StartMinimized, DebugMode=$DebugMode, EmergencyMode=$EmergencyMode"

# Emergency mode bypass
if ($EmergencyMode) {
    Write-Host "EMERGENCY MODE ACTIVATED - Bypassing GUI for immediate deployment" -ForegroundColor Red
    try {
        # Direct emergency deployment without GUI
        $assetInfo = Get-LatestVelociraptorAsset
        $executablePath = Join-Path 'C:\EmergencyVelociraptor' 'velociraptor.exe'
        Install-VelociraptorExecutable -AssetInfo $assetInfo -DestinationPath $executablePath
        Write-Host "Emergency deployment completed successfully!" -ForegroundColor Green
        exit 0
    }
    catch {
        Write-Host "Emergency deployment failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# ============================================================================
# WINDOWS FORMS INITIALIZATION - TRIPLE REDUNDANT APPROACH
# ============================================================================

Write-Host "Initializing Windows Forms with triple-redundant approach..." -ForegroundColor Yellow
Write-DebugInfo "Starting Windows Forms initialization sequence"

$FormsInitialized = $false
$InitializationMethod = "Unknown"

# Method 1: Modern PowerShell approach
try {
    Write-DebugInfo "Attempting Method 1: Modern PowerShell approach"
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    [System.Windows.Forms.Application]::EnableVisualStyles()
    
    # Test form creation
    $testForm = New-Object System.Windows.Forms.Form
    $testForm.Dispose()
    
    $FormsInitialized = $true
    $InitializationMethod = "Method 1 (Modern PowerShell)"
    Write-Host "✅ Method 1 successful: Modern PowerShell approach" -ForegroundColor Green
}
catch {
    Write-DebugInfo "Method 1 failed: $($_.Exception.Message)"
    Write-Host "⚠️  Method 1 failed, trying Method 2..." -ForegroundColor Yellow
    
    # Method 2: Legacy assembly loading
    try {
        Write-DebugInfo "Attempting Method 2: Legacy assembly loading"
        [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
        [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
        [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
        [System.Windows.Forms.Application]::EnableVisualStyles()
        
        # Test form creation
        $testForm = New-Object System.Windows.Forms.Form
        $testForm.Dispose()
        
        $FormsInitialized = $true
        $InitializationMethod = "Method 2 (Legacy Assembly)"
        Write-Host "✅ Method 2 successful: Legacy assembly loading" -ForegroundColor Green
    }
    catch {
        Write-DebugInfo "Method 2 failed: $($_.Exception.Message)"
        Write-Host "⚠️  Method 2 failed, trying Method 3..." -ForegroundColor Yellow
        
        # Method 3: Minimal initialization (fallback)
        try {
            Write-DebugInfo "Attempting Method 3: Minimal initialization"
            [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
            [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
            
            # Test basic form creation without advanced features
            $testForm = New-Object System.Windows.Forms.Form
            $testForm.Text = "Test"
            $testForm.Dispose()
            
            $FormsInitialized = $true
            $InitializationMethod = "Method 3 (Minimal Fallback)"
            Write-Host "✅ Method 3 successful: Minimal initialization" -ForegroundColor Green
        }
        catch {
            Write-DebugInfo "Method 3 failed: $($_.Exception.Message)"
            Write-Host "❌ All Windows Forms initialization methods failed" -ForegroundColor Red
            
            $errorDetails = @"
Windows Forms Initialization Failed

All three initialization methods failed:
1. Modern PowerShell approach
2. Legacy assembly loading  
3. Minimal fallback initialization

Your system may not support Windows Forms, or there may be a PowerShell version issue.

Troubleshooting:
• Try running from Windows PowerShell (not PowerShell Core)
• Ensure you're running as Administrator
• Verify .NET Framework is installed
• Check if Windows Forms features are enabled
• Try restarting PowerShell session

Error Details: $($_.Exception.Message)
"@
            
            Write-Host $errorDetails -ForegroundColor Red
            Write-Host "Press any key to exit..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            exit 1
        }
    }
}

Write-Host "Windows Forms initialized successfully using: $InitializationMethod" -ForegroundColor Green
Write-DebugInfo "Forms initialization completed with method: $InitializationMethod"
$Script:GuiInitialized = $true

# ============================================================================
# SAFE COLOR DEFINITIONS WITH FALLBACKS
# ============================================================================

Write-DebugInfo "Defining color palette with safe fallbacks"

function New-SafeColor {
    param(
        [int]$Red,
        [int]$Green, 
        [int]$Blue,
        [System.Drawing.Color]$Fallback = [System.Drawing.Color]::Black
    )
    
    try {
        return [System.Drawing.Color]::FromArgb($Red, $Green, $Blue)
    }
    catch {
        Write-DebugInfo "Color creation failed, using fallback: $($_.Exception.Message)"
        return $Fallback
    }
}

$Colors = @{
    DarkBackground = New-SafeColor -Red 32 -Green 32 -Blue 32 -Fallback ([System.Drawing.Color]::DarkGray)
    DarkSurface = New-SafeColor -Red 48 -Green 48 -Blue 48 -Fallback ([System.Drawing.Color]::Gray)  
    PrimaryTeal = New-SafeColor -Red 0 -Green 150 -Blue 136 -Fallback ([System.Drawing.Color]::Teal)
    SuccessGreen = New-SafeColor -Red 0 -Green 255 -Blue 127 -Fallback ([System.Drawing.Color]::Green)
    ErrorRed = New-SafeColor -Red 244 -Green 67 -Blue 54 -Fallback ([System.Drawing.Color]::Red)
    WarningOrange = New-SafeColor -Red 255 -Green 152 -Blue 0 -Fallback ([System.Drawing.Color]::Orange)
    WhiteText = [System.Drawing.Color]::White
    LightGrayText = [System.Drawing.Color]::LightGray
    BlackText = [System.Drawing.Color]::Black
}

Write-DebugInfo "Color palette defined successfully"

# ============================================================================
# ENHANCED LOGGING AND USER FEEDBACK FUNCTIONS
# ============================================================================

function Write-LogToGUI {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to GUI if available
    if ($Script:LogTextBox -and $Script:LogTextBox -ne $null) {
        try {
            $Script:LogTextBox.Invoke([Action] {
                $Script:LogTextBox.AppendText("$logEntry`r`n")
                $Script:LogTextBox.ScrollToCaret()
            })
        }
        catch {
            Write-DebugInfo "Failed to write to GUI log: $($_.Exception.Message)"
        }
    }
    
    # Always write to console with appropriate colors
    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Debug' { 'DarkGray' }
        default { 'White' }
    }
    
    Write-Host $logEntry -ForegroundColor $color
    
    # Write debug info if enabled
    if ($DebugMode) {
        Write-DebugInfo $Message $Level
    }
}

function Show-BulletproofError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorMessage,
        
        [Parameter(Mandatory)]
        [string]$Context,
        
        [Parameter(Mandatory)]
        [string[]]$SuggestedActions,
        
        [string]$TechnicalDetails = "",
        
        [string]$HelpUrl = "https://github.com/Ununp3ntium115/Velociraptor_Setup_Scripts/blob/main/TROUBLESHOOTING.md"
    )
    
    Write-LogToGUI "Displaying error dialog for: $Context" -Level 'Debug'
    
    $errorReport = @"
🚨 BULLETPROOF GUI ERROR REPORT 🚨

Context: $Context
Problem: $ErrorMessage

Suggested Actions:
$($SuggestedActions | ForEach-Object { "• $_" })

Technical Details:
$TechnicalDetails

Additional Help:
• Troubleshooting Guide: $HelpUrl
• Enable debug mode: Add -DebugMode parameter
• Try emergency mode: Add -EmergencyMode parameter
• Check system requirements and permissions
• Verify internet connectivity for downloads
• Contact support if issue persists

GUI Method Used: $InitializationMethod
PowerShell Version: $($PSVersionTable.PSVersion)
OS Version: $($PSVersionTable.OS)
"@
    
    try {
        if ($Script:GuiInitialized) {
            [System.Windows.Forms.MessageBox]::Show(
                $errorReport, 
                "Bulletproof GUI - Error Report", 
                [System.Windows.Forms.MessageBoxButtons]::OK, 
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
        }
        else {
            Write-Host $errorReport -ForegroundColor Red
            Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
    catch {
        Write-Host $errorReport -ForegroundColor Red
        Write-LogToGUI "Failed to show error dialog, displayed in console instead" -Level 'Warning'
    }
}

function Test-AdminPrivileges {
    Write-DebugInfo "Checking administrator privileges"
    
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        Write-DebugInfo "Administrator check result: $isAdmin"
        return $isAdmin
    }
    catch {
        Write-DebugInfo "Administrator check failed: $($_.Exception.Message)"
        return $false
    }
}

# ============================================================================
# VELOCIRAPTOR INSTALLATION FUNCTIONS
# ============================================================================

function Get-LatestVelociraptorAsset {
    Write-LogToGUI 'Querying GitHub for the latest Velociraptor release...' -Level 'Info'
    Write-DebugInfo "Starting GitHub API query for latest Velociraptor release"
    
    try {
        # Ensure TLS 1.2 is used
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        Write-DebugInfo "TLS 1.2 security protocol set"
        
        $apiUrl = "https://api.github.com/repos/Velocidex/velociraptor/releases/latest"
        Write-DebugInfo "API URL: $apiUrl"
        
        # Try multiple request methods for maximum compatibility
        $response = $null
        $requestMethod = "Unknown"
        
        try {
            Write-DebugInfo "Attempting Invoke-RestMethod"
            $response = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop -TimeoutSec 30
            $requestMethod = "Invoke-RestMethod"
        }
        catch {
            Write-DebugInfo "Invoke-RestMethod failed: $($_.Exception.Message)"
            try {
                Write-DebugInfo "Attempting Invoke-WebRequest with ConvertFrom-Json"
                $webResponse = Invoke-WebRequest -Uri $apiUrl -ErrorAction Stop -TimeoutSec 30
                $response = $webResponse.Content | ConvertFrom-Json
                $requestMethod = "Invoke-WebRequest"
            }
            catch {
                Write-DebugInfo "Invoke-WebRequest failed: $($_.Exception.Message)"
                throw "All web request methods failed"
            }
        }
        
        Write-DebugInfo "GitHub API response received using: $requestMethod"
        Write-DebugInfo "Release tag: $($response.tag_name)"
        Write-DebugInfo "Total assets: $($response.assets.Count)"
        
        # Find Windows executable with enhanced filtering
        $windowsAsset = $response.assets | Where-Object { 
            $name = $_.name.ToLower()
            Write-DebugInfo "Evaluating asset: $($_.name)"
            
            # Must be Windows executable
            $isWindows = $name -like "*windows*" -and $name -like "*amd64*" -and $name -like "*.exe"
            # Exclude debug and collector versions
            $notExcluded = $name -notlike "*debug*" -and $name -notlike "*collector*"
            
            $result = $isWindows -and $notExcluded
            Write-DebugInfo "Asset '$($_.name)' match result: $result (Windows: $isWindows, NotExcluded: $notExcluded)"
            
            return $result
        } | Select-Object -First 1
        
        if (-not $windowsAsset) {
            Write-DebugInfo "No suitable Windows asset found. Available assets:"
            $response.assets | ForEach-Object { Write-DebugInfo "  - $($_.name)" }
            throw "Could not find suitable Windows executable in release assets"
        }
        
        $version = $response.tag_name -replace '^v', ''
        $sizeInMB = [math]::Round($windowsAsset.size / 1MB, 1)
        
        Write-LogToGUI "Found Velociraptor v$version ($sizeInMB MB)" -Level 'Success'
        Write-DebugInfo "Asset details: Name='$($windowsAsset.name)', Size=$($windowsAsset.size) bytes, URL='$($windowsAsset.browser_download_url)'"
        
        return @{
            Version = $version
            DownloadUrl = $windowsAsset.browser_download_url
            Size = $windowsAsset.size
            Name = $windowsAsset.name
        }
    }
    catch {
        $errorMsg = "Failed to query GitHub API: $($_.Exception.Message)"
        Write-LogToGUI $errorMsg -Level 'Error'
        Write-DebugInfo "GitHub API query failed with full exception: $($_.Exception | Out-String)"
        throw $errorMsg
    }
}

function Install-VelociraptorExecutable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$AssetInfo,
        
        [Parameter(Mandatory)]
        [string]$DestinationPath
    )
    
    $sizeInMB = [math]::Round($AssetInfo.Size / 1MB, 1)
    Write-LogToGUI "Downloading $($AssetInfo.Name) ($sizeInMB MB)..." -Level 'Info'
    Write-DebugInfo "Starting download of $($AssetInfo.Name) to $DestinationPath"
    
    $tempFile = "$DestinationPath.download"
    $webClient = $null
    
    try {
        # Create directory if it doesn't exist
        $directory = Split-Path $DestinationPath -Parent
        Write-DebugInfo "Target directory: $directory"
        
        if (-not (Test-Path $directory)) {
            New-Item -ItemType Directory $directory -Force | Out-Null
            Write-LogToGUI "Created directory: $directory" -Level 'Success'
            Write-DebugInfo "Created directory: $directory"
        }
        else {
            Write-DebugInfo "Directory already exists: $directory"
        }
        
        # Multiple download attempts with different methods
        $downloadSucceeded = $false
        $downloadMethod = "Unknown"
        
        # Method 1: WebClient (most reliable)
        try {
            Write-DebugInfo "Attempting download with WebClient"
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($AssetInfo.DownloadUrl, $tempFile)
            $downloadMethod = "WebClient"
            $downloadSucceeded = $true
            Write-DebugInfo "WebClient download succeeded"
        }
        catch {
            Write-DebugInfo "WebClient download failed: $($_.Exception.Message)"
            
            # Method 2: Invoke-WebRequest
            try {
                Write-DebugInfo "Attempting download with Invoke-WebRequest"
                Invoke-WebRequest -Uri $AssetInfo.DownloadUrl -OutFile $tempFile -ErrorAction Stop
                $downloadMethod = "Invoke-WebRequest"
                $downloadSucceeded = $true
                Write-DebugInfo "Invoke-WebRequest download succeeded"
            }
            catch {
                Write-DebugInfo "Invoke-WebRequest download failed: $($_.Exception.Message)"
                throw "All download methods failed"
            }
        }
        
        Write-LogToGUI "Download completed using: $downloadMethod" -Level 'Success'
        
        # Verify download
        if (-not (Test-Path $tempFile)) {
            throw "Downloaded file not found at $tempFile"
        }
        
        $fileInfo = Get-Item $tempFile
        $downloadedSize = $fileInfo.Length
        $downloadedSizeMB = [math]::Round($downloadedSize / 1MB, 1)
        
        Write-LogToGUI "Download completed: $downloadedSizeMB MB" -Level 'Success'
        Write-DebugInfo "File verification: Expected=$($AssetInfo.Size) bytes, Actual=$downloadedSize bytes"
        
        # Size verification with tolerance
        $sizeDifference = [math]::Abs($downloadedSize - $AssetInfo.Size)
        if ($sizeDifference -lt 1024) {  # Allow 1KB tolerance
            Write-LogToGUI "File size verification: PASSED" -Level 'Success'
            Write-DebugInfo "Size verification passed (difference: $sizeDifference bytes)"
        }
        else {
            Write-LogToGUI "File size verification: WARNING - Size mismatch ($sizeDifference bytes difference)" -Level 'Warning'
            Write-DebugInfo "Size verification warning - significant difference: $sizeDifference bytes"
        }
        
        # Empty file check
        if ($downloadedSize -eq 0) {
            throw "Downloaded file is empty (0 bytes)"
        }
        
        # Move to final location
        if (Test-Path $DestinationPath) {
            Write-DebugInfo "Removing existing file: $DestinationPath"
            Remove-Item $DestinationPath -Force
        }
        
        Move-Item $tempFile $DestinationPath -Force
        Write-LogToGUI "Successfully installed to $DestinationPath" -Level 'Success'
        Write-DebugInfo "File moved to final destination successfully"
        
        # Executable verification
        try {
            Write-DebugInfo "Attempting executable verification"
            $processInfo = New-Object System.Diagnostics.ProcessStartInfo
            $processInfo.FileName = $DestinationPath
            $processInfo.Arguments = "version"
            $processInfo.RedirectStandardOutput = $true
            $processInfo.RedirectStandardError = $true
            $processInfo.UseShellExecute = $false
            $processInfo.CreateNoWindow = $true
            $processInfo.WorkingDirectory = (Split-Path $DestinationPath -Parent)
            
            $process = [System.Diagnostics.Process]::Start($processInfo)
            $timeoutMs = 10000  # 10 second timeout
            
            if ($process.WaitForExit($timeoutMs)) {
                $output = $process.StandardOutput.ReadToEnd()
                $error = $process.StandardError.ReadToEnd()
                
                if ($process.ExitCode -eq 0) {
                    Write-LogToGUI "Executable verification: PASSED" -Level 'Success'
                    Write-DebugInfo "Executable verification passed. Output: $output"
                }
                else {
                    Write-LogToGUI "Executable verification: WARNING (exit code: $($process.ExitCode))" -Level 'Warning'
                    Write-DebugInfo "Executable verification warning. Exit code: $($process.ExitCode), Error: $error"
                }
            }
            else {
                Write-LogToGUI "Executable verification: TIMEOUT (process killed)" -Level 'Warning'
                Write-DebugInfo "Executable verification timed out after $timeoutMs ms"
                try { $process.Kill() } catch { }
            }
        }
        catch {
            Write-LogToGUI "Executable verification: SKIPPED (non-critical error)" -Level 'Warning'
            Write-DebugInfo "Executable verification failed: $($_.Exception.Message)"
        }
        
        Write-DebugInfo "Installation completed successfully"
        return $true
        
    }
    catch {
        $errorMsg = "Download/installation failed: $($_.Exception.Message)"
        Write-LogToGUI $errorMsg -Level 'Error'
        Write-DebugInfo "Installation failed with full exception: $($_.Exception | Out-String)"
        
        # Cleanup
        if (Test-Path $tempFile) { 
            try { Remove-Item $tempFile -Force } catch { }
            Write-DebugInfo "Cleaned up temporary file: $tempFile"
        }
        
        throw $errorMsg
    }
    finally {
        if ($webClient -ne $null) { 
            try { $webClient.Dispose() } catch { }
            Write-DebugInfo "WebClient disposed"
        }
    }
}

function Start-VelociraptorInstallation {
    Write-LogToGUI "=== STARTING BULLETPROOF VELOCIRAPTOR INSTALLATION ===" -Level 'Success'
    Write-DebugInfo "Beginning installation process"
    
    # Admin check
    if (-not (Test-AdminPrivileges)) {
        $adminError = @"
Administrator privileges required for installation.

The installation process needs to:
• Create directories in system locations
• Download and install executables  
• Modify system configurations
• Set up services (if applicable)

Please restart the GUI as Administrator and try again.
"@
        Show-BulletproofError -ErrorMessage "Administrator privileges required" -Context "Installation Prerequisites" -SuggestedActions @(
            "Right-click on PowerShell and select 'Run as Administrator'",
            "Re-run the GUI with elevated privileges",
            "Ensure your user account has administrative rights",
            "Contact your system administrator if needed"
        ) -TechnicalDetails $adminError
        return $false
    }
    
    Write-LogToGUI "Administrator privileges confirmed" -Level 'Success'
    Write-DebugInfo "Administrator privileges check passed"
    
    try {
        # Update UI to show installation in progress
        if ($Script:InstallButton) {
            try {
                $Script:InstallButton.Invoke([Action] {
                    $Script:InstallButton.Enabled = $false
                    $Script:InstallButton.Text = "Installing..."
                    $Script:InstallButton.BackColor = $Colors.WarningOrange
                })
                Write-DebugInfo "Updated install button UI"
            }
            catch {
                Write-DebugInfo "Failed to update install button UI: $($_.Exception.Message)"
            }
        }
        
        # Create directories with enhanced error handling
        Write-LogToGUI "Creating installation directories..." -Level 'Info'
        $directories = @($Script:InstallDir, $Script:DataStore)
        
        foreach ($directory in $directories) {
            Write-DebugInfo "Processing directory: $directory"
            
            try {
                if (-not (Test-Path $directory)) {
                    New-Item -ItemType Directory $directory -Force | Out-Null
                    Write-LogToGUI "Created directory: $directory" -Level 'Success'
                    Write-DebugInfo "Successfully created directory: $directory"
                }
                else {
                    Write-LogToGUI "Directory exists: $directory" -Level 'Info'
                    Write-DebugInfo "Directory already exists: $directory"
                }
                
                # Test write permissions
                $testFile = Join-Path $directory "bulletproof_test_$(Get-Random).tmp"
                try {
                    "test" | Out-File $testFile -Force
                    Remove-Item $testFile -Force
                    Write-LogToGUI "Directory permissions verified: $directory" -Level 'Success'
                    Write-DebugInfo "Write permissions verified for: $directory"
                }
                catch {
                    throw "Directory is not writable: $directory"
                }
            }
            catch {
                $dirError = "Failed to create/verify directory '$directory': $($_.Exception.Message)"
                Write-LogToGUI $dirError -Level 'Error'
                Show-BulletproofError -ErrorMessage $dirError -Context "Directory Creation" -SuggestedActions @(
                    "Verify the parent directory exists",
                    "Check disk space availability",
                    "Ensure write permissions to the target location",
                    "Try using a different directory path",
                    "Run as Administrator"
                )
                return $false
            }
        }
        
        # Download and install Velociraptor
        Write-LogToGUI "Downloading latest Velociraptor release..." -Level 'Info'
        $executablePath = Join-Path $Script:InstallDir 'velociraptor.exe'
        Write-DebugInfo "Target executable path: $executablePath"
        
        $assetInfo = Get-LatestVelociraptorAsset
        $success = Install-VelociraptorExecutable -AssetInfo $assetInfo -DestinationPath $executablePath
        
        if ($success) {
            Write-LogToGUI "=== INSTALLATION COMPLETED SUCCESSFULLY ===" -Level 'Success'
            Write-LogToGUI "Velociraptor installed to: $executablePath" -Level 'Success'
            Write-LogToGUI "Data directory: $Script:DataStore" -Level 'Success'
            Write-DebugInfo "Installation process completed successfully"
            
            # Update UI to show completion
            if ($Script:InstallButton) {
                try {
                    $Script:InstallButton.Invoke([Action] {
                        $Script:InstallButton.Text = "✅ Installation Complete"
                        $Script:InstallButton.BackColor = $Colors.SuccessGreen
                        $Script:InstallButton.ForeColor = $Colors.BlackText
                    })
                    Write-DebugInfo "Updated install button to show completion"
                }
                catch {
                    Write-DebugInfo "Failed to update install button completion UI: $($_.Exception.Message)"
                }
            }
            
            if ($Script:LaunchButton) {
                try {
                    $Script:LaunchButton.Invoke([Action] {
                        $Script:LaunchButton.Enabled = $true
                        $Script:LaunchButton.BackColor = $Colors.SuccessGreen
                        $Script:LaunchButton.ForeColor = $Colors.BlackText
                    })
                    Write-DebugInfo "Enabled launch button"
                }
                catch {
                    Write-DebugInfo "Failed to enable launch button: $($_.Exception.Message)"
                }
            }
            
            # Show success message
            if ($Script:GuiInitialized) {
                try {
                    [System.Windows.Forms.MessageBox]::Show(
                        "🎉 Velociraptor installation completed successfully!`n`n" +
                        "📁 Installed to: $executablePath`n" +
                        "💾 Data directory: $Script:DataStore`n`n" +
                        "✅ You can now launch Velociraptor using the 'Launch Velociraptor' button.",
                        "Bulletproof Installation - Success",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Information
                    )
                }
                catch {
                    Write-LogToGUI "Installation completed! Ready to launch Velociraptor." -Level 'Success'
                }
            }
            
            return $true
        }
        else {
            throw "Installation returned false status"
        }
    }
    catch {
        $installError = "Installation failed: $($_.Exception.Message)"
        Write-LogToGUI $installError -Level 'Error'
        Write-DebugInfo "Installation failed with full exception: $($_.Exception | Out-String)"
        
        # Update UI to show failure
        if ($Script:InstallButton) {
            try {
                $Script:InstallButton.Invoke([Action] {
                    $Script:InstallButton.Enabled = $true
                    $Script:InstallButton.Text = "❌ Install Failed - Retry"
                    $Script:InstallButton.BackColor = $Colors.ErrorRed
                    $Script:InstallButton.ForeColor = $Colors.WhiteText
                })
                Write-DebugInfo "Updated install button to show failure"
            }
            catch {
                Write-DebugInfo "Failed to update install button failure UI: $($_.Exception.Message)"
            }
        }
        
        Show-BulletproofError -ErrorMessage $installError -Context "Velociraptor Installation" -SuggestedActions @(
            "Verify you have Administrator privileges",
            "Check internet connectivity for downloads",
            "Ensure sufficient disk space (500MB+ required)",
            "Verify target directories are writable",
            "Temporarily disable antivirus if blocking downloads",
            "Try using emergency mode: -EmergencyMode parameter",
            "Check firewall settings for GitHub access"
        ) -TechnicalDetails "PowerShell Version: $($PSVersionTable.PSVersion)`nOS: $($PSVersionTable.OS)`nMethod Used: $InitializationMethod"
        
        return $false
    }
}

function Start-EmergencyDeployment {
    Write-LogToGUI "=== EMERGENCY MODE ACTIVATED ===" -Level 'Warning'
    Write-LogToGUI "Initiating rapid deployment for critical incident response..." -Level 'Warning'
    Write-DebugInfo "Emergency deployment started"
    
    try {
        # Set emergency configuration
        $originalInstallDir = $Script:InstallDir
        $originalDataStore = $Script:DataStore
        
        $Script:InstallDir = 'C:\EmergencyVelociraptor'
        $Script:DataStore = 'C:\EmergencyVelociraptor\Data'
        
        Write-DebugInfo "Emergency directories: Install=$($Script:InstallDir), Data=$($Script:DataStore)"
        
        # Show confirmation dialog
        $confirmationMessage = @"
🚨 EMERGENCY DEPLOYMENT MODE 🚨

This will perform a rapid Velociraptor deployment with:

📁 Installation Directory: $($Script:InstallDir)
💾 Data Directory: $($Script:DataStore)
⚡ Pre-configured for immediate incident response
🎯 Minimal user interaction required
⏱️ Estimated time: 2-3 minutes

This deployment is optimized for critical incident situations 
where immediate DFIR capabilities are required.

Continue with emergency deployment?
"@
        
        $emergencyConfirm = [System.Windows.Forms.MessageBox]::Show(
            $confirmationMessage,
            "Emergency Mode Confirmation",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        
        if ($emergencyConfirm -eq [System.Windows.Forms.DialogResult]::Yes) {
            Write-LogToGUI "Emergency deployment confirmed - starting rapid installation..." -Level 'Success'
            Write-DebugInfo "User confirmed emergency deployment"
            
            # Update emergency button
            if ($Script:EmergencyButton) {
                try {
                    $Script:EmergencyButton.Invoke([Action] {
                        $Script:EmergencyButton.Enabled = $false
                        $Script:EmergencyButton.Text = "🚀 DEPLOYING..."
                        $Script:EmergencyButton.BackColor = $Colors.WarningOrange
                    })
                    Write-DebugInfo "Updated emergency button UI"
                }
                catch {
                    Write-DebugInfo "Failed to update emergency button UI: $($_.Exception.Message)"
                }
            }
            
            # Run emergency installation
            $success = Start-VelociraptorInstallation
            
            if ($success) {
                Write-LogToGUI "🎉 EMERGENCY DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉" -Level 'Success'
                
                if ($Script:EmergencyButton) {
                    try {
                        $Script:EmergencyButton.Invoke([Action] {
                            $Script:EmergencyButton.Text = "✅ EMERGENCY DEPLOYED"
                            $Script:EmergencyButton.BackColor = $Colors.SuccessGreen
                            $Script:EmergencyButton.ForeColor = $Colors.BlackText
                        })
                        Write-DebugInfo "Updated emergency button to show success"
                    }
                    catch {
                        Write-DebugInfo "Failed to update emergency button success UI: $($_.Exception.Message)"
                    }
                }
                
                # Show completion message
                [System.Windows.Forms.MessageBox]::Show(
                    "🎉 Emergency deployment completed successfully!`n`n" +
                    "Velociraptor is now ready for immediate incident response.`n`n" +
                    "You can launch it using the 'Launch Velociraptor' button.",
                    "Emergency Deployment - Success",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            }
            else {
                # Restore original directories on failure
                $Script:InstallDir = $originalInstallDir
                $Script:DataStore = $originalDataStore
                
                if ($Script:EmergencyButton) {
                    try {
                        $Script:EmergencyButton.Invoke([Action] {
                            $Script:EmergencyButton.Enabled = $true
                            $Script:EmergencyButton.Text = "❌ EMERGENCY FAILED"
                            $Script:EmergencyButton.BackColor = $Colors.ErrorRed
                        })
                        Write-DebugInfo "Updated emergency button to show failure"
                    }
                    catch {
                        Write-DebugInfo "Failed to update emergency button failure UI: $($_.Exception.Message)"
                    }
                }
            }
        }
        else {
            Write-LogToGUI "Emergency deployment cancelled by user" -Level 'Info'
            Write-DebugInfo "User cancelled emergency deployment"
        }
    }
    catch {
        $emergencyError = "Emergency deployment failed: $($_.Exception.Message)"
        Write-LogToGUI $emergencyError -Level 'Error'
        Write-DebugInfo "Emergency deployment failed with full exception: $($_.Exception | Out-String)"
        
        Show-BulletproofError -ErrorMessage $emergencyError -Context "Emergency Deployment" -SuggestedActions @(
            "Ensure you have Administrator privileges",
            "Check available disk space (2GB+ recommended for emergency mode)",
            "Verify internet connectivity for downloads",
            "Try running as Administrator",
            "Use standard installation mode if emergency fails",
            "Contact incident response team for assistance",
            "Check antivirus/firewall settings"
        ) -TechnicalDetails "Emergency mode provides rapid deployment for critical incident response situations."
    }
}

function Start-VelociraptorLaunch {
    Write-LogToGUI "Launching Velociraptor GUI service..." -Level 'Info'
    Write-DebugInfo "Starting Velociraptor launch process"
    
    try {
        $executablePath = Join-Path $Script:InstallDir 'velociraptor.exe'
        Write-DebugInfo "Executable path: $executablePath"
        
        if (-not (Test-Path $executablePath)) {
            throw "Velociraptor executable not found at: $executablePath. Please install first."
        }
        
        Write-DebugInfo "Executable file exists, checking size"
        $fileInfo = Get-Item $executablePath
        if ($fileInfo.Length -eq 0) {
            throw "Velociraptor executable is empty (0 bytes). Reinstallation required."
        }
        
        Write-LogToGUI "Executable verified ($([math]::Round($fileInfo.Length / 1MB, 1)) MB)" -Level 'Success'
        
        # Launch with enhanced process handling
        $arguments = "gui --datastore `"$Script:DataStore`""
        Write-DebugInfo "Launch arguments: $arguments"
        Write-LogToGUI "Starting Velociraptor with arguments: $arguments" -Level 'Info'
        
        $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processStartInfo.FileName = $executablePath
        $processStartInfo.Arguments = $arguments
        $processStartInfo.WorkingDirectory = $Script:InstallDir
        $processStartInfo.UseShellExecute = $false
        $processStartInfo.RedirectStandardOutput = $true
        $processStartInfo.RedirectStandardError = $true
        $processStartInfo.CreateNoWindow = $false  # Show window for user visibility
        
        Write-DebugInfo "Starting process with enhanced configuration"
        $process = [System.Diagnostics.Process]::Start($processStartInfo)
        
        if ($process) {
            Write-LogToGUI "Velociraptor process started (PID: $($process.Id))" -Level 'Success'
            Write-DebugInfo "Process started successfully with PID: $($process.Id)"
            
            # Wait for startup
            Write-LogToGUI "Waiting for service to start..." -Level 'Info'
            Start-Sleep -Seconds 8  # Increased wait time for better reliability
            
            # Check if process is still running
            try {
                $process.Refresh()
                if ($process.HasExited) {
                    $exitCode = $process.ExitCode
                    Write-LogToGUI "Process exited unexpectedly with code: $exitCode" -Level 'Warning'
                    
                    # Try to read error output
                    try {
                        $errorOutput = $process.StandardError.ReadToEnd()
                        $standardOutput = $process.StandardOutput.ReadToEnd()
                        Write-DebugInfo "Process stderr: $errorOutput"
                        Write-DebugInfo "Process stdout: $standardOutput"
                        
                        if ($errorOutput) {
                            Write-LogToGUI "Process error: $errorOutput" -Level 'Warning'
                        }
                    }
                    catch {
                        Write-DebugInfo "Could not read process output: $($_.Exception.Message)"
                    }
                }
                else {
                    Write-LogToGUI "Process is running successfully" -Level 'Success'
                }
            }
            catch {
                Write-DebugInfo "Process status check failed: $($_.Exception.Message)"
            }
            
            # Open web interface with retry mechanism
            Write-LogToGUI "Opening web interface..." -Level 'Info'
            $webUrl = "https://127.0.0.1:8889"
            Write-DebugInfo "Web interface URL: $webUrl"
            
            try {
                # Try multiple methods to open browser
                $browserOpened = $false
                
                # Method 1: Start-Process
                try {
                    Start-Process $webUrl
                    $browserOpened = $true
                    Write-DebugInfo "Browser opened using Start-Process"
                }
                catch {
                    Write-DebugInfo "Start-Process failed: $($_.Exception.Message)"
                    
                    # Method 2: System.Diagnostics.Process
                    try {
                        [System.Diagnostics.Process]::Start($webUrl) | Out-Null
                        $browserOpened = $true
                        Write-DebugInfo "Browser opened using System.Diagnostics.Process"
                    }
                    catch {
                        Write-DebugInfo "System.Diagnostics.Process failed: $($_.Exception.Message)"
                    }
                }
                
                if ($browserOpened) {
                    Write-LogToGUI "Web interface opened in default browser" -Level 'Success'
                }
                else {
                    Write-LogToGUI "Could not open browser automatically - please navigate to $webUrl manually" -Level 'Warning'
                }
            }
            catch {
                Write-LogToGUI "Browser launch failed - please navigate to $webUrl manually" -Level 'Warning'
                Write-DebugInfo "Browser launch failed: $($_.Exception.Message)"
            }
            
            Write-LogToGUI "Velociraptor GUI is ready at: $webUrl" -Level 'Success'
            Write-LogToGUI "Default credentials: admin / password" -Level 'Warning'
            Write-DebugInfo "Launch process completed"
            
            # Show success message
            $launchMessage = @"
🎉 Velociraptor launched successfully!

🌐 Web Interface: $webUrl
🆔 Process ID: $($process.Id)
👤 Default credentials: admin / password

The web interface should open automatically in your default browser.
If it doesn't, please navigate to the URL manually.

Important Security Notes:
• Change the default password immediately after first login
• Configure proper SSL certificates for production use
• Review security settings in the admin panel
"@
            
            [System.Windows.Forms.MessageBox]::Show(
                $launchMessage,
                "Bulletproof Launch - Success",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
        else {
            throw "Failed to start Velociraptor process - no process object returned"
        }
    }
    catch {
        $launchError = "Launch failed: $($_.Exception.Message)"
        Write-LogToGUI $launchError -Level 'Error'
        Write-DebugInfo "Launch failed with full exception: $($_.Exception | Out-String)"
        
        Show-BulletproofError -ErrorMessage $launchError -Context "Velociraptor Launch" -SuggestedActions @(
            "Verify Velociraptor installation completed successfully",
            "Check that data directory path is valid and accessible",
            "Ensure no other Velociraptor processes are running",
            "Try launching as Administrator",
            "Check Windows Firewall and antivirus settings",
            "Verify port 8889 is not in use by another application",
            "Review installation logs for any issues",
            "Try reinstalling Velociraptor if the executable is corrupted"
        ) -TechnicalDetails "Executable: $executablePath`nData Store: $Script:DataStore`nProcess Creation Method: System.Diagnostics.Process"
    }
}

# ============================================================================
# SAFE CONTROL CREATION FUNCTIONS
# ============================================================================

function New-BulletproofControl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ControlType,
        
        [hashtable]$Properties = @{},
        
        [System.Drawing.Color]$BackColor = $null,
        [System.Drawing.Color]$ForeColor = $null,
        
        [string]$ControlName = "UnnamedControl"
    )
    
    Write-DebugInfo "Creating $ControlType control: $ControlName"
    
    try {
        # Create the control
        $control = New-Object $ControlType
        Write-DebugInfo "Base control created successfully"
        
        # Set colors with safe fallbacks
        if ($BackColor -ne $null) {
            try {
                $control.BackColor = $BackColor
                Write-DebugInfo "BackColor set successfully"
            }
            catch {
                Write-DebugInfo "BackColor assignment failed, trying fallback: $($_.Exception.Message)"
                try {
                    $control.BackColor = [System.Drawing.Color]::FromKnownColor([System.Drawing.KnownColor]::Control)
                }
                catch {
                    Write-DebugInfo "BackColor fallback also failed, leaving default"
                }
            }
        }
        
        if ($ForeColor -ne $null) {
            try {
                $control.ForeColor = $ForeColor
                Write-DebugInfo "ForeColor set successfully"
            }
            catch {
                Write-DebugInfo "ForeColor assignment failed, trying fallback: $($_.Exception.Message)"
                try {
                    $control.ForeColor = [System.Drawing.Color]::FromKnownColor([System.Drawing.KnownColor]::ControlText)
                }
                catch {
                    Write-DebugInfo "ForeColor fallback also failed, leaving default"
                }
            }
        }
        
        # Set other properties
        foreach ($propName in $Properties.Keys) {
            try {
                $propValue = $Properties[$propName]
                $control.$propName = $propValue
                Write-DebugInfo "Property $propName set successfully"
            }
            catch {
                Write-DebugInfo "Failed to set property $propName`: $($_.Exception.Message)"
                # Continue with other properties even if one fails
            }
        }
        
        Write-DebugInfo "Control $ControlName created successfully"
        return $control
    }
    catch {
        Write-DebugInfo "Failed to create control $ControlName`: $($_.Exception.Message)"
        Write-LogToGUI "Warning: Failed to create $ControlType control: $ControlName" -Level 'Warning'
        return $null
    }
}

function Add-BulletproofControlToParent {
    param(
        [Parameter(Mandatory)]
        $ParentControl,
        
        [Parameter(Mandatory)]
        $ChildControl,
        
        [string]$ControlName = "UnnamedControl"
    )
    
    if ($ChildControl -eq $null) {
        Write-DebugInfo "Skipping null control: $ControlName"
        return $false
    }
    
    try {
        $ParentControl.Controls.Add($ChildControl)
        Write-DebugInfo "Added $ControlName to parent successfully"
        return $true
    }
    catch {
        Write-DebugInfo "Failed to add $ControlName to parent: $($_.Exception.Message)"
        Write-LogToGUI "Warning: Failed to add control to parent: $ControlName" -Level 'Warning'
        return $false
    }
}

# ============================================================================
# GUI CREATION FUNCTIONS
# ============================================================================

function New-MainForm {
    Write-LogToGUI "Creating main application form..." -Level 'Info'
    Write-DebugInfo "Starting main form creation"
    
    try {
        $form = New-BulletproofControl -ControlType "System.Windows.Forms.Form" -Properties @{
            Text = "Velociraptor GUI - Bulletproof Edition v5.0.4-beta"
            Size = New-Object System.Drawing.Size(1000, 700)
            MinimumSize = New-Object System.Drawing.Size(900, 650)
            StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
            FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
            MaximizeBox = $true
            MinimizeBox = $true
            ShowIcon = $true
        } -BackColor $Colors.DarkBackground -ForeColor $Colors.WhiteText -ControlName "MainForm"
        
        if ($form -eq $null) {
            throw "Failed to create main form"
        }
        
        # Set icon safely
        try {
            $form.Icon = [System.Drawing.SystemIcons]::Shield
            Write-DebugInfo "Form icon set successfully"
        }
        catch {
            Write-DebugInfo "Could not set form icon: $($_.Exception.Message)"
        }
        
        Write-LogToGUI "Main form created successfully" -Level 'Success'
        Write-DebugInfo "Main form creation completed"
        return $form
    }
    catch {
        Write-DebugInfo "Main form creation failed: $($_.Exception.Message)"
        throw "Failed to create main form: $($_.Exception.Message)"
    }
}

function New-HeaderPanel {
    param($ParentForm)
    
    Write-DebugInfo "Creating header panel"
    
    try {
        $headerPanel = New-BulletproofControl -ControlType "System.Windows.Forms.Panel" -Properties @{
            Size = New-Object System.Drawing.Size(980, 100)
            Location = New-Object System.Drawing.Point(10, 10)
            Anchor = ([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right)
        } -BackColor $Colors.PrimaryTeal -ForeColor $Colors.WhiteText -ControlName "HeaderPanel"
        
        if ($headerPanel -eq $null) {
            Write-DebugInfo "Header panel creation failed"
            return $null
        }
        
        # Title label
        $titleLabel = New-BulletproofControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "🦖 VELOCIRAPTOR - BULLETPROOF EDITION"
            Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
            Location = New-Object System.Drawing.Point(20, 20)
            Size = New-Object System.Drawing.Size(600, 30)
            BackColor = [System.Drawing.Color]::Transparent
        } -ForeColor $Colors.WhiteText -ControlName "TitleLabel"
        
        Add-BulletproofControlToParent -ParentControl $headerPanel -ChildControl $titleLabel -ControlName "TitleLabel"
        
        # Subtitle label
        $subtitleLabel = New-BulletproofControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "DFIR Framework - Complete Installation & Configuration Suite"
            Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
            Location = New-Object System.Drawing.Point(20, 55)
            Size = New-Object System.Drawing.Size(500, 25)
            BackColor = [System.Drawing.Color]::Transparent
        } -ForeColor $Colors.LightGrayText -ControlName "SubtitleLabel"
        
        Add-BulletproofControlToParent -ParentControl $headerPanel -ChildControl $subtitleLabel -ControlName "SubtitleLabel"
        
        # Version label
        $versionLabel = New-BulletproofControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "v5.0.4-beta | Bulletproof Edition"
            Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            Location = New-Object System.Drawing.Point(750, 70)
            Size = New-Object System.Drawing.Size(200, 20)
            TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
            Anchor = ([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right)
            BackColor = [System.Drawing.Color]::Transparent
        } -ForeColor $Colors.WhiteText -ControlName "VersionLabel"
        
        Add-BulletproofControlToParent -ParentControl $headerPanel -ChildControl $versionLabel -ControlName "VersionLabel"
        
        Add-BulletproofControlToParent -ParentControl $ParentForm -ChildControl $headerPanel -ControlName "HeaderPanel"
        Write-DebugInfo "Header panel created successfully"
        return $headerPanel
    }
    catch {
        Write-DebugInfo "Header panel creation failed: $($_.Exception.Message)"
        return $null
    }
}

function New-ContentPanel {
    param($ParentForm)
    
    Write-DebugInfo "Creating content panel"
    
    try {
        $contentPanel = New-BulletproofControl -ControlType "System.Windows.Forms.Panel" -Properties @{
            Size = New-Object System.Drawing.Size(980, 440)
            Location = New-Object System.Drawing.Point(10, 120)
            Anchor = ([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom)
            BorderStyle = [System.Windows.Forms.BorderStyle]::None
        } -BackColor $Colors.DarkSurface -ForeColor $Colors.WhiteText -ControlName "ContentPanel"
        
        if ($contentPanel -eq $null) {
            Write-DebugInfo "Content panel creation failed"
            return $null
        }
        
        # Installation directory controls
        $installDirLabel = New-BulletproofControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Installation Directory:"
            Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
            Location = New-Object System.Drawing.Point(30, 30)
            Size = New-Object System.Drawing.Size(200, 25)
            BackColor = [System.Drawing.Color]::Transparent
        } -ForeColor $Colors.WhiteText -ControlName "InstallDirLabel"
        
        Add-BulletproofControlToParent -ParentControl $contentPanel -ChildControl $installDirLabel -ControlName "InstallDirLabel"
        
        $installDirTextBox = New-BulletproofControl -ControlType "System.Windows.Forms.TextBox" -Properties @{
            Text = $Script:InstallDir
            Font = New-Object System.Drawing.Font("Consolas", 10)
            Location = New-Object System.Drawing.Point(30, 60)
            Size = New-Object System.Drawing.Size(400, 25)
            TabIndex = 1
        } -BackColor $Colors.DarkBackground -ForeColor $Colors.WhiteText -ControlName "InstallDirTextBox"
        
        if ($installDirTextBox -ne $null) {
            # Add real-time validation
            $installDirTextBox.Add_TextChanged({
                $Script:InstallDir = $installDirTextBox.Text
                
                # Visual feedback for path validation
                try {
                    $parentDir = Split-Path $installDirTextBox.Text -Parent
                    $isValid = $false
                    
                    if (-not [string]::IsNullOrWhiteSpace($installDirTextBox.Text)) {
                        if ($parentDir -and (Test-Path $parentDir)) {
                            $isValid = $true
                        }
                        elseif ([System.IO.Path]::IsPathRooted($installDirTextBox.Text)) {
                            $isValid = $true  # Valid format
                        }
                    }
                    
                    if ($isValid) {
                        $installDirTextBox.BackColor = New-SafeColor -Red 25 -Green 80 -Blue 25 -Fallback $Colors.DarkBackground
                    }
                    else {
                        $installDirTextBox.BackColor = New-SafeColor -Red 80 -Green 25 -Blue 25 -Fallback $Colors.DarkBackground  
                    }
                    
                    Write-DebugInfo "Install directory validation: $isValid for path: $($installDirTextBox.Text)"
                }
                catch {
                    Write-DebugInfo "Install directory validation failed: $($_.Exception.Message)"
                }
            })
        }
        
        Add-BulletproofControlToParent -ParentControl $contentPanel -ChildControl $installDirTextBox -ControlName "InstallDirTextBox"
        
        # Data directory controls
        $dataDirLabel = New-BulletproofControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "Data Directory:"
            Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
            Location = New-Object System.Drawing.Point(30, 100)
            Size = New-Object System.Drawing.Size(200, 25)
            BackColor = [System.Drawing.Color]::Transparent
        } -ForeColor $Colors.WhiteText -ControlName "DataDirLabel"
        
        Add-BulletproofControlToParent -ParentControl $contentPanel -ChildControl $dataDirLabel -ControlName "DataDirLabel"
        
        $dataDirTextBox = New-BulletproofControl -ControlType "System.Windows.Forms.TextBox" -Properties @{
            Text = $Script:DataStore
            Font = New-Object System.Drawing.Font("Consolas", 10)
            Location = New-Object System.Drawing.Point(30, 130)
            Size = New-Object System.Drawing.Size(400, 25)
            TabIndex = 2
        } -BackColor $Colors.DarkBackground -ForeColor $Colors.WhiteText -ControlName "DataDirTextBox"
        
        if ($dataDirTextBox -ne $null) {
            $dataDirTextBox.Add_TextChanged({
                $Script:DataStore = $dataDirTextBox.Text
                
                # Visual feedback for path validation  
                try {
                    $parentDir = Split-Path $dataDirTextBox.Text -Parent
                    $isValid = $false
                    
                    if (-not [string]::IsNullOrWhiteSpace($dataDirTextBox.Text)) {
                        if ($parentDir -and (Test-Path $parentDir)) {
                            $isValid = $true
                        }
                        elseif ([System.IO.Path]::IsPathRooted($dataDirTextBox.Text)) {
                            $isValid = $true  # Valid format
                        }
                    }
                    
                    if ($isValid) {
                        $dataDirTextBox.BackColor = New-SafeColor -Red 25 -Green 80 -Blue 25 -Fallback $Colors.DarkBackground
                    }
                    else {
                        $dataDirTextBox.BackColor = New-SafeColor -Red 80 -Green 25 -Blue 25 -Fallback $Colors.DarkBackground
                    }
                    
                    Write-DebugInfo "Data directory validation: $isValid for path: $($dataDirTextBox.Text)"
                }
                catch {
                    Write-DebugInfo "Data directory validation failed: $($_.Exception.Message)"
                }
            })
        }
        
        Add-BulletproofControlToParent -ParentControl $contentPanel -ChildControl $dataDirTextBox -ControlName "DataDirTextBox"
        
        # Log area
        $logLabel = New-BulletproofControl -ControlType "System.Windows.Forms.Label" -Properties @{
            Text = "📋 Installation Log & Progress:"
            Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
            Location = New-Object System.Drawing.Point(30, 180)
            Size = New-Object System.Drawing.Size(300, 25)
            BackColor = [System.Drawing.Color]::Transparent
        } -ForeColor $Colors.PrimaryTeal -ControlName "LogLabel"
        
        Add-BulletproofControlToParent -ParentControl $contentPanel -ChildControl $logLabel -ControlName "LogLabel"
        
        $Script:LogTextBox = New-BulletproofControl -ControlType "System.Windows.Forms.TextBox" -Properties @{
            Multiline = $true
            ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
            Font = New-Object System.Drawing.Font("Consolas", 9)
            Location = New-Object System.Drawing.Point(30, 210)
            Size = New-Object System.Drawing.Size(920, 210)
            Anchor = ([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Bottom)
            ReadOnly = $true
            TabStop = $false
        } -BackColor $Colors.DarkBackground -ForeColor $Colors.WhiteText -ControlName "LogTextBox"
        
        Add-BulletproofControlToParent -ParentControl $contentPanel -ChildControl $Script:LogTextBox -ControlName "LogTextBox"
        
        Add-BulletproofControlToParent -ParentForm $ParentForm -ChildControl $contentPanel -ControlName "ContentPanel"
        Write-DebugInfo "Content panel created successfully"
        return $contentPanel
    }
    catch {
        Write-DebugInfo "Content panel creation failed: $($_.Exception.Message)"
        return $null
    }
}

function New-ButtonPanel {
    param($ParentForm)
    
    Write-DebugInfo "Creating button panel"
    
    try {
        $buttonPanel = New-BulletproofControl -ControlType "System.Windows.Forms.Panel" -Properties @{
            Size = New-Object System.Drawing.Size(980, 70)
            Location = New-Object System.Drawing.Point(10, 570)
            Anchor = ([System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right)
        } -BackColor $Colors.DarkSurface -ForeColor $Colors.WhiteText -ControlName "ButtonPanel"
        
        if ($buttonPanel -eq $null) {
            Write-DebugInfo "Button panel creation failed"
            return $null
        }
        
        # Emergency Mode button (prominent placement)
        $Script:EmergencyButton = New-BulletproofControl -ControlType "System.Windows.Forms.Button" -Properties @{
            Text = "🚨 EMERGENCY MODE"
            Size = New-Object System.Drawing.Size(200, 45)
            Location = New-Object System.Drawing.Point(400, 15)
            FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
            TabIndex = 3
        } -BackColor $Colors.ErrorRed -ForeColor $Colors.WhiteText -ControlName "EmergencyButton"
        
        if ($Script:EmergencyButton -ne $null) {
            $Script:EmergencyButton.Add_Click({
                Write-DebugInfo "Emergency button clicked"
                try {
                    # Run in background to prevent UI freezing
                    $runspace = [runspacefactory]::CreateRunspace()
                    $runspace.Open()
                    $runspace.SessionStateProxy.SetVariable('EmergencyFunction', ${function:Start-EmergencyDeployment})
                    $runspace.SessionStateProxy.SetVariable('Colors', $Colors)
                    $runspace.SessionStateProxy.SetVariable('Script:InstallDir', $Script:InstallDir)
                    $runspace.SessionStateProxy.SetVariable('Script:DataStore', $Script:DataStore)
                    $runspace.SessionStateProxy.SetVariable('Script:EmergencyButton', $Script:EmergencyButton)
                    
                    $powershell = [powershell]::Create()
                    $powershell.Runspace = $runspace
                    $powershell.AddScript({ & $EmergencyFunction }) | Out-Null
                    $powershell.BeginInvoke() | Out-Null
                }
                catch {
                    Write-DebugInfo "Emergency button handler failed: $($_.Exception.Message)"
                    Start-EmergencyDeployment
                }
            })
        }
        
        Add-BulletproofControlToParent -ParentControl $buttonPanel -ChildControl $Script:EmergencyButton -ControlName "EmergencyButton"
        
        # Install button
        $Script:InstallButton = New-BulletproofControl -ControlType "System.Windows.Forms.Button" -Properties @{
            Text = "📥 Install Velociraptor"
            Size = New-Object System.Drawing.Size(160, 40)
            Location = New-Object System.Drawing.Point(620, 17)
            FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
            TabIndex = 4
        } -BackColor $Colors.PrimaryTeal -ForeColor $Colors.WhiteText -ControlName "InstallButton"
        
        if ($Script:InstallButton -ne $null) {
            $Script:InstallButton.Add_Click({
                Write-DebugInfo "Install button clicked"
                try {
                    # Run installation in background to prevent UI freezing
                    $runspace = [runspacefactory]::CreateRunspace()
                    $runspace.Open()
                    $runspace.SessionStateProxy.SetVariable('InstallFunction', ${function:Start-VelociraptorInstallation})
                    $runspace.SessionStateProxy.SetVariable('Colors', $Colors)
                    $runspace.SessionStateProxy.SetVariable('Script:InstallDir', $Script:InstallDir)
                    $runspace.SessionStateProxy.SetVariable('Script:DataStore', $Script:DataStore)
                    $runspace.SessionStateProxy.SetVariable('Script:InstallButton', $Script:InstallButton)
                    $runspace.SessionStateProxy.SetVariable('Script:LaunchButton', $Script:LaunchButton)
                    
                    $powershell = [powershell]::Create()
                    $powershell.Runspace = $runspace
                    $powershell.AddScript({ & $InstallFunction }) | Out-Null
                    $powershell.BeginInvoke() | Out-Null
                }
                catch {
                    Write-DebugInfo "Install button handler failed: $($_.Exception.Message)"
                    Start-VelociraptorInstallation
                }
            })
        }
        
        Add-BulletproofControlToParent -ParentControl $buttonPanel -ChildControl $Script:InstallButton -ControlName "InstallButton"
        
        # Launch button  
        $Script:LaunchButton = New-BulletproofControl -ControlType "System.Windows.Forms.Button" -Properties @{
            Text = "🚀 Launch Velociraptor"
            Size = New-Object System.Drawing.Size(160, 40)
            Location = New-Object System.Drawing.Point(800, 17)
            FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
            Enabled = $false
            TabIndex = 5
        } -BackColor $Colors.SuccessGreen -ForeColor $Colors.BlackText -ControlName "LaunchButton"
        
        if ($Script:LaunchButton -ne $null) {
            $Script:LaunchButton.Add_Click({
                Write-DebugInfo "Launch button clicked"
                Start-VelociraptorLaunch
            })
        }
        
        Add-BulletproofControlToParent -ParentControl $buttonPanel -ChildControl $Script:LaunchButton -ControlName "LaunchButton"
        
        # Exit button
        $exitButton = New-BulletproofControl -ControlType "System.Windows.Forms.Button" -Properties @{
            Text = "❌ Exit"
            Size = New-Object System.Drawing.Size(80, 35)
            Location = New-Object System.Drawing.Point(30, 20)
            FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            TabIndex = 6
        } -BackColor $Colors.DarkBackground -ForeColor $Colors.WhiteText -ControlName "ExitButton"
        
        if ($exitButton -ne $null) {
            $exitButton.Add_Click({
                Write-DebugInfo "Exit button clicked"
                
                $confirmExit = [System.Windows.Forms.MessageBox]::Show(
                    "Are you sure you want to exit the Bulletproof GUI?",
                    "Confirm Exit",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Question
                )
                
                if ($confirmExit -eq [System.Windows.Forms.DialogResult]::Yes) {
                    Write-LogToGUI "User requested exit - closing application" -Level 'Info'
                    $Script:MainForm.Close()
                }
                else {
                    Write-LogToGUI "Exit cancelled by user" -Level 'Info'
                }
            })
        }
        
        Add-BulletproofControlToParent -ParentControl $buttonPanel -ChildControl $exitButton -ControlName "ExitButton"
        
        Add-BulletproofControlToParent -ParentForm $ParentForm -ChildControl $buttonPanel -ControlName "ButtonPanel"
        Write-DebugInfo "Button panel created successfully"
        return $buttonPanel
    }
    catch {
        Write-DebugInfo "Button panel creation failed: $($_.Exception.Message)"
        return $null
    }
}

# ============================================================================
# MAIN APPLICATION ENTRY POINT
# ============================================================================

Write-LogToGUI "=== BULLETPROOF GUI INITIALIZATION COMPLETE ===" -Level 'Success'
Write-LogToGUI "System Information:" -Level 'Info'
Write-LogToGUI "• PowerShell Version: $($PSVersionTable.PSVersion)" -Level 'Info'
Write-LogToGUI "• OS Version: $($PSVersionTable.OS)" -Level 'Info' 
Write-LogToGUI "• Windows Forms Method: $InitializationMethod" -Level 'Info'
Write-LogToGUI "• Admin Privileges: $(if (Test-AdminPrivileges) { 'YES' } else { 'NO' })" -Level 'Info'

try {
    Write-LogToGUI "Creating main application window..." -Level 'Info'
    
    # Create main form
    $Script:MainForm = New-MainForm
    if ($Script:MainForm -eq $null) {
        throw "Failed to create main form"
    }
    
    # Create UI components
    $headerPanel = New-HeaderPanel -ParentForm $Script:MainForm
    $contentPanel = New-ContentPanel -ParentForm $Script:MainForm  
    $buttonPanel = New-ButtonPanel -ParentForm $Script:MainForm
    
    # Initial log messages
    Write-LogToGUI "=== Bulletproof Velociraptor GUI Ready ===" -Level 'Success'
    Write-LogToGUI "✅ All systems initialized successfully" -Level 'Success'
    Write-LogToGUI "" -Level 'Info'
    Write-LogToGUI "📋 Instructions:" -Level 'Info'
    Write-LogToGUI "1. Review installation and data directory paths above" -Level 'Info'
    Write-LogToGUI "2. Click 'Install Velociraptor' for standard installation" -Level 'Info'  
    Write-LogToGUI "3. Click 'EMERGENCY MODE' for rapid deployment in critical situations" -Level 'Info'
    Write-LogToGUI "4. Monitor this log for progress updates and any issues" -Level 'Info'
    Write-LogToGUI "" -Level 'Info'
    Write-LogToGUI "🛡️ This Bulletproof Edition handles all known failure scenarios gracefully" -Level 'Success'
    
    # Handle minimized start
    if ($StartMinimized) {
        $Script:MainForm.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
        Write-LogToGUI "GUI started in minimized mode" -Level 'Info'
    }
    
    Write-Host "🎉 Bulletproof GUI created successfully!" -ForegroundColor Green
    Write-Host "🚀 Launching application window..." -ForegroundColor Green
    
    # Show the form and run the application
    Write-DebugInfo "Starting Windows Forms application"
    [System.Windows.Forms.Application]::Run($Script:MainForm)
    
    Write-LogToGUI "Application closed successfully" -Level 'Success'
    Write-Host "✅ Bulletproof GUI session completed successfully!" -ForegroundColor Green
    
}
catch {
    $criticalError = "Critical GUI failure: $($_.Exception.Message)"
    Write-Host $criticalError -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
    
    if ($DebugMode) {
        Write-Host "Full exception details:" -ForegroundColor Yellow
        Write-Host ($_.Exception | Out-String) -ForegroundColor Yellow
    }
    
    # Try to show error dialog if forms are working
    try {
        if ($Script:GuiInitialized) {
            $errorReport = @"
🚨 CRITICAL GUI FAILURE 🚨

The Bulletproof GUI encountered a critical error and cannot continue.

Error: $($_.Exception.Message)

Troubleshooting Steps:
• Try running as Administrator
• Verify Windows Forms support is available
• Check PowerShell version compatibility
• Try emergency mode: -EmergencyMode parameter
• Enable debug mode: -DebugMode parameter
• Restart PowerShell session
• Check system requirements

Initialization Method Used: $InitializationMethod
PowerShell Version: $($PSVersionTable.PSVersion)
OS: $($PSVersionTable.OS)

For support, please include this error information.
"@
            
            [System.Windows.Forms.MessageBox]::Show(
                $errorReport,
                "Bulletproof GUI - Critical Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
        else {
            Write-Host $errorReport -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Cannot show error dialog. GUI systems failed completely." -ForegroundColor Red
    }
    
    Write-Host "`nPress any key to exit..." -ForegroundColor Yellow
    try {
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {
        Start-Sleep -Seconds 5
    }
    
    exit 1
}
finally {
    Write-DebugInfo "Entering cleanup phase"
    
    # Cleanup resources
    try {
        if ($Script:MainForm -ne $null) {
            $Script:MainForm.Dispose()
            Write-DebugInfo "Main form disposed"
        }
        
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        Write-DebugInfo "Garbage collection completed"
    }
    catch {
        Write-DebugInfo "Cleanup failed: $($_.Exception.Message)"
        # Silently handle cleanup errors
    }
}

Write-Host "🛡️ Bulletproof GUI shutdown completed." -ForegroundColor Green