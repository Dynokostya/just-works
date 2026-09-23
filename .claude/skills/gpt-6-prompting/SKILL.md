---
name: gpt-5-6-prompting
description: Apply when creating or editing prompts targeting GPT-5.6 (gpt-5.6-sol, gpt-5.6-terra, gpt-5.6-luna). Covers lean prompting, outcome-first structure, reasoning-effort calibration (none through max), verbosity tuning, autonomy and approval boundaries, tool routing, programmatic tool calling, preamble and phase patterns, persisted-reasoning state, retrieval budgets, citation discipline, validation contracts, frontend prompting, and migration from GPT-5.5, GPT-5.4, GPT-5.3-Codex, or older GPT models.
---

# GPT-5.6 Prompt Writing Guidelines

## When to Use

- Creating or editing prompts targeting GPT-5.6 (any variant: `gpt-5.6-sol`, `gpt-5.6-terra`, `gpt-5.6-luna`)
- Calibrating reasoning effort, verbosity, autonomy boundaries, and tool routing for GPT-5.6 workloads
- Migrating prompt text from GPT-5.5, GPT-5.4, GPT-5.3-Codex, or older GPT models
- Diagnosing 5.6-specific behaviors (concise-by-default output, instruction-conflict instability, `medium` default reasoning, proactive multi-step execution)

## Overview

GPT-5.6 is OpenAI's frontier family. `gpt-5.6-sol` is the flagship (the bare `gpt-5.6` alias routes to it); `gpt-5.6-terra` balances cost; `gpt-5.6-luna` targets high-volume efficiency. Sol and Terra run ~1.05M-token context with 128K max output; Luna runs 400K context, 128K max output.

Compared with GPT-5.5, it reaches frontier performance with fewer output tokens, is more concise by default, follows prompt contracts more tightly (so conflicting instructions create instability), executes multi-step work more proactively, and has stronger layout and design judgment. New capabilities relevant to prompt design: programmatic tool calling, persisted reasoning across turns, pro mode for quality-first work, and multi-agent coordination (beta).

The core discipline is lean prompting: OpenAI measured 10-15% eval-score improvement with 41-66% token reduction from pruning prompts — GPT-5.6 rewards removing scaffolding more than adding it.

<context>
Key behavioral characteristics to design prompts around:

- **Outcome-first**: Strongest when the prompt defines destination, constraints, evidence, and completion bar, then leaves the path to the model.
- **Tight contract-following**: Follows prompt contracts closely; duplicated or conflicting instructions destabilize behavior. State each instruction once.
- **Concise by default**: More concise than GPT-5.5 — carried-over brevity blocks can now cut content you need. Define what brief answers must include.
- **Proactive and persistent**: Carries multi-step tasks forward on its own; needs approval boundaries, not step-by-step supervision.
- **Strong planning over tools**: Needs less fallback and invocation scaffolding than 5.5; still benefits from explicit prerequisite-retrieval and routing rules.
- **Stronger design judgment**: Better layout, hierarchy, and visual taste — constrain it to the existing design system rather than prescribing layout steps.
- **Legacy-prompt penalty**: Process-heavy stacks carried from older models narrow the search space and waste tokens.
</context>

## Lean Prompting

Trim iteratively — one group of instructions, examples, or tools at a time — validating against evals after each cut.

Remove:
- Duplicate statements of the same rule (state each instruction once)
- Style/process guidance that doesn't change behavior in evals
- Examples that don't alter behavior
- Process instructions for behaviors the model already does reliably
- Tools out of scope for the task (expose only what the task needs)

Preserve:
- User-visible outcomes, success criteria, and stopping conditions
- Safety, business, evidence, and permission constraints
- Context-dependent tool-routing rules
- Required output schemas and validation requirements

## Suggested Prompt Structure

8-section layout for complex prompts. Keep each section short; add detail only where it changes behavior.

```
Role: [1-2 sentences defining the model's function, context, and job]

# Personality
[tone plus collaboration style: when to ask vs assume, how it checks work]

# Goal
[user-visible outcome]

# Success criteria
[what must be true before the final answer]

# Constraints
[policy, safety, business, evidence, side-effect limits]

# Tools
[which tools to use, when, and what not to use]

# Output
[format, sections, tone, and a quantitative length bound]

# Stop rules
[when to retry, fallback, abstain, ask, or stop]
```

Keep personality short — describe specific writing choices (warmth, directness, formality, humor), not labels like "friendly". Collaboration style covers when the model asks questions, makes assumptions, checks work, and handles uncertainty.

## Outcome-First Prompting

Describe what "good" looks like; let the model choose the tool, search, or reasoning strategy.

```
Resolve the customer's issue end to end.

Success means:
- the eligibility decision is made from available policy and account data
- any allowed action is completed before responding
- the final answer includes completed_actions, customer_message, and blockers
- if evidence is missing, ask for the smallest missing field
```

