# AI Workspace

Universal AI/vibe-coding development workflow for Windows.

This repository is not for one project only. It is a reusable workflow system for all projects, including:

- SentinelX
- Indian algo trading platform
- Dynamic Bubble website
- AI/physics research projects
- future startup/project work

## Purpose

This repo stores reusable templates, prompts, scripts, and workflow documentation for a multi-agent AI development setup using:

- VS Code
- PowerShell
- GitHub
- Gemini CLI
- Codex CLI
- Codex VS Code panel
- Cline + MCP
- Ollama
- Continue.dev
- GitHub Copilot
- Playwright
- n8n
- pm2
- git-secrets
- Infisical
- Context7
- Firecrawl

## Main Rule

Use only one heavy agent at a time.

Do not run Gemini CLI, Codex CLI, Cline, Ollama, n8n, and browser automation together unless absolutely necessary.

## Folder Structure

```text
ai-workspace/
├── docs/
│   ├── DAILY_WORKFLOW.md
│   └── RAM_SAFETY.md
├── scripts/
│   ├── start-n8n.cmd
│   └── stop-heavy-tools.ps1
├── templates/
│   ├── github-actions/
│   ├── gitignore/
│   ├── mcp-profiles/
│   └── prompts/
├── .gitignore
├── .env.example
├── AI_WORKFLOW_CONTEXT.md
└── README.md
```
