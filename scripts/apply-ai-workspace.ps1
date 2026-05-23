<#
.SYNOPSIS
    One-command AI workspace applicator for any project.
.DESCRIPTION
    Detects project type, generates context files, CI, docs, agent rules,
    GitHub templates, and a project map. Supports DryRun, Backup, and Force.
.PARAMETER ProjectPath
    Path to the target project. Defaults to current directory.
.PARAMETER Preset
    Force a preset. Default is auto.
.PARAMETER IncludeCI
    Generate .github/workflows/ci.yml.
.PARAMETER IncludeSecretScan
    Copy secret-scan.yml workflow.
.PARAMETER IncludePrompts
    Copy ai-prompts directory.
.PARAMETER IncludeDocs
    Copy project docs templates.
.PARAMETER GenerateProjectMap
    Generate PROJECT_MAP.md.
.PARAMETER IncludeADR
    Add docs/adr/0001-project-direction.md.
.PARAMETER IncludePRD
    Add docs/PRD.md.
.PARAMETER IncludeRoadmap
    Add docs/ROADMAP.md.
.PARAMETER IncludeAgentRules
    Add AGENTS.md and AI_AGENT_RULES.md.
.PARAMETER IncludeGitHubTemplates
    Add GitHub issue and PR templates.
.PARAMETER DryRun
    Print planned actions without executing.
.PARAMETER Force
    Overwrite existing files.
.PARAMETER Backup
    Backup files before overwriting.
.EXAMPLE
    .\apply-ai-workspace.ps1 -ProjectPath C:\MyProject -Preset auto -IncludeCI -GenerateProjectMap -DryRun
    .\apply-ai-workspace.ps1 -ProjectPath C:\MyProject -Preset auto -IncludeCI -IncludeSecretScan -IncludePrompts -IncludeDocs -GenerateProjectMap -IncludeADR -IncludePRD -IncludeRoadmap -IncludeAgentRules -IncludeGitHubTemplates -Backup
#>
param (
    [Parameter(Mandatory=$false)]
    [string]$ProjectPath = '.',

    [ValidateSet('auto','python-backend','node-frontend','fullstack','static-website',
                 'ml-project','agentic-ai','trading-system','data-science')]
    [string]$Preset = 'auto',

    [switch]$IncludeCI,
    [switch]$IncludeSecretScan,
    [switch]$IncludePrompts,
    [switch]$IncludeDocs,
    [switch]$GenerateProjectMap,
    [switch]$IncludeADR,
    [switch]$IncludePRD,
    [switch]$IncludeRoadmap,
    [switch]$IncludeAgentRules,
    [switch]$IncludeGitHubTemplates,
    [switch]$DryRun,
    [switch]$Force,
    [switch]$Backup
)

$ErrorActionPreference = 'Stop'
$WorkspaceRoot = Split-Path -Parent $PSScriptRoot

# --- tracking -----------------------------------------------------------------
$filesCreated  = [System.Collections.Generic.List[string]]::new()
$filesSkipped  = [System.Collections.Generic.List[string]]::new()
$filesBackedUp = [System.Collections.Generic.List[string]]::new()
$warnings      = [System.Collections.Generic.List[string]]::new()
$script:backupDir = ''

# --- helpers ------------------------------------------------------------------
function Write-Step([string]$msg) { Write-Host "  -> $msg" -ForegroundColor Cyan }
function Write-Warn([string]$msg) {
    Write-Host "  ! $msg" -ForegroundColor Yellow
    $warnings.Add($msg)
}
function Write-Done([string]$msg) { Write-Host "  OK $msg" -ForegroundColor Green }

function Get-BackupDir {
    $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
    return Join-Path $ProjectPath ".ai-workspace-backup\$ts"
}

function Ensure-BackupDir {
    if (-not $script:backupDir) { $script:backupDir = Get-BackupDir }
}

