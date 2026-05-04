---
name: gemini-3-prompting
description: Apply when creating or editing prompts targeting Gemini 3. Covers prompt layering (system instruction + context + task), thinking_level tuning, structured output prompting, function calling guidance, grounding prompt wording, few-shot examples, long-context patterns, persona/constraint alignment, prompt decomposition, agentic workflows, and migration from Gemini 2.5.
---

# Gemini 3 Prompting

## When to Use

- Creating or editing system prompts targeting Gemini 3
- Writing few-shot examples for classification or extraction tasks
- Structuring long-context prompts with multiple sources
- Writing agentic instructions for Gemini 3 tool-use workflows
- Decomposing complex prompts into chainable sub-prompts
- Migrating prompt text from Gemini 2.5

## Overview

Gemini 3 responds best to direct, concise instructions. Verbose prompt engineering techniques from older models (Gemini 2.5 and earlier) cause over-analysis and degrade output quality. The model has native thinking capabilities controlled by a `thinking_level` parameter (snake_case in Python, `thinkingLevel` in JS/REST) -- do not write manual chain-of-thought instructions. (Source: ai.google.dev/gemini-api/docs/gemini-3)

<context>
Key characteristics to design around (all cited from ai.google.dev/gemini-api/docs/prompting-strategies and ai.google.dev/gemini-api/docs/gemini-3):

- **Conciseness Over Verbosity**: "Be concise in your input prompts. Gemini 3 responds best to direct, clear instructions." Remove filler.
- **Context Before Task**: "When providing large amounts of context (e.g., documents, code), supply all the context first. Place your specific instructions or questions at the very end of the prompt."
- **Constraints + Persona at the Beginning**: "Place essential behavioral constraints, role definitions (persona), and output format requirements in the System Instruction or at the very beginning of the user prompt."
- **Native Thinking**: `thinking_level` (values: `minimal` / `low` / `medium` / `high`; default `high`, dynamic) replaces manual CoT prompting -- do not write "Let's think step by step." `minimal` is not accepted on Gemini 3.1 Pro.
- **Temperature at 1.0**: "We strongly recommend keeping the `temperature` at its default value of 1.0." Setting it below may cause "looping or degraded performance."
- **Persona + Constraint Alignment**: Persona and other constraints belong together in the System Instruction. Ensure they do not contradict each other.
- **Default Directness**: "By default, Gemini 3 models provide direct and efficient answers." Request conversational tone explicitly if needed.
- **Few-Shot Recommended**: "Prompts without few-shot examples are likely to be less effective."
</context>

## Core Prompt Structure

### Prompt Structure: System Instruction + Context + Task

Google's current guidance splits prompt content by role and position. Constraints and persona go FIRST (system instruction or prompt start); long context goes next; the specific question goes LAST.

> "Prioritize critical instructions: Place essential behavioral constraints, role definitions (persona), and output format requirements in the System Instruction or at the very beginning of the user prompt." -- ai.google.dev/gemini-api/docs/prompting-strategies

> "When providing large amounts of context (e.g., documents, code), supply all the context first. Place your specific instructions or questions at the very end of the prompt." -- ai.google.dev/gemini-api/docs/prompting-strategies

```jinja
{# System Instruction -- behavioural rules, persona, output format #}
<role>{{ persona }}</role>
<constraints>
{% for constraint in behavioural_constraints %}
- {{ constraint }}
{% endfor %}
</constraints>
<output_format>{{ output_format }}</output_format>

{# User Prompt -- context first, specific task last #}
<context>
{{ context_data }}
</context>

<task>
Based on the information above, {{ specific_question }}.
</task>
```

### Bridging Context to Task

Use bridging phrases to connect the context block to the task at the end: "Based on the information above, ...", "Using only the provided documents, ...", "Given the context above, ...", "Based on the entire document above, provide a comprehensive answer to: ...". The last phrasing is especially effective when synthesizing from multiple sources -- it anchors the model to the full input rather than just the most recent section.

### Consistent Delimiters

Pick ONE delimiter style within a single prompt -- XML tags (`<role>`, `<constraints>`, `<context>`, `<task>`) OR Markdown headings (`# Identity`, `# Constraints`, `# Context`, `# Task`), not both. XML tags work best for programmatic prompts; Markdown headings work best for human-readable prompts. (Source: ai.google.dev/gemini-api/docs/prompting-strategies)

