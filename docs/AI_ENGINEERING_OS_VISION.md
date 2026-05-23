# AI Engineering OS — Vision

> The larger vision behind ai-workspace.

---

## What Is an AI Engineering OS?

An AI Engineering OS is not a single tool. It is a **system of systems** — a set of conventions, scripts, templates, and agent rules that makes every project you touch:

- **Discoverable** — any AI agent can understand the project structure in seconds
- **Safe** — no secrets leaked, no destructive defaults, no surprises
- **Consistent** — the same quality standards applied regardless of project type
- **Onboardable** — a new developer or AI agent can be productive within minutes
- **Auditable** — every change is traceable, every risk is documented

ai-workspace is the foundation of that system.

---

## The Core Problem

Modern engineering with AI agents is powerful but chaotic:
- AI agents make assumptions about project structure
- Different projects have wildly different layouts
- CI pipelines are copy-pasted and then forgotten
- Security context is implicit, not explicit
- There is no standard "handoff" between humans and AI agents

This leads to:
- AI agents editing the wrong files
- CI failing because of missing environment variables
- Secrets accidentally committed
- Teams rebuilding the same boilerplate for every project

---

## The Solution: Universal Context

ai-workspace solves this by providing:

### 1. Project Detection
`detect-project.ps1` analyzes any repository and produces a structured understanding of:
- Project type and tech stack
- Backend and frontend paths
- Dependency files and test commands
- Risk indicators (trading, agentic AI, ML, credentials)

### 2. Standardized Context Files
`PROJECT_MAP.md` and `AGENTS.md` give every AI agent a shared, reliable starting point.
No more "please read the README and figure it out."

### 3. Safe CI Generation
`generate-ci.ps1` creates CI workflows that are:
- Tailored to the detected project type
- Safe by default (PAPER trading mode, no live credentials)
- Immediately runnable without configuration

### 4. Structured Templates
Templates for ADRs, PRDs, roadmaps, issue trackers, and security checklists ensure
that every project has professional-grade documentation from day one.

### 5. Agent Rules
`AGENTS.md` and `AI_AGENT_RULES.md` establish explicit contracts with AI agents:
what they can do, what they cannot do, and how to behave.

---

## The Engineering Disciplines It Enables

| Discipline | How ai-workspace helps |
|---|---|
| **Safe agentic coding** | Agent rules, dry-run, backup, rollback |
| **Project context management** | PROJECT_MAP.md, detect-project |
| **CI/Security readiness** | CI generation, secret scan, security checklist |
| **Challenge authoring** | Templates for problem, tests, solution, Dockerfile |
| **Startup-grade discipline** | PRD, ADR, roadmap, production readiness |

---

## The 10-Year Vision

A developer clones ai-workspace once. For every project they ever work on:

1. One command generates full project understanding
2. AI agents are immediately productive with zero hand-holding
3. Security is enforced by default, not as an afterthought
4. Documentation is generated, not written from scratch
5. CI is tailored, not copied from Stack Overflow

This is not science fiction. It is achievable today with the right conventions.

---

## Principles

1. **Inspect before editing** — understand before changing
2. **Explicit over implicit** — state rules, state constraints, state risks
3. **Reversible by default** — backup, rollback, dry-run everywhere
4. **Public-safe always** — no names, no paths, no secrets
5. **One command is better than ten** — complexity lives in scripts, not in user heads
