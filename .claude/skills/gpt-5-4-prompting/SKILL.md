---
name: gpt-5-4-prompting
description: Apply when creating or editing prompts targeting GPT-5.4. Covers output contracts, scope discipline, reasoning_effort tuning, long-context handling, ambiguity management, tool persistence, completeness and verification contracts, structured extraction, research mode with citation discipline, personality controls, coding autonomy, compaction awareness, and migration from older GPT models.
---

# GPT-5.4 Prompt Writing Guidelines

## When to Use

- Creating or editing system prompts targeting GPT-5.4
- Writing prompts for long-context inputs (10k+ tokens)
- Writing agentic prompts with multi-step tool workflows
- Structuring extraction prompts for documents, PDFs, tables, and emails
- Managing verbosity, scope, and personality in GPT-5.4 outputs
- Writing tool descriptions and tool-calling instructions for GPT-5.4
- Writing research and synthesis agent prompts
- Migrating prompts from GPT-4o, GPT-4.1, GPT-5, GPT-5.1, GPT-5.2, or GPT-5.3-Codex

## Overview

GPT-5.4 is OpenAI's current frontier model. Compared to GPT-5.2, it delivers stronger personality and tone adherence (less drift on long answers), more disciplined multi-step execution, better long-context coherence, and more accurate batched/parallel tool calls. It remains prompt-sensitive and responds well to structured constraints and explicit output specifications.

<context>
Key behavioral characteristics to design prompts around:

- **Stronger Instruction Adherence**: More reliable with explicit output contracts; less drift from user intent
- **Improved Long-Context Coherence**: Stays coherent over longer, multi-turn conversations; fewer breakdowns as sessions grow
- **Agentic Discipline**: More reliably completes multi-step work and retries; still benefits from explicit persistence rules
- **Tone and Style Stability**: Holds persona and register across long outputs without drifting
- **Conservative Grounding Bias**: Favors correctness and explicit reasoning; research mode needs citation discipline to stay grounded
- **Token Efficiency**: More concise by default, though still responsive to length specs
</context>

## Output Contract

GPT-5.4 defaults to concise output and respects section/format contracts well. Use an explicit output contract rather than loose "be concise" instructions:

```
<output_contract>
- Return exactly the sections requested, in the requested order.
- If the prompt defines a preamble, analysis block, or working section, do not treat it as extra output.
- Apply length limits only to the section they are intended for.
- If a format is required (JSON, Markdown, SQL, XML), output only that format.
</output_contract>
```

For quantitative length control, combine the contract with explicit limits per section:

```
<output_verbosity>
- Default: 3-6 sentences or <=5 bullets for typical answers.
- Simple "yes/no + short explanation" questions: <=2 sentences.
- Complex multi-step or multi-file tasks:
  - 1 short overview paragraph
  - then <=5 bullets tagged: What changed, Where, Risks, Next steps, Open questions.
- Prefer compact bullets and short sections over long narrative paragraphs.
- Do not rephrase the user's request unless it changes semantics.
</output_verbosity>
```

Quantitative constraints ("3-6 sentences") outperform qualitative ones ("be concise").

## Scope and Design Constraints

GPT-5.4 is stronger at structured code but may still produce more than minimal specs require. Use scope constraints adapted to the task domain to prevent over-engineering.

For code generation and UI tasks:

```
<design_and_scope_constraints>
- Explore existing design systems deeply.
- Implement EXACTLY and ONLY what the user requests.
- No extra features, no added components, no UX embellishments.
- Style aligned to the design system at hand.
- Do NOT invent colors, shadows, tokens, animations, or new UI elements, unless requested.
- If any instruction is ambiguous, choose the simplest valid interpretation.
</design_and_scope_constraints>
```

For extraction and data tasks, scope is schema adherence:

```
- Follow this schema exactly (no extra fields).
- If a field is not present in the source, set it to null rather than guessing.
```

For research and synthesis tasks, scope is query coverage -- cover plausible user intents rather than expanding into tangential topics.

