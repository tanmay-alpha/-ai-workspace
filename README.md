# ai-workspace

**A universal, production-oriented workflow toolkit for AI-assisted software engineering.**

Apply it to any project with one command. Get project detection, CI generation,
security scanning, AI agent context files, documentation templates, and rollback — all instantly.

---

## What Is ai-workspace?

ai-workspace is a **reusable engineering system** that you clone once and apply to every project you work on.
It is not a framework, a boilerplate generator, or an opinionated SaaS. It is a collection of:

- **Smart PowerShell scripts** that detect, analyze, and configure any project
- **CI/CD templates** tailored to your project type (Python, Node, fullstack, ML, trading, agentic AI)
- **Prompt playbooks** for AI agents to audit, debug, review, and plan
- **Documentation templates** for PRDs, roadmaps, ADRs, and checklists
- **Agent rules** that enforce safe, disciplined AI-assisted coding

---

## Who Is It For?

- **Solo engineers** who want professional discipline without overhead
- **AI-assisted developers** who use Codex, Claude, Gemini, or similar agents
- **Hackathon builders** who need a clean project setup in minutes
- **Students and learners** who want to adopt engineering best practices
- **Challenge authors** who need to create verifiable coding exercises
- **Startup engineers** who need a foundation that can scale

---

## Quick Start

### 1. Clone Once

```powershell
git clone https://github.com/tanmay-alpha/-ai-workspace.git C:\ai-workspace
```

### 2. Check Workspace Health

```powershell
powershell -ExecutionPolicy Bypass -File scripts\doctor.ps1
```

### 3. Apply to Any Existing Project (One Command)

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

### 4. Scaffold a New Project

```powershell
powershell -ExecutionPolicy Bypass -File scripts\new-project.ps1 `
  -ProjectPath "C:\Projects\my-new-app" `
  -ProjectName "My App" `
  -Preset python-backend
```

---

## Supported Project Types

| Type | Detection Signal | CI Behavior |
|---|---|---|
| `python-backend` | `requirements.txt` / `pyproject.toml` | Install deps, compileall, pytest |
| `node-frontend` | `package.json` | npm/pnpm/yarn install, build, test |
| `fullstack` | Both Python + Node | Separate backend + frontend jobs |
| `static-website` | `index.html` only | File existence checks |
| `ml-project` | sklearn / torch / pandas keywords | Python checks, no training in CI |
| `agentic-ai` | langchain / crewai / openai keywords | Python checks, no live API keys |
| `trading-system` | broker / order / strategy keywords | TRADING_MODE=PAPER enforced |
| `data-science` | Notebooks + ML keywords | Python checks |

Detection is automatic. Override with `-Preset` if needed.

---

## Scripts Reference

| Script | Purpose |
|---|---|
| `apply-ai-workspace.ps1` | **One-command** project applicator |
| `detect-project.ps1` | Detect project type and structure |
| `generate-project-map.ps1` | Generate `PROJECT_MAP.md` |
| `generate-ci.ps1` | Generate tailored CI workflow |
| `doctor.ps1` | Diagnose workspace and project health |
| `rollback-ai-workspace.ps1` | Restore from backup |
| `new-project.ps1` | Scaffold a new project from scratch |
| `validate-workspace.ps1` | Validate ai-workspace itself |
| `stop-heavy-tools.ps1` | Stop resource-heavy background processes |
| `bootstrap-project.ps1` | Legacy bootstrapper (v1) |

---

## Templates

| Template | Purpose |
|---|---|
| `templates/project-docs/` | PRD, Roadmap, Security Checklist, Production Readiness |
| `templates/agent-rules/` | AGENTS.md, AI_AGENT_RULES.md |
| `templates/github/` | PR template, Issue templates |
| `templates/adr/` | Architecture Decision Record starter |
| `templates/prompts/` | AI agent prompt playbooks |
| `templates/github-actions/` | CI/CD workflow templates by project type |
| `templates/gitignore/` | Language-specific gitignore files |
| `templates/challenge-authoring/` | Coding challenge creation workflow |
| `templates/mcp-profiles/` | MCP agent configuration references |

---

## Prompt Playbooks

Ready-to-use prompts for AI agents:

| Prompt | Use When |
|---|---|
| `repo-audit.md` | Comprehensive codebase review |
| `security-audit.md` | Security-focused review |
| `backend-debug.md` | Debugging a backend error |
| `frontend-qa.md` | Frontend quality assurance |
| `ci-fix.md` | CI pipeline is failing |
| `test-improvement.md` | Improving test coverage |
| `architecture-review.md` | Reviewing or planning architecture |
| `product-roadmap.md` | Building or refining a roadmap |
| `trading-system-safety-audit.md` | Pre-deployment safety check for trading |
| `ml-project-audit.md` | ML project quality and reproducibility |
| `agentic-ai-audit.md` | Agentic AI project safety audit |
| `startup-readiness-audit.md` | Startup readiness assessment |
| `shipd-challenge-authoring.md` | Creating coding challenges |

---

## AI Agent Workflow

ai-workspace is designed for use with:

| Agent | Role |
|---|---|
| **Codex** | Implementation (code writing, refactoring) |
| **Antigravity** | Large repo analysis, browser testing |
| **Gemini** | Repo analysis, large context reading |
| **Claude** | Architecture, planning, documentation |
| **Cline** | Local script orchestration |
| **Ollama** | Offline fallback |

See [docs/MCP_AND_AGENT_SETUP.md](docs/MCP_AND_AGENT_SETUP.md) for setup details.

---

## How to Apply to an Existing Project

See [docs/ONE_COMMAND_WORKFLOW.md](docs/ONE_COMMAND_WORKFLOW.md) for the full workflow.

**Always run with `-DryRun` first.** Then add `-Backup` when applying for real.
No files are overwritten without `-Force`. All overwrites create a backup with `-Backup`.

---

## How to Rollback

```powershell
# List backups
powershell -ExecutionPolicy Bypass -File scripts\rollback-ai-workspace.ps1 `
  -ProjectPath "C:\path\to\project" -List

# Restore a backup
powershell -ExecutionPolicy Bypass -File scripts\rollback-ai-workspace.ps1 `
  -ProjectPath "C:\path\to\project" -BackupName 20250524_120000
