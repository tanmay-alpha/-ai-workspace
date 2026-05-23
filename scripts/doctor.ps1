<#
.SYNOPSIS
    Diagnostic tool for ai-workspace and target projects.
.DESCRIPTION
    Checks that ai-workspace is healthy (scripts, docs, templates exist).
    If -ProjectPath is given, also audits that target project.
.PARAMETER ProjectPath
    Optional target project path to audit.
.PARAMETER Json
    Output as JSON.
.EXAMPLE
    .\doctor.ps1
    .\doctor.ps1 -ProjectPath C:\MyProject
    .\doctor.ps1 -ProjectPath C:\MyProject -Json
#>
param (
    [string]$ProjectPath = '',
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$WorkspaceRoot = Split-Path -Parent $PSScriptRoot

$results = [System.Collections.Generic.List[PSCustomObject]]::new()

function Add-Check {
    param([string]$Category, [string]$Check, [string]$Status, [string]$Detail='')
    $results.Add([PSCustomObject]@{
        Category = $Category
        Check    = $Check
        Status   = $Status
        Detail   = $Detail
    })
    if (-not $Json) {
        $color = switch ($Status) {
            'PASS' { 'Green'  }
            'WARN' { 'Yellow' }
            'FAIL' { 'Red'    }
            default { 'Gray'  }
        }
        $line = "  [$Status] $Category / $Check"
        if ($Detail) { $line += " : $Detail" }
        Write-Host $line -ForegroundColor $color
    }
}

function Test-WS([string]$rel) { Test-Path (Join-Path $WorkspaceRoot $rel) }
function Test-Cmd([string]$cmd) { $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue) }

if (-not $Json) {
    Write-Host ''
    Write-Host 'ai-workspace - Doctor' -ForegroundColor Cyan
    Write-Host ('-' * 54) -ForegroundColor Cyan
    Write-Host "  Workspace: $WorkspaceRoot" -ForegroundColor Yellow
    Write-Host ''
    Write-Host '-- Workspace Health ----------------------------------' -ForegroundColor Cyan
}

# --- scripts ------------------------------------------------------------------
$coreScripts = @(
    'scripts\detect-project.ps1',
    'scripts\generate-project-map.ps1',
    'scripts\generate-ci.ps1',
    'scripts\apply-ai-workspace.ps1',
    'scripts\doctor.ps1',
    'scripts\rollback-ai-workspace.ps1',
    'scripts\new-project.ps1',
    'scripts\validate-workspace.ps1',
    'scripts\stop-heavy-tools.ps1'
)
foreach ($s in $coreScripts) {
    $ok = Test-WS $s
    $status = if ($ok) { 'PASS' } else { 'FAIL' }
    $detail = if (-not $ok) { 'Missing' } else { '' }
    Add-Check 'Scripts' $s $status $detail
}

# --- docs ---------------------------------------------------------------------
$coreDocs = @(
    'README.md',
    'AI_WORKFLOW_CONTEXT.md',
    'docs\ONE_COMMAND_WORKFLOW.md',
    'docs\AI_ENGINEERING_OS_VISION.md',
    'docs\SUPPORTED_PROJECT_TYPES.md',
    'docs\SECURITY_MODEL.md',
    'docs\MCP_AND_AGENT_SETUP.md',
    'docs\SHIPD_CHALLENGE_WORKFLOW.md'
)
foreach ($d in $coreDocs) {
    $ok = Test-WS $d
    $status = if ($ok) { 'PASS' } else { 'WARN' }
    $detail = if (-not $ok) { 'Missing - consider creating' } else { '' }
    Add-Check 'Docs' $d $status $detail
}

# --- templates ----------------------------------------------------------------
$coreTemplates = @(
    'templates\project-docs\PRD.md',
    'templates\project-docs\ROADMAP.md',
    'templates\agent-rules\AGENTS.md',
    'templates\agent-rules\AI_AGENT_RULES.md',
    'templates\github\PULL_REQUEST_TEMPLATE.md',
    'templates\github\ISSUE_TEMPLATE\bug_report.md',
    'templates\adr\0001-project-direction.md',
    'templates\github-actions\security\secret-scan.yml',
    'templates\prompts\repo-audit.md',
    'templates\prompts\security-audit.md'
)
foreach ($t in $coreTemplates) {
    $ok = Test-WS $t
    $status = if ($ok) { 'PASS' } else { 'WARN' }
    $detail = if (-not $ok) { 'Missing' } else { '' }
    Add-Check 'Templates' $t $status $detail
}

# --- environment --------------------------------------------------------------
$psVer = $PSVersionTable.PSVersion.Major
$psStatus = if ($psVer -ge 5) { 'PASS' } else { 'WARN' }
Add-Check 'Environment' 'PowerShell version' $psStatus "v$psVer (5+ recommended)"

$gitOk = Test-Cmd 'git'
Add-Check 'Environment' 'git'    $(if ($gitOk)    { 'PASS' } else { 'WARN' }) $(if (-not $gitOk)    { 'Not found - install from git-scm.com' } else { '' })
$pyOk = Test-Cmd 'python'
Add-Check 'Environment' 'python' $(if ($pyOk)     { 'PASS' } else { 'WARN' }) $(if (-not $pyOk)     { 'Not found - optional but recommended'  } else { '' })
$nodeOk = Test-Cmd 'node'
Add-Check 'Environment' 'node'   $(if ($nodeOk)   { 'PASS' } else { 'WARN' }) $(if (-not $nodeOk)   { 'Not found - optional'                  } else { '' })
$npmOk = Test-Cmd 'npm'
Add-Check 'Environment' 'npm'    $(if ($npmOk)    { 'PASS' } else { 'WARN' }) $(if (-not $npmOk)    { 'Not found - optional'                  } else { '' })