## Long-Context Handling

GPT-5.4 remains more coherent over long sessions, but inputs exceeding ~10k tokens still benefit from explicit grounding instructions:

```
<long_context_handling>
- For inputs longer than ~10k tokens (multi-chapter docs, long threads, multiple PDFs):
  - First, produce a short internal outline of key sections relevant to the request.
  - Re-state the user's constraints explicitly before answering.
  - In your answer, anchor claims to sections rather than speaking generically.
- If the answer depends on fine details (dates, thresholds, clauses), quote or paraphrase them.
</long_context_handling>
```

## Ambiguity, Uncertainty, and Follow-Through

GPT-5.4 handles ambiguity better by default. Set explicit follow-through policy to avoid unnecessary clarifying questions:

```
<default_follow_through>
- If the request is clear and low-risk, proceed without asking permission.
- Ask before: irreversible actions, external side effects, or operations requiring sensitive info not yet provided.
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

For high-stakes domains, add a self-check step:

```
<high_risk_self_check>
Before finalizing an answer in legal, financial, compliance, or safety-sensitive contexts:
- Briefly re-scan your own answer for:
  - Unstated assumptions,
  - Specific numbers or claims not grounded in context,
  - Overly strong language ("always," "guaranteed," etc.).
- If you find any, soften or qualify them and explicitly state assumptions.
</high_risk_self_check>
```

## Reasoning Effort Tuning

GPT-5.4 supports `reasoning_effort` (`none` | `minimal` | `low` | `medium` | `high` | `xhigh`). It defaults to `none` for fast, low-deliberation behavior.

**Engineer the prompt before bumping reasoning.** Before increasing `reasoning_effort`, first add:
- Completeness contract
- Verification loop
- Tool persistence rules

These often restore behavior without added latency/cost. Only bump reasoning when evals show a gap the prompt can't close.

**Recommended defaults by task:**

| Task profile | reasoning_effort |
|---|---|
| Fast, cost-sensitive; no thinking needed | `none` |
| Latency-sensitive with instruction complexity | `low` |
| Stronger reasoning required; measure perf gain | `medium` or `high` |
| Long-horizon agents, research-heavy workflows | `medium` or `high` |
| Hardest analytical work where intelligence >> speed/cost | `xhigh` (reserve; do not default) |

### Migration Mapping

When migrating prompts across models, use the appropriate `reasoning_effort` to preserve behavior:

| Current Model | Target | reasoning_effort | Notes |
|---|---|---|---|
| GPT-4o | GPT-5.4 | `none` | Treat as "fast/low-deliberation" by default |
| GPT-4.1 | GPT-5.4 | `none` | Same as GPT-4o for snappy behavior |
| GPT-5 / 5.1 / 5.2 | GPT-5.4 | match current | Preserve prior setting |
| GPT-5.3-Codex | GPT-5.4 | match current | Preserves coding behavior |

## Tool Persistence

For agentic prompts, instruct the model not to stop early and to retry on empty or partial results:

```
<tool_persistence_rules>
- Use tools whenever they materially improve correctness, completeness, or grounding.
- Do not stop early when another tool call is likely to materially improve correctness or completeness.
- Keep calling tools until: (1) the task is complete, and (2) verification passes.
- If a tool returns empty or partial results, retry with a different strategy.
</tool_persistence_rules>
```

## Completeness Contract

For lists, batches, and paginated work, require an internal checklist and explicit `[blocked]` markers:

```
<completeness_contract>
- Treat the task as incomplete until all requested items are covered or explicitly marked [blocked].
- Keep an internal checklist of required deliverables.
- For lists, batches, or paginated results: determine expected scope when possible, track processed items or pages, confirm coverage before finalizing.
- If any item is blocked by missing data, mark it [blocked] and state exactly what is missing.
</completeness_contract>
```

## Verification Loop

For high-stakes outputs, require a pre-finalization check:

```
<verification_loop>
Before finalizing:
- Check correctness: does the output satisfy every requirement?
- Check grounding: are factual claims backed by provided context or tool outputs?
- Check formatting: does the output match the requested schema or style?
- Check safety and irreversibility: if the next step has external side effects, ask permission first.
</verification_loop>
```

## Empty Result Recovery

Prevent premature "no results" conclusions:

```
<empty_result_recovery>
If a lookup returns empty, partial, or suspiciously narrow results:
- do not immediately conclude that no results exist,
- try at least one or two fallback strategies, such as:
  - alternate query wording,
  - broader filters,
  - a prerequisite lookup,
  - or an alternate source or tool,
