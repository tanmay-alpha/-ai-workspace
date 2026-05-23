<#
.SYNOPSIS
    Scaffolds a new project directory with professional structure.
.DESCRIPTION
    Creates a minimal, production-oriented project layout and applies
    ai-workspace context files, CI, docs, and agent rules templates.
.PARAMETER ProjectPath
    Where to create the new project. Defaults to current directory.
.PARAMETER ProjectName
    Display name for the project (used in README and docs).
.PARAMETER Preset
    Project type preset.
.PARAMETER DryRun
    Preview actions without creating files.
.PARAMETER Force
    Overwrite existing files.
.EXAMPLE
    .\new-project.ps1 -ProjectPath C:\Projects\my-api -ProjectName "My API" -Preset python-backend
    .\new-project.ps1 -ProjectPath C:\Projects\my-app -ProjectName "My App" -Preset fullstack -DryRun
#>
param (
    [Parameter(Mandatory=$false)]
    [string]$ProjectPath = '.',

    [string]$ProjectName = '',

    [ValidateSet('python-backend','node-frontend','fullstack','static-website',
                 'ml-project','agentic-ai','trading-system')]
    [string]$Preset = 'python-backend',

    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$WorkspaceRoot = Split-Path -Parent $PSScriptRoot

if (-not $ProjectName) { $ProjectName = Split-Path $ProjectPath -Leaf }

Write-Host ''
Write-Host 'ai-workspace - New Project Scaffolder' -ForegroundColor Cyan
Write-Host ('-' * 54) -ForegroundColor Cyan
Write-Host "  Project Name : $ProjectName"
Write-Host "  Project Path : $ProjectPath"
Write-Host "  Preset       : $Preset"
if ($DryRun) { Write-Host '  *** DRY RUN - no files will be created ***' -ForegroundColor Magenta }
Write-Host ''

# --- helpers ------------------------------------------------------------------
function New-Dir([string]$path) {
    if ($DryRun) { Write-Host "  [DRY RUN] Would create dir: $path" -ForegroundColor Yellow; return }
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Write-Host "  Created dir : $path" -ForegroundColor Green
    }
}

function New-FileContent([string]$filePath, [string]$content) {
    if ($DryRun) { Write-Host "  [DRY RUN] Would create: $filePath" -ForegroundColor Yellow; return }
    if ((Test-Path $filePath) -and -not $Force) {
        Write-Host "  Skipped (exists): $filePath" -ForegroundColor Yellow
        return
    }
    $parent = Split-Path $filePath -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $content | Out-File -FilePath $filePath -Encoding utf8
    Write-Host "  Created: $(Split-Path $filePath -Leaf)" -ForegroundColor Green
}

# --- common structure ---------------------------------------------------------
New-Dir $ProjectPath
New-Dir (Join-Path $ProjectPath 'docs')
New-Dir (Join-Path $ProjectPath '.github\workflows')

# --- preset-specific structure ------------------------------------------------
switch ($Preset) {
    { $_ -in @('python-backend','ml-project','agentic-ai','trading-system') } {
        New-Dir  (Join-Path $ProjectPath 'src')
        New-Dir  (Join-Path $ProjectPath 'tests')
        New-FileContent (Join-Path $ProjectPath 'requirements.txt')       "# Add Python dependencies here`n"
        New-FileContent (Join-Path $ProjectPath 'src\__init__.py')        "# $ProjectName`n"
        New-FileContent (Join-Path $ProjectPath 'tests\__init__.py')      ''
        New-FileContent (Join-Path $ProjectPath 'tests\test_placeholder.py') @"
def test_placeholder():
    '''Placeholder test - replace with real tests.'''
    assert True
"@
        New-FileContent (Join-Path $ProjectPath '.python-version') '3.11'
    }
    'node-frontend' {
        New-Dir (Join-Path $ProjectPath 'src')
        New-Dir (Join-Path $ProjectPath 'public')
        $pkgName = ($ProjectName -replace '[^a-zA-Z0-9-]', '-').ToLower()
        New-FileContent (Join-Path $ProjectPath 'package.json') @"
{
  "name": "$pkgName",
  "version": "0.1.0",
  "description": "$ProjectName",
  "private": true,
  "scripts": {
    "dev": "echo 'Replace with your dev server command'",
    "build": "echo 'Replace with your build command'",
    "test": "echo 'Replace with your test command'"
  }
}
"@
    }
    'fullstack' {
        New-Dir (Join-Path $ProjectPath 'backend\src')
        New-Dir (Join-Path $ProjectPath 'backend\tests')
        New-Dir (Join-Path $ProjectPath 'frontend\src')
        New-Dir (Join-Path $ProjectPath 'frontend\public')
        New-FileContent (Join-Path $ProjectPath 'backend\requirements.txt') "# Backend Python dependencies`n"
        New-FileContent (Join-Path $ProjectPath 'backend\tests\__init__.py') ''
        $pkgName = ($ProjectName -replace '[^a-zA-Z0-9-]', '-').ToLower()
        New-FileContent (Join-Path $ProjectPath 'frontend\package.json') @"
{
  "name": "$pkgName-frontend",
  "version": "0.1.0",
  "description": "$ProjectName frontend",
  "private": true,
  "scripts": {
    "dev": "echo 'Replace with your dev command'",
    "build": "echo 'Replace with your build command'",
    "test": "echo 'Replace with your test command'"
  }
}
"@
    }
    'static-website' {
        New-Dir (Join-Path $ProjectPath 'assets\css')
        New-Dir (Join-Path $ProjectPath 'assets\js')
        New-FileContent (Join-Path $ProjectPath 'index.html') @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$ProjectName</title>
</head>
<body>
  <h1>$ProjectName</h1>
  <p>Replace this with your content.</p>
</body>
</html>
"@
    }
}

