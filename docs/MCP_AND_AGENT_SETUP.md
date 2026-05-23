# MCP and Agent Setup

> How to configure and use AI agents effectively with ai-workspace.

---

## Agent Role Map

| Agent | Primary Role | Best For |
|---|---|---|
| **Codex** | Implementation | Writing code, refactoring, adding tests |
| **Antigravity** | Large repo analysis + browser | Repo-wide edits, devtools, multi-file changes |
| **Gemini** | Analysis + context | Repo analysis, large file review, planning |
| **Claude** | Architecture + planning | Design discussions, documentation, review |
| **Cline** | Local orchestration | Running scripts, multi-step workflows |
| **Ollama** | Offline fallback | Simple tasks without internet |
| **n8n** | Automation | Recurring workflows, event-driven tasks |
| **Playwright / Chrome MCP** | Browser validation | UI testing, form filling, screenshot capture |
| **GitHub MCP** | GitHub operations | Issues, PRs, repo management |
| **Context7** | Documentation lookup | Finding API docs, library references |

---

## MCP (Model Context Protocol)

MCP servers extend AI agents with specialized tools. ai-workspace is designed to work
with the following MCP servers:

### filesystem-ai-workspace
- Provides file read/write access to the workspace
- Used by agents to read PROJECT_MAP.md and AGENTS.md
- Configured via `.gemini/` or equivalent agent config

### github-mcp-server
- Creates issues, PRs, and manages repository operations
- Used for: automated issue creation, PR review, branch management

### playwright / chrome-devtools-mcp
- Browser automation and testing
- Used for: UI validation, frontend QA, screenshot capture

### sequential-thinking
- Structured reasoning for complex multi-step tasks
- Used for: architecture decisions, debugging complex issues

---

## Setting Up Context for Any Agent

When starting a session with any AI agent, provide this context:

```
I am working in: [absolute path to project]

Before starting, please read:
1. PROJECT_MAP.md (project structure and detected type)
2. AGENTS.md (rules for AI agents in this project)
3. AI_AGENT_RULES.md (global agent rules)

The project type is: [detected type from detect-project.ps1]
```

---

## One-Heavy-Agent-at-a-Time Rule

Running multiple large AI processes simultaneously causes:
- RAM exhaustion
- CPU throttling
- Context confusion (agents overwriting each other's work)

**Rule:** Only run one heavyweight AI agent at a time.

Use `scripts/stop-heavy-tools.ps1` to terminate background processes before switching agents.

---

## Recommended Workflow by Task Type

### "I need to understand a new codebase"
1. Run `generate-project-map.ps1` to create PROJECT_MAP.md
2. Use **Gemini / Antigravity** to analyze (large context window)
3. Ask specific questions about architecture or code patterns

### "I need to implement a feature"
1. Read PROJECT_MAP.md and AGENTS.md first
2. Use **Codex** for implementation (focused, code-first)
3. Review generated code before accepting

### "I need to fix a CI failure"
1. Read the CI error log in full
2. Use the `ci-fix.md` prompt template
3. Use **Claude or Antigravity** to diagnose
4. Apply fix and verify locally before pushing

### "I need to test a UI flow"
1. Use **Playwright MCP or Chrome DevTools MCP**
2. Take screenshots before and after
3. Verify functionality across viewport sizes

### "I need to manage GitHub issues"
1. Use **GitHub MCP** for issue creation and PR management
2. Link issues to commits and PRs
