# Shipd Challenge Authoring Workflow

> How to use ai-workspace to create verifiable coding challenges.

---

## Overview

A coding challenge consists of:
1. A real or realistic codebase with a specific problem
2. A problem description that describes the task without spoiling the solution
3. Deterministic tests that fail on the broken code and pass on the fix
4. A reference solution (a minimal patch)
5. A Docker environment that runs the tests consistently

ai-workspace provides templates and prompt playbooks to guide this entire workflow.

---

## Step 1: Repository Selection

Use `templates/challenge-authoring/repository-selection-checklist.md`.

Good challenge repositories:
- Have clear, readable code
- Have a real, testable bug or missing feature
- Do not require external credentials to test
- Can be solved in 30 minutes to 2 hours

---

## Step 2: Detect and Analyze

```powershell
# Generate a project map of the candidate repo
powershell -ExecutionPolicy Bypass -File scripts\generate-project-map.ps1 `
  -ProjectPath "C:\path\to\candidate-repo"

# Detect project type
powershell -ExecutionPolicy Bypass -File scripts\detect-project.ps1 `
  -ProjectPath "C:\path\to\candidate-repo"
```

Read the generated PROJECT_MAP.md to understand the codebase structure.

---

## Step 3: Identify the Challenge

Use the `templates/prompts/shipd-challenge-authoring.md` prompt with an AI agent:

```
Read PROJECT_MAP.md for the repository at [PATH].
Identify 3-5 candidate challenges that:
- Can be solved in 30-90 minutes
- Have deterministic, testable solutions
- Do not require external APIs or credentials
- Require real code understanding (not just config changes)
```

---

## Step 4: Write the Problem Description

Use `templates/challenge-authoring/problem-description-template.md`.

Key rules:
- Describe the system context without spoiling the fix
- Be specific about what the solver must implement or fix
- Include clear acceptance criteria
- Provide example inputs and expected outputs

---

## Step 5: Write Deterministic Tests

Use `templates/challenge-authoring/test-design-template.md`.

Test requirements:
- Tests MUST fail on the unmodified repository
- Tests MUST pass with the correct solution
- Tests MUST NOT require network access
- Tests MUST NOT require environment variables with real values
- Tests MUST complete in under 30 seconds

Verify:
```bash
# Should fail (before fix)
pytest tests/ -v

# Apply reference solution
git apply solution.patch

# Should pass (after fix)
pytest tests/ -v
```

---

## Step 6: Write the Reference Solution

Use `templates/challenge-authoring/solution-patch-checklist.md`.

- Use `git diff` to generate the patch
- The patch should be minimal — only what is necessary
- Document WHY the fix is correct (a few sentences)

---

## Step 7: Create the Docker Environment

Use `templates/challenge-authoring/dockerfile-template.md`.

The Dockerfile must:
- Use a specific, pinned base image (not `latest`)
- Install all dependencies without network access (if possible)
- Run the test suite as the default command

---

## Step 8: Sanitize and Validate

Use `templates/challenge-authoring/submission-checklist.md`.

Before publishing:
- [ ] Remove all private user data from the codebase
- [ ] Remove all credentials and API keys
- [ ] Verify tests pass in a clean Docker build
- [ ] Verify the solution patch applies cleanly
- [ ] Pin the challenge to a specific commit hash

---

## Prompt Templates Available

- `templates/prompts/shipd-challenge-authoring.md` — full challenge authoring prompt
- `templates/prompts/repo-audit.md` — understanding a new codebase
- `templates/prompts/test-improvement.md` — writing better tests
- `templates/prompts/security-audit.md` — checking for issues to turn into challenges

---

## Example Challenge Types by Project Type

| Project Type | Challenge Ideas |
|---|---|
| python-backend | Fix a broken API endpoint / Add input validation / Fix authentication logic |
| node-frontend | Fix a React component bug / Add form validation / Fix async race condition |
| ml-project | Fix data leakage in preprocessing / Fix model serialization / Add reproducibility |
| trading-system | Fix a risk calculation / Add a circuit breaker / Fix order quantity validation |
| agentic-ai | Fix a tool call error / Add retry logic / Fix prompt injection vulnerability |