function Safe-Copy {
    param([string]$src, [string]$dest, [string]$label)

    if (-not (Test-Path $src)) { Write-Warn "Source not found, skipping: $src"; return }

    if ($DryRun) {
        Write-Step "[DRY RUN] Would copy $label -> $dest"
        $filesCreated.Add("[DRY RUN] $dest")
        return
    }

    if ((Test-Path $dest) -and -not $Force) {
        Write-Warn "Already exists (use -Force): $dest"
        $filesSkipped.Add($dest)
        return
    }

    if ((Test-Path $dest) -and $Backup) {
        Ensure-BackupDir
        $relDest      = $dest.Replace($ProjectPath, '').TrimStart('\/')
        $backupTarget = Join-Path $script:backupDir $relDest
        $backupParent = Split-Path $backupTarget -Parent
        if (-not (Test-Path $backupParent)) { New-Item -ItemType Directory -Path $backupParent -Force | Out-Null }
        Copy-Item $dest $backupTarget -Force
        $filesBackedUp.Add($dest)
    }

    $destParent = Split-Path $dest -Parent
    if (-not (Test-Path $destParent)) { New-Item -ItemType Directory -Path $destParent -Force | Out-Null }
    Copy-Item $src $dest -Force
    $filesCreated.Add($dest)
    Write-Done "Created: $(Split-Path $dest -Leaf)"
}

# --- banner -------------------------------------------------------------------
Write-Host ''
Write-Host 'AI Workspace v2 - Universal Project Applicator' -ForegroundColor Cyan
Write-Host ('-' * 54) -ForegroundColor Cyan
Write-Host ''

# --- validate project path ----------------------------------------------------
if (-not (Test-Path $ProjectPath)) {
    Write-Error "ProjectPath does not exist: $ProjectPath"
    exit 1
}
$ProjectPath = (Resolve-Path $ProjectPath).Path
Write-Host "Target project : $ProjectPath" -ForegroundColor Yellow
Write-Host "Workspace root : $WorkspaceRoot" -ForegroundColor Gray
if ($DryRun) { Write-Host '  *** DRY RUN MODE - no files will be written ***' -ForegroundColor Magenta }
Write-Host ''

# --- detect project -----------------------------------------------------------
$DetectScript = Join-Path $WorkspaceRoot 'scripts\detect-project.ps1'
if (-not (Test-Path $DetectScript)) {
    Write-Error "detect-project.ps1 not found at: $DetectScript"
    exit 1
}

Write-Host 'Detecting project type...' -ForegroundColor Cyan
$detection = & $DetectScript -ProjectPath $ProjectPath -Json | ConvertFrom-Json
Write-Host "Detected type  : $($detection.ProjectType)" -ForegroundColor Yellow
Write-Host "Preset         : $($detection.RecommendedPreset)" -ForegroundColor Yellow
Write-Host ''

if ($detection.EnvFilesTracked) {
    Write-Warn '.env is tracked by git in target project - this is a security risk!'
}

# --- plan ---------------------------------------------------------------------
Write-Host 'Planned actions:' -ForegroundColor Cyan
if ($GenerateProjectMap)    { Write-Step 'Generate PROJECT_MAP.md' }
if ($IncludeCI)             { Write-Step 'Generate .github/workflows/ci.yml' }
if ($IncludeSecretScan)     { Write-Step 'Copy secret-scan.yml workflow' }
if ($IncludePrompts)        { Write-Step 'Copy ai-prompts templates' }
if ($IncludeDocs)           { Write-Step 'Copy project-docs templates' }
if ($IncludeADR)            { Write-Step 'Add docs/adr/0001-project-direction.md' }
if ($IncludePRD)            { Write-Step 'Add docs/PRD.md' }
if ($IncludeRoadmap)        { Write-Step 'Add docs/ROADMAP.md' }
if ($IncludeAgentRules)     { Write-Step 'Add AGENTS.md and AI_AGENT_RULES.md' }
if ($IncludeGitHubTemplates){ Write-Step 'Add GitHub issue/PR templates' }
Write-Host ''

if ($DryRun) {
    Write-Host 'DRY RUN complete. No files written.' -ForegroundColor Magenta
    Write-Host 'Remove -DryRun to apply for real (add -Backup for safety).'
    return
}

