function Restore-VelociraptorConfiguration {
    <#
    .SYNOPSIS
        Restores Velociraptor configuration files from backup.

    .DESCRIPTION
        Restores Velociraptor configurations from backup files created by
        Backup-VelociraptorConfiguration, including validation and verification.

    .PARAMETER BackupPath
        Path to the backup file or compressed backup to restore from.

    .PARAMETER RestorePath
        Destination path for the restored configuration. If not specified, uses original path.

    .PARAMETER IncludeDatastore
        Restore datastore if available in backup.

    .PARAMETER ValidateAfterRestore
        Validate the restored configuration file.

    .PARAMETER Force
        Overwrite existing files without prompting.

    .PARAMETER CreateBackupBeforeRestore
        Create backup of existing files before restoring.

    .EXAMPLE
        Restore-VelociraptorConfiguration -BackupPath "C:\Backups\server_backup.yaml"

    .EXAMPLE
        Restore-VelociraptorConfiguration -BackupPath "backup.zip" -IncludeDatastore -ValidateAfterRestore

    .OUTPUTS
        PSCustomObject with restore results including validation and file information.

    .NOTES
        Requires read access to backup files and write access to restore location.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_})]
        [string]$BackupPath,
        
        [Parameter()]
        [string]$RestorePath,
        
        [Parameter()]
        [switch]$IncludeDatastore,
        
        [Parameter()]
        [switch]$ValidateAfterRestore = $true,
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$CreateBackupBeforeRestore = $true
    )
    
    try {
        Write-VelociraptorLog "Starting configuration restore from: $BackupPath" -Level Info
        
        # Initialize result object
        $result = [PSCustomObject]@{
            Success = $false
            BackupPath = $BackupPath
            RestorePath = $null
            RestoredFiles = @()
            DatastoreRestored = $false
            ValidationResult = $null
            RestoreDate = Get-Date
            OriginalBackupInfo = $null
        }
        
        # Determine if backup is compressed
        $isCompressed = [System.IO.Path]::GetExtension($BackupPath) -eq '.zip'
        $workingDir = $null
        $configFile = $null
        $metadataFile = $null
        $datastoreDir = $null
        
        if ($isCompressed) {
            # Extract compressed backup to temporary directory
            $workingDir = Join-Path $env:TEMP "VelociraptorRestore_$(Get-Date -Format 'yyyyMMddHHmmss')"
            New-Item -ItemType Directory -Path $workingDir -Force | Out-Null
            
            Write-VelociraptorLog "Extracting compressed backup..." -Level Info
            Expand-Archive -Path $BackupPath -DestinationPath $workingDir -Force
            
            # Find configuration file in extracted content
            $configFile = Get-ChildItem -Path $workingDir -Filter "*.yaml" | Select-Object -First 1
            if (-not $configFile) {
                throw "No YAML configuration file found in backup archive"
            }
            $configFile = $configFile.FullName
            
            # Look for metadata and datastore
            $metadataFile = Get-ChildItem -Path $workingDir -Filter "*.metadata.json" | Select-Object -First 1
            if ($metadataFile) { $metadataFile = $metadataFile.FullName }
            
            $datastoreDir = Get-ChildItem -Path $workingDir -Directory -Filter "*.datastore" | Select-Object -First 1
            if ($datastoreDir) { $datastoreDir = $datastoreDir.FullName }
        } else {
            # Direct backup file
            $configFile = $BackupPath
            $metadataFile = "$BackupPath.metadata.json"
            $datastoreDir = "$BackupPath.datastore"
            
            if (-not (Test-Path $metadataFile)) { $metadataFile = $null }
            if (-not (Test-Path $datastoreDir)) { $datastoreDir = $null }
        }
        
        # Read metadata if available
        if ($metadataFile -and (Test-Path $metadataFile)) {
            try {
                $metadata = Get-Content $metadataFile -Raw | ConvertFrom-Json
                $result.OriginalBackupInfo = $metadata.BackupInfo
                Write-VelociraptorLog "Backup metadata loaded: Created $($metadata.BackupInfo.BackupDate)" -Level Info
            }
            catch {
                Write-VelociraptorLog "Warning: Could not read backup metadata" -Level Warning
            }
        }
        
        # Determine restore path
        if (-not $RestorePath) {
            if ($result.OriginalBackupInfo -and $result.OriginalBackupInfo.OriginalPath) {
                $RestorePath = $result.OriginalBackupInfo.OriginalPath
            } else {
                # Default to current directory with backup filename
                $RestorePath = Join-Path (Get-Location) ([System.IO.Path]::GetFileName($configFile))
            }
        }
        
        $result.RestorePath = $RestorePath
        
        # Create backup of existing file if requested
        if ($CreateBackupBeforeRestore -and (Test-Path $RestorePath)) {
            $preRestoreBackup = "${RestorePath}.pre-restore.$(Get-Date -Format 'yyyyMMddHHmmss')"
            Copy-Item $RestorePath $preRestoreBackup -Force
            Write-VelociraptorLog "Created pre-restore backup: $preRestoreBackup" -Level Info
        }
        
        # Check if destination exists and handle accordingly
        if (Test-Path $RestorePath -and -not $Force) {
            $overwrite = Read-VelociraptorUserInput -Prompt "Destination file exists. Overwrite?" -DefaultValue "N" -ValidValues @("Y", "N")
            if ($overwrite -eq "N") {
                throw "Restore cancelled by user"
            }
        }
        
        # Create destination directory if needed
        $restoreDir = Split-Path $RestorePath -Parent
        if (-not (Test-Path $restoreDir)) {
            New-Item -ItemType Directory -Path $restoreDir -Force | Out-Null
        }
        
        # Restore configuration file
        Copy-Item $configFile $RestorePath -Force
        $result.RestoredFiles += $RestorePath
        Write-VelociraptorLog "Configuration restored to: $RestorePath" -Level Success
        
        # Restore datastore if requested and available
        if ($IncludeDatastore -and $datastoreDir -and (Test-Path $datastoreDir)) {
            # Determine datastore restore path
            $datastoreRestorePath = $null
            
            if ($result.OriginalBackupInfo -and $result.OriginalBackupInfo.DatastorePath) {
                $datastoreRestorePath = $result.OriginalBackupInfo.DatastorePath
            } else {
                # Try to determine from configuration
                $tempValidation = Test-VelociraptorConfiguration -ConfigPath $RestorePath -ValidationLevel Basic -OutputFormat Object
                if ($tempValidation.ConfigInfo.DatastorePath) {
                    $datastoreRestorePath = $tempValidation.ConfigInfo.DatastorePath
                }
            }
            
            if ($datastoreRestorePath) {
                Write-VelociraptorLog "Restoring datastore to: $datastoreRestorePath" -Level Info
                
                try {
                    # Create datastore directory if needed
                    if (-not (Test-Path $datastoreRestorePath)) {
                        New-Item -ItemType Directory -Path $datastoreRestorePath -Force | Out-Null
                    }
                    
                    # Copy datastore files
                    Copy-Item -Path "$datastoreDir\*" -Destination $datastoreRestorePath -Recurse -Force
                    $result.DatastoreRestored = $true
                    Write-VelociraptorLog "Datastore restored successfully" -Level Success
                }
                catch {
                    Write-VelociraptorLog "Warning: Datastore restore failed: $($_.Exception.Message)" -Level Warning
                }
            } else {
                Write-VelociraptorLog "Warning: Could not determine datastore restore path" -Level Warning
            }
        }
        
        # Validate restored configuration
        if ($ValidateAfterRestore) {
            Write-VelociraptorLog "Validating restored configuration..." -Level Info
            $result.ValidationResult = Test-VelociraptorConfiguration -ConfigPath $RestorePath -ValidationLevel Standard -OutputFormat Object
            
            if ($result.ValidationResult.IsValid) {
                Write-VelociraptorLog "Restored configuration is valid" -Level Success
            } else {
                Write-VelociraptorLog "Warning: Restored configuration has validation issues" -Level Warning
            }
        }
        
        # Verify file integrity if original hash is available
        if ($result.OriginalBackupInfo -and $result.OriginalBackupInfo.FileInfo -and $result.OriginalBackupInfo.FileInfo.OriginalHash) {
            $restoredHash = (Get-FileHash $RestorePath -Algorithm SHA256).Hash
            if ($restoredHash -eq $result.OriginalBackupInfo.FileInfo.OriginalHash) {
                Write-VelociraptorLog "File integrity verified (hash match)" -Level Success
            } else {
                Write-VelociraptorLog "Warning: File hash does not match original" -Level Warning
            }
        }
        
        # Cleanup temporary directory if used
        if ($workingDir -and (Test-Path $workingDir)) {
            Remove-Item $workingDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        $result.Success = $true
        Write-VelociraptorLog "Configuration restore completed successfully" -Level Success
        return $result
    }
    catch {
        # Cleanup on failure
        if ($workingDir -and (Test-Path $workingDir)) {
            Remove-Item $workingDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        $errorMessage = "Restore failed: $($_.Exception.Message)"
        Write-VelociraptorLog $errorMessage -Level Error
        
        $result.Success = $false
        $result.Error = $_.Exception.Message
        return $result
    }
}