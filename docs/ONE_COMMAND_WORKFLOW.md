# One-Command Workflow

> The complete guide to using ai-workspace with any project in a single command.

---

## Quick Start

### Step 1: Clone ai-workspace (once)

```powershell
git clone https://github.com/tanmay-alpha/-ai-workspace.git C:\ai-workspace
cd C:\ai-workspace
```

### Step 2: Run Doctor (verify workspace health)

```powershell
powershell -ExecutionPolicy Bypass -File scripts\doctor.ps1
```

Review the output. All core scripts should PASS.

### Step 3: Dry Run on Your Project

```powershell
powershell -ExecutionPolicy Bypass -File scripts\apply-ai-workspace.ps1 `
  -ProjectPath "C:\path\to\your-project" `
  -Preset auto `
  -IncludeCI `
  -IncludeSecretScan `
  -IncludePrompts `
  -IncludeDocs `
  -GenerateProjectMap `
  -IncludeADR `
  -IncludePRD `
  -IncludeRoadmap `
  -IncludeAgentRules `
  -IncludeGitHubTemplates `
  -DryRun
```

Review the planned actions. No files are written in DryRun mode.

### Step 4: Apply with Backup

```powershell
powershell -ExecutionPolicy Bypass -File scripts\apply-ai-workspace.ps1 `
  -ProjectPath "C:\path\to\your-project" `
  -Preset auto `
  -IncludeCI `
  -IncludeSecretScan `
  -IncludePrompts `
  -IncludeDocs `
  -GenerateProjectMap `
  -IncludeADR `
  -IncludePRD `
  -IncludeRoadmap `
  -IncludeAgentRules `
  -IncludeGitHubTemplates `
  -Backup
```

### Step 5: Validate Target Project

```powershell
powershell -ExecutionPolicy Bypass -File scripts\doctor.ps1 -ProjectPath "C:\path\to\your-project"
```

Review the PASS/WARN/FAIL table for the target project.

### Step 6: Review and Commit Safely

```powershell
cd C:\path\to\your-project
git diff --stat
git add -p  # stage selectively
git commit -m "Apply ai-workspace v2 context files"
```

### Step 7: Rollback (if needed)

```powershell
powershell -ExecutionPolicy Bypass -File scripts\rollback-ai-workspace.ps1 `
  -ProjectPath "C:\path\to\your-project" -List
# Then restore a specific backup:
powershell -ExecutionPolicy Bypass -File scripts\rollback-ai-workspace.ps1 `
  -ProjectPath "C:\path\to\your-project" -BackupName 20250524_120000
```

---

## AI Agent Workflow

### Using Codex (Implementation)

1. Run apply-ai-workspace to generate `PROJECT_MAP.md`
2. Open Codex and point it at the project
3. Paste the task with: "Read PROJECT_MAP.md and AGENTS.md first"
4. Review generated code before accepting

### Using Antigravity / Gemini (Analysis)

1. Open the conversation
2. Say: "I am working in C:\path\to\project — read PROJECT_MAP.md"
3. Ask analysis questions
4. Request specific targeted changes only

### Using Claude (Architecture)

1. Paste the contents of PROJECT_MAP.md and relevant source files
2. Use the `architecture-review.md` prompt template from ai-prompts/
3. Review the architectural proposal before asking for implementation

### Using Cline (Local Orchestration)

1. Cline can run PowerShell scripts directly
2. Direct it to run: `apply-ai-workspace.ps1` first
3. Then run task-specific agent commands

---

## Full Command Reference

```powershell
# Detect project type
powershell -ExecutionPolicy Bypass -File scripts\detect-project.ps1 -ProjectPath <path>

# Generate project map
powershell -ExecutionPolicy Bypass -File scripts\generate-project-map.ps1 -ProjectPath <path>

# Generate CI only
powershell -ExecutionPolicy Bypass -File scripts\generate-ci.ps1 -ProjectPath <path> -DryRun

# Apply everything
powershell -ExecutionPolicy Bypass -File scripts\apply-ai-workspace.ps1 -ProjectPath <path> -Preset auto -IncludeCI -GenerateProjectMap -Backup

# Doctor check
powershell -ExecutionPolicy Bypass -File scripts\doctor.ps1 -ProjectPath <path>

# Rollback
powershell -ExecutionPolicy Bypass -File scripts\rollback-ai-workspace.ps1 -ProjectPath <path> -List

# Scaffold new project
powershell -ExecutionPolicy Bypass -File scripts\new-project.ps1 -ProjectPath C:\Projects\my-new-app -Preset python-backend -DryRun

# Validate workspace
powershell -ExecutionPolicy Bypass -File scripts\validate-workspace.ps1
```