# --- generate project map -----------------------------------------------------
if ($GenerateProjectMap) {
    Write-Host '-- Generating Project Map --' -ForegroundColor Cyan
    $MapScript = Join-Path $WorkspaceRoot 'scripts\generate-project-map.ps1'
    if (Test-Path $MapScript) {
        $mapDest = Join-Path $ProjectPath 'PROJECT_MAP.md'
        if ((Test-Path $mapDest) -and -not $Force -and -not $Backup) {
            Write-Warn 'PROJECT_MAP.md exists. Use -Force or -Backup to overwrite.'
            $filesSkipped.Add($mapDest)
        } else {
            if ((Test-Path $mapDest) -and $Backup) {
                Ensure-BackupDir
                $backupTarget = Join-Path $script:backupDir 'PROJECT_MAP.md'
                $bp = Split-Path $backupTarget -Parent
                if (-not (Test-Path $bp)) { New-Item -ItemType Directory -Path $bp -Force | Out-Null }
                Copy-Item $mapDest $backupTarget -Force -ErrorAction SilentlyContinue
                $filesBackedUp.Add($mapDest)
            }
            & $MapScript -ProjectPath $ProjectPath -OutputPath $mapDest
            $filesCreated.Add($mapDest)
        }
    } else { Write-Warn 'generate-project-map.ps1 not found.' }
}

# --- generate CI --------------------------------------------------------------
if ($IncludeCI) {
    Write-Host '-- Generating CI Workflow --' -ForegroundColor Cyan
    $CIScript = Join-Path $WorkspaceRoot 'scripts\generate-ci.ps1'
    if (Test-Path $CIScript) {
        $ciArgs = @('-ProjectPath', $ProjectPath, '-Preset', $Preset)
        if ($Force)  { $ciArgs += '-Force' }
        if ($Backup) { $ciArgs += '-Backup' }
        & $CIScript @ciArgs
        $ciFile = Join-Path $ProjectPath '.github\workflows\ci.yml'
        if ((Test-Path $ciFile) -and $filesCreated -notcontains $ciFile) { $filesCreated.Add($ciFile) }
    } else { Write-Warn 'generate-ci.ps1 not found.' }
}

# --- secret scan --------------------------------------------------------------
if ($IncludeSecretScan) {
    Write-Host '-- Adding Secret Scan Workflow --' -ForegroundColor Cyan
    $src  = Join-Path $WorkspaceRoot 'templates\github-actions\security\secret-scan.yml'
    $dest = Join-Path $ProjectPath '.github\workflows\secret-scan.yml'
    Safe-Copy $src $dest 'secret-scan.yml'
}

# --- prompts ------------------------------------------------------------------
if ($IncludePrompts) {
    Write-Host '-- Copying AI Prompts --' -ForegroundColor Cyan
    $srcDir  = Join-Path $WorkspaceRoot 'templates\prompts'
    $destDir = Join-Path $ProjectPath 'ai-prompts'
    if (Test-Path $srcDir) {
        Get-ChildItem -Path $srcDir -File | ForEach-Object {
            Safe-Copy $_.FullName (Join-Path $destDir $_.Name) $_.Name
        }
    } else { Write-Warn 'templates\prompts directory not found.' }
}

# --- project docs -------------------------------------------------------------
if ($IncludeDocs) {
    Write-Host '-- Copying Project Docs --' -ForegroundColor Cyan
    $srcDir  = Join-Path $WorkspaceRoot 'templates\project-docs'
    $destDir = Join-Path $ProjectPath 'docs'
    if (Test-Path $srcDir) {
        Get-ChildItem -Path $srcDir -File | ForEach-Object {
            Safe-Copy $_.FullName (Join-Path $destDir $_.Name) $_.Name
        }
    } else { Write-Warn 'templates\project-docs directory not found.' }
}

# --- ADR ----------------------------------------------------------------------
if ($IncludeADR) {
    Write-Host '-- Adding ADR --' -ForegroundColor Cyan
    $src  = Join-Path $WorkspaceRoot 'templates\adr\0001-project-direction.md'
    $dest = Join-Path $ProjectPath 'docs\adr\0001-project-direction.md'
    Safe-Copy $src $dest '0001-project-direction.md'
}

