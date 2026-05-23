param (
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,

    [Parameter(Mandatory=$true)]
    [ValidateSet("python-backend", "node-frontend", "fullstack", "static-website", "challenge-authoring")]
    [string]$ProjectType,

    [switch]$IncludeSecretScan,
    [switch]$IncludePrompts,
    [switch]$IncludeProjectDocs,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "Bootstrapping project at: $ProjectPath" -Cyan
Write-Host "Project Type: $ProjectType" -Cyan

if (-not (Test-Path $ProjectPath)) {
    Write-Host "Creating project directory..."
    New-Item -ItemType Directory -Path $ProjectPath | Out-Null
}

$githubActionsPath = Join-Path $ProjectPath ".github/workflows"
if (-not (Test-Path $githubActionsPath)) {
    New-Item -ItemType Directory -Path $githubActionsPath | Out-Null
}

# 1. Copy CI template
$ciSource = "templates/github-actions/$ProjectType/ci.yml"
if (Test-Path $ciSource) {
    $ciDest = Join-Path $githubActionsPath "ci.yml"
    if (-not (Test-Path $ciDest) -or $Force) {
        Write-Host "Copying CI template..."
        Copy-Item $ciSource $ciDest -Force
    } else {
        Write-Host "CI template already exists. Use -Force to overwrite." -ForegroundColor Yellow
    }
}

# 2. Copy gitignore
$gitignoreSourceMap = @{
    "python-backend" = "templates/gitignore/python.gitignore"
    "node-frontend" = "templates/gitignore/node.gitignore"
    "fullstack" = "templates/gitignore/fullstack.gitignore"
    "static-website" = "templates/gitignore/static-website.gitignore"
}

if ($gitignoreSourceMap.ContainsKey($ProjectType)) {
    $gitignoreSource = $gitignoreSourceMap[$ProjectType]
    $gitignoreDest = Join-Path $ProjectPath ".gitignore"
    if (-not (Test-Path $gitignoreDest) -or $Force) {
        Write-Host "Copying .gitignore..."
        Copy-Item $gitignoreSource $gitignoreDest -Force
    } else {
        Write-Host ".gitignore already exists. Use -Force to overwrite." -ForegroundColor Yellow
    }
}

# 3. Optional: Secret Scan
if ($IncludeSecretScan) {
    $secretScanSource = "templates/github-actions/security/secret-scan.yml"
    $secretScanDest = Join-Path $githubActionsPath "secret-scan.yml"
    if (-not (Test-Path $secretScanDest) -or $Force) {
        Write-Host "Copying secret scan workflow..."
        Copy-Item $secretScanSource $secretScanDest -Force
    } else {
        Write-Host "Secret scan workflow already exists. Use -Force to overwrite." -ForegroundColor Yellow
    }
}

# 4. Optional: Prompts
if ($IncludePrompts) {
    $promptsSource = "templates/prompts"
    $promptsDest = Join-Path $ProjectPath "ai-prompts"
    if (-not (Test-Path $promptsDest) -or $Force) {
        Write-Host "Copying prompt playbooks..."
        if (Test-Path $promptsDest) { Remove-Item $promptsDest -Recurse -Force }
        Copy-Item $promptsSource $promptsDest -Recurse -Force
    } else {
        Write-Host "ai-prompts directory already exists. Use -Force to overwrite." -ForegroundColor Yellow
    }
}

# 5. Optional: Project Docs
if ($IncludeProjectDocs) {
    $docsDest = Join-Path $ProjectPath "docs"
    if (-not (Test-Path $docsDest)) {
        New-Item -ItemType Directory -Path $docsDest | Out-Null
    }
    
    $workflowDocs = @("APPLY_TO_PROJECT.md", "DAILY_WORKFLOW.md", "RAM_SAFETY.md", "VALIDATION.md")
    foreach ($doc in $workflowDocs) {
        $docSource = "docs/$doc"
        $docDestPath = Join-Path $docsDest $doc
        if (-not (Test-Path $docDestPath) -or $Force) {
            Write-Host "Copying $doc..."
            Copy-Item $docSource $docDestPath -Force
        }
    }
}

Write-Host "Project bootstrap complete!" -ForegroundColor Green
