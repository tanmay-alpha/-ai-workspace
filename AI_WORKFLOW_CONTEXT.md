# AI Workflow Context

## Purpose

This repository provides a reusable AI-assisted software development workflow.

The goal is to organize:

- AI coding workflows
- CI/CD templates
- security workflows
- prompt playbooks
- MCP usage patterns
- reusable project templates
- local development tooling

into a single reusable engineering system.

This repository is intended to work across many project types rather than a single codebase.

---

# Core Workflow Philosophy

Use the right tool for the right task.

Different AI systems perform better at different kinds of work:

- large-context analysis
- implementation
- debugging
- documentation lookup
- filesystem tooling
- automation
- local/offline coding

The workflow separates these responsibilities to reduce confusion, improve reliability, and reduce system overload.

---

# AI Agent Roles

## Planning / Architecture Assistant

Recommended for:

- architecture review
- debugging strategy
- planning
- workflow design
- prompt engineering
- code review discussion

Avoid using for:

- large autonomous repo rewrites
- uncontrolled code generation

---

## Large-Context CLI Assistant

Recommended for:

- repository-wide analysis
- long logs
- architecture review
- identifying technical debt
- planning refactors

Best used before implementation work begins.

---

## Coding Agent

Recommended for:

- implementation
- bug fixing
- refactoring
- writing tests
- terminal workflows
- safe incremental changes

Preferred workflow:

1. inspect code first
2. explain plan
3. make minimal changes
4. validate
5. summarize changes

---

## IDE Coding Assistant

Recommended for:

- quick editor tasks
- autocomplete
- small fixes
- rapid iteration

Avoid relying on IDE autocomplete for architecture decisions.

---

## MCP / Tool Agent

Recommended for workflows involving:

- filesystem access
- GitHub operations
- documentation lookup
- web research
- scraping
- tool orchestration
- git-aware workflows

Use only the MCP tools needed for the current task.

Avoid enabling unnecessary tools.

---

## Local Models

Recommended for:

- offline work
- low-cost fallback usage
- experimentation
- lightweight coding support

Local models should not replace validation, testing, or architecture review.

---

# Recommended Tool Usage

## Analysis Workflow

Use:

- large-context analysis assistant
- repository analysis prompts
- architecture review prompts

Avoid editing code during analysis-only sessions.

---

## Implementation Workflow

Use:

- coding agent
- IDE assistant
- terminal workflows
- incremental commits

Implementation sessions should stay focused on a small number of related tasks.

---

## Documentation Workflow

Use:

- MCP/documentation tools
- official docs
- repository notes
- reusable prompt templates

Avoid relying entirely on memory for framework/library behavior.

---

## Security Workflow

Always:

- ignore `.env`
- use `.env.example`
- scan for secrets
- validate commits before pushing

Never:

- commit credentials
- expose tokens
- expose API keys
- expose private certificates
- expose production secrets

---

# MCP Usage Strategy

MCP tools should be activated selectively.

Recommended pattern:

## Frontend Projects

Use:

- filesystem
- github
- documentation lookup
- fetch
- browser/testing tools only when required

---

## Backend Projects

Use:

- filesystem
- github
- documentation lookup
- git-aware tools
- structured reasoning tools when needed

---

## Research / Exploration Projects

Use:

- filesystem
- fetch
- scraping/research tools
- memory tools
- documentation tools

---

## Automation Projects

Use:

- filesystem
- fetch
- github
- automation platforms manually when needed

---

# CI/CD Principles

Every project should ideally include:

- automated validation
- dependency installation
- test execution
- linting/formatting where appropriate
- secret scanning

Workflow templates should remain:

- reusable
- minimal
- understandable
- easy to adapt

Avoid over-engineering CI pipelines early.

---

# Repository Template Philosophy

This repository stores reusable templates for:

- GitHub Actions
- `.gitignore`
- prompts
- workflow docs
- scripts
- MCP guidance
- coding challenge authoring

Templates are intended to accelerate project setup while maintaining consistency.

---

# Verifiable Coding Challenge Creation

Coding challenge templates should help convert public open-source repository
tasks into deterministic, reviewable exercises.

Recommended workflow:

1. select a suitable public repository
2. pin an immutable commit hash
3. describe expected behavior without prescribing the implementation
4. add deterministic tests that fail before the solution and pass after it
5. create a minimal reference solution patch
6. validate the environment with reproducible Docker or local commands
7. review final diffs for secrets, private context, and unrelated changes

Keep challenge materials generic, public-friendly, and platform-neutral.

---

# RAM And System Stability Rules

Use only one heavy AI workflow at a time.

Running multiple systems simultaneously can cause:

- high RAM usage
- thermal throttling
- CPU overload
- editor lag
- reduced productivity
- context confusion

Heavy workloads may include:

- large-context AI analysis
- local models
- browser automation
- automation servers
- large editor sessions

---

# Recommended Daily Workflow

## Start Of Session

1. open project
2. check git status
3. stop unnecessary tools
4. determine task scope

---

## Analysis Phase

Use analysis tools to:

- inspect architecture
- identify issues
- define implementation plan

Avoid editing during pure analysis sessions.

---

## Implementation Phase

1. make small focused changes
2. validate locally
3. inspect git diff
4. run secret scan
5. commit incrementally

---

## Validation Phase

Before pushing:

- run tests
- review changed files
- inspect secrets
- confirm workflow status

---

## End Of Session

- stop unnecessary background tools
- verify clean git state
- summarize pending tasks

---

# Repository Usage Pattern

Typical workflow:

1. create or open a project
2. copy required templates
3. configure CI/CD
4. configure secret scanning
5. apply appropriate `.gitignore`
6. use prompt playbooks for analysis/implementation
7. validate locally
8. commit and push

The workflow is intentionally modular.

Projects should adopt only the components they actually need.

---

# Security Principles

Prefer:

- reusable safe templates
- example environment files
- minimal permissions
- incremental validation

Avoid:

- storing secrets in repositories
- exposing machine-specific sensitive data
- committing generated credentials
- enabling unnecessary tooling

---

# Long-Term Goal

Create a reusable, stable, AI-assisted development workflow that can support multiple project types while remaining:

- modular
- understandable
- lightweight
- secure
- adaptable
- automation-friendly
