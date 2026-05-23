# Prompt: Backend Debug

> Paste this prompt when debugging a backend issue.

---

## Task

You are debugging a backend issue in: `[PROJECT_PATH]`

**Error / Symptom:** `[Paste the error message or describe the symptom]`

**Environment:** `[local / staging / CI]`

**Last working commit (if known):** `[commit hash]`

## Debug Approach

Follow this order:
1. **Read the full error message** — do not skip the stack trace.
2. **Identify the file and line number** where the error originates.
3. **Read that file** and the files it imports.
4. **Check recent git changes** to that file: `git log -p --follow <file>`
5. **Check environment variables** — are required vars set? (Do NOT log secrets)
6. **Check dependency compatibility** — was anything recently updated?

## Rules

- Do NOT make changes without explaining what you plan to do first.
- Do NOT restart services unless explicitly asked.
- Do NOT modify `.env` files.
- If the issue is unclear, ask one specific clarifying question.

## Output Format

1. **Root Cause** (what is the actual cause?)
2. **Affected Files** (list files involved)
3. **Fix** (exact code change with diff format)
4. **Tests to Verify** (how to confirm the fix works)
5. **Preventative Note** (how to avoid this in the future)
