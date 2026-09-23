---
name: gpt-6-prompting
description: Apply when creating or editing prompts targeting the GPT-6 family (gpt-6-astra, gpt-6-sol, gpt-6-luna). Covers bias to action, approval boundaries, writing style, skill and AGENTS.md hygiene, reasoning effort, delegation, testing calibration, and migration from GPT-5.6.
---

# GPT-6 Prompt Writing Guidelines

## When to Use

- Creating or editing prompts targeting GPT-6 (`gpt-6-astra`, `gpt-6-sol`, `gpt-6-luna`)
- Writing or auditing skills and AGENTS.md files that GPT-6 models will read
- Tuning persistence, approval boundaries, writing style, delegation, and testing behavior
- Migrating prompt text from GPT-5.6 or older GPT models
- Diagnosing Astra behaviors: early stops for review, unneeded questions, detailed formatted output, over-testing, under-delegation

## Overview

GPT-6 is OpenAI's frontier family: `gpt-6-astra` (the primary focus of this skill), `gpt-6-sol`, and `gpt-6-luna`. OpenAI's prompt snippets address behavior observed with GPT-6 Astra — evaluate them with your chosen model and workload before applying them to Sol or Luna. The reverse also holds: guidance that helps Sol or Luna may overconstrain GPT-6 Astra.

The core discipline is lean prompting. On Astra, "what used to require a lot of handholding and scaffolding no longer does," and "overly specific guidance can now hinder." Prompts, skills, and AGENTS.md files carried over from GPT-5.6 are the most common source of regressions — several Astra defaults reverse GPT-5.6 behavior.

<context>
Key behavioral characteristics to design prompts around:

- **Outcome-first**: Strongest when the prompt defines destination, constraints, evidence, and completion bar, then leaves the path to the model.
- **Stronger instruction following**: More sensitive to instructions in prompts and skills. Duplicated, conflicting, or cautionary instructions are taken seriously — state each once.
- **Tentative by default**: More likely to ask when additional input could materially change the result, and asks non-blocking questions while working. This can stop work where the user expected reasonable assumptions and persistence.
- **Early review stops**: May reach a first implementation and come back for review while work remains. Put running, inspecting, and fixing inside the definition of done.
- **Detailed, formatted output**: Tends toward detailed, formatted responses and may use recurring phrases across sessions. Specify writing style and structure.
- **Tests on its own**: Runs tests without prompting — carried-over "always run tests" nudges produce unnecessary testing.
- **Under-delegates**: May parallelize through subagents less than you want. Say when delegation is expected.
- **Legacy-prompt penalty**: Process-heavy stacks and prescriptive skills narrow the search space and cause early pauses.
</context>

## Lean Prompting

Trim iteratively — one group of instructions, examples, skills, or tools at a time — validating against evals after each cut.

**Remove**: duplicate statements of the same rule; style/process guidance and examples that don't change behavior in evals; process instructions for behaviors the model already does reliably (testing, persistence scaffolding); cautionary "ask first" and "stop for review" language on safe work; out-of-scope tools.

**Preserve**: user-visible outcomes, success criteria, and the definition of done; safety, business, evidence, and permission constraints; context-dependent tool-routing rules; required output schemas and writing-style contracts.

## Suggested Prompt Structure

Keep each section short; add detail only where it changes behavior.

```
Role: [1-2 sentences defining the model's function, context, and job]
# Personality: [tone plus collaboration style: when to assume vs ask, how it checks work]
# Goal: [user-visible outcome]
# Success criteria: [what must be true before the final answer, including running and checking the result]
# Constraints: [policy, safety, business, evidence, side-effect limits]
# Tools: [which tools to use, when, and what not to use]
# Output: [format, writing style, and a quantitative length bound]
# Stop rules: [when to retry, fall back, abstain, ask, or stop]
```

Describe personality through specific writing choices (warmth, directness, formality), not labels like "friendly".

## Outcome-First Prompting

Describe what "good" looks like; let the model choose the tool, search, or reasoning strategy. OpenAI's framing: "Give it the sources, templates, constraints, and checks that define a useful result."

```
Resolve the customer's issue end to end.

Success means:
- the eligibility decision is made from available policy and account data
- any allowed action is completed before responding
- the final answer includes completed_actions, customer_message, and blockers
- if evidence is missing, ask for the smallest missing field
```

