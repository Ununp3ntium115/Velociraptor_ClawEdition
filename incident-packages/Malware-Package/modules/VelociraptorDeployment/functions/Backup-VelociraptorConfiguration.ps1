function Backup-VelociraptorConfiguration {
    <#
    .SYNOPSIS
        Creates backups of Velociraptor configuration files with metadata.

    .DESCRIPTION
        Performs comprehensive backup of Velociraptor configurations including
        metadata, validation results, and optional datastore backup.

    .PARAMETER ConfigPath
        Path to the Velociraptor configuration file to backup.

    .PARAMETER BackupPath
        Destination path for the backup. If not specified, generates automatic path.

    .PARAMETER BackupType
        Type of backup: ConfigOnly, WithDatastore, or Full. Default is ConfigOnly.

    .PARAMETER IncludeMetadata
        Include metadata file with backup information. Default is true.

    .PARAMETER Compress
        Compress the backup into a ZIP file.

    .PARAMETER Force
        Overwrite existing backup files without prompting.

    .EXAMPLE
        Backup-VelociraptorConfiguration -ConfigPath "C:\tools\server.yaml"

    .EXAMPLE
        Backup-VelociraptorConfiguration -ConfigPath "server.yaml" -BackupType WithDatastore -Compress

    .OUTPUTS
        PSCustomObject with backup results including paths and metadata.

    .NOTES
        Requires read access to configuration file and write access to backup location.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$ConfigPath,

        [Parameter()]
        [string]$BackupPath,

        [Parameter()]
        [ValidateSet('ConfigOnly', 'WithDatastore', 'Full')]
        [string]$BackupType = 'ConfigOnly',

        [Parameter()]
        [switch]$IncludeMetadata = $true,

        [Parameter()]
        [switch]$Compress,

        [Parameter()]
        [switch]$Force
    )

    try {
        Write-VelociraptorLog "Creating backup of configuration: $ConfigPath" -Level Info

        # Validate source configuration
        $validation = Test-VelociraptorConfiguration -ConfigPath $ConfigPath -ValidationLevel Basic -OutputFormat Object
        if (-not $validation.IsValid) {
            Write-VelociraptorLog "Warning: Configuration has validation issues" -Level Warning
        }

        # Generate backup path if not specified
        if (-not $BackupPath) {
            $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            $configName = [System.IO.Path]::GetFileNameWithoutExtension($ConfigPath)
            $backupDir = Join-Path $env:ProgramData 'VelociraptorBackups'

            if (-not (Test-Path $backupDir)) {
                New-Item -ItemType Directory -Path $backupDir -Force -ErrorAction SilentlyContinue | Out-Null
            }

            $BackupPath = Join-Path $backupDir "${configName}_backup_${timestamp}.yaml"
        }

        # Check if backup already exists
        if (Test-Path $BackupPath -and -not $Force) {
            $overwrite = Read-VelociraptorUserInput -Prompt "Backup file exists. Overwrite?" -DefaultValue "N" -ValidValues @("Y", "N")
            if ($overwrite -eq "N") {
                throw "Backup cancelled by user"
            }
        }

        # Create backup directory
        $backupDir = Split-Path $BackupPath -Parent
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force -ErrorAction SilentlyContinue | Out-Null
        }

        # Copy main configuration file
        Copy-Item $ConfigPath $BackupPath -Force -ErrorAction SilentlyContinue
        Write-VelociraptorLog "Configuration file backed up to: $BackupPath" -Level Success

        # Initialize result object
        $result = [PSCustomObject]@{
            Success = $true
            ConfigPath = $ConfigPath
            BackupPath = $BackupPath
            BackupType = $BackupType
            BackupDate = Get-Date
            FilesBackedUp = @($BackupPath)
            DatastoreBackedUp = $false
            MetadataPath = $null
            CompressedPath = $null
            ValidationResult = $validation
        }

        # Handle datastore backup if requested
        if ($BackupType -in 'WithDatastore', 'Full') {
            $datastorePath = $validation.ConfigInfo.DatastorePath

            if ($datastorePath -and (Test-Path $datastorePath)) {
                $datastoreBackupPath = "$BackupPath.datastore"
                Write-VelociraptorLog "Backing up datastore: $datastorePath" -Level Info

                try {
                    # Create datastore backup directory
                    New-Item -ItemType Directory -Path $datastoreBackupPath -Force -ErrorAction SilentlyContinue | Out-Null

                    # Copy datastore files (excluding large filestore if needed)
                    $copyParams = @{
                        Path = "$datastorePath\*"
                        Destination = $datastoreBackupPath
                        Recurse = $true
                        Force = $true
                    }

                    Copy-Item @copyParams

                    $result.FilesBackedUp += $datastoreBackupPath
                    $result.DatastoreBackedUp = $true
                    Write-VelociraptorLog "Datastore backup completed" -Level Success
                }
                catch {
                    Write-VelociraptorLog "Warning: Datastore backup failed: $($_.Exception.Message)" -Level Warning
                }
            } else {
                Write-VelociraptorLog "Warning: Datastore path not found or not accessible" -Level Warning
            }
        }

        # Create metadata file
        if ($IncludeMetadata) {
            $metadataPath = "$BackupPath.metadata.json"

            $metadata = @{
                BackupInfo = @{
                    OriginalPath = $ConfigPath
                    BackupPath = $BackupPath
                    BackupType = $BackupType
                    BackupDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                    BackupBy = $env:USERNAME
                    ComputerName = $env:COMPUTERNAME
                }
                FileInfo = @{
                    OriginalSize = (Get-Item $ConfigPath).Length
                    OriginalHash = (Get-FileHash $ConfigPath -Algorithm SHA256).Hash
                    BackupSize = (Get-Item $BackupPath).Length
                    BackupHash = (Get-FileHash $BackupPath -Algorithm SHA256).Hash
                }
                ValidationResult = $validation
                SystemInfo = @{
                    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
                    OSVersion = [System.Environment]::OSVersion.ToString()
                    ModuleVersion = "1.0.0"
                }
            }

            $metadata | ConvertTo-Json -Depth 10 | Out-File $metadataPath -Encoding UTF8
            $result.MetadataPath = $metadataPath
            $result.FilesBackedUp += $metadataPath
            Write-VelociraptorLog "Metadata saved to: $metadataPath" -Level Debug
        }

        # Compress if requested
        if ($Compress) {
            $zipPath = [System.IO.Path]::ChangeExtension($BackupPath, '.zip')
            Write-VelociraptorLog "Compressing backup to: $zipPath" -Level Info

            try {
                # Create zip archive
                Compress-Archive -Path $result.FilesBackedUp -DestinationPath $zipPath -Force -ErrorAction SilentlyContinue

                # Remove original files after compression
                foreach ($file in $result.FilesBackedUp) {
                    if (Test-Path $file) {
                        if ((Get-Item $file).PSIsContainer) {
                            Remove-Item $file -Recurse -Force -ErrorAction SilentlyContinue
                        } else {
                            Remove-Item $file -Force -ErrorAction SilentlyContinue
                        }
                    }
                }

                $result.CompressedPath = $zipPath
                $result.FilesBackedUp = @($zipPath)
                Write-VelociraptorLog "Backup compressed successfully" -Level Success
            }
            catch {
                Write-VelociraptorLog "Warning: Compression failed: $($_.Exception.Message)" -Level Warning
            }
        }

        # Calculate total backup size
        $totalSize = 0
        foreach ($file in $result.FilesBackedUp) {
            if (Test-Path $file) {
                $item = Get-Item $file
                if ($item.PSIsContainer) {
                    $totalSize += (Get-ChildItem $file -Recurse | Measure-Object -Property Length -Sum).Sum
                } else {
                    $totalSize += $item.Length
                }
            }
        }

        $result | Add-Member -NotePropertyName 'TotalSizeMB' -NotePropertyValue ([math]::Round($totalSize / 1MB, 2))

        Write-VelociraptorLog "Backup completed successfully ($($result.TotalSizeMB) MB)" -Level Success
        return $result
    }
    catch {
        $errorMessage = "Backup failed: $($_.Exception.Message)"
        Write-VelociraptorLog $errorMessage -Level Error

        return [PSCustomObject]@{
            Success = $false
            ConfigPath = $ConfigPath
            BackupPath = $BackupPath
            Error = $_.Exception.Message
            BackupDate = Get-Date
        }
    }
}