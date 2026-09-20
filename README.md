# just-works

I am tired of manually prompting Claude Code each time to include all tools, best practices, aggressive language — that's why I created this repo.

Drop-in AI agent workflows, coding skills, and prompt standards for **Claude Code** and **OpenAI Codex**.

Just copy `.claude/` into any project — or install globally — and get pre-configured agents, quality guardrails, and documentation pipelines out of the box.

**`.codex/` works only if you install it globally (only skills folder works per-project).**

## What's Inside

**Lean by default** — the `compressed` output style trims response tokens (filler, hedging, emojis); `minimal-coding` forces least-code solutions. Less context burned, lower cost.

**Full Claude Code fluency** — uses the whole toolset by default: `AskUserQuestion` for structured choices, rich markdown, `TaskCreate` progress tracking, and parallel tool calls — not plain-text walls.

**Context-isolating subagents** — delegates file-type work (`python`, `react`, `swift`, …) to subagents that carry their own context, so the main thread stays lean and focused.

**Agents** — file-type-triggered writers (`python`, `typescript`, `swift`, `csharp`, `react`), plus `prompt-writer`, `diagrammer`, and `ticket-creator`. 8 per provider.
**Commands** — `project-docs` and `git-sync` (Claude & Codex).

**Skills** — coding standards (Python, TypeScript, React, Tailwind, shadcn/ui, Swift, C#), model-specific prompt engineering (Claude Opus 5 & Fable 5, GPT-5.6, Gemini 3), and behavioral modes (`minimal-coding` for least-code solutions). Applied automatically based on the file type you're editing.

**Security** — `settings.json` blocks agent access to `*.pem`, `*.key`, credentials, cloud configs, SSH keys, Terraform state, and databases.

## Installation

Installs agents, skills, commands, and settings globally to `~/.claude/` and `~/.codex/`. Existing files get backed up automatically.

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
| Model / effort | Claude Code defaults | `opus[1m]` main model, subagents forced to `opus`, `max` effort |
| Output style | `default` | `Compressed` (fewer tokens) |
| Codex | model + basic status line | `danger-full-access`, no approval prompts, MCP servers (Playwright, ClickUp) |
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

MCP servers are configured per-project, not globally. To set up MCP in your project:

```bash
cp .mcp.json.default /path/to/your/project/.mcp.json
```
OR
```bash
cp .mcp.json /path/to/your/project/.mcp.json
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
  agents/           # Claude Code agent definitions
  skills/           # Coding and prompting standards
  commands/         # Multi-step workflows (project-docs, git-sync)
  output-styles/    # Selectable output styles (compressed)
  settings.json     # Permissions, hooks, env, MCP toggles
.codex/
  agents/           # Codex custom agent definitions (TOML)
  prompts/          # Codex slash commands (project-docs, git-sync)
  skills/           # Same standards, mirrored for Codex
  config/azure/     # config.toml.default + config.toml
  hooks.json        # Lifecycle hooks (notification)
bin/cli.mjs         # npx installer
CLAUDE.md           # Behavioral instructions for Claude Code
CLAUDE-CHAT.md      # Behavioral instructions for claude.ai chat
AGENTS.md           # Behavioral instructions for Codex
```

`.claude/` and `.codex/` are parallel and independent — use one or both.

## Customization

Add project-specific agents in `.claude/agents/` or `.codex/agents/`. Override skill defaults in your own `CLAUDE.md` or `AGENTS.md`. Extend the deny-list in `.claude/settings.json`.

If you fork this: skills must be mirrored across both providers (Codex doesn't support `@file` references). Keep instructions model-agnostic.

## License

Apache 2.0