- Only then report that no results were found, along with what you tried.
</empty_result_recovery>
```

## Agentic Steerability

Clamp update verbosity and scope discipline:

```
<user_updates_spec>
- Send brief updates (1-2 sentences) only when:
  - You start a new major phase of work, or
  - You discover something that changes the plan.
- Avoid narrating routine tool calls ("reading file...", "running tests...").
- Each update must include at least one concrete outcome ("Found X", "Confirmed Y", "Updated Z").
- Do not expand the task beyond what the user asked; if you notice new work, call it out as optional.
</user_updates_spec>
```

## Tool-Calling Prompt Patterns

### Usage Rules

```
<tool_usage_rules>
- Prefer tools over internal knowledge whenever:
  - You need fresh or user-specific data (tickets, orders, configs, logs).
  - You reference specific IDs, URLs, or document titles.
- Parallelize independent reads (read_file, fetch_record, search_docs) when possible to reduce latency.
- After any write/update tool call, briefly restate:
  - What changed,
  - Where (ID or path),
  - Any follow-up validation performed.
</tool_usage_rules>
```

### Tool Description Guidance

- **Describe tools crisply** in 1-2 sentences. Verbose descriptions waste context without improving selection accuracy.
- **Encourage parallelism** for codebases, vector stores, and multi-entity operations. Mark tools as independent when they are.
- **Require verification** for high-impact operations (orders, billing, infrastructure). Add the verification step in the tool description or system prompt.

## Structured Output (JSON / SQL)

For strict format outputs:

```
<structured_output_contract>
- Output only the requested format.
- Do not add prose or markdown fences unless requested.
- Validate that parentheses and brackets are balanced.
- Do not invent tables or fields.
- If required schema information is missing, ask for it or return an explicit error object.
</structured_output_contract>
```

## Structured Extraction

For extracting structured data from tables, PDFs, emails, and documents:

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
- Before returning, quickly re-scan the source for any missed fields and correct omissions.
</extraction_spec>
```

For multi-table/multi-file extraction, serialize per-document results separately and include a stable ID (filename, contract title, page range).

### Bounding-Box Extraction

For layout-aware extraction with coordinates:

```
<bbox_extraction_spec>
- Use the specified coordinate format exactly (e.g., [x1,y1,x2,y2] normalized 0..1).
- For each bbox, include: page, label, text snippet, confidence.
- Add a vertical-drift sanity check: ensure bboxes align with the line of text (not shifted up or down).
- If dense layout, process page by page and do a second pass for missed items.
</bbox_extraction_spec>
```

## Personality and Writing Controls

GPT-5.4 holds persona well across long outputs. Separate persistent personality from per-response controls:

```
<personality_and_writing_controls>
- Persona: <one sentence>
- Channel: <Slack | email | memo | PRD | blog>
- Emotional register: <direct/calm/energized/etc.> + "not <overdo this>"
- Formatting: <ban bullets/headers/markdown if you want prose>
- Length: <hard limit, e.g., <=150 words or 3-5 sentences>
- Default follow-through: if the request is clear and low-risk, proceed without asking permission.
</personality_and_writing_controls>
```

For polished professional writing:

```
<memo_mode>
- Write in a polished, professional memo style.
- Use exact names, dates, entities, and authorities when supported by record.
- Follow domain-specific structure if one is requested.
- Prefer precise conclusions over generic hedging.
- When uncertainty is real, tie it to the exact missing fact or conflicting source.
- Synthesize across documents rather than summarizing each one independently.
</memo_mode>
```