**Define "done" before starting.** Astra may return for review after a first implementation. If the task includes getting the implementation running, inspecting the result, and fixing what fails, make that part of the request. A requirement to stop for review after the first implementation pulls the model toward an earlier stopping point.

For lists, batches, and paginated work, require tracked coverage: the task is incomplete until every item is covered or marked `[blocked]` with what is missing.

**Reserve absolute rules for invariants.** Use `ALWAYS`, `NEVER`, `must`, and `only` for safety rules, required output fields, or actions that must never happen. For judgment calls, prefer decision rules — replace `"ALWAYS search the web before answering"` with `"Search the web when the question names a specific product, person, date, version, or figure; otherwise answer from context."`

## Reasoning Effort — Prompt Implications

| Model | Levels | Starting point |
|---|---|---|
| Astra | `low`, `medium`, `high`, `xhigh`, `max` — no `none` | Default undocumented, so pin it; Codex suggests starting at `low` |
| Sol | `none` through `max`, default `medium` | Codex suggests `medium` |
| Luna | `none` through `max`, default `medium` | Codex suggests `high` |

- **Levels don't map exactly between generations.** Try a familiar task at a lower setting than you used on GPT-5.6 before assuming the old level carries over.
- **Astra's lowest level is `low`.** Where old prompts relied on `none` or `minimal`, start Astra at `low`.
- **Fix the prompt before raising effort.** Check for a missing success criterion, definition of done, routing rule, or verification loop first; escalate only when evals show a gap the prompt cannot close.
- **Reserve `max`** for the hardest quality-first workloads, never as a global default.
- **Latency**: "For faster time to first visible token in latency-sensitive applications, ask the model to generate a short preamble before continuing with deeper reasoning."

## Autonomy, Persistence, and Approval

Astra's typical failure is stopping too early, not overreaching. Three snippets from OpenAI's guide address it.

Bias to action and persistence:
```
You should infer the user's intent and task scope from the instructions and prior conversation context. Your job is to bias towards action and carry the user's intended task to completion.

When the user expresses intent to perform new work or fix an existing issue, persist until the user's intended goal is complete. Progress autonomously towards the user's goal (e.g. creating isolated worktrees / checkouts if needed, resolving merge conflicts, read-only actions, creating draft PRs etc.) unless they are clearly destructive or irreversible.
```

Treat "can you…" as a request:
```
When the user's prompt indicates a request for action, such as "can you...", "I want to...", "help me..." and similar expressions, treat these as instructions to do the work and take action. Do not stop at acknowledging capability (e.g. "Yes…"), proposing a plan, or offering to continue. Do not settle for a partial or "helpful enough" solution that does not fully satisfy the user's task to save time, effort or tokens. If a task requires sustained work, complete all the necessary work until the intended outcome is fulfilled.
```

Ask for approval only on a concrete result:
```
Before asking the user clarifying questions, you should complete the work that is already authorized from context and necessary to make the proposed action concrete and reviewable. The user should be approving a concrete, reviewable result. For example, before deploying a change, writing to an external application, merging a PR or publishing a site, do all the required work first so that user approval is the final step. You don't need user permission for reversible tasks, read-only actions, reviews or fixes, or anything for which authorization is provided earlier in the session or strongly implied from the task instruction.

Do not introduce unsolicited warnings, disclaimers, approval flows, or safety/compliance checklists due to hypothetical risk.
```

**Audit carried-over "ask first" language.** Repetitive "ask first" language creates approval pauses on work that was already safe, and Astra "could take it too seriously and may stop work where you'd actually be happy for it to continue." GPT-5.6-era boundaries such as "require confirmation for scope expansion beyond the request" are a common trigger. Keep confirmation for destructive, irreversible, and external actions, stated once. Where a workflow is safe, grant permission for it explicitly — OpenAI's AGENTS.md example:
```
The local tests use disposable fixtures and have no production access. Run them, fix failures caused by the requested change, and rerun affected tests without asking for approval at each step.
```

**Ambiguity**: default to labeled assumptions; ask a blocking question only when picking the wrong interpretation would be costly. If the host gives the model a non-blocking way to ask the user, instruct it to continue independent work after asking and to wait for the answer only before a step that depends on it.

