# ai-workspace Phase 6 - Full Validation Suite
# Run from ai-workspace root:
#   powershell -ExecutionPolicy Bypass -File tests\run-validation.ps1

$ErrorActionPreference = 'Continue'   # don't stop on child process errors

$RepoRoot            = Resolve-Path (Join-Path $PSScriptRoot "..")
$FixturesRoot        = Join-Path $RepoRoot "tests\fixtures"
$PythonFixture       = Join-Path $FixturesRoot "sample-python-backend"
$NodeFixture         = Join-Path $FixturesRoot "sample-node-frontend"
$FullstackFixture    = Join-Path $FixturesRoot "sample-fullstack"
$FastAPIFixture      = Join-Path $FixturesRoot "sample-fastapi-backend"
$FraudFixture        = Join-Path $FixturesRoot "sample-fraud-backend"
$TradingFixture      = Join-Path $FixturesRoot "sample-trading-backend"

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

function Assert-NotContains($text, $substring, $message) {
    if ($text -like "*$substring*") {
        throw "Assertion Failed: $message (Expected NOT to contain '$substring')"
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

# 4. Detect FastAPI Backend
Test-Step "Detect Project - FastAPI Backend" {
    $json = & $DetectScript -ProjectPath $FastAPIFixture -Json
    $result = $json | ConvertFrom-Json
    Assert-Equal $result.ProjectType "python-backend" "Should detect python-backend for FastAPI"
    Assert-Contains ($result.DetectionEvidence -join " ") "FastAPI" "Evidence should mention FastAPI"
}

# 5. Detect Fraud Backend (SentinelX-like)
Test-Step "Detect Project - Fraud Backend" {
    $json = & $DetectScript -ProjectPath $FraudFixture -Json
    $result = $json | ConvertFrom-Json
    Assert-Equal $result.ProjectType "python-backend" "Should detect python-backend for Fraud backend"
    Assert-Equal $result.HasTradingHints $false "Should NOT have trading hints"
    Assert-Contains ($result.DomainHints -join " ") "fraud" "Domain hints should include fraud"
}

# 6. Detect Trading Backend
Test-Step "Detect Project - Trading Backend" {
    $json = & $DetectScript -ProjectPath $TradingFixture -Json
    $result = $json | ConvertFrom-Json
    Assert-Equal $result.ProjectType "python-backend" "Should detect python-backend for Trading backend"
    Assert-Equal $result.HasTradingHints $true "Should have trading hints due to strong broker evidence"
    Assert-Contains ($result.DomainHints -join " ") "trading" "Domain hints should include trading"
}

# 7. Generate Project Map - NoWrite
Test-Step "Generate Project Map - NoWrite" {
    $output = & $MapScript -ProjectPath $PythonFixture -NoWrite
    $outputText = Join-Output $output
    Assert-Contains $outputText "# Project Map" "Output should contain '# Project Map' heading"
}

# 8. Generate CI - DryRun
Test-Step "Generate CI - DryRun" {
    $output = & $CIScript -ProjectPath $PythonFixture -DryRun
    $outputText = Join-Output $output
    Assert-Contains $outputText "name: Universal CI" "Output should contain generated YAML header"
}

# 9. Validate Workspace Script
Test-Step "Validate Workspace Script" {
    $res = Invoke-PS1 -File $ValidateWS
    Assert-Equal $res.ExitCode 0 "validate-workspace.ps1 should exit with 0"
    Assert-Contains $res.Output "Workspace validation passed!" "Should report validation passed"
}

# 10. Doctor Script
Test-Step "Doctor Script" {
    $res = Invoke-PS1 -File $DoctorScript
    Assert-Equal $res.ExitCode 0 "doctor.ps1 should exit with 0"
}

# 11. Public-Safety Scan
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
            $fullName -notmatch '\\.git|node_modules|venv|\.venv|__pycache__|dist|build|\.next|\.pytest_cache|\.ruff_cache|\.mypy_cache|\.tox|\.ai-workspace-backup' -and
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

# 12. Verify Preset Synchronization and Regression Tests
Test-Step "Verify Preset Synchronization and Regression Tests" {
    # Test valid preset python-backend succeeds
    $res1 = Invoke-PS1 -File (Join-Path $RepoRoot "scripts\apply-ai-workspace.ps1") -ScriptArgs @("-Preset", "python-backend", "-DryRun")
    Assert-Equal $res1.ExitCode 0 "apply-ai-workspace.ps1 -Preset python-backend should succeed"

    # Test invalid preset fails cleanly
    $res2 = Invoke-PS1 -File (Join-Path $RepoRoot "scripts\apply-ai-workspace.ps1") -ScriptArgs @("-Preset", "invalid-preset-xyz")
    Assert-Contains $res2.Output "Invalid preset" "apply-ai-workspace.ps1 should throw validation error for invalid preset"

    # Test generate-ci.ps1 with invalid preset
    $res3 = Invoke-PS1 -File (Join-Path $RepoRoot "scripts\generate-ci.ps1") -ScriptArgs @("-Preset", "invalid-preset-xyz")
    Assert-Contains $res3.Output "Invalid preset" "generate-ci.ps1 should throw validation error for invalid preset"

    # Test new-project.ps1 with invalid preset
    $res4 = Invoke-PS1 -File (Join-Path $RepoRoot "scripts\new-project.ps1") -ScriptArgs @("-Preset", "invalid-preset-xyz")
    Assert-Contains $res4.Output "Invalid preset" "new-project.ps1 should throw validation error for invalid preset"

    # Regression: apply-ai-workspace.ps1 runs with auto on trading fixture in DryRun
    $argsList = @(
        "-ProjectPath", $TradingFixture,
        "-Preset", "auto",
        "-IncludeCI",
        "-IncludeSecretScan",
        "-IncludePrompts",
        "-IncludeDocs",
        "-GenerateProjectMap",
        "-Backup",
        "-DryRun"
    )
    $resTrading = Invoke-PS1 -File (Join-Path $RepoRoot "scripts\apply-ai-workspace.ps1") -ScriptArgs $argsList
    Assert-Equal $resTrading.ExitCode 0 "Trading backend apply with auto and DryRun should succeed"
    Assert-Contains $resTrading.Output "DRY RUN complete. No files written." "Output should confirm DryRun completed"
    Assert-NotContains $resTrading.Output "Invalid preset" "Trading backend apply should not throw preset errors"

    # Regression: dry-run must write NO files to destination
    $mapFile = Join-Path $TradingFixture "PROJECT_MAP.md"
    $ciFile = Join-Path $TradingFixture ".github\workflows\ci.yml"
    Assert-Equal (Test-Path $mapFile) $false "DryRun must not write PROJECT_MAP.md"
    Assert-Equal (Test-Path $ciFile) $false "DryRun must not write ci.yml"

    # Verify generate-ci.ps1 accepts valid presets: python-backend, fullstack, trading-system, unknown, auto
    $presetsToTest = @('python-backend', 'fullstack', 'trading-system', 'unknown', 'auto')
    foreach ($p in $presetsToTest) {
        $resCI = Invoke-PS1 -File (Join-Path $RepoRoot "scripts\generate-ci.ps1") -ScriptArgs @("-ProjectPath", $TradingFixture, "-Preset", $p, "-DryRun")
        Assert-Equal $resCI.ExitCode 0 "generate-ci.ps1 should accept preset '$p'"
    }

    # Verify atomic apply: preflight catches bad preset before writing anything
    # We will run a non-dryrun command with an invalid preset and verify no files are written
    $resBadApply = Invoke-PS1 -File (Join-Path $RepoRoot "scripts\apply-ai-workspace.ps1") -ScriptArgs @("-ProjectPath", $TradingFixture, "-Preset", "bad-preset-xyz")
    if ($resBadApply.ExitCode -eq 0) {
        throw "Assertion Failed: Bad preset should fail execution (Expected non-zero exit code, Got '0')"
    }
    Assert-Equal (Test-Path $mapFile) $false "Preflight failure must prevent writing PROJECT_MAP.md"
    Assert-Equal (Test-Path $ciFile) $false "Preflight failure must prevent writing ci.yml"
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