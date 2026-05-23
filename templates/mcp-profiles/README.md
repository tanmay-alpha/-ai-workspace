# MCP Profiles

This folder contains suggested MCP/tool combinations for different development workflows.

The goal is to avoid enabling unnecessary tools while still providing enough capability for the current task.

---

# Frontend Project Profile

Recommended tools:

- filesystem
- github
- fetch
- browser automation/testing
- documentation lookup

Use for:

- React
- Next.js
- Vite
- static websites
- UI debugging

Avoid enabling backend-heavy tooling unless required.

---

# Backend Project Profile

Recommended tools:

- filesystem
- github
- documentation lookup
- terminal tooling
- git-aware tooling

Use for:

- Python APIs
- FastAPI
- Node backends
- automation services
- database services

Focus on architecture, testing, and debugging workflows.

---

# Fullstack Project Profile

Recommended tools:

- filesystem
- github
- frontend tooling
- backend tooling
- documentation lookup

Use for projects containing:

- frontend + backend
- API + UI
- dashboards
- admin panels
- SaaS systems

---

# Research / Exploration Profile

Recommended tools:

- filesystem
- fetch
- scraping/research tools
- documentation lookup

Use for:

- research projects
- experimentation
- AI/ML workflows
- prototype systems

---

# Security Notes

Only enable the MCP tools required for the current task.

Avoid:

- unnecessary browser automation
- excessive filesystem access
- exposing secrets to tools
- overlapping heavy tooling

---

# Recommended Workflow

1. Select project type
2. Enable minimum required tools
3. Perform analysis
4. Implement incrementally
5. Validate changes
6. Run secret checks
7. Commit safely
