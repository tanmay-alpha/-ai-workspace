<#
.SYNOPSIS
    Rolls back ai-workspace changes applied to a project.
.DESCRIPTION
    Restores files from a .ai-workspace-backup/<timestamp>/ directory.
    Never deletes backups automatically.
.PARAMETER ProjectPath
    Path to the target project. Defaults to current directory.
.PARAMETER BackupName
    Specific backup timestamp to restore. If omitted, uses the latest backup.
.PARAMETER List
    List all available backups.
.PARAMETER DryRun
    Show what would be restored without doing it.
.EXAMPLE
    .\rollback-ai-workspace.ps1 -ProjectPath C:\MyProject -List
    .\rollback-ai-workspace.ps1 -ProjectPath C:\MyProject
    .\rollback-ai-workspace.ps1 -ProjectPath C:\MyProject -BackupName 20250524_120000 -DryRun
#>
param (
    [Parameter(Mandatory=$false)]
    [string]$ProjectPath = '.',

    [string]$BackupName = '',

    [switch]$List,

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $ProjectPath)) {
    Write-Error "ProjectPath does not exist: $ProjectPath"
    return
}
$ProjectPath = (Resolve-Path $ProjectPath).Path
$backupBase  = Join-Path $ProjectPath '.ai-workspace-backup'

Write-Host ''
Write-Host 'ai-workspace - Rollback Tool' -ForegroundColor Cyan
Write-Host ('-' * 54) -ForegroundColor Cyan
Write-Host ''

if (-not (Test-Path $backupBase)) {
    Write-Host '  No backups found. .ai-workspace-backup directory does not exist.' -ForegroundColor Yellow
    Write-Host "  Expected location: $backupBase" -ForegroundColor Gray
    Write-Host ''
    Write-Host '  Backups are created automatically when you run apply-ai-workspace.ps1 with -Backup.'
    return
}

$backups = Get-ChildItem -Path $backupBase -Directory -ErrorAction SilentlyContinue | Sort-Object Name

if ($backups.Count -eq 0) {
    Write-Host '  No backup snapshots found in .ai-workspace-backup.' -ForegroundColor Yellow
    return
}

if ($List) {
    Write-Host '  Available backups (latest last):' -ForegroundColor Cyan
    foreach ($b in $backups) {
        Write-Host "    $($b.Name)"
    }
    Write-Host ''
    return
}

# Find target backup
$targetBackupDir = $null
if ($BackupName) {
    $targetBackupDir = Join-Path $backupBase $BackupName
    if (-not (Test-Path $targetBackupDir)) {
        Write-Error "Backup '$BackupName' not found at '$targetBackupDir'"
        return
    }
} else {
    # Use latest backup
    $targetBackupDir = $backups[-1].FullName
}

Write-Host "  Restoring from: $(Split-Path $targetBackupDir -Leaf)" -ForegroundColor Yellow
if ($DryRun) {
    Write-Host '  *** DRY RUN MODE - no files will be written ***' -ForegroundColor Magenta
}
Write-Host ''

$backupFiles = Get-ChildItem -Path $targetBackupDir -File -Recurse -ErrorAction SilentlyContinue
if ($backupFiles.Count -eq 0) {
    Write-Host '  No files found in the selected backup snapshot.' -ForegroundColor Yellow
    return
}

$restoredCount = 0
foreach ($file in $backupFiles) {
    # Compute relative path of the file from the target backup directory
    $relPath = $file.FullName.Substring($targetBackupDir.Length).TrimStart('\/')
    # Compute destination path
    $destPath = Join-Path $ProjectPath $relPath
    
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would restore: $relPath -> $destPath" -ForegroundColor Gray
    } else {
        $destParent = Split-Path $destPath -Parent
        if (-not (Test-Path $destParent)) {
            New-Item -ItemType Directory -Path $destParent -Force | Out-Null
        }
        Copy-Item $file.FullName $destPath -Force
        Write-Host "  Restored: $relPath" -ForegroundColor Green
        $restoredCount++
    }
}

Write-Host ''
if (-not $DryRun) {
    Write-Host "  Successfully restored $restoredCount files." -ForegroundColor Green
} else {
    Write-Host "  [DRY RUN] Would restore $($backupFiles.Count) files." -ForegroundColor Magenta
}
Write-Host ''
return