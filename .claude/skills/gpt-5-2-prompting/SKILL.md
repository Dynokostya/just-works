---
name: gpt-5-2-prompting
description: Apply when creating or editing prompts targeting GPT-5.2. Covers verbosity control, scope discipline, reasoning_effort awareness, long-context handling, ambiguity management, structured extraction, compaction awareness, tool-calling prompt patterns, web research defaults, and migration from older GPT models.
---

# GPT-5.2 Prompt Writing Guidelines

## When to Use

- Creating or editing system prompts targeting GPT-5.2
- Writing prompts for long-context inputs (10k+ tokens)
- Structuring extraction prompts for documents, PDFs, and emails
- Managing verbosity and scope in GPT-5.2 outputs
- Writing tool descriptions and tool-calling instructions for GPT-5.2
- Writing web research agent prompts
- Migrating prompts from GPT-4o, GPT-4.1, GPT-5, or GPT-5.1

## Overview

GPT-5.2 is OpenAI's latest frontier model. It delivers stronger instruction adherence, lower default verbosity, and more deliberate reasoning scaffolding compared to previous GPT models. The model is prompt-sensitive -- it responds well to structured constraints and explicit output specifications.

<context>
Key behavioral characteristics to design prompts around:

- **More Deliberate Scaffolding**: Produces clearer intermediate plans with more structured reasoning; benefits from explicit scope and verbosity constraints
- **Lower Verbosity**: More concise and task-focused by default, though still responsive to prompt preferences
- **Stronger Instruction Adherence**: Less drift from user intent; improved formatting and rationale presentation
- **Conservative Grounding Bias**: Favors correctness and explicit reasoning; ambiguity handling improves with clarification prompts
- **Tool Efficiency Trade-offs**: Takes additional tool actions in interactive flows; optimizable via prompting
</context>

## Verbosity and Output Control

GPT-5.2 defaults to concise output. Use the following template to set explicit verbosity expectations in system prompts:

```
<output_verbosity_spec>
- Default: 3-6 sentences or <=5 bullets for typical answers.
- For simple "yes/no + short explanation" questions: <=2 sentences.
- For complex multi-step or multi-file tasks:
  - 1 short overview paragraph
  - then <=5 bullets tagged: What changed, Where, Risks, Next steps, Open questions.
- Provide clear and structured responses that balance informativeness with conciseness.
- Avoid long narrative paragraphs; prefer compact bullets and short sections.
- Do not rephrase the user's request unless it changes semantics.
</output_verbosity_spec>
```

Adjust the default ranges to match your use case. The model respects quantitative output constraints well -- specifying "3-6 sentences" is more effective than "be concise."

## Scope and Design Constraints

GPT-5.2 is stronger at structured code but may produce more code than minimal specs require. Use this template to prevent over-engineering and scope creep:

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

This is especially effective for code generation and UI tasks where the model might otherwise add unrequested polish.

## Long-Context Handling

For inputs exceeding approximately 10k tokens (large documents, codebases, conversation histories), add explicit grounding instructions:

```
<long_context_handling>
- For inputs longer than ~10k tokens (multi-chapter docs, long threads, multiple PDFs):
  - First, produce a short internal outline of key sections relevant to the request.
  - Re-state the user's constraints explicitly before answering.
  - In your answer, anchor claims to sections rather than speaking generically.
- If the answer depends on fine details (dates, thresholds, clauses), quote or paraphrase them.
</long_context_handling>
```

Without these instructions, long-context responses may drift from specifics. The grounding template keeps the model anchored to source material.

## Ambiguity and Hallucination Mitigation

GPT-5.2 has a conservative grounding bias but still benefits from explicit uncertainty handling instructions:

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

## Reasoning Effort Awareness

GPT-5.2 supports a `reasoning_effort` parameter (`none` | `minimal` | `low` | `medium` | `high` | `xhigh`) that trades off speed/cost versus deeper reasoning. GPT-5.2 defaults to `none`, behaving as a fast, low-deliberation model out of the box.

When writing prompts, be aware that reasoning effort affects how the model processes your instructions:

- At `none`/`low`: keep prompts direct and unambiguous; the model won't reason deeply through complex instructions
- At `medium`/`high`: the model can handle more nuanced multi-step instructions
- At `xhigh`: maximum reasoning depth; suitable for the hardest analytical tasks

### Migration Mapping

When migrating prompts across models, use the appropriate reasoning_effort to preserve behavior:

| Current Model | Target | reasoning_effort | Notes |
|---|---|---|---|
| GPT-4o | GPT-5.2 | `none` | Treat as "fast/low-deliberation" by default |
| GPT-4.1 | GPT-5.2 | `none` | Same as GPT-4o for snappy behavior |
| GPT-5 | GPT-5.2 | same (`minimal` -> `none`) | Preserve none/low/medium/high |
| GPT-5.1 | GPT-5.2 | same | Adjust only after running evals |

## Agentic Steerability

GPT-5.2 excels at agentic scaffolding and multi-step execution. Use update instructions to control how the model communicates progress. Reuse GPT-5.1 patterns while adding two key tweaks: clamp verbosity of updates and make scope discipline explicit.

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

This prevents the model from over-narrating its process while still keeping users informed at meaningful checkpoints.

## Tool-Calling Prompt Patterns

### Usage Rules

Include this in system prompts to guide tool selection and reporting:

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

When writing tool descriptions for GPT-5.2 prompts:

- **Describe tools crisply** in 1-2 sentences. The model parses tool descriptions carefully -- verbose descriptions waste context without improving selection accuracy.
- **Encourage parallelism** for codebases, vector stores, and multi-entity operations. GPT-5.2 handles parallel tool calls well when tools are marked as independent.
- **Require verification** for high-impact operations (orders, billing, infrastructure changes). Add a verification step in the tool description or system prompt.

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

Provide the exact JSON schema in the prompt. GPT-5.2 adheres to schema constraints well -- specifying `null` for missing fields prevents hallucinated values.

## Compaction Awareness

Compaction extends effective context windows for long-running, tool-heavy workflows via the `/responses/compact` endpoint. When writing prompts for systems that use compaction:

- **Keep prompts functionally identical when resuming** -- do not change system prompts between compacted sessions, as this causes behavior drift
- **Design prompts to be self-contained** -- compacted items are opaque; the system prompt is the only stable anchor across compaction boundaries
- **Compact after major milestones** (not every turn) -- frequent compaction loses nuance

## Web Research

GPT-5.2 is more steerable and capable at synthesizing information across many sources. Use this template to configure web research behavior:

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

## Prompt Migration Guide

When migrating prompts to GPT-5.2, follow these steps to isolate changes and preserve behavior:

1. **Switch models without prompt changes** -- test the model alone to isolate model-vs-prompt effects. Make one change at a time.
2. **Pin reasoning_effort** -- explicitly set to match the prior model's latency/depth profile (see migration mapping above).
3. **Run evals for baseline** -- measure post-switch performance before touching prompts.
4. **Tune if regressions** -- use targeted constraints (verbosity/format/schema, scope discipline) to restore parity or improve.
5. **Re-run evals after each change** -- iterate by bumping reasoning_effort one notch or making incremental prompt tweaks, then re-measure.

### Prompt-Specific Migration Notes

**From GPT-4o / GPT-4.1:**
- Remove defensive prompting (GPT-5.2 handles edge cases better by default)
- Add verbosity control template if outputs are too long or too short
- Add scope constraints template for code generation tasks

**From GPT-5 / GPT-5.1:**
- Test without prompt changes first -- isolate model-vs-prompt effects
- Add long-context handling template if working with large inputs
- Add uncertainty template for high-stakes domains

## Anti-Patterns

- **Asking clarifying questions when you can cover plausible intents** -- instruct the model to present interpretations instead
- **Expanding task scope beyond user request** -- implement only what was asked
- **Inventing exact figures or external references when uncertain** -- instruct to hedge or use tools to verify
- **Rephrasing user requests unless semantics change** -- preserve the user's language
- **Narrating routine tool calls in agent updates** -- instruct to report only meaningful milestones
- **Creating extra UI/styling beyond design system specs** -- enforce scope constraints
- **Changing prompts during model migrations** -- test model alone first, then tune prompts
- **Over-prompting for default behavior** -- GPT-5.2's instruction adherence means less scaffolding is needed for basics
- **Verbose tool descriptions** -- keep to 1-2 sentences; more wastes context without improving selection

## Quality Checklist

- [ ] Verbosity expectations are set explicitly (sentence counts, bullet limits)
- [ ] Scope constraints are defined for code and design tasks
- [ ] Long-context grounding is added for inputs over 10k tokens
- [ ] Uncertainty handling is specified for the domain's risk level
- [ ] `reasoning_effort` is chosen appropriately for the task complexity
- [ ] Tool descriptions are crisp (1-2 sentences each)
- [ ] Extraction tasks include exact JSON schema with null handling
- [ ] Web search instructions specify research depth and citation behavior
- [ ] Prompt has been tested without changes after model migration

## Reference

- Official GPT-5.2 Prompting Guide: https://developers.openai.com/cookbook/examples/gpt-5/gpt-5-2_prompting_guide/
