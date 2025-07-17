<#
.SYNOPSIS
    Backup and restore Velociraptor data and configurations.

.DESCRIPTION
    Provides comprehensive backup and restore functionality for:
    • Configuration files
    • Datastore contents
    • Log files
    • Certificates and keys
    • Custom artifacts
    • Hunt results

.PARAMETER Action
    Action to perform: Backup, Restore, List, Verify

.PARAMETER BackupPath
    Path for backup storage

.PARAMETER DataPath
    Path to Velociraptor data directory

.PARAMETER ConfigPath
    Path to configuration file

.PARAMETER Compress
    Compress backup archives

.PARAMETER Incremental
    Perform incremental backup (only changed files)

.EXAMPLE
    .\Backup-VelociraptorData.ps1 -Action Backup -BackupPath "D:\Backups"

.EXAMPLE
    .\Backup-VelociraptorData.ps1 -Action Restore -BackupPath "D:\Backups\backup_20241216.zip"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Backup', 'Restore', 'List', 'Verify')]
    [string]$Action,
    
    [Parameter(Mandatory)]
    [string]$BackupPath,
    
    [string]$DataPath = 'C:\VelociraptorData',
    [string]$ConfigPath = 'C:\tools\server.yaml',
    [switch]$Compress,
    [switch]$Incremental
)

$ErrorActionPreference = 'Stop'

function Write-BackupLog {
    param([string]$Message, [string]$Level = 'Info')
    
    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        default { 'White' }
    }
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host "[$timestamp] $Message" -ForegroundColor $color
}

function New-VelociraptorBackup {
    param([string]$BackupPath, [string]$DataPath, [string]$ConfigPath, [bool]$Compress, [bool]$Incremental)
    
    Write-BackupLog "Starting Velociraptor backup..." -Level 'Success'
    
    try {
        # Create backup directory structure
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backupName = "velociraptor_backup_$timestamp"
        $backupDir = Join-Path $BackupPath $backupName
        
        if (-not (Test-Path $BackupPath)) {
            New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
        }
        
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        
        # Create backup manifest
        $manifest = @{
            BackupDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            BackupType = if ($Incremental) { 'Incremental' } else { 'Full' }
            ComputerName = $env:COMPUTERNAME
            UserName = $env:USERNAME
            VelociraptorVersion = 'Unknown'
            Files = @()
            TotalSize = 0
        }
        
        # Try to get Velociraptor version
        $veloExe = 'C:\tools\velociraptor.exe'
        if (Test-Path $veloExe) {
            try {
                $version = & $veloExe version 2>&1 | Select-Object -First 1
                $manifest.VelociraptorVersion = $version
            } catch {
                # Version detection failed
            }
        }
        
        # Backup configuration
        if (Test-Path $ConfigPath) {
            $configBackupPath = Join-Path $backupDir 'configuration'
            New-Item -ItemType Directory -Path $configBackupPath -Force | Out-Null
            
            Copy-Item $ConfigPath (Join-Path $configBackupPath (Split-Path $ConfigPath -Leaf))
            Write-BackupLog "✓ Configuration backed up"
            
            $manifest.Files += @{
                Type = 'Configuration'
                Source = $ConfigPath
                Size = (Get-Item $ConfigPath).Length
            }
        }
        
        # Backup datastore
        if (Test-Path $DataPath) {
            $datastoreBackupPath = Join-Path $backupDir 'datastore'
            Write-BackupLog "Backing up datastore (this may take a while)..."
            
            if ($Incremental) {
                # Incremental backup - only files modified in last 24 hours
                $cutoffDate = (Get-Date).AddDays(-1)
                $filesToBackup = Get-ChildItem -Path $DataPath -Recurse -File | Where-Object { $_.LastWriteTime -gt $cutoffDate }
                Write-BackupLog "Incremental backup: $($filesToBackup.Count) files modified since $($cutoffDate.ToString('yyyy-MM-dd HH:mm'))"
            } else {
                # Full backup
                $filesToBackup = Get-ChildItem -Path $DataPath -Recurse -File
                Write-BackupLog "Full backup: $($filesToBackup.Count) files"
            }
            
            foreach ($file in $filesToBackup) {
                $relativePath = $file.FullName.Substring($DataPath.Length + 1)
                $targetPath = Join-Path $datastoreBackupPath $relativePath
                $targetDir = Split-Path $target