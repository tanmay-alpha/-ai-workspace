<#
.SYNOPSIS
    Generates a smart GitHub Actions CI workflow for any project.
.DESCRIPTION
    Uses detect-project.ps1 to analyze the project, then generates a
    tailored .github/workflows/ci.yml. Supports DryRun, Backup, and Force.
.PARAMETER ProjectPath
    Path to the project root. Defaults to current directory.
.PARAMETER OutputPath
    Override output path for ci.yml.
.PARAMETER Preset
    Force a preset (default: auto-detect).
.PARAMETER Force
    Overwrite existing ci.yml.
.PARAMETER DryRun
    Print what would be written without writing.
.PARAMETER Backup
    Back up existing ci.yml before overwriting.
.EXAMPLE
    .\generate-ci.ps1 -ProjectPath C:\MyProject
    .\generate-ci.ps1 -ProjectPath C:\MyProject -DryRun
    .\generate-ci.ps1 -ProjectPath C:\MyProject -Force -Backup
#>
param (
    [Parameter(Mandatory=$false)]
    [string]$ProjectPath = '.',

    [string]$OutputPath = '',

    [ValidateSet('auto','python-backend','node-frontend','fullstack','static-website',
                 'ml-project','agentic-ai','trading-system','data-science')]
    [string]$Preset = 'auto',

    [switch]$Force,
    [switch]$DryRun,
    [switch]$Backup
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $ProjectPath)) {
    Write-Error "ProjectPath does not exist: $ProjectPath"
    exit 1
}

$ProjectPath   = (Resolve-Path $ProjectPath).Path
$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$DetectScript  = Join-Path $WorkspaceRoot 'scripts\detect-project.ps1'

if (-not (Test-Path $DetectScript)) {
    Write-Error "detect-project.ps1 not found at: $DetectScript"
    exit 1
}

if (-not $DryRun) {
    Write-Host ''
    Write-Host 'ai-workspace - CI Generator' -ForegroundColor Cyan
    Write-Host ('-' * 54) -ForegroundColor Cyan
    Write-Host ''
    Write-Host "Detecting project: $ProjectPath" -ForegroundColor Cyan
}

$d = & $DetectScript -ProjectPath $ProjectPath -Json | ConvertFrom-Json

$effectivePreset = if ($Preset -ne 'auto') { $Preset } else { $d.RecommendedPreset }

if (-not $DryRun) {
    Write-Host "Effective preset : $effectivePreset" -ForegroundColor Yellow
    Write-Host ''
}

# --- CI snippet builders ------------------------------------------------------
function Get-PythonJob([string]$jobName='python-backend') {
    $pythonVer  = $d.PythonVersionHint
    $backendDir = $d.BackendPath
    $depFile    = $d.PythonDependencyFile
    $compileDir = if ($backendDir -and $backendDir -ne '.') { $backendDir } else { '.' }

    return @"
  ${jobName}:
    name: Python checks ($jobName)
    runs-on: ubuntu-latest

    env:
      TRADING_MODE: PAPER
      APP_ENV: test
      PYTHONDONTWRITEBYTECODE: '1'

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Python $pythonVer
        uses: actions/setup-python@v5
        with:
          python-version: '$pythonVer'

      - name: Install dependencies
        shell: bash
        run: |
          python -m pip install --upgrade pip
          if [ -f 'requirements.txt' ]; then
            pip install -r requirements.txt
          fi
          if [ -f 'backend/requirements.txt' ]; then
            pip install -r backend/requirements.txt
          fi
          pip install pytest pytest-asyncio || true

      - name: Set PYTHONPATH
        shell: bash
        run: |
          echo "PYTHONPATH=${'$'}{GITHUB_WORKSPACE}/$compileDir" >> "${'$'}GITHUB_ENV"

      - name: Syntax check (compileall)
        shell: bash
        run: python -m compileall $compileDir -q

      - name: Run tests
        shell: bash
        run: |
          if [ -d 'tests' ]; then
            pytest tests -q --tb=short
          elif [ -d 'backend/tests' ]; then
            pytest backend/tests -q --tb=short
          elif [ -d 'test' ]; then
            pytest test -q --tb=short
          else
            echo 'No tests directory found - skipping pytest.'
          fi
"@
}

