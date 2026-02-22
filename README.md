# just-works

A drop-in scaffold of AI agent workflows, coding skills, and prompt engineering standards for projects using **Claude Code** and **OpenAI Codex**.

Copy the `.claude/` and `.codex/` directories into any project to get pre-configured agents, quality guardrails, and documentation pipelines — no setup from scratch.

## What's Included

### Agents

| Agent | Provider | Purpose |
|-------|----------|---------|
| `python-code-writer` | Claude Code | Write and edit Python files with automatic ruff/mypy quality checks |
| `prompt-writer` | Claude Code | Create LLM prompts and Jinja2 templates with model-specific standards |
| `plan-reviewer` | Codex | Review implementation plans for over-engineering and unnecessary complexity |
| `project-docs` | Both | 5-phase documentation generation pipeline with evidence-based citations |

### Skills (coding & prompting standards)

| Skill | Covers |
|-------|--------|
| `python-coding` | Error handling, async patterns, type safety, security defaults, 25 "never rules" |
| `claude-opus-4-6-prompting` | Adaptive thinking, XML tags, behavioral tuning, overtriggering mitigation |
| `gpt-5-2-prompting` | Verbosity control, reasoning effort, long-context handling, structured extraction |
| `gemini-3-prompting` | Three-layer prompts, context-first pattern, thinking levels, persona conflicts |

### Security defaults

The included `settings.json` blocks agent access to sensitive files: `.env`, `*.pem`, `*.key`, credentials, AWS/GCP/Azure configs, SSH keys, Terraform state, and databases.

## Installation

```bash
git clone https://github.com/dynokostya/just-works.git
cd just-works
```

**macOS / Linux:**
```bash
./install.sh
```

**Windows:**
```cmd
install.bat
```

This installs agents, skills, commands, and settings globally to `~/.claude/` and `~/.codex/`.

### Options

| Flag | Effect |
|------|--------|
| `--personal` | Install opinionated settings (pre-approved Bash commands, notification sounds, file size hooks) instead of minimal defaults |
| `--claude-only` | Install only Claude Code files |
| `--codex-only` | Install only Codex files |
| `--dry-run` | Preview what would be installed without making changes |

```bash
# Preview first
./install.sh --dry-run          # or: install.bat --dry-run

# Install with opinionated settings
./install.sh --personal          # or: install.bat --personal

# Only Claude Code
./install.sh --claude-only       # or: install.bat --claude-only
```

Existing files are backed up automatically with a `.bak` timestamp before overwriting.

### Codex Azure setup (additional step)

Copy and edit the Azure OpenAI config:

```bash
cp .codex/config/azure/config.toml ~/.codex/config.toml
```

Edit `~/.codex/config.toml` — replace `<your-resource-name>` with your Azure OpenAI resource name and set your API key:

```bash
export AZURE_OPENAI_API_KEY="your-key-here"
```

### MCP Servers

Both providers are pre-configured to use:

- **Context7** — up-to-date library documentation retrieval (no more stale API knowledge)
- **Playwright** — browser automation and testing

Requires `npx` (Node.js) available in your PATH.

> **Want to set up MCP in your project?** Copy `.mcp.json.default` into your project root as `.mcp.json` (not global). Context7 is strongly recommended — it keeps library documentation up to date so your agents don't hallucinate stale APIs.
>
> ```bash
> cp .mcp.json.default /path/to/your/project/.mcp.json
> ```

## Project Structure

```
.claude/
  agents/           # Claude Code agent definitions
  skills/           # Coding and prompting standards
  commands/         # Multi-step workflows (project-docs)
  settings.json     # Permissions, hooks, MCP servers
.codex/
  prompts/          # Codex agent definitions
  skills/           # Same standards, mirrored for Codex
  config/azure/     # Azure OpenAI configuration template
docs/
  architecture.md   # How the scaffold is organized
  mission.md        # What this project is and who it's for
  tech-stack.md     # Languages, frameworks, and tools
CLAUDE.md           # Root behavioral instructions for Claude Code
AGENTS.md           # Root behavioral instructions for Codex
```

`.claude/` and `.codex/` are parallel and independent — use one or both, zero cross-dependency.

## Customization

- **Add project-specific agents** in `.claude/agents/` or `.codex/prompts/`
- **Override skill defaults** with project conventions in your own `CLAUDE.md` or `AGENTS.md`
- **Extend the deny-list** in `.claude/settings.json` for additional sensitive file patterns
- **Add hooks** for custom pre/post-tool validations

### Forking / modifying this project

If you want to create a custom version, keep two things in mind:

1. **Duplicate skills across both providers.** Skills in `.claude/skills/` must be mirrored to `.codex/skills/`. Codex does not support `@file` references, so each provider needs its own copy.
2. **Use model-agnostic instructions.** When writing agents, skills, or commands, avoid Claude-specific or GPT-specific phrasing. Keep instructions generic so they work across both providers.

## License

Apache 2.0
