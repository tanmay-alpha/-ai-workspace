<#
.SYNOPSIS
    Detects project type and structure for a given directory.
.DESCRIPTION
    Analyzes a project directory and returns detection results including
    project type, dependency files, build commands, and risk notes.
    Can output human-readable summary or JSON.
.PARAMETER ProjectPath
    Path to the project root to analyze. Default is current directory.
.PARAMETER Json
    Output results as JSON instead of human-readable summary.
.EXAMPLE
    .\detect-project.ps1 -ProjectPath C:\MyProject
    .\detect-project.ps1 -ProjectPath C:\MyProject -Json
#>
param (
    [Parameter(Mandatory=$false)]
    [string]$ProjectPath = '.',

    [switch]$Json
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $ProjectPath)) {
    Write-Error "ProjectPath does not exist: $ProjectPath"
    exit 1
}

$ProjectPath = (Resolve-Path $ProjectPath).Path

# --- helpers ------------------------------------------------------------------
function Test-Exists([string]$rel) {
    Test-Path (Join-Path $ProjectPath $rel)
}

function Get-FileContent([string]$rel) {
    $p = Join-Path $ProjectPath $rel
    if (Test-Path $p) { return (Get-Content $p -Raw -ErrorAction SilentlyContinue) }
    return ''
}

function Search-Content([string[]]$keywords, [string[]]$extensions) {
    foreach ($ext in $extensions) {
        $files = Get-ChildItem -Path $ProjectPath -Filter "*.$ext" -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\\.git|node_modules|venv|\.venv|__pycache__|dist|build|\.next|\.pytest_cache|\.ruff_cache|\.mypy_cache|\.tox|\.nuxt|htmlcov' }
        foreach ($file in $files) {
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content) {
                foreach ($kw in $keywords) {
                    if ($content -imatch $kw) { return $true }
                }
            }
        }
    }
    return $false
}

# --- detection flags ----------------------------------------------------------
$hasPkgRoot     = Test-Exists 'package.json'
$hasPkgFront    = Test-Exists 'frontend/package.json'
$hasPkgClient   = Test-Exists 'client/package.json'
$hasPyRoot      = (Test-Exists 'requirements.txt') -or (Test-Exists 'pyproject.toml') -or (Test-Exists 'setup.py')
$hasPyBackend   = (Test-Exists 'backend/requirements.txt') -or (Test-Exists 'backend/pyproject.toml')
$hasIndexHtml   = Test-Exists 'index.html'
$hasDockerfile  = (Test-Exists 'Dockerfile') -or (Test-Exists 'backend/Dockerfile') -or (Test-Exists 'frontend/Dockerfile')
$hasCompose     = (Test-Exists 'docker-compose.yml') -or (Test-Exists 'docker-compose.yaml')
$hasWorkflows   = Test-Exists '.github/workflows'
$hasEnvFile     = (Test-Exists '.env') -or (Test-Exists 'backend/.env') -or (Test-Exists 'frontend/.env')
$hasTests       = (Test-Exists 'tests') -or (Test-Exists 'test') -or (Test-Exists 'backend/tests') -or
                  (Test-Exists '__tests__') -or (Test-Exists 'spec')

# content-based hints
$mlKeywords      = @('sklearn','torch','tensorflow','keras','xgboost','lightgbm','pandas','numpy',
                     'notebook','model','dataset','training','inference','mlflow','huggingface','transformers')
$tradingKeywords = @('broker','order','market','candle','risk','portfolio','strategy','alpaca','ibkr',
                     'binance','oanda','backtesting','backtest','tick','spread','equity','futures',
                     'options','trading','exchange','position','fill','slippage')
$agentKeywords   = @('langchain','crewai','autogen','openai','anthropic','llm','agent','planner',
                     'memory','tool_call','function_call','embeddings','rag','vectorstore','mcp',
                     'function_tools','assistant','chat_completion')
$dbKeywords      = @('postgresql','sqlite','mysql','mongodb','redis','sqlalchemy','prisma',
                     'sequelize','mongoose','database','migration','orm','diesel','typeorm')

