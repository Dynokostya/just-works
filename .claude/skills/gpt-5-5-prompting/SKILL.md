---
name: gpt-5-5-prompting
description: Apply when creating or editing prompts targeting GPT-5.5. Covers outcome-first prompting, reasoning-effort calibration, verbosity tuning, long-context handling, ambiguity management, tool persistence and validation, preamble and phase patterns, retrieval budgets, structured extraction, citation discipline, personality and collaboration style, coding autonomy, frontend prompting, and migration from GPT-5.4 or older GPT models.
---

# GPT-5.5 Prompt Writing Guidelines

## Overview

GPT-5.5 is OpenAI's frontier model (1M context, 128K max output, knowledge cutoff Dec 1, 2025). Compared with GPT-5.4, it defaults to `medium` reasoning (not `none`), takes instructions more literally, defaults to a more concise and task-oriented style, and is stronger at large tool surfaces and long-running agent tasks. Prompting it well means shorter, outcome-first prompts rather than legacy process-heavy stacks.

<context>
Key behavioral characteristics to design prompts around:

- **Outcome-first**: Performs best when you describe the destination, success criteria, constraints, and evidence; avoid prescribing every step.
- **Literal interpretation**: Define success criteria and stopping rules explicitly, especially for tool-heavy or long-running work.
- **Direct default style**: Responses stay focused and avoid conversational padding; customer-facing surfaces need explicit personality.
- **Strong tool selection**: Excels with large tool surfaces and multi-step workflows; still benefits from explicit persistence and retrieval budgets.
- **Steerable formatting**: Highly responsive to verbosity, explicit length, and structure instructions.
- **Conservative grounding bias**: Research mode needs citation and retrieval discipline to stay grounded.
- **Legacy-prompt penalty**: Carrying over process-heavy instructions from older models narrows the search space and produces mechanical answers.
</context>

## Suggested Prompt Structure

Use this 7-section layout as the starting point for complex prompts. Keep each section short and add detail only where it changes behavior.

```
Role: [1-2 sentences defining the model's function, context, and job]

# Personality
[tone, warmth, directness, formality, humor, empathy, polish]

# Collaboration style
[when to ask vs assume, proactivity, how it checks work, handles uncertainty]

# Goal
[user-visible outcome]

# Success criteria
[what must be true before the final answer]

# Constraints
[policy, safety, business, evidence, side-effect limits]

# Output
[sections, length, tone, format]

# Stop rules
[when to retry, fallback, abstain, ask, or stop]
```

## Outcome-First Prompting

GPT-5.5 is strongest when the prompt defines the target, not the path. Describe what "good" looks like; let the model choose the tool, search, or reasoning strategy.

Prefer this:

```
Resolve the customer's issue end to end.

Success means:
- the eligibility decision is made from available policy and account data
- any allowed action is completed before responding
- the final answer includes completed_actions, customer_message, and blockers
- if evidence is missing, ask for the smallest missing field
```

Avoid step-by-step prescriptions unless every step is truly required ("First inspect A, then inspect B, then compare every field, then decide which tool to call...").

**Reserve absolute rules for invariants.** Use `ALWAYS`, `NEVER`, `must`, and `only` for safety rules, required output fields, or actions that must never happen. For judgment calls (when to search, when to ask, when to keep iterating), prefer decision rules — e.g., replace `"ALWAYS search the web before answering"` with `"Search the web when the question names a specific product, person, date, version, or figure; otherwise answer from context."`

## Reasoning Effort Calibration

GPT-5.5 supports four reasoning-effort levels: `low`, `medium`, `high`, `xhigh`. The default is `medium` — the recommended balanced starting point. Values `none` and `minimal`, supported on some earlier GPT-5.x models, are not available on GPT-5.5.

**Engineer the prompt before escalating reasoning.** Before increasing effort, first add success criteria and stopping conditions, tool persistence and validation rules, and a completeness contract. These often recover behavior without added latency and cost. Only escalate when evals show a gap the prompt cannot close.

**Recommended starting points by task profile:**

| Task profile | Start at | Escalate to |
|---|---|---|
| Latency-sensitive Q&A over modest context | `low` | `medium` if quality gap |
| General production workflows, default | `medium` | `high` if evals show gaps |
| Complex debugging, multi-step tool workflows | `medium` | `high` |
| Deep research, long agentic traces | `high` | `xhigh` only for offline/async |
| Async background work where intelligence dominates | `xhigh` | — |

