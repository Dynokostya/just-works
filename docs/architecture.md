# Architecture

## Structure

Two parallel provider directories plus distribution scaffolding:

- `.claude/` — Claude Code agents, skills, commands, hooks, settings, statusline, plans
- `.codex/` — OpenAI Codex agents, prompts, skills, config, hooks, plan-reviews
- `bin/cli.mjs` — Node.js installer published as `npx @dynokostya/just-works`
- `install.sh`, `install.bat` — shell installers for macOS/Linux and Windows
- `src/evals/` — pytest eval harness validating skill files against frontier models
- `CLAUDE.md` / `AGENTS.md` / `CLAUDE-CHAT.md` — shared behavioral guidelines at root
- `.mcp.json` — per-project MCP server declarations (Playwright)

## Module Boundaries

**Agents** (`.claude/agents/`, `.codex/agents/`) — 8 specialized writers per provider, file-type-triggered via `description` frontmatter:
- `python-code-writer`, `typescript-code-writer`, `swift-code-writer`, `csharp-code-writer`
- `react-code-writer` (React/Tailwind/shadcn)
- `prompt-writer` (Opus, GPT, Gemini)
- `diagrammer` (PlantUML)
- `ticket-creator` (ClickUp MCP)

**Skills** (`.claude/skills/`, `.codex/skills/`) — 17 mirrored skill directories: coding standards per language, architecture patterns (DDD, feature-driven), model-specific prompting (`opus-4-7-prompting`, `gpt-5-4-prompting`, `gemini-3-prompting`), domain skills (`ticket-writing`, `clickup-tickets`, `plantuml-diagramming`, `rest-api`), and the `caveman` communication mode.

**Commands** (`.claude/commands/`, `.codex/prompts/`) — multi-phase workflows:
- `project-docs` — 5-phase documentation pipeline (Detect → Explore → Synthesize → Write → Verify)
- `git-sync` — sync repos and submodules to default branch
- `plan-reviewer` — Codex-only, reviews plans authored by Claude Opus

Dependency direction: Agents → Skills (declared in agent frontmatter). Commands → Agents and Skills (referenced in command prompts). Skills may compose (`clickup-tickets` pairs with `ticket-writing`). No reverse dependencies.

## Data Flow

1. User invokes agent via CLI (e.g., Claude Code matches `*.py` edit → `python-code-writer`).
2. Orchestrator reads agent frontmatter, loads declared skills as behavioral standards.
3. Agent reads target file and project context before editing.
4. Agent edits via `Read`/`Edit`/`Write`/`Bash` tools within declared tool allow-list.
5. Orchestrator marks task complete per `CLAUDE.md` rule 3.

Commands orchestrate multi-phase work: `project-docs` spawns three parallel `Explore` subagents in Phase 2, synthesizes with citation-gating in Phase 3, writes in Phase 4, and verifies traceability in Phase 5.

## Key Patterns

- **Dual-provider mirror** — `.claude/` (Markdown with YAML frontmatter) and `.codex/` (TOML) hold parallel copies of the same agents and skills; Codex can't resolve `@file` references, so skills must be duplicated.
- **File-extension-triggered selection** — agent `description` fields declare target file types; the orchestrator matches on descriptions, not names.
- **Skill composition** — agents stack multiple skills (e.g., `react-code-writer` loads `react-coding` + `tailwind-css-coding` + `shadcn-ui-coding`).
- **Permission deny-list** — shipped `settings.json` blocks `.env`, `*.pem`, `*.key`, credentials, cloud configs, SSH keys, and DB files.
- **Evidence-gated documentation** — `project-docs` discards claims without source citations during verification.
- **Personal vs default configs** — `settings.json` + `settings.json.default` pair, `config.toml` + `config.toml.default` pair; installer `--personal` flag picks the opinionated variants.

## Entry Points

- `bin/cli.mjs` — `npx @dynokostya/just-works` installer
- `install.sh`, `install.bat` — clone-and-run installers
- `.claude/commands/project-docs.md` — documentation pipeline
- `.claude/commands/git-sync.md` — multi-repo branch sync
- `.codex/prompts/plan-reviewer.md` — Codex plan review
- `.claude/agents/*.md`, `.codex/agents/*.toml` — 8 specialized writer agents per provider
- `src/evals/` — pytest harness for skill validation via OpenRouter

---
*Generated: 2026-04-21 | Commit: 2dc99fd*
