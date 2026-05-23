# AI Workspace

A reusable AI-assisted development workflow system for building, testing, reviewing, and maintaining software projects.

This repository is not an application or a deployed website.  
It is a developer workflow toolkit containing reusable templates, prompts, scripts, and documentation for AI-assisted software engineering.

## Purpose

Modern development often involves multiple tools:

- AI coding agents
- terminal-based assistants
- IDE extensions
- CI/CD workflows
- secret scanning
- documentation workflows
- automation tools

This repository organizes those pieces into a reusable workflow that can be applied to many project types.

## What This Repo Provides

- GitHub Actions workflow templates
- Secret scanning workflow templates
- Reusable `.gitignore` templates
- AI prompt playbooks
- MCP/tooling workflow notes
- RAM and system safety guidelines
- Daily development workflow documentation
- Utility scripts for local development

## Coding Challenge Authoring

The `templates/challenge-authoring/` folder contains generic templates for
creating real-world, verifiable coding challenges from open-source repositories.
It covers repository selection, problem descriptions, deterministic tests,
reference solution review, Docker environments, and final submission checks.

## Supported Project Types

This workflow can be adapted for:

- Python backend projects
- Node.js / frontend projects
- full-stack applications
- static websites
- automation projects
- research or prototype repositories
- CLI tools
- internal developer tooling

## Repository Structure

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