### Conciseness

Remove filler that does not change model behavior:

```
Before: "I would like you to carefully analyze the following text and provide
         a detailed summary of the key points, making sure to capture all the
         important information."

After:  "Summarize the key points from the text above."
```

## Thinking and Reasoning

The `thinking_level` parameter controls how deeply the model reasons. It replaces manual chain-of-thought prompting entirely.

| Level | Availability | Use Case |
|-------|-------------|----------|
| `high` (default, dynamic) | All Gemini 3 models | Complex reasoning, analysis, math, multi-step problems |
| `medium` | All Gemini 3 models | Balanced for moderate complexity |
| `low` | All Gemini 3 models | Simple instruction following, chat, high throughput |
| `minimal` | Flash, Flash-Lite only (not Pro) | Chat, quick Q&A; does not guarantee thinking is off |

Parameter name note: `thinking_level` in Python (snake_case) / `thinkingLevel` in JS/REST (camelCase). Cannot disable thinking for Gemini 3.1 Pro -- `minimal` is not accepted there.

**Prompt implications:**

- Remove "Let's think step by step", "Think carefully", and similar CoT triggers from all prompts.
- If you need visible reasoning steps in the output (not just internal reasoning), request it explicitly:

```
Analyze this data. Show your reasoning step by step, then provide your final answer.
```

- For lower latency on Flash models, target `thinking_level: low` or `minimal`. Pro does not accept `minimal`. Do not add manual "think silently" instructions -- rely on the parameter.

## Constraint Writing

### Scope Negatives to the Task

Broad negations like "do not infer any information" work WELL for strict extraction/verbatim-reporting (Google uses exactly this phrasing for grounded extraction: "Do not assume or infer from the provided facts; simply report them exactly as they appear" -- ai.google.dev/gemini-api/docs/prompting-strategies).

They work POORLY when the task requires reasoning or deduction -- the model becomes overly conservative and refuses sensible inferences.

For verbatim extraction:
    "Do not infer. Report facts exactly as they appear in the source."

For reasoning/QA tasks:
    "Use the provided context for deductions. Do not use outside knowledge."

Match the negative to the task type.

### Grounding to Provided Context

When the model should not use training data, be explicit about the source of truth:

```
The provided context is the only source of truth for the current session.
Do not supplement answers with information from your training data.
If the context does not contain relevant information, say so.
```

This is particularly important for hypothetical scenarios, fictional settings, or domain-specific data that contradicts general knowledge.

### Quantitative Constraints

Gemini 3 follows quantitative constraints reliably. Use them instead of vague qualifiers:

```
Avoid:   "Keep it short."
Better:  "Respond in 2-3 sentences."

Avoid:   "List some examples."
Better:  "List exactly 5 examples."
```

## Few-Shot Examples

Google recommends **always including** few-shot examples in Gemini 3 prompts: "Prompts without few-shot examples are likely to be less effective." (Source: ai.google.dev/gemini-api/docs/prompting-strategies) The model reproduces patterns it sees -- every example should reflect exactly the behaviour you want.

- Include 2-5 diverse examples demonstrating the desired pattern
- Use consistent semantic prefixes (Input:, Output:)
- Show correct patterns only, not anti-patterns
- Place examples before the final input (context-first principle)

```jinja
{% for example in few_shot_examples %}
Input: {{ example.input }}
Output: {{ example.output }}

{% endfor %}
Input: {{ current_input }}
Output:
```

For classification with structured output:

```jinja
Classify each message into one of these categories: {{ categories | join(", ") }}.

{% for example in examples %}
Message: {{ example.message }}
Category: {{ example.category }}
Confidence: {{ example.confidence }}

{% endfor %}
Message: {{ input_message }}
Category:
```

## Structured Output

When the caller needs JSON output, JSON schema is enforced by API parameters outside the prompt text itself -- not by embedding the schema in prose. The prompt's job is to state the task clearly; the schema's job is to define the shape.

**Prompt-level guidance when structured output is active:**

