# AI Workflow Context

> **Canonical context file for AI agents working in this repository.**
> Read this file before making any changes.

---

## Repository Purpose

ai-workspace is a **universal AI engineering workflow toolkit**.

It provides scripts, templates, and conventions that can be applied to any software project to:
- Auto-detect project type and structure
- Generate tailored CI/CD workflows
- Produce AI agent context files (`PROJECT_MAP.md`, `AGENTS.md`)
- Enforce security best practices by default
- Enable one-command project onboarding with backup and rollback

---

## Non-Negotiable Safety Rules

1. **Never read, write, or reference `.env` files.** Not in this repo, not in target projects.
2. **Never add real API keys, tokens, passwords, or credentials** to any file.
3. **Never place real broker or exchange orders.** Trading CI always uses `TRADING_MODE=PAPER`.
4. **Never overwrite user files** without `-Force` being explicitly passed.
5. **Never push to remote** without explicit human instruction.
6. **Never run destructive commands** (DROP TABLE, bulk deletes, file removals) without explicit approval.
7. **Never commit generated folders** (node_modules, venv, __pycache__, dist, .next).

---

## How Agents Should Inspect This Repo

Before modifying anything:
1. Read this file (`AI_WORKFLOW_CONTEXT.md`)
2. Read `README.md` for the high-level picture
3. List `scripts/` to see what automation exists
4. List `templates/` to understand available templates
5. Run detect-project on any target project before touching it

---

## How Agents Should Modify This Repo

**Allowed:**
- Creating new scripts in `scripts/`
- Creating new templates in `templates/`
- Updating `docs/`
- Updating `README.md` and this file

**Requires explicit approval:**
- Modifying existing scripts (review impact on dependent scripts first)
- Adding new PowerShell parameters to existing scripts
- Changing template file names or paths (updates validate-workspace.ps1 too)

**Never allowed:**
- Adding hardcoded paths, usernames, or project names
- Adding secrets or credentials
- Modifying `.gitignore` to track sensitive files
- Adding heavy runtime dependencies without documenting them

---

## Validation Commands

After any changes to this repository, run:

```powershell
# Full workspace validation
powershell -ExecutionPolicy Bypass -File scripts\validate-workspace.ps1

# Self-diagnostic
powershell -ExecutionPolicy Bypass -File scripts\doctor.ps1

# Smoke test: detect this repo itself
powershell -ExecutionPolicy Bypass -File scripts\detect-project.ps1 -ProjectPath .

# Dry-run apply to this repo (no files written)
powershell -ExecutionPolicy Bypass -File scripts\apply-ai-workspace.ps1 -ProjectPath . -Preset auto -GenerateProjectMap -DryRun

# CI generation dry run
powershell -ExecutionPolicy Bypass -File scripts\generate-ci.ps1 -ProjectPath . -DryRun

# Check for whitespace errors
git diff --check
git status
```

---

## No-Secret Policy

This repo is **public**. Every file in it must be safe to share publicly.

Before committing any file:
- No real API keys (search for `AKIA`, `sk-`, `ghp_`)
- No passwords or secrets (search for `password=`, `secret=`)
- No personal access tokens
- No private paths or usernames
- No internal project names or company references

`validate-workspace.ps1` enforces a subset of these checks automatically.

---

## Dry-Run / Backup / Rollback Policy

All scripts that modify files must support:
- `-DryRun` — preview actions without executing
- `-Backup` — create a timestamped backup before overwriting
- `-Force` — explicitly allow overwriting

All backups are stored in `.ai-workspace-backup/<timestamp>/` in the target project.
`rollback-ai-workspace.ps1` can restore any backup without deleting it.

---

## Supported Workflows

1. **Apply to existing project** — `apply-ai-workspace.ps1`
2. **Scaffold new project** — `new-project.ps1`
3. **Generate project map only** — `generate-project-map.ps1`
4. **Generate CI only** — `generate-ci.ps1`
5. **Diagnose project** — `doctor.ps1 -ProjectPath <path>`
6. **Rollback changes** — `rollback-ai-workspace.ps1`
7. **Validate workspace** — `validate-workspace.ps1`

---

## How to Respond After Changes

After completing any change to this repository, provide:

```
## Changes Made
- [file or script]: [what changed and why]

## Commands Run
- [command]: [summary of output]

## Validation Results
- validate-workspace.ps1: [PASS / WARN / FAIL]
- doctor.ps1: [PASS / WARN / FAIL]

## Risks
- [any risk, known limitation, or follow-up needed]

## Next Steps
- [exact commands the human should run next]
```

---

## Agent Role Summary

| What you need | Use this |
|---|---|
| Understand a project | `detect-project.ps1`, `generate-project-map.ps1` |
| Set up CI | `generate-ci.ps1` |
| Apply all templates | `apply-ai-workspace.ps1` |
| Check workspace health | `doctor.ps1`, `validate-workspace.ps1` |
| Undo changes | `rollback-ai-workspace.ps1` |
| Create new project | `new-project.ps1` |
| Find prompt templates | `templates/prompts/` |
| Find doc templates | `templates/project-docs/` |
