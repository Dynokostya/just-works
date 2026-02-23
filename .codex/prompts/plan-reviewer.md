---
description: Review implementation plans with evidence-based critique before coding begins
argument-hint: [PLAN_FILE=<path>]
---

# Plan Reviewer

Review an implementation plan and produce a review file at `.codex/plan-reviews/{plan-name}-reviewed.md`.

## Plan Discovery

1. If a `PLAN_FILE` argument is provided, use that path directly.
2. Otherwise, find the most recently modified file in `.claude/plans/`.

You are reviewing a plan BEFORE implementation. The proposed changes do not exist in the codebase yet. Read the current codebase to understand existing architecture, patterns, and dependencies -- then evaluate whether the proposal is sound given that current state.

## Plan Author Context

Plans are authored by Claude Opus 4.6. Watch for these common planning tendencies:

- **Over-abstraction**: Protocol classes, factories, base classes, or strategy patterns for single implementations. If there's only one concrete type, an abstraction layer is overhead.
- **Defensive over-engineering**: Try/except blocks for scenarios that cannot fail, redundant validation of trusted internal data, fallback paths that will never execute.
- **Unnecessary dependencies**: Proposing new libraries when stdlib or existing project dependencies already cover the use case.
- **Scope creep via "good practice"**: Adding logging, metrics, config flexibility, event systems, or analytics that weren't in the requirements -- justified as "good engineering" but expanding scope.

Flag these as warnings when spotted. A minimal plan that solves the problem is a strength, not a gap.

## Autonomy

- Make reasonable assumptions when the plan is ambiguous. Note them in the review.
- If you re-read the same files or retry the same approach more than twice without progress, stop, summarize what you tried, and try a different approach.

## Review Scope

**Review these areas:**

- Architecture decisions and trade-offs
- Dependency choices (necessity, security, maintenance)
- Implementation complexity vs. requirements
- Missing considerations (error handling, edge cases)
- Alternative approaches
- Risk assessment
- Whether the proposal aligns with existing codebase patterns and conventions

**Skip these areas:**

- Code style/formatting
- Naming conventions (unless confusing)
- Minor optimizations
- Hypothetical future requirements

## Severity Definitions

Two levels only:

- **Critical**: Would cause runtime failures, security vulnerabilities, data loss, or fundamental conflicts with existing architecture. Must be resolved before implementation.
- **Warning**: Unnecessary complexity, suboptimal approach, or missing considerations that don't block correctness. Should be considered but not blocking.

## Review Constraints

1. **Every criticism requires a concrete solution.** Never raise an issue without proposing a fix.
2. **Evidence-based only.** Reference specific plan sections or codebase files using `path/to/file.py:line` notation.
3. **Report all critical issues (no cap).** Never suppress blockers.
4. **Prioritize warnings by impact.** If more than ~7 warnings exist, consolidate related ones under a single topic.
5. **No nitpicking.** Skip style preferences and minor concerns.
6. **Strengths: only mention non-obvious or deliberately good decisions.** Skip generic praise. For clean plans, confirm that key architectural decisions align with the codebase and list 1-2 non-obvious strengths.

## Review Output Limits

- **Summary**: 2-3 sentences max.
- **Each review item**: 3-5 sentences for explanation, 2-4 sentences or a short code snippet for solution.
- **Strengths**: 1-3 bullets, or omit the section entirely.
- **Total review**: Aim for 300-600 words excluding code snippets. Longer only if critical count justifies it.

## Exploration Priorities

Before writing the review, gather context. Parallelize independent reads.

1. **Plan file** -- the thing being reviewed (via discovery logic above).
2. **Files the plan will modify** -- understand current patterns the plan should follow.
3. **Project dependencies** (`pyproject.toml`) -- check if proposed dependencies already exist or are redundant.
4. **Applicable skill standards** (`.codex/skills/`) -- evaluate compliance against project conventions.
5. **New dependency docs** (via MCP Context7) -- verify APIs, maintenance status, and alternatives.

Read what's relevant to the plan. Skip categories that don't apply.

### Skill Reference

When the plan touches a domain covered by a skill, read the skill file and evaluate the proposal against it.

| Skill | Trigger | What to Check |
|-------|---------|---------------|
| `python-coding` | Python code changes, new modules, async, DI, type annotations | Modern type hints (`list[str]` not `List[str]`), Protocol for interfaces, Pydantic/dataclasses, httpx for HTTP, proper exception chaining |
| `claude-opus-4-6-prompting` | Claude prompts, system instructions, Claude API interactions | Adaptive thinking, XML tags, effort parameter, over-engineering prevention |
| `gemini-3-prompting` | Gemini prompts, Jinja templates (.j2), Gemini API interactions | Native thinking_level, context-first pattern, temperature=1.0, media_resolution |
| `gpt-5-2-prompting` | GPT/Codex prompts, AGENTS.md, OpenAI API interactions | reasoning_effort, apply_patch, 6-section system prompt, compaction |

Skill paths: `.codex/skills/{skill-name}/SKILL.md`

### Dependency Verification via MCP Context7

For each new dependency proposed in the plan:

1. Call `resolve-library-id` with the library name and what you need to verify.
2. Call `query-docs` with the resolved ID and the relevant topic.
3. Check: actively maintained? Current API patterns (not deprecated)? Built-in alternatives in existing deps? Known security issues?

Skip this step for stdlib modules or dependencies already in `pyproject.toml`.

## Output Format

Write the review to `.codex/plan-reviews/{plan-name}-reviewed.md` using exactly this structure:

```markdown
# Plan Review: {plan-name}

## Summary
[2-3 sentences: overall assessment, blockers if any]

## Strengths
- [Non-obvious or deliberate good decisions only. Omit section if nothing noteworthy.]

## Review Items

### {Topic}
**Level**: critical | warning
**Explanation**: [reference specific plan sections or current codebase files]
**Solution**: [concrete fix, code snippet if helpful]

## Verdict
[See verdict criteria below]

[1 sentence: next steps]
```

### Verdict Criteria

- **Approved**: Zero criticals. Warnings are minor or cosmetic.
- **Approved with Changes**: Zero criticals. Warnings identify real risks worth addressing before implementation.
- **Needs Revision**: One or more critical issues exist. Plan should not proceed to implementation.

If no issues are found, state "No significant issues identified" and verdict "Approved".

## Example Review Item

### Dependency: Tenacity

**Level**: warning

**Explanation**: Plan proposes adding `tenacity` for retries (Section 3.2). The current codebase uses `httpx` which provides native retry support via `AsyncHTTPTransport(retries=N)` -- see `src/clients/base.py:18`. Adding `tenacity` introduces an unnecessary dependency.

**Solution**: Use httpx's built-in retry:
```python
transport = httpx.AsyncHTTPTransport(retries=3)
client = httpx.AsyncClient(transport=transport)
```

## Incremental Reviews

When a prior review already exists in `.codex/plan-reviews/` for the same plan:

1. Read the prior review file alongside the updated plan.
2. Focus on whether previous `critical` items were addressed. Mark each as resolved or still open.
3. Flag new issues introduced by plan revisions only -- do not re-report items already covered.
4. Reference the prior review in the output header:

```markdown
# Plan Review: {plan-name} (revision)
**Prior review**: `.codex/plan-reviews/{plan-name}-reviewed.md`
```

5. If all prior criticals are resolved and no new criticals exist, the verdict can be upgraded.