# --- README -------------------------------------------------------------------
New-FileContent (Join-Path $ProjectPath 'README.md') @"
# $ProjectName

A $Preset project.

## Getting Started

TODO: Add setup instructions here.

## Project Structure

See [PROJECT_MAP.md](PROJECT_MAP.md) for a full auto-generated project map.

## Development

TODO: Add development workflow here.

## Testing

TODO: Add test instructions here.

## Security

- Never commit `.env` files.
- Run a secret scan before pushing to remote.
- See [docs/SECURITY_CHECKLIST.md](docs/SECURITY_CHECKLIST.md).
"@

# --- .env.example -------------------------------------------------------------
New-FileContent (Join-Path $ProjectPath '.env.example') @"
# Copy this file to .env and fill in real values.
# NEVER commit .env to git.

# Example environment variables:
# DATABASE_URL=postgresql://user:password@localhost:5432/mydb
# API_KEY=your-api-key-here
# APP_ENV=development
# SECRET_KEY=your-secret-key-here
"@

# --- .gitignore ---------------------------------------------------------------
$gitignoreMap = @{
    'python-backend' = 'templates\gitignore\python.gitignore'
    'ml-project'     = 'templates\gitignore\python.gitignore'
    'agentic-ai'     = 'templates\gitignore\python.gitignore'
    'trading-system' = 'templates\gitignore\python.gitignore'
    'node-frontend'  = 'templates\gitignore\node.gitignore'
    'fullstack'      = 'templates\gitignore\fullstack.gitignore'
    'static-website' = 'templates\gitignore\static-website.gitignore'
}
if ($gitignoreMap.ContainsKey($Preset)) {
    $giSrc  = Join-Path $WorkspaceRoot $gitignoreMap[$Preset]
    $giDest = Join-Path $ProjectPath '.gitignore'
    if (Test-Path $giSrc) {
        if (-not $DryRun) {
            if (-not (Test-Path $giDest) -or $Force) {
                Copy-Item $giSrc $giDest -Force
                Write-Host '  Created: .gitignore' -ForegroundColor Green
            } else {
                Write-Host '  Skipped (exists): .gitignore' -ForegroundColor Yellow
            }
        } else {
            Write-Host '  [DRY RUN] Would create: .gitignore' -ForegroundColor Yellow
        }
    }
}

# --- apply ai-workspace files -------------------------------------------------
Write-Host ''
Write-Host '  Applying ai-workspace context files...' -ForegroundColor Cyan
$ApplyScript = Join-Path $WorkspaceRoot 'scripts\apply-ai-workspace.ps1'
if (Test-Path $ApplyScript) {
    $applyArgs = @(
        '-ProjectPath', $ProjectPath,
        '-Preset', $Preset,
        '-IncludeCI',
        '-IncludeSecretScan',
        '-IncludePrompts',
        '-IncludeDocs',
        '-GenerateProjectMap',
        '-IncludeADR',
        '-IncludeAgentRules',
        '-IncludeGitHubTemplates'
    )
    if ($DryRun) { $applyArgs += '-DryRun' }
    if ($Force)  { $applyArgs += '-Force' }
    & $ApplyScript @applyArgs
} else {
    Write-Host '  apply-ai-workspace.ps1 not found - skipping context files.' -ForegroundColor Yellow
}

Write-Host ''
Write-Host '  New project scaffolded!' -ForegroundColor Green
Write-Host ''
Write-Host '  Suggested next steps:' -ForegroundColor Cyan
Write-Host "    cd `"$ProjectPath`""
Write-Host '    git init'
Write-Host '    git add .'
Write-Host '    git commit -m "Initial scaffold from ai-workspace"'
Write-Host ''