- State the intent plainly: "Extract sentiment and confidence from the review."
- Do not paste the schema into the prompt text; rely on the schema parameter to constrain shape. Duplicating the schema in prose wastes tokens and can conflict with the enforced schema.
- If the schema defines enum values (e.g., `"positive" | "neutral" | "negative"`), you can still reference them by name in the prompt instructions to reinforce intent.
- For classification, describe the class meanings in the prompt even when enum values are in the schema -- the schema constrains syntax, not semantics.

**When structured output is NOT active** and you want JSON in prose, include a minimal schema-like example in the prompt:

```jinja
Extract {{ fields | join(", ") }} from the following text.

Text: {{ input_text }}

Respond in JSON format:
{
  {% for field in fields %}
  "{{ field }}": "..."{% if not loop.last %},{% endif %}
  {% endfor %}
}

JSON:
```

**Structured output vs function calling (prompt-design choice):** Use structured output for the model's final *answer*. Use function calling for intermediate actions where the model triggers external code.

## Persona and Tone

### Persona and Constraint Alignment

Define persona in the System Instruction alongside output format and behavioural constraints, and check that they don't contradict each other. Contradictions force the model to pick one -- results become unpredictable.

```
{# Contradiction: persona says "friendly/talkative" but output constraint says "2 words" #}
<role>You are a friendly, talkative customer support agent.</role>
<output_format>Respond in 1-2 words only.</output_format>

{# Aligned: persona and output format agree #}
<role>You are a concise customer support agent who values brevity.</role>
<output_format>Respond in 1-2 words only.</output_format>
```

Review potential conflicts between the persona description and:
- Output length constraints
- Tone requirements elsewhere in the prompt
- Domain restrictions (e.g., a "creative writer" persona asked to stick to facts)

### Conversational Tone

Gemini 3 defaults to direct, efficient responses. If you need a warmer or more conversational tone, request it explicitly:

```
Explain this as a friendly, talkative assistant. Use casual language
and occasional humor where appropriate.
```

Without this, responses will be professional and to-the-point.

## Long-Context and Multi-Source

### Multi-Source Synthesis

When the prompt includes multiple documents, wrap each in an indexed tag and anchor the task to the full set:

```jinja
{% for doc in documents %}
<document id="{{ loop.index }}">
{{ doc }}
</document>
{% endfor %}

Based on the entire set of documents above, provide a comprehensive answer
to the following question. Reference specific documents by ID when citing
information.

Question: {{ question }}
```

### Prefix-Cache-Friendly Ordering

Gemini 3 has a 1M input / 64k output context window. Implicit caching matches on prompt prefix. Put stable content (system instructions, few-shot examples, large reference documents) at the START; put volatile content (user query, session-specific data) at the END. Prompts that share a stable prefix across requests hit the cache; prompts that interleave volatile and stable content do not.

### Knowledge Cutoff Declaration

When the model needs to be aware of its knowledge boundaries, include the cutoff in system instructions:

```
Your knowledge cutoff date is January 2025. For events or information
after this date, rely only on the provided context.
```

### Grounding Hypothetical Scenarios

For fictional, counterfactual, or simulation-based prompts, establish the context as the sole source of truth:

```
You are operating in a simulated environment. The provided context describes
the current state of this environment. Treat it as the only source of truth.
Do not reference real-world information that contradicts the simulation state.
```

## Prompt Decomposition

When a single prompt tries to do too much, split it into focused sub-prompts and chain outputs. Three common shapes:

**Sequential chain** -- extract, analyze, summarize:

```
Stage 1 -- Extract: "Extract all dates, names, and monetary amounts from the
contract above. Respond in JSON format."

Stage 2 -- Analyze (receives Stage 1 output): "Given the extracted data above,
identify any clauses where the effective date is more than 90 days from the
signing date."

Stage 3 -- Summarize (receives Stage 2 output): "Summarize the flagged clauses
in plain language for a non-legal audience."
```

**Two-step verification** -- prevents silent fallback to training data:

```
First, check if the document above contains information about {{ topic }}.
If it does, answer the following question based on that information:
{{ question }}
If the document does not contain relevant information, state that clearly
instead of answering from general knowledge.
```

**Parallel decomposition** -- independent sub-prompts aggregated:

```jinja
{% for section in document_sections %}
Prompt {{ loop.index }}: "Summarize the following section in 2-3 sentences: {{ section }}"
{% endfor %}

Aggregation: "Given the section summaries above, write a unified executive summary in one paragraph."
```

## Agentic Prompts

Gemini 3 agentic workflows benefit from explicit guidance on four dimensions (Source: ai.google.dev/gemini-api/docs/prompting-strategies):

1. **Logical decomposition** -- how to sequence operations and satisfy constraints.
2. **Risk assessment** -- distinguishing exploratory reads from state-changing writes.
3. **Adaptability** -- pivoting when observation contradicts assumption.
4. **Persistence** -- recovering from failures without abandoning the task.

**System instruction skeleton:**

```jinja
Agent Instructions:
- For EXPLORATORY actions (searches, reads, lookups): prefer calling the tool with available information over asking for clarification. Missing optional parameters is low risk.
- For STATE-CHANGING actions (writes, deletes, external side effects): explain what will change and why before acting. Ask for confirmation when the user's intent is ambiguous.
- When observation contradicts your plan, revise the plan rather than retrying the same action.
- For routine tool execution, proceed without narration.
- For planning and complex decisions, explain your reasoning.
```

**Tool scope affects prompt design:**

- Cap the active tool set at **10-20 tools**. "Providing too many can increase the risk of selecting an incorrect or suboptimal tool." (Source: ai.google.dev/gemini-api/docs/function-calling) Large tool sets also inflate the system prompt; prune tools the agent won't plausibly call for the current workflow.
- Gemini 3 generates a unique `id` for every function call and exposes `thought_signature` on function-call turns. When prompt-flow metadata is authored manually (e.g., REST history or custom scaffolds), those fields must round-trip unchanged.

**Thinking level tuning:**

- `thinking_level: high` for planning and multi-step decisions.
- `thinking_level: low` or `medium` for routine tool execution loops.
- Let native thinking handle task decomposition; avoid manually prescribing reasoning steps.

## Function Calling

Gemini 3 function-calling prompt-design conventions (Source: ai.google.dev/gemini-api/docs/function-calling):

**Tool declaration wording -- this text IS prompt content the model reads:**

- Name functions with descriptive snake_case or camelCase -- no spaces, no special characters.
- Write specific, unambiguous tool descriptions: "The model relies on these to choose the correct function." A vague description is a prompt-quality issue.
- Describe parameter semantics in each parameter's description, including valid ranges, units, and enum meanings.
- Mark required parameters explicitly; optional parameters should state what omitting them means.

**Active tool set:** cap at 10-20 tools per request -- scope each prompt to just the tools relevant to the workflow.

**Function calling modes (prompt-scope implications):**

| Mode | Prompt implication |
|------|--------------------|
| `AUTO` | Prompt should describe when tool use is appropriate vs when prose answer suffices. |
| `ANY` | Prompt can assume a call will happen; focus on guiding argument selection. |
| `VALIDATED` | Prompt should support both paths; describe when each is preferred. |
| `NONE` | Treat as a pure prompt-only task; don't reference tools. |

**Parallel and compositional calls:** Gemini 3 issues multiple function calls per turn when warranted. For compositional chains (e.g., `get_location()` then `get_weather(location)`), let the model orchestrate -- don't prescribe the sequence in prose.

**Multi-turn state:** when authoring conversation history manually, surface `function_call_id` on each `functionCall`/`functionResponse` pair and preserve `thought_signature` across turns. Mismatched or dropped fields break reasoning continuity.

## Grounding with Google Search

When grounding is enabled via the `google_search` tool, the model performs real-time retrieval and returns citation metadata. The prompt's job is to shape when and how the model uses that retrieval.

**Prompt wording that triggers grounding well:**

- Phrase queries that reference current information: "What is the current price of...", "What are the latest...", "As of today, ..."
- Include explicit triggers when grounding should fire: "Use up-to-date information" or "Based on the most recent data available".
- For time-sensitive tasks, include a dated frame: "As of {{ today }}, ..."

**Prompt pattern when grounding is on:**

```
Answer the user's question using up-to-date information from Google Search.
Cite specific sources with inline markers. Use bracketed indices like [1], [2]
that correspond to the retrieved sources.

Question: {{ user_query }}
```

