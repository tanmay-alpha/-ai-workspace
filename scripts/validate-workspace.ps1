# Workspace Validation Script
# This script checks the repository for required folders, files, and templates.
# It also validates file content for public-readiness and security.
# Also runs a sanity check of detect-project.ps1 on the workspace root.

$ErrorActionPreference = 'Stop'

$WorkspaceRoot = Split-Path -Parent $PSScriptRoot

$failures = 0
$warnings = 0
$passes   = 0

# Grouped warnings lists
$secretWarnings       = [System.Collections.Generic.List[string]]::new()
$publicSafetyWarnings = [System.Collections.Generic.List[string]]::new()
$optionalFileWarnings = [System.Collections.Generic.List[string]]::new()
$encodingWarnings     = [System.Collections.Generic.List[string]]::new()

function Write-Result {
    param([bool]$success, [string]$message)
    if ($success) {
        Write-Host "[PASS] $message" -ForegroundColor Green
        $script:passes++
    } else {
        Write-Host "[FAIL] $message" -ForegroundColor Red
        $script:failures++
    }
}

function Add-Warning {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Secret', 'PublicSafety', 'Optional', 'Encoding')]
        [string]$Category,
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    switch ($Category) {
        'Secret'       { $script:secretWarnings.Add($Message) }
        'PublicSafety' { $script:publicSafetyWarnings.Add($Message) }
        'Optional'     { $script:optionalFileWarnings.Add($Message) }
        'Encoding'     { $script:encodingWarnings.Add($Message) }
    }
    Write-Host "[WARN] ($Category) $Message" -ForegroundColor Yellow
    $script:warnings++
}

function Test-WS([string]$rel) {
    return Test-Path (Join-Path $WorkspaceRoot $rel)
}

Write-Host ''
Write-Host 'ai-workspace - Workspace Validation' -ForegroundColor Cyan
Write-Host ('-' * 54) -ForegroundColor Cyan
Write-Host ''

# --- required folders ---------------------------------------------------------
Write-Host '-- Folder Structure --' -ForegroundColor Cyan
$requiredFolders = @(
    'docs',
    'scripts',
    'templates',
    'templates\github-actions',
    'templates\gitignore',
    'templates\mcp-profiles',
    'templates\prompts',
    'templates\challenge-authoring',
    'templates\project-docs',
    'templates\agent-rules',
    'templates\github',
    'templates\github\ISSUE_TEMPLATE',
    'templates\adr',
    'tests\fixtures'
)
foreach ($folder in $requiredFolders) {
    Write-Result (Test-WS $folder) "Folder: $folder"
}

# --- required files -----------------------------------------------------------
Write-Host ''
Write-Host '-- Core Files --' -ForegroundColor Cyan
$requiredFiles = @(
    'README.md',
    'AI_WORKFLOW_CONTEXT.md',
    'docs\ONE_COMMAND_WORKFLOW.md',
    'docs\AI_ENGINEERING_OS_VISION.md',
    'docs\SUPPORTED_PROJECT_TYPES.md',
    'docs\SECURITY_MODEL.md',
    'docs\MCP_AND_AGENT_SETUP.md',
    'docs\SHIPD_CHALLENGE_WORKFLOW.md',
    'docs\DAILY_WORKFLOW.md',
    'docs\RAM_SAFETY.md',
    'docs\VALIDATION.md',
    'scripts\detect-project.ps1',
    'scripts\generate-project-map.ps1',
    'scripts\generate-ci.ps1',
    'scripts\apply-ai-workspace.ps1',
    'scripts\doctor.ps1',
    'scripts\rollback-ai-workspace.ps1',
    'scripts\new-project.ps1',
    'scripts\validate-workspace.ps1',
    'scripts\stop-heavy-tools.ps1',
    'scripts\presets.json',
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

foreach ($file in $requiredFiles) {
    $exists = Test-WS $file
    Write-Result $exists "File: $file"
    
    if ($exists) {
        $fullPath = Join-Path $WorkspaceRoot $file
        $content = Get-Content $fullPath -Raw
        $lines = (Get-Content $fullPath).Count
        
        if ($lines -eq 0) {
            Add-Warning 'Optional' "File is empty: $file"
        } elseif ($lines -eq 1 -and $file.EndsWith('.md')) {
            Add-Warning 'Optional' "File is a suspicious one-line Markdown: $file"
        }
        
        # Check GitHub Actions templates structure
        if ($file.EndsWith('.yml') -and $file.Contains('github-actions')) {
            $hasName = $content -match 'name:'
            $hasOn = $content -match 'on:'
            $hasJobs = $content -match 'jobs:'
            Write-Result ($hasName -and $hasOn -and $hasJobs) "GitHub Action structure valid: $file"
        }
    }
}

# --- recursive codebase scanning for safety & secrets -------------------------
Write-Host ''
Write-Host '-- Codebase Security & Safety Scanning --' -ForegroundColor Cyan

$forbiddenWords = @(
    ("TAN" + "MAY"),
    ("Personal" + "Project" + "X"),
    ("Internal" + "System" + "Y"),
    ("Private" + "Repo" + "Z"),
    ("Challenge" + "Platform" + "A")
)

$filesToScan = Get-ChildItem -Path $WorkspaceRoot -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object {
        $fullName = $_.FullName
        $fullName -notmatch '\\.git|node_modules|venv|\.venv|__pycache__|dist|build|\.next|\.pytest_cache|\.ruff_cache|\.mypy_cache|\.tox|\.ai-workspace-backup' -and
        $_.Name -ne 'validate-workspace.ps1' -and
        $_.Name -ne 'run-validation.ps1'
    }

foreach ($file in $filesToScan) {
    $relPath = $file.FullName.Substring($WorkspaceRoot.Length).TrimStart('\/')
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        # 1. Forbidden words check
        foreach ($word in $forbiddenWords) {
            if ($word -eq ("TAN" + "MAY")) {
                $cleanContent = $content -ireplace ("tanmay" + "-alpha"), ""
                if ($cleanContent -imatch $word) {
                    Write-Result $false "Forbidden word '$word' found in: $relPath"
                }
            } else {
                if ($content -match $word) {
                    Write-Result $false "Forbidden word '$word' found in: $relPath"
                }
            }
        }

        # 2. Hardcoded private/local paths check
        if ($content -match '(?i)(?:[c-z]:\\Users\\[a-z0-9_\-]+|/Users/[a-z0-9_\-]+|/home/[a-z0-9_\-]+)') {
            Write-Result $false "Hardcoded private/local path found in: $relPath"
        }

        # 3. Real-looking secrets check
        $foundRealSecret = $false
        $matchedSecret = ''
        if ($content -match 'AKIA[0-9A-Z]{16}') {
            $foundRealSecret = $true
            $matchedSecret = $Matches[0]
        } elseif ($content -match 'sk-(?:proj-)?[a-zA-Z0-9_\-]{30,}') {
            $match = $Matches[0]
            if ($match -notmatch '(?i)placeholder|example|your|test') {
                $foundRealSecret = $true
                $matchedSecret = $match
            }
        } elseif ($content -match 'gh[pso]_[a-zA-Z0-9]{36}') {
            $match = $Matches[0]
            if ($match -notmatch '(?i)placeholder|example|your|test') {
                $foundRealSecret = $true
                $matchedSecret = $match
            }
        } elseif ($content -match 'xox[baprs]-[a-zA-Z0-9\-]{10,}') {
            $match = $Matches[0]
            if ($match -notmatch '(?i)placeholder|example|your|test') {
                $foundRealSecret = $true
                $matchedSecret = $match
            }
        }
        if ($foundRealSecret) {
            Write-Result $false "Real-looking secret '$matchedSecret' found in: $relPath"
        }

        # 4. Secret-like value assignments check (WARN only)
        $assignRegex = [regex]'(?i)(?:api_key|secret_key|password|token|credential|secret)\s*[:=]\s*["'']?([a-zA-Z0-9_\-\.~]{8,})["'']?'
        $matchObj = $assignRegex.Match($content)
        while ($matchObj.Success) {
            $val = $matchObj.Groups[1].Value
            $isPlaceholder = $val -match '(?i)your|example|placeholder|changeme|value|key|token|password|secret|my-secret|test|dummy|<|>|\$'
            if (-not $isPlaceholder) {
                Add-Warning 'Secret' "Secret-like value assignment found in $($relPath): $($matchObj.Value)"
            }
            $matchObj = $matchObj.NextMatch()
        }

        # 5. Encoding/Non-ASCII checks for scripts
        if ($file.Extension -eq '.ps1' -and $content -match '[^\x00-\x7F]') {
            Add-Warning 'Encoding' "Script contains non-ASCII characters: $relPath"
        }
    }
}

# --- environment checks -------------------------------------------------------
Write-Host ''
Write-Host '-- Environment & Optional Tools --' -ForegroundColor Cyan

function Test-Cmd([string]$cmd) {
    return $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue)
}

$tools = @('git', 'python', 'node', 'npm')
foreach ($t in $tools) {
    $hasTool = Test-Cmd $t
    if ($hasTool) {
        Write-Result $true "Tool available: $t"
    } else {
        Add-Warning 'Optional' "Optional tool not found on PATH: $t"
    }
}

# --- local .env check ---------------------------------------------------------
Write-Host ''
Write-Host '-- Local .env checks --' -ForegroundColor Cyan

if (Test-Path (Join-Path $WorkspaceRoot '.env')) {
    Add-Warning 'PublicSafety' "Local .env file exists. Ensure it is never committed."
}

# Git tracking of .env check
if (Test-Path (Join-Path $WorkspaceRoot '.git')) {
    $envTracked = $false
    try {
        $null = & git -C $WorkspaceRoot ls-files --error-unmatch .env 2>&1
        if ($LASTEXITCODE -eq 0) { $envTracked = $true }
    } catch { $envTracked = $false }

    if ($envTracked) {
        Write-Result $false "CRITICAL: .env file is tracked by Git!"
    } else {
        Write-Result $true ".env file is not tracked by Git"
    }
}

# --- dry-run sanity check of detect-project -----------------------------------
Write-Host ''
Write-Host '-- Project Detection Sanity Check --' -ForegroundColor Cyan
$DetectScript = Join-Path $WorkspaceRoot 'scripts\detect-project.ps1'
if (Test-Path $DetectScript) {
    try {
        $json = & $DetectScript -ProjectPath $WorkspaceRoot -Json
        if ($json) {
            $result = $json | ConvertFrom-Json
            if ($result.ProjectType) {
                Write-Result $true "detect-project.ps1 returned project type: $($result.ProjectType)"
            } else {
                Write-Result $false "detect-project.ps1 output does not contain ProjectType"
            }
        } else {
            Write-Result $false "detect-project.ps1 returned empty output"
        }
    } catch {
        Write-Result $false "detect-project.ps1 failed to execute: $($_.Exception.Message)"
    }
} else {
    Write-Result $false "detect-project.ps1 not found"
}

# --- print grouped warnings ---------------------------------------------------
if ($warnings -gt 0) {
    Write-Host ''
    Write-Host '==================================================' -ForegroundColor Yellow
    Write-Host 'GROUPED WARNINGS SUMMARY' -ForegroundColor Yellow
    Write-Host '==================================================' -ForegroundColor Yellow

    if ($secretWarnings.Count -gt 0) {
        Write-Host '  Secret-like value warnings:' -ForegroundColor Yellow
        foreach ($w in $secretWarnings) { Write-Host "    - $w" -ForegroundColor Yellow }
    }
    if ($publicSafetyWarnings.Count -gt 0) {
        Write-Host '  Public-safety warnings:' -ForegroundColor Yellow
        foreach ($w in $publicSafetyWarnings) { Write-Host "    - $w" -ForegroundColor Yellow }
    }
    if ($optionalFileWarnings.Count -gt 0) {
        Write-Host '  Optional file/tool warnings:' -ForegroundColor Yellow
        foreach ($w in $optionalFileWarnings) { Write-Host "    - $w" -ForegroundColor Yellow }
    }
    if ($encodingWarnings.Count -gt 0) {
        Write-Host '  Line-ending/encoding warnings:' -ForegroundColor Yellow
        foreach ($w in $encodingWarnings) { Write-Host "    - $w" -ForegroundColor Yellow }
    }
    Write-Host ''
}

# --- summary ------------------------------------------------------------------
Write-Host ''
Write-Host 'Validation Summary:' -ForegroundColor Cyan
Write-Host "  PASS : $passes" -ForegroundColor Green
Write-Host "  WARN : $warnings" -ForegroundColor Yellow
Write-Host "  FAIL : $failures" -ForegroundColor Red
Write-Host ''

if ($failures -gt 0) {
    Write-Host 'Workspace validation failed!' -ForegroundColor Red
    exit 1
} else {
    Write-Host 'Workspace validation passed!' -ForegroundColor Green
    exit 0
}
