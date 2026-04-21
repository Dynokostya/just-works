# Tech Stack

## Languages

- Node.js >=18 — CLI installer runtime (`package.json:5, 30-32`)
- Python >=3.11 — eval subproject (`src/evals/pyproject.toml:5`)
- Bash — installer and statusline scripts (`install.sh:1`, `.claude/statusline-command.sh:1`)
- Windows Batch — Windows installer (`install.bat:1`)
- Markdown — agent, skill, and command definitions
- TOML — Codex config and agent definitions (`.codex/config.toml`, `.codex/agents/*.toml`)

## Frameworks

- Claude Code — Anthropic CLI target harness (`.claude/`)
- OpenAI Codex — GPT CLI target harness (`.codex/`)

## Infrastructure

- Playwright MCP — browser automation MCP server (`.mcp.json:3-6`, `.codex/config.toml:25-27`)
- OpenRouter — eval-suite API provider (`src/evals/client.py:16`)
- Azure OpenAI — optional Codex provider variant (`.codex/config/azure/config.toml`)

## Dev Tools

- uv — Python package manager and lockfile (`src/evals/uv.lock`)
- pytest — Python test runner (`src/evals/pyproject.toml:7, 12-18`)
- httpx — HTTP client for OpenRouter (`src/evals/client.py:10`)
- python-dotenv — env loader (`src/evals/client.py:11`)
- npx — MCP server and CLI execution (`.mcp.json:4`, `package.json:6-7`)
- jq — statusline JSON parsing (`.claude/statusline-command.sh`)

---
*Generated: 2026-04-21 | Commit: 2dc99fd*
