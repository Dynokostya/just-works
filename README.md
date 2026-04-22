# just-works

I am tired of manually prompting Claude Code each time to include all tools, best practices, aggressive language — that's why I created this repo.

Drop-in AI agent workflows, coding skills, and prompt standards for **Claude Code** and **OpenAI Codex**.

Just copy `.claude/` into any project — or install globally — and get pre-configured agents, quality guardrails, and documentation pipelines out of the box.

**`.codex/` works only if you install it globally (only skills folder works per-project).**

## What's Inside

**Agents** — `python-code-writer`, `prompt-writer` (Claude).
**Commands** - `plan-reviewer` (Codex), `project-docs` (Claude & Codex).

**Skills** — coding standards (Python, React, Tailwind, shadcn/ui), architecture patterns (DDD, feature-driven), and model-specific prompt engineering (Claude Opus 4.6, GPT-5.2, Gemini 3). Applied automatically based on the file type you're editing.

**Security** — `settings.json` blocks agent access to `.env`, `*.pem`, `*.key`, credentials, cloud configs, SSH keys, Terraform state, and databases.

## Installation

Installs agents, skills, commands, and settings globally to `~/.claude/` and `~/.codex/`. Existing files get backed up automatically.

### Quick install (recommended)

One-liner, no Node.js required. Needs `curl` and `tar` (preinstalled on macOS/Linux).

```bash
curl -fsSL https://raw.githubusercontent.com/dynokostya/just-works/main/bootstrap.sh | bash
```

With flags:

```bash
curl -fsSL https://raw.githubusercontent.com/dynokostya/just-works/main/bootstrap.sh | bash -s -- --personal
curl -fsSL https://raw.githubusercontent.com/dynokostya/just-works/main/bootstrap.sh | bash -s -- --dry-run
```

Pin to a specific version:

```bash
JUST_WORKS_REF=v1.1.3 curl -fsSL https://raw.githubusercontent.com/dynokostya/just-works/main/bootstrap.sh | bash
```

To update: re-run the same command.

### Via npm

Requires [Node.js](https://nodejs.org/) 18+.

```bash
npx @dynokostya/just-works              # default settings
npx @dynokostya/just-works --personal   # opinionated settings (permissions, hooks, sounds)
npx @dynokostya/just-works@latest       # update
```

### From source

```bash
git clone https://github.com/dynokostya/just-works.git
cd just-works
./install.sh            # macOS / Linux
install.bat             # Windows
```

To update: `git pull && ./install.sh`

### Options

```bash
--personal              # opinionated settings (pre-approved commands, hooks, sounds)
--dry-run               # preview without changes
--skip-config           # skip settings.json
--skip-statusline       # skip statusline-command.sh
--skip-skills-claude    # skip Claude Code skills
--skip-skills-codex     # skip Codex skills
--claude-only           # skip Codex
--codex-only            # skip Claude
--no-backup             # skip backup prompt (for CI/scripts)
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
