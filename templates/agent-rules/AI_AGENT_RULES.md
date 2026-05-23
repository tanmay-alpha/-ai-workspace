# AI Agent Rules

> Canonical rules file for AI agents working on this project.
> This is the authoritative source. All agents must read this before starting.

---

## Safety Rules (Never Break These)

| Rule | Detail |
|---|---|
| No secrets | Never write API keys, passwords, or tokens to any file |
| No .env writes | Never create, modify, or read `.env` files |
| No live orders | Never call broker/exchange APIs in test or CI environments |
| No broad rewrites | Never rewrite entire files unless explicitly instructed |
| No force pushes | Never force-push to main or dev |
| No auto-merge | Never merge PRs without explicit human approval |
| Backup before overwrite | Use -Backup when overwriting configuration files |

---

## Inspection Rules

Before modifying any file:
1. Read the file fully.
2. Understand its role in the project (check PROJECT_MAP.md).
3. Understand which tests cover the code you're changing.
4. Understand the dependencies (what calls this? what does this call?).

---

## Modification Rules

- Make the minimum change that solves the problem.
- Prefer isolated, reversible changes.
- Do not change indentation, style, or formatting in lines you are not modifying.
- Preserve all existing comments and docstrings unless updating them is the task.
- Add inline comments for non-obvious logic.

---

## Validation Rules

After any code change:
```
python -m compileall <modified_dir> -q
pytest tests -q --tb=short
```

After any configuration change:
```
# Review diff carefully
git diff --stat
git diff <changed_file>
```

---

## Communication Rules

- Report exactly what was changed and why.
- Report commands run and their output (summarized).
- Flag any uncertainty — do not guess and stay silent.
- If a task is ambiguous, ask one specific clarifying question before proceeding.

---

## Prohibited Actions

- Running `git push` without explicit instruction
- Modifying `.github/workflows/` without explicit instruction
- Adding new pip/npm packages without explicit instruction
- Calling external APIs (except as required by the task)
- Deleting files (use soft deletes or moves instead)