**Citation rendering:** Gemini returns grounding metadata keyed by index. When the prompt asks for inline citations, instruct the model to use bracketed indices (`[1]`, `[2]`) -- the caller maps those indices to URLs in the grounding metadata. Do not ask the model to emit full URLs inline; it degrades answer quality.

**Tool selection note:** current Gemini 3 variants use the `google_search` tool (not the legacy `google_search_retrieval` tool). If a migrated prompt references the legacy name in tool-instruction text, update it.

## Gemini 3 Pro vs Flash (prompt-design choices)

- **Gemini 3.1 Pro**: complex reasoning, multimodal tasks, long deliberation. Default `thinking_level: high` (dynamic). Does NOT accept `thinking_level: minimal`. Target Pro when the prompt demands multi-step reasoning, synthesis across many sources, or high-stakes analysis.
- **Gemini 3 Flash / 3.1 Flash-Lite**: high-throughput, latency-sensitive, chat, structured extraction. Accept all `thinking_level` values including `minimal`. Target Flash for classification, extraction, routing, and conversational tasks where latency matters more than depth.

Flash-specific prompting: include "current day accuracy" context and explicit knowledge-cutoff statements for time-sensitive tasks. (Source: ai.google.dev/gemini-api/docs/prompting-strategies, Gemini 3 Flash strategies section)

## Common Patterns

### Classification Task

```jinja
Classify the following {{ item_type }} into one of these categories: {{ categories | join(", ") }}.

{% for example in examples %}
{{ item_type }}: {{ example.input }}
Category: {{ example.category }}

{% endfor %}
{{ item_type }}: {{ input_item }}
Category:
```

### Reasoning Task

Keep the prompt simple; rely on `thinking_level: high`:

```jinja
{{ question }}

Provide your analysis and final answer.
```

If you need visible reasoning in the output:

```jinja
{{ question }}

Show your reasoning step by step, then provide your final answer.
```

## Iteration Techniques

When a prompt is not producing the desired output:

1. **Rephrase**: Gemini 3 can respond differently to semantically equivalent phrasings.
2. **Reorder**: move the question to the end (after context); move constraints, persona, and output format to the beginning.
3. **Switch to an analogous task**: if "summarize this document" fails, try "extract the 5 most important points" -- differently framed.
4. **Add or remove examples**: over-fitting? reduce to 2. Under-performing? add edge-case examples.
5. **Adjust constraint specificity**: replace vague constraints with quantitative ones, or loosen overly tight ones.
6. **Decompose**: if iteration is not converging, split into sub-prompts.

## Migration from Gemini 2.5

Prompt-level changes when migrating from Gemini 2.5 to Gemini 3 (Source: ai.google.dev/gemini-api/docs/gemini-3):

- [ ] Remove manual CoT instructions ("Let's think step by step", "Think carefully before answering") -- rely on `thinking_level` instead.
- [ ] Remove prompt text that assumes `temperature` below 1.0. Gemini 3 expects 1.0.
- [ ] Simplify verbose prompts. "Gemini 3 responds best to direct, clear instructions."
- [ ] Move critical constraints, persona, and output format to the **beginning** (System Instruction or prompt start). Move specific questions to the **end**.
- [ ] Review broad negatives ("do not infer"). Keep them for strict verbatim-extraction tasks; replace with specific alternatives for reasoning tasks.
- [ ] Verify persona instructions do not contradict output-format or length constraints.
- [ ] Remove image segmentation instructions (not supported in Gemini 3).
- [ ] Remove in-prompt JSON schema templates when the caller now uses schema-enforced structured output -- state the task in prose, let the schema define shape.
- [ ] In tool-instruction text, replace legacy `google_search_retrieval` references with `google_search`.
- [ ] Replace any `thinking_budget` phrasing (Gemini 2.5) with `thinking_level` (Gemini 3) in prompt metadata.

## Anti-Patterns