**Prompt implications by effort level.** At lower efforts, prompts should be more explicit about stopping conditions, completeness, and validation; the model has less room to self-correct. At higher efforts, scope constraints matter more because the model will explore further before committing.

Consider `gpt-5.5-pro` for maximum reasoning when latency and cost matter less.

### Effort Migration Mapping

Match the source model's effort unless the prompt has been re-engineered:

| Current Model + Effort | Target (GPT-5.5) | Notes |
|---|---|---|
| GPT-4o / GPT-4.1 (no effort param) | `low` | GPT-5.5 has no `none`; `low` is the snappy-baseline replacement |
| GPT-5 / 5.1 / 5.2 @ `none` or `minimal` | `low` | Re-evaluate `medium` after adding stop rules |
| GPT-5.3-Codex @ any effort | match current, floor at `low` | Preserves coding behavior |
| GPT-5.4 @ `none` / `minimal` | `low` | `low` is the new snappy baseline |
| GPT-5.4 @ `low` / `medium` / `high` / `xhigh` | match current | Preserve prior setting |

## Verbosity

GPT-5.5 is highly steerable on output shape and length. If the host exposes a verbosity control, use it as the first lever (default is `medium`; use `low` for short customer-facing replies and batch classification, `high` for long-form writing where density hurts comprehension). Otherwise, encode length contracts directly in the prompt.

Combine verbosity with explicit section and length contracts:

```
<output_contract>
- Return exactly the sections requested, in the requested order.
- If the prompt defines a preamble, analysis block, or working section, do not treat it as extra output.
- Apply length limits only to the section they are intended for.
- If a format is required (JSON, Markdown, SQL, XML), output only that format.
</output_contract>
```

For plain conversational surfaces, instruct the model to use plain paragraphs as the default and reserve headers, bold, bullets, and numbered lists for when the user requests them or when the information needs clear comparison or ranking.

For editing / rewriting / polishing tasks, tell the model to preserve the requested artifact, length, structure, and genre first; improve clarity and correctness quietly without adding new claims or a more promotional tone.

Quantitative constraints ("3-6 sentences", "under 400 words") outperform qualitative ones ("be concise").

## Scope and Design Constraints

GPT-5.5's literal interpretation plus stronger default brevity means it is less likely to over-engineer than older models, but scope constraints remain important for code and UI work.

For code generation and UI tasks:

```
<design_and_scope_constraints>
- Explore existing design systems deeply before writing any UI.
- Implement EXACTLY and ONLY what the user requests.
- No extra features, no added components, no UX embellishments.
- Style aligned to the existing design system.
- Do not invent colors, shadows, tokens, animations, or UI elements unless requested.
- If any instruction is ambiguous, choose the simplest valid interpretation.
- Avoid generic AI-UI defaults: split hero cards, decorative gradients, orbs,
  nested cards inside cards, visible instructional text on finished screens.
</design_and_scope_constraints>
```

For extraction and data tasks, scope is schema adherence: follow the schema exactly with no extra fields, and set missing fields to null rather than guessing. For research and synthesis tasks, scope is query coverage — cover plausible user intents rather than expanding into tangential topics.

## Long-Context Handling

GPT-5.5 supports a 1M-token context window. Coherence over long sessions is strong, but grounding instructions still improve accuracy on inputs over ~10k tokens:

```
<long_context_handling>
- For inputs longer than ~10k tokens (multi-chapter docs, long threads, multiple PDFs):
  - Produce a short internal outline of key sections relevant to the request.
  - Re-state the user's constraints explicitly before answering.
  - Anchor claims to sections rather than speaking generically.
- If the answer depends on fine details (dates, thresholds, clauses), quote
  or paraphrase them.
</long_context_handling>
```

For the largest contexts (>500k tokens), prefer targeted retrieval into the working window over stuffing the entire corpus; retrieval budgets and per-document IDs stay useful even when the window allows the full payload.

## Ambiguity, Uncertainty, and Follow-Through

Set an explicit follow-through policy so the model proceeds on clear low-risk requests instead of asking permission:

```
<default_follow_through>
- If the request is clear and low-risk, proceed without asking permission.
- Prefer making progress over stopping for clarification when the request is
  already clear enough to attempt; use context and reasonable assumptions.
- Ask for clarification only when the missing information would materially
  change the answer or create meaningful risk.
- Ask before: irreversible actions, external side effects, or operations
  requiring sensitive info not yet provided.
- Preserve earlier instructions that do not conflict with newer ones.
</default_follow_through>
```

