# Supported Project Types

> How ai-workspace detects and handles each project type.

---

## Detection Overview

`detect-project.ps1` analyzes a project directory and classifies it into one of the following types.
Detection uses file presence and keyword search — no execution required.

---

## Project Types

### `python-backend`

**Detected when:**
- `requirements.txt`, `pyproject.toml`, or `setup.py` exists at root or in `backend/`
- No frontend indicators (no `package.json`)
- No ML/trading/agentic keywords dominant

**CI behavior:**
- Install Python dependencies
- Run `python -m compileall` on backend directory
- Run `pytest` if a `tests/` directory exists
- Set `TRADING_MODE=PAPER`, `APP_ENV=test`

**Example projects:** REST APIs, CLI tools, automation scripts, web scrapers

---

### `node-frontend`

**Detected when:**
- `package.json` exists at root, `frontend/`, or `client/`
- No Python dependency files

**CI behavior:**
- Detect npm / pnpm / yarn from lockfiles
- Run install command
- Run build if `build` script exists
- Run test if a meaningful `test` script exists

**Example projects:** React, Next.js, Vite, Vue apps

---

### `fullstack`

**Detected when:**
- Both Python and Node indicators are present
- `backend/` has Python files AND `frontend/` has `package.json` (or similar)

**CI behavior:**
- Separate `python-backend` and `node-frontend` jobs
- Both jobs run in parallel

**Example projects:** FastAPI + React, Django + Next.js, Flask + Vue

---

### `static-website`

**Detected when:**
- `index.html` exists at root
- No Python or Node dependency files

**CI behavior:**
- Verify `index.html` exists
- List HTML files

**Example projects:** HTML/CSS/JS landing pages, GitHub Pages sites

---

### `ml-project`

**Detected when:**
- Python is present AND ML keywords found (`sklearn`, `torch`, `tensorflow`, `pandas`, `notebook`, `model`, `training`)
- OR `.ipynb` files are present

**CI behavior:**
- Python install + compileall + tests (if any)
- Does NOT run model training in CI
- Tests verify imports and data pipeline logic only

**Example projects:** Scikit-learn classifiers, PyTorch models, data pipelines, Jupyter notebooks

---

### `data-science`

**Detected when:**
- ML keywords found but without strong Python project structure
- Notebooks without requirements files

**CI preset:** `ml-project`

**Example projects:** Exploratory notebooks, data analysis scripts

---

### `trading-system`

**Detected when:**
- Python is present AND trading keywords found (`broker`, `order`, `market`, `candle`, `risk`, `portfolio`, `strategy`, `alpaca`, `backtesting`)
- Takes priority over ml-project

**CI behavior:**
- Python job with `TRADING_MODE=PAPER` enforced
- No broker credentials in CI
- Order-placing code is never executed

**Example projects:** Algo trading bots, backtesting frameworks, paper trading systems

---

### `agentic-ai`

**Detected when:**
- Python is present AND agentic keywords found (`langchain`, `crewai`, `autogen`, `openai`, `anthropic`, `llm`, `agent`, `mcp`, `rag`)
- Takes priority over python-backend

**CI behavior:**
- Python job with no live API keys
- External API calls must be mocked in tests
- Agent tools verified through unit tests only

**Example projects:** LangChain agents, CrewAI crews, custom LLM pipelines, MCP servers

---

### `unknown`

**Detected when:**
- No recognizable indicators found

**CI behavior:**
- Attempts Python checks if Python is detected
- Falls back to a basic check with informative output

---

## Overriding Auto-Detection

All scripts support a `-Preset` parameter:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\apply-ai-workspace.ps1 `
  -ProjectPath C:\MyProject `
  -Preset trading-system  # Force a specific preset
```

---

## Detection JSON Output

```powershell
powershell -ExecutionPolicy Bypass -File scripts\detect-project.ps1 `
  -ProjectPath C:\MyProject -Json
```

Returns a JSON object with all detected properties. Useful for scripting and automation.