# --- target project audit -----------------------------------------------------
if ($ProjectPath) {
    if (-not (Test-Path $ProjectPath)) {
        if (-not $Json) { Write-Host "  ERROR: ProjectPath does not exist: $ProjectPath" -ForegroundColor Red }
    } else {
        $ProjectPath = (Resolve-Path $ProjectPath).Path
        if (-not $Json) {
            Write-Host ''
            Write-Host "--- Target Project: $ProjectPath ---" -ForegroundColor Cyan
        }

        # git repo
        $isGit = Test-Path (Join-Path $ProjectPath '.git')
        $gitS = if ($isGit) { 'PASS' } else { 'WARN' }
        $gitD = if (-not $isGit) { 'Not a git repo - run: git init' } else { '' }
        Add-Check 'Project' 'Git repository' $gitS $gitD

        # .env tracked
        $envTracked = $false
        try {
            if ($isGit) {
                $null = & git -C $ProjectPath ls-files --error-unmatch .env 2>&1
                if ($LASTEXITCODE -eq 0) { $envTracked = $true }
            }
        } catch { }
        $envS = if (-not $envTracked) { 'PASS' } else { 'FAIL' }
        $envD = if ($envTracked) { 'CRITICAL: git rm --cached .env && echo .env >> .gitignore' } else { '' }
        Add-Check 'Project' '.env NOT tracked' $envS $envD

        # .gitignore
        $hasGI = Test-Path (Join-Path $ProjectPath '.gitignore')
        Add-Check 'Project' '.gitignore exists' $(if ($hasGI) { 'PASS' } else { 'WARN' }) $(if (-not $hasGI) { 'Missing - copy from templates/gitignore/' } else { '' })

        # PROJECT_MAP
        $hasMap = Test-Path (Join-Path $ProjectPath 'PROJECT_MAP.md')
        Add-Check 'Project' 'PROJECT_MAP.md' $(if ($hasMap) { 'PASS' } else { 'WARN' }) $(if (-not $hasMap) { 'Run: generate-project-map.ps1' } else { '' })

        # workflows
        $hasWF = Test-Path (Join-Path $ProjectPath '.github\workflows')
        Add-Check 'Project' 'GitHub workflows' $(if ($hasWF) { 'PASS' } else { 'WARN' }) $(if (-not $hasWF) { 'Run: generate-ci.ps1' } else { '' })

        # dep files
        $hasDepFile = (Test-Path (Join-Path $ProjectPath 'requirements.txt')) -or
                      (Test-Path (Join-Path $ProjectPath 'pyproject.toml'))   -or
                      (Test-Path (Join-Path $ProjectPath 'package.json'))     -or
                      (Test-Path (Join-Path $ProjectPath 'backend\requirements.txt'))
        Add-Check 'Project' 'Dependency file' $(if ($hasDepFile) { 'PASS' } else { 'WARN' }) $(if (-not $hasDepFile) { 'No requirements.txt / package.json found' } else { '' })

        # tests
        $hasTests = (Test-Path (Join-Path $ProjectPath 'tests')) -or
                    (Test-Path (Join-Path $ProjectPath 'test'))  -or
                    (Test-Path (Join-Path $ProjectPath '__tests__'))
        Add-Check 'Project' 'Tests directory' $(if ($hasTests) { 'PASS' } else { 'WARN' }) $(if (-not $hasTests) { 'No tests/ found - add tests' } else { '' })

        # risky tracked folders
        $riskyFolders = @('node_modules','venv','.venv','__pycache__','.next','uploads')
        foreach ($rf in $riskyFolders) {
            $tracked = $false
            try {
                if ($isGit) {
                    $out = & git -C $ProjectPath ls-files $rf 2>&1
                    if ($LASTEXITCODE -eq 0 -and $out) { $tracked = $true }
                }
            } catch { }
            if ($tracked) {
                Add-Check 'Project' "$rf NOT tracked" 'FAIL' "Add $rf to .gitignore and remove from git tracking"
            }
        }
    }
}

# --- summary ------------------------------------------------------------------
$passes = ($results | Where-Object { $_.Status -eq 'PASS' }).Count
$warns  = ($results | Where-Object { $_.Status -eq 'WARN' }).Count
$fails  = ($results | Where-Object { $_.Status -eq 'FAIL' }).Count

if ($Json) {
    [PSCustomObject]@{
        WorkspaceRoot = $WorkspaceRoot
        Results       = $results
        Summary       = [PSCustomObject]@{ Passes=$passes; Warnings=$warns; Failures=$fails }
    } | ConvertTo-Json -Depth 5
} else {
    Write-Host ''
    Write-Host '--- Summary -------------------------------------------' -ForegroundColor Cyan
    Write-Host "  PASS : $passes" -ForegroundColor Green
    Write-Host "  WARN : $warns"  -ForegroundColor Yellow
    Write-Host "  FAIL : $fails"  -ForegroundColor Red
    Write-Host ''
    if ($fails -gt 0) {
        Write-Host '  Action required: fix FAIL items before proceeding.' -ForegroundColor Red
        Write-Host ''
        Write-Host '  Quick fix command:' -ForegroundColor Cyan
        Write-Host '    powershell -ExecutionPolicy Bypass -File scripts\apply-ai-workspace.ps1 -ProjectPath <path> -Preset auto -IncludeCI -IncludeSecretScan -GenerateProjectMap -Backup'
    } elseif ($warns -gt 0) {
        Write-Host '  Workspace functional with warnings. Review WARN items.' -ForegroundColor Yellow
    } else {
        Write-Host '  All checks passed. Workspace is healthy.' -ForegroundColor Green
    }
    Write-Host ''
}