For genuine ambiguity and hallucination mitigation:

```
<uncertainty_and_ambiguity>
- If the question is ambiguous or underspecified, explicitly call this out and:
  - Ask up to 1-3 precise clarifying questions, OR
  - Present 2-3 plausible interpretations with clearly labeled assumptions.
- When external facts may have changed recently and no tools are available:
  - Answer in general terms and state that details may have changed.
- Never fabricate exact figures, line numbers, or external references when uncertain.
- When unsure, prefer language like "Based on the provided context..." instead of absolute claims.
</uncertainty_and_ambiguity>
```

For high-stakes domains (legal, finance, compliance, safety), add a self-check before finalizing: re-scan the answer for unstated assumptions, specific numbers not grounded in context, and overly strong language ("always", "guaranteed"); soften or qualify and explicitly state assumptions.

## Preamble Patterns

For streaming or tool-heavy tasks, prompt a short visible acknowledgment (1-2 sentences) before the model starts thinking or calling tools. This improves perceived time-to-first-token without changing the work. Example: `"Before any tool calls for a multi-step task, send a short user-visible update that acknowledges the request and states your first step. Keep it to one or two sentences."` For coding agents that expose separate message channels, require the preamble to appear before any content in the analysis channel.

## Phase Discipline

GPT-5.5 assistant messages carry a `phase` value that distinguishes intermediate updates from final answers. When writing prompts that shape multi-message responses, treat these as two distinct message categories:

- `phase: "commentary"` — intermediate user-visible updates (preambles, progress notes, brief milestone reports). Concise, informational, no final content.
- `phase: "final_answer"` — the completed answer. Full output, matches the requested format and schema.

Prompt implications:
- Preamble instructions produce commentary messages; keep them short (1-2 sentences) and task-progress oriented.
- Final-answer instructions should define format, schema, and length independently of preamble length.
- Do not conflate the two in a single instruction: make clear which content is user-visible progress vs. the final deliverable.

## Tool Persistence and Usage

For agentic prompts, instruct the model not to stop early and to retry on empty or partial results:

```
<tool_persistence_rules>
- Use tools whenever they materially improve correctness, completeness, or grounding.
- Do not stop early when another tool call is likely to materially improve correctness.
- Keep calling tools until (1) the task is complete, and (2) verification passes.
- If a tool returns empty or partial results, retry with a different strategy.
</tool_persistence_rules>
```

```
<tool_usage_rules>
- Prefer tools over internal knowledge whenever:
  - You need fresh or user-specific data (tickets, orders, configs, logs).
  - You reference specific IDs, URLs, or document titles.
- Parallelize independent reads when possible to reduce latency.
- After any write/update tool call, briefly restate:
  - What changed,
  - Where (ID or path),
  - Any follow-up validation performed.
</tool_usage_rules>
```

### Tool Description Guidance

- **Describe tools crisply** in 1-2 sentences. Verbose descriptions waste context without improving selection.
- **Encourage parallelism** for independent reads over codebases, vector stores, and multi-entity operations.
- **Require verification** for high-impact operations (orders, billing, infrastructure). Add the verification step in the tool description or system prompt.
- **Keep the initial tool set small.** Aim for fewer than 20 tools at conversation start; defer rarely-used tools behind allow-lists or tool-search when available.
- **Prefer strict schemas** when the host supports them: forbid extra properties and mark every property required (use `["string", "null"]` for optional fields). This keeps tool arguments reliable without prompt-level cleanup.

## Validation Contracts

GPT-5.5 responds well to concrete validation-command instructions. Replace vague "verify correctness" prompts with runnable checks.

For coding agents, instruct the model to run the most relevant validation available after changes: targeted unit tests, type or lint checks, build checks for affected packages, or a minimal smoke test when full validation is too expensive. If validation cannot be run, require an explanation and a description of the next best check.

For visual artifacts, require the model to render the artifact before finalizing, inspect for layout, clipping, spacing, and missing content, and revise until the rendered output matches the requirements.

For implementation plans, require coverage of: requirements and where each is addressed; named resources, files, APIs, or systems involved; state transitions or data flow; validation commands; failure behavior; privacy and security considerations; open questions that materially affect implementation.

## Completeness Contract

For lists, batches, and paginated work, require an internal checklist and explicit `[blocked]` markers:

```
<completeness_contract>
- Treat the task as incomplete until all requested items are covered or
  explicitly marked [blocked].
- Keep an internal checklist of required deliverables.
- For lists, batches, or paginated results: determine expected scope, track
  processed items or pages, confirm coverage before finalizing.
- If any item is blocked by missing data, mark it [blocked] and state exactly
  what is missing.
</completeness_contract>
```

## Retrieval Budget and Empty Results

Prevent premature "no results" conclusions, and give the model an explicit stopping rule for search:

```
<retrieval_budget>
For ordinary Q&A, start with one broad search using short, discriminative
keywords. If the top results contain enough citable support for the core
request, answer from those results instead of searching again.

Make another retrieval call only when:
- The top results do not answer the core question.
- A required fact, parameter, owner, date, ID, or source is missing.
- The user asked for exhaustive coverage, a comparison, or a comprehensive list.
- A specific document, URL, email, meeting, record, or code artifact must be read.
- The answer would otherwise contain an important unsupported factual claim.

Do not search again to improve phrasing, add examples, cite nonessential
details, or support wording that can safely be made more generic.
</retrieval_budget>
```

```
<empty_result_recovery>
If a lookup returns empty, partial, or suspiciously narrow results:
- do not immediately conclude that no results exist,
- try at least one or two fallback strategies (alternate query wording,
  broader filters, a prerequisite lookup, or an alternate source or tool),
- Only then report that no results were found, along with what you tried.
</empty_result_recovery>
```

## Agentic Updates

Clamp update verbosity and scope discipline. Pairs with the preamble pattern — preamble sets the first update; this spec governs the rest.

```
<user_updates_spec>
- Send brief updates (1-2 sentences) only when:
  - You start a new major phase of work, or
  - You discover something that changes the plan.
- Avoid narrating routine tool calls ("reading file...", "running tests...").
- Each update must include at least one concrete outcome ("Found X",
  "Confirmed Y", "Updated Z").
- Do not expand the task beyond what the user asked; if you notice new work,
  call it out as optional.
</user_updates_spec>
```

## Structured Output and Extraction

When the host supports strict schema-constrained output, prefer it over hand-rolled format prompts — it guarantees schema adherence without retries. When you cannot rely on that guarantee, encode the contract in the prompt:

```
<structured_output_contract>
- Output only the requested format.
- Do not add prose or markdown fences unless requested.
- Validate that parentheses and brackets are balanced.
- Do not invent tables or fields.
- If required schema information is missing, ask for it or return an explicit error object.
</structured_output_contract>
```

For extracting structured data from tables, PDFs, emails, and documents, include the schema inline in the prompt:

```
<extraction_spec>
You will extract structured data from tables/PDFs/emails into JSON.

- Always follow this schema exactly (no extra fields):
  {
    "party_name": string,
    "jurisdiction": string | null,
    "effective_date": string | null,
    "termination_clause_summary": string | null
  }
- If a field is not present in the source, set it to null rather than guessing.
- Before returning, re-scan the source for any missed fields and correct omissions.
</extraction_spec>
```

For multi-table or multi-file extraction, serialize per-document results separately and include a stable ID (filename, contract title, page range).

For layout-aware extraction with coordinates: specify the coordinate format exactly (e.g., `[x1,y1,x2,y2]` normalized 0..1), include page / label / text snippet / confidence per bbox, add a vertical-drift sanity check, and process dense layouts page by page with a second pass.

## Research Mode

For multi-source research, use a 3-pass structure paired with a retrieval budget and explicit stopping condition:

```
<research_mode>
- Plan: list 3-6 sub-questions to answer.
- Retrieve: search each sub-question and follow 1-2 second-order leads.
  Apply the retrieval budget: stop when top results cover the sub-question.
- Synthesize: resolve contradictions and write the final answer with citations.
- Stop only when more searching is unlikely to change the conclusion.
</research_mode>
```

### Citation Discipline

Lock citations to retrieved sources. If the host renders inline citation markers (e.g., Unicode markers like `​cite​`, `​start​`, `​end​`), emit one marker per source rather than combining sources:

```
<citation_rules>
- Only cite sources retrieved in the current workflow.
- Never fabricate citations, URLs, IDs, line ranges, or block locators.
- Use exactly the citation format required by the host application.
- Attach citations to the specific claims they support, not only at the end.
- Do not cite outside knowledge or outside authorities.
- When multiple sources support a claim, emit one citation marker per source.
</citation_rules>
```