$hasMLHints       = Search-Content $mlKeywords @('py','txt','toml','ipynb')
$hasTradingHints  = Search-Content $tradingKeywords @('py','js','ts','txt','toml','md')
$hasAgenticHints  = Search-Content $agentKeywords @('py','js','ts','txt','toml','md','json')
$hasDatabaseHints = Search-Content $dbKeywords @('py','js','ts','txt','toml','json','sql')

# notebooks
$hasNotebooks = (Get-ChildItem -Path $ProjectPath -Filter '*.ipynb' -Recurse -ErrorAction SilentlyContinue |
    Measure-Object).Count -gt 0

# --- backend / frontend paths -------------------------------------------------
$BackendPath  = ''
$FrontendPath = ''

if ($hasPyBackend -or (Test-Exists 'backend')) { $BackendPath = 'backend' }
elseif ($hasPyRoot)                             { $BackendPath = '.' }

if ($hasPkgFront)                              { $FrontendPath = 'frontend' }
elseif ($hasPkgClient)                         { $FrontendPath = 'client' }
elseif ($hasPkgRoot -and (-not $hasPyRoot))    { $FrontendPath = '.' }

# --- python dependency file ---------------------------------------------------
$PythonDependencyFile = ''
if (Test-Exists 'backend/requirements.txt')  { $PythonDependencyFile = 'backend/requirements.txt' }
elseif (Test-Exists 'requirements.txt')       { $PythonDependencyFile = 'requirements.txt' }
elseif (Test-Exists 'pyproject.toml')         { $PythonDependencyFile = 'pyproject.toml' }
elseif (Test-Exists 'setup.py')               { $PythonDependencyFile = 'setup.py' }

# --- python version hint -----------------------------------------------------
$PythonVersionHint = '3.11'
if (Test-Exists '.python-version') {
    $v = (Get-Content (Join-Path $ProjectPath '.python-version') -ErrorAction SilentlyContinue | Select-Object -First 1)
    if ($v) { $PythonVersionHint = $v.Trim() }
} elseif (Test-Exists 'pyproject.toml') {
    $toml = Get-FileContent 'pyproject.toml'
    if ($toml -match 'python_requires\s*=\s*">=?([\d.]+)"') { $PythonVersionHint = $Matches[1] }
    elseif ($toml -match 'python\s*=\s*"[^"]*?([\d]+\.[\d]+)') { $PythonVersionHint = $Matches[1] }
}

# --- python commands ---------------------------------------------------------
$pythonCompileRoot    = if ($BackendPath -and $BackendPath -ne '.') { $BackendPath } else { '.' }
$PythonCompileCommand = "python -m compileall $pythonCompileRoot -q"
$PythonTestCommand    = ''
if ($hasTests) {
    if (Test-Exists 'backend/tests') { $PythonTestCommand = 'pytest backend/tests -q' }
    elseif (Test-Exists 'tests')     { $PythonTestCommand = 'pytest tests -q' }
    elseif (Test-Exists 'test')      { $PythonTestCommand = 'pytest test -q' }
    else                             { $PythonTestCommand = 'pytest -q' }
}

# --- node package manager ----------------------------------------------------
$nodePkgDir         = if ($FrontendPath) { $FrontendPath } else { '.' }
$NodePackageManager = 'none'
$NodeInstallCommand = ''
$NodeBuildCommand   = ''
$NodeTestCommand    = ''
$NodePath           = ''