## Writing Style

Astra tends toward detailed, formatted responses. Specify the style you want rather than relying on defaults. OpenAI's writing-style snippet:
```
Default to using clear, concise paragraphs, each developing one main idea. Use lists only when the information is genuinely parallel, sequential, or easier to compare, and avoid nested lists unless the hierarchy cannot be expressed clearly in prose. Use plain, simple language: familiar words, concrete examples, and precise verbs. Prefer active voice and direct statements.

Make sure to state the main point clearly and early, then develop it with the explanation and detail the reader needs. Let each sentence build on what came before. Develop the points that matter and provide enough support to be useful.
```

For technical communication:
```
Use plain language over jargon, and reference technical details only to the degree that it helps illustrate an idea or your work to the user. Communicate complex concepts in a clear and cohesive manner, and calibrate your writing to the level of background knowledge assumed from the user's prompt and context.
```

Astra may reuse recurring phrases across sessions. To suppress stock phrasing:
```
Avoid using slop words or phrases like "Bottom Line:" in conclusions, "delve," "foster," "leverage," "it's worth noting," "importantly," "Question? Answer." or "This isn't about X. It's about Y.", "genuinely" or hyphenated compound descriptions and adjectives. Do not use concluding summary statements such as "In short:..", "The simplest mental model is:...".

State the intended action directly. Avoid adding what you won't do, what will remain unchanged, or how you'll separate or categorize results. Do not use contrastive framing such as "X, not Y" or "X—not Y" that introduces an unprompted alternative that the user didn't ask about. Avoid invented compound labels like "exact-head checks" and "editorial-row layouts", vague qualifiers, and canned transitions; use plain verbs and prepositions to state the actual relationship directly.
```

A host verbosity setting, where available, sets the default detail level; the Output section still states format and a quantitative length bound ("3-6 sentences", "under 400 words"). For editing, rewriting, or summarizing: preserve the requested artifact, length, structure, genre, and factual claims; improve clarity without adding claims or sections.

## Skills and AGENTS.md

Astra is more sensitive to instructions in skills, and unclear or conflicting skill guidance may cause it to pause and block work early. OpenAI strongly recommends auditing skills and other files accessible to the model for instructions that could influence its behavior.

State precedence explicitly:
```
The user's instructions take precedence over guidelines provided in a skill. If explicit user instructions conflict with a skill's instructions, prioritize the user's instructions.
```

Make skill-caused pauses traceable:
```
If a skill causes you to ask for permission or confirmation, pause, leave requested work unfinished, or diverge from the user's intent, name and link to the exact SKILL.md file you read, quote the relevant instruction, and briefly explain how it applies. Distinguish explicit skill requirements from your interpretation of guidelines.
```

Skill hygiene:
- **Short descriptions.** Keep descriptions as short as possible while making it clear when to use the skill — Codex truncates them when many skills are loaded. Bad: "…Use when working with databases, queries, models, or persistence." Good: "…Use when adding or changing a migration, or reviewing its rollout."
- **Minimal root file.** Make SKILL.md or AGENTS.md a minimal router that points to supporting docs and scripts. Avoid elaborate itineraries or recipes.
- **Point to docs by context.** Bad: "Before every edit, read architecture.md, database.md, and deployment.md." Good: "Use architecture.md for service boundaries, database.md for schema changes, and deployment.md when preparing a deployment."

## Subagents

Astra may delegate less than you want. Encourage parallelization:
```
If at any point you can parallelize work by delegating tasks to another agent (no matter if you are the root or subagent), you should do so using collaboration tools if it could save time or improve quality.
```

Keep inter-agent messages readable:
```
Messages that you send to other agents and your final answer may be read by a human, so ensure they are legible. Always put proper spaces between words and/or numbers.
```

## Tool Routing

- **Expose only task-relevant tools.** Descriptions state purpose, when to use it, key return fields, and error behavior in 1-2 sentences.
- **Make prerequisite retrieval explicit** when correctness depends on it: "Read the current config before proposing changes."
- **Parallelize independent reads**; keep work sequential when one result determines the next call.
- **Empty-result recovery**: on empty, partial, or suspiciously narrow results, require 1-2 meaningful fallbacks (alternate wording, broader filters, prerequisite lookup) before concluding "no results", reported with what was tried.
- **Strict tool schemas** where the host supports them: no extra properties, every property required, nullable types for optional fields.