## Coding Autonomy

For coding tasks, require end-to-end persistence within the turn:

```
<autonomy_and_persistence>
- Persist until the task is fully handled end-to-end within the current turn whenever feasible.
- Do not stop at analysis or partial fixes; carry changes through implementation, verification, and a clear explanation of outcomes.
- Stop only if the user explicitly pauses or redirects.
</autonomy_and_persistence>
```

Pair with a terse update spec: 1 sentence on outcome + 1 sentence on next step; no routine tool narration.

## Research Mode

For multi-source research, use a 3-pass structure:

```
<research_mode>
- Do research in 3 passes:
  1) Plan: list 3-6 sub-questions to answer.
  2) Retrieve: search each sub-question and follow 1-2 second-order leads.
  3) Synthesize: resolve contradictions and write the final answer with citations.
- Stop only when more searching is unlikely to change the conclusion.
</research_mode>
```

### Citation Discipline

Lock citations to retrieved sources to prevent fabrication:

```
<citation_rules>
- Only cite sources retrieved in the current workflow.
- Never fabricate citations, URLs, IDs, or quote spans.
- Use exactly the citation format required by the host application.
- Attach citations to the specific claims they support, not only at the end.
</citation_rules>
```

### Web Research Template

```
<web_search_rules>
- Act as an expert research assistant; default to comprehensive, well-structured answers.
- Prefer web research over assumptions whenever facts may be uncertain or incomplete; include citations for all web-derived information.
- Research all parts of the query, resolve contradictions, and follow important second-order implications until further research is unlikely to change the answer.
- Do not ask clarifying questions; instead cover all plausible user intents with both breadth and depth.
- Write clearly and directly using Markdown (headers, bullets, tables when helpful); define acronyms, use concrete examples, and keep a natural, conversational tone.
</web_search_rules>
```

### Web Research Agent Reference Prompt

The official guide provides this structure for a comprehensive web research agent:

- **CORE MISSION**: Answer fully and helpfully with enough evidence for skeptical readers. Never invent facts. Go one step further by adding high-value adjacent material.
- **PERSONA**: Be the world's greatest research assistant. Engage warmly while avoiding ungrounded flattery. Default to natural, conversational tone.
- **FACTUALITY AND ACCURACY**: Browse the web and include citations for all non-creative queries. Always browse for latest/current topics, time-sensitive info, recommendations, navigational queries, or ambiguous terms.
- **CITATIONS**: Include citations after paragraphs containing non-obvious web-derived claims. Use multiple sources for key claims, prioritizing primary sources.
- **HOW YOU RESEARCH**: Conduct deep research. Use parallel searches when helpful. Research until additional searching is unlikely to materially change the answer.
- **WRITING GUIDELINES**: Be direct and comprehensive. Use simple language. Use readable Markdown formatting. Do not add potential follow-up questions unless explicitly asked.
- **REQUIRED VALUE-ADD**: Provide concrete examples, specific numbers/dates, and "how it works" detail. Include relevant, well-researched material that makes answers more useful.
- **HANDLING AMBIGUITY**: Never ask clarifying questions unless explicitly requested. State your best-guess interpretation and comprehensively cover the most likely intent(s).
- **IF YOU CANNOT FULLY COMPLY**: Don't lead with blunt refusal. First deliver what you can, then clearly state limitations.

## Mid-Conversation Task Updates

When changing scope mid-conversation, scope the update explicitly so earlier instructions survive:

```
<task_update>
For the next response only:
[specific change]

All earlier instructions still apply unless they conflict with this update.
</task_update>
```

## Compaction Awareness

GPT-5.4 is more coherent over long sessions, but compaction still helps tool-heavy workflows. When writing prompts for systems that use compaction:

- **Keep prompts functionally identical when resuming** -- do not change system prompts between compacted sessions, as this causes behavior drift
- **Design prompts to be self-contained** -- compacted items are opaque; the system prompt is the only stable anchor across compaction boundaries
- **Compact after major milestones** (not every turn) -- frequent compaction loses nuance

## Prompt Migration Guide

When migrating prompts to GPT-5.4, follow these steps to isolate changes and preserve behavior:

1. **Switch models without prompt changes** -- test the model alone to isolate model-vs-prompt effects.
2. **Pin `reasoning_effort`** -- explicitly match the prior model's latency/depth profile (see migration mapping above).
3. **Run evals for baseline** -- measure post-switch performance before touching prompts.
4. **Add output contract + verbosity controls** if outputs are verbose or unfocused.
5. **Add tool persistence + completeness contract** for agent prompts.
6. **Add verification loop** for high-stakes outputs.
7. **Add citation rules + empty-result recovery** for research prompts.
8. **Tune `reasoning_effort` only after prompt engineering is exhausted.** Change one thing at a time and re-run evals.

### Prompt-Specific Migration Notes

**From GPT-4o / GPT-4.1:**
- Remove defensive prompting (GPT-5.4 handles edge cases better by default)
- Add output contract if outputs are too long or too short
- Add scope constraints for code generation tasks

**From GPT-5 / GPT-5.1 / GPT-5.2:**
- Test without prompt changes first -- isolate model-vs-prompt effects
- Replace older `<output_verbosity_spec>` wording with `<output_contract>` where helpful
- Add tool persistence, completeness, and verification templates for agentic flows
- Long-context handling is still useful but less critical given improved coherence

**From GPT-5.3-Codex:**
- Preserve existing `reasoning_effort` to keep coding behavior stable
- Add `<autonomy_and_persistence>` for end-to-end task completion

## Anti-Patterns

- **Asking clarifying questions when you can cover plausible intents** -- instruct the model to present interpretations instead
- **Expanding task scope beyond user request** -- implement only what was asked
- **Inventing exact figures, citations, or external references when uncertain** -- instruct to hedge, lock to retrieved sources, or use tools to verify
- **Rephrasing user requests unless semantics change** -- preserve the user's language
- **Narrating routine tool calls in agent updates** -- instruct to report only meaningful milestones
- **Creating extra UI/styling beyond design system specs** -- enforce scope constraints
- **Changing prompts during model migrations** -- test model alone first, then tune prompts
- **Over-prompting for default behavior** -- GPT-5.4's instruction adherence means less scaffolding is needed for basics
- **Verbose tool descriptions** -- keep to 1-2 sentences; more wastes context without improving selection
- **Bumping `reasoning_effort` before engineering the prompt** -- add completeness, verification, and tool persistence first
- **Defaulting to `xhigh` reasoning** -- reserve for long agentic tasks where intelligence outweighs speed/cost
- **Treating empty tool results as final** -- require fallback strategies first
- **Skipping prerequisites when the end state looks obvious** -- require dependency checks for multi-step flows

## Quality Checklist

- [ ] Output contract is set (sections, format, length limits per section)
- [ ] Scope constraints are defined for code and design tasks
- [ ] Long-context grounding is added for inputs over 10k tokens
- [ ] Default follow-through policy is set for agentic prompts
- [ ] Uncertainty handling is specified for the domain's risk level
- [ ] `reasoning_effort` is chosen deliberately; not defaulted to `xhigh`
- [ ] Tool persistence, completeness contract, and verification loop are set for agents
- [ ] Empty-result recovery is specified for tool-heavy flows
- [ ] Tool descriptions are crisp (1-2 sentences each)
- [ ] Extraction tasks include exact JSON schema with null handling
- [ ] Research prompts specify 3-pass structure and citation rules
- [ ] Personality and memo mode are set for customer-facing prose
- [ ] `<autonomy_and_persistence>` is set for coding tasks
- [ ] Prompt has been tested without changes after model migration

## Reference

- Official GPT-5.4 Prompt Guidance: https://developers.openai.com/api/docs/guides/prompt-guidance
