# AI Workflow Context

## Purpose

This repository provides a reusable AI-assisted software development workflow. The goal is to organize AI coding workflows, CI/CD templates, and prompt playbooks into a single, modular engineering system.

---

# Core Workflow Philosophy

1. **Agent Role Separation:** Use the right tool for the right task (Analysis vs. Implementation).
2. **One-Heavy-Agent-at-a-Time:** Prevent system overload and context confusion by running only one intensive AI process.
3. **Validation First:** Always validate the workspace and code locally before applying changes or pushing to remote.
4. **Public-Friendly Security:** Rigorously avoid committing secrets and personal data.

---

# AI Agent Roles

## Planning / Architecture Assistant
Focused on high-level design, review, and strategy. Best for architecture discussions and debugging plans.

## Large-Context CLI Assistant
Excellent for repository-wide analysis, log processing, and identifying technical debt across many files.

## Coding Agent (Implementation)
Handles the "heavy lifting" of writing code, refactoring, and adding tests. Operates on a Plan -> Act -> Validate cycle.

## Tool / MCP Agent
Specialized in filesystem access, GitHub operations, documentation lookup, and web research using the Model Context Protocol.

---

# Project Application Workflow

Before applying this toolkit to a new project:
1. **Run Validation:** Ensure the source toolkit is clean using `scripts/validate-workspace.ps1`.
2. **Select Components:** Choose only the templates (CI, gitignore, prompts) needed for the target project.
3. **Configure Locally:** Update environment variables using `.env.example`.
4. **Final Check:** Run a secret scan on the target project after applying templates.

---

# Verifiable Coding Challenge Authoring

The challenge authoring workflow converts repository tasks into deterministic exercises.
1. **Pin Commit:** Use an immutable commit hash.
2. **Deterministic Tests:** Ensure tests fail without the fix and pass with it.
3. **Reference Solution:** Create a minimal, clean patch for verification.
4. **Sanitize:** Remove all private context and internal details before publishing.

---

# Security Principles

- **Ignore `.env`:** Never track environment files with real secrets.
- **Use Examples:** Provide `.env.example` with generic placeholders.
- **Scan Workflows:** Mandatory secret scanning in CI/CD.
- **Minimalism:** Enable only the tools and permissions required for the current task.

---

# Stability Rules

Running multiple large-context models or automation servers simultaneously can cause RAM exhaustion and CPU throttling. Always stop background tools when switching between intensive tasks.
