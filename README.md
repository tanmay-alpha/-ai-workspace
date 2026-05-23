# AI Workspace

A reusable AI development workflow system for building, testing, and maintaining multiple software projects with AI agents.

This is not an app or website.  
This repo is my personal AI engineering command center.

It helps me quickly apply the same development workflow, CI/CD setup, security checks, prompt templates, and agent rules across different projects.

## Why This Exists

I work on multiple projects:

- SentinelX
- Indian algo trading platform
- Dynamic Bubble website
- AI/research experiments
- future startup/product ideas

Instead of setting up CI, secret scanning, prompts, gitignore files, and AI agent rules again and again, this repo stores reusable templates and workflows in one place.

## What This Repo Contains

```text
ai-workspace/
├── docs/
│   ├── DAILY_WORKFLOW.md
│   └── RAM_SAFETY.md
├── scripts/
│   └── stop-heavy-tools.ps1
├── templates/
│   ├── github-actions/
│   ├── gitignore/
│   ├── mcp-profiles/
│   └── prompts/
├── .env.example
├── .gitignore
├── AI_WORKFLOW_CONTEXT.md
└── README.md
## Tech Stack

- VS Code
- PowerShell
- GitHub Actions
- Gemini CLI
- Codex CLI
- Cline
- Ollama
- Context7 MCP
- Firecrawl MCP
- git-secrets
- Infisical
- Python
- Node.js