function Get-NodeJob([string]$jobName='node-frontend') {
    $nodeDir = if ($d.NodePath) { $d.NodePath } else { '.' }
    $pm      = $d.NodePackageManager

    $installCmd = switch ($pm) {
        'pnpm' { "npm install -g pnpm`n          pnpm install" }
        'yarn' { "npm install -g yarn`n          yarn install" }
        default {
            "if [ -f 'package-lock.json' ]; then`n            npm ci`n          else`n            npm install`n          fi"
        }
    }

    $buildCheck = switch ($pm) {
        'pnpm' { "pnpm run build" }
        'yarn' { "yarn build" }
        default { "npm run build" }
    }

    $testCheck = switch ($pm) {
        'pnpm' { "pnpm run test" }
        'yarn' { "yarn test" }
        default { "npm test -- --watchAll=false --passWithNoTests" }
    }

    return @"
  ${jobName}:
    name: Node checks ($jobName)
    runs-on: ubuntu-latest

    defaults:
      run:
        working-directory: $nodeDir

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '22'

      - name: Install dependencies
        shell: bash
        run: |
          $installCmd

      - name: Build (if build script exists)
        shell: bash
        run: |
          if node -e "const p=require('./package.json');process.exit(p.scripts&&p.scripts.build?0:1)" 2>/dev/null; then
            $buildCheck
          else
            echo 'No build script - skipping build.'
          fi

      - name: Test (if meaningful test script exists)
        shell: bash
        run: |
          if node -e "const p=require('./package.json');const s=(p.scripts&&p.scripts.test)||'';process.exit(s&&s!=='echo \"Error: no test specified\"'&&s!=='exit 1'?0:1)" 2>/dev/null; then
            $testCheck
          else
            echo 'No meaningful test script - skipping tests.'
          fi
"@
}

function Get-StaticJob {
    return @"
  static-website:
    name: Static website checks
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Check index.html exists
        shell: bash
        run: |
          test -f index.html || (echo 'ERROR: index.html not found' && exit 1)
          echo 'index.html found.'

      - name: List HTML files
        shell: bash
        run: |
          echo 'HTML files found:'
          find . -maxdepth 3 -name '*.html' | head -20
"@
}

# --- compose jobs -------------------------------------------------------------
$jobs = ''

switch ($effectivePreset) {
    'python-backend' { $jobs = Get-PythonJob 'python-backend' }
    'node-frontend'  { $jobs = Get-NodeJob 'node-frontend' }
    'fullstack' {
        $jobs  = Get-PythonJob 'python-backend'
        $jobs += "`n"
        $jobs += Get-NodeJob 'node-frontend'
    }
    'static-website' { $jobs = Get-StaticJob }
    { $_ -in @('ml-project','data-science') } { $jobs = Get-PythonJob 'ml-checks' }
    'agentic-ai'      { $jobs = Get-PythonJob 'agent-checks' }
    'trading-system'  { $jobs = Get-PythonJob 'trading-checks' }
    default {
        if ($d.HasBackend)  { $jobs += Get-PythonJob 'backend-checks'; $jobs += "`n" }
        if ($d.HasFrontend) { $jobs += Get-NodeJob 'frontend-checks' }
        if (-not $d.HasBackend -and -not $d.HasFrontend) {
            $jobs = Get-PythonJob 'default-checks'
        }
    }
}

$ciYaml = @"
name: Universal CI
# Generated by ai-workspace scripts/generate-ci.ps1
# Preset: $effectivePreset
# This workflow does NOT use live API keys, broker credentials, or external services.
# It is safe to run on every push and pull request.

on:
  push:
    branches: [ main, dev ]
  pull_request:
    branches: [ main, dev ]
  workflow_dispatch:

jobs:
$jobs
"@

# --- write output -------------------------------------------------------------
$destDir  = if ($OutputPath) { Split-Path $OutputPath -Parent }
            else { Join-Path $ProjectPath '.github\workflows' }
$destFile = if ($OutputPath) { $OutputPath }
            else { Join-Path $destDir 'ci.yml' }

if ($DryRun) {
    $ciYaml
    return
}

if ((Test-Path $destFile) -and -not $Force) {
    Write-Warning "ci.yml already exists at $destFile. Use -Force to overwrite or -Backup -Force to backup then overwrite."
    return
}

if ((Test-Path $destFile) -and $Backup) {
    $ts         = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backupPath = "$destFile.backup_$ts"
    Copy-Item $destFile $backupPath -Force
    Write-Host "Backed up existing ci.yml to: $backupPath" -ForegroundColor Yellow
}

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

$ciYaml | Out-File -FilePath $destFile -Encoding utf8
Write-Host "CI workflow written to: $destFile" -ForegroundColor Green
Write-Host "Preset used           : $effectivePreset" -ForegroundColor Yellow