Add stopping conditions that prevent over-iteration. For lists, batches, and paginated work, require tracked coverage: treat the task as incomplete until every requested item is covered or explicitly marked `[blocked]` with what is missing.

**Reserve absolute rules for invariants.** Use `ALWAYS`, `NEVER`, `must`, and `only` for safety rules, required output fields, or actions that must never happen. For judgment calls, prefer decision rules — replace `"ALWAYS search the web before answering"` with `"Search the web when the question names a specific product, person, date, version, or figure; otherwise answer from context."`

## Reasoning Effort Calibration

GPT-5.6 supports six levels: `none`, `low`, `medium`, `high`, `xhigh`, `max`. The default is `medium` when unset. `none` returns (absent on GPT-5.5) as the no-reasoning baseline; `max` is new — reserve it for the hardest quality-first workloads, never as a global default. Pro mode exists as a separate quality-first execution mode independent of effort; prefer it over `max`-everywhere for offline work where quality dominates.

**Baseline before changing.** Preserve the source model's reasoning effort as the baseline, then test the same setting and one level lower on representative tasks — GPT-5.6 frequently holds quality one level down, converting directly to latency and cost savings.

**Engineer the prompt before escalating.** Before raising effort, check whether the prompt is missing a success criterion, dependency rule, tool-routing rule, or verification loop. Only escalate when evals show a gap the prompt cannot close.

| Task profile | Start at |
|---|---|
| Latency-sensitive Q&A, high-volume classification | `low` (test `none` where no tool reasoning is needed) |
| General production workflows, default | `medium` |
| Complex debugging, multi-step tool workflows | `medium`, escalate to `high` on eval gaps |
| Deep research, long agentic traces | `high`, `xhigh` for offline/async |
| Hardest quality-first workloads | `max` or pro mode |

### Effort Migration Mapping

| Current Model + Effort | Target (GPT-5.6) |
|---|---|
| GPT-5.5 @ any effort | same level as baseline, then test one lower |
| GPT-5.4 @ `none` / `minimal` | `none` |
| GPT-5.4 @ `low`-`xhigh` | same level as baseline, then test one lower |
| GPT-5.3-Codex @ any effort | same level as baseline, then test one lower |
| GPT-4o / GPT-4.1 (no effort param) | `none` or `low` |
| GPT-5.5-pro workloads | pro mode |

## Verbosity

GPT-5.6 is more concise by default than GPT-5.5. Two consequences:

- **Re-validate carried-over brevity blocks.** "Be concise" scaffolding written for 5.5 can now cut content you need. Remove blanket brevity instructions unless evals show they still earn their place.
- **Define what brief answers must include**: conclusions, supporting evidence, material caveats, next actions. List what may be omitted (secondary detail, repetition, generic reassurance) rather than capping length alone.

Use the host verbosity control (`text.verbosity`: `low` / `medium` / `high`) as the first lever for default detail level — it sets defaults, not task contracts. Every prompt's Output section still states the output format (JSON / Markdown / prose / code) and a quantitative length bound per user-facing section; quantitative constraints ("3-6 sentences", "under 400 words") outperform qualitative ones.

For editing / rewriting / summarizing: preserve the requested artifact, length, structure, genre, and factual claims first; improve clarity, flow, and correctness without adding new claims or sections.

## Autonomy and Approval Boundaries

GPT-5.6 is proactive and persistent on multi-step work. Define what each request type authorizes — once, in one place. Repetitive "ask first" language paradoxically creates approval pauses on work that was already safe.

```
<approval_boundaries>
- For answer/explain/review/diagnose requests: inspect materials, report results;
  do not implement changes unless asked.
- For change/build/fix requests: make in-scope local changes and run
  non-destructive validation without asking.
- Safe local actions never need approval: reading files, inspecting logs,
  editing code in scope, running tests.
- Require confirmation for: external writes, destructive actions, purchases,
  and scope expansion beyond the request.
</approval_boundaries>
```

For long-running work, name the current work layer (research, design, implementation, review, external coordination) so the model doesn't silently escalate from one to the next.

For genuine ambiguity: present 2-3 plausible interpretations with labeled assumptions by default; ask a blocking question only when picking the wrong branch would be costly.

## Tool Routing and Descriptions

- **Expose only task-relevant tools.** Descriptions state purpose, when to use it, key return fields, and error behavior — 1-2 sentences.
- **Make prerequisite retrieval explicit** when correctness depends on it: "Read the current config before proposing changes" — GPT-5.6 may otherwise skip discovery steps when the end state seems obvious.
- **Parallelize independent reads**; keep work sequential when one result determines the next call.
- **Empty-result recovery**: on empty, partial, or suspiciously narrow results, require 1-2 meaningful fallbacks (alternate wording, broader filters, prerequisite lookup) before concluding "no results", reported with what was tried.
- **Prefer strict schemas** where the host supports them: forbid extra properties, mark every property required (use `["string", "null"]` for optional fields).

