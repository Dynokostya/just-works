# Project Documentation

Generate or update project documentation in `docs/`. Produces three files:

- `docs/mission.md` — What the project is and who it's for
- `docs/tech-stack.md` — Inventory of languages, frameworks, tools, infrastructure
- `docs/architecture.md` — How the system is structured and how parts connect

## Phase 1: Detect State

Classify each file independently:

| File | Exists & non-empty | Status |
|------|-------------------|--------|
| `docs/mission.md` | yes | **update** |
| `docs/mission.md` | no | **create** |
| `docs/tech-stack.md` | yes | **update** |
| `docs/tech-stack.md` | no | **create** |
| `docs/architecture.md` | yes | **update** |
| `docs/architecture.md` | no | **create** |

A file with only whitespace or markdown headers with no content counts as **create**, not update.

**Git context gathering.** If `.git` exists, run these two commands via Bash and include the output as background context for all Explore agents in Phase 2:

```bash
git log --oneline -30
git shortlog -s -n --no-merges
```

If the repo has fewer than 5 commits, note this — it signals an early-stage project where exploration will find less and user questions become more important.

Announce the per-file status table and commit count to the user before continuing.

## Phase 2: Explore

Launch three parallel Explore agents using the Task tool (`subagent_type: "Explore"`). All three are independent — launch them in a single message, never sequentially. Specify `thoroughness: "very thorough"` in each prompt.

Every agent prompt must include:
- The git context gathered in Phase 1 (last 30 commit subjects + contributor summary)
- This instruction: **"For every finding, include the source file path and line number (e.g., `src/main.py:42`). Findings without a file reference will be discarded."**
- This ignore directive: **"Skip these directories entirely: `node_modules/`, `.venv/`, `venv/`, `__pycache__/`, `dist/`, `build/`, `.git/`, `.next/`, `.nuxt/`, `target/`, `vendor/` (unless vendor is committed Go code)."**

### Agent 1: Architecture

> Explore the codebase very thoroughly for architectural information. For every finding, include the source file path and line number (e.g., `src/main.py:42`). Findings without a file reference will be discarded. Skip: node_modules/, .venv/, venv/, __pycache__/, dist/, build/, .git/, .next/, .nuxt/, target/, vendor/.
>
> Look for:
> - Top-level directory structure and what each directory contains
> - Module/package boundaries and dependency direction between them
> - Entry points: main scripts, CLI commands, API servers, workers, scheduled jobs
> - Design patterns: MVC, hexagonal, event-driven, repository pattern, etc.
> - Data flow: how a request or input travels from entry point to response
> - Configuration management: env files, config modules, feature flags
> - Test organization relative to source code
> - Whether this is a monorepo (multiple package manifests, separate apps in subdirectories)

### Agent 2: Tech Stack

> Explore the codebase very thoroughly for technology inventory. For every finding, include the source file path and line number (e.g., `pyproject.toml:3`). Findings without a file reference will be discarded. Skip: node_modules/, .venv/, venv/, __pycache__/, dist/, build/, .git/, .next/, .nuxt/, target/, vendor/.
>
> Look for:
> - Programming languages and their versions (configs, CI, runtime files, shebangs)
> - Package manifests: pyproject.toml, package.json, Cargo.toml, go.mod, Gemfile, etc.
> - Frameworks: web, ORM, task queues, testing, CLI
> - Databases and storage: connection strings, migrations, docker-compose services
> - Infrastructure: Dockerfiles, terraform, k8s manifests, CI/CD pipelines, deployment configs
> - Dev tools: linters, formatters, type checkers, test runners, pre-commit hooks
> - External services: API client imports, SDK usage, webhook handlers, third-party integrations

### Agent 3: Mission & Purpose

> Explore the codebase very thoroughly for project purpose and audience. For every finding, include the source file path and line number (e.g., `README.md:1`). Findings without a file reference will be discarded. Skip: node_modules/, .venv/, venv/, __pycache__/, dist/, build/, .git/, .next/, .nuxt/, target/, vendor/.
>
> Look for:
> - README.md and any ABOUT or CONTRIBUTING files
> - Package/project descriptions in manifests (pyproject.toml description, package.json description)
> - User-facing text: landing pages, onboarding flows, help text, CLI descriptions
> - API descriptions, OpenAPI specs, GraphQL schema descriptions
> - Comments or docstrings describing project purpose
> - License and contribution guidelines
> - Any marketing copy, about pages, or FAQ content

## Phase 3: Synthesize & Confirm

After all three agents return, consolidate their findings into a structured summary organized by document. **Discard any finding that lacks a file path reference** — this enforces the "no invention" rule.

### For files in **create** status

Present the summary to the user. Then identify genuine gaps — things the code did not clearly answer.

**Gap detection heuristics** — ask only when the trigger condition is met:

Mission gaps:
- **What problem does this solve?** → Trigger: no README exists, or README has no description beyond project name/install instructions
- **Who is the target user?** → Trigger: no user-facing text found (no CLI help, no UI copy, no API descriptions)
- **What differentiates this?** → Trigger: README does not mention alternatives or positioning

Tech-stack gaps:
- **Ambiguous primary tool** → Trigger: multiple tools serving the same role found (e.g., two ORMs, two test frameworks)
- **Deployment target** → Trigger: no Dockerfile, no CI/CD config, no infra files found
- **External services** → Trigger: code references services (database URLs, API keys) but no config or docker-compose defines them