### Creative Drafting Guardrails

For slides, launch copy, summaries, and narrative framing, distinguish source-backed facts from creative wording:

```
<creative_draft_rules>
- Use retrieved or provided facts for concrete product, customer, metric,
  roadmap, date, capability, and competitive claims, and cite those claims.
- Do not invent specific names, first-party data claims, metrics, roadmap
  status, customer outcomes, or product capabilities to make the draft sound
  stronger.
- If there is little or no citable support, write a useful generic draft
  with placeholders or clearly labeled assumptions rather than unsupported specifics.
</creative_draft_rules>
```

## Personality and Collaboration Style

GPT-5.5 holds persona well across long outputs. Separate the two concerns: **Personality** is how the assistant sounds; **Collaboration style** is how it works.

Example personality block (steady, task-focused):

```
# Personality
You are a capable collaborator: approachable, steady, and direct. Assume the
user is competent and acting in good faith, and respond with patience,
respect, and practical helpfulness.

Stay concise without becoming curt. Give enough context for the user to
understand and trust the answer, then stop. Use examples, comparisons, or
simple analogies when they make the point easier to grasp. When correcting
the user or disagreeing, be candid but constructive.

Match the user's tone within professional bounds. Avoid emojis and profanity
by default, unless the user explicitly asks for that style or has clearly
established it as appropriate.
```

Example collaboration block:

```
# Collaboration style
Prefer making progress over stopping for clarification when the request is
already clear enough to attempt. Use context and reasonable assumptions to
move forward. Ask for clarification only when the missing information would
materially change the answer or create meaningful risk, and keep any
question narrow.

When an error is pointed out, acknowledge it plainly and focus on fixing it.
Check your work via the validation tools available (tests, type checks,
render-and-inspect) before finalizing.
```

For polished professional writing (memos, briefs), require a precise tone that uses exact names, dates, entities, and authorities when supported by record; ties uncertainty to the exact missing fact or conflicting source; and synthesizes across documents rather than summarizing each independently.

## Coding Autonomy

For coding tasks, require end-to-end persistence within the turn and concrete validation before finalizing:

```
<autonomy_and_persistence>
- Persist until the task is fully handled end-to-end within the current turn.
- Do not stop at analysis or partial fixes; carry changes through
  implementation, validation, and a clear explanation of outcomes.
- Stop only if the user explicitly pauses or redirects.
- Before finalizing, run the most relevant validation available: targeted
  unit tests, type checks, build checks, or a minimal smoke test. If
  validation cannot be run, explain why and describe the next best check.
</autonomy_and_persistence>
```

Pair with a terse update spec: 1 sentence on outcome + 1 sentence on next step; no routine tool narration.

## Frontend Design

Key rules for UI prompts:

- Build the usable experience as the first screen, not marketing content; brand/product must be a first-viewport signal, not only tiny nav text.
- Never use split text/media hero card layouts; avoid decorative gradients and SVG heroes when real or generated images suffice.
- Do not put UI cards inside other cards.
- Use lucide icons in buttons when one exists instead of manually-drawn SVG.
- Keep card border radius at 8px or less; define stable dimensions using responsive constraints.
- Avoid one-note palettes (purple-only, beige-only, dark-blue-only).
- Avoid discrete orbs, gradient orbs, or bokeh blobs as decoration.
- Do not scale font size with viewport width; letter spacing must be 0.

Two prompting strategies: (1) specify a concrete alternative — explicit palette hex, typeface, radii, spacing — and the model follows it precisely; (2) have the model propose 4 distinct visual directions (bg hex / accent hex / typeface / one-line rationale) before building, then pick one.

## Mid-Conversation Task Updates

When changing scope mid-conversation, scope the update explicitly so earlier instructions survive:

```
<task_update>
For the next response only:
[specific change]

All earlier instructions still apply unless they conflict with this update.
</task_update>
```

## Migration Guide

When migrating prompts to GPT-5.5:

