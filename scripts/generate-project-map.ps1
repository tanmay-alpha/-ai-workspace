<#
.SYNOPSIS
    Generates a PROJECT_MAP.md for any project directory.
.DESCRIPTION
    Uses detect-project.ps1 internally to analyze the project, then writes
    a comprehensive markdown map for AI agents and developers.
.PARAMETER ProjectPath
    Path to the project root. Defaults to current directory.
.PARAMETER OutputPath
    Where to write PROJECT_MAP.md. Defaults to ProjectPath/PROJECT_MAP.md.
.PARAMETER NoWrite
    Print to console instead of writing file.
.PARAMETER IncludeTree
    Include a directory tree snapshot.
.PARAMETER MaxDepth
    Max depth for directory tree. Default 3.
.EXAMPLE
    .\generate-project-map.ps1 -ProjectPath C:\MyProject
    .\generate-project-map.ps1 -ProjectPath C:\MyProject -NoWrite -IncludeTree
#>
param (
    [Parameter(Mandatory=$false)]
    [string]$ProjectPath = '.',

    [string]$OutputPath = '',

    [switch]$NoWrite,

    [switch]$IncludeTree,

    [int]$MaxDepth = 3
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $ProjectPath)) {
    Write-Error "ProjectPath does not exist: $ProjectPath"
    exit 1
}

$ProjectPath   = (Resolve-Path $ProjectPath).Path
$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$DetectScript  = Join-Path $WorkspaceRoot 'scripts\detect-project.ps1'

if (-not $NoWrite) {
    Write-Host "Analyzing project: $ProjectPath" -ForegroundColor Cyan
}

# --- run detection ------------------------------------------------------------
if (Test-Path $DetectScript) {
    $detection = & $DetectScript -ProjectPath $ProjectPath -Json | ConvertFrom-Json
} else {
    Write-Warning 'detect-project.ps1 not found. Using basic detection.'
    $detection = [PSCustomObject]@{
        ProjectType='unknown'; RecommendedPreset='unknown'
        BackendPath=''; FrontendPath=''; PythonDependencyFile=''
        PythonVersionHint='3.11'; PythonTestCommand=''; PythonCompileCommand='python -m compileall . -q'
        NodePath=''; NodePackageManager='none'; NodeInstallCommand=''; NodeBuildCommand=''; NodeTestCommand=''
        HasDockerfile=$false; HasDockerCompose=$false; HasGitHubWorkflows=$false
        HasEnvFile=$false; EnvFilesTracked=$false; HasTests=$false
        HasFrontend=$false; HasBackend=$false; HasDatabaseHints=$false
        HasMLHints=$false; HasTradingHints=$false; HasAgenticHints=$false
        RiskNotes=@('Detection script unavailable.')
    }
}

# --- ignore list --------------------------------------------------------------
$ignorePatterns = @('.git','node_modules','venv','.venv','dist','build','.next','out',
    'coverage','__pycache__','.pytest_cache','uploads','.mypy_cache','.ruff_cache',
    '.tox','.eggs','.nuxt','htmlcov','.DS_Store')

function Should-Ignore([string]$fullPath) {
    foreach ($pat in $ignorePatterns) {
        if ($fullPath -match [regex]::Escape("\$pat") -or
            $fullPath -match [regex]::Escape("/$pat")) { return $true }
        $seg = Split-Path $fullPath -Leaf
        if ($seg -eq $pat) { return $true }
    }
    return $false
}

