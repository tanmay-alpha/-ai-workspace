# AGENTS.md — AI Agent Rules for This Project

> This file defines how AI coding agents should behave in this repository.
> Read this file before making any changes.

---

## Project Context

This project uses AI coding agents (Codex, Gemini, Claude, Antigravity, Cline, etc.)
for implementation, review, and analysis. This file establishes the rules all agents must follow.

---

## Non-Negotiable Rules

1. **Never touch `.env` files.** Never read, write, or reference real credentials.
2. **Never commit secrets.** No API keys, tokens, or passwords in any file.
3. **Never place real orders.** If this is a trading project, `TRADING_MODE` must be `PAPER` in all non-production code.
4. **Never overwrite files** without explicitly being told to do so or using `-Force`.
5. **Never run destructive commands** (database drops, bulk deletes) without explicit approval.
6. **Always prefer dry-run** when a script supports it. Show the plan before executing.
7. **Always validate after changes.** Run tests, lint, and compile checks.

---

## Required Workflow

Before making changes:
1. Read `PROJECT_MAP.md` to understand the project structure.
2. Read relevant source files — do not guess structure.
3. Understand the detected project type and tech stack.
4. Confirm scope: what files are in scope, what are out of scope.

After making changes:
1. Run: `python -m compileall . -q` (Python projects)
2. Run: `pytest tests -q` (if tests exist)
3. Run: `npm run build` (Node projects)
4. Report all files created, modified, or deleted.
5. Note any risks or follow-up actions required.

---

## Scope Limits

- Only modify files explicitly mentioned in the task.
- Do not refactor unrelated files even if they look messy.
- Do not add new dependencies without explicit approval.
- Do not change CI/CD configuration unless the task is specifically about CI/CD.

---

## Response Format

After completing a task, provide:

```
## Changes Made
- [file]: [what changed and why]

## Commands Run
- [command]: [output summary]

## Risks
- [any risk or follow-up needed]

## Next Steps
- [what the human should do next]
```

---

## Agent-Specific Notes

| Agent | Preferred Use |
|---|---|
| Codex | Code implementation, refactoring, test writing |
| Gemini / Antigravity | Repo analysis, large file review, browser testing |
| Claude | Architecture, planning, documentation |
| Cline | Local orchestration, multi-step workflows |
| Ollama | Offline fallback for simple tasks |