1. **Switch the model string without prompt changes first.** Test the model alone to isolate model-vs-prompt effects.
2. **Pin reasoning effort.** Preserve the source model's latency/depth profile (see migration mapping). Do not silently change it to `medium` just because the default changed.
3. **Run evals for baseline.** Measure post-switch performance before touching prompts.
4. **Prune legacy process-heavy instructions.** Remove step-by-step scripts, absolute rules on judgment calls (`ALWAYS search`, `NEVER assume`), and compensatory scaffolding that does not encode a true invariant or task constraint.
5. **Add outcome-first structure.** Replace process scripts with Goal / Success criteria / Constraints / Stop rules.
6. **Use host-level verbosity controls** instead of loose length prompts where available.
7. **Split Personality and Collaboration blocks** if the prompt had them fused.
8. **Add retrieval budget and citation rules** for research prompts.
9. **Add validation-command prompts** for coding and visual tasks.
10. **Add preamble and phase discipline** for streaming workflows.
11. **Tune reasoning effort only after prompt engineering is exhausted.** Change one thing at a time and re-run evals.

### Prompt-Specific Migration Notes

**From GPT-5.4:** pin the current effort explicitly (the default shifted from `none` to `medium`); if the prior prompt relied on `none` / `minimal`, set `low` as the GPT-5.5 floor; fuse length-control blocks into host-level verbosity where available; split fused Personality + Writing Controls; add retrieval budget, preamble, and validation blocks if missing; remove absolute rules on judgment calls.

**From GPT-5 / 5.1 / 5.2 / 5.3-Codex:** test without prompt changes first; if prior effort was `none` or `minimal`, start at `low`; add outcome-first structure if the prompt is process-heavy; add phase discipline for streaming flows.

**From GPT-4o / GPT-4.1:** remove defensive prompting (GPT-5.5 handles edge cases better); start at `low` effort; add output contract if outputs drift in length; add scope constraints for code and UI generation.

## Anti-Patterns

- **Carrying over every legacy instruction** — GPT-5.5 punishes process-heavy stacks with mechanical answers. Prune.
- **Using `ALWAYS` / `NEVER` / `must` / `only` for judgment calls** — reserve for true invariants (safety, required fields). Use decision rules for search/ask/iterate choices.
- **Step-by-step scripts where outcome-first would work** — define the destination; let the model pick the path.
- **Asking clarifying questions when you can cover plausible intents** — instruct the model to present interpretations instead.
- **Expanding task scope beyond user request** — implement only what was asked.
- **Inventing exact figures, citations, or external references when uncertain** — instruct to hedge, lock to retrieved sources, or verify via tools.
- **Rephrasing user requests unless semantics change** — preserve the user's language.
- **Narrating routine tool calls in agent updates** — instruct to report only meaningful milestones.
- **Creating extra UI/styling beyond design system specs** — enforce scope constraints.
- **Verbose tool descriptions** — keep to 1-2 sentences; more wastes context without improving selection.
- **Bumping reasoning effort before engineering the prompt** — add stop rules, retrieval budget, validation blocks, and completeness contracts first.
- **Defaulting to `xhigh` reasoning** — reserve for offline/async research where intelligence dominates speed/cost.
- **Treating empty tool results as final** — require fallback strategies first.
- **Conflating commentary and final-answer phases in prompts** — preamble instructions should produce short progress messages, not share length or format rules with the final deliverable.
- **Fusing Personality and Collaboration into one block** — they answer different questions and should stay separate.
- **Emitting one citation marker for multiple sources** — emit one marker per source when the host renders inline citations.

## Quality Checklist

- [ ] Prompt uses the 7-section structure for complex tasks
- [ ] Personality and Collaboration style are separate blocks if both apply
- [ ] Reasoning effort chosen deliberately; not defaulted to `xhigh`
- [ ] Verbosity set where the host supports it; length contracts per section otherwise
- [ ] Scope constraints defined for code and UI tasks
- [ ] Long-context grounding added for inputs over 10k tokens
- [ ] Default follow-through policy set for agentic prompts
- [ ] Uncertainty handling specified for the domain's risk level
- [ ] Preamble pattern set for streaming / multi-step tasks
- [ ] Commentary vs. final-answer phases kept distinct in prompt instructions
- [ ] Tool persistence, completeness contract, and validation block set for agents
- [ ] Retrieval budget and empty-result recovery set for search-enabled flows
- [ ] Tool descriptions crisp (1-2 sentences each); initial tool set small
- [ ] Strict schema relied on where available; otherwise structured-output contract in the prompt
- [ ] Extraction tasks include exact JSON schema with null handling; research prompts specify 3-pass structure, retrieval budget, and citation rules
- [ ] Creative-drafting guardrails set for slides/copy/summaries
- [ ] `<autonomy_and_persistence>` set for coding tasks with concrete validation commands
- [ ] Prompt tested without changes after model migration; reasoning effort pinned to source value on first pass
