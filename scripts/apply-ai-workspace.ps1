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

function Get-ValidPresets {
    $jsonPath = Join-Path $PSScriptRoot "presets.json"
    if (Test-Path $jsonPath) {
        return (Get-Content $jsonPath -Raw | ConvertFrom-Json)
    }
    return @('auto', 'unknown', 'python-backend', 'node-frontend', 'fullstack', 'static-website', 'ml-project', 'agentic-ai', 'trading-system', 'data-science')
}

function Assert-ValidPreset([string]$p) {
    $valid = Get-ValidPresets
    if ($p -notin $valid) {
        throw "Invalid preset '$p'. Valid presets are: $($valid -join ', ')"
    }
}

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

# --- PREFLIGHT PHASE ----------------------------------------------------------

# 1. Validate project path
if (-not (Test-Path $ProjectPath)) {
    throw "Preflight failed: ProjectPath does not exist: $ProjectPath"
}
$ProjectPath = (Resolve-Path $ProjectPath).Path

# 2. Assert input preset is canonically valid
Assert-ValidPreset $Preset

# Verify scripts exist
$DetectScript = Join-Path $WorkspaceRoot 'scripts\detect-project.ps1'
if (-not (Test-Path $DetectScript)) {
    throw "Preflight failed: detect-project.ps1 not found at '$DetectScript'"
}
$MapScript = Join-Path $WorkspaceRoot 'scripts\generate-project-map.ps1'
$CIScript  = Join-Path $WorkspaceRoot 'scripts\generate-ci.ps1'

# 3. Detect project
$detectParams = @{
    ProjectPath = $ProjectPath
    Json        = $true
}
$detection = & $DetectScript @detectParams | ConvertFrom-Json

# 4. Resolve and validate preset
$effectivePreset = if ($Preset -eq 'auto') { $detection.RecommendedPreset } else { $Preset }
Assert-ValidPreset $effectivePreset

# 5. Verify template files exist
$requiredTemplates = [System.Collections.Generic.List[string]]::new()
if ($IncludeSecretScan) { $requiredTemplates.Add('templates\github-actions\security\secret-scan.yml') }
if ($IncludePrompts) { $requiredTemplates.Add('templates\prompts') }
if ($IncludeDocs) { $requiredTemplates.Add('templates\project-docs') }
if ($IncludeADR) { $requiredTemplates.Add('templates\adr\0001-project-direction.md') }
if ($IncludePRD) { $requiredTemplates.Add('templates\project-docs\PRD.md') }
if ($IncludeRoadmap) { $requiredTemplates.Add('templates\project-docs\ROADMAP.md') }
if ($IncludeAgentRules) {
    $requiredTemplates.Add('templates\agent-rules\AGENTS.md')
    $requiredTemplates.Add('templates\agent-rules\AI_AGENT_RULES.md')
}
if ($IncludeGitHubTemplates) {
    $requiredTemplates.Add('templates\github\PULL_REQUEST_TEMPLATE.md')
    $requiredTemplates.Add('templates\github\ISSUE_TEMPLATE')
}

foreach ($t in $requiredTemplates) {
    $p = Join-Path $WorkspaceRoot $t
    if (-not (Test-Path $p)) {
        throw "Preflight failed: Required template source not found at '$p'"
    }
}

# 6. Verify generate-project-map.ps1 can run in -NoWrite mode
if ($GenerateProjectMap) {
    if (-not (Test-Path $MapScript)) {
        throw "Preflight failed: generate-project-map.ps1 not found at '$MapScript'"
    }
    $mapPreflightParams = @{
        ProjectPath = $ProjectPath
        NoWrite     = $true
    }
    $null = & $MapScript @mapPreflightParams
}

# 7. Verify generate-ci.ps1 can run in -DryRun mode if IncludeCI is requested
if ($IncludeCI) {
    if (-not (Test-Path $CIScript)) {
        throw "Preflight failed: generate-ci.ps1 not found at '$CIScript'"
    }
    $ciPreflightParams = @{
        ProjectPath = $ProjectPath
        Preset      = $effectivePreset
        DryRun      = $true
    }
    $null = & $CIScript @ciPreflightParams
}

# --- banner -------------------------------------------------------------------
Write-Host ''
Write-Host 'AI Workspace v2 - Universal Project Applicator' -ForegroundColor Cyan
Write-Host ('-' * 54) -ForegroundColor Cyan
Write-Host ''

Write-Host "Target project : $ProjectPath" -ForegroundColor Yellow
Write-Host "Workspace root : $WorkspaceRoot" -ForegroundColor Gray
if ($DryRun) { Write-Host '  *** DRY RUN MODE - no files will be written ***' -ForegroundColor Magenta }
Write-Host ''

# Print detection results
Write-Host "Detected type  : $($detection.ProjectType)" -ForegroundColor Yellow
Write-Host "Preset         : $effectivePreset" -ForegroundColor Yellow
Write-Host "Domain Hints   : $($detection.DomainHints -join ', ')" -ForegroundColor Yellow
Write-Host "Confidence     : $($detection.Confidence)" -ForegroundColor Yellow
Write-Host "Evidence       :" -ForegroundColor Yellow
foreach ($ev in $detection.DetectionEvidence) {
    Write-Host "  - $ev" -ForegroundColor Gray
}
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
        $mapParams = @{
            ProjectPath = $ProjectPath
            OutputPath  = $mapDest
        }
        & $MapScript @mapParams
        $filesCreated.Add($mapDest)
    }
}

# --- generate CI --------------------------------------------------------------
if ($IncludeCI) {
    Write-Host '-- Generating CI Workflow --' -ForegroundColor Cyan
    $ciFile = Join-Path $ProjectPath '.github\workflows\ci.yml'
    if ((Test-Path $ciFile) -and -not $Force -and -not $Backup) {
        Write-Warn 'ci.yml exists. Use -Force or -Backup to overwrite.'
        $filesSkipped.Add($ciFile)
    } else {
        if ((Test-Path $ciFile) -and $Backup) {
            Ensure-BackupDir
            $backupTarget = Join-Path $script:backupDir '.github\workflows\ci.yml'
            $bp = Split-Path $backupTarget -Parent
            if (-not (Test-Path $bp)) { New-Item -ItemType Directory -Path $bp -Force | Out-Null }
            Copy-Item $ciFile $backupTarget -Force -ErrorAction SilentlyContinue
            $filesBackedUp.Add($ciFile)
        }
        $ciParams = @{
            ProjectPath = $ProjectPath
            Preset      = $effectivePreset
        }
        if ($Force)  { $ciParams.Force  = $true }
        if ($Backup) { $ciParams.Backup = $true }
        & $CIScript @ciParams
        if ((Test-Path $ciFile) -and $filesCreated -notcontains $ciFile) { $filesCreated.Add($ciFile) }
    }
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