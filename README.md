# just-works

Drop-in AI agent workflows, coding skills, and prompt standards for **Claude Code** and **OpenAI Codex**.

Just copy `.claude/` into any project — or install globally — and get pre-configured agents, quality guardrails, and documentation pipelines out of the box.

**`.codex/` works only if you install it globally (only skills folder works per-project).**

## What's Inside

**Agents** — `python-code-writer`, `prompt-writer` (Claude).
**Commands** - `plan-reviewer` (Codex), `project-docs` (Claude & Codex).

**Skills** — coding standards (Python, React, Tailwind, shadcn/ui), architecture patterns (DDD, feature-driven), and model-specific prompt engineering (Claude Opus 4.6, GPT-5.2, Gemini 3). Applied automatically based on the file type you're editing.

**Security** — `settings.json` blocks agent access to `.env`, `*.pem`, `*.key`, credentials, cloud configs, SSH keys, Terraform state, and databases.

## Installation

```bash
git clone https://github.com/dynokostya/just-works.git
cd just-works
./install.sh            # macOS / Linux
install.bat             # Windows
```

Installs agents, skills, commands, and settings globally to `~/.claude/` and `~/.codex/`. Existing files get backed up automatically.

### Options

```bash
./install.sh --dry-run          # preview without changes
./install.sh --personal         # opinionated settings (pre-approved commands, hooks, sounds)
./install.sh --claude-only      # skip Codex
./install.sh --codex-only       # skip Claude
```

### Codex Azure config

Default install copies `config.toml.default` → `~/.codex/config.toml` (minimal model config).
Personal (my) install copies `config.toml` → `~/.codex/config.toml` (includes MCP servers).

Either way, edit the file — replace `<your-resource-name>` with your Azure OpenAI resource and set your environment variable:

```bash
export AZURE_OPENAI_API_KEY="your-key-here"
```

### MCP for Claude Code

MCP servers are configured per-project, not globally. To set up MCP in your project:

```bash
cp .mcp.json.default /path/to/your/project/.mcp.json
```
OR
```bash
cp .mcp.json /path/to/your/project/.mcp.json
```

Requires `npx` (Node.js) in your PATH.

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
  config/azure/     # config.toml.default + config.toml
CLAUDE.md           # Behavioral instructions for Claude Code
AGENTS.md           # Behavioral instructions for Codex
```

`.claude/` and `.codex/` are parallel and independent — use one or both.

## Customization

Add project-specific agents in `.claude/agents/` or `.codex/prompts/`. Override skill defaults in your own `CLAUDE.md` or `AGENTS.md`. Extend the deny-list in `.claude/settings.json`.

If you fork this: skills must be mirrored across both providers (Codex doesn't support `@file` references). Keep instructions model-agnostic.

## License

Apache 2.0
