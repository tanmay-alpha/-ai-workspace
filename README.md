# AI Workspace

A polished, public-friendly, reusable AI-assisted development workflow toolkit for building, testing, reviewing, and maintaining software projects.

## Purpose

Modern development often involves multiple tools: AI coding agents, terminal-based assistants, CI/CD workflows, and automation. This repository organizes these pieces into a reusable system that can be applied to any project type.

## Tech Stack

- **CI/CD:** GitHub Actions
- **Scripting:** PowerShell / Bash
- **Documentation:** Markdown
- **AI Tooling:** MCP (Model Context Protocol), Prompt Engineering

## Folder Structure

- `docs/`: Core workflow documentation and safety guides.
- `scripts/`: Utility scripts for workspace management and validation.
- `templates/`:
  - `github-actions/`: CI/CD workflows for various project types.
  - `gitignore/`: Standard gitignore templates.
  - `mcp-profiles/`: Configurations for AI tool agents.
  - `prompts/`: Reusable prompt playbooks for analysis and implementation.
  - `challenge-authoring/`: Workflows for creating verifiable coding challenges.

## Validate This Workspace

To ensure the toolkit is healthy and secure, run the validation script:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\validate-workspace.ps1
```

See [docs/VALIDATION.md](docs/VALIDATION.md) for more details.

## How To Apply To A Project

1. Choose your project type (Python, Node, etc.).
2. Copy relevant GitHub Actions from `templates/github-actions/`.
3. Apply standard `.gitignore` from `templates/gitignore/`.
4. Setup secret scanning.
5. Follow the [docs/APPLY_TO_PROJECT.md](docs/APPLY_TO_PROJECT.md) guide for a full walkthrough.

## Coding Challenge Authoring

The `templates/challenge-authoring/` folder provides a structured way to create verifiable, deterministic coding challenges from existing repositories. This is ideal for technical interviews, skill assessments, or educational content.

## Security Rules

- **No Secrets:** Never commit API keys, tokens, or production credentials.
- **Scan Often:** Use the included secret-scanning workflows.
- **Generic Examples:** Keep all public-facing documentation generic.

## Daily Workflow

1. Determine task scope.
2. Use one heavy AI agent at a time.
3. Validate changes locally before pushing.
4. See [docs/DAILY_WORKFLOW.md](docs/DAILY_WORKFLOW.md) for the full checklist.
