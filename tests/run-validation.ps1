# ai-workspace Phase 6 - Full Validation Suite
# Run from ai-workspace root:
#   powershell -ExecutionPolicy Bypass -File tests\run-validation.ps1

$ErrorActionPreference = 'Continue'   # don't stop on child process errors

$RepoRoot         = Resolve-Path (Join-Path $PSScriptRoot "..")
$FixturesRoot     = Join-Path $RepoRoot "tests\fixtures"
$PythonFixture    = Join-Path $FixturesRoot "sample-python-backend"
$NodeFixture      = Join-Path $FixturesRoot "sample-node-frontend"
$FullstackFixture = Join-Path $FixturesRoot "sample-fullstack"

$results = [System.Collections.Generic.List[PSCustomObject]]::new()

# --- helpers --------------------------------------------------------------------
function Join-Output($raw) {
    if ($raw -is [array]) { return $raw -join "`n" } else { return "$raw" }
}

function Test-Step {
    param([string]$Name, [scriptblock]$Block)
    Write-Host ''
    Write-Host "TEST: $Name" -ForegroundColor Cyan
    try {
        & $Block
        Write-Host "  PASS: $Name" -ForegroundColor Green
        $results.Add([PSCustomObject]@{ Name=$Name; Status='PASS'; Detail='' })
    } catch {
        $msg = $_.Exception.Message -replace "`r`n","`n"
        $firstLine = ($msg -split "`n")[0]
        Write-Host "  FAIL: $Name" -ForegroundColor Red
        Write-Host "        $firstLine" -ForegroundColor Red
        $results.Add([PSCustomObject]@{ Name=$Name; Status='FAIL'; Detail=$firstLine })
    }
}

function Invoke-PS1 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$File,
        [Parameter(Mandatory=$false)]
        [string[]]$ScriptArgs = @()
    )
    $raw = & powershell -ExecutionPolicy Bypass -File $File @ScriptArgs 2>&1
    return [PSCustomObject]@{ Output=(Join-Output $raw); ExitCode=$LASTEXITCODE }
}

function Assert-Equal($actual, $expected, $message) {
    if ($actual -ne $expected) {
        throw "Assertion Failed: $message (Expected '$expected', Got '$actual')"
    }
}

function Assert-Contains($text, $substring, $message) {
    if ($text -notlike "*$substring*") {
        throw "Assertion Failed: $message (Expected to contain '$substring')"
    }
}

# --- tests ----------------------------------------------------------------------

$DetectScript = Join-Path $RepoRoot "scripts\detect-project.ps1"
$MapScript    = Join-Path $RepoRoot "scripts\generate-project-map.ps1"
$CIScript     = Join-Path $RepoRoot "scripts\generate-ci.ps1"
$ValidateWS   = Join-Path $RepoRoot "scripts\validate-workspace.ps1"
$DoctorScript = Join-Path $RepoRoot "scripts\doctor.ps1"

# 1. Detect Python Backend
Test-Step "Detect Project - Python Backend" {
    $json = & $DetectScript -ProjectPath $PythonFixture -Json
    $result = $json | ConvertFrom-Json
    Assert-Equal $result.ProjectType "python-backend" "Should detect python-backend"
    Assert-Equal $result.PythonDependencyFile "requirements.txt" "Should detect requirements.txt"
}

# 2. Detect Node Frontend
Test-Step "Detect Project - Node Frontend" {
    $json = & $DetectScript -ProjectPath $NodeFixture -Json
    $result = $json | ConvertFrom-Json
    Assert-Equal $result.ProjectType "node-frontend" "Should detect node-frontend"
    Assert-Equal $result.NodePackageManager "npm" "Should detect npm"
}

# 3. Detect Fullstack
Test-Step "Detect Project - Fullstack" {
    $json = & $DetectScript -ProjectPath $FullstackFixture -Json
    $result = $json | ConvertFrom-Json
    Assert-Equal $result.ProjectType "fullstack" "Should detect fullstack"
}

# 4. Generate Project Map - NoWrite
Test-Step "Generate Project Map - NoWrite" {
    $output = & $MapScript -ProjectPath $PythonFixture -NoWrite
    $outputText = Join-Output $output
    Assert-Contains $outputText "# Project Map" "Output should contain '# Project Map' heading"
}

# 5. Generate CI - DryRun
Test-Step "Generate CI - DryRun" {
    $output = & $CIScript -ProjectPath $PythonFixture -DryRun
    $outputText = Join-Output $output
    Assert-Contains $outputText "name: Universal CI" "Output should contain generated YAML header"
}

# 6. Validate Workspace Script
Test-Step "Validate Workspace Script" {
    $res = Invoke-PS1 -File $ValidateWS
    Assert-Equal $res.ExitCode 0 "validate-workspace.ps1 should exit with 0"
    Assert-Contains $res.Output "Workspace validation passed!" "Should report validation passed"
}

# 7. Doctor Script
Test-Step "Doctor Script" {
    $res = Invoke-PS1 -File $DoctorScript
    Assert-Equal $res.ExitCode 0 "doctor.ps1 should exit with 0"
}

# 8. Public-Safety Scan
Test-Step "Public-Safety Scan" {
    $forbiddenWords = @(
        ("TAN" + "MAY"),
        ("Personal" + "Project" + "X"),
        ("Internal" + "System" + "Y"),
        ("Private" + "Repo" + "Z"),
        ("Challenge" + "Platform" + "A")
    )
    
    $filesToScan = Get-ChildItem -Path $RepoRoot -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object {
            $fullName = $_.FullName
            $fullName -notmatch '\\.git|node_modules|venv|\.venv|__pycache__|dist|build|\.next|\.pytest_cache|\.ruff_cache|\.mypy_cache|\.tox' -and
            $_.Name -ne 'validate-workspace.ps1' -and
            $_.Name -ne 'run-validation.ps1'
        }
        
    $foundForbidden = [System.Collections.Generic.List[string]]::new()
    foreach ($file in $filesToScan) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content) {
            foreach ($word in $forbiddenWords) {
                if ($word -eq ("TAN" + "MAY")) {
                    $cleanContent = $content -ireplace ("tanmay" + "-alpha"), ""
                    if ($cleanContent -imatch $word) {
                        $foundForbidden.Add("$($file.FullName) contains forbidden word: $word")
                    }
                } else {
                    if ($content -match $word) {
                        $foundForbidden.Add("$($file.FullName) contains forbidden word: $word")
                    }
                }
            }
        }
    }
    
    if ($foundForbidden.Count -gt 0) {
        $msg = $foundForbidden -join "`n"
        throw "Found forbidden placeholder words in codebase:`n$msg"
    }
}

# --- summary --------------------------------------------------------------------
Write-Host ''
Write-Host '==================================================' -ForegroundColor Cyan
Write-Host 'TEST RESULTS SUMMARY' -ForegroundColor Cyan
Write-Host '==================================================' -ForegroundColor Cyan
$failuresCount = 0
foreach ($res in $results) {
    $color = if ($res.Status -eq 'PASS') { 'Green' } else { 'Red' }
    Write-Host "  [$($res.Status)] $($res.Name)" -ForegroundColor $color
    if ($res.Status -eq 'FAIL') {
        Write-Host "         $($res.Detail)" -ForegroundColor Red
        $failuresCount++
    }
}
Write-Host ''

if ($failuresCount -gt 0) {
    Write-Host "Validation failed with $failuresCount failures." -ForegroundColor Red
    exit 1
} else {
    Write-Host "All tests passed successfully!" -ForegroundColor Green
    exit 0
}