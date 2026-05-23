# Security Model

> How ai-workspace enforces security by design.

---

## Core Security Principles

### 1. No Secrets — Ever

ai-workspace contains **zero real credentials** of any kind.

- No API keys
- No broker credentials
- No database passwords
- No private tokens
- No personal access tokens

All templates use generic placeholder values. Any script that touches credentials
in a target project does so read-only and only to check for risks.

### 2. No `.env` Tracking

ai-workspace will never:
- Read the contents of `.env` files
- Write to `.env` files
- Commit `.env` files
- Copy `.env` files

`doctor.ps1` and `validate-workspace.ps1` actively check that `.env` is NOT tracked by git.
If `.env` is found to be git-tracked in a target project, it raises a FAIL.

### 3. No Live Trading Actions

For trading and financial projects:
- All CI workflows set `TRADING_MODE=PAPER` and `APP_ENV=test`
- CI never has access to live broker API keys
- The safety audit prompt (`trading-system-safety-audit.md`) checks for this explicitly
- `detect-project.ps1` flags trading keywords as a risk note

### 4. No Destructive Defaults

- Scripts never overwrite files without `-Force`
- Scripts support `-Backup` to create backups before overwriting
- Scripts support `-DryRun` to preview actions without executing
- `rollback-ai-workspace.ps1` can undo any applied changes
- Backups are never auto-deleted

### 5. No Broad Rewrites

- Scripts only copy templates and generate files in clearly defined locations
- They never modify source code in target projects
- They never run `git push` or any remote operations
- All changes are local and require explicit `git commit` by the user

---

## Validation and Scanning

### Workspace Self-Validation

```powershell
powershell -ExecutionPolicy Bypass -File scripts\validate-workspace.ps1
```

Checks:
- No forbidden private words in public files
- No `.env` in workspace root
- All CI templates have valid structure
- All required scripts and docs exist
- `detect-project.ps1` runs without error

### Project Audit

```powershell
powershell -ExecutionPolicy Bypass -File scripts\doctor.ps1 -ProjectPath <path>
```

Checks:
- `.env` is not git-tracked in the target project
- No risky folders (`node_modules`, `venv`) are git-tracked
- CI workflows exist

### Secret Scanning Workflow

`templates/github-actions/security/secret-scan.yml` uses [Gitleaks](https://github.com/gitleaks/gitleaks)
to scan every push and PR for secrets. This is automatically applied to target projects
when `apply-ai-workspace.ps1` is run with `-IncludeSecretScan`.

---

## Rollback and Recovery

If ai-workspace scripts modify a project in an unwanted way:

```powershell
# List available backups
powershell -ExecutionPolicy Bypass -File scripts\rollback-ai-workspace.ps1 `
  -ProjectPath <path> -List

# Restore from backup
powershell -ExecutionPolicy Bypass -File scripts\rollback-ai-workspace.ps1 `
  -ProjectPath <path> -BackupName <timestamp>
```

Backups are stored in `.ai-workspace-backup/<timestamp>/` inside the target project.

---

## Public Safety

This repository is designed to be fully public:
- No personal names, email addresses, or usernames in templates
- No hardcoded paths specific to any machine
- No internal project names or company references
- `validate-workspace.ps1` checks for forbidden words before any release