function Get-RelPath([string]$full) {
    $full.Replace($ProjectPath, '').TrimStart('\/').Replace('\','/')
}

# --- collect files ------------------------------------------------------------
$allFiles = Get-ChildItem -Path $ProjectPath -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object {
        $keep = $true
        foreach ($pat in $ignorePatterns) {
            if ($_.FullName -match [regex]::Escape($pat)) { $keep = $false; break }
        }
        $keep
    }

$entryPoints = $allFiles | Where-Object {
    $_.Name -match '^(index|main|app|server|start|run|manage|worker|celery)\.(js|ts|py|html|mjs|cjs)$'
} | ForEach-Object { Get-RelPath $_.FullName }

$testFiles = $allFiles | Where-Object {
    $_.FullName -match '[/\\](tests|test|spec|__tests__)[/\\]' -or
    $_.Name -match '^test_|^spec_|\.test\.|\.spec\.'
} | Select-Object -First 20 | ForEach-Object { Get-RelPath $_.FullName }

$workflowFiles = Get-ChildItem -Path (Join-Path $ProjectPath '.github\workflows') -File -ErrorAction SilentlyContinue |
    ForEach-Object { ".github/workflows/$($_.Name)" }

$docFiles = $allFiles | Where-Object { $_.Extension -eq '.md' } |
    Select-Object -First 20 | ForEach-Object { Get-RelPath $_.FullName }

$depFiles = @()
foreach ($f in @('requirements.txt','backend/requirements.txt','pyproject.toml','setup.py',
    'package.json','frontend/package.json','client/package.json','go.mod','Cargo.toml','Gemfile')) {
    if (Test-Path (Join-Path $ProjectPath $f)) { $depFiles += $f }
}

$importantDirs = Get-ChildItem -Path $ProjectPath -Directory -ErrorAction SilentlyContinue |
    Where-Object {
        $keep = $true
        foreach ($pat in $ignorePatterns) { if ($_.Name -eq $pat) { $keep = $false; break } }
        $keep
    } | ForEach-Object { $_.Name } | Sort-Object

# --- directory tree (optional) -----------------------------------------------
$treeSection = ''
if ($IncludeTree) {
    $treeLines = [System.Collections.Generic.List[string]]::new()
    function Write-Tree([string]$path, [string]$prefix, [int]$depth) {
        if ($depth -gt $MaxDepth) { return }
        $items = Get-ChildItem -Path $path -ErrorAction SilentlyContinue |
            Where-Object {
                $keep = $true
                foreach ($pat in $ignorePatterns) { if ($_.Name -eq $pat) { $keep = $false; break } }
                $keep
            } | Sort-Object Name
        $count = $items.Count
        for ($i = 0; $i -lt $count; $i++) {
            $item   = $items[$i]
            $isLast = ($i -eq $count - 1)
            $conn   = if ($isLast) { '`-- ' } else { '|-- ' }
            $treeLines.Add("$prefix$conn$($item.Name)$(if($item.PSIsContainer){'/'} else {''})")
            if ($item.PSIsContainer) {
                $newPfx = if ($isLast) { "$prefix    " } else { "$prefix|   " }
                Write-Tree $item.FullName $newPfx ($depth + 1)
            }
        }
    }
    Write-Tree $ProjectPath '' 0
    $treeText = $treeLines -join "`n"
    $treeSection = "`n## Directory Tree (depth $MaxDepth)`n`n``````n$treeText`n``````"
}

# --- build sections -----------------------------------------------------------
function Format-List([string[]]$items, [string]$fallback='- None detected') {
    if ($items -and $items.Count -gt 0) { return ($items | ForEach-Object { "- $_ " }) -join "`n" }
    return $fallback
}

$safeCommands = [System.Collections.Generic.List[string]]::new()
if ($detection.PythonCompileCommand) { $safeCommands.Add("# Syntax check`n$($detection.PythonCompileCommand)") }
if ($detection.PythonTestCommand)    { $safeCommands.Add("# Run tests`n$($detection.PythonTestCommand)") }
if ($detection.NodeInstallCommand)   { $safeCommands.Add("# Install node dependencies`n$($detection.NodeInstallCommand)") }
if ($detection.NodeBuildCommand -and $detection.HasFrontend) {
    $safeCommands.Add("# Build frontend`n$($detection.NodeBuildCommand)")
}
$safeCommandsText = if ($safeCommands.Count -gt 0) { $safeCommands -join "`n`n" }
                    else { '# No commands auto-detected. Review package files manually.' }

$riskText  = ($detection.RiskNotes | ForEach-Object { "- $_ " }) -join "`n"
$depText   = Format-List $depFiles
$docText   = Format-List $docFiles
$testText  = Format-List $testFiles
$epText    = Format-List $entryPoints
$wfText    = Format-List $workflowFiles
$dirText   = Format-List $importantDirs

$generated   = Get-Date -Format 'yyyy-MM-dd HH:mm'
$projectName = Split-Path $ProjectPath -Leaf

$md = @"
# Project Map

**Project Name:** $projectName
**Generated on:** $generated
**Path:** $ProjectPath

---

## Project Summary

| Field | Value |
|---|---|
| **Project Name** | $projectName |
| **Path** | $ProjectPath |
| **Detected Type** | $($detection.ProjectType) |
| **Recommended CI Preset** | $($detection.RecommendedPreset) |
| **Has Backend** | $($detection.HasBackend) |
| **Has Frontend** | $($detection.HasFrontend) |
| **Has Tests** | $($detection.HasTests) |
| **Has Dockerfile** | $($detection.HasDockerfile) |
| **Has GitHub Workflows** | $($detection.HasGitHubWorkflows) |
| **Has ML Hints** | $($detection.HasMLHints) |
| **Has Trading Hints** | $($detection.HasTradingHints) |
| **Has Agentic AI Hints** | $($detection.HasAgenticHints) |
| **Has Database Hints** | $($detection.HasDatabaseHints) |

---

## Paths

| Role | Path |
|---|---|
| Backend | $(if($detection.BackendPath){$detection.BackendPath}else{'(not detected)'}) |
| Frontend | $(if($detection.FrontendPath){$detection.FrontendPath}else{'(not detected)'}) |
| Python Dep File | $(if($detection.PythonDependencyFile){$detection.PythonDependencyFile}else{'(none)'}) |
| Node Package Manager | $($detection.NodePackageManager) |

---

## Dependency Files

$depText

---

## Entry Points

$epText

---

## Test Files

$testText

---

## GitHub Workflows

$wfText

---

## Documentation Files

$docText

---

## Important Directories

$dirText

---

## Ignored / Generated Directories

The following are excluded from this map (generated, deps, build artifacts):

- ``.git/``
- ``node_modules/``
- ``venv/``, ``.venv/``
- ``dist/``, ``build/``, ``.next/``, ``out/``
- ``coverage/``, ``htmlcov/``
- ``__pycache__/``, ``.pytest_cache/``, ``.mypy_cache/``
- ``uploads/``

---

## Safe Commands to Run

```bash
$safeCommandsText
```

---

## Do Not Touch

- **``.env``** - Never commit. Contains secrets and credentials.
- **``node_modules/``** - Generated. Run install command instead.
- **``venv/`` / ``.venv/``** - Generated. Use ``pip install -r requirements.txt``.
- **``dist/`` / ``build/``** - Generated artifacts.
- **Any file containing real API keys, passwords, or tokens.**

---

## Risk Notes

$riskText

---

## AI Agent Working Instructions

1. Always read this file before starting work on the project.
2. Understand the detected project type before making any changes.
3. Run syntax/compile checks after any Python edits.
4. Run the test suite if present before marking a task complete.
5. Never write to ``.env`` files or create files containing real secrets.
6. Never commit generated folders (node_modules, venv, __pycache__).
7. Check CI workflows are valid before pushing.
8. For trading/financial projects: never place real orders in tests or CI.
9. For agentic AI projects: never embed live API keys in CI configuration.
10. Raise a warning if hardcoded credentials are detected anywhere.

---

## Suggested Next Audit Prompts

- "Audit the backend for missing input validation and unsafe defaults."
- "Review all CI workflows for missing secrets or broken steps."
- "Check all API endpoints for authentication and authorization gaps."
- "Identify untested code paths and suggest concrete test cases."
- "Review dependency files for outdated or known-vulnerable packages."
- "Verify .gitignore covers all generated and secret files."
- "Suggest a security hardening checklist for this project type."
$treeSection
"@

if ($NoWrite) {
    $md
} else {
    $dest = if ($OutputPath) { $OutputPath } else { Join-Path $ProjectPath 'PROJECT_MAP.md' }
    $md | Out-File -FilePath $dest -Encoding utf8
    Write-Host "Project map written to: $dest" -ForegroundColor Green
    Write-Host "Detected type         : $($detection.ProjectType)" -ForegroundColor Yellow
}