```

---

## Challenge Authoring

ai-workspace includes a full workflow for creating verifiable coding challenges.
See [docs/SHIPD_CHALLENGE_WORKFLOW.md](docs/SHIPD_CHALLENGE_WORKFLOW.md).

---

## Safety Rules

- **No secrets.** Never commit API keys, tokens, or credentials.
- **No `.env` tracking.** `.env` files must always be in `.gitignore`.
- **No live trading in CI.** All CI workflows enforce `TRADING_MODE=PAPER`.
- **No destructive defaults.** Scripts preview before acting.
- **Backup before overwrite.** Use `-Backup` whenever replacing existing files.
- **Rollback always available.** Use `rollback-ai-workspace.ps1` to undo.

---

## Folder Structure

```
ai-workspace/
├── scripts/              # PowerShell automation scripts
├── templates/
│   ├── project-docs/     # PRD, Roadmap, Security, Production checklists
│   ├── agent-rules/      # AGENTS.md, AI_AGENT_RULES.md
│   ├── github/           # PR template, Issue templates
│   ├── adr/              # Architecture Decision Records
│   ├── prompts/          # AI agent prompt playbooks
│   ├── github-actions/   # CI/CD templates by project type
│   ├── gitignore/        # Language gitignores
│   ├── challenge-authoring/ # Coding challenge workflow
│   └── mcp-profiles/     # MCP configuration references
├── docs/                 # Workflow and vision documentation
├── tests/fixtures/       # Minimal fixture projects for testing
├── tools/                # Utility tools
├── README.md             # This file
└── AI_WORKFLOW_CONTEXT.md  # Canonical AI agent context file
```

---

## Roadmap

- [ ] Auto-commit prevention hooks (pre-commit integration)
- [ ] GitHub Codespaces devcontainer support
- [ ] VS Code extension for PROJECT_MAP.md visualization
- [ ] Challenge submission validation script
- [ ] Multi-project workspace management
- [ ] Automated dependency update PR generation

---

## License

MIT — use freely in personal and commercial projects.

---

> **This is a production-oriented workflow toolkit, not a production-ready product for all use cases.**
> Test everything. Review all AI-generated content. Validate before shipping.
