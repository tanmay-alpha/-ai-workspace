# Prompt: Security Audit

> Paste this prompt to perform a security review of a project.

---

## Task

Perform a security audit of the repository at: `[PROJECT_PATH]`

Read `PROJECT_MAP.md` and `AI_WORKFLOW_CONTEXT.md` first.

## Audit Checklist

### Credential and Secret Safety
- [ ] Search all files for patterns: `api_key`, `secret_key`, `password`, `token`, `AWS_ACCESS_KEY`, `private_key`
- [ ] Verify `.env` is in `.gitignore`
- [ ] Verify no `.env` files are git-tracked: `git ls-files | grep -i .env`
- [ ] Check git history for accidentally committed secrets: `git log --all -p | grep -i "api_key\|password\|secret"`

### Input Validation
- [ ] Are all external inputs (HTTP params, file uploads, form fields) validated server-side?
- [ ] Are SQL queries parameterized? Search for string formatting in query strings.
- [ ] Is file upload type and size validated?

### Authentication and Authorization
- [ ] Are authentication tokens validated on every protected endpoint?
- [ ] Are authorization checks present (not just authentication)?
- [ ] Are there any admin routes not protected by auth?

### Dependency Security
- [ ] Run `pip audit` (Python) or `npm audit` (Node)
- [ ] Identify any `HIGH` or `CRITICAL` severity findings
- [ ] Check if packages are pinned to specific versions

### CI/CD Security
- [ ] Does CI require secrets not available to PRs from forks?
- [ ] Are environment variables masked in logs?
- [ ] Are CI steps minimal and principle-of-least-privilege?

### Trading / Financial (if applicable)
- [ ] Is `TRADING_MODE=PAPER` the default?
- [ ] Are live broker credentials absent from CI?
- [ ] Are risk limits validated before order submission?

## Output Format

1. **Critical Findings** — must fix immediately
2. **High Severity** — fix before production
3. **Medium Severity** — fix before next release
4. **Low Severity / Hardening** — schedule for backlog
5. **Recommended Commands** to fix or verify each finding

Do NOT make changes. This is a read-only audit.
