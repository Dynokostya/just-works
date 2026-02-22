# Architecture

## Structure

Two parallel provider directories at root, plus shared behavioral standards:

- `.claude/` — Claude Code agents, skills, commands, and settings
- `.codex/` — OpenAI Codex prompts, skills, and Azure configuration
- `CLAUDE.md` / `AGENTS.md` — shared agent behavioral guidelines at root

## Module Boundaries

**Agents** (`.claude/agents/`, `.codex/prompts/`) — entry points that delegate specialized work:
- `python-code-writer` — Python file creation, editing, and quality enforcement
- `prompt-writer` — LLM prompt creation across Claude, GPT-5.2, and Gemini 3

**Skills** (`.claude/skills/`, `.codex/skills/`) — behavioral standards referenced by agents:
- `python-coding` — error handling, async patterns, type safety, security defaults
- `claude-opus-4-6-prompting` — adaptive thinking, XML tags, behavioral tuning
- `gpt-5-2-prompting` — verbosity control, reasoning effort, structured extraction
- `gemini-3-prompting` — three-layer prompts, context-first, thinking levels

**Commands** (`.claude/commands/`) — multi-step workflows:
- `project-docs` — 5-phase documentation generation pipeline

Dependency direction: Agents → Skills. Commands → Agents. No reverse dependencies.

## Data Flow

1. User invokes agent via CLI (e.g., `/python-code-writer`)
2. Agent loads applicable skill standards
3. Agent reads project context and target files
4. For external libraries, agent queries Context7 MCP for documentation
5. Agent implements changes via Read/Edit/Write tools
6. Quality checks run post-write (ruff, mypy for Python)

## Key Patterns

- **Dual-provider support** — identical capabilities via `.claude/` and `.codex/`, zero cross-dependency
- **Skill-based standardization** — shared coding and prompting conventions prevent per-agent reinvention
- **Permission sandboxing** — explicit deny-list for sensitive files (`.env`, keys, credentials) in `.claude/settings.json`
- **Evidence-based documentation** — auto-generated docs require source file citations; unverifiable claims are discarded

## Entry Points

- `.claude/agents/python-code-writer.md` — Python development workflows
- `.claude/agents/prompt-writer.md` — prompt engineering workflows
- `.claude/commands/project-docs.md` — documentation generation pipeline
- `.codex/prompts/plan-reviewer.md` — implementation plan review

---
*Generated: 2026-02-21 | Commit: 2589783*