Architecture gaps:
- **Intended vs actual boundaries** → Trigger: import cycles detected or modules with unclear ownership
- **Missing components** → Trigger: code references modules/packages that don't exist yet

Rules for questions:
- Do NOT ask about things the code clearly answers. Every question must address a genuine gap where the trigger condition was met.
- When exploration found relevant evidence, provide 2-4 concrete options derived from findings.
- When exploration found nothing relevant (common for "target user" or "deployment target" in early projects), ask as a free-text question without forced options.
- The AskUserQuestion tool automatically provides an "Other" free-text option — do not add one manually.
- If no trigger conditions are met, skip questions entirely. It is acceptable to have zero questions.

After gaps are resolved, present the planned content for each **create** file and ask the user to approve before writing.

### For files in **update** status

Read the existing docs. Compare each against the exploration findings.

Present a structured change summary:

```
Changes detected:

architecture.md:
  + New module `workers/` found (src/workers/__init__.py:1), not documented
  ~ Description of `api/` outdated — now uses FastAPI (pyproject.toml:15) instead of Flask
  - Module `legacy/` removed from codebase but still in docs

tech-stack.md:
  + Redis added (docker-compose.yml:23)
  - Removed: celery no longer in dependencies

mission.md:
  No changes detected
```

Every `+` and `~` line must cite the source file. Changes without evidence are not presented.

Ask the user to approve, modify, or reject changes per file. Only write files the user approves.

If exploration reveals something contradicting existing docs and the correct answer is ambiguous, ask the user before deciding.

### Monorepo handling

If Agent 1 identified multiple separate applications (e.g., `frontend/`, `backend/`, `services/auth/`), restructure the output:

- `tech-stack.md` — group items under subheadings per service/app instead of a flat list
- `architecture.md` — add a "Services" section before "Module Boundaries" describing each top-level app and how they communicate
- `mission.md` — no change (mission is project-wide)

## Phase 4: Write

Create `docs/` directory if it does not exist. Write each approved file using these structures.

### docs/mission.md

```markdown
# Mission

## What

[1-2 sentences: what the project does, stated as fact]

## Who

[1-2 sentences: target users or audience]

## Why

[1-2 sentences: core problem being solved, value delivered]

---
*Generated: YYYY-MM-DD | Commit: abc1234*
```

10-15 lines max (excluding footer). No aspirational language. No marketing fluff.

### docs/tech-stack.md

```markdown
# Tech Stack

## Languages

- [Language] [version] — [source: pyproject.toml / Dockerfile / .python-version]

## Frameworks

- [Framework] — [one-line role, e.g. "web server", "ORM", "task queue"]

## Storage

- [Database/cache/queue] — [one-line role]

## Infrastructure

- [Tool] — [one-line role]

## Dev Tools

- [Tool] — [one-line role]

---
*Generated: YYYY-MM-DD | Commit: abc1234*
```

Flat list. One line per item. No prose paragraphs. Only include sections that have at least one entry. Omit empty sections entirely.

For monorepos, replace flat sections with grouped subheadings:
```markdown
## Frameworks

### backend/
- FastAPI — web server
- SQLAlchemy — ORM

### frontend/
- Next.js — React framework
```

### docs/architecture.md

```markdown
# Architecture

## Structure

[Brief description of top-level project organization. Reference actual directory names.]

## Module Boundaries

[Which modules exist, what each owns, dependency direction between them.]

## Data Flow

[How a typical request/input travels through the system, from entry point to response/output.]

## Key Patterns

[Design patterns in use: name, where applied, one-line rationale.]

## Entry Points

- [Entry point] — [what it starts/serves]

---
*Generated: YYYY-MM-DD | Commit: abc1234*
```

Reference tech-stack items by name. Do not duplicate their descriptions.

### Footer values

- **Date**: current date in YYYY-MM-DD format
- **Commit**: short hash from `git rev-parse --short HEAD` (if `.git` exists). If no git repo, omit the commit portion and use only the date.

## Phase 5: Verify

After writing all files, perform a verification pass. For each generated document:

1. Read the file back.
2. For every factual claim (tool name, framework, directory name, pattern), confirm it traces to a specific file found during exploration.
3. If a claim cannot be traced — remove it and note the removal to the user.

Report verification results:

```
Verification:
  mission.md — 3/3 claims verified ✓
  tech-stack.md — 11/12 claims verified, removed: "GraphQL" (no schema or dependency found)
  architecture.md — 8/8 claims verified ✓
```

If all claims verify, report clean and finish. If removals were made, show what was removed and why.

## Rules

These apply to all phases:

- **No invention.** Every statement must trace to a file path found by exploration or to user confirmation. Findings without source references are discarded.
- **No aspiration.** Document what exists, not what is planned. No "we plan to", "future work", "upcoming".
- **No padding.** If a section has nothing to say, omit it. Do not write filler content.
- **Terse language.** These docs are reference material for engineers. Factual, direct, no marketing tone.
- **Respect the templates.** Do not add sections beyond what the templates define unless the user explicitly requests them.
- **Evidence required.** Explore agents must cite file paths. The synthesis phase must cite file paths. The change summary must cite file paths. Uncited claims are removed during verification.
