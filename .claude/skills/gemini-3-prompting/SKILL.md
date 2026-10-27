---
name: gemini-3-prompting
description: Apply when creating or editing prompts, system prompts or agent instructions that target the Gemini 3.x family (3.1 Pro, 3 Flash, 3.5 to 3.8 Flash, Flash-Lite), including thinking-level settings, grounding and tool prompts, and migration from 3.0 and 2.5. Not for Gemini 4 (gemini-4-argon).
---

# Gemini 3.x Prompting

## When to Use

- Creating or editing system prompts targeting Gemini 3.x
- Writing few-shot examples for classification or extraction
- Structuring long-context prompts with multiple sources
- Writing agentic or tool-use instructions for Gemini 3.x
- Migrating prompt text from Gemini 2.5 or an earlier 3.x release

Gemini 4 (`gemini-4-argon`) has its own guidance; check https://ai.google.dev/gemini-api/docs/models before applying this skill to it.

## Overview

Gemini 3.x is a reasoning model family. It responds best to short, direct instructions and may over-analyze verbose prompt-engineering techniques written for older models (https://ai.google.dev/gemini-api/docs/gemini-3, "Prompting best practices"). Reasoning depth is set by the `thinking_level` parameter (`thinkingLevel` in JS and REST), so do not write manual chain-of-thought instructions.

<context>
Design around these documented behaviors:

- **Concise input.** "Be concise in your input prompts. Gemini 3 responds best to direct, clear instructions." (gemini-3 page)
- **Direct output by default.** Ask explicitly for a conversational or detailed tone. (prompting-strategies page)
- **Context first, question last.** Supply all context first and put the specific question at the very end. (prompting-strategies page)
- **Constraints first.** Put behavioral constraints, persona, and output format in the system instruction or at the very start of the user prompt. (prompting-strategies page)
- **Temperature stays at 1.0.** Google strongly recommends the default for all Gemini 3 models; lower values "may lead to unexpected behavior, such as looping or degraded performance". (gemini-3 page)
- **Few-shot examples.** "We recommend to always include few-shot examples in your prompts." (prompting-strategies page)
</context>

Sources: https://ai.google.dev/gemini-api/docs/gemini-3 and https://ai.google.dev/gemini-api/docs/prompting-strategies.

## Prompt Structure

Put stable rules first, long context next, and the task last. Pick one delimiter style per prompt, XML tags or Markdown headings, and do not mix them.

```jinja
{# System instruction: persona, rules, output format #}
<role>{{ persona }}</role>
<constraints>
{% for constraint in behavioural_constraints %}
- {{ constraint }}
{% endfor %}
</constraints>
<output_format>{{ output_format }}</output_format>

{# User prompt: context first, task last #}
<context>
{{ context_data }}
</context>

<task>
Based on the information above, {{ specific_question }}.
</task>
```

Bridge the context to the task with a phrase such as "Based on the information above, ..." or, for several sources, "Based on the entire document above, provide a comprehensive answer to: ...". Google recommends such a transition after large data blocks.

Order for cache hits: implicit caching is on by default for Gemini 2.5 and newer, and Google advises putting large, common content at the start of the prompt and sending requests with a similar prefix close together (https://ai.google.dev/gemini-api/docs/caching). Keep system instructions, few-shot examples, and reference documents before volatile content such as the user query.

Persona and constraints must not contradict each other. A "friendly, talkative" persona with an "answer in 1-2 words" format forces the model to pick one.

## Thinking Level

`thinking_level` replaces manual reasoning prompts. Defaults and supported levels differ by model, so check the "Controlling thinking" table before writing prompts that assume a level (https://ai.google.dev/gemini-api/docs/thinking). Rows from that table:

| Endpoint | Default | Supported levels |
|---|---|---|
| `gemini-3.1-pro-preview` | high | low, medium, high |
| `gemini-3-flash-preview` | high | minimal, low, medium, high |
| `gemini-3.6-flash` | medium | minimal, low, medium, high |
| `gemini-3.8-flash` | medium | low, medium, high |
| `gemini-3.5-flash-lite` | minimal | minimal, low, medium, high |

- `gemini-3.8-flash` rejects `minimal` with an error (https://ai.google.dev/gemini-api/docs/models/gemini-3.8-flash). Pro does not support it either.
- `minimal` "does not guarantee that thinking is off" (gemini-3 page).
- Levels are relative allowances, not token guarantees. Do not combine `thinking_level` with the legacy `thinking_budget` in one request; that returns a 400 error.
- To cut latency or cost, lower `thinking_level` rather than setting a small `max_output_tokens`, which can truncate output after the thinking tokens are spent.
- Remove "Let's think step by step" and similar triggers. If the user needs visible reasoning in the answer, request it explicitly: "Show your reasoning step by step, then give your final answer."

## Constraints and Grounding

Scope negative constraints to the task. "Do not infer; report facts exactly as they appear" suits verbatim extraction and is close to Google's own grounding clause. The same broad negative makes the model refuse sensible deductions in reasoning or QA tasks; use "Use the provided context for deductions. Do not use outside knowledge." there.

Abridged from Google's grounding clause for provided-context tasks (the full text is on the prompting-strategies page, "Gemini 3 Flash strategies"):

```
You are a strictly grounded assistant limited to the information provided in the User Context. In your answers, rely only on the facts that are directly mentioned in that context. You must not access or utilize your own knowledge or common sense to answer. Do not assume or infer from the provided facts; simply report them exactly as they appear. If the exact answer is not explicitly written in the context, you must state that the information is not available.
```

Prefer numbers over vague qualifiers: "Respond in 2-3 sentences" beats "Keep it short".

Time-awareness clauses adapted from Google's Flash strategies (the original hardcodes the year). Fill the placeholders from the harness; do not hardcode a year or cutoff:

```
For time-sensitive user queries that require up-to-date information, you MUST follow the provided current time (date and year) when formulating search queries in tool calls. Remember it is {{ current_year }} this year.

Your knowledge cutoff date is {{ knowledge_cutoff }}.
```

Google documents a January 2025 cutoff for Gemini 3 and 3.1 Pro, but its model pages do not list one for later Flash releases, so confirm the value for the endpoint you target.

## Few-Shot Examples

Use few-shot examples for classification, extraction, and formatting. Reasoning tasks can run zero-shot on `thinking_level`. The model copies what it sees, so every example must show exactly the behavior you want.

- Use 2-5 varied examples with identical structure and consistent prefixes (`Input:`, `Output:`).
- Show correct patterns only, and put examples before the final input.
- Google notes that clear examples can let you remove instructions.

See `references/jinja-patterns.md` for classification, extraction, and multi-source templates.

## Structured Output

When an API schema enforces JSON, the prompt states the task and the meaning of each field; the schema defines the shape. Do not paste the schema into the prompt, because duplicates can conflict. Describe class meanings for enums in prose, since the schema constrains syntax and not semantics. Without a schema, include a minimal JSON skeleton in the prompt (template in `references/jinja-patterns.md`).

Use structured output for the final answer and function calling for intermediate actions that run external code.

## Agentic Prompts

Google lists the behavior dimensions an agent prompt can steer: logical decomposition, problem diagnosis, information exhaustiveness, adaptability, persistence and recovery, risk assessment, ambiguity and permission handling, verbosity, and precision and completeness (https://ai.google.dev/gemini-api/docs/prompting-strategies, "Agentic workflows"). Google also publishes a full evaluated agent system-instruction template on that page; start from it for rule-heavy agents.

A compact skeleton:

```jinja
Agent Instructions:
- For EXPLORATORY actions (searches, reads, lookups): prefer calling the tool with the available information over asking for clarification. Missing optional parameters is low risk.
- For STATE-CHANGING actions (writes, deletes, external side effects): explain what will change and why before acting. Ask for confirmation when the user's intent is ambiguous.
- When an observation contradicts your plan, revise the plan rather than retrying the same action.
- For routine tool execution, proceed without narration. For planning and complex decisions, explain your reasoning.
```

- Keep the active tool set to 10-20 tools (https://ai.google.dev/gemini-api/docs/function-calling, "Best practices"). Remove tools the workflow will not use.
- Tool names, descriptions, and parameter descriptions are prompt text. Write them as specifically as the system prompt.
- Use `high` thinking for planning and `low` or `medium` for routine tool loops. Let native thinking handle decomposition.
- If a prompt asks for structured text (XML, JSON) immediately before a tool call, the call can fail with `Malformed_Function_Call`. Google's preferred workaround is to have the model put pre-tool notes in a dedicated `update()` function call (function-calling page, "Workarounds for pre-tool text requirements").

Function-calling modes, thought-signature handling, and Google Search grounding wording are in `references/tools-and-grounding.md`.

## Model Choice

Endpoint names and aliases change with each release; confirm against https://ai.google.dev/gemini-api/docs/models and https://ai.google.dev/gemini-api/docs/deprecations before hardcoding a model name in a prompt template. Some older endpoints (for example `gemini-3.5-flash`) are aliases that route to a newer model.

- **Pro** (`gemini-3.1-pro-preview`): multi-step reasoning, synthesis across many sources, high-stakes analysis.
- **Flash**: default for agentic work, coding, and chat where latency matters.
- **Flash-Lite**: classification, extraction, routing, and other high-volume routes.

All Gemini 3 models take about 1M input tokens and 64k output tokens (https://ai.google.dev/gemini-api/docs/long-context).

## Checklist

- [ ] Persona, rules, and output format are at the start; the question is last.
- [ ] One delimiter style; no contradictions between persona and format.
- [ ] No chain-of-thought triggers; `thinking_level` is supported by the target endpoint.
- [ ] No temperature below 1.0 assumed.
- [ ] Negative constraints match the task type (strict for extraction, specific for reasoning).
- [ ] Few-shot examples for pattern tasks, correct patterns only.
- [ ] With a response schema, the prompt does not repeat the schema.
- [ ] Time-sensitive tasks carry the current date and cutoff from the harness.
- [ ] Tool set capped at 10-20, with specific descriptions.

## Reference Files

- `references/jinja-patterns.md`: read when writing few-shot, extraction, multi-source, or decomposed prompts as Jinja templates.
- `references/tools-and-grounding.md`: read when the prompt drives function calling or Google Search grounding.
- `references/migration.md`: read when converting prompts from Gemini 2.5 or an earlier 3.x model.

## Reference

- Gemini 3 developer guide: https://ai.google.dev/gemini-api/docs/gemini-3
- Prompting strategies: https://ai.google.dev/gemini-api/docs/prompting-strategies
- Thinking: https://ai.google.dev/gemini-api/docs/thinking
- Function calling: https://ai.google.dev/gemini-api/docs/function-calling
- Grounding with Google Search: https://ai.google.dev/gemini-api/docs/google-search
- Long context: https://ai.google.dev/gemini-api/docs/long-context
- Context caching: https://ai.google.dev/gemini-api/docs/caching
- Models: https://ai.google.dev/gemini-api/docs/models
- Deprecations: https://ai.google.dev/gemini-api/docs/deprecations
