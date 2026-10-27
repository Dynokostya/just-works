---
name: gpt-6-prompting
description: Apply when creating or editing prompts, system prompts, AGENTS.md files or agent instructions that target the GPT-6 family (gpt-6-astra, gpt-6.1-sol, gpt-6-luna), including reasoning effort settings and migration from GPT-5.6.
---

# GPT-6 Prompt Writing Guidelines

## When to Use

- Creating or editing prompts targeting GPT-6 (`gpt-6-astra`, `gpt-6.1-sol`, `gpt-6-luna`)
- Writing or auditing skills and AGENTS.md files that GPT-6 models will read
- Tuning persistence, approval boundaries, writing style, delegation, and testing behavior
- Migrating prompt text from GPT-5.6 or older GPT models
- Diagnosing Astra behaviors: early stops for review, unneeded questions, detailed formatted output, over-testing, under-delegation

## Overview

GPT-6 is OpenAI's frontier family: `gpt-6-astra` (highest intelligence, the main focus of this skill), `gpt-6.1-sol` (near-Astra performance at lower cost), and `gpt-6-luna` (fast, low cost, high volume). The earlier `gpt-6-sol` is still an API model with different reasoning-effort support (see the table). Source: https://developers.openai.com/api/docs/guides/latest-model.

OpenAI's prompt snippets address behavior observed with Astra. Evaluate them on the model and workload you target before applying them to Sol or Luna. The reverse also holds: "Guidance that helps Sol or Luna may overconstrain GPT-6 Astra" (https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra).

The core discipline is lean prompting. On Astra, "what used to require a lot of handholding and scaffolding no longer does," and "overly specific guidance can now hinder results where it previously helped" (same blog post). Prompts, skills, and AGENTS.md files carried over from GPT-5.6 are the most common source of regressions because several Astra defaults reverse GPT-5.6 behavior.

<context>
Behaviors to design around (latest-model guide, "GPT-6 Astra behavior"):

- **Tentative by default**: asks a question when extra input could materially change the result, including non-blocking questions while it works. This can stop work where the user expected reasonable assumptions and persistence.
- **Early review stops**: may reach a first implementation and return for review while work remains (blog, "Persistence").
- **Stronger instruction following**: more sensitive to instructions in prompts, skills, and AGENTS.md. Conflicting or unclear guidance can make it pause and block work early. State each rule once.
- **Detailed, formatted output**: tends toward lists, tables, Markdown, and recurring phrases across sessions. Specify writing style and structure.
- **Tests on its own**: carried-over "always run tests" nudges produce unnecessary testing.
- **Under-delegates**: may use subagents less than the workflow wants. Say when delegation is expected.
</context>

## Lean Prompting

Trim iteratively, one group of instructions, examples, skills, or tools at a time, and re-run evals after each cut.

- Remove duplicate statements of a rule, process instructions for things Astra already does (testing, persistence scaffolding), and cautionary "ask first" or "stop for review" language on safe work.
- Keep user-visible outcomes, success criteria, the definition of done, safety and permission constraints, tool-routing rules that depend on context, and required output schemas.
- Use `ALWAYS`, `NEVER`, `must`, and `only` for invariants (safety rules, required output fields). For judgment calls write a decision rule: replace `"ALWAYS search the web before answering"` with `"Search the web when the question names a specific product, person, date, version, or figure; otherwise answer from context."`

Prompt layout, outcome-first examples, tool routing, and retrieval wording are in `references/general-techniques.md`.

## Reasoning Effort

Sources: https://developers.openai.com/api/docs/guides/reasoning, https://developers.openai.com/codex/models, and the latest-model guide.

| Model | Supported `reasoning.effort` | Default | Suggested start |
|---|---|---|---|
| `gpt-6-astra` | `low`, `medium`, `high`, `xhigh`, `max`. `none` returns HTTP 400 | no default documented, so pin it | Codex: its Light setting, which is `low` |
| `gpt-6.1-sol` | `low` to `max`. `none` and `minimal` unsupported | `medium` | Codex: the client default |
| `gpt-6-sol` | `none` to `max` | `medium` | |
| `gpt-6-luna` | `none` to `max` | `medium` | Codex: `high` |