# --- PRD ----------------------------------------------------------------------
if ($IncludePRD) {
    Write-Host '-- Adding PRD --' -ForegroundColor Cyan
    $src  = Join-Path $WorkspaceRoot 'templates\project-docs\PRD.md'
    $dest = Join-Path $ProjectPath 'docs\PRD.md'
    Safe-Copy $src $dest 'PRD.md'
}

# --- Roadmap ------------------------------------------------------------------
if ($IncludeRoadmap) {
    Write-Host '-- Adding Roadmap --' -ForegroundColor Cyan
    $src  = Join-Path $WorkspaceRoot 'templates\project-docs\ROADMAP.md'
    $dest = Join-Path $ProjectPath 'docs\ROADMAP.md'
    Safe-Copy $src $dest 'ROADMAP.md'
}

# --- Agent Rules --------------------------------------------------------------
if ($IncludeAgentRules) {
    Write-Host '-- Adding Agent Rules --' -ForegroundColor Cyan
    foreach ($name in @('AGENTS.md','AI_AGENT_RULES.md')) {
        $src  = Join-Path $WorkspaceRoot "templates\agent-rules\$name"
        $dest = Join-Path $ProjectPath $name
        Safe-Copy $src $dest $name
    }
}

# --- GitHub Templates ---------------------------------------------------------
if ($IncludeGitHubTemplates) {
    Write-Host '-- Adding GitHub Templates --' -ForegroundColor Cyan
    $srcBase = Join-Path $WorkspaceRoot 'templates\github'

    $prSrc  = Join-Path $srcBase 'PULL_REQUEST_TEMPLATE.md'
    $prDest = Join-Path $ProjectPath '.github\PULL_REQUEST_TEMPLATE.md'
    Safe-Copy $prSrc $prDest 'PULL_REQUEST_TEMPLATE.md'

    $issueDir = Join-Path $srcBase 'ISSUE_TEMPLATE'
    if (Test-Path $issueDir) {
        Get-ChildItem -Path $issueDir -File | ForEach-Object {
            $d = Join-Path $ProjectPath ".github\ISSUE_TEMPLATE\$($_.Name)"
            Safe-Copy $_.FullName $d $_.Name
        }
    }
}

# --- Final Report -------------------------------------------------------------
Write-Host ''
Write-Host 'Application Complete' -ForegroundColor Green
Write-Host ('-' * 54) -ForegroundColor Green
Write-Host ''
Write-Host "  Files created  : $($filesCreated.Count)" -ForegroundColor Green
Write-Host "  Files skipped  : $($filesSkipped.Count)" -ForegroundColor Yellow
Write-Host "  Files backed up: $($filesBackedUp.Count)" -ForegroundColor Cyan
Write-Host "  Warnings       : $($warnings.Count)" -ForegroundColor $(if($warnings.Count -gt 0){'Yellow'}else{'Gray'})
Write-Host ''

if ($filesCreated.Count -gt 0) {
    Write-Host '  Created:' -ForegroundColor Green
    $filesCreated | ForEach-Object { Write-Host "    $_" -ForegroundColor Green }
    Write-Host ''
}
if ($filesSkipped.Count -gt 0) {
    Write-Host '  Skipped (already exist - use -Force to overwrite):' -ForegroundColor Yellow
    $filesSkipped | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
    Write-Host ''
}
if ($filesBackedUp.Count -gt 0) {
    Write-Host "  Backed up to: $script:backupDir" -ForegroundColor Cyan
    Write-Host ''
}
if ($warnings.Count -gt 0) {
    Write-Host '  Warnings:' -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "    ! $_" -ForegroundColor Yellow }
    Write-Host ''
}

Write-Host '  Recommended next steps:' -ForegroundColor Cyan
Write-Host '    1. Review generated files: git diff --stat'
Write-Host '    2. Run doctor: powershell -ExecutionPolicy Bypass -File scripts\doctor.ps1'
Write-Host '    3. Read PROJECT_MAP.md to understand the project structure.'
Write-Host '    4. Run a secret scan before pushing to remote.'
Write-Host '    5. Commit only what you intend: git add -p'
Write-Host ''