if ($hasPkgRoot -or $hasPkgFront -or $hasPkgClient) {
    $NodePath = $nodePkgDir
    if (Test-Exists (Join-Path $nodePkgDir 'pnpm-lock.yaml')) {
        $NodePackageManager = 'pnpm'
        $NodeInstallCommand = 'pnpm install'
        $NodeBuildCommand   = 'pnpm run build'
        $NodeTestCommand    = 'pnpm run test'
    } elseif (Test-Exists (Join-Path $nodePkgDir 'yarn.lock')) {
        $NodePackageManager = 'yarn'
        $NodeInstallCommand = 'yarn install'
        $NodeBuildCommand   = 'yarn build'
        $NodeTestCommand    = 'yarn test'
    } elseif (Test-Exists (Join-Path $nodePkgDir 'package-lock.json')) {
        $NodePackageManager = 'npm'
        $NodeInstallCommand = 'npm ci'
        $NodeBuildCommand   = 'npm run build'
        $NodeTestCommand    = 'npm test'
    } else {
        $NodePackageManager = 'npm'
        $NodeInstallCommand = 'npm install'
        $NodeBuildCommand   = 'npm run build'
        $NodeTestCommand    = 'npm test'
    }
}

# --- check .env tracked ------------------------------------------------------
$EnvFilesTracked = $false
try {
    $isGitRepo = Test-Path (Join-Path $ProjectPath '.git')
    if ($isGitRepo) {
        $gitOut = & git -C $ProjectPath ls-files --error-unmatch .env 2>&1
        if ($LASTEXITCODE -eq 0) { $EnvFilesTracked = $true }
    }
} catch { $EnvFilesTracked = $false }

# --- project type ------------------------------------------------------------
$ProjectType       = 'unknown'
$RecommendedPreset = 'unknown'

$hasAnyPython = $hasPyRoot -or $hasPyBackend
$hasAnyNode   = $hasPkgRoot -or $hasPkgFront -or $hasPkgClient

if ($hasTradingHints -and $hasAnyPython) {
    $ProjectType = 'trading-system'; $RecommendedPreset = 'trading-system'
} elseif ($hasAgenticHints -and $hasAnyPython) {
    $ProjectType = 'agentic-ai'; $RecommendedPreset = 'agentic-ai'
} elseif (($hasMLHints -or $hasNotebooks) -and $hasAnyPython) {
    $ProjectType = 'ml-project'; $RecommendedPreset = 'ml-project'
} elseif ($hasAnyPython -and $hasAnyNode) {
    $ProjectType = 'fullstack'; $RecommendedPreset = 'fullstack'
} elseif ($hasAnyPython -and -not $hasAnyNode) {
    $ProjectType = 'python-backend'; $RecommendedPreset = 'python-backend'
} elseif ($hasAnyNode -and -not $hasAnyPython) {
    $ProjectType = 'node-frontend'; $RecommendedPreset = 'node-frontend'
} elseif ($hasIndexHtml -and -not $hasAnyNode -and -not $hasAnyPython) {
    $ProjectType = 'static-website'; $RecommendedPreset = 'static-website'
} elseif ($hasMLHints -or $hasNotebooks) {
    $ProjectType = 'data-science'; $RecommendedPreset = 'ml-project'
}

# --- risk notes --------------------------------------------------------------
$RiskNotes = [System.Collections.Generic.List[string]]::new()
if ($EnvFilesTracked)   { $RiskNotes.Add('WARNING: .env is tracked by git - remove with: git rm --cached .env') }
if ($hasEnvFile)         { $RiskNotes.Add('INFO: .env file detected locally - ensure it is in .gitignore') }
if ($hasTradingHints)    { $RiskNotes.Add('TRADING: Broker/order keywords detected - never run order-placing code in CI') }
if ($hasAgenticHints)    { $RiskNotes.Add('AGENTIC: AI agent keywords found - ensure no live API keys are in CI environment') }
if ($hasCompose)         { $RiskNotes.Add('DOCKER: docker-compose detected - review compose files for hardcoded credentials') }
if ($hasMLHints -and -not $PythonDependencyFile) {
    $RiskNotes.Add('ML: ML hints found but no dependency file detected - add requirements.txt or pyproject.toml')
}
if ($RiskNotes.Count -eq 0) {
    $RiskNotes.Add('No critical risks detected - run a full security audit before production deployment')
}

# --- result -------------------------------------------------------------------
$result = [ordered]@{
    ProjectType           = $ProjectType
    RecommendedPreset     = $RecommendedPreset
    BackendPath           = $BackendPath
    FrontendPath          = $FrontendPath
    PythonDependencyFile  = $PythonDependencyFile
    PythonVersionHint     = $PythonVersionHint
    PythonTestCommand     = $PythonTestCommand
    PythonCompileCommand  = $PythonCompileCommand
    NodePath              = $NodePath
    NodePackageManager    = $NodePackageManager
    NodeInstallCommand    = $NodeInstallCommand
    NodeBuildCommand      = $NodeBuildCommand
    NodeTestCommand       = $NodeTestCommand
    HasDockerfile         = $hasDockerfile
    HasDockerCompose      = $hasCompose
    HasGitHubWorkflows    = $hasWorkflows
    HasEnvFile            = $hasEnvFile
    EnvFilesTracked       = $EnvFilesTracked
    HasTests              = $hasTests
    HasFrontend           = ($FrontendPath -ne '')
    HasBackend            = ($BackendPath -ne '')
    HasDatabaseHints      = $hasDatabaseHints
    HasMLHints            = $hasMLHints
    HasTradingHints       = $hasTradingHints
    HasAgenticHints       = $hasAgenticHints
    RiskNotes             = $RiskNotes.ToArray()
}

if ($Json) {
    $result | ConvertTo-Json -Depth 5
} else {
    Write-Host ''
    Write-Host 'ai-workspace - Project Detection' -ForegroundColor Cyan
    Write-Host ('-' * 54) -ForegroundColor Cyan
    Write-Host ''
    Write-Host "  Path          : $ProjectPath"
    Write-Host "  Project Type  : $($result.ProjectType)"   -ForegroundColor Yellow
    Write-Host "  Preset        : $($result.RecommendedPreset)" -ForegroundColor Yellow
    Write-Host ''
    Write-Host '  Python ---------------------------------------------'
    Write-Host "  Dep File      : $(if($result.PythonDependencyFile){$result.PythonDependencyFile}else{'none'})"
    Write-Host "  Version Hint  : $($result.PythonVersionHint)"
    Write-Host "  Test Cmd      : $(if($result.PythonTestCommand){$result.PythonTestCommand}else{'(no tests detected)'})"
    Write-Host "  Compile Cmd   : $($result.PythonCompileCommand)"
    Write-Host ''
    Write-Host '  Node -----------------------------------------------'
    Write-Host "  Node Path     : $(if($result.NodePath){$result.NodePath}else{'none'})"
    Write-Host "  Pkg Manager   : $($result.NodePackageManager)"
    Write-Host "  Install Cmd   : $(if($result.NodeInstallCommand){$result.NodeInstallCommand}else{'none'})"
    Write-Host ''
    Write-Host '  Flags ----------------------------------------------'
    Write-Host "  Has Backend   : $($result.HasBackend)"
    Write-Host "  Has Frontend  : $($result.HasFrontend)"
    Write-Host "  Has Tests     : $($result.HasTests)"
    Write-Host "  Has Dockerfile: $($result.HasDockerfile)"
    Write-Host "  Has Workflows : $($result.HasGitHubWorkflows)"
    Write-Host "  Has DB Hints  : $($result.HasDatabaseHints)"
    Write-Host "  Has ML Hints  : $($result.HasMLHints)"
    Write-Host "  Has Trading   : $($result.HasTradingHints)"
    Write-Host "  Has Agentic   : $($result.HasAgenticHints)"
    Write-Host "  .env Tracked  : $($result.EnvFilesTracked)"
    Write-Host ''
    Write-Host '  Risk Notes -----------------------------------------'
    foreach ($note in $result.RiskNotes) {
        $color = if ($note -match '^WARNING') { 'Red' }
                 elseif ($note -match '^TRADING|^AGENTIC') { 'Yellow' }
                 else { 'Gray' }
        Write-Host "  $note" -ForegroundColor $color
    }
    Write-Host ''
}