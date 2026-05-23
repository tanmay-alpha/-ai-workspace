# Workspace Validation Script
# This script checks the repository for required folders, files, and templates.
# It also validates file content for public-readiness and security.

$ErrorActionPreference = "Stop"

$requiredFolders = @(
    "docs",
    "scripts",
    "templates",
    "templates/github-actions",
    "templates/gitignore",
    "templates/mcp-profiles",
    "templates/prompts",
    "templates/challenge-authoring"
)

$requiredFiles = @(
    "README.md",
    "AI_WORKFLOW_CONTEXT.md",
    "docs/DAILY_WORKFLOW.md",
    "docs/RAM_SAFETY.md",
    "docs/VALIDATION.md",
    "scripts/stop-heavy-tools.ps1",
    "scripts/validate-workspace.ps1",
    "scripts/bootstrap-project.ps1",
    "scripts/generate-project-map.ps1",
    "templates/github-actions/python-backend/ci.yml",
    "templates/github-actions/node-frontend/ci.yml",
    "templates/github-actions/fullstack/ci.yml",
    "templates/github-actions/static-website/ci.yml",
    "templates/github-actions/security/secret-scan.yml",
    "templates/mcp-profiles/README.md",
    "templates/challenge-authoring/README.md",
    "templates/challenge-authoring/repository-selection-checklist.md",
    "templates/challenge-authoring/problem-description-template.md",
    "templates/challenge-authoring/test-design-template.md",
    "templates/challenge-authoring/dockerfile-template.md",
    "templates/challenge-authoring/test-sh-template.md",
    "templates/challenge-authoring/solution-patch-checklist.md",
    "templates/challenge-authoring/submission-checklist.md",
    "templates/challenge-authoring/spec-planning-prompt.md"
)

# Forbidden wording check (generic examples)
$forbiddenWords = @(
    "TANMAY",
    "PersonalProjectX",
    "InternalSystemY",
    "PrivateRepoZ",
    "ChallengePlatformA"
)

# Secret patterns (basic)
$secretPatterns = @(
    "AKIA[0-9A-Z]{16}", # AWS Access Key ID
    "(?i)secret_key",
    "(?i)api_key",
    "(?i)password",
    "(?i)token"
)

$failures = 0
$warnings = 0

function Write-Result($success, $message, $isWarning = $false) {
    if ($success) {
        Write-Host "[PASS] $message" -ForegroundColor Green
    } else {
        if ($isWarning) {
            Write-Host "[WARN] $message" -ForegroundColor Yellow
            $script:warnings++
        } else {
            Write-Host "[FAIL] $message" -ForegroundColor Red
            $script:failures++
        }
    }
}

Write-Host "Starting Workspace Validation..." -Cyan

# Check Folders
foreach ($folder in $requiredFolders) {
    Write-Result (Test-Path $folder) "Folder exists: $folder"
}

# Check Files
foreach ($file in $requiredFiles) {
    $exists = Test-Path $file
    Write-Result $exists "File exists: $file"
    
    if ($exists) {
        $content = Get-Content $file -Raw
        $lines = (Get-Content $file).Count
        
        # Check if empty or suspicious one-line
        if ($lines -eq 0) {
            Write-Result $false "File is empty: $file"
        } elseif ($lines -eq 1 -and $file.EndsWith(".md")) {
            Write-Result $false "File is a suspicious one-line Markdown: $file" $true
        }
        
        # Check GitHub Actions templates
        if ($file.EndsWith(".yml") -and $file.Contains("github-actions")) {
            $hasName = $content -match "name:"
            $hasOn = $content -match "on:"
            $hasJobs = $content -match "jobs:"
            Write-Result ($hasName -and $hasOn -and $hasJobs) "GitHub Action structure valid: $file"
        }
        
        # Check Forbidden Words
        # Skip this script itself for the forbidden word check to avoid self-failure
        if ($file -ne "scripts/validate-workspace.ps1") {
            foreach ($word in $forbiddenWords) {
                if ($content -match $word) {
                    Write-Result $false "Forbidden word '$word' found in: $file"
                }
            }
        }
        
        # Check Secret Patterns
        foreach ($pattern in $secretPatterns) {
            # Exclude matches in scripts/validate-workspace.ps1 itself or .env.example
            if ($file -ne "scripts/validate-workspace.ps1" -and $file -ne "templates/.env.example") {
                if ($content -match $pattern) {
                    # Filter out some common false positives like "GitHub Token" usage in workflows
                    if (-not ($file.EndsWith(".yml") -and $content -match "secrets\.GITHUB_TOKEN")) {
                         Write-Result $false "Potential secret pattern '$pattern' found in: $file" $true
                    }
                }
            }
        }
    }
}

Write-Host "`nValidation Summary:" -Cyan
Write-Host "Passes: " -NoNewline; Write-Host ($requiredFolders.Count + $requiredFiles.Count - $failures - $warnings) -ForegroundColor Green
Write-Host "Warnings: " -NoNewline; Write-Host $warnings -ForegroundColor Yellow
Write-Host "Failures: " -NoNewline; Write-Host $failures -ForegroundColor Red

if ($failures -gt 0) {
    Write-Host "`nWorkspace validation failed!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nWorkspace validation passed!" -ForegroundColor Green
    exit 0
}