### Programmatic Tool Calling

Where the model can run code that orchestrates tool calls, route through code when the workflow is bounded and deterministic: filtering, joining, sorting, deduplication, and aggregation across many records; batching similar calls; reducing large intermediate results to a compact shape.

Keep direct tool calls when one call suffices, when each result may change the next decision, when the action requires approval, or when the final answer must preserve citations or artifacts. If a task needs both routes, define one handoff point so the model doesn't switch mid-task or repeat work. Test both the program output and the final message — correct records can still arrive with required fields or caveats missing.

## Progress Updates

Before the first tool call on multi-step work, have the model send 1-2 user-visible sentences acknowledging the request and stating the first step. After that, brief updates only when a major phase begins or a finding changes the plan — one concrete outcome plus the next step. Keep update rules separate from the final answer's format and length contract, and keep the reusable prompt prefix stable across turns — churn in large system prompts defeats caching.

## Grounding, Citations, and Retrieval Budget

Define what needs support, what counts as sufficient evidence, and what to do when evidence is missing. Absence of evidence is not a factual "no" — instruct the model to narrow the answer or report the gap.

```
<retrieval_budget>
Start with one broad search using short, discriminative keywords. If the top
results contain enough citable support for the core request, answer from them.

Search again only when: a required fact, parameter, owner, date, or ID is
missing; the user asked for exhaustive coverage or a comparison; a specific
document or artifact must be read; or the answer would otherwise contain an
important unsupported claim.

Do not search again to improve phrasing, add examples, or support wording that
can safely be made more generic.
</retrieval_budget>
```

Citation rules: cite only sources retrieved in the current workflow, never fabricating citations, URLs, IDs, or locators; attach citations to the claims they support; label inference separately from supported facts; state source conflicts rather than resolving them silently; if the host renders inline citation markers, emit one per source in exactly the host's format.

For creative drafting (slides, launch copy), use retrieved or provided facts for concrete product, metric, date, and customer claims; never invent specifics — write a generic draft with placeholders or labeled assumptions instead.

## Validation and Testing

Astra tests on its own; the risk is over-testing, not under-testing. Replace GPT-5.6-era "run the most relevant check" nudges with:
```
Do not write tests for reversible, low-impact changes that mirror the implementation. If you do choose to verify your work with tests, make sure that the tests are meaningful and necessary to verify implementation.

Run tests appropriate to the change and complete required checks. Once those pass, broaden or repeat testing only when new changes, failures, or unresolved concerns justify it; otherwise, continue toward completing the task.
```

**Give the model ways to inspect its own work.** Astra does well with a loop to reproduce a problem, inspect screenshots and state, trace the relevant code, make a change, and rerun the check. Provide the tools that loop needs (renderer, screenshots, logs, a runnable build). For visual artifacts, require rendering and inspecting layout, clipping, spacing, and missing content before finalizing. For implementation plans, require requirements mapped to where each is addressed, named files/APIs/systems, data flow, validation checks, failure behavior, and open questions that materially affect implementation.

## Structured Extraction

Prefer host-enforced strict schemas over format prompts. When the contract lives in the prompt, include the schema inline, require exact adherence with no extra fields, and set missing fields to `null` rather than guessing; re-scan the source for missed fields before returning. For multi-document extraction, key per-document results with a stable ID (filename, title, page range). For layout-aware extraction, specify the coordinate format exactly and process dense layouts page by page with a second pass.

## Frontend and Visual Tasks

Constrain design work; don't script it:
```
<design_constraints>
- Inspect and preserve the existing design system: tokens, components, patterns.
- Implement exactly what was requested — no extra features or decorative UI.
- Preserve responsive behavior and expected states (loading, error, empty).
- Render and inspect the result before finalizing.
</design_constraints>
```

For net-new design with no system, specify a concrete direction (palette hexes, typeface, radii, spacing) or have the model propose 3-4 distinct directions and build only the one picked.

For vision, computer-use, or OCR tasks needing spatial precision, choose image detail intentionally — use original detail for large, dense, or coordinate-sensitive images when the extra input cost is justified.