GPT-5.6 plans well over large tool surfaces — the verbose invocation scaffolding GPT-5.5 needed (persistence blocks, detailed fallback ladders) can usually shrink to the rules above.

## Programmatic Tool Calling

GPT-5.6 can execute code that orchestrates tool calls in a hosted runtime. Prompt-design guidance:

Route through code when the workflow is bounded and deterministic:
- Filtering, joining, sorting, ranking, deduplication, aggregation across many records
- Batching many similar calls; repeated deterministic validation
- Reducing large intermediate results to a compact schema

Keep direct tool calls when:
- One call suffices, or intermediate outputs are already small
- Each result may change the next decision (semantic judgment between calls)
- The action requires approval, or the final answer must preserve citations or artifacts

If a task needs both routes, define one clear handoff point — do not let the model switch routes mid-task or repeat work across them. Test both the program output and the final assistant message: a program can return correct records while the message omits required fields or caveats.

## Long-Running Work: Preamble, Updates, State

**Preamble**: before the first tool call on multi-step work, send 1-2 user-visible sentences acknowledging the request and stating the first step.

**Updates**: after the preamble, brief updates only when a major phase begins or a finding changes the plan — one concrete outcome plus the next step. No narration of routine tool calls.

**Phase discipline**: assistant messages carry a `phase` value — `"commentary"` (progress updates) vs `"final_answer"` (the deliverable). Keep the two distinct in prompt instructions: preamble/update rules govern commentary; format, schema, and length contracts govern the final answer. When replaying conversation history manually, preserve each message's original phase value; hosts that persist state across turns handle this automatically.

**Persisted reasoning**: useful when the objective, assumptions, and priorities stay stable across turns. When earlier reasoning is stale (pivoted objective, invalidated assumptions), prefer fresh current-turn reasoning — stale reasoning adds tokens and anchors the model to outdated approaches.

**Compaction and caching**: compact after major milestones rather than every turn, keep the prompt functionally consistent after compaction, and keep reusable prompt prefixes stable — churn in large system prompts defeats caching.

## Grounding, Citations, and Retrieval Budget

Define what needs support, what counts as sufficient evidence, and what to do when evidence is missing. Absence of evidence is not a factual "no" — instruct the model to narrow the answer or report the gap instead of guessing.

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

Citation rules — lock citations to retrieved sources:
- Cite only sources retrieved in the current workflow; never fabricate citations, URLs, IDs, or locators.
- Attach citations to the claims they support, not only at the end; label inference separately from directly supported facts; state source conflicts rather than resolving them silently.
- If the host renders inline citation markers (e.g. Unicode markers like `<ZWSP>cite<ZWSP>` where `<ZWSP>` stands for the invisible U+200B), emit one marker per source, in exactly the host's format.

For research and synthesis, scope is query coverage: cover plausible user intents rather than expanding into tangential topics, and keep the answer within the requested length even when more material was retrieved.

For creative drafting (slides, launch copy, narrative framing): use retrieved or provided facts for concrete product, metric, date, roadmap, and customer claims; never invent specifics to make the draft sound stronger — write a useful generic draft with placeholders or labeled assumptions instead.

## Validation Contracts

State what validation matters before finishing, and give the model access to the tools that run it.

- **Coding**: after changes, run the most relevant check available — targeted tests for changed behavior, type/lint checks, build checks for affected packages, or a minimal smoke test. If validation cannot run, explain why and name the next-best check.
- **Visual artifacts**: render before finalizing; inspect layout, clipping, spacing, missing content; revise until the rendered output matches requirements.
- **Implementation plans**: cover requirements and where each is addressed, named files/APIs/systems, state transitions or data flow, validation checks, failure behavior, privacy/security considerations, and open questions that materially affect implementation.

GPT-5.6 iterates well — validation instructions can be this concise without losing thoroughness.

## Structured Extraction

Prefer host-enforced strict schemas over format prompts. When encoding the contract in the prompt, include the schema inline, require exact adherence with no extra fields, and set missing fields to `null` rather than guessing; re-scan the source for missed fields before returning. For multi-document extraction, serialize per-document results with a stable ID (filename, title, page range). For layout-aware extraction, specify the coordinate format exactly and process dense layouts page by page with a second pass.

## Frontend and Visual Tasks

GPT-5.6 has stronger layout, visual hierarchy, and design judgment than 5.5 — constrain it, don't script it:

```
<design_constraints>
- Inspect and preserve the existing design system: tokens, components, patterns.
- Implement exactly what was requested — no extra features or decorative UI.
- Preserve responsive behavior and expected states (loading, error, empty).
- Render and inspect the result before finalizing.
</design_constraints>
```

For net-new design where no system exists, either specify a concrete direction (palette hexes, typeface, radii, spacing) or have the model propose 3-4 distinct visual directions and build only the one picked.

For vision, computer-use, localization, or OCR tasks needing spatial precision, choose image detail intentionally — use original detail for large, dense, or coordinate-sensitive images when the extra input cost is justified.

## Migration Guide

Isolate one variable at a time — never rewrite a working prompt in the same step as a model switch:

1. **Switch the model string, preserve the current reasoning effort.** Pin it explicitly — GPT-5.6 defaults to `medium` when unset, which silently changes cost and latency for prompts that relied on 5.4-era `none`.
2. **Run representative evals before touching the prompt.**
3. **Remove obsolete scaffolding**: repeated instructions, brevity blocks, verbose tool-invocation guidance, non-behavioral examples, out-of-scope tools.
4. **Test one effort level lower** than baseline on representative tasks.
5. **Add only the smallest targeted instruction that fixes a measured regression**, re-running evals after each change.

To debug a regression: collect a small set of real failing traces, identify the failure mode, find the instruction or contradiction causing it, make one surgical edit, re-run the same cases.

Compare four configurations when validating: original model + prompt; GPT-5.6 + same prompt + preserved effort; GPT-5.6 + same prompt + one lower effort; GPT-5.6 + minimal fixes. Measure success rate, latency, tokens, cost, tool-choice quality, and schema validity.

**From GPT-5.5**: the structural patterns carry over (outcome-first, retrieval budget, phase discipline, validation contracts). Prune: brevity blocks (5.6 is already concise), tool-persistence scaffolding, repeated rules. Add: approval boundaries, one-level-lower effort test. Replace `gpt-5.5-pro` routing with pro mode.

**From GPT-5.4 / GPT-5.3-Codex**: pin effort explicitly first (`none` stays available). Then apply the lean-prompting pass — these prompts typically carry the most process scaffolding.

**From GPT-4o / GPT-4.1**: remove defensive prompting; start at `none` or `low`; add an output contract only if outputs drift; add approval boundaries for agentic use.

## Anti-Patterns

- **Stating an instruction more than once** — duplicated rules destabilize contract-following. Consolidate.
- **Carrying 5.5-era brevity blocks** — 5.6 is already concise; blanket "be concise" now cuts needed content. Define what brief answers must include.
- **Repetitive "ask first" language** — creates approval pauses on safe work. One approval-boundaries block, stated once.
- **Generic phrases**: "be brief", "think step by step" — dead weight; reasoning is parameter-controlled and conciseness is default.
- **`max` effort or pro mode as global default** — reserve for the hardest quality-first workloads.
- **Raising effort before engineering the prompt** — add the missing success criterion, routing rule, or verification loop first.
- **Absolute rules on judgment calls** — reserve `ALWAYS`/`NEVER` for invariants; use decision rules for search/ask/iterate choices.
- **Routing judgment-dependent workflows through programmatic tool calling** — code paths hide semantic decisions and drop citations; keep those on direct calls.
- **Letting PTC and direct calls trade the same work back and forth** — define one handoff.
- **Replaying history without phase values** — the model loses the commentary/final-answer distinction.
- **Persisting stale reasoning across a pivot** — anchors the model to the outdated approach; use fresh reasoning when objectives change.
- **Treating empty tool results as final** — require 1-2 fallbacks with a report of what was tried.
- **Inventing figures, citations, or references when evidence is missing** — narrow the answer or report the gap.
- **Scripting layout steps for UI work** — constrain to the design system instead; 5.6's design judgment outperforms step-scripts.
- **Churning the system-prompt prefix** — defeats caching on long-running agents.

## Quality Checklist

The easy-to-forget items:

- [ ] Reasoning effort pinned explicitly — preserved from the source model, then tested one level lower; not silently inherited from the `medium` default
- [ ] Every instruction stated exactly once — no rule appears in both system prompt and tool descriptions
- [ ] Brevity blocks re-validated against 5.6's concise default, with "what brief answers must include" defined
- [ ] Output section states the format and a quantitative length bound — the host verbosity control sets defaults, not task contracts
- [ ] Approval boundaries stated once, with safe local actions named
- [ ] Commentary vs. final-answer phases kept distinct, and phase values preserved on manual history replay
- [ ] Retrieval budget and empty-result recovery set for search-enabled flows
- [ ] PTC vs direct-call routing defined with a single handoff for hybrid workflows
- [ ] Extraction tasks include the exact JSON schema inline, with missing fields set to null rather than guessed
- [ ] Prompt tested unchanged after the model switch, before any re-engineering