- Where an old prompt relied on `none` or `minimal`, start Astra and `gpt-6.1-sol` at `low`.
- Effort levels do not map exactly between generations. OpenAI advises trying a familiar task at a lower setting than before.
- Fix the prompt before raising effort: look for a missing success criterion, definition of done, routing rule, or verification loop first.
- Codex notes that most tasks do not need `max`, and the 5.6-era guide says to use pro mode (`reasoning.mode: "pro"`) only where evals show a gain. Do not set either as a global default.
- For faster time to first visible token, "ask the model to generate a short preamble before continuing with deeper reasoning" (reasoning guide).

## Autonomy, Persistence, and Approval

Astra's typical failure is stopping too early, not overreaching. Three snippets from the latest-model guide ("Initiative and follow-through") address it.

Bias to action and persistence:

```
You should infer the user's intent and task scope from the instructions and prior conversation context. Your job is to bias towards action and carry the user's intended task to completion.

When the user expresses intent to perform new work or fix an existing issue, persist until the user's intended goal is complete. Progress autonomously towards the user's goal (e.g. creating isolated worktrees / checkouts if needed, resolving merge conflicts, read-only actions, creating draft PRs etc.) unless they are clearly destructive or irreversible.
```

Treat "can you..." as a request:

```
When the user's prompt indicates a request for action, such as "can you...", "I want to...", "help me..." and similar expressions, treat these as instructions to do the work and take action. Do not stop at acknowledging capability (e.g. "Yes…"), proposing a plan, or offering to continue. Do not settle for a partial or "helpful enough" solution that does not fully satisfy the user's task to save time, effort or tokens. If a task requires sustained work, complete all the necessary work until the intended outcome is fulfilled.
```

Ask for approval only on a concrete result:

```
Before asking the user clarifying questions, you should complete the work that is already authorized from context and necessary to make the proposed action concrete and reviewable. The user should be approving a concrete, reviewable result. For example, before deploying a change, writing to an external application, merging a PR or publishing a site, do all the required work first so that user approval is the final step. You don't need user permission for reversible tasks, read-only actions, reviews or fixes, or anything for which authorization is provided earlier in the session or strongly implied from the task instruction.

Do not introduce unsolicited warnings, disclaimers, approval flows, or safety/compliance checklists due to hypothetical risk.
```

The model also asks non-blocking questions by default, so adjust these snippets to the level of autonomy the application needs.

**Define "done" before starting.** If the task includes getting the implementation running, inspecting the result, and fixing what fails, put that in the request. "A requirement to stop for review after the first implementation will pull the model toward an earlier stopping point" (blog). To make it explore past a first pass, say what to explore and where to stop. For lists and batches, require tracked coverage: the task is incomplete until each item is covered or marked `[blocked]` with what is missing.

**Audit carried-over "ask first" language.** Astra "could take it too seriously and may stop work where you'd actually be happy for it to continue" (blog, "Decision boundaries"). The GPT-5.6 section of the latest-model guide already warns that repeating "ask first," "do not mutate," or "wait for approval" causes unnecessary approval requests for safe, expected actions. Keep confirmation for destructive, irreversible, and external actions, stated once. Grant permission for safe workflows explicitly, for example in AGENTS.md:

```
The local tests use disposable fixtures and have no production access. Run them, fix failures caused by the requested change, and rerun affected tests without asking for approval at each step.
```

## Writing Style

Astra "tends to use lists, tables and Markdown to make responses scannable" (latest-model guide). State the style your application needs. OpenAI's snippet:

```
Default to using clear, concise paragraphs, each developing one main idea. Use lists only when the information is genuinely parallel, sequential, or easier to compare, and avoid nested lists unless the hierarchy cannot be expressed clearly in prose. Use plain, simple language: familiar words, concrete examples, and precise verbs. Prefer active voice and direct statements.

Make sure to state the main point clearly and early, then develop it with the explanation and detail the reader needs. Let each sentence build on what came before. Develop the points that matter and provide enough support to be useful.
```