## Migration

Isolate one variable at a time — never rewrite a working prompt in the same step as a model switch. Switch the model, pin reasoning effort explicitly, run representative evals, then make the smallest targeted edit that fixes each measured regression. To debug: collect a few real failing traces, find the instruction or contradiction causing the failure, make one surgical edit, and re-run the same cases.

### From GPT-5.6

- [ ] Pin reasoning effort. On Astra, move `none`/`minimal` routes to `low`; test a familiar task at a lower level than the GPT-5.6 setting.
- [ ] Remove blanket brevity reliance — Astra defaults to detailed, formatted output. Add the writing-style snippet and state format and length in the Output section.
- [ ] Replace "proactive by default" assumptions with the bias-to-action, "can you…", and concrete-approval snippets.
- [ ] Remove "ask first", "stop for review after the first implementation", and "confirm scope expansion" language on safe work; grant explicit permission for safe workflows.
- [ ] Put running, inspecting, and fixing the result inside the definition of done.
- [ ] Replace "always run tests" / "run the most relevant check" nudges with the testing snippet.
- [ ] Audit skills and AGENTS.md: short descriptions, minimal router files, docs referenced by context, user-over-skill precedence, and the name-the-skill instruction.
- [ ] Add delegation encouragement and the legible-messages instruction for multi-agent setups.
- [ ] Keep: outcome-first structure, retrieval budget, citation rules, tool routing, PTC routing, design constraints.

### From older models

- **GPT-5.5 / GPT-5.4 / GPT-5.3-Codex**: run the lean-prompting pass first — these prompts carry the most process scaffolding and tool-persistence blocks — then apply the GPT-5.6 checklist.
- **GPT-4o / GPT-4.1**: remove defensive prompting, start Astra at `low`, add an output contract only if outputs drift, and add approval boundaries for agentic use.

## Anti-Patterns

- **Stating an instruction more than once** — Astra follows instructions closely; duplicates and conflicts destabilize behavior.
- **Not specifying writing style** — Astra defaults to lists, tables, and Markdown with recurring phrases.
- **Leaving old "ask first" or "always run tests" nudges** — cause early pauses and unnecessary testing.
- **Stop-for-review requirements after a first implementation** — pull the model toward an earlier stopping point.
- **Unaudited or prescriptive skills** — conflicting skill guidance blocks work early; long descriptions get truncated.
- **Raising effort before fixing the prompt** — add the missing success criterion, routing rule, or verification loop first.
- **`max` effort (or pro mode, where available) as a global default** — reserve for the hardest quality-first workloads.
- **Routing judgment-dependent workflows through programmatic tool calling** — code paths hide semantic decisions and drop citations.
- **Inventing figures, citations, or references** — narrow the answer or report the gap.
- **Scripting layout steps for UI work** — constrain to the design system instead.
- **Churning the system-prompt prefix** — defeats caching on long-running agents.

## Quality Checklist

The easy-to-forget items:

- [ ] Reasoning effort pinned explicitly — Astra has no `none` and an undocumented default
- [ ] Every instruction stated exactly once across system prompt, tool descriptions, skills, and AGENTS.md
- [ ] Writing style and structure specified; Output section states format and a quantitative length bound
- [ ] Definition of done includes running, inspecting, and fixing the result where relevant
- [ ] Approval limited to destructive, irreversible, or external actions; safe workflows explicitly permitted
- [ ] No leftover "ask first", "stop for review", or "always run tests" nudges
- [ ] Skills and AGENTS.md audited; user-over-skill precedence stated
- [ ] Delegation guidance present for multi-agent setups
- [ ] Retrieval budget and empty-result recovery set for search-enabled flows
- [ ] PTC vs direct-call routing defined with a single handoff for hybrid workflows
- [ ] Prompt tested unchanged after the model switch, before any re-engineering

## Reference

- Using GPT-6 (latest model guide): https://developers.openai.com/api/docs/guides/latest-model
- Rethinking skills and prompts for GPT-6 Astra: https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra
- Reasoning models: https://developers.openai.com/api/docs/guides/reasoning
- Codex models: https://developers.openai.com/codex/models
- How to build games with Astra: https://developers.openai.com/blog/how-to-build-games-with-astra
