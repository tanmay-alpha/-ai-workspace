param (
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,

    [switch]$NoWrite
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ProjectPath)) {
    Write-Error "Project path does not exist: $ProjectPath"
    exit 1
}

Write-Host "Generating project map for: $ProjectPath" -Cyan

$ignorePatterns = @(".git", "node_modules", "venv", ".venv", "dist", "build", "uploads", "__pycache__", ".next", ".nuxt")

# Helper to check if path should be ignored
function Should-Ignore($path) {
    foreach ($pattern in $ignorePatterns) {
        if ($path -like "*\$pattern" -or $path -like "*\$pattern\*") {
            return $true
        }
    }
    return $false
}

# Detect Project Type
$projectType = "Unknown"
if (Test-Path (Join-Path $ProjectPath "package.json")) {
    $projectType = "Node.js / Frontend"
} elseif (Test-Path (Join-Path $ProjectPath "requirements.txt") -or Test-Path (Join-Path $ProjectPath "pyproject.toml")) {
    $projectType = "Python"
} elseif (Test-Path (Join-Path $ProjectPath "index.html") -and -not (Test-Path (Join-Path $ProjectPath "package.json"))) {
    $projectType = "Static Website"
}

# Gather Important Folders
$folders = Get-ChildItem -Path $ProjectPath -Directory -Recurse | Where-Object { -not (Should-Ignore $_.FullName) } | Select-Object -ExpandProperty Name -Unique | Sort-Object

# Gather Important Files
$allFiles = Get-ChildItem -Path $ProjectPath -File -Recurse | Where-Object { -not (Should-Ignore $_.FullName) }

$entryPoints = $allFiles | Where-Object { $_.Name -match "^(index|main|app|server|start)\.(js|ts|py|html)$" }
$configs = $allFiles | Where-Object { $_.Name -match "\.(json|yml|yaml|toml|conf|config|js)$" -and $_.Name -notmatch "package-lock|yarn\.lock" }
$tests = $allFiles | Where-Object { $_.FullName -match "test" -or $_.Name -match "spec" }
$workflows = Get-ChildItem -Path (Join-Path $ProjectPath ".github/workflows") -File -ErrorAction SilentlyContinue

# Build Markdown
$md = @"
# Project Map: $(Split-Path $ProjectPath -Leaf)

## Overview
- **Path:** $ProjectPath
- **Detected Type:** $projectType

## Important Folders
$(if ($folders) { $folders | ForEach-Object { "- $_" } | Out-String } else { "None detected" })

## Entry Points
$(if ($entryPoints) { $entryPoints | ForEach-Object { "- $($_.FullName.Replace($ProjectPath, '').TrimStart('\'))" } | Out-String } else { "None detected" })

## Configuration Files
$(if ($configs) { $configs | ForEach-Object { "- $($_.FullName.Replace($ProjectPath, '').TrimStart('\'))" } | Out-String } else { "None detected" })

## Tests
$(if ($tests) { $tests | ForEach-Object { "- $($_.FullName.Replace($ProjectPath, '').TrimStart('\'))" } | Out-String } else { "None detected" })

## GitHub Workflows
$(if ($workflows) { $workflows | ForEach-Object { "- $($_.Name)" } | Out-String } else { "None detected" })

"@

if ($NoWrite) {
    Write-Host "`n--- PROJECT_MAP.md ---" -Cyan
    Write-Host $md
} else {
    $outputPath = Join-Path $ProjectPath "PROJECT_MAP.md"
    $md | Out-File -FilePath $outputPath -Encoding utf8
    Write-Host "Project map written to: $outputPath" -ForegroundColor Green
}
