# just-works

I am tired of manually prompting Claude Code each time to include all tools, best practices, aggressive language — that's why I created this repo.

Drop-in AI agent workflows, coding skills, and prompt standards for **Claude Code** and **OpenAI Codex**.

Just copy `.claude/` into any project — or install globally — and get pre-configured agents and quality guardrails out of the box.

**`.codex/` works only if you install it globally.** The exception is skills: Codex reads project skills from `.agents/skills/`, so for a single project copy `.claude/skills/` to `<project>/.agents/skills/`.

## What's Inside

**Lean by default** — the `compressed` output style trims response tokens (filler, hedging, emojis); `minimal-coding` forces least-code solutions. Less context burned, lower cost.

**Full Claude Code fluency** — uses the whole toolset by default: `AskUserQuestion` for structured choices, rich markdown, and parallel tool calls — not plain-text walls.

**Context-isolating subagents** — delegates file-type work (`python`, `react`, `swift`, …) to subagents that carry their own context, so the main thread stays lean and focused.

**Agents** — file-type-triggered writers (`python`, `typescript`, `swift`, `csharp`, `react`), plus `prompt-writer`. 6 per provider. PlantUML diagrams are handled by the `plantuml-diagramming` skill.

**Skills** — coding standards (Python, TypeScript, React, Tailwind, shadcn/ui, Swift, C#), model-specific prompt engineering (Claude Opus 5.5 and Fable 5.1, GPT-6, Gemini 3), behavioral modes (`minimal-coding` for least-code solutions), and `human-writing` for documents that people outside the project can follow. Applied automatically based on the file type you're editing. The exception is `staged-docs`, which runs only when you start it with a topic (`/staged-docs <topic>`, or `$staged-docs` in Codex): it builds a document with you piece by piece, in a mode you choose per piece (agent-drafted, step by step, or author-led), with review rounds you decide on a local page.

**Security** — the `--personal` `settings.json` blocks agent reads of `.env`, `*.pem`, `*.key`, credentials, cloud configs, SSH keys, Terraform state, and databases. The default `settings.json` has an empty deny-list.

## Installation

Installs agents, skills, and settings globally to `~/.claude/` and `~/.codex/` (Codex skills go to `~/.agents/skills/`). The status line script (`statusline-command.sh`) needs [`jq`](https://jqlang.org/).

The installer only touches what this repo ships. It replaces each agent, skill and output style one by one, so other skills and agents already in those folders stay as they are. Before it replaces or removes anything it backs it up to `~/just-works-backups/<timestamp>/`, unless you answer `n` at the prompt or pass `--no-backup`. Each install writes a `.just-works-manifest` file in `~/.claude/`, `~/.codex/` and `~/.agents/` listing what it installed. On the next run, entries that a newer version no longer ships (renamed or deleted skills, for example) are removed from that list. Your own files are never in it.

To install into another Claude Code profile or Codex home, set the variable that tool already reads, for example `CLAUDE_CONFIG_DIR=~/.claude-2 ./install.sh --claude-only --skip-config` or `CODEX_HOME=~/.codex-work ./install.sh --codex-only`.

> **For the best experience, add `--personal`** — installs my full opinionated config instead of the minimal defaults:
>
> ```bash
> curl -fsSL https://raw.githubusercontent.com/dynokostya/just-works/main/bootstrap.sh | bash -s -- --personal
> ```

### My `--personal` config vs default

`--personal` swaps the minimal `*.default` files for my opinionated config:

| | Default | `--personal` (my config) |
|---|---|---|
| Permissions | prompts for everything | `bypassPermissions` + safe read-only allow-list |
| Security deny-list | empty | blocks reads of keys, credentials, lockfiles, build dirs |
| Model / effort | Claude Code defaults | `opus[1m]` main model at `high` effort, subagents forced to `sonnet` at `high` effort; the limit of 5 concurrent subagents and nesting depth 1 are set by `env` variables in `settings.json` |
| Output style | `default` | `Compressed` (fewer tokens) |
| Codex | model + basic status line | `danger-full-access`, no approval prompts, up to 6 concurrent agent threads, MCP server (Playwright) |
| Hooks (Claude) | none | Bash command rewriting + completion sounds |

**Two `--personal` hooks need extra setup to work:**

- **`rtk` Bash rewriting** (`rtk hook claude`) rewrites commands to save tokens, but needs [`rtk`](https://github.com/rtk-ai/rtk) ≥ 0.37.0 installed. Without it every Bash call shows a non-blocking hook error and runs unchanged — install `rtk`, or delete the `PreToolUse` hook from `settings.json`. Upgrading from an older just-works install? Re-run the installer (even with `--skip-config`) to switch the old `~/.claude/hooks/rtk-rewrite.sh` hook entry to `rtk hook claude`, then delete that leftover script — see [Troubleshooting](#troubleshooting).
- **Completion sounds** use `afplay` + `/System/Library/Sounds/Glass.aiff`, which are **macOS-only**. On Linux/Windows the notification hooks fail silently (no sound) — swap `afplay` for your player (`paplay`/`aplay` on Linux), or remove the hook.

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
JUST_WORKS_REF=v1.1.4 curl -fsSL https://raw.githubusercontent.com/dynokostya/just-works/main/bootstrap.sh | bash
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
--skip-config           # skip settings.json (still migrates a legacy rtk hook entry)
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

MCP servers are configured per project, not globally. The installers do not copy the MCP files, so download the one you want from this repo into your project. `.mcp.json.default` is an empty server list; `.mcp.json` declares the Playwright server.

```bash
curl -fsSL https://raw.githubusercontent.com/dynokostya/just-works/main/.mcp.json.default -o /path/to/your/project/.mcp.json
```
OR
```bash
curl -fsSL https://raw.githubusercontent.com/dynokostya/just-works/main/.mcp.json -o /path/to/your/project/.mcp.json
```

Requires `npx` (Node.js) in your PATH.

## Troubleshooting

### `PreToolUse:Bash hook error` … `rtk-rewrite.sh: No such file or directory`

`settings.json` still points at the pre-0.37 rtk hook script, which rtk ≥ 0.37 deletes when it migrates — usually after restoring or copying an older `settings.json`. Every Bash call shows the error and runs without rtk.

`rtk init -g` doesn't repair this: it counts the stale entry as an installed hook and writes nothing ([rtk-ai/rtk#3693](https://github.com/rtk-ai/rtk/issues/3693)). Re-run the installer (add `--skip-config` to keep your settings), or patch the file directly — swap the path for other config dirs such as `~/.claude-2`:

```bash
perl -pi -e 's/("command"\s*:\s*)"(?:[^"\\]|\\.)*rtk-rewrite\.sh(?:[^"\\]|\\.)*"/$1"rtk hook claude"/g' ~/.claude/settings.json
```

Confirm with `rtk verify` (prefix `CLAUDE_CONFIG_DIR=<dir>` for other config dirs): it should report `native binary hook registered in settings.json` as `PASS`. Don't rely on `rtk init --show` here — it reports the stale entry as configured.

## Project Structure

```
.claude/
  agents/                 # Claude Code agent definitions
  skills/                 # Coding and prompting standards (the single copy, also installed for Codex)
  output-styles/          # Selectable output styles (compressed)
  settings.json           # Personal permissions, hooks, env (--personal)
  settings.json.default   # Minimal settings
  statusline-command.sh   # Status line (needs jq)
.codex/
  agents/                 # Codex custom agent definitions (TOML)
  skills/                 # Codex-only extras laid over .claude/skills (staged-docs/agents/openai.yaml)
  config.toml             # Personal config (--personal)
  config.toml.default     # Minimal config
  config/azure/           # Azure OpenAI variants of both
  hooks.json              # Lifecycle hooks (notification), plus hooks.json.default
bin/cli.mjs               # npx installer
install.sh, install.bat   # Installers for macOS/Linux and Windows
bootstrap.sh              # curl | bash wrapper around install.sh
.mcp.json, .mcp.json.default  # Per-project MCP server declarations
CLAUDE.md                 # Behavioral instructions for Claude Code
web-chat-prompt.md        # Behavioral instructions for claude.ai chat
AGENTS.md                 # Behavioral instructions for Codex
```

`.claude/` and `.codex/` are parallel and independent — use one or both.

## Customization

Add project-specific agents in `.claude/agents/` or `.codex/agents/`. Override skill defaults in your own `CLAUDE.md` or `AGENTS.md`. Extend the deny-list in `.claude/settings.json`.

If you fork this: write each skill once in `.claude/skills/`. The installers copy that folder to `~/.agents/skills/` for Codex and add any files from `.codex/skills/` on top, so put Codex-only files there under the same skill name. Codex doesn't support `@file` references, so keep each skill self-contained. Keep instructions model-agnostic.

## License

Apache 2.0