- Describe tone through writing choices (how directly to answer, when to acknowledge a problem), not labels such as "friendly" (GPT-5.6 section of the latest-model guide).
- Put a quantitative length bound in the output contract ("3-6 sentences", "under 400 words"). `text.verbosity` sets the default detail level; the prompt then states task-specific length and content.
- Astra reuses stock phrases across sessions. The stock-phrase suppression snippet is in `references/prompt-snippets.md`.

## Skills and AGENTS.md

Source: the blog post and the latest-model guide ("Instruction following").

State precedence explicitly:

```
The user's instructions take precedence over guidelines provided in a skill. If explicit user instructions conflict with a skill's instructions, prioritize the user's instructions.
```

- Keep skill descriptions as short as possible while making clear when to use the skill. Codex shortens descriptions when many skills load, so the model sees less of each.
- Make SKILL.md or AGENTS.md a minimal router to supporting docs and scripts. Avoid itineraries and recipes.
- Point to docs by context: "Use architecture.md for service boundaries, database.md for schema changes, and deployment.md when preparing a deployment," not "Before every edit, read architecture.md, database.md, and deployment.md."
- Revisit every AGENTS.md instruction and ask whether it is still needed. Repository skills also guide other contributors' agents on other models.
- The snippet that makes skill-caused pauses traceable is in `references/prompt-snippets.md`.

## Testing and Verification

Astra tests on its own, so the risk is over-testing small changes. Replace "always run tests" and "run the most relevant check" nudges with OpenAI's snippet:

```
Do not write tests for reversible, low-impact changes that mirror the implementation. If you do choose to verify your work with tests, make sure that the tests are meaningful and necessary to verify implementation.

Run tests appropriate to the change and complete required checks. Once those pass, broaden or repeat testing only when new changes, failures, or unresolved concerns justify it; otherwise, continue toward completing the task.
```

Give the model ways to inspect its own work. OpenAI's games write-up describes the loop of reproducing a problem, inspecting screenshots and state, tracing the code, making a change, and rerunning the check, and recommends building the tools for it early: repeatable scenes, state and performance counters, and browser tests (https://developers.openai.com/blog/how-to-build-games-with-astra). For visual artifacts, require rendering and inspecting the result before finalizing.

## Subagents

Astra can delegate to parallel subagents but may do so less than the workflow wants. OpenAI's snippets (latest-model guide, "Subagent delegation"):

```
If at any point you can parallelize work by delegating tasks to another agent (no matter if you are the root or subagent), you should do so using collaboration tools if it could save time or improve quality.
```

```
Messages that you send to other agents and your final answer may be read by a human, so ensure they are legible. Always put proper spaces between words and/or numbers.
```

Tune the first snippet to the harness: say when and how much to delegate.

## Checklist

- [ ] Reasoning effort pinned explicitly for the target model; no `none` on Astra or `gpt-6.1-sol`.
- [ ] Each instruction stated once across system prompt, tool descriptions, skills, and AGENTS.md.
- [ ] Writing style and structure specified; the output contract has a quantitative length bound.
- [ ] Definition of done includes running, inspecting, and fixing the result.
- [ ] Approval limited to destructive, irreversible, or external actions; safe workflows explicitly permitted.
- [ ] No leftover "ask first," "stop for review," or "always run tests" nudges.
- [ ] Skills and AGENTS.md audited, with user-over-skill precedence stated.
- [ ] Delegation guidance present for multi-agent setups.
- [ ] Prompt tested unchanged after the model switch, before any re-engineering.

## Reference Files

- `references/prompt-snippets.md`: read when you need the stock-phrase suppression snippet, the technical-communication snippet, or the skill-pause tracing snippet.
- `references/general-techniques.md`: read when laying out a full system prompt, or writing tool routing, Programmatic Tool Calling, retrieval, or frontend instructions.
- `references/migration.md`: read when converting prompts or harness settings from GPT-5.6 or older GPT models.

## Reference

- Using GPT-6: https://developers.openai.com/api/docs/guides/latest-model
- Rethinking skills and prompts for GPT-6 Astra: https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra
- Reasoning models: https://developers.openai.com/api/docs/guides/reasoning
- Codex models: https://developers.openai.com/codex/models
- Building games with Astra: https://developers.openai.com/blog/how-to-build-games-with-astra