- **Manual chain-of-thought**: "Let's think step by step" is redundant when `thinking_level` is active. Remove it. (Source: ai.google.dev/gemini-api/docs/gemini-3)
- **Assuming `temperature` below 1.0**: "May lead to unexpected behavior, such as looping or degraded performance." Prompts written to compensate for low-temperature determinism won't match Gemini 3's default sampling. (Source: ai.google.dev/gemini-api/docs/gemini-3)
- **Broad negatives in reasoning tasks**: "Never assume" makes the model refuse reasonable deductions. Scope the negative to the task -- strict for extraction, specific for reasoning.
- **Persona-constraint contradictions**: A "friendly, talkative" persona paired with a "2-word response" constraint produces unpredictable output. Align persona with output format in the System Instruction.
- **Context after the question**: "The model's performance will be better if you put your query / question at the end of the prompt." Context first, question last. (Source: ai.google.dev/gemini-api/docs/long-context)
- **Constraints placed at the end instead of the beginning**: Behavioural constraints, persona, output format go at the BEGINNING or in the System Instruction -- not at the end. (Source: ai.google.dev/gemini-api/docs/prompting-strategies)
- **Mixed delimiter styles**: Using both XML tags and Markdown headings for structural sections in the same prompt. Pick one style.
- **Over-specified prompts**: Long meta-instructions about how to approach the task. Gemini 3 handles concise instructions better than verbose ones.
- **Anti-pattern examples**: Showing the model what NOT to do. It reproduces patterns it sees, including bad ones.
- **Duplicating schema in prose when structured output is active**: Wastes tokens and can conflict with the enforced schema. State the task; let the schema define shape.
- **Overloading the tool set**: Exceeding 20 active tools -- "Providing too many can increase the risk of selecting an incorrect or suboptimal tool." Scope prompts to the tools the current workflow actually needs. (Source: ai.google.dev/gemini-api/docs/function-calling)
- **Vague tool descriptions**: Tool descriptions are prompt content. A description like "Gets data" forces the model to guess when to call it.

## Quality Checklist

- [ ] Instructions are concise and direct (no verbose meta-instructions).
- [ ] Persona, behavioural constraints, and output format are placed at the BEGINNING (System Instruction).
- [ ] Large context blocks are placed BEFORE the specific question/task.
- [ ] Specific question or task is placed at the END of the user prompt.
- [ ] One delimiter style (XML OR Markdown) is used consistently.
- [ ] Response format is explicitly defined; when structured output is active, the prompt states the task in prose without duplicating the schema.
- [ ] Few-shot examples are included (Google: "always include" -- 2-5 diverse examples).
- [ ] Examples show only correct patterns, not anti-patterns.
- [ ] No manual CoT instructions -- rely on `thinking_level`.
- [ ] `thinking_level` target respects model support (`minimal` is not accepted on Gemini 3.1 Pro).
- [ ] Prompt does not assume temperature below 1.0.
- [ ] Negative constraints match the task type (strict for extraction, specific for reasoning).
- [ ] Persona does not contradict output-format or length constraints.
- [ ] Grounding instructions are included when context should override training data.
- [ ] Knowledge-cutoff clause is present for time-sensitive tasks.
- [ ] For tool use: active tool set is capped at 10-20; tool and parameter descriptions are specific.
- [ ] For grounding: tool-instruction text references `google_search` (not legacy `google_search_retrieval`); citation format is described.
- [ ] Stable content (system, examples, large docs) is at the START of the prompt for prefix-cache hits.
- [ ] Complex prompts are decomposed into chainable sub-prompts where needed.

## Reference

- Gemini 3 Developer Guide: https://ai.google.dev/gemini-api/docs/gemini-3
- Gemini Prompting Strategies: https://ai.google.dev/gemini-api/docs/prompting-strategies
- Thinking Level: https://ai.google.dev/gemini-api/docs/thinking
- Structured Output (JSON Schema): https://ai.google.dev/gemini-api/docs/structured-output
- Function Calling: https://ai.google.dev/gemini-api/docs/function-calling
- Context Caching: https://ai.google.dev/gemini-api/docs/caching
- Grounding with Google Search: https://ai.google.dev/gemini-api/docs/google-search
- Long Context: https://ai.google.dev/gemini-api/docs/long-context
- Gemini Models: https://ai.google.dev/gemini-api/docs/models
- Vertex AI Prompt Design: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/prompts/introduction-